# FILE: src/coach-engine/coach_llm.py
from __future__ import annotations

import json
import logging
import os
import re
import time
from typing import Any

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, __version__ as TRANSFORMERS_VERSION

logger = logging.getLogger("cadence.coach_engine")

DEFAULT_COACH_MODEL = os.getenv("COACH_LLM_MODEL_ID", "Qwen/Qwen2.5-3B-Instruct")


def _format_support_error(message: str) -> str:
    normalized = message.strip()
    if "model type `gemma4`" in normalized or "model type 'gemma4'" in normalized:
        return (
            f"Gemma 4 is not supported by your installed Transformers build "
            f"(detected version {TRANSFORMERS_VERSION}). "
            "Update the coach environment with `pip install -U accelerate`, "
            "and install the latest Transformers source build with "
            "`pip install git+https://github.com/huggingface/transformers.git`."
        )
    return normalized


def _extract_json_object(content: str) -> str:
    trimmed = content.strip()
    if trimmed.startswith("{") and trimmed.endswith("}"):
        return trimmed

    fenced_match = re.search(r"```(?:json)?\s*([\s\S]*?)```", trimmed, re.IGNORECASE)
    if fenced_match:
        return fenced_match.group(1).strip()

    first_brace = trimmed.find("{")
    last_brace = trimmed.rfind("}")
    if first_brace >= 0 and last_brace > first_brace:
        return trimmed[first_brace : last_brace + 1]

    return trimmed


def _clean_model_output(content: str) -> str:
    cleaned = re.sub(r"<\|[^|]+?\|>", " ", str(content))
    cleaned = re.sub(r"</?think>", " ", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\r\n?", "\n", cleaned)
    cleaned = re.sub(r"[ \t]+", " ", cleaned)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned).strip()
    return cleaned


def _latest_history_content(
    history: list[dict[str, Any]],
    role: str,
) -> str:
    for entry in reversed(history):
        if str(entry.get("role") or "").lower() != role:
            continue

        content = re.sub(r"\s+", " ", str(entry.get("content") or "")).strip()
        if content:
            return content
    return ""


def _normalize_for_match(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.lower()).strip()


def _strip_inline_coach_annotations(value: str) -> str:
    normalized = str(value or "")
    normalized = re.sub(
        r"\[\s*checkpoint\s*:\s*[^\]]+?\s*\]",
        "",
        normalized,
        flags=re.IGNORECASE,
    )
    normalized = re.sub(
        r"\[\s*transcript\s*=\s*[^\]]+?\s*\]",
        "",
        normalized,
        flags=re.IGNORECASE,
    )
    normalized = re.sub(
        r"\[\s*cue\s*=\s*[^\]]+?\s*\]",
        "",
        normalized,
        flags=re.IGNORECASE,
    )
    normalized = re.sub(
        r"\bCue\s*:\s*.+?(?=\bCheckpoint\s*:|\Z)",
        "",
        normalized,
        flags=re.IGNORECASE,
    )
    normalized = re.sub(
        r"\bCheckpoint\s*:\s*.+$",
        "",
        normalized,
        flags=re.IGNORECASE,
    )
    normalized = re.sub(
        r"\bLearnerReply\s*:\s*$",
        "",
        normalized,
        flags=re.IGNORECASE,
    )
    return re.sub(r"\s+", " ", normalized).strip()


def _looks_like_prompt_echo(content: str) -> bool:
    lowered = str(content or "").strip().lower()
    if not lowered:
        return False

    return any(
        re.search(pattern, lowered)
        for pattern in (
            r"\btopic\s*:",
            r"\baction\s*:",
            r"\bturn type\s*:",
            r"\blearner mode\s*:",
            r"\breply mode\b",
            r"\btarget mode\b",
            r"\bfreedom mode\b",
            r"\bcoachmessage\b",
            r"\blearnerreply\b",
            r"\bnextstep\s*=",
            r"\bnext step\s*[:=]",
            r"\btarget\s*=",
            r"\btranscript\s*=",
            r"\bscore\s*=",
            r"\bsummary\s*=",
            r"\bcue\s*[:=]",
            r"\bcheckpoint\s*[:=]",
            r"\blatest pronunciation assessment\b",
        )
    )


