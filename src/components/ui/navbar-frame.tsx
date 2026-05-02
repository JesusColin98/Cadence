import { cn } from '@/lib/utils'

interface NavbarFrameProps {
  children: React.ReactNode
  variant?: 'default' | 'dark'
}

export function NavbarFrame({
  children,
  variant = 'default',
}: NavbarFrameProps) {
  return (
    <header
      className={cn(
        'rounded-3xl px-5 py-4',
        variant === 'dark'
          ? 'bg-hunter-green text-bright-snow'
          : 'bg-white text-hunter-green',
      )}
    >
      <div className="flex flex-wrap items-center justify-between gap-4 md:flex-nowrap">
        {children}
      </div>
    </header>
  )
}
