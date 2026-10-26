const { app, BrowserWindow, ipcMain, shell } = require('electron')
const fs = require('fs')
const { spawn } = require('child_process')
const path = require('path')

const bridge = 'C:\\Users\\fidel\\AppData\\Local\\ClaudeOllamaBridge'

function createWindow() {
  const win = new BrowserWindow({
    width: 720,
    height: 520,
    minWidth: 620,
    minHeight: 460,
    title: 'XHumanX Control',
    backgroundColor: '#080a10',
    autoHideMenuBar: true,
    resizable: true,
    webPreferences: { preload: path.join(__dirname, 'preload.cjs'), contextIsolation: true, nodeIntegration: false }
  })
  win.loadFile(path.join(__dirname, '..', 'dist', 'index.html'))
}

function runPowerShell(scriptPath, args = [], timeout = 900000) {
  return new Promise((resolve) => {
    const child = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptPath, ...args], { cwd: bridge, windowsHide: true })
    let output = ''
    let error = ''
    const timer = setTimeout(() => { child.kill(); resolve({ ok: false, message: 'La preparaci?n tard? demasiado. Revisa la conexi?n a Internet.' }) }, timeout)
    child.stdout.on('data', (chunk) => { output += chunk.toString() })
    child.stderr.on('data', (chunk) => { error += chunk.toString() })
    child.on('error', (cause) => { clearTimeout(timer); resolve({ ok: false, message: cause.message }) })
    child.on('close', (code) => { clearTimeout(timer); resolve({ ok: code === 0, message: (code === 0 ? output : error || output).trim().slice(-800) }) })
  })
}

async function prepareSystem() {
  const script = path.join(process.resourcesPath, 'installer-resources', 'setup-bridge.ps1')
  if (fs.existsSync(script)) return runPowerShell(script)
  return { ok: fs.existsSync(path.join(bridge, 'venv', 'Scripts', 'litellm.exe')), message: 'Modo desarrollo: usa el instalador para preparar el puente.' }
}

async function launch(target) {
  const prepared = await prepareSystem()
  if (!prepared.ok) return prepared
  const script = target === 'codex' ? 'Iniciar-Codex-XHumanX.ps1' : 'Iniciar-Claude-XHumanX.ps1'
  const result = await runPowerShell(path.join(bridge, script), [], 180000)
  return result.ok ? { ok: true, message: (target === 'codex' ? 'Codex' : 'Claude Code') + ' iniciado.' } : result
}

const supportedPlatforms = new Set(['groq', 'google', 'gemini', 'cerebras', 'mistral', 'openrouter', 'huggingface', 'cohere', 'cloudflare', 'zhipu', 'pollinations', 'llm7', 'nvidia', 'longcat', 'volcengine', 'routeway', 'bazaarlink'])

function getDashboardToken() {
  const dir = path.join(process.env.APPDATA || '', 'FreeLLMAPI', 'Local Storage', 'leveldb')
  const files = fs.readdirSync(dir).filter((file) => file.endsWith('.log') || file.endsWith('.ldb'))
  for (const file of files) {
    const text = fs.readFileSync(path.join(dir, file)).toString('latin1')
    const match = text.match(/freellmapi_dashboard_token.{0,180}/)
    const found = match && match[0].match(/[a-f0-9]{64}/i)
    if (found) return found[0]
  }
  return ''
}

function addProvider({ platform, key }) {
  if (!supportedPlatforms.has(platform)) return Promise.resolve({ ok: false, message: 'Proveedor no compatible.' })
  if (typeof key !== 'string' || key.trim().length < 4) return Promise.resolve({ ok: false, message: 'Pega una clave válida.' })
  let token
  try { token = getDashboardToken() } catch { return Promise.resolve({ ok: false, message: 'Abre FreeLLMAPI y vuelve a intentarlo.' }) }
  if (!token) return Promise.resolve({ ok: false, message: 'No se encontró la sesión local de FreeLLMAPI. Abre su panel una vez.' })
  return new Promise((resolve) => {
    const child = spawn('npx.cmd', ['--yes', 'freellmapi', 'keys', 'add', platform, '--url', 'http://127.0.0.1:31415', '--token', token, '--key', key.trim()], { cwd: bridge, windowsHide: true })
    let output = ''
    let error = ''
    child.stdout.on('data', (chunk) => { output += chunk.toString() })
    child.stderr.on('data', (chunk) => { error += chunk.toString() })
    child.on('error', () => resolve({ ok: false, message: 'No se pudo ejecutar npx. Comprueba que Node.js esté instalado.' }))
    child.on('close', (code) => resolve({ ok: code === 0, message: (code === 0 ? output : error || output).trim().slice(-500) || (code === 0 ? 'Clave añadida.' : 'FreeLLMAPI rechazó la clave.') }))
  })
}

ipcMain.handle('launch-agent', (_event, target) => launch(target))
ipcMain.handle('prepare-system', () => prepareSystem())
ipcMain.handle('open-external', (_event, url) => shell.openExternal(url))
ipcMain.handle('add-provider', (_event, payload) => addProvider(payload || {}))
ipcMain.handle('provider-list', async () => {
  const defaults = [
    { name: 'Kilo', platform: 'kilo', status: 'healthy', keyless: true },
    { name: 'OVH', platform: 'ovh', status: 'healthy', keyless: true },
    { name: 'AI Horde', platform: 'aihorde', status: 'healthy', keyless: true }
  ]
  try {
    const token = getDashboardToken()
    if (!token) return defaults
    const response = await fetch('http://127.0.0.1:31415/api/keys', { headers: { Authorization: `Bearer ${token}` } })
    if (!response.ok) return defaults
    const keys = await response.json()
    return keys.map((key) => ({ name: key.platform, platform: key.platform, status: key.status || 'unknown', keyless: Boolean(key.keyless) }))
  } catch { return defaults }
})
ipcMain.handle('service-status', async () => {
  const check = async (port) => { try { await fetch(`http://127.0.0.1:${port}`); return true } catch { return false } }
  return { free: await check(31415), lite: await check(4000) }
})

app.whenReady().then(() => { createWindow(); app.on('activate', () => { if (!BrowserWindow.getAllWindows().length) createWindow() }) })
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit() })
