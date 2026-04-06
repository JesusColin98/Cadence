import { DesktopSidebar } from '@/components/ui/desktop-sidebar'

/**
 * Wraps the (dashboard) route group.
 *
 * Electron: renders the full sidebar + scrollable content layout.
 * Web:      renders children as-is (no-op passthrough).
 */
export function DesktopShell({
  children,
  enabled,
  userId,
  topBar,
}: {
  children: React.ReactNode
  enabled: boolean
  userId?: string | null
  topBar?: React.ReactNode
}) {
  if (!enabled) return <>{topBar}{children}</>

  return (
    <div className="flex h-screen overflow-hidden bg-vanilla-cream">
      <DesktopSidebar userId={userId} />
      <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
        {topBar}
        <div className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden">
        {children}
        </div>
      </div>
    </div>
  )
}
