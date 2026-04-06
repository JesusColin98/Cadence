import { app, BrowserWindow, type UtilityProcess } from 'electron'
import { join } from 'path'
import { DesktopSetupManager } from './setup-manager'
import {
  APP_NAME,
  APP_ORIGIN,
  AUTH_PATHS,
  AUTH_WINDOW_SIZE,
  BLOCKED_PATHS,
  DEFAULT_WINDOW_SIZE,
  DESKTOP_USER_AGENT_SUFFIX,
  PORT,
  SETUP_PATHS,
  SETUP_WINDOW_SIZE,
  isDev,
  resourcesPath,
} from './main/constants'
import { buildMenu } from './main/menu'
import { startNextServer } from './main/next-server'
import { createCadenceWindow } from './main/browser-window'
import { registerSetupIpc } from './main/setup-ipc'

const ICON_PATH = join(__dirname, '../assets/icon.icns')
const PRELOAD_PATH = join(__dirname, 'preload.js')

let mainWindow: BrowserWindow | null = null
let nextServer: UtilityProcess | null = null
let setupManager: DesktopSetupManager | null = null
let disposeSetupIpc: (() => void) | null = null

app.setName(APP_NAME)

function debugLog(message: string, detail?: unknown): void {
  if (!isDev) {
    return
  }

  if (typeof detail === 'undefined') {
    console.log(`[desktop] ${message}`)
    return
  }

  console.log(`[desktop] ${message}`, detail)
}

async function getDesktopHomePath(): Promise<string> {
  try {
    const setupState = setupManager ? await setupManager.getState() : null
    if (setupState && setupState.phase !== 'ready') {
      return '/desktop/setup'
    }
  } catch {
    // Fall back to the authenticated app shell if setup state can't be read.
  }

  return '/dashboard'
}

async function bootWindow(): Promise<void> {
  mainWindow = await createCadenceWindow({
    appName: APP_NAME,
    appOrigin: APP_ORIGIN,
    isDev,
    iconPath: ICON_PATH,
    preloadPath: PRELOAD_PATH,
    defaultWindowSize: DEFAULT_WINDOW_SIZE,
    authWindowSize: AUTH_WINDOW_SIZE,
    setupWindowSize: SETUP_WINDOW_SIZE,
    authPaths: AUTH_PATHS,
    setupPaths: SETUP_PATHS,
    blockedPaths: BLOCKED_PATHS,
    desktopUserAgentSuffix: DESKTOP_USER_AGENT_SUFFIX,
    resolveDesktopHomePath: getDesktopHomePath,
    onStartBundledServer: async () => {
      if (nextServer) {
        return
      }

      nextServer = await startNextServer({
        appOrigin: APP_ORIGIN,
        port: PORT,
        resourcesPath,
      })
      nextServer.on('exit', () => {
        nextServer = null
      })
    },
    debugLog,
    onClosed: () => {
      mainWindow = null
    },
  })
}

app.whenReady().then(async () => {
  buildMenu(APP_NAME)

  setupManager = new DesktopSetupManager()
  disposeSetupIpc = registerSetupIpc({
    setupManager,
    getMainWindow: () => mainWindow,
  })

  await bootWindow()
})

app.on('window-all-closed', () => {
  nextServer?.kill()
  nextServer = null

  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    void bootWindow()
  }
})

app.on('before-quit', () => {
  disposeSetupIpc?.()
  disposeSetupIpc = null
  setupManager?.dispose()
  nextServer?.kill()
  nextServer = null
})
