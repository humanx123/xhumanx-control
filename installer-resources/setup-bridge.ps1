$ErrorActionPreference = 'Stop'
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
if (-not (Get-Command py.exe -ErrorAction SilentlyContinue)) {
  if (Get-Command winget.exe -ErrorAction SilentlyContinue) { winget install --id Python.Python.3.11 --scope user --silent --accept-package-agreements --accept-source-agreements }
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
Write-Host 'XHumanX Control preparado. Abre la aplicación y configura tu clave unificada.'
