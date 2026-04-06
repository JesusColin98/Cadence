import { lstat, readdir, rm, symlink } from 'node:fs/promises'
import { dirname, join, relative } from 'node:path'

const standaloneRoot = join(process.cwd(), '..', '.next', 'standalone')
const hoistedRoot = join(standaloneRoot, 'node_modules', '.pnpm', 'node_modules')
const semverLinkPath = join(hoistedRoot, 'semver')
const pnpmRoot = join(standaloneRoot, 'node_modules', '.pnpm')

async function isBrokenSymlink(path) {
  try {
    const stats = await lstat(path)
    return stats.isSymbolicLink()
  } catch {
    return false
  }
}

async function findSemverTarget() {
  const entries = await readdir(pnpmRoot, { withFileTypes: true })
  const candidate = entries.find(
    (entry) => entry.isDirectory() && entry.name.startsWith('semver@'),
  )

  if (!candidate) {
    return null
  }

  return join(pnpmRoot, candidate.name, 'node_modules', 'semver')
}

async function main() {
  const broken = await isBrokenSymlink(semverLinkPath)
  if (!broken) {
    return
  }

  const target = await findSemverTarget()
  if (!target) {
    throw new Error('Could not find a semver package inside .next/standalone/.pnpm')
  }

  await rm(semverLinkPath, { force: true })
  await symlink(relative(dirname(semverLinkPath), target), semverLinkPath)
  console.log(`Repaired standalone semver symlink -> ${target}`)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
