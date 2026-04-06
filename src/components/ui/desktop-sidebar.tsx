'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Settings } from 'griddy-icons'
import { BrandMark } from '@/components/ui/brand-mark'
import { cn } from '@/lib/utils'

const navItems = [
  { href: '/dashboard',    label: 'Home'         },
  { href: '/learn',        label: 'Modules'      },
  { href: '/conversation', label: 'Conversation' },
  { href: '/coach',        label: 'AI Coach'     },
]

export function DesktopSidebar() {
  const pathname = usePathname()

  const isActive = (href: string) =>
    pathname === href || pathname.startsWith(href + '/')

  return (
    <aside className="flex h-screen w-56 shrink-0 flex-col border-r border-alabaster-grey bg-white text-hunter-green">

      {/* ── Traffic-light zone ── */}
      <div className="h-[52px] shrink-0 w-full px-3 pt-2">
        <div
          className="h-full w-full rounded-[18px]"
          style={{ WebkitAppRegion: 'drag' } as React.CSSProperties}
        />
      </div>

      {/* ── Logo ── */}
      <div className="px-4 pb-5">
        <BrandMark />
      </div>

      {/* ── Nav items ── */}
      <nav className="flex flex-1 flex-col gap-0.5 px-4">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={cn(
              'flex items-center rounded-full px-4 py-2 text-sm font-semibold transition-colors',
              isActive(item.href)
                ? 'bg-yellow-green text-hunter-green'
                : 'text-hunter-green hover:bg-vanilla-cream',
            )}
          >
            {item.label}
          </Link>
        ))}
      </nav>

      {/* ── Settings ── */}
      <div className="px-4 pb-5">
        <Link
          href="/profile"
          className={cn(
            'flex items-center gap-2.5 rounded-full px-4 py-2.5 text-sm font-semibold transition-colors',
            isActive('/profile')
              ? 'bg-yellow-green text-hunter-green'
              : 'text-hunter-green hover:bg-vanilla-cream',
          )}
        >
          <Settings size={16} color="currentColor" />
          Settings
        </Link>
      </div>
    </aside>
  )
}
