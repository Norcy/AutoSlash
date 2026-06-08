#!/bin/bash
set -e

# ──────────────────────────────────────────────
# AutoSlash 安装脚本
# 一键安装：curl -sL <URL>/install.sh | bash
# ──────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[AutoSlash]${NC} $1"; }
ok()    { echo -e "${GREEN}[AutoSlash]${NC} $1"; }
warn()  { echo -e "${YELLOW}[AutoSlash]${NC} $1"; }
error() { echo -e "${RED}[AutoSlash]${NC} $1"; exit 1; }

HAMMERSPOON_DIR="$HOME/.hammerspoon"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 1. 检查 / 安装 Homebrew ──────────────────
if ! command -v brew &>/dev/null; then
  info "安装 Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # 让 brew 立即可用
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
ok "Homebrew 就绪"

# ── 2. 检查 / 安装 Hammerspoon ──────────────
if ! ls /Applications/Hammerspoon.app &>/dev/null; then
  info "安装 Hammerspoon..."
  brew install --cask hammerspoon
fi
ok "Hammerspoon 就绪"

# ── 3. 部署 SlashFix.lua ────────────────────
mkdir -p "$HAMMERSPOON_DIR"

# 优先从脚本同目录复制，否则从仓库下载
if [ -f "$SCRIPT_DIR/SlashFix.lua" ]; then
  cp "$SCRIPT_DIR/SlashFix.lua" "$HAMMERSPOON_DIR/SlashFix.lua"
  ok "SlashFix.lua 已从本地复制"
else
  # 如果是远程执行，从 GitLab 下载
  REMOTE_URL="https://git.corp.kuaishou.com/chenying09/autoslash/-/raw/master/SlashFix.lua"
  info "从仓库下载 SlashFix.lua..."
  curl -sL "$REMOTE_URL" -o "$HAMMERSPOON_DIR/SlashFix.lua"
  ok "SlashFix.lua 已下载"
fi

# ── 4. 配置 init.lua ────────────────────────
INIT_LUA="$HAMMERSPOON_DIR/init.lua"

if [ ! -f "$INIT_LUA" ]; then
  cat > "$INIT_LUA" <<'EOF'
-- Hammerspoon 配置入口
hs.ipc.cliInstall()
require("SlashFix")
EOF
  ok "init.lua 已创建"
else
  if grep -q "require.*SlashFix" "$INIT_LUA" 2>/dev/null; then
    ok "init.lua 已包含 SlashFix，跳过"
  else
    echo 'require("SlashFix")' >> "$INIT_LUA"
    ok "SlashFix 已追加到 init.lua"
  fi
fi

# ── 5. 启动 / 重载 Hammerspoon ──────────────
if pgrep -x Hammerspoon &>/dev/null; then
  if command -v hs &>/dev/null; then
    hs -c "hs.reload()" &>/dev/null && ok "Hammerspoon 已重载配置" || warn "重载失败，请手动点击菜单栏 → Reload Config"
  else
    warn "未找到 hs CLI，请手动点击菜单栏 Hammerspoon → Reload Config"
  fi
else
  open -a Hammerspoon
  ok "Hammerspoon 已启动"
fi

# ── 6. 提示授权 ─────────────────────────────
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  AutoSlash 安装完成！${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}  ⚠  首次使用需要授权辅助功能权限：${NC}"
echo ""
echo -e "  1. 系统会弹出权限弹窗，点击 ${BOLD}「打开系统设置」${NC}"
echo -e "  2. 在 ${BOLD}隐私与安全性 → 辅助功能${NC} 中勾选 Hammerspoon"
echo -e "  3. 如果没有弹窗，手动打开："
echo -e "     ${CYAN}系统设置 → 隐私与安全性 → 辅助功能${NC}"
echo -e "     找到 Hammerspoon 并打勾 ✅"
echo ""
echo -e "  授权后 Hammerspoon 会自动生效，无需重启"
echo ""
echo -e "  验证：打开 iTerm2，标题含 claude/jarvis/codex 等，"
echo -e "  中文输入法下按 ${BOLD}、${NC} 键 → 应该输出 ${BOLD}/${NC}"
echo ""
