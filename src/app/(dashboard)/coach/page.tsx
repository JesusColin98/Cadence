// FILE: src/app/(dashboard)/coach/page.tsx
import type { Metadata } from "next";
import { AiCoachPlayground } from "@/components/coach/AiCoachPlayground";
import { ModuleProgress } from "@/components/ui/module-progress";
import { Navbar } from "@/components/ui/navbar";
import { requireAppUser } from "@/lib/app-session";
import { cn } from "@/lib/utils";

export const metadata: Metadata = {
  title: "AI Coach",
  robots: { index: false, follow: false },
};

export default async function CoachPage() {
  const session = await requireAppUser("/coach");

  return (
    <main
      data-lenis-prevent
      className={cn(
        "box-border flex w-full flex-col overflow-hidden overscroll-none p-4 sm:p-5 lg:p-6",
        "h-[100dvh] max-h-[100dvh]",
      )}
    >
      <div className="mx-auto flex w-full max-w-[1600px] shrink-0 flex-col gap-4">
        <Navbar current="coach" />
        <ModuleProgress />
      </div>
      <div className="mx-auto flex min-h-0 w-full max-w-[1600px] flex-1 flex-col overflow-hidden">
        <AiCoachPlayground
          userId={session.user.id}
          showOverviewCard={true}
          showEngineDiagnostics={session.mode === "local"}
        />
      </div>
    </main>
  );
}
