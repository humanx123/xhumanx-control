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
$key = $keys | Where-Object { $_.Length -eq 59 } | Select-Object -First 1
if (-not $key) { throw 'Unified FreeLLMAPI key was not found.' }

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $activate -ApiKey $key -LaunchClaude
