param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    [switch]$LaunchClaude
)

$ErrorActionPreference = 'Stop'
$appHome = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $appHome 'litellm-ollama.yaml'
$backupPath = Join-Path $appHome 'litellm-ollama.ollama-backup.yaml'
$masterKeyPath = Join-Path $appHome 'master.key'
$liteLlmPath = Join-Path $appHome 'venv\Scripts\litellm.exe'

if ($ApiKey -notmatch '^freellmapi-') { throw 'The key must start with freellmapi-.' }
if (-not (Test-Path -LiteralPath $liteLlmPath)) { throw "LiteLLM not found: $liteLlmPath" }
if (-not (Test-Path -LiteralPath $masterKeyPath)) { throw "Local key not found: $masterKeyPath" }
if (-not (Test-Path -LiteralPath $backupPath)) { Copy-Item -LiteralPath $configPath -Destination $backupPath }

$masterKey = (Get-Content -LiteralPath $masterKeyPath -Raw).Trim()
$quote = [char]34
$lines = @(
    'model_list:',
    '  - model_name: claude-sonnet-4-5',
    '    litellm_params:',
    ('      model: ' + $quote + 'openai/auto:smart' + $quote),
    ('      api_base: ' + $quote + 'http://127.0.0.1:31415/v1' + $quote),
    ('      api_key: ' + $quote + $ApiKey + $quote),
    '      num_retries: 0',
    '      timeout: 120',
    '  - model_name: claude-sonnet-4-5-balanced',
    '    litellm_params:',
    ('      model: ' + $quote + 'openai/auto:balanced' + $quote),
    ('      api_base: ' + $quote + 'http://127.0.0.1:31415/v1' + $quote),
    ('      api_key: ' + $quote + $ApiKey + $quote),
    '      num_retries: 0',
    '      timeout: 120',
    '  - model_name: claude-sonnet-4-5-local',
    '    litellm_params:',
    ('      model: ' + $quote + 'ollama_chat/qwen2.5-coder:1.5b' + $quote),
    ('      api_base: ' + $quote + 'http://127.0.0.1:11434' + $quote),
    '      num_retries: 0',
    '      timeout: 120',
    '  - model_name: gpt-5.6-luna',
    '    litellm_params:',
    ('      model: ' + $quote + 'openai/auto:smart' + $quote),
    ('      api_base: ' + $quote + 'http://127.0.0.1:31415/v1' + $quote),
    ('      api_key: ' + $quote + $ApiKey + $quote),
    '      num_retries: 0',
    '      timeout: 120',
    '  - model_name: gpt-5.6-luna-balanced',
    '    litellm_params:',
    ('      model: ' + $quote + 'openai/auto:balanced' + $quote),
    ('      api_base: ' + $quote + 'http://127.0.0.1:31415/v1' + $quote),
    ('      api_key: ' + $quote + $ApiKey + $quote),
    '      num_retries: 0',
    '      timeout: 120',
    '  - model_name: gpt-5.6-luna-local',
    '    litellm_params:',
    ('      model: ' + $quote + 'ollama_chat/qwen2.5-coder:1.5b' + $quote),
    ('      api_base: ' + $quote + 'http://127.0.0.1:11434' + $quote),
    '      num_retries: 0',
    '      timeout: 120',
    'litellm_settings:',
    '  drop_params: true',
    'router_settings:',
    '  num_retries: 0',
    '  retry_after: 0',
    '  allowed_fails: 1',
    '  cooldown_time: 30',
    '  fallbacks:',
    '    - claude-sonnet-4-5: [claude-sonnet-4-5-balanced, claude-sonnet-4-5-local]',
    '    - gpt-5.6-luna: [gpt-5.6-luna-balanced, gpt-5.6-luna-local]',
    'general_settings:',
    ('  master_key: ' + $quote + $masterKey + $quote)
)
Set-Content -LiteralPath $configPath -Value ($lines -join "`r`n") -Encoding UTF8

$ollama = Get-Command ollama.exe -ErrorAction SilentlyContinue
if ($ollama -and -not (Get-NetTCPConnection -LocalPort 11434 -State Listen -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $ollama.Source -ArgumentList 'serve' -WindowStyle Hidden | Out-Null
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        if (Get-NetTCPConnection -LocalPort 11434 -State Listen -ErrorAction SilentlyContinue) { break }
    }
}

Get-Process -Name litellm -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
Start-Process -FilePath $liteLlmPath -ArgumentList '--config',$configPath,'--host','127.0.0.1','--port','4000','--num_workers','1' -WorkingDirectory $appHome -WindowStyle Hidden | Out-Null

$ready = $false
for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 1
    try {
        Invoke-WebRequest -Uri 'http://127.0.0.1:4000/health/liveliness' -TimeoutSec 2 | Out-Null
        $ready = $true
        break
    } catch { }
}
if (-not $ready) { throw 'LiteLLM did not open port 4000.' }
Write-Host 'FreeLLMAPI to LiteLLM is active on http://127.0.0.1:4000' -ForegroundColor Green

if ($LaunchClaude) {
    $env:ANTHROPIC_BASE_URL = 'http://127.0.0.1:4000'
    $env:ANTHROPIC_AUTH_TOKEN = $masterKey
    $env:ANTHROPIC_API_KEY = ''
    $env:ANTHROPIC_MODEL = 'claude-sonnet-4-5'
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','claude','--model','claude-sonnet-4-5'
}
