$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$bridge = Join-Path $env:LOCALAPPDATA 'ClaudeOllamaBridge'
$apps = Join-Path $env:LOCALAPPDATA 'XHumanX\Apps'
$freeHome = Join-Path $apps 'FreeLLMAPI'
$resource = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Force -Path $bridge,$apps | Out-Null
Copy-Item (Join-Path $resource 'bridge\*') $bridge -Force
if (-not (Test-Path (Join-Path $bridge 'master.key'))) {
  $bytes = New-Object byte[] 32
  [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  [Convert]::ToBase64String($bytes) | Set-Content (Join-Path $bridge 'master.key') -NoNewline
}
if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
  if (-not (Get-Command py.exe -ErrorAction SilentlyContinue)) { winget install --id Python.Python.3.11 --scope user --silent --accept-package-agreements --accept-source-agreements }
  if (-not (Get-Command ollama.exe -ErrorAction SilentlyContinue)) { winget install --id Ollama.Ollama --scope user --silent --accept-package-agreements --accept-source-agreements }
}
if (Get-Command py.exe -ErrorAction SilentlyContinue -and -not (Test-Path (Join-Path $bridge 'venv\Scripts\litellm.exe'))) {
  & py.exe -3 -m venv (Join-Path $bridge 'venv')
  & (Join-Path $bridge 'venv\Scripts\python.exe') -m pip install --upgrade pip
  & (Join-Path $bridge 'venv\Scripts\python.exe') -m pip install 'litellm[proxy]'
}
if (-not (Test-Path (Join-Path $freeHome 'FreeLLMAPI.exe'))) {
  $zip = Join-Path $env:TEMP 'FreeLLMAPI-win.zip'
  Invoke-WebRequest 'https://github.com/tashfeenahmed/freellmapi/releases/download/v0.16.10/FreeLLMAPI-0.16.10-win.zip' -OutFile $zip
  New-Item -ItemType Directory -Force -Path $freeHome | Out-Null
  Expand-Archive $zip -DestinationPath $freeHome -Force
  $candidate = Get-ChildItem $freeHome -Filter FreeLLMAPI.exe -Recurse | Select-Object -First 1
  if ($candidate -and $candidate.DirectoryName -ne $freeHome) { Copy-Item $candidate.FullName (Join-Path $freeHome 'FreeLLMAPI.exe') -Force }
}
if (Test-Path (Join-Path $freeHome 'FreeLLMAPI.exe')) {
  (Get-Content (Join-Path $bridge 'Iniciar-Claude-XHumanX.ps1') -Raw).Replace('C:\Users\fidel\Apps\FreeLLMAPI\FreeLLMAPI.exe',(Join-Path $freeHome 'FreeLLMAPI.exe')) | Set-Content (Join-Path $bridge 'Iniciar-Claude-XHumanX.ps1')
  (Get-Content (Join-Path $bridge 'Iniciar-Codex-XHumanX.ps1') -Raw).Replace('C:\Users\fidel\Apps\FreeLLMAPI\FreeLLMAPI.exe',(Join-Path $freeHome 'FreeLLMAPI.exe')) | Set-Content (Join-Path $bridge 'Iniciar-Codex-XHumanX.ps1')
}
if ((Test-Path (Join-Path $freeHome 'FreeLLMAPI.exe')) -and -not (Get-NetTCPConnection -LocalPort 31415 -State Listen -ErrorAction SilentlyContinue)) { Start-Process (Join-Path $freeHome 'FreeLLMAPI.exe') -WorkingDirectory $freeHome | Out-Null }
if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
  if (-not (Get-Command claude.cmd -ErrorAction SilentlyContinue) -and -not (Get-Command claude.exe -ErrorAction SilentlyContinue)) { npm.cmd install --global @anthropic-ai/claude-code }
  if (-not (Get-Command codex.cmd -ErrorAction SilentlyContinue) -and -not (Get-Command codex.exe -ErrorAction SilentlyContinue)) { npm.cmd install --global @openai/codex }
}
Write-Host 'XHumanX Control preparado. Abre la aplicación y configura tu clave unificada.'