def _is_repeated_coach_message(coach_message: str, history: list[dict[str, Any]]) -> bool:
    latest_coach = _latest_history_content(history, "coach")
    if not latest_coach:
        return False

    normalized_coach = _normalize_for_match(coach_message)
    normalized_latest = _normalize_for_match(latest_coach)
    if not normalized_coach or not normalized_latest:
        return False

    if normalized_coach == normalized_latest:
        return True

    if len(normalized_coach) < 36 or len(normalized_latest) < 36:
        return False

    return normalized_coach.startswith(normalized_latest) or normalized_latest.startswith(
        normalized_coach
    )


def _should_reject_coach_message(coach_message: str, history: list[dict[str, Any]]) -> bool:
    normalized = _sanitize_coach_message(coach_message, "")
    if not normalized:
        return True

    return (
        _looks_like_prompt_echo(coach_message)
        or _is_echoed_user_message(normalized, history)
        or _is_repeated_coach_message(normalized, history)
        or _is_low_information_coach_message(normalized)
    )


def _is_low_information_coach_message(coach_message: str) -> bool:
    normalized = re.sub(r"\s+", " ", coach_message).strip()
    if not normalized:
        return True

    lowered = normalized.lower()
    word_count = len(lowered.split())

    generic_patterns = (
        r"^continue (your|the) ",
        r"^continue preparing",
        r"^continue practicing",
        r"^keep practicing",
        r"^keep preparing",
        r"^keep working on",
        r"^let'?s continue",
        r"^let'?s keep going",
        r"^continue the conversation",
        r"^continue your preparations",
    )
    if any(re.search(pattern, lowered) for pattern in generic_patterns):
        return True

    if "?" not in normalized and word_count <= 7:
        return True

    if "?" not in normalized and lowered.startswith("let's make sure"):
        return True

    return False


def _parse_labeled_turn(content: str) -> dict[str, str] | None:
    matches = re.finditer(
        r"(?ims)(?:^|\n)\s*(coachmessage|coach message|coach|learnerreply|learner reply|reply|cue|checkpoint)\s*[:=-]\s*(.+?)(?=(?:\n\s*(?:coachmessage|coach message|coach|learnerreply|learner reply|reply|cue|checkpoint)\s*[:=-])|\Z)",
        content,
    )

    parsed: dict[str, str] = {}
    for match in matches:
        raw_key = match.group(1).strip().lower().replace(" ", "")
        value = match.group(2).strip().strip('"')

        if raw_key in {"coachmessage", "coach"}:
            parsed["coachMessage"] = value
        elif raw_key in {"learnerreply", "reply"}:
            parsed["learnerReply"] = value
        elif raw_key == "cue":
            parsed["cue"] = value
        elif raw_key == "checkpoint":
            parsed["checkpoint"] = value

    if not parsed:
        return None

    coach_message = parsed.get("coachMessage")
    if coach_message:
        inline_bracket_cue = re.search(
            r"\[\s*cue\s*=\s*([^\]]+?)\s*\]",
            coach_message,
            flags=re.IGNORECASE,
        )
        inline_cue = re.search(
            r"\bCue\s*:\s*(.+?)(?=\bCheckpoint\s*:|\Z)",
            coach_message,
            flags=re.IGNORECASE,
        )
        inline_checkpoint_text = re.search(
            r"\bCheckpoint\s*:\s*(.+?)\s*$",
            coach_message,
            flags=re.IGNORECASE,
        )
        inline_checkpoint = re.search(
            r"\[\s*checkpoint\s*:\s*([^\]]+?)\s*\]",
            coach_message,
            flags=re.IGNORECASE,
        )
        if inline_bracket_cue and not parsed.get("cue"):
            parsed["cue"] = inline_bracket_cue.group(1).strip()
        if inline_cue and not parsed.get("cue"):
            parsed["cue"] = inline_cue.group(1).strip()
        if inline_checkpoint_text and not parsed.get("checkpoint"):
            parsed["checkpoint"] = inline_checkpoint_text.group(1).strip()
        if inline_checkpoint and not parsed.get("checkpoint"):
            parsed["checkpoint"] = inline_checkpoint.group(1).strip()

        parsed["coachMessage"] = _strip_inline_coach_annotations(coach_message)

    return _coerce_turn(parsed)


