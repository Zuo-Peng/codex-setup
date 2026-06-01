# codex-setup

Codex CLI 一键配置脚本(macOS / Linux)。

## 使用

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/<用户名>/codex-setup@main/codex-setup.sh | bash
```

运行后按提示粘贴你的 API Key 即可,脚本会自动写好 `~/.codex/config.toml` 和 `~/.codex/auth.json`。
未安装 Codex CLI 时,脚本会提示安装(`npm install -g @openai/codex`)。
