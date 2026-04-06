import { fileURLToPath } from 'node:url'
import { resetDesktopRuntime } from './reset-runtime.mjs'

const distDir = fileURLToPath(new URL('../dist', import.meta.url))
const packagesDir = fileURLToPath(new URL('../packages', import.meta.url))
const nextCacheDir = fileURLToPath(new URL('../../.next', import.meta.url))

const dryRun = process.argv.includes('--dry-run')

await resetDesktopRuntime({
  dryRun,
  distDir,
  extraPaths: [packagesDir, nextCacheDir],
  removeInstalledApp: true,
})

if (dryRun) {
  console.log(
    `Dry run: would remove the installed Cadence app, Cadence desktop runtime, ${distDir}, ${packagesDir}, and ${nextCacheDir}`,
  )
  process.exit(0)
}

console.log('Cadence app install, runtime, caches, and build outputs have been fully reset.')