def _parse_turn_response(
    decoded: str,
    mode: str,
    history: list[dict[str, Any]],
) -> dict[str, str]:
    cleaned = _clean_model_output(decoded)
    json_candidate = _extract_json_object(cleaned)

    if json_candidate:
        try:
            parsed_turn = _normalize_turn(_coerce_turn(json.loads(json_candidate)), mode)
            if _should_reject_coach_message(parsed_turn["coachMessage"], history):
                raise RuntimeError(
                    "Coach model output was rejected because it echoed prompt metadata or repeated the previous coach turn."
                )
            return parsed_turn
        except json.JSONDecodeError:
            pass

    labeled = _parse_labeled_turn(cleaned)
    if labeled:
        parsed_turn = _normalize_turn(labeled, mode)
        if _should_reject_coach_message(parsed_turn["coachMessage"], history):
            raise RuntimeError(
                "Coach model output was rejected because it echoed prompt metadata or repeated the previous coach turn."
            )
        return parsed_turn

    raise RuntimeError(
        f"Coach model returned an invalid turn format. Expected JSON with coachMessage, learnerReply, cue, and checkpoint. Output preview: {cleaned[:240]}"
    )


def _sanitize_sentence(value: Any, fallback: str) -> str:
    normalized = re.sub(r"\s+", " ", str(value or "")).strip()
    return normalized or fallback


def _sanitize_coach_message(value: Any, fallback: str) -> str:
    normalized = _sanitize_sentence(value, fallback)
    normalized = _strip_inline_coach_annotations(normalized)
    return normalized or fallback


def _is_echoed_user_message(coach_message: str, history: list[dict[str, Any]]) -> bool:
    latest_user = _latest_history_content(history, "user")
    if not latest_user:
        return False

    normalized_coach = _normalize_for_match(coach_message)
    normalized_user = _normalize_for_match(latest_user)
    if not normalized_coach or not normalized_user:
        return False

    return normalized_coach.startswith(normalized_user)


def _normalize_turn(turn: dict[str, str], mode: str) -> dict[str, str]:
    coach_message = _sanitize_coach_message(turn.get("coachMessage"), "")
    if not coach_message:
        raise RuntimeError("Coach response is missing coachMessage.")

    learner_reply = "" if mode == "freedom" else _sanitize_sentence(
        turn.get("learnerReply"),
        "",
    )
    if mode != "freedom" and not learner_reply:
        raise RuntimeError("Coach response is missing learnerReply in target mode.")

    if learner_reply and learner_reply[-1:] not in ".!?":
        learner_reply = f"{learner_reply}."

    cue = _sanitize_sentence(turn.get("cue"), "")
    if not cue:
        raise RuntimeError("Coach response is missing cue.")

    checkpoint = _sanitize_sentence(turn.get("checkpoint"), "").lower()
    if not checkpoint:
        raise RuntimeError("Coach response is missing checkpoint.")

    return {
        "coachMessage": coach_message,
        "learnerReply": learner_reply,
        "cue": cue,
        "checkpoint": checkpoint,
    }


def _coerce_turn(raw: Any) -> dict[str, str]:
    if not isinstance(raw, dict):
        raise RuntimeError("Coach response was not valid JSON.")

    return {
        "coachMessage": _sanitize_coach_message(
            raw.get("coachMessage"),
            "",
        ),
        "learnerReply": _sanitize_sentence(
            raw.get("learnerReply") if raw.get("learnerReply") != "" else "",
            "",
        ),
        "cue": _sanitize_sentence(
            raw.get("cue"),
            "",
        ),
        "checkpoint": _sanitize_sentence(
            raw.get("checkpoint"),
            "",
        ).lower(),
    }


def _serialize_history(history: list[dict[str, Any]]) -> str:
    if not history:
        return "No previous turns yet."

    lines: list[str] = []
    for index, entry in enumerate(history[-10:], start=1):
        content = str(entry.get("content") or "").strip()
        role = str(entry.get("role") or "user").upper()
        lines.append(f"{index}. {role}: {content}")
    return "\n".join(lines)


def _system_prompt() -> str:
    return " ".join(
        [
            "You are Cadence Coach.",
            "You are an English speaking partner for short conversational practice.",
            "Speak like a natural conversation partner, not like a lecturer or technical instructor.",
            "Return exactly one JSON object with these keys: coachMessage, learnerReply, cue, checkpoint.",
            "coachMessage is the next thing the coach says.",
            "It should usually be one short question, or two short sentences when you need to answer the learner briefly first.",
            "Do not dodge or replace a specific learner question with a vague encouragement.",
            "Do not give step-by-step lessons, long explanations, safety guidance, or multi-part instructions.",
            "Keep coachMessage under 20 words when possible.",
            "In target mode, learnerReply is the exact sentence the learner should say next and it must be a short natural first-person answer to coachMessage.",
            "In freedom mode, learnerReply must be an empty string.",
            "Keep learnerReply under 16 words when possible.",
            "cue is a short pronunciation note.",
            "checkpoint is a short lowercase label.",
            "Return JSON only.",
        ]
    )


