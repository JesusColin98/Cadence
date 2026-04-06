import { spawn } from 'child_process'
import { createWriteStream, existsSync } from 'fs'
import { mkdir, readFile, rename, rm, writeFile } from 'fs/promises'
import { dirname, join } from 'path'
import { pipeline } from 'stream/promises'
import { Readable } from 'stream'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const desktopRoot = join(__dirname, '..')
const vendorRoot = join(desktopRoot, 'vendor', 'python')
const downloadsDir = join(vendorRoot, '.downloads')
const manifestPath = join(vendorRoot, 'manifest.json')
const releaseTag = '20260325'
const pythonVersion = '3.11.15'
const targets = [
  {
    key: 'aarch64-apple-darwin',
    assetName: `cpython-${pythonVersion}+${releaseTag}-aarch64-apple-darwin-install_only.tar.gz`,
  },
  {
    key: 'x86_64-apple-darwin',
    assetName: `cpython-${pythonVersion}+${releaseTag}-x86_64-apple-darwin-install_only.tar.gz`,
  },
]
const dryRun = process.argv.includes('--dry-run')
const force = process.argv.includes('--force')

function log(message) {
  console.log(`[desktop python] ${message}`)
}

function getAssetUrl(assetName) {
  return `https://github.com/astral-sh/python-build-standalone/releases/download/${releaseTag}/${assetName.replace('+', '%2B')}`
}

function getTargetDir(targetKey) {
  return join(vendorRoot, targetKey)
}

function getInterpreterPath(targetKey) {
  return join(getTargetDir(targetKey), 'python', 'bin', 'python3')
}

async function readManifest() {
  try {
    return JSON.parse(await readFile(manifestPath, 'utf8'))
  } catch {
    return null
  }
}

async function run(command, args) {
  await new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: 'inherit' })
    child.on('error', reject)
    child.on('exit', (code) => {
      if (code === 0) {
        resolve()
        return
      }

      reject(new Error(`Command failed (${command} ${args.join(' ')}) with exit code ${code}`))
    })
  })
}

async function downloadFile(url, outputPath) {
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'cadence-desktop',
    },
  })

  if (!response.ok || !response.body) {
    throw new Error(`Failed to download ${url} (${response.status} ${response.statusText})`)
  }

  const tempPath = `${outputPath}.download`
  const writeStream = createWriteStream(tempPath)

  try {
    await pipeline(Readable.fromWeb(response.body), writeStream)
    await rename(tempPath, outputPath)
  } catch (error) {
    await rm(tempPath, { force: true })
    throw error
  }
}

async function extractArchive(archivePath, destinationDir) {
  const tempDir = `${destinationDir}.tmp`
  await rm(tempDir, { recursive: true, force: true })
  await mkdir(tempDir, { recursive: true })
  await run('tar', ['-xzf', archivePath, '-C', tempDir])
  await rm(destinationDir, { recursive: true, force: true })
  await rename(tempDir, destinationDir)
}

async function main() {
  const expectedManifest = {
    releaseTag,
    pythonVersion,
    targets: targets.map((target) => ({
      key: target.key,
      assetName: target.assetName,
    })),
  }

  const currentManifest = await readManifest()
  const alreadyPrepared =
    !force &&
    currentManifest &&
    JSON.stringify(currentManifest) === JSON.stringify(expectedManifest) &&
    targets.every((target) => existsSync(getInterpreterPath(target.key)))

  if (alreadyPrepared) {
    log('bundled Python runtimes are already prepared.')
    return
  }

  log(`preparing bundled Python ${pythonVersion} from python-build-standalone ${releaseTag}`)

  if (dryRun) {
    for (const target of targets) {
      log(`would prepare ${target.key} from ${getAssetUrl(target.assetName)}`)
    }
    return
  }

  await mkdir(downloadsDir, { recursive: true })

  for (const target of targets) {
    const archivePath = join(downloadsDir, target.assetName)
    const targetDir = getTargetDir(target.key)
    const url = getAssetUrl(target.assetName)

    if (!existsSync(archivePath) || force) {
      log(`downloading ${target.assetName}`)
      await downloadFile(url, archivePath)
    } else {
      log(`using cached archive ${target.assetName}`)
    }

    log(`extracting ${target.key}`)
    await extractArchive(archivePath, targetDir)
  }

  await writeFile(manifestPath, `${JSON.stringify(expectedManifest, null, 2)}\n`, 'utf8')
  log('bundled Python runtimes are ready.')
}

main().catch((error) => {
  console.error(
    `[desktop python] ${error instanceof Error ? error.message : String(error)}`,
  )
  process.exitCode = 1
})
