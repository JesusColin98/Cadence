import type { Metadata } from 'next'
import { DesktopSetup } from '@/components/desktop/desktop-setup'

export const metadata: Metadata = {
  title: 'Desktop Setup',
  robots: { index: false, follow: false },
}

export default function DesktopSetupPage() {
  return <DesktopSetup />
}
