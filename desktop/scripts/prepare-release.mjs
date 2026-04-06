import { mkdir, readFile, rm, writeFile } from 'fs/promises'
import { dirname, join } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const desktopRoot = join(__dirname, '..')
const packageJsonPath = join(desktopRoot, 'package.json')
const packagesDir = join(desktopRoot, 'packages')

function extractVersionFromTag(rawTag) {
  const normalized = String(rawTag ?? '').trim()
  const match = normalized.match(/^(?:desktop-)?v?(\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?)$/)
  return match?.[1] ?? null
}

async function main() {
  const rawPackageJson = await readFile(packageJsonPath, 'utf8')
  const packageJson = JSON.parse(rawPackageJson)
  const tagVersion = extractVersionFromTag(process.env.CADENCE_RELEASE_TAG)

  console.log(`[desktop release] clearing old build artifacts in ${packagesDir}`)
  await rm(packagesDir, { recursive: true, force: true })
  await mkdir(packagesDir, { recursive: true })

  if (!tagVersion) {
    console.log('[desktop release] no release tag provided, keeping current desktop version.')
    return
  }

  const currentVersion = String(packageJson.version ?? '').trim()
  if (!currentVersion) {
    throw new Error('desktop/package.json is missing a version field.')
  }

  packageJson.version = tagVersion
  await writeFile(packageJsonPath, `${JSON.stringify(packageJson, null, 2)}\n`, 'utf8')

  console.log(`[desktop release] desktop version set from tag: ${currentVersion} -> ${tagVersion}`)
}

main().catch((error) => {
  console.error(
    `[desktop release] ${error instanceof Error ? error.message : String(error)}`,
  )
  process.exitCode = 1
})
