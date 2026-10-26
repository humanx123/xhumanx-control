param([string]$Uri)
$bridge = 'C:\Users\fidel\AppData\Local\ClaudeOllamaBridge'
$target = if ($Uri -match 'codex') { 'Iniciar-Codex-XHumanX.ps1' } else { 'Iniciar-Claude-XHumanX.ps1' }
$script = Join-Path $bridge $target
if (-not (Test-Path -LiteralPath $script)) { throw "Launcher not found: $script" }
Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$script -WorkingDirectory $bridge
