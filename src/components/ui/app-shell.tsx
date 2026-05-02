'use client'

import { SmoothScroll } from '@/components/ui/smooth-scroll'

export function AppShell({
  children,
}: {
  children: React.ReactNode
}) {
  return <SmoothScroll>{children}</SmoothScroll>
}
