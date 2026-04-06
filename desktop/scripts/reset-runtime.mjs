import { spawn } from 'node:child_process'
import { readFile, rm, stat } from 'node:fs/promises'
import { homedir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const PRODUCT_NAME = 'Cadence'
const APP_ID = 'com.cadence.app'
const COMPOSE_PROJECT_NAME = 'cadence-desktop-beta'

function getUserDataDir() {
  if (process.platform === 'darwin') {
    return join(homedir(), 'Library', 'Application Support', PRODUCT_NAME)
  }

  if (process.platform === 'win32') {
    return process.env.APPDATA
      ? join(process.env.APPDATA, PRODUCT_NAME)
      : join(homedir(), 'AppData', 'Roaming', PRODUCT_NAME)
  }

  return join(
    process.env.XDG_CONFIG_HOME ?? join(homedir(), '.config'),
    PRODUCT_NAME,
  )
}

function runCommand(command, args, { allowFailure = false } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    })

    let stdout = ''
    let stderr = ''

    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString()
    })

    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString()
    })

    child.on('error', (error) => {
      if (allowFailure) {
        resolve({
          stdout,
          stderr: `${stderr}${stderr ? '\n' : ''}${String(error)}`,
          exitCode: 1,
        })
        return
      }

      reject(error)
    })

    child.on('close', (exitCode) => {
      if (!allowFailure && exitCode !== 0) {
        const summary = stderr.trim() || stdout.trim() || `Exit code ${exitCode}`
        reject(new Error(summary))
        return
      }

      resolve({ stdout, stderr, exitCode })
    })
  })
}

async function pathExists(path) {
  try {
    await stat(path)
    return true
  } catch {
    return false
  }
}

async function detectComposeCommand() {
  const dockerCompose = await runCommand('docker', ['compose', 'version'], {
    allowFailure: true,
  })

  if (
    dockerCompose.exitCode === 0 &&
    dockerCompose.stdout.toLowerCase().includes('docker compose')
  ) {
    return { command: 'docker', argsPrefix: ['compose'] }
  }

  const legacyCompose = await runCommand('docker-compose', ['version'], {
    allowFailure: true,
  })

  if (
    legacyCompose.exitCode === 0 &&
    legacyCompose.stdout.toLowerCase().includes('docker')
  ) {
    return { command: 'docker-compose', argsPrefix: [] }
  }

  return null
}

async function stopComposeRuntime({ composeFilePath, dryRun }) {
  const compose = await detectComposeCommand()
  if (!compose) {
    console.log('No Docker Compose command found; skipping desktop runtime shutdown.')
  } else {
    const composeArgs = [
      ...compose.argsPrefix,
      '-p',
      COMPOSE_PROJECT_NAME,
      '-f',
      composeFilePath,
      'down',
      '--remove-orphans',
      '--volumes',
    ]

    if (await pathExists(composeFilePath)) {
      if (dryRun) {
        console.log(
          `Dry run: ${compose.command} ${composeArgs.join(' ')}`,
        )
      } else {
        const result = await runCommand(compose.command, composeArgs, {
          allowFailure: true,
        })

        if (result.exitCode === 0) {
          console.log('Stopped the desktop background services.')
        } else {
          const details = result.stderr.trim() || result.stdout.trim()
          console.log(
            `Compose shutdown did not complete cleanly${details ? `: ${details}` : '.'}`,
          )
        }
      }
    } else {
      console.log('No desktop compose file found yet; skipping compose shutdown.')
    }
  }

  const containerLookup = await runCommand(
    'docker',
    [
      'ps',
      '-aq',
      '--filter',
      `label=com.docker.compose.project=${COMPOSE_PROJECT_NAME}`,
    ],
    { allowFailure: true },
  )

  const containerIds = containerLookup.stdout
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)

  if (containerIds.length === 0) {
    return
  }

  if (dryRun) {
    console.log(`Dry run: docker rm -f ${containerIds.join(' ')}`)
    return
  }

  const removeResult = await runCommand('docker', ['rm', '-f', ...containerIds], {
    allowFailure: true,
  })

  if (removeResult.exitCode === 0) {
    console.log('Removed lingering desktop runtime containers.')
  } else {
    const details = removeResult.stderr.trim() || removeResult.stdout.trim()
    console.log(
      `Container cleanup did not complete cleanly${details ? `: ${details}` : '.'}`,
    )
  }
}

