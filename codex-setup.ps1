# Codex relay one-click setup script (Windows / PowerShell)
#
# Recommended usage (paste your API Key when prompted):
#   irm https://your-domain/codex-setup.ps1 | iex
# Or download and run:
#   powershell -ExecutionPolicy Bypass -File codex-setup.ps1

$ErrorActionPreference = 'Stop'

# Force UTF-8 console output so messages render correctly on legacy code pages
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ============ Operator-editable config ============
$RelayBaseUrl = 'https://codex.gogogpt.net'   # relay base_url (note: no /v1 suffix)
$DefaultModel = 'gpt-5.5'                       # default model
$ProviderId   = 'OpenAI'                        # provider id
$ProviderName = 'OpenAI'                        # provider display name
# ==================================================

$CodexDir   = Join-Path $env:USERPROFILE '.codex'
$ConfigFile = Join-Path $CodexDir 'config.toml'
$AuthFile   = Join-Path $CodexDir 'auth.json'

# Get API Key (interactive; under irm|iex, Read-Host still reads from the console)
$ApiKey = (Read-Host 'Paste your API Key and press Enter').Trim()
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host 'No API Key entered, aborted.' -ForegroundColor Red
    return
}

New-Item -ItemType Directory -Force -Path $CodexDir | Out-Null

# Back up existing config
$ts = Get-Date -Format 'yyyyMMddHHmmss'
if (Test-Path $ConfigFile) {
    Copy-Item $ConfigFile "$ConfigFile.bak.$ts" -Force
    Write-Host "Backed up old config.toml -> config.toml.bak.$ts"
}
if (Test-Path $AuthFile) {
    Copy-Item $AuthFile "$AuthFile.bak.$ts" -Force
    Write-Host "Backed up old auth.json -> auth.json.bak.$ts"
}

# config.toml content
$configContent = @"
model_provider = "$ProviderId"
model = "$DefaultModel"
review_model = "$DefaultModel"
model_reasoning_effort = "xhigh"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true

[model_providers.$ProviderId]
name = "$ProviderName"
base_url = "$RelayBaseUrl"
wire_api = "responses"
requires_openai_auth = true

[features]
goals = true
"@

# auth.json content (use ConvertTo-Json for correct escaping)
$authContent = [ordered]@{ OPENAI_API_KEY = $ApiKey } | ConvertTo-Json

# Write files: UTF-8 without BOM (TOML/JSON parsers are sensitive to BOM)
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ConfigFile, $configContent, $enc)
[System.IO.File]::WriteAllText($AuthFile, $authContent, $enc)

Write-Host ''
Write-Host 'Setup complete' -ForegroundColor Green
Write-Host "  config: $ConfigFile"
Write-Host "  relay:  $RelayBaseUrl"
Write-Host "  model:  $DefaultModel"
Write-Host ''

# Detect Codex CLI; if missing, prompt and try interactive install
if (Get-Command codex -ErrorAction SilentlyContinue) {
    Write-Host 'You can run it now: codex'
} else {
    Write-Host 'Note: Codex CLI is not installed yet; once installed it will use the config above.' -ForegroundColor Yellow
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $ans = Read-Host 'Install Codex CLI globally via npm now? [y/N]'
        if ($ans -match '^[yY]') {
            npm install -g '@openai/codex'
            if ($LASTEXITCODE -eq 0) {
                Write-Host 'Installed. Now run: codex'
            } else {
                Write-Host 'Install failed. Run manually: npm install -g @openai/codex'
            }
        } else {
            Write-Host 'Install later manually: npm install -g @openai/codex'
        }
    } else {
        Write-Host 'npm not found. Install Node.js first, then run: npm install -g @openai/codex'
    }
}
