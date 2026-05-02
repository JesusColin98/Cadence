import logging
from transformers import AutoModelForCausalLM, AutoTokenizer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("download_models")

MODEL_ID = "Qwen/Qwen2.5-3B-Instruct"

logger.info(f"Downloading {MODEL_ID}...")
AutoTokenizer.from_pretrained(MODEL_ID)
# We use torch_dtype="auto" and don't specify device_map here to keep it simple during build
# It will default to CPU and download the weights.
AutoModelForCausalLM.from_pretrained(MODEL_ID)

logger.info("Model downloaded successfully.")
