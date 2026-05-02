'use client'

interface ModuleProgressFrameProps {
  children: React.ReactNode
}

export function ModuleProgressFrame({
  children,
}: ModuleProgressFrameProps) {
  return (
    <div className="w-full">
      <div className="mx-auto flex max-w-4xl flex-col gap-4 rounded-[2rem] bg-white px-5 py-4 sm:px-6 lg:flex-row lg:items-center">
        {children}
      </div>
    </div>
  )
}
