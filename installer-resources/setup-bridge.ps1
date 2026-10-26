$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$bridge = Join-Path $env:LOCALAPPDATA 'ClaudeOllamaBridge'
$apps = Join-Path $env:LOCALAPPDATA 'XHumanX\Apps'
$freeHome = Join-Path $apps 'FreeLLMAPI'
$resource = Split-Path -Parent $MyInvocation.MyCommand.Path
$freeApp = Join-Path $freeHome 'FreeLLMAPI.exe'
$freePortFile = Join-Path $bridge 'freellmapi-port.txt'
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
if (Test-Path $freeApp) {
  $freePort = 31415
  $freeConfig = Join-Path $env:APPDATA 'FreeLLMAPI\config.json'
  if (Test-Path $freeConfig) {
    try {
      $configuredPort = ([int](Get-Content $freeConfig -Raw | ConvertFrom-Json).port)
      if ($configuredPort -ge 1 -and $configuredPort -le 65535) { $freePort = $configuredPort }
    } catch { }
  }
  $freeAlreadyReady = [bool](Get-NetTCPConnection -LocalPort $freePort -State Listen -ErrorAction SilentlyContinue)
  if ($freeAlreadyReady) { Set-Content $freePortFile $freePort -NoNewline }
}
if ((Test-Path $freeApp) -and -not (Get-NetTCPConnection -LocalPort $freePort -State Listen -ErrorAction SilentlyContinue)) {
  Start-Process $freeApp -WorkingDirectory $freeHome | Out-Null
  $freeReady = $false
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 1
    foreach ($candidatePort in (31415..31465)) {
      if (Get-NetTCPConnection -LocalPort $candidatePort -State Listen -ErrorAction SilentlyContinue) { $freePort = $candidatePort; $freeReady = $true; break }
    }
    if ($freeReady) { Set-Content $freePortFile $freePort -NoNewline; break }
  }
  if (-not $freeReady) { throw 'FreeLLMAPI no abrió ningún puerto entre 31415 y 31465. Revisa %APPDATA%\FreeLLMAPI\logs.' }
}
if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
  if (-not (Get-Command claude.cmd -ErrorAction SilentlyContinue) -and -not (Get-Command claude.exe -ErrorAction SilentlyContinue)) { npm.cmd install --global @anthropic-ai/claude-code }
  if (-not (Get-Command codex.cmd -ErrorAction SilentlyContinue) -and -not (Get-Command codex.exe -ErrorAction SilentlyContinue)) { npm.cmd install --global @openai/codex }
}
Write-Host 'XHumanX Control preparado. Abre la aplicación y configura tu clave unificada.'
