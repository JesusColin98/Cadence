import { app, shell } from 'electron'
import { spawn } from 'child_process'
import { EventEmitter } from 'events'
import { appendFile, mkdir, readFile, writeFile } from 'fs/promises'
import { existsSync } from 'fs'
import { join } from 'path'

const AI_ENGINE_URL = 'http://127.0.0.1:8000/health'
const COACH_ENGINE_URL = 'http://127.0.0.1:8001/coach-status'
const DESKTOP_WEB_APP_URL = 'http://localhost:3000'
const COMPOSE_PROJECT_NAME = 'cadence-desktop-beta'
const INSTALL_TIMEOUT_MS = 20 * 60 * 1000
const POLL_INTERVAL_MS = 5000
const DEFAULT_DESKTOP_SPEECH_MODEL_ID = 'facebook/wav2vec2-xlsr-53-espeak-cv-ft'
const DEFAULT_DESKTOP_TRANSCRIBER_MODEL_ID =
  process.env.CADENCE_ASR_MODEL ?? 'openai/whisper-base.en'
const DEFAULT_DESKTOP_TTS_MODEL_ID =
  process.env.OMNIVOICE_MODEL_NAME ?? 'k2-fsa/OmniVoice'
const DEFAULT_DESKTOP_TTS_LANGUAGE =
  process.env.OMNIVOICE_LANGUAGE ?? 'English'
const DEFAULT_DESKTOP_TTS_INSTRUCT =
  process.env.OMNIVOICE_INSTRUCT ?? 'elderly, moderate pitch, american accent'
const DEFAULT_DESKTOP_COACH_MODEL_ID =
  process.env.CADENCE_DESKTOP_COACH_MODEL_ID ?? 'Qwen/Qwen2.5-0.5B-Instruct'

const COMMAND_ENV = {
  ...process.env,
  PATH: [
    process.env.PATH,
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
    '/Applications/Docker.app/Contents/Resources/bin',
  ]
    .filter(Boolean)
    .join(':'),
}

export type DesktopSetupPhase =
  | 'idle'
  | 'checking'
  | 'installing'
  | 'starting-services'
  | 'verifying'
  | 'ready'
  | 'error'

export interface DesktopSetupState {
  phase: DesktopSetupPhase
  currentStep: string | null
  percent: number
  aiEngineReady: boolean
  coachEngineReady: boolean
  transcriberReady: boolean
  ttsReady: boolean
  modelsReady: boolean
  error: string | null
  logsPath: string | null
  installStrategy: 'docker-beta'
  isPackaged: boolean
  runtimeDetails: DesktopRuntimeDetails | null
}

export interface DesktopRuntimeDetails {
  appVersion: string
  installStrategy: 'docker-beta'
  isPackaged: boolean
  lastReadyAt: string | null
  setupRoot: string
  runtimeDir: string
  modelsDir: string
  huggingFaceDir: string
  composeFilePath: string
  composeFilePresent: boolean
  logsPath: string
  setupManifestPresent: boolean
  endpoints: {
    webApp: string
    aiEngine: string
    coachEngine: string
  }
  availability: {
    huggingFaceTokenConfigured: boolean
  }
  aiEngine: {
    modelId: string
    ready: boolean
    loadError: string | null
    device: string | null
  }
  transcriber: {
    modelId: string
    ready: boolean
    loadError: string | null
    device: string | null
  }
  tts: {
    modelId: string
    ready: boolean
    loadError: string | null
    device: string | null
    language: string
    instruct: string
  }
  coach: {
    modelId: string
    ready: boolean
    loadError: string | null
    device: string | null
    provider: string
    transformersVersion: string | null
  }
}

export type DesktopRuntimeLocation =
  | 'setupRoot'
  | 'runtimeDir'
  | 'modelsDir'
  | 'huggingFaceDir'
  | 'logsPath'
  | 'composeFilePath'

interface SetupManifest {
  version: 1
  appVersion: string
  lastReadyAt: string | null
}

