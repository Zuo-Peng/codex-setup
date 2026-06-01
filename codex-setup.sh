#!/usr/bin/env bash
#
# Codex 中转站一键配置脚本
# 用户用法(推荐, 跑完按提示粘贴 API Key):
#   curl -fsSL https://你的域名/codex-setup.sh | bash
# 也可直接带 key 参数(非交互):
#   curl -fsSL https://你的域名/codex-setup.sh | bash -s -- <API_KEY>
#   bash codex-setup.sh <API_KEY>
#
set -euo pipefail

# ============ 运营方需要修改的配置 ============
RELAY_BASE_URL="https://codex.gogogpt.net"     # 中转站 base_url(注意: 不带 /v1)
DEFAULT_MODEL="gpt-5.5"                          # 默认模型
PROVIDER_ID="OpenAI"                             # provider 标识
PROVIDER_NAME="OpenAI"                           # 显示名
# =============================================

CODEX_DIR="$HOME/.codex"
CONFIG_FILE="$CODEX_DIR/config.toml"
AUTH_FILE="$CODEX_DIR/auth.json"

# 是否已安装 Codex CLI
codex_installed() { command -v codex >/dev/null 2>&1; }

# 终端是否真正可交互(能打开 /dev/tty)。CI/纯管道下打不开, 静默判否。
tty_available() { { true < /dev/tty; } 2>/dev/null; }

# 读取 y/n。兼容 curl|bash: 此时 stdin 是脚本本身, 从 /dev/tty 读真实键盘输入。
# 无法交互(无 tty)时返回非 0(视为 No), 不阻塞自动化场景。
prompt_yes_no() {
  local ans=""
  tty_available || return 1
  printf '%s' "$1" > /dev/tty
  read -r ans < /dev/tty 2>/dev/null || ans=""
  case "$ans" in [yY]*) return 0 ;; *) return 1 ;; esac
}

# 获取 API Key: 优先用命令行参数; 否则交互式让用户粘贴。
# curl|bash 时 stdin 被脚本占用, 同样从 /dev/tty 读键盘输入。
API_KEY="${1:-}"
if [ -z "$API_KEY" ]; then
  if tty_available; then
    printf '请粘贴你的 API Key 后回车: ' > /dev/tty
    read -r API_KEY < /dev/tty 2>/dev/null || API_KEY=""
  fi
fi
# 去掉首尾空白
API_KEY="$(printf '%s' "$API_KEY" | tr -d '[:space:]')"
if [ -z "$API_KEY" ]; then
  echo "未输入 API Key, 已取消。" >&2
  echo "可重试(交互): curl -fsSL <脚本地址> | bash" >&2
  echo "或带参数:    bash codex-setup.sh <你的API_KEY>" >&2
  exit 1
fi

mkdir -p "$CODEX_DIR"

# 备份已有配置(兼容 macOS 自带 bash 3.2)
ts="$(date +%Y%m%d%H%M%S)"
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$ts"
  echo "已备份旧 config.toml -> config.toml.bak.$ts"
fi
if [ -f "$AUTH_FILE" ]; then
  cp "$AUTH_FILE" "$AUTH_FILE.bak.$ts"
  echo "已备份旧 auth.json -> auth.json.bak.$ts"
fi

# 写 config.toml
cat > "$CONFIG_FILE" <<EOF
model_provider = "$PROVIDER_ID"
model = "$DEFAULT_MODEL"
review_model = "$DEFAULT_MODEL"
model_reasoning_effort = "xhigh"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true

[model_providers.$PROVIDER_ID]
name = "$PROVIDER_NAME"
base_url = "$RELAY_BASE_URL"
wire_api = "responses"
requires_openai_auth = true

[features]
goals = true
EOF

# 写 auth.json(Codex 从这里读 OPENAI_API_KEY 鉴权)
cat > "$AUTH_FILE" <<EOF
{
  "OPENAI_API_KEY": "$API_KEY"
}
EOF
chmod 600 "$AUTH_FILE"

echo ""
echo "配置完成"
echo "  config: $CONFIG_FILE"
echo "  中转站: $RELAY_BASE_URL"
echo "  模型:   $DEFAULT_MODEL"
echo ""

# 检测 Codex CLI; 未安装则提醒并尝试交互式安装
if codex_installed; then
  echo "现在直接运行即可: codex"
else
  echo "注意: 还没装 Codex CLI, 装好后即可使用上面的配置。"
  if command -v npm >/dev/null 2>&1; then
    if prompt_yes_no "是否现在用 npm 全局安装 Codex CLI? [y/N] "; then
      if npm install -g @openai/codex; then
        echo "安装完成, 现在运行: codex"
      else
        echo "安装失败, 请手动执行: npm install -g @openai/codex"
      fi
    else
      echo "稍后手动安装: npm install -g @openai/codex"
    fi
  else
    echo "未检测到 npm, 请先安装 Node.js, 再执行其一:"
    echo "  npm install -g @openai/codex"
    echo "  brew install codex"
  fi
fi
