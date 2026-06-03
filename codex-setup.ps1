# Codex 中转站一键配置脚本 (Windows / PowerShell)
#
# 用法(推荐, 跑完按提示粘贴 API Key):
#   irm https://你的域名/codex-setup.ps1 | iex
# 或下载后运行:
#   powershell -ExecutionPolicy Bypass -File codex-setup.ps1

$ErrorActionPreference = 'Stop'

# ============ 运营方需要修改的配置 ============
$RelayBaseUrl = 'https://codex.gogogpt.net'   # 中转站 base_url(注意: 不带 /v1)
$DefaultModel = 'gpt-5.5'                       # 默认模型
$ProviderId   = 'OpenAI'                        # provider 标识
$ProviderName = 'OpenAI'                        # 显示名
# =============================================

$CodexDir   = Join-Path $env:USERPROFILE '.codex'
$ConfigFile = Join-Path $CodexDir 'config.toml'
$AuthFile   = Join-Path $CodexDir 'auth.json'

# 获取 API Key(交互式; irm|iex 下 Read-Host 仍从控制台读取)
$ApiKey = (Read-Host '请粘贴你的 API Key 后回车').Trim()
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host '未输入 API Key, 已取消。' -ForegroundColor Red
    return
}

New-Item -ItemType Directory -Force -Path $CodexDir | Out-Null

# 备份已有配置
$ts = Get-Date -Format 'yyyyMMddHHmmss'
if (Test-Path $ConfigFile) {
    Copy-Item $ConfigFile "$ConfigFile.bak.$ts" -Force
    Write-Host "已备份旧 config.toml -> config.toml.bak.$ts"
}
if (Test-Path $AuthFile) {
    Copy-Item $AuthFile "$AuthFile.bak.$ts" -Force
    Write-Host "已备份旧 auth.json -> auth.json.bak.$ts"
}

# config.toml 内容
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

# auth.json 内容(用 ConvertTo-Json 正确转义)
$authContent = [ordered]@{ OPENAI_API_KEY = $ApiKey } | ConvertTo-Json

# 写文件: UTF-8 无 BOM(TOML/JSON 解析器对 BOM 敏感)
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ConfigFile, $configContent, $enc)
[System.IO.File]::WriteAllText($AuthFile, $authContent, $enc)

Write-Host ''
Write-Host '配置完成' -ForegroundColor Green
Write-Host "  config: $ConfigFile"
Write-Host "  中转站: $RelayBaseUrl"
Write-Host "  模型:   $DefaultModel"
Write-Host ''

# 检测 Codex CLI; 未安装则提示并尝试交互式安装
if (Get-Command codex -ErrorAction SilentlyContinue) {
    Write-Host '现在直接运行即可: codex'
} else {
    Write-Host '注意: 还没装 Codex CLI, 装好后即可使用上面的配置。' -ForegroundColor Yellow
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $ans = Read-Host '是否现在用 npm 全局安装 Codex CLI? [y/N]'
        if ($ans -match '^[yY]') {
            npm install -g '@openai/codex'
            if ($LASTEXITCODE -eq 0) {
                Write-Host '安装完成, 现在运行: codex'
            } else {
                Write-Host '安装失败, 请手动执行: npm install -g @openai/codex'
            }
        } else {
            Write-Host '稍后手动安装: npm install -g @openai/codex'
        }
    } else {
        Write-Host '未检测到 npm, 请先安装 Node.js, 再执行: npm install -g @openai/codex'
    }
}
