import { headers } from 'next/headers'

export type AppRuntime = 'web'

export async function getRequestRuntime(): Promise<AppRuntime> {
  return 'web'
}

export function getRuntimeFromUserAgent(
  userAgent: string | null | undefined,
): AppRuntime {
  return 'web'
}

export function getRequestRuntimeFromRequest(request: Request): AppRuntime {
  return 'web'
}

export function getAiEngineUrl(runtime: AppRuntime): string {
  return normalizeBaseUrl(process.env.AI_ENGINE_URL, 'http://127.0.0.1:8000')
}

export function getCoachEngineUrl(runtime: AppRuntime): string {
  return normalizeBaseUrl(
    process.env.AI_COACH_ENGINE_URL,
    'http://127.0.0.1:8001',
  )
}

export function getAiEngineUrlForRequest(request: Request): string {
  return getAiEngineUrl('web')
}

export function getCoachEngineUrlForRequest(request: Request): string {
  return getCoachEngineUrl('web')
}

function normalizeBaseUrl(value: string | undefined, fallback: string): string {
  return value?.replace(/\/$/, '') ?? fallback
}
