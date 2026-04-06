// FILE: src/app/(auth)/layout.tsx
import Image from "next/image";
import type { ReactNode } from "react";
import { SplitText } from "@/components/ui/split-text";

export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <main className="h-screen overflow-hidden bg-[#efe4c8]">
      <div className="grid h-full min-h-0 md:grid-cols-[1.06fr_0.94fr]">
        <section className="min-h-0 bg-hunter-green text-bright-snow md:rounded-r-[2.35rem]">
          <div className="flex h-full min-h-0 flex-col justify-between gap-6 px-6 pb-6 pt-[4.9rem] sm:px-8 sm:pb-8 sm:pt-[5.35rem] lg:px-10 lg:pb-10 lg:pt-[5.6rem]">
            <div className="max-w-xl space-y-4">
                <SplitText
                  text="Keep your pronunciation practice moving."
                  tag="h1"
                  delay={30}
                  duration={760}
                  className="max-w-md text-[2.5rem] font-semibold leading-[1.02] sm:text-[2.9rem] lg:text-[3.2rem]"
                />
                <p className="max-w-md text-sm leading-7 text-bright-snow/78 sm:text-[0.98rem]">
                  Log in, recover access, and return to the next speaking round without losing progress.
                </p>
              </div>

              <div className="rounded-[2rem] bg-vanilla-cream p-4 text-hunter-green sm:p-5">
                <div className="grid gap-3 sm:grid-cols-[0.96fr_1.04fr] sm:items-center">
                  <div className="space-y-2">
                    <p className="eyebrow text-sm text-sage-green">
                      Practice flow
                    </p>
                    <h2 className="text-[1.45rem] font-semibold leading-tight sm:text-[1.65rem]">
                      One account for progress, streaks, and saved takes.
                    </h2>
                    <p className="text-sm leading-7 text-iron-grey">
                      Return to your studio and pick up exactly where the last speaking round ended.
                    </p>
                  </div>
                  <div className="hidden items-center justify-center sm:flex">
                    <Image
                      src="/illustration/progress-1.svg"
                      alt="Learner illustration"
                      width={280}
                      height={220}
                      className="h-auto w-full max-w-[12.5rem] object-contain lg:max-w-[14rem]"
                    />
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section className="flex min-h-0 items-center justify-center bg-[#efe4c8] px-4 py-4 sm:px-6 sm:py-6 lg:px-8">
            {children}
          </section>
      </div>
    </main>
  );
}
