import * as http from 'http'
import { join } from 'path'
import { utilityProcess, type UtilityProcess } from 'electron'

export function waitForServer(
  appOrigin: string,
  retries = 40,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const attempt = (remaining: number) => {
      const req = http.get(appOrigin, (res) => {
        if (res.statusCode && res.statusCode < 500) {
          resolve()
        } else {
          retry(remaining)
        }
      })
      req.on('error', () => retry(remaining))
      req.end()
    }

    const retry = (remaining: number) => {
      if (remaining <= 0) {
        reject(new Error('Next.js server failed to start within the timeout.'))
        return
      }
      setTimeout(() => attempt(remaining - 1), 500)
    }

    attempt(retries)
  })
}

export async function startNextServer({
  appOrigin,
  port,
  resourcesPath,
}: {
  appOrigin: string
  port: number
  resourcesPath: string
}): Promise<UtilityProcess> {
  return new Promise((resolve, reject) => {
    const serverScript = join(resourcesPath, 'next-server', 'server.js')
    const nextServer = utilityProcess.fork(serverScript, [], {
      cwd: join(resourcesPath, 'next-server'),
      env: {
        ...process.env,
        PORT: String(port),
        NODE_ENV: 'production',
        NEXT_SHARP_PATH: join(resourcesPath, 'next-server', 'node_modules', 'sharp'),
      },
      stdio: 'pipe',
      serviceName: 'Cadence Web Runtime',
    })

    let settled = false
    const finishSuccess = () => {
      if (settled) {
        return
      }
      settled = true
      resolve(nextServer)
    }

    const finishError = (error: Error) => {
      if (settled) {
        return
      }
      settled = true
      reject(error)
    }

    nextServer.stdout?.on('data', (chunk) => {
      const message = chunk.toString()
      console.log('[next]', message)
      if (message.includes('Ready') || message.includes('started server')) {
        finishSuccess()
      }
    })

    nextServer.stderr?.on('data', (chunk) => {
      console.error('[next:err]', chunk.toString())
    })

    nextServer.on('error', (error) => {
      finishError(new Error(`Next.js utility process failed: ${JSON.stringify(error)}`))
    })
    nextServer.on('exit', (code) => {
      if (code !== 0 && code !== null) {
        finishError(new Error(`Next.js process exited with code ${code}`))
      }
    })

    waitForServer(appOrigin).then(finishSuccess).catch(finishError)
  })
}