interface AiEngineHealthPayload {
  model?: string
  modelReady?: boolean
  loadError?: string | null
  hfTokenConfigured?: boolean
  diagnostics?: {
    modelName?: string
    loadError?: string | null
    hfTokenConfigured?: boolean
    device?: string | null
  }
  ttsModel?: string
  ttsLanguage?: string
  ttsInstruct?: string
  transcriberReady?: boolean
  transcriberModel?: string
  transcriberLoadError?: string | null
  transcriberDevice?: string | null
  ttsReady?: boolean
  ttsLoadError?: string | null
  ttsDevice?: string | null
}

interface CoachEngineHealthPayload {
  ready?: boolean
  provider?: string
  model?: string
  coachReady?: boolean
  coachModel?: string
  coachDevice?: string | null
  coachLoadError?: string | null
  coachTransformersVersion?: string | null
}

interface HealthSnapshot {
  aiEngineReady: boolean
  coachEngineReady: boolean
  transcriberReady: boolean
  ttsReady: boolean
  modelsReady: boolean
}

interface RuntimeFailureSnapshot {
  type: 'coach-oom'
  message: string
}

interface CommandResult {
  stdout: string
  stderr: string
  exitCode: number | null
}

interface RunCommandOptions {
  allowFailure?: boolean
  onStdoutChunk?: (chunk: string) => void
  onStderrChunk?: (chunk: string) => void
}

type StateListener = (state: DesktopSetupState) => void

export class DesktopSetupManager {
  private readonly emitter = new EventEmitter()
  private readonly setupRoot = join(app.getPath('userData'), 'desktop-runtime')
  private readonly logsDir = join(this.setupRoot, 'logs')
  private readonly runtimeDir = join(this.setupRoot, 'runtime')
  private readonly modelsDir = join(this.setupRoot, 'models')
  private readonly setupFilePath = join(this.setupRoot, 'setup.json')
  private readonly logFilePath = join(this.logsDir, 'desktop-setup.log')
  private readonly composeFilePath = join(this.runtimeDir, 'docker-compose.ai.yml')

  private installPromise: Promise<void> | null = null

  private state: DesktopSetupState = {
    phase: 'idle',
    currentStep: null,
    percent: 0,
    aiEngineReady: false,
    coachEngineReady: false,
    transcriberReady: false,
    ttsReady: false,
    modelsReady: false,
    error: null,
    logsPath: this.logFilePath,
    installStrategy: 'docker-beta',
    isPackaged: app.isPackaged,
    runtimeDetails: null,
  }

  onState(listener: StateListener): () => void {
    this.emitter.on('state', listener)
    return () => this.emitter.off('state', listener)
  }

  async getState(): Promise<DesktopSetupState> {
    if (this.installPromise) {
      return this.state
    }

    return this.refreshState()
  }

  async refreshState(): Promise<DesktopSetupState> {
    await this.ensureDirectories()
    const runtime = await this.inspectRuntime()
    const health = runtime.health
    const manifest = await this.readManifest()

    if (health.modelsReady) {
      const lastReadyAt = manifest?.lastReadyAt ?? new Date().toISOString()
      await this.persistManifest({
        version: 1,
        appVersion: app.getVersion(),
        lastReadyAt,
      })

      return this.setState({
        ...health,
        phase: 'ready',
        currentStep: 'Cadence is ready to open.',
        percent: 100,
        error: null,
        runtimeDetails: {
          ...runtime.details,
          lastReadyAt,
        },
      })
    }

    return this.setState({
      ...health,
      phase: 'idle',
      currentStep: manifest?.lastReadyAt
        ? 'Cadence needs a quick repair before it can open.'
        : 'Finish setup to get Cadence ready on this Mac.',
      percent: 0,
      error: null,
      runtimeDetails: runtime.details,
    })
  }

  async install(): Promise<DesktopSetupState> {
    if (!this.installPromise) {
      this.installPromise = this.runInstall().finally(() => {
        this.installPromise = null
      })
    }

    return this.state
  }

  async retry(): Promise<DesktopSetupState> {
    return this.install()
  }

