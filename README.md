# AutoSlash

使用 Claude Code / Codex 等 AI 终端时，绝大部分都是处于中文输入法状态，而一些常用的命令（如 `/status`、`/resume`、`/skills`）需要频繁输入 `/` 开头的命令，故经常输入为顿号 `、`，导致每次都要删除后重打，非常烦，而目前各大主流输入法（搜狗、豆包、微信）均无法解决该问题

使用本工具可以无感解决该问题，AI 命令行模式下，会自动将顿号转为 `/`，也支持将 `！` 转换为 `!`

如果你需要键入顿号，可以连按两下 `/` 即可自动转化为顿号

## 一键安装

```bash
curl -sL https://github.com/Norcy/autoslash/blob/master/install.sh | bash
```

**⚠️ 安装后必须授权：** 系统设置 → 隐私与安全性 → 辅助功能 → 勾选 Hammerspoon ✅，否则不生效

**💡 建议设置开机自启：** 点击菜单栏 Hammerspoon 图标 → Preferences → 勾选「Launch Hammerspoon at login」

## 一键卸载

```bash
curl -sL https://github.com/Norcy/autoslash/blob/master/uninstall.sh | bash
```

## 自定义

以下情况需要编辑 `~/.hammerspoon/SlashFix.lua`：

- 你用的终端不在默认列表中（如 WezTerm）
- 你用的 AI 工具关键词不在默认列表中（如 gemini）
- 想临时关闭功能（`enabled = false`）
- 想排查问题（`debug = true`，日志写入 `/tmp/slashfix.log`）

```lua
M.config = {
  aiTerminals = { ["iTerm2"] = true, ["Terminal"] = true, ["Warp"] = true, ["Alacritty"] = true, ["kitty"] = true, ["Hyper"] = true },
  aiKeywords  = { "claude", "aider", "copilot", "cursor", "cline", "codex", "codeflicker", "cf" },
  enabled     = true,
  debug       = false,
}
```

点击菜单栏 Hammerspoon 图标 → Reload Config。

## 工作原理

核心逻辑基于 Hammerspoon 的 `hs.eventtap` 监听键盘事件：非 keyCode 44 直接放行（99%+ 零开销），命中后检测 AI 终端 + 中文输入法，500ms 内连按两次输出顿号，单次替换为 `/`。

## FAQ

- **非 AI 终端受影响吗？** 不会
- **想输入顿号？** 连按两次 `、、`
- **我的 AI 终端为什么不生效？** 见[自定义](#自定义)，检查终端和关键词是否在默认列表中