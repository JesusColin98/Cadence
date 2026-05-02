"""
GeminiCoachEngine: model loading and turn generation using Google Generative AI.
"""
from __future__ import annotations

import logging
import os
import time
from typing import Any

import google.generativeai as genai
from dotenv import load_dotenv

from parsing import clean_model_output, parse_turn_response
from prompts import build_messages

load_dotenv()

logger = logging.getLogger("cadence.coach_engine")

DEFAULT_COACH_MODEL = os.getenv("GEMINI_MODEL_ID", "gemini-1.5-flash")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

class QwenCoachEngine:
    def __init__(self, model_id: str = DEFAULT_COACH_MODEL) -> None:
        self.model_id = model_id
        self.model_loaded = False
        self.load_error: str | None = None
        self.last_warmup_seconds: float | None = None
        self.last_generation_seconds: float | None = None
        
        if not GEMINI_API_KEY:
            self.load_error = "GEMINI_API_KEY is not configured in .env"
            logger.error(self.load_error)
        else:
            genai.configure(api_key=GEMINI_API_KEY)
            self.model_loaded = True

    def warmup(self, force: bool = False) -> None:
        if self.model_loaded and not force:
            return
        
        load_start = time.perf_counter()
        if not GEMINI_API_KEY:
            self.load_error = "GEMINI_API_KEY is not configured in .env"
            self.model_loaded = False
        else:
            genai.configure(api_key=GEMINI_API_KEY)
            self.model_loaded = True
            self.load_error = None
        
        self.last_warmup_seconds = time.perf_counter() - load_start

    def get_status(self) -> dict[str, Any]:
        return {
            "coachReady": self.model_loaded,
            "coachModel": self.model_id,
            "coachDevice": "cloud",
            "coachLoadError": self.load_error,
            "coachLastWarmupSeconds": self.last_warmup_seconds,
            "coachLastGenerationSeconds": self.last_generation_seconds,
        }

    def generate_turn(self, payload: dict[str, Any]) -> dict[str, Any]:
        if not self.model_loaded:
            self.warmup(force=True)

        if not self.model_loaded:
            raise RuntimeError(self.load_error or "Gemini API is not ready.")

        topic = str(payload.get("topic") or "").strip()
        if not topic:
            raise ValueError("A topic is required to start the coach.")

        history = payload.get("history") if isinstance(payload.get("history"), list) else []
        mode = str(payload.get("mode") or "target")

        messages = build_messages(payload)
        
        # Convert messages to Gemini format
        gemini_history = []
        system_instruction = None
        
        for msg in messages:
            if msg["role"] == "system":
                system_instruction = msg["content"]
            else:
                role = "user" if msg["role"] == "user" else "model"
                gemini_history.append({"role": role, "parts": [msg["content"]]})

        generation_start = time.perf_counter()

        model = genai.GenerativeModel(
            model_name=self.model_id,
            system_instruction=system_instruction
        )
        
        # The last message in messages is the user prompt
        user_prompt = gemini_history[-1]["parts"][0]
        chat_history = gemini_history[:-1]

        chat = model.start_chat(history=chat_history)
        response = chat.send_message(user_prompt)
        
        decoded = response.text
        logger.info("Coach Gemini output:\n%s", clean_model_output(decoded))

        turn = parse_turn_response(decoded, mode=mode, history=history)

        self.last_generation_seconds = time.perf_counter() - generation_start
        logger.info(
            "Coach turn generated model=%s elapsed=%.2fs topic=%s",
            self.model_id,
            self.last_generation_seconds,
            topic,
        )

        return {"provider": "gemini-coach", "model": self.model_id, "turn": turn}