def _user_prompt(payload: dict[str, Any]) -> str:
    topic = str(payload.get("topic") or "").strip()
    action = str(payload.get("action") or "continue")
    mode = str(payload.get("mode") or "target").strip().lower()
    history = payload.get("history") if isinstance(payload.get("history"), list) else []
    latest_coach = _latest_history_content(history, "coach")
    latest_user = _latest_history_content(history, "user")
    lines = [
        f"Topic: {topic or 'open speaking practice'}",
        f"Action: {action}",
        f"Mode: {mode}",
        "History:",
        _serialize_history(history),
    ]

    if latest_coach:
        lines.append(f"Latest coach line: {latest_coach}")
    if latest_user:
        lines.append(f"Latest learner line: {latest_user}")

    latest_assessment = payload.get("latestAssessment")
    if isinstance(latest_assessment, dict):
        lines.extend(
            [
                "Latest pronunciation note:",
                str(latest_assessment.get("nextStep") or "").strip(),
            ]
        )

    lines.extend(
        [
            "Instruction:",
            "Start the conversation on the topic."
            if action == "start"
            else "Continue the conversation from the latest exchange.",
            "Keep it conversational and concise.",
            "Your next coachMessage must respond directly to the latest learner line.",
            "If the learner asks a question, answer it briefly and then ask one short follow-up question.",
            "If the learner changes the angle of the conversation, follow that change.",
            "Do not ignore specific details like dates, worries, plans, or side ideas if the learner brings them up.",
            "Ask one simple follow-up instead of teaching the topic.",
            "If mode is target, generate one short answer sentence the learner can repeat aloud easily.",
            "If mode is freedom, leave learnerReply empty.",
        ]
    )

    return "\n".join(lines)


def _revision_prompt(
    payload: dict[str, Any],
    *,
    previous_output: str,
    error_message: str,
) -> str:
    mode = str(payload.get("mode") or "target").strip().lower()
    latest_user = _latest_history_content(
        payload.get("history") if isinstance(payload.get("history"), list) else [],
        "user",
    )

    lines = [
        "Revise your previous turn.",
        f"Problem: {error_message}",
        f"Mode: {mode}",
        f"Latest learner line: {latest_user or 'none'}",
        f"Previous output: {_clean_model_output(previous_output)[:240]}",
        "Return exactly one JSON object with coachMessage, learnerReply, cue, checkpoint.",
        "coachMessage must clearly respond to the latest learner line.",
        "If the learner asked a direct question, answer it briefly and ask one short follow-up question.",
        "Do not give a generic line like 'continue your preparations'.",
        "Do not ignore specific details from the learner line.",
        "Keep the turn conversational and concise.",
        "If mode is freedom, learnerReply must be an empty string.",
    ]

    return "\n".join(lines)