async function removeCadenceImages({ dryRun }) {
  const imageLookup = await runCommand(
    'docker',
    ['image', 'ls', '--format', '{{json .}}'],
    { allowFailure: true },
  )

  if (imageLookup.exitCode !== 0) {
    return
  }

  const imageIds = imageLookup.stdout
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line)
      } catch {
        return null
      }
    })
    .filter(Boolean)
    .filter((image) =>
      typeof image.Repository === 'string' &&
      image.Repository.startsWith(`${COMPOSE_PROJECT_NAME}-`),
    )
    .map((image) => image.ID)
    .filter(Boolean)

  if (imageIds.length === 0) {
    return
  }

  if (dryRun) {
    console.log(`Dry run: docker image rm -f ${imageIds.join(' ')}`)
    return
  }

  const removeResult = await runCommand('docker', ['image', 'rm', '-f', ...imageIds], {
    allowFailure: true,
  })

  if (removeResult.exitCode === 0) {
    console.log('Removed cached Cadence desktop images.')
  } else {
    const details = removeResult.stderr.trim() || removeResult.stdout.trim()
    console.log(
      `Image cleanup did not complete cleanly${details ? `: ${details}` : '.'}`,
    )
  }
}

export async function resetDesktopRuntime({
  dryRun = false,
  distDir = null,
  extraPaths = [],
  removeInstalledApp = false,
} = {}) {
  const setupRoot = join(getUserDataDir(), 'desktop-runtime')
  const composeFilePath = join(setupRoot, 'runtime', 'docker-compose.ai.yml')
  const aiPidPath = join(setupRoot, 'runtime', 'ai-engine.pid')
  const coachPidPath = join(setupRoot, 'runtime', 'coach-engine.pid')
  const installedAppPaths = [
    '/Applications/Cadence.app',
    join(homedir(), 'Applications', 'Cadence.app'),
  ]
  const deepCachePaths = [
    join(getUserDataDir()),
    join(homedir(), 'Library', 'Caches', PRODUCT_NAME),
    join(homedir(), 'Library', 'Caches', APP_ID),
    join(homedir(), 'Library', 'Preferences', `${APP_ID}.plist`),
    join(homedir(), 'Library', 'HTTPStorages', APP_ID),
    join(homedir(), 'Library', 'Saved Application State', `${APP_ID}.savedState`),
    join(homedir(), 'Library', 'WebKit', APP_ID),
  ]

  for (const targetPath of [distDir, ...extraPaths].filter(Boolean)) {
    if (dryRun) {
      console.log(`Dry run: remove ${targetPath}`)
    } else {
      await rm(targetPath, { recursive: true, force: true })
      console.log(`Cleared ${targetPath}`)
    }
  }

  for (const pidPath of [aiPidPath, coachPidPath]) {
    if (!(await pathExists(pidPath))) {
      continue
    }

    const pidRaw = await readFile(pidPath, 'utf8').catch(() => '')
    const pid = Number(pidRaw.trim())
    if (!Number.isFinite(pid) || pid <= 0) {
      continue
    }

    if (dryRun) {
      console.log(`Dry run: kill ${pid}`)
      continue
    }

    try {
      process.kill(pid, 'SIGTERM')
      console.log(`Stopped native desktop runtime process ${pid}`)
    } catch {
      // Ignore stale pid files.
    }
  }

  await stopComposeRuntime({ composeFilePath, dryRun })
  await removeCadenceImages({ dryRun })

  if (dryRun) {
    console.log(`Dry run: remove ${setupRoot}`)
    if (removeInstalledApp) {
      for (const appPath of installedAppPaths) {
        console.log(`Dry run: remove ${appPath}`)
      }
      for (const cachePath of deepCachePaths) {
        console.log(`Dry run: remove ${cachePath}`)
      }
    }
    return
  }

  await rm(setupRoot, { recursive: true, force: true })
  console.log(`Reset desktop runtime at ${setupRoot}`)

  if (removeInstalledApp) {
    for (const appPath of installedAppPaths) {
      await rm(appPath, { recursive: true, force: true })
      console.log(`Removed installed app at ${appPath}`)
    }

    for (const cachePath of deepCachePaths) {
      await rm(cachePath, { recursive: true, force: true })
      console.log(`Cleared ${cachePath}`)
    }
  }
}

const isEntryPoint = process.argv[1] === fileURLToPath(import.meta.url)

if (isEntryPoint) {
  const dryRun = process.argv.includes('--dry-run')
  await resetDesktopRuntime({ dryRun })
}
