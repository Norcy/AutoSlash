--- SlashFix: AI 终端下顿号自动转斜杠、全角感叹号自动转半角
---
--- 规则：
---   、 → /     （AI 终端 + 中文输入法下，所有顿号自动转斜杠）
---   、、 → 、   （连续两个顿号反转义为一个顿号，需要顿号时用）
---   ！ → !     （全角感叹号自动转半角）
---   ！！ → ！  （连续两个感叹号反转义为一个全角感叹号）
---
--- 条件：受支持的终端标题含 claude/codex 等，或已知 AI 客户端 + 中文输入法

local M = {}

M.config = {
  aiTerminals = {
    ["iTerm"] = true, ["iTerm2"] = true, ["Terminal"] = true,
    ["Warp"] = true, ["Alacritty"] = true, ["kitty"] = true,
    ["Hyper"] = true, ["WezTerm"] = true, ["Ghostty"] = true,
  },
  aiApps = { ["Codex"] = true, ["Claude"] = true },
  aiKeywords = { "claude", "aider", "copilot", "cursor", "cline", "codex", "codeflicker", "cf" },
  enabled = true,
  showNotification = true,
  debug = false,
}

local _converting     = false
local _keyTap         = nil
local _lastDunhaoTime = 0
local _lastBangTime   = 0
local DOUBLETAP_MS    = 500

local function log(msg)
  if M.config.debug then
    print("[SlashFix] " .. msg)
    local f = io.open("/tmp/slashfix.log", "a")
    if f then f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n"); f:close() end
  end
end

local function configuredAppContains(apps, value)
  if not value then return false end
  value = value:lower()
  for name, enabled in pairs(apps or {}) do
    if enabled and type(name) == "string" and name:lower() == value then
      return true
    end
  end
  return false
end

local function containsAIKeyword(value)
  value = (value or ""):lower()
  for _, kw in ipairs(M.config.aiKeywords or {}) do
    if type(kw) == "string" and value:find(kw:lower(), 1, true) then
      return true
    end
  end
  return false
end

local function isAITerminal()
  local win = hs.window.focusedWindow()
  if not win then return false end
  local app = win:application()
  if not app then return false end

  local appName = app:name()
  if configuredAppContains(M.config.aiApps, appName) then return true end
  if not configuredAppContains(M.config.aiTerminals, appName) then return false end

  return containsAIKeyword(win:title())
end

local function isChineseInput()
  local id = hs.keycodes.currentSourceID()
  if not id then return false end
  if id:find("ABC") or id:find("U%.S%.") or id:find("USExtended") then return false end
  local patterns = {
    "[Cc]hinese", "[Pp]inyin", "[Ww]ubi", "SCIM",
    "Sogou", "sogou", "Rime", "rime",
    "Baidu", "baidu", "百度", "搜狗", "鼠鬚管", "doubaoime",
  }
  for _, p in ipairs(patterns) do
    if id:find(p) then return true end
  end
  return false
end

local function onKeyEvent(event)
  if _converting then return false end

  local keyCode = event:getKeyCode()
  local flags   = event:getFlags()

  -- 快速短路：只处理顿号键(44) 或 Shift+1(18, 全角！)
  local isDunhao = (keyCode == 44) and not (flags.ctrl or flags.cmd or flags.alt or flags.shift)
  local isBang   = (keyCode == 18) and flags.shift and not (flags.ctrl or flags.cmd or flags.alt)
  if not (isDunhao or isBang) then return false end

  -- 开关关闭时不处理
  if not M.config.enabled then return false end

  -- 条件判断
  if not (isAITerminal() and isChineseInput()) then return false end

  local now = hs.timer.secondsSinceEpoch()

  if isDunhao then
    local elapsed = (now - _lastDunhaoTime) * 1000
    _lastDunhaoTime = now

    -- 连续两个顿号 → 反转义为一个顿号
    if elapsed < DOUBLETAP_MS then
      log("、、→ 、")
      _converting = true
      hs.eventtap.keyStroke({}, 51)  -- Backspace
      hs.timer.doAfter(0.03, function()
        hs.eventtap.keyStrokes("、")
        hs.timer.doAfter(0.05, function() _converting = false end)
      end)
      return true
    end

    -- 单个顿号 → /
    log("、→ /")
    _converting = true
    hs.eventtap.keyStrokes("/")
    hs.timer.doAfter(0.05, function() _converting = false end)
    return true
  end

  -- isBang: 全角！处理
  local elapsed = (now - _lastBangTime) * 1000
  _lastBangTime = now

  -- 连续两个感叹号 → 反转义为一个全角感叹号
  if elapsed < DOUBLETAP_MS then
    log("！！→ ！")
    _converting = true
    hs.eventtap.keyStroke({}, 51)  -- Backspace
    hs.timer.doAfter(0.03, function()
      hs.eventtap.keyStrokes("！")
      hs.timer.doAfter(0.05, function() _converting = false end)
    end)
    return true
  end

  -- 单个全角！ → !
  log("！→ !")
  _converting = true
  hs.eventtap.keyStrokes("!")
  hs.timer.doAfter(0.05, function() _converting = false end)
  return true
end

function M.start()
  if _keyTap then _keyTap:stop() end
  _keyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, onKeyEvent)
  _keyTap:start()
  log("已启动 (、→/  、、→、  ！→!  ！！→！)")
end

function M.stop()
  if _keyTap then _keyTap:stop(); _keyTap = nil end
end

function M.toggleDebug(on)
  M.config.debug = on
  log("调试模式 " .. (on and "开启" or "关闭"))
end

M.start()
return M