class GemmaCoachEngine:
    def __init__(self, model_id: str = DEFAULT_COACH_MODEL) -> None:
        self.model_id = model_id
        self.model: AutoModelForCausalLM | None = None
        self.tokenizer = None
        self.model_loaded = False
        self.load_error: str | None = None
        self.device_label = self._detect_device()
        self.last_warmup_seconds: float | None = None
        self.last_generation_seconds: float | None = None
        self.max_new_tokens = int(os.getenv("COACH_LLM_MAX_NEW_TOKENS", "160"))
        self.temperature = float(os.getenv("COACH_LLM_TEMPERATURE", "0.78"))
        self.top_p = float(os.getenv("COACH_LLM_TOP_P", "0.9"))

    def _detect_device(self) -> str:
        forced = os.getenv("COACH_LLM_DEVICE", "").strip().lower()
        if forced:
            return forced
        if torch.cuda.is_available():
            return "cuda"
        if torch.backends.mps.is_available():
            return "mps"
        return "cpu"

    def _load_model(self) -> None:
        if self.model_loaded and self.model and self.tokenizer:
            return

        load_start = time.perf_counter()
        logger.info(
            "Coach model loading model=%s device=%s",
            self.model_id,
            self.device_label,
        )

        self.tokenizer = AutoTokenizer.from_pretrained(self.model_id, padding_side="left")
        if self.tokenizer.pad_token_id is None and self.tokenizer.eos_token is not None:
            self.tokenizer.pad_token = self.tokenizer.eos_token

        if self.device_label == "cuda":
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_id,
                torch_dtype="auto",
                device_map="auto",
            )
        elif self.device_label == "mps":
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_id,
                torch_dtype=torch.float16,
            )
            self.model.to("mps")
        else:
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_id,
                torch_dtype=torch.float32,
            )

        self.model.eval()
        self.model_loaded = True
        self.load_error = None
        self.last_warmup_seconds = time.perf_counter() - load_start
        logger.info(
            "Coach model loaded model=%s device=%s elapsed=%.2fs",
            self.model_id,
            self.device_label,
            self.last_warmup_seconds,
        )

    def warmup(self, force: bool = False) -> None:
        if self.model_loaded and not force:
            return

        try:
            self._load_model()
        except Exception as exc:
            self.model_loaded = False
            self.load_error = _format_support_error(str(exc))
            logger.exception("Coach model warmup failed")

    def get_status(self) -> dict[str, Any]:
        return {
            "coachReady": self.model_loaded,
            "coachModel": self.model_id,
            "coachDevice": self.device_label,
            "coachLoadError": self.load_error,
            "coachTransformersVersion": TRANSFORMERS_VERSION,
            "coachLastWarmupSeconds": self.last_warmup_seconds,
            "coachLastGenerationSeconds": self.last_generation_seconds,
        }

    def _generate_decoded(
        self,
        messages: list[dict[str, str]],
        *,
        max_new_tokens: int | None = None,
        temperature: float | None = None,
        top_p: float | None = None,
    ) -> str:
        try:
            prompt = self.tokenizer.apply_chat_template(
                messages,
                tokenize=False,
                add_generation_prompt=True,
                enable_thinking=False,
            )
        except TypeError:
            prompt = self.tokenizer.apply_chat_template(
                messages,
                tokenize=False,
                add_generation_prompt=True,
            )

        inputs = self.tokenizer(prompt, return_tensors="pt")

        if self.device_label == "mps":
            inputs = {key: value.to("mps") for key, value in inputs.items()}
        elif self.device_label == "cuda":
            inputs = {key: value.to(self.model.device) for key, value in inputs.items()}

        input_len = inputs["input_ids"].shape[-1]

        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=max_new_tokens or self.max_new_tokens,
                do_sample=True,
                temperature=self.temperature if temperature is None else temperature,
                top_p=self.top_p if top_p is None else top_p,
                repetition_penalty=1.08,
                pad_token_id=self.tokenizer.pad_token_id or self.tokenizer.eos_token_id,
            )

        return self.tokenizer.decode(
            outputs[0][input_len:],
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )

    def generate_turn(self, payload: dict[str, Any]) -> dict[str, Any]:
        if not self.model_loaded or not self.model or not self.tokenizer:
            self.warmup(force=True)

        if not self.model_loaded or not self.model or not self.tokenizer:
            raise RuntimeError(
                self.load_error or "Coach model is not ready yet."
            )

        topic = str(payload.get("topic") or "").strip()
        history = payload.get("history") if isinstance(payload.get("history"), list) else []
        if not topic:
            raise ValueError("A topic is required to start the coach.")

        messages = [
            {"role": "system", "content": _system_prompt()},
            {"role": "user", "content": _user_prompt(payload)},
        ]
        generation_start = time.perf_counter()
        last_error: str | None = None
        decoded = ""
        turn: dict[str, str] | None = None

        for attempt in range(2):
            decoded = self._generate_decoded(messages)
            logger.info(
                "Coach raw model output attempt=%s preview=%s",
                attempt + 1,
                _clean_model_output(decoded)[:240],
            )

            try:
                turn = _parse_turn_response(
                    decoded,
                    mode=str(payload.get("mode") or "target"),
                    history=history,
                )
                break
            except RuntimeError as exc:
                last_error = str(exc)
                if attempt == 1:
                    raise

                messages = [
                    {"role": "system", "content": _system_prompt()},
                    {"role": "user", "content": _user_prompt(payload)},
                    {"role": "assistant", "content": decoded},
                    {
                        "role": "user",
                        "content": _revision_prompt(
                            payload,
                            previous_output=decoded,
                            error_message=last_error,
                        ),
                    },
                ]

        if turn is None:
            raise RuntimeError(last_error or "Coach model did not return a valid turn.")

        self.last_generation_seconds = time.perf_counter() - generation_start

        logger.info(
            "Coach model generated turn model=%s device=%s elapsed=%.2fs topic=%s",
            self.model_id,
            self.device_label,
            self.last_generation_seconds,
            topic,
        )

        return {
            "provider": "local-coach",
            "model": self.model_id,
            "turn": turn,
        }
