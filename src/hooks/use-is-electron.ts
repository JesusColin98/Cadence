'use client'

import { useState, useEffect, useLayoutEffect } from 'react'

// useLayoutEffect on client (runs before paint = no flash),
// useEffect on server (doesn't run during SSR, avoids the warning).
const useIsomorphicLayoutEffect =
  typeof window !== 'undefined' ? useLayoutEffect : useEffect

/**
 * Returns true when running inside the Cadence Electron desktop app.
 *
 * Uses useLayoutEffect so the sidebar appears synchronously before the first
 * paint — no flash of the web layout. Starts as false on the server so there
 * is no hydration mismatch.
 */
export function useIsElectron(): boolean {
  const [isElectron, setIsElectron] = useState(false)

  useIsomorphicLayoutEffect(() => {
    // window.electron is injected synchronously by the Electron preload script
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    setIsElectron(Boolean((window as any).electron?.isElectron))
  }, [])

  return isElectron
}
