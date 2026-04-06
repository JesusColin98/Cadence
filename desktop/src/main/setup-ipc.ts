import { BrowserWindow, ipcMain } from 'electron'
import { DesktopSetupManager } from '../setup-manager'
import type { DesktopRuntimeLocation } from '../setup-manager'

export function registerSetupIpc({
  setupManager,
  getMainWindow,
}: {
  setupManager: DesktopSetupManager
  getMainWindow: () => BrowserWindow | null
}): () => void {
  const unsubscribe = setupManager.onState((state) => {
    const mainWindow = getMainWindow()
    if (!mainWindow || mainWindow.isDestroyed()) {
      return
    }

    mainWindow.webContents.send('desktop-setup:state', state)
  })

  ipcMain.handle('desktop-setup:get-state', async () => {
    return setupManager.getState()
  })

  ipcMain.handle('desktop-setup:get-runtime-details', async () => {
    const state = await setupManager.getState()
    return state.runtimeDetails ?? null
  })

  ipcMain.handle('desktop-setup:install', async () => {
    return setupManager.install()
  })

  ipcMain.handle('desktop-setup:retry', async () => {
    return setupManager.retry()
  })

  ipcMain.handle('desktop-setup:open-logs', async () => {
    const mainWindow = getMainWindow()
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.openDevTools({ mode: 'detach', activate: true })
    }

    await setupManager.openLogs()
    return null
  })

  ipcMain.handle('desktop-setup:open-location', async (_event, location: string) => {
    await setupManager.openLocation(location as DesktopRuntimeLocation)
    return null
  })

  ipcMain.handle('desktop:open-devtools', async () => {
    const mainWindow = getMainWindow()
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.openDevTools({ mode: 'detach', activate: true })
    }

    return null
  })

  return () => {
    unsubscribe()
    ipcMain.removeHandler('desktop-setup:get-state')
    ipcMain.removeHandler('desktop-setup:get-runtime-details')
    ipcMain.removeHandler('desktop-setup:install')
    ipcMain.removeHandler('desktop-setup:retry')
    ipcMain.removeHandler('desktop-setup:open-logs')
    ipcMain.removeHandler('desktop-setup:open-location')
    ipcMain.removeHandler('desktop:open-devtools')
  }
}
