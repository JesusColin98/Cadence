import { getRequestRuntime } from '@/lib/runtime/request-runtime'
import { ModuleProgress } from '@/components/ui/module-progress'
import { DesktopTopBar } from '@/components/ui/desktop-top-bar'
import { DesktopShell } from '@/components/ui/desktop-shell'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createSupabaseServerClient()
  const runtime = await getRequestRuntime()
  const isDesktop = runtime === 'desktop'
  const {
    data: { user },
  } = await supabase.auth.getUser()

  return (
    <DesktopShell
      enabled={isDesktop}
      userId={user?.id ?? null}
      topBar={(
        <DesktopTopBar enabled={isDesktop}>
          <ModuleProgress variant="dark" />
        </DesktopTopBar>
      )}
    >
      {children}
    </DesktopShell>
  )
}
