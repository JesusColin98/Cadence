import { app } from 'electron'

export const isDev = !app.isPackaged
export const APP_NAME = 'Cadence'
export const DEV_PORT = Number(process.env.CADENCE_DEV_SERVER_PORT ?? '3000')
export const PACKAGED_PORT = Number(process.env.CADENCE_DESKTOP_PORT ?? '3130')
export const PORT = isDev ? DEV_PORT : PACKAGED_PORT
export const DEV_SERVER_ORIGIN =
  process.env.CADENCE_DEV_SERVER_URL ?? `http://localhost:${DEV_PORT}`
export const APP_ORIGIN = isDev
  ? DEV_SERVER_ORIGIN
  : `http://127.0.0.1:${PACKAGED_PORT}`

export const DEFAULT_WINDOW_SIZE = {
  width: 1280,
  height: 800,
  minWidth: 960,
  minHeight: 640,
}

export const AUTH_WINDOW_SIZE = {
  width: 1160,
  height: 760,
}

export const SETUP_WINDOW_SIZE = {
  width: 1280,
  height: 800,
}

export const DESKTOP_USER_AGENT_TOKEN = 'CadenceDesktop'
export const DESKTOP_USER_AGENT_SUFFIX =
  `${DESKTOP_USER_AGENT_TOKEN}/${app.getVersion()}`

export const AUTH_PATHS = new Set([
  '/login',
  '/signup',
  '/forgot-password',
  '/reset-password',
])

export const SETUP_PATHS = new Set(['/desktop/setup'])

export const BLOCKED_PATHS = new Set([
  '/',
  '/contact',
  '/help',
  '/terms',
  '/privacy',
  '/pricing',
  '/download',
])

export const resourcesPath = (process as NodeJS.Process & {
  resourcesPath: string
}).resourcesPath
