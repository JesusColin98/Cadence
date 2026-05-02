from __future__ import annotations

import io
import json
import logging
import os
import time
import tempfile
from typing import Any

import google.generativeai as genai
import numpy as np
import soundfile as sf
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("cadence.ai_engine.scorer")

DEFAULT_GEMINI_MODEL = os.getenv("GEMINI_MODEL_ID", "gemini-1.5-flash")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

MODEL_NAME = "gemini-cloud"

class PhonemeScorer:
    def __init__(
        self,
        model_name: str = DEFAULT_GEMINI_MODEL,
        reference_synthesizer: Any | None = None,
    ) -> None:
        self.model_name = model_name
        self.reference_synthesizer = reference_synthesizer
        self.model_loaded = False
        self.load_error: str | None = None
        self.last_warmup_seconds: float | None = None

        if not GEMINI_API_KEY:
            self.load_error = "GEMINI_API_KEY is not configured in .env"
            logger.error(self.load_error)
        else:
            genai.configure(api_key=GEMINI_API_KEY)
            self.model_loaded = True

    def get_diagnostics(self) -> dict[str, Any]:
        return {
            "engine": "gemini-cloud",
            "modelName": self.model_name,
            "modelLoaded": self.model_loaded,
            "loadError": self.load_error,
        }

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

    def assess(
        self,
        audio_bytes: bytes,
        target_text: str,
        filename: str | None = None,
    ) -> dict[str, Any]:
        self.warmup()
        
        if not self.model_loaded:
            raise RuntimeError(self.load_error or "The Gemini API is not ready.")

        start_time = time.perf_counter()
        
        try:
            # Get audio duration
            with io.BytesIO(audio_bytes) as bio:
                data, samplerate = sf.read(bio)
                duration = len(data) / samplerate

            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
                tmp.write(audio_bytes)
                tmp_path = tmp.name

            try:
                uploaded_file = genai.upload_file(path=tmp_path, mime_type="audio/wav")
                
                prompt = f"""
                Analyze the pronunciation of the following audio compared to the target text: "{target_text}"
                
                Provide a detailed assessment in JSON format with the following structure:
                {{
                    "targetText": "{target_text}",
                    "ipaTarget": "/<ipa_representation>/",
                    "transcript": "<transcription_of_what_was_heard>",
                    "overallScore": <integer_0_to_100>,
                    "summary": "<one_sentence_summary>",
                    "nextStep": "<one_sentence_advice>",
                    "highlights": [
                        {{
                            "text": "<word>",
                            "status": "correct" | "mixed" | "needs-work",
                            "feedback": "<short_feedback>",
                            "replyStartSec": <start_time_in_audio>,
                            "replyEndSec": <end_time_in_audio>
                        }},
                        ...
                    ],
                    "phonemes": [
                        {{
                            "symbol": "/<phoneme>/",
                            "expected": "/<expected_phoneme>/",
                            "heard": "/<heard_phoneme>/",
                            "accuracy": <integer_0_to_100>,
                            "status": "correct" | "needs-work"
                        }},
                        ...
                    ]
                }}
                
                The audio duration is {duration:.2f} seconds. Ensure the timestamps in 'highlights' are within this range.
                Return ONLY the raw JSON.
                """
                
                model = genai.GenerativeModel(model_name=self.model_name)
                response = model.generate_content([prompt, uploaded_file])
                
                # Extract JSON from response
                text_response = response.text.strip()
                if "```json" in text_response:
                    text_response = text_response.split("```json")[1].split("```")[0].strip()
                elif "```" in text_response:
                    text_response = text_response.split("```")[1].split("```")[0].strip()
                
                assessment = json.loads(text_response)
                
                genai.delete_file(uploaded_file.name)
            finally:
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)

            assessment["engine"] = f"gemini-{self.model_name}"
            assessment["modelReady"] = True
            assessment["loadError"] = None
            
        except Exception as exc:
            logger.exception("Gemini assessment failed")
            raise RuntimeError(f"Gemini assessment failed: {exc}") from exc

        logger.info(
            "Assessment complete. target=%s score=%s elapsed=%.2fs",
            target_text,
            assessment.get("overallScore"),
            time.perf_counter() - start_time,
        )
        return assessment

    def transcribe(
        self,
        audio_bytes: bytes,
        filename: str | None = None,
    ) -> dict[str, Any]:
        # Fallback to a simpler transcription if needed, but we can reuse the same logic or call SpeechTranscriber
        from speech_transcriber import SpeechTranscriber
        transcriber = SpeechTranscriber(model_name=self.model_name)
        return transcriber.transcribe(audio_bytes, filename)
