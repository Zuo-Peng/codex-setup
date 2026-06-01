# codex-setup

Codex CLI 一键配置脚本(macOS / Linux / Windows)。

运行后按提示粘贴 API Key 即可,脚本会自动写好 `config.toml` 和 `auth.json`。
未安装 Codex CLI 时会提示安装(`npm install -g @openai/codex`)。

## macOS / Linux

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Zuo-Peng/codex-setup@main/codex-setup.sh | bash
```

配置写入 `~/.codex/`。Windows 用户在 **Git Bash** 里也可用这条(同样写入 `C:\Users\<你>\.codex\`)。

## Windows(PowerShell)

```powershell
irm https://cdn.jsdelivr.net/gh/Zuo-Peng/codex-setup@main/codex-setup.ps1 | iex
```

配置写入 `%USERPROFILE%\.codex\`。若 `irm | iex` 拉取异常,可改用 `iwr -useb <url> | iex`。
