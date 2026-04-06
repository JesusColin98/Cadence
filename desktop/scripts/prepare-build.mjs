import { mkdir, readFile, rm, writeFile } from 'fs/promises'
import { dirname, join } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const desktopRoot = join(__dirname, '..')
const packageJsonPath = join(desktopRoot, 'package.json')
const packagesDir = join(desktopRoot, 'packages')
const dryRun = process.argv.includes('--dry-run')

function bumpPatchVersion(version) {
  const match = version.match(/^(\d+)\.(\d+)\.(\d+)(.*)$/)
  if (!match) {
    throw new Error(`Unsupported version format: ${version}`)
  }

  const [, major, minor, patch, suffix] = match
  const nextPatch = Number.parseInt(patch, 10) + 1
  return `${major}.${minor}.${nextPatch}${suffix}`
}

async function main() {
  const rawPackageJson = await readFile(packageJsonPath, 'utf8')
  const packageJson = JSON.parse(rawPackageJson)
  const currentVersion = String(packageJson.version ?? '').trim()

  if (!currentVersion) {
    throw new Error('desktop/package.json is missing a version field.')
  }

  const nextVersion = bumpPatchVersion(currentVersion)

  console.log(`[desktop build] current version: ${currentVersion}`)
  console.log(`[desktop build] next version: ${nextVersion}`)
  console.log(`[desktop build] clearing old build artifacts in ${packagesDir}`)

  if (dryRun) {
    console.log('[desktop build] dry run enabled, no files were changed.')
    return
  }

  await rm(packagesDir, { recursive: true, force: true })
  await mkdir(packagesDir, { recursive: true })

  packageJson.version = nextVersion
  await writeFile(packageJsonPath, `${JSON.stringify(packageJson, null, 2)}\n`, 'utf8')

  console.log('[desktop build] desktop package version updated and old artifacts removed.')
}

main().catch((error) => {
  console.error(`[desktop build] ${error instanceof Error ? error.message : String(error)}`)
  process.exitCode = 1
})
