from __future__ import annotations

import logging
import os
import time
import tempfile
from typing import Any

import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("cadence.ai_engine.transcriber")

DEFAULT_GEMINI_MODEL = os.getenv("GEMINI_MODEL_ID", "gemini-1.5-flash")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

class SpeechTranscriber:
    def __init__(self, model_name: str = DEFAULT_GEMINI_MODEL) -> None:
        self.model_name = model_name
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
            "transcriberModel": self.model_name,
            "transcriberReady": self.model_loaded,
            "transcriberLoadError": self.load_error,
            "transcriberDevice": "cloud",
            "transcriberLastWarmupSeconds": self.last_warmup_seconds,
            "transcriberLastGenerationSeconds": self.last_generation_seconds,
        }

    def transcribe(
        self,
        audio_bytes: bytes,
        filename: str | None = None,
    ) -> dict[str, Any]:
        self.warmup()

        if not self.model_loaded:
            raise RuntimeError(self.load_error or "The Gemini API is not ready.")

        generation_start = time.perf_counter()
        
        try:
            # Gemini 1.5 can process audio bytes directly if uploaded to the Files API
            # or if sent as a part in some SDKs. The python SDK supports uploading files.
            
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
                tmp.write(audio_bytes)
                tmp_path = tmp.name
                
            try:
                # Upload the file
                uploaded_file = genai.upload_file(path=tmp_path, mime_type="audio/wav")
                
                # Wait for processing (usually very fast for small files)
                # For small clips we can just send it.
                
                model = genai.GenerativeModel(model_name=self.model_name)
                response = model.generate_content([
                    "Transcribe the following audio exactly as spoken. Output ONLY the transcript text.",
                    uploaded_file
                ])
                
                transcription = response.text.strip()
                
                # Delete the file from Gemini
                genai.delete_file(uploaded_file.name)
            finally:
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
            
            self.last_generation_seconds = time.perf_counter() - generation_start
        except Exception as exc:
            logger.exception("Gemini transcription failed")
            raise RuntimeError(f"Gemini transcription failed: {exc}") from exc

        logger.info(
            "Gemini transcription complete model=%s elapsed=%.2fs transcript=%s",
            self.model_name,
            self.last_generation_seconds or 0.0,
            transcription,
        )

        return {
            "transcript": transcription,
            "engine": "gemini-cloud",
            "modelReady": self.model_loaded,
            "loadError": self.load_error,
        }
