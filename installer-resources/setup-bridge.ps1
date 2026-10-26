$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$bridge = Join-Path $env:LOCALAPPDATA 'ClaudeOllamaBridge'
$apps = Join-Path $env:LOCALAPPDATA 'XHumanX\Apps'
$freeHome = Join-Path $apps 'FreeLLMAPI'
$resource = Split-Path -Parent $MyInvocation.MyCommand.Path
$freeApp = Join-Path $freeHome 'FreeLLMAPI.exe'
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
if ((Get-Command py.exe -ErrorAction SilentlyContinue) -and -not (Test-Path (Join-Path $bridge 'venv\Scripts\litellm.exe'))) {
  & py.exe -3 -m venv (Join-Path $bridge 'venv')
  & (Join-Path $bridge 'venv\Scripts\python.exe') -m pip install --upgrade pip
  & (Join-Path $bridge 'venv\Scripts\python.exe') -m pip install 'litellm[proxy]'
}
if (-not (Test-Path $freeApp)) {
  $zip = Join-Path $env:TEMP 'FreeLLMAPI-win.zip'
  Invoke-WebRequest 'https://github.com/tashfeenahmed/freellmapi/releases/download/v0.16.10/FreeLLMAPI-0.16.10-win.zip' -OutFile $zip
  New-Item -ItemType Directory -Force -Path $freeHome | Out-Null
  Expand-Archive $zip -DestinationPath $freeHome -Force
  $candidate = Get-ChildItem $freeHome -Filter FreeLLMAPI.exe -Recurse | Select-Object -First 1
  if ($candidate -and $candidate.DirectoryName -ne $freeHome) { Copy-Item $candidate.FullName $freeApp -Force }
}
if (Test-Path $freeApp) {
  (Get-Content (Join-Path $bridge 'Iniciar-Claude-XHumanX.ps1') -Raw).Replace('C:\Users\fidel\Apps\FreeLLMAPI\FreeLLMAPI.exe',(Join-Path $freeHome 'FreeLLMAPI.exe')) | Set-Content (Join-Path $bridge 'Iniciar-Claude-XHumanX.ps1')
  (Get-Content (Join-Path $bridge 'Iniciar-Codex-XHumanX.ps1') -Raw).Replace('C:\Users\fidel\Apps\FreeLLMAPI\FreeLLMAPI.exe',(Join-Path $freeHome 'FreeLLMAPI.exe')) | Set-Content (Join-Path $bridge 'Iniciar-Codex-XHumanX.ps1')
}
if ((Test-Path $freeApp) -and -not (Get-NetTCPConnection -LocalPort 31415 -State Listen -ErrorAction SilentlyContinue)) {
  Start-Process $freeApp -WorkingDirectory $freeHome | Out-Null
  $freeReady = $false
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 1
    if (Get-NetTCPConnection -LocalPort 31415 -State Listen -ErrorAction SilentlyContinue) { $freeReady = $true; break }
  }
  if (-not $freeReady) { throw 'FreeLLMAPI no abrió el puerto 31415. Abre su panel o revisa el firewall.' }
}
if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
  if (-not (Get-Command claude.cmd -ErrorAction SilentlyContinue) -and -not (Get-Command claude.exe -ErrorAction SilentlyContinue)) { npm.cmd install --global @anthropic-ai/claude-code }
  if (-not (Get-Command codex.cmd -ErrorAction SilentlyContinue) -and -not (Get-Command codex.exe -ErrorAction SilentlyContinue)) { npm.cmd install --global @openai/codex }
}
Write-Host 'XHumanX Control preparado. Abre la aplicación y configura tu clave unificada.'
