// FILE: src/app/coach/page.tsx
import type { Metadata } from "next";
import { redirect } from "next/navigation";

export const metadata: Metadata = {
  title: "AI Coach",
  robots: { index: false, follow: false },
};
import { AiCoachPlayground } from "@/components/coach/AiCoachPlayground";
import { ModuleProgress } from "@/components/ui/module-progress";
import { Navbar } from "@/components/ui/navbar";
import { getRequestRuntime } from "@/lib/runtime/request-runtime";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export default async function CoachPage() {
  const supabase = await createSupabaseServerClient();
  const runtime = await getRequestRuntime();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  return (
    <main className="min-h-screen p-4 sm:p-5 lg:p-6 flex flex-col items-center">
      <div className="mx-auto flex w-full max-w-[1600px] flex-col gap-4">
        <Navbar current="coach" />
        <ModuleProgress />
        <AiCoachPlayground
          userId={user.id}
          showOverviewCard={runtime !== "desktop"}
        />
      </div>
    </main>
  );
}