  async openLogs(): Promise<void> {
    await this.ensureDirectories()
    try {
      const compose = await this.detectComposeCommand()
      if (compose && existsSync(this.composeFilePath)) {
        const result = await this.runCommand(
          compose.command,
          [
            ...compose.argsPrefix,
            '-p',
            COMPOSE_PROJECT_NAME,
            '-f',
            this.composeFilePath,
            'logs',
            '--no-color',
          ],
          { allowFailure: true },
        )

        if (result.stdout || result.stderr) {
          await this.writeLog('----- docker compose logs -----')
          if (result.stdout) {
            await this.writeLog(result.stdout.trim())
          }
          if (result.stderr) {
            await this.writeLog(result.stderr.trim())
          }
        }
      }
    } catch {
      // Fall back to opening the existing log file.
    }

    await shell.openPath(this.logFilePath)
  }

  async openLocation(location: DesktopRuntimeLocation): Promise<void> {
    await this.ensureDirectories()

    const targets: Record<DesktopRuntimeLocation, string> = {
      setupRoot: this.setupRoot,
      runtimeDir: this.runtimeDir,
      modelsDir: this.modelsDir,
      huggingFaceDir: join(this.modelsDir, 'huggingface'),
      logsPath: this.logFilePath,
      composeFilePath: this.composeFilePath,
    }

    const target = targets[location]
    if (location === 'logsPath') {
      await shell.openPath(target)
      return
    }

    if (location === 'composeFilePath') {
      if (existsSync(target)) {
        shell.showItemInFolder(target)
        return
      }

      await shell.openPath(this.runtimeDir)
      return
    }

    await shell.openPath(target)
  }

  private async runInstall(): Promise<void> {
    await this.ensureDirectories()
    await this.writeLog(`Starting Cadence Desktop setup (${app.getVersion()})`)

    this.setState({
      phase: 'checking',
      currentStep: 'Checking what is already ready.',
      percent: 8,
      error: null,
    })

    const initialRuntime = await this.inspectRuntime()
    const initialHealth = initialRuntime.health
    if (initialHealth.modelsReady) {
      const lastReadyAt = new Date().toISOString()
      await this.persistManifest({
        version: 1,
        appVersion: app.getVersion(),
        lastReadyAt,
      })

      this.setState({
        ...initialHealth,
        phase: 'ready',
        currentStep: 'Cadence is already ready to open.',
        percent: 100,
        error: null,
        runtimeDetails: {
          ...initialRuntime.details,
          lastReadyAt,
        },
      })
      return
    }

    const compose = await this.detectComposeCommand()
    if (!compose) {
      await this.writeLog('Docker Compose was not available on this machine.')
      this.setState({
        ...initialHealth,
        phase: 'error',
        currentStep: 'Cadence could not finish setup just yet.',
        percent: 0,
        error:
          'Cadence could not start the background setup tools it needs. Please make sure they are installed and open on this Mac, then try again.',
        runtimeDetails: initialRuntime.details,
      })
      return
    }

    const sources = this.resolveServiceSources()
    if (!existsSync(sources.aiEngineDir) || !existsSync(sources.coachEngineDir)) {
      await this.writeLog(
        `Runtime sources missing ai=${sources.aiEngineDir} coach=${sources.coachEngineDir}`,
      )
      this.setState({
        ...initialHealth,
        phase: 'error',
        currentStep: 'The bundled AI runtime sources were not found.',
        percent: 0,
        error:
          'Cadence could not locate the packaged AI runtime sources for the speech and coach services.',
        runtimeDetails: initialRuntime.details,
      })
      return
    }

    await this.writeComposeFile(sources.aiEngineDir, sources.coachEngineDir)

    this.setState({
      ...initialHealth,
      phase: 'installing',
      currentStep: 'Preparing your speaking tools for the first launch.',
      percent: 28,
      error: null,
    })

    await this.writeLog(`Using compose file ${this.composeFilePath}`)

    let installPulse = 28
    const installHeartbeat = setInterval(() => {
      if (this.state.phase !== 'installing') {
        return
      }

      installPulse = Math.min(52, installPulse + 1)
      this.setState({
        phase: 'installing',
        percent: installPulse,
        currentStep:
          'Still getting Cadence ready. The first setup can take a few more minutes.',
      })
    }, 8000)

    const composeResult = await this.runCommand(compose.command, [
      ...compose.argsPrefix,
      '-p',
      COMPOSE_PROJECT_NAME,
      '-f',
      this.composeFilePath,
      'up',
      '--build',
      '-d',
    ], {
      allowFailure: true,
      onStdoutChunk: (chunk) => {
        this.handleInstallOutput(chunk)
        void this.writeChunkToLog(chunk)
      },
      onStderrChunk: (chunk) => {
        this.handleInstallOutput(chunk)
        void this.writeChunkToLog(chunk)
      },
    })

    clearInterval(installHeartbeat)

    if (composeResult.exitCode !== 0) {
      this.setState({
        ...initialHealth,
        phase: 'error',
        currentStep: 'Cadence could not finish setup just yet.',
        percent: 0,
        error:
          'Cadence could not start its background setup steps. Please try again, or open the details view to see what happened.',
        runtimeDetails: initialRuntime.details,
      })
      return
    }

    this.setState({
      phase: 'starting-services',
      currentStep: 'Starting your speaking tools.',
      percent: 55,
      error: null,
    })

    const started = await this.waitForHealthyRuntime()
    if (!started) {
      if (this.state.phase === 'error') {
        return
      }

      const stalledRuntime = await this.inspectRuntime()
      this.setState({
        ...stalledRuntime.health,
        phase: 'error',
        currentStep: 'Cadence took too long to finish getting ready.',
        percent: 0,
        error:
          'Cadence started its background setup, but the speaking tools did not finish getting ready in time. Open the details view, then try again.',
        runtimeDetails: stalledRuntime.details,
      })
      return
    }

    const finalRuntime = await this.inspectRuntime()
    const finalHealth = finalRuntime.health
    const lastReadyAt = new Date().toISOString()
    await this.persistManifest({
      version: 1,
      appVersion: app.getVersion(),
      lastReadyAt,
    })

    this.setState({
      ...finalHealth,
      phase: 'ready',
      currentStep: 'Everything is ready. Opening Cadence…',
      percent: 100,
      error: null,
      runtimeDetails: {
        ...finalRuntime.details,
        lastReadyAt,
      },
    })
  }

