import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { AiCoachHistory } from "@/components/coach/AiCoachHistory";
import { ModuleProgress } from "@/components/ui/module-progress";
import { Navbar } from "@/components/ui/navbar";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = {
  title: "AI Coach History",
  robots: { index: false, follow: false },
};

export default async function CoachHistoryPage() {
  const supabase = await createSupabaseServerClient();
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
        <AiCoachHistory userId={user.id} />
      </div>
    </main>
  );
}
