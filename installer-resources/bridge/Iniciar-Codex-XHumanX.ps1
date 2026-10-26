$ErrorActionPreference = 'Stop'
$bridge = Split-Path -Parent $MyInvocation.MyCommand.Path
$freeApp = 'C:\Users\fidel\Apps\FreeLLMAPI\FreeLLMAPI.exe'
$activate = Join-Path $bridge 'Activar-FreeLLMAPI.ps1'

if (-not (Get-NetTCPConnection -LocalPort 31415 -State Listen -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path -LiteralPath $freeApp)) { throw "FreeLLMAPI not found: $freeApp" }
    Start-Process -FilePath $freeApp -WorkingDirectory (Split-Path $freeApp)
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        if (Get-NetTCPConnection -LocalPort 31415 -State Listen -ErrorAction SilentlyContinue) { $ready = $true; break }
    }
    if (-not $ready) { throw 'FreeLLMAPI did not open port 31415.' }
}

$keys = rg -a -o 'freellmapi-[A-Za-z0-9_-]+' "$env:APPDATA\FreeLLMAPI" -g '*' |
    ForEach-Object { [regex]::Match($_, 'freellmapi-[A-Za-z0-9_-]+').Value } |
    Sort-Object -Unique
$unifiedKey = $keys | Where-Object { $_.Length -eq 59 } | Select-Object -First 1
if (-not $unifiedKey) { throw 'Unified FreeLLMAPI key was not found.' }

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $activate -ApiKey $unifiedKey
$env:OPENAI_BASE_URL = 'http://127.0.0.1:4000/v1'
$env:OPENAI_API_KEY = (Get-Content -LiteralPath (Join-Path $bridge 'master.key') -Raw).Trim()
$env:OPENAI_MODEL = 'gpt-5.6-luna'
Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','codex','-m','gpt-5.6-luna'
