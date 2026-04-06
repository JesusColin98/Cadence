'use client'

import { startTransition, useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Activity, ArrowRight, Microphone } from 'griddy-icons'
import { Button } from '@/components/ui/button'
import { Card, CardDescription, CardTitle } from '@/components/ui/card'
import { useIsElectron } from '@/hooks/use-is-electron'
import { cn } from '@/lib/utils'

const INITIAL_STATE: DesktopSetupState = {
  phase: 'checking',
  currentStep: 'Checking what is already ready.',
  percent: 5,
  aiEngineReady: false,
  coachEngineReady: false,
  transcriberReady: false,
  ttsReady: false,
  modelsReady: false,
  error: null,
  logsPath: null,
  installStrategy: 'docker-beta',
  isPackaged: false,
  runtimeDetails: null,
}

function StatusPill({
  label,
  ready,
}: {
  label: string
  ready: boolean
}) {
  return (
    <div
      className={cn(
        'rounded-full px-4 py-2 text-sm font-semibold whitespace-nowrap',
        ready
          ? 'bg-yellow-green text-hunter-green'
          : 'bg-vanilla-cream text-iron-grey',
      )}
    >
      {label}
    </div>
  )
}

export function DesktopSetup() {
  const router = useRouter()
  const isElectron = useIsElectron()
  const [state, setState] = useState<DesktopSetupState>(INITIAL_STATE)
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    if (!isElectron || !window.cadenceDesktopSetup) {
      setIsLoading(false)
      return
    }

    let active = true

    const applyState = (nextState: DesktopSetupState | null) => {
      if (!active || !nextState) {
        return
      }

      setState(nextState)

      if (nextState.phase === 'ready') {
        startTransition(() => {
          router.replace('/dashboard')
        })
      }
    }

    window.cadenceDesktopSetup
      .getState()
      .then((nextState) => {
        applyState(nextState)
      })
      .finally(() => {
        if (active) {
          setIsLoading(false)
        }
      })

    const unsubscribe = window.cadenceDesktopSetup.onProgress((nextState) => {
      applyState(nextState)
    })

    return () => {
      active = false
      unsubscribe()
    }
  }, [isElectron, router])

  const progressWidth = `${Math.max(state.percent, 6)}%`
  const primaryLabel =
    state.phase === 'ready'
      ? 'Open Cadence'
      : state.phase === 'error'
        ? 'Retry setup'
        : 'Set up Cadence'

  async function handlePrimaryAction() {
    if (!window.cadenceDesktopSetup) {
      return
    }

    if (state.phase === 'ready') {
      startTransition(() => {
        router.replace('/dashboard')
      })
      return
    }

    setIsSubmitting(true)

    try {
      if (state.phase === 'error') {
        await window.cadenceDesktopSetup.retry()
      } else {
        await window.cadenceDesktopSetup.install()
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleOpenLogs() {
    await window.cadenceDesktopSetup?.openLogs()
  }

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(167,201,87,0.3),_transparent_35%),linear-gradient(180deg,_#f2e8cf_0%,_#ece1c3_100%)] px-4 py-6 sm:px-6 lg:px-8">
      <div className="mx-auto flex min-h-[calc(100vh-3rem)] w-full max-w-6xl items-center justify-center">
        <section className="grid w-full max-w-5xl gap-4 lg:grid-cols-[1.08fr_0.92fr] lg:items-center">
          <Card className="bg-hunter-green text-bright-snow">
            <div className="space-y-5">
              <div className="inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-2 text-yellow-green">
                <Microphone size={18} filled color="currentColor" />
                <span className="eyebrow text-sm">Desktop Setup</span>
              </div>

              <div className="space-y-3">
                <h1 className="text-4xl font-semibold text-bright-snow sm:text-5xl">
                  Getting Cadence ready for your first session.
                </h1>
                <p className="max-w-2xl text-base leading-7 text-bright-snow/80">
                  Cadence is preparing the speaking tools it needs so practice,
                  listening, and coach responses all work smoothly. The first
                  setup can take a few minutes.
                </p>
              </div>

              <div className="rounded-3xl bg-white/10 px-5 py-5">
                <div className="flex items-center justify-between gap-4">
                  <div>
                    <p className="eyebrow text-sm text-yellow-green/80">Current step</p>
                    <p className="mt-2 text-lg font-semibold text-bright-snow">
                      {isLoading ? 'Loading installer state…' : state.currentStep}
                    </p>
                  </div>
                  <div className="rounded-full bg-white/12 px-4 py-3 text-sm font-semibold text-bright-snow">
                    {state.percent}%
                  </div>
                </div>

                <div className="mt-5 rounded-full bg-white/12 p-2">
                  <div
                    className="h-4 rounded-full bg-yellow-green transition-[width] duration-500"
                    style={{ width: progressWidth }}
                  />
                </div>
              </div>

              <div className="flex flex-wrap gap-3">
                <Button
                  variant="secondary"
                  onClick={() => void handlePrimaryAction()}
                  disabled={isLoading || isSubmitting || !isElectron}
                >
                  {primaryLabel}
                  <ArrowRight size={16} color="currentColor" />
                </Button>

                <Button
                  variant="ghost"
                  className="bg-white/12 text-bright-snow hover:bg-white/18"
                  onClick={() => void handleOpenLogs()}
                  disabled={!isElectron}
                >
                  View details
                </Button>
              </div>

              {state.error ? (
                <div className="rounded-3xl bg-blushed-brick px-4 py-3 text-sm text-bright-snow">
                  {state.error}
                </div>
              ) : null}
            </div>
          </Card>

          <Card className="bg-white">
            <div className="space-y-6">
              <div className="space-y-2">
                <div className="inline-flex items-center gap-2 rounded-full bg-sage-green/15 px-4 py-2 text-sage-green">
                  <Activity size={18} filled color="currentColor" />
                  <span className="eyebrow text-sm">Runtime Health</span>
                </div>
                <CardTitle>What Cadence is preparing on this machine</CardTitle>
                <CardDescription>
                  The first launch can take a little while because Cadence is
                  getting its voice, listening, and coach tools ready in the
                  background.
                </CardDescription>
              </div>

              <div className="flex flex-wrap gap-3">
                <StatusPill label="Speech checks" ready={state.aiEngineReady} />
                <StatusPill label="Listening" ready={state.transcriberReady} />
                <StatusPill label="Coach voice" ready={state.ttsReady} />
                <StatusPill label="Coach replies" ready={state.coachEngineReady} />
              </div>

              <div className="grid gap-3 sm:grid-cols-2">
                <div className="rounded-3xl bg-vanilla-cream px-5 py-5">
                  <p className="eyebrow text-sm text-sage-green">Setup style</p>
                  <p className="mt-3 text-2xl font-semibold text-hunter-green">
                    Automatic setup
                  </p>
                  <p className="mt-2 text-sm leading-7 text-iron-grey">
                    Cadence handles the background preparation and opens the app
                    as soon as everything is ready.
                  </p>
                </div>

                <div className="rounded-3xl bg-vanilla-cream px-5 py-5">
                  <p className="eyebrow text-sm text-sage-green">Ready to enter</p>
                  <p className="mt-3 text-2xl font-semibold text-hunter-green">
                    {state.modelsReady ? 'Yes' : 'Not yet'}
                  </p>
                  <p className="mt-2 text-sm leading-7 text-iron-grey">
                    Cadence opens the app as soon as the speech and coach models
                    report healthy.
                  </p>
                </div>
              </div>

              {!isElectron ? (
                <div className="rounded-3xl bg-vanilla-cream px-5 py-5 text-sm leading-7 text-iron-grey">
                  This page is meant for the desktop app. Open Cadence Desktop
                  to run the setup flow.
                </div>
              ) : null}
            </div>
          </Card>
        </section>
      </div>
    </div>
  )
}
