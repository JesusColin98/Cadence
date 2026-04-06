import { app } from 'electron'

export const AI_ENGINE_URL = 'http://127.0.0.1:8000/health'
export const COACH_ENGINE_URL = 'http://127.0.0.1:8001/coach-status'
export const DESKTOP_WEB_APP_URL = app.isPackaged
  ? `http://127.0.0.1:${process.env.CADENCE_DESKTOP_PORT ?? '3130'}`
  : `http://localhost:${process.env.CADENCE_DEV_SERVER_PORT ?? '3000'}`
export const INSTALL_TIMEOUT_MS = 20 * 60 * 1000
export const POLL_INTERVAL_MS = 5000
export const HEALTH_CHECK_TIMEOUT_MS = 1500
export const INSTALL_STRATEGY = 'native-sidecar-beta' as const
export const MIN_DESKTOP_PYTHON_MAJOR = 3
export const MIN_DESKTOP_PYTHON_MINOR = 10

export const DEFAULT_DESKTOP_SPEECH_MODEL_ID =
  'facebook/wav2vec2-xlsr-53-espeak-cv-ft'
export const DEFAULT_DESKTOP_TRANSCRIBER_MODEL_ID =
  process.env.CADENCE_ASR_MODEL ?? 'openai/whisper-base.en'
export const DEFAULT_DESKTOP_TTS_MODEL_ID =
  process.env.OMNIVOICE_MODEL_NAME ?? 'k2-fsa/OmniVoice'
export const DEFAULT_DESKTOP_TTS_LANGUAGE =
  process.env.OMNIVOICE_LANGUAGE ?? 'English'
export const DEFAULT_DESKTOP_TTS_INSTRUCT =
  process.env.OMNIVOICE_INSTRUCT ?? 'elderly, moderate pitch, american accent'
export const DEFAULT_DESKTOP_COACH_MODEL_ID =
  process.env.CADENCE_DESKTOP_COACH_MODEL_ID ?? 'Qwen/Qwen2.5-0.5B-Instruct'

export const COMMAND_ENV = {
  ...process.env,
  PATH: [
    process.env.PATH,
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
  ]
    .filter(Boolean)
    .join(':'),
}
