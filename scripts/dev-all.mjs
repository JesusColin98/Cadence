/**
 * dev-all.mjs — starts all Cadence services in parallel with hot-reload.
 *
 * Reload behaviour:
 *   • Next.js web app  — HMR handles it
 *   • Python backends  — uvicorn --reload restarts only the Python worker
 *
 * Usage:
 *   pnpm dev:all              — start everything
 *   pnpm dev:all -- --cache   — clear build caches
 *   Ctrl-C                    — graceful shutdown, no leftovers
 */

import { rm } from 'node:fs/promises'
import { spawn } from 'node:child_process'
import { createServer } from 'node:net'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

// ─── Paths ────────────────────────────────────────────────────────────────────

const rootDir    = fileURLToPath(new URL('..', import.meta.url))
const aiDir      = path.join(rootDir, 'src', 'backend', 'ai-engine')
const coachDir   = path.join(rootDir, 'src', 'backend', 'coach-engine')

const nextCli      = path.join(rootDir, 'node_modules', 'next', 'dist', 'bin', 'next')
const nextCacheDir = path.join(rootDir, '.next')

// ─── Args ─────────────────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2)
const shouldCache    = rawArgs.includes('--cache')
const targetPort     = process.env.PORT ?? '3000'
const python         = process.env.PYTHON ?? 'python3'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function isPortAvailable(port) {
  return new Promise((resolve) => {
    const server = createServer()
    server.once('error', () => resolve(false))
    server.once('listening', () => server.close(() => resolve(true)))
    server.listen(Number(port), '127.0.0.1')
  })
}

function prefixedSpawn(tag, color, cmd, args, opts) {
  const prefix = `\x1b[${color}m[${tag}]\x1b[0m`

  const env = {
    ...process.env,
    PYTHONUNBUFFERED: '1',
    PYTHONDONTWRITEBYTECODE: '1',
    ...(opts?.env ?? {}),
  }

  const child = spawn(cmd, args, { ...opts, env, stdio: ['ignore', 'pipe', 'pipe'] })

  function printLines(stream, write) {
    let leftover = ''
    stream.on('data', (chunk) => {
      const text = leftover + chunk.toString()
      const lines = text.split('\n')
      leftover = lines.pop()
      for (const line of lines) {
        if (line.length > 0) write(`${prefix} ${line}\n`)
      }
    })
    stream.on('end', () => {
      if (leftover.length > 0) write(`${prefix} ${leftover}\n`)
    })
  }

  printLines(child.stdout, (l) => process.stdout.write(l))
  printLines(child.stderr, (l) => process.stderr.write(l))

  return child
}

function log(msg) {
  process.stdout.write(`\x1b[33m[dev:all]\x1b[0m ${msg}\n`)
}

// ─── Clear caches ─────────────────────────────────────────────────────────────

if (shouldCache) {
  log('Clearing caches…')
  await Promise.all([
    rm(nextCacheDir, { recursive: true, force: true }).then(() => log('  ✓ .next cleared')),
    rm(path.join(aiDir,    '__pycache__'), { recursive: true, force: true }),
    rm(path.join(coachDir, '__pycache__'), { recursive: true, force: true }),
  ]).then(() => log('  ✓ Caches cleared'))
}

// ─── Port check ───────────────────────────────────────────────────────────────

if (!(await isPortAvailable(targetPort))) {
  process.stderr.write(
    `\x1b[31m[dev:all]\x1b[0m Port ${targetPort} is already in use. Stop the existing server or set PORT=<port>.\n`,
  )
  process.exit(1)
}

// ─── Shutdown registry ────────────────────────────────────────────────────────

const allChildren = new Set()
let shuttingDown = false

function trackChild(child) {
  allChildren.add(child)
  child.on('exit', () => allChildren.delete(child))
  return child
}

function killAll(signal) {
  for (const child of allChildren) {
    if (!child.killed) child.kill(signal)
  }
}

function shutdown(signal) {
  if (shuttingDown) return
  shuttingDown = true
  log(`Received ${signal} — stopping all services…`)
  killAll(signal)
  const timer = setTimeout(() => { killAll('SIGKILL'); process.exit(1) }, 5000)
  timer.unref()
}

process.on('SIGINT',  () => shutdown('SIGINT'))
process.on('SIGTERM', () => shutdown('SIGTERM'))

// ─── 1. Next.js web app ──────────────────────────────────────────────────────

log('Starting all services…\n')

trackChild(prefixedSpawn(
  'web-app  ', 32,
  process.execPath, [nextCli, 'dev', '--port', targetPort],
  { cwd: rootDir },
))

// ─── 2. AI engine — uvicorn --reload (file-watches src/backend/ai-engine/) ───

trackChild(prefixedSpawn(
  'ai-engine', 36,
  python, [
    '-m', 'uvicorn', 'main:app',
    '--host', '0.0.0.0',
    '--port', process.env.AI_ENGINE_PORT ?? '8000',
    '--reload',
    '--reload-dir', aiDir,
  ],
  { cwd: aiDir },
))

// ─── 3. Coach engine — uvicorn --reload (file-watches src/backend/coach-engine/) ─

trackChild(prefixedSpawn(
  'coach-eng', 35,
  python, [
    '-m', 'uvicorn', 'main:app',
    '--host', '0.0.0.0',
    '--port', process.env.COACH_ENGINE_PORT ?? '8001',
    '--reload',
    '--reload-dir', coachDir,
  ],
  { cwd: coachDir },
))
