// FILE: src/app/(auth)/layout.tsx
import Image from "next/image";
import type { ReactNode } from "react";
import { SplitText } from "@/components/ui/split-text";

export default async function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <main className="h-screen overflow-hidden bg-[#efe4c8] px-4 py-5 sm:px-6 sm:py-6 lg:px-8">
      <div className="mx-auto flex h-full max-w-6xl items-center justify-center">
        <div className="grid w-full items-center gap-4 lg:grid-cols-[1.02fr_0.98fr] xl:gap-5">
          <section className="hidden min-h-0 rounded-[2.75rem] bg-hunter-green text-bright-snow lg:block">
            <div className="flex h-full min-h-[22rem] flex-col justify-between gap-8 px-7 py-8 sm:px-10 sm:py-10 lg:px-12 lg:py-12">
              <div className="max-w-xl space-y-5">
                <p className="eyebrow text-sm text-yellow-green">
                  Cadence account
                </p>
                <SplitText
                  text="Keep your speaking progress in one place."
                  tag="h1"
                  delay={26}
                  duration={760}
                  className="max-w-lg text-[2.7rem] font-semibold leading-[0.98] sm:text-[3.15rem] lg:text-[3.55rem]"
                />
                <p className="max-w-md text-base leading-8 text-bright-snow/78">
                  Sign in on the web to manage your plan, return to saved practice,
                  and keep every coaching round connected to the same learner profile.
                </p>
              </div>

              <div className="rounded-[2.15rem] bg-[#f6edd8] p-5 text-hunter-green sm:p-6">
                <div className="grid gap-5 sm:grid-cols-[0.94fr_1.06fr] sm:items-center">
                  <div className="space-y-3">
                    <p className="eyebrow text-sm text-sage-green">
                      Web workspace
                    </p>
                    <h2 className="text-[1.55rem] font-semibold leading-tight sm:text-[1.8rem]">
                      Review your path, restart modules, and jump back into practice.
                    </h2>
                    <p className="text-sm leading-7 text-iron-grey">
                      Your account ties together pronunciation drills, conversation coaching, and every module checkpoint.
                    </p>
                  </div>
                  <div className="hidden items-center justify-center sm:flex">
                    <Image
                      src="/illustration/getting-help-1.svg"
                      alt="Learner using Cadence on the web"
                      width={320}
                      height={240}
                      className="h-auto w-full max-w-[15rem] object-contain lg:max-w-[16.5rem]"
                    />
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section className="flex min-h-0 w-full items-center justify-center px-0 py-0 sm:px-2 lg:px-4">
            {children}
          </section>
        </div>
      </div>
    </main>
  );
}
