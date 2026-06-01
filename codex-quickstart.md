# Codex 一键配置

一行命令搞定,无需手动创建或编辑配置文件。请按你的系统选择对应命令。

## 第一步:执行一键配置命令

### macOS / Linux

在终端粘贴执行(Windows 用户在 **Git Bash** 里也可用这条):

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Zuo-Peng/codex-setup@main/codex-setup.sh | bash
```

### Windows(PowerShell)

在 PowerShell 里粘贴执行:

```powershell
irm https://cdn.jsdelivr.net/gh/Zuo-Peng/codex-setup@main/codex-setup.ps1 | iex
```

执行后会提示你粘贴 **API Key**(可在左侧「API 密钥」页面复制),粘贴后回车即可。脚本会自动写好 `config.toml` 和 `auth.json`。

## 第二步:开始使用

配置完成后,直接运行:

```bash
codex
```

## 还没装 Codex CLI?

脚本检测到未安装时会提示你。也可以先手动安装(任选其一):

```bash
npm install -g @openai/codex
# 或
brew install codex
```

装好后回到第一步执行那条命令即可。

---

### 备用:手动配置(一般用不到)

如果上面的命令在你的网络环境下无法访问,可手动创建配置。把下面整段复制到终端(Windows 用 Git Bash),**替换其中的 `在这里粘贴你的API_KEY`** 后执行:

```bash
mkdir -p ~/.codex
cat > ~/.codex/config.toml <<'EOF'
model_provider = "OpenAI"
model = "gpt-5.5"
review_model = "gpt-5.5"
model_reasoning_effort = "xhigh"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true

[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://codex.gogogpt.net"
wire_api = "responses"
requires_openai_auth = true

[features]
goals = true
EOF
cat > ~/.codex/auth.json <<'EOF'
{
  "OPENAI_API_KEY": "在这里粘贴你的API_KEY"
}
EOF
echo "配置完成,直接运行 codex 即可。"
```