  private async waitForHealthyRuntime(): Promise<boolean> {
    const startedAt = Date.now()

    while (Date.now() - startedAt < INSTALL_TIMEOUT_MS) {
      const runtime = await this.inspectRuntime()
      const health = runtime.health
      if (health.modelsReady) {
        return true
      }

      const runtimeFailure = await this.inspectRuntimeFailure()
      if (runtimeFailure) {
        this.setState({
          ...health,
          phase: 'error',
          currentStep: 'Cadence needs a lighter setup profile on this Mac.',
          percent: 0,
          error: runtimeFailure.message,
          runtimeDetails: runtime.details,
        })
        return false
      }

      const readyParts = [
        health.aiEngineReady,
        health.transcriberReady,
        health.ttsReady,
        health.coachEngineReady,
      ].filter(Boolean).length

      this.setState({
        ...health,
        phase: 'verifying',
        currentStep:
          'Almost there. Cadence is warming everything up for the first time.',
        percent: 60 + readyParts * 9,
        error: null,
        runtimeDetails: runtime.details,
      })

      await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS))
    }

    await this.writeLog(
      `Timed out waiting for healthy runtime after ${INSTALL_TIMEOUT_MS}ms`,
    )
    return false
  }

  private async inspectRuntime(): Promise<{
    health: HealthSnapshot
    details: DesktopRuntimeDetails
  }> {
    const manifest = await this.readManifest()
    const [aiPayload, coachPayload] = await Promise.all([
      this.fetchJson<AiEngineHealthPayload>(AI_ENGINE_URL),
      this.fetchJson<CoachEngineHealthPayload>(COACH_ENGINE_URL),
    ])

    const aiEngineReady = aiPayload?.modelReady === true
    const coachEngineReady = coachPayload?.ready === true
    const transcriberReady = aiPayload?.transcriberReady === true
    const ttsReady = aiPayload?.ttsReady === true

    const health = {
      aiEngineReady,
      coachEngineReady,
      transcriberReady,
      ttsReady,
      modelsReady:
        aiEngineReady && coachEngineReady && transcriberReady && ttsReady,
    }

    return {
      health,
      details: this.createRuntimeDetails({
        manifest,
        health,
        aiPayload,
        coachPayload,
      }),
    }
  }

  private async fetchJson<T>(url: string): Promise<T | null> {
    try {
      const response = await fetch(url, { cache: 'no-store' })
      if (!response.ok) {
        return null
      }

      return (await response.json()) as T
    } catch {
      return null
    }
  }

  private async inspectRuntimeFailure(): Promise<RuntimeFailureSnapshot | null> {
    const compose = await this.detectComposeCommand()
    if (!compose || !existsSync(this.composeFilePath)) {
      return null
    }

    const stateResult = await this.runCommand(
      compose.command,
      [
        ...compose.argsPrefix,
        '-p',
        COMPOSE_PROJECT_NAME,
        '-f',
        this.composeFilePath,
        'ps',
        '-a',
        '--format',
        'json',
      ],
      { allowFailure: true },
    )

    if (stateResult.exitCode !== 0 || !stateResult.stdout.trim()) {
      return null
    }

    const lines = stateResult.stdout
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean)

    for (const line of lines) {
      try {
        const payload = JSON.parse(line) as {
          Service?: string
          State?: string
          ExitCode?: number
        }

        if (
          payload.Service === 'coach-engine' &&
          payload.State === 'exited' &&
          payload.ExitCode === 137
        ) {
          await this.writeLog(
            'Coach runtime exited with code 137. This usually means the local model ran out of memory while loading.',
          )
          return {
            type: 'coach-oom',
            message:
              'Cadence ran out of memory while loading the conversation coach. I have switched the desktop beta to a lighter coach profile. Please click Retry setup once more.',
          }
        }
      } catch {
        // Ignore lines that are not JSON.
      }
    }

    return null
  }

  private createRuntimeDetails({
    manifest,
    health,
    aiPayload,
    coachPayload,
  }: {
    manifest: SetupManifest | null
    health: HealthSnapshot
    aiPayload: AiEngineHealthPayload | null
    coachPayload: CoachEngineHealthPayload | null
  }): DesktopRuntimeDetails {
    const huggingFaceDir = join(this.modelsDir, 'huggingface')

    return {
      appVersion: app.getVersion(),
      installStrategy: 'docker-beta',
      isPackaged: app.isPackaged,
      lastReadyAt: manifest?.lastReadyAt ?? null,
      setupRoot: this.setupRoot,
      runtimeDir: this.runtimeDir,
      modelsDir: this.modelsDir,
      huggingFaceDir,
      composeFilePath: this.composeFilePath,
      composeFilePresent: existsSync(this.composeFilePath),
      logsPath: this.logFilePath,
      setupManifestPresent: manifest !== null,
      endpoints: {
        webApp: DESKTOP_WEB_APP_URL,
        aiEngine: AI_ENGINE_URL,
        coachEngine: COACH_ENGINE_URL,
      },
      availability: {
        huggingFaceTokenConfigured:
          aiPayload?.hfTokenConfigured === true ||
          aiPayload?.diagnostics?.hfTokenConfigured === true ||
          Boolean(process.env.HF_TOKEN),
      },
      aiEngine: {
        modelId:
          aiPayload?.diagnostics?.modelName ??
          aiPayload?.model ??
          DEFAULT_DESKTOP_SPEECH_MODEL_ID,
        ready: health.aiEngineReady,
        loadError:
          aiPayload?.loadError ??
          aiPayload?.diagnostics?.loadError ??
          null,
        device: aiPayload?.diagnostics?.device ?? null,
      },
      transcriber: {
        modelId:
          aiPayload?.transcriberModel ?? DEFAULT_DESKTOP_TRANSCRIBER_MODEL_ID,
        ready: health.transcriberReady,
        loadError: aiPayload?.transcriberLoadError ?? null,
        device: aiPayload?.transcriberDevice ?? null,
      },
      tts: {
        modelId: aiPayload?.ttsModel ?? DEFAULT_DESKTOP_TTS_MODEL_ID,
        ready: health.ttsReady,
        loadError: aiPayload?.ttsLoadError ?? null,
        device: aiPayload?.ttsDevice ?? null,
        language: aiPayload?.ttsLanguage ?? DEFAULT_DESKTOP_TTS_LANGUAGE,
        instruct: aiPayload?.ttsInstruct ?? DEFAULT_DESKTOP_TTS_INSTRUCT,
      },
      coach: {
        modelId:
          coachPayload?.coachModel ??
          coachPayload?.model ??
          DEFAULT_DESKTOP_COACH_MODEL_ID,
        ready: health.coachEngineReady,
        loadError: coachPayload?.coachLoadError ?? null,
        device: coachPayload?.coachDevice ?? null,
        provider: coachPayload?.provider ?? 'local-coach',
        transformersVersion: coachPayload?.coachTransformersVersion ?? null,
      },
    }
  }

  private resolveServiceSources() {
    if (app.isPackaged) {
      const resourcesPath = (process as NodeJS.Process & {
        resourcesPath: string
      }).resourcesPath

      return {
        aiEngineDir: join(resourcesPath, 'desktop-runtime', 'ai-engine'),
        coachEngineDir: join(resourcesPath, 'desktop-runtime', 'coach-engine'),
      }
    }

    const repoRoot = join(__dirname, '..', '..')
    return {
      aiEngineDir: join(repoRoot, 'src', 'backend', 'ai-engine'),
      coachEngineDir: join(repoRoot, 'src', 'backend', 'coach-engine'),
    }
  }

  private async detectComposeCommand(): Promise<{
    command: string
    argsPrefix: string[]
  } | null> {
    const dockerCompose = await this.runCommand('docker', ['compose', 'version'], {
      allowFailure: true,
    })
    if (
      dockerCompose.exitCode === 0 &&
      dockerCompose.stdout.includes('Docker Compose')
    ) {
      return { command: 'docker', argsPrefix: ['compose'] }
    }

    const legacyCompose = await this.runCommand('docker-compose', ['version'], {
      allowFailure: true,
    })
    if (
      legacyCompose.exitCode === 0 &&
      (legacyCompose.stdout.toLowerCase().includes('docker-compose') ||
        legacyCompose.stdout.toLowerCase().includes('docker compose'))
    ) {
      return { command: 'docker-compose', argsPrefix: [] }
    }

    return null
  }

  private async runCommand(
    command: string,
    args: string[],
    options: RunCommandOptions = {},
  ): Promise<CommandResult> {
    return new Promise((resolve, reject) => {
      const child = spawn(command, args, {
        env: COMMAND_ENV,
        cwd: this.runtimeDir,
        stdio: ['ignore', 'pipe', 'pipe'],
      })

      let stdout = ''
      let stderr = ''

      child.stdout?.on('data', (chunk) => {
        const text = chunk.toString()
        stdout += text
        options.onStdoutChunk?.(text)
      })

      child.stderr?.on('data', (chunk) => {
        const text = chunk.toString()
        stderr += text
        options.onStderrChunk?.(text)
      })

      child.on('error', (error) => {
        if (options.allowFailure) {
          resolve({
            stdout,
            stderr: `${stderr}${error.message}`.trim(),
            exitCode: null,
          })
          return
        }

        reject(error)
      })

      child.on('exit', (code) => {
        if (code === 0 || options.allowFailure) {
          resolve({ stdout, stderr, exitCode: code })
          return
        }

        reject(
          new Error(
            `Command failed (${command} ${args.join(' ')}) with exit code ${code}`,
          ),
        )
      })
    })
  }

  private handleInstallOutput(chunk: string): void {
    const latestLine = chunk
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean)
      .at(-1)

    if (!latestLine) {
      return
    }

    const nextPercent = Math.min(52, Math.max(this.state.percent, 28) + 1)
    this.setState({
      phase: 'installing',
      percent: nextPercent,
      currentStep: this.describeInstallLine(latestLine),
      error: null,
    })
  }

  private describeInstallLine(line: string): string {
    const normalized = line.toLowerCase()

    if (
      normalized.includes('load build definition') ||
      normalized.includes('load metadata') ||
      normalized.includes('resolve image config') ||
      normalized.includes('pulling fs layer') ||
      normalized.includes('downloading')
    ) {
      return 'Downloading the pieces Cadence needs for the first launch.'
    }

    if (
      normalized.includes('apt-get') ||
      normalized.includes('ffmpeg') ||
      normalized.includes('espeak') ||
      normalized.includes('libsndfile')
    ) {
      return 'Installing audio support for listening and voice playback.'
    }

    if (
      normalized.includes('pip install') ||
      normalized.includes('collecting') ||
      normalized.includes('installing collected packages') ||
      normalized.includes('requirements.txt')
    ) {
      return 'Installing the speaking and coaching tools.'
    }

    if (
      normalized.includes('exporting to image') ||
      normalized.includes('naming to') ||
      normalized.includes('writing image')
    ) {
      return 'Finishing the setup in the background.'
    }

    if (
      normalized.includes('started') ||
      normalized.includes('running') ||
      normalized.includes('created') ||
      normalized.includes('healthy')
    ) {
      return 'Starting your speaking tools.'
    }

    return 'Preparing your speaking tools for the first launch.'
  }

  private async writeChunkToLog(chunk: string): Promise<void> {
    const lines = chunk
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean)

    for (const line of lines) {
      await this.writeLog(line)
    }
  }

  private async writeComposeFile(
    aiEngineDir: string,
    coachEngineDir: string,
  ): Promise<void> {
    const huggingFaceDir = join(this.modelsDir, 'huggingface')
    await mkdir(huggingFaceDir, { recursive: true })

    const quote = (value: string) => JSON.stringify(value)

    const composeYaml = `services:
  ai-engine:
    build:
      context: ${quote(aiEngineDir)}
      dockerfile: "Dockerfile"
    environment:
      AI_ENGINE_HOST: "0.0.0.0"
      AI_ENGINE_PORT: "8000"
      HF_HOME: "/models/huggingface"
      TRANSFORMERS_CACHE: "/models/huggingface"
      CADENCE_LOG_LEVEL: "INFO"
      HF_TOKEN: ${quote(process.env.HF_TOKEN ?? '')}
    ports:
      - "127.0.0.1:8000:8000"
    volumes:
      - ${quote(`${huggingFaceDir}:/models/huggingface`)}

  coach-engine:
    build:
      context: ${quote(coachEngineDir)}
      dockerfile: "Dockerfile"
    environment:
      COACH_ENGINE_HOST: "0.0.0.0"
      COACH_ENGINE_PORT: "8001"
      COACH_LLM_MODEL_ID: ${JSON.stringify(DEFAULT_DESKTOP_COACH_MODEL_ID)}
      COACH_LLM_DEVICE: "cpu"
      HF_HOME: "/models/huggingface"
      TRANSFORMERS_CACHE: "/models/huggingface"
      CADENCE_LOG_LEVEL: "INFO"
      HF_TOKEN: ${quote(process.env.HF_TOKEN ?? '')}
    ports:
      - "127.0.0.1:8001:8001"
    volumes:
      - ${quote(`${huggingFaceDir}:/models/huggingface`)}
`

    await writeFile(this.composeFilePath, composeYaml, 'utf8')
  }

  private async ensureDirectories(): Promise<void> {
    await mkdir(this.logsDir, { recursive: true })
    await mkdir(this.runtimeDir, { recursive: true })
    await mkdir(this.modelsDir, { recursive: true })
    await mkdir(join(this.modelsDir, 'huggingface'), { recursive: true })
    await appendFile(this.logFilePath, '', 'utf8')
  }

  private async writeLog(message: string): Promise<void> {
    await appendFile(
      this.logFilePath,
      `[${new Date().toISOString()}] ${message}\n`,
      'utf8',
    )
  }

  private async readManifest(): Promise<SetupManifest | null> {
    try {
      const raw = await readFile(this.setupFilePath, 'utf8')
      return JSON.parse(raw) as SetupManifest
    } catch {
      return null
    }
  }

  private async persistManifest(manifest: SetupManifest): Promise<void> {
    await writeFile(this.setupFilePath, JSON.stringify(manifest, null, 2), 'utf8')
  }

  private setState(nextState: Partial<DesktopSetupState>): DesktopSetupState {
    this.state = {
      ...this.state,
      ...nextState,
      logsPath: this.logFilePath,
      installStrategy: 'docker-beta',
      isPackaged: app.isPackaged,
    }

    this.emitter.emit('state', this.state)
    return this.state
  }
}
