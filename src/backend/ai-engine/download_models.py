import os
import logging
from huggingface_hub import hf_hub_download
from transformers import Wav2Vec2FeatureExtractor, Wav2Vec2ForCTC, WhisperForConditionalGeneration, WhisperProcessor

# Configure logging to see progress
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("download_models")

# Models to download
WAV2VEC_MODEL = "facebook/wav2vec2-xlsr-53-espeak-cv-ft"
WAV2VEC_REVISION = "3e836924cfd3b858a0bbdbc1f7ef412105d00446"
WHISPER_MODEL = "openai/whisper-base.en"
OMNIVOICE_MODEL = "k2-fsa/OmniVoice"

logger.info(f"Downloading {WAV2VEC_MODEL}...")
hf_hub_download(repo_id=WAV2VEC_MODEL, filename="vocab.json", revision=WAV2VEC_REVISION)
hf_hub_download(repo_id=WAV2VEC_MODEL, filename="model.safetensors", revision=WAV2VEC_REVISION)
Wav2Vec2FeatureExtractor.from_pretrained(WAV2VEC_MODEL, revision=WAV2VEC_REVISION)
Wav2Vec2ForCTC.from_pretrained(WAV2VEC_MODEL, revision=WAV2VEC_REVISION, use_safetensors=True)

logger.info(f"Downloading {WHISPER_MODEL}...")
WhisperProcessor.from_pretrained(WHISPER_MODEL)
WhisperForConditionalGeneration.from_pretrained(WHISPER_MODEL)

logger.info(f"Downloading {OMNIVOICE_MODEL}...")
try:
    from omnivoice import OmniVoice
    # Load to CPU just to trigger download/caching
    OmniVoice.from_pretrained(OMNIVOICE_MODEL, device_map="cpu")
except Exception as e:
    logger.warning(f"Failed to pre-download OmniVoice via its loader: {e}")
    # Fallback to manual download if the loader fails during build (e.g. due to missing audio libs)
    from huggingface_hub import snapshot_download
    snapshot_download(repo_id=OMNIVOICE_MODEL)

logger.info("All models downloaded successfully.")
