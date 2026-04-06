import { contextBridge, ipcRenderer } from 'electron'

function markElectronDocument() {
  if (document.documentElement) {
    document.documentElement.classList.add('electron')
    return
  }

  window.addEventListener(
    'DOMContentLoaded',
    () => {
      document.documentElement?.classList.add('electron')
    },
    { once: true },
  )
}

// Expose a minimal, safe API to the renderer (the Next.js app).
// Do NOT expose ipcRenderer directly — only wrap specific channels you need.
contextBridge.exposeInMainWorld('electron', {
  isElectron: true,
  platform: process.platform,
  openDevTools: () => ipcRenderer.invoke('desktop:open-devtools'),
})

contextBridge.exposeInMainWorld('cadenceDesktopSetup', {
  getState: () => ipcRenderer.invoke('desktop-setup:get-state'),
  getRuntimeDetails: () => ipcRenderer.invoke('desktop-setup:get-runtime-details'),
  install: () => ipcRenderer.invoke('desktop-setup:install'),
  retry: () => ipcRenderer.invoke('desktop-setup:retry'),
  openLogs: () => ipcRenderer.invoke('desktop-setup:open-logs'),
  openLocation: (location: string) =>
    ipcRenderer.invoke('desktop-setup:open-location', location),
  onProgress: (listener: (state: unknown) => void) => {
    const wrapped = (_event: unknown, state: unknown) => listener(state)
    ipcRenderer.on('desktop-setup:state', wrapped)
    return () => ipcRenderer.removeListener('desktop-setup:state', wrapped)
  },
})

markElectronDocument()
window.dispatchEvent(new Event('cadence-electron-ready'))
