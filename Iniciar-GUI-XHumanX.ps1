$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$handler = Join-Path $root 'Handle-XHumanX.ps1'
$icon = 'C:\Users\fidel\AppData\Local\ClaudeOllamaBridge\XHumanX-IA.ico'
$protocol = 'HKCU:\Software\Classes\xhumanx'
New-Item -Path "$protocol\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path $protocol -Name '(Default)' -Value 'URL:XHumanX Control Protocol'
Set-ItemProperty -Path $protocol -Name 'URL Protocol' -Value ''
New-Item -Path "$protocol\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$protocol\DefaultIcon" -Name '(Default)' -Value "$icon,0"
$command = "`"$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe`" -NoProfile -ExecutionPolicy Bypass -File `"$handler`" `"%1`""
Set-ItemProperty -Path "$protocol\shell\open\command" -Name '(Default)' -Value $command

if (-not (Test-Path (Join-Path $root 'dist\index.html'))) {
    Start-Process -FilePath 'npm.cmd' -ArgumentList 'run','build' -WorkingDirectory $root -Wait -WindowStyle Hidden
}
Start-Process -FilePath 'npm.cmd' -ArgumentList 'run','desktop' -WorkingDirectory $root -WindowStyle Hidden
