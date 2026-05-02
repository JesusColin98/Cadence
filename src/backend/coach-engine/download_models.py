import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("download_models")

logger.info("Local models are disabled. Gemini cloud engine is active.")
logger.info("No models to download.")
