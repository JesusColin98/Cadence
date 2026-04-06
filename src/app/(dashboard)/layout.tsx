import { ModuleProgress } from '@/components/ui/module-progress'
import { DesktopTopBar } from '@/components/ui/desktop-top-bar'
import { DesktopShell } from '@/components/ui/desktop-shell'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <DesktopShell>
      <DesktopTopBar>
        <ModuleProgress variant="dark" />
      </DesktopTopBar>
      {children}
    </DesktopShell>
  )
}
