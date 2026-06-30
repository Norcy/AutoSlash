#!/bin/bash
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${CYAN}[AutoSlash]${NC} $1"; }
ok()    { echo -e "${GREEN}[AutoSlash]${NC} $1"; }

HAMMERSPOON_DIR="$HOME/.hammerspoon"

# 1. 删除 SlashFix.lua
if [ -f "$HAMMERSPOON_DIR/SlashFix.lua" ]; then
  rm "$HAMMERSPOON_DIR/SlashFix.lua"
  ok "SlashFix.lua 已删除"
fi

# 2. 从 init.lua 移除 require("SlashFix")
INIT_LUA="$HAMMERSPOON_DIR/init.lua"
if [ -f "$INIT_LUA" ] && grep -q "require.*SlashFix" "$INIT_LUA"; then
  sed -i '' '/require.*SlashFix/d' "$INIT_LUA"
  ok "init.lua 中的 SlashFix 引用已移除"
fi

# 3. 重载 Hammerspoon
if pgrep -x Hammerspoon &>/dev/null; then
  if command -v hs &>/dev/null && hs -c "hs.reload()" &>/dev/null; then
    ok "Hammerspoon 已重载"
  elif killall Hammerspoon &>/dev/null && open -a Hammerspoon; then
    ok "Hammerspoon 已重启并加载配置"
  fi
fi

echo ""
ok "AutoSlash 已卸载！"
