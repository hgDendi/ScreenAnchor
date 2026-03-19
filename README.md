# ScreenAnchor

[English](#english) | [中文](#中文)

---

## English

macOS menu bar app for multi-screen window management. Automatically saves and restores window layouts when displays are connected/disconnected.

### Features

- **Layout Snapshots** — Remembers window positions for each screen configuration
- **App Rules** — Pin specific apps to specific screens (e.g., terminal always on left portrait display)
- **Auto-restore** — When screens change, automatically restores the last known layout
- **Profile Overrides** — Different rules for 2-screen vs 3-screen setups
- **Hot-reload Config** — Edit the JSON config file and changes apply immediately
- **Launch at Login** — Optional auto-start on boot

### Requirements

- macOS 13+ (Ventura)
- Apple Silicon or Intel Mac
- Accessibility permission (prompted on first run)

### Install

```bash
git clone https://github.com/hgDendi/ScreenAnchor.git && cd ScreenAnchor

# Build + bundle + install to ~/Applications
make install

# Or just build and run
make bundle
open ScreenAnchor.app
```

Manual build:

```bash
swift build -c release
bash Scripts/bundle.sh
cp -R ScreenAnchor.app ~/Applications/
```

### Configuration

Config file: `~/.config/screenanchor/config.json`

A default config is created on first run. Edit it to match your setup:

```json
{
  "version": 1,
  "debounceMs": 500,
  "screens": [
    { "alias": "dell-portrait", "nameContains": "U2723QE" },
    { "alias": "dell-main", "nameContains": "UP2720Q" },
    { "alias": "macbook", "nameContains": "Built-in" }
  ],
  "rules": [
    {
      "app": { "bundleId": "com.mitchellh.ghostty" },
      "targetScreen": "dell-portrait"
    },
    {
      "app": { "bundleId": "com.google.Chrome" },
      "targetScreen": "dell-main",
      "profileOverrides": { "2-screen": "macbook" }
    }
  ],
  "profiles": {
    "3-screen": { "screenCount": 3 },
    "2-screen": { "screenCount": 2 }
  }
}
```

#### Screen aliases

Map display names to short aliases. `nameContains` does a case-insensitive substring match against `NSScreen.localizedName`.

#### Rules

- `app.bundleId` — The app's bundle identifier
- `targetScreen` — Which screen alias to move the app to
- `profileOverrides` — Override the target for specific screen-count profiles

#### Finding bundle IDs

```bash
osascript -e 'id of app "Google Chrome"'
# or
lsappinfo list | grep bundleID
```

### How it works

1. **Screen change detected** via `CGDisplayReconfigurationCallback`
2. Wait 500ms debounce (macOS fires multiple events)
3. Save current window positions as a snapshot for the old screen profile
4. Apply app rules (move rule-matched apps to target screens)
5. Restore saved snapshot for the new screen profile (non-rule apps)
6. Save the new layout state

When an app launches, if it matches a rule, it's moved to the target screen after a short delay.

### Data storage

- Config: `~/.config/screenanchor/config.json`
- Snapshots: `~/.config/screenanchor/snapshots/`

### Troubleshooting

| Problem | Solution |
|---------|----------|
| Accessibility Permission Required | System Settings > Privacy & Security > Accessibility > enable ScreenAnchor |
| Windows not moving | Ensure the app is ad-hoc signed (`bundle.sh` does this automatically) |
| Screen names don't match | Check screen names in the menu bar dropdown, update `nameContains` in config |

---

## 中文

macOS 菜单栏应用，用于多屏窗口管理。自动保存和恢复显示器插拔时的窗口布局。

### 功能特性

- **布局快照** — 记忆每种屏幕组合下的窗口位置
- **应用规则** — 固定应用到指定屏幕（如终端始终在左侧竖屏）
- **自动恢复** — 屏幕变化时自动恢复上次已知的布局
- **多配置支持** — 二屏/三屏可设置不同规则
- **配置热更新** — 编辑 JSON 配置文件后立即生效
- **开机自启** — 可选的登录时自动启动

### 系统要求

- macOS 13+（Ventura）
- Apple Silicon 或 Intel Mac
- 辅助功能权限（首次运行时提示授权）

### 安装

```bash
git clone https://github.com/hgDendi/ScreenAnchor.git && cd ScreenAnchor

# 构建 + 打包 + 安装到 ~/Applications
make install

# 或者只构建运行
make bundle
open ScreenAnchor.app
```

手动构建：

```bash
swift build -c release
bash Scripts/bundle.sh
cp -R ScreenAnchor.app ~/Applications/
```

### 配置

配置文件路径：`~/.config/screenanchor/config.json`

首次运行会自动创建默认配置，根据你的屏幕环境修改即可：

```json
{
  "version": 1,
  "debounceMs": 500,
  "screens": [
    { "alias": "dell-portrait", "nameContains": "U2723QE" },
    { "alias": "dell-main", "nameContains": "UP2720Q" },
    { "alias": "macbook", "nameContains": "Built-in" }
  ],
  "rules": [
    {
      "app": { "bundleId": "com.mitchellh.ghostty" },
      "targetScreen": "dell-portrait"
    },
    {
      "app": { "bundleId": "com.google.Chrome" },
      "targetScreen": "dell-main",
      "profileOverrides": { "2-screen": "macbook" }
    }
  ],
  "profiles": {
    "3-screen": { "screenCount": 3 },
    "2-screen": { "screenCount": 2 }
  }
}
```

#### 屏幕别名

将显示器名称映射为短别名。`nameContains` 对 `NSScreen.localizedName` 做大小写不敏感的子串匹配。

#### 规则配置

- `app.bundleId` — 应用的 Bundle Identifier
- `targetScreen` — 目标屏幕别名
- `profileOverrides` — 针对不同屏幕数量覆盖目标屏幕

#### 查找 Bundle ID

```bash
osascript -e 'id of app "Google Chrome"'
# 或
lsappinfo list | grep bundleID
```

### 工作原理

1. 通过 `CGDisplayReconfigurationCallback` 检测屏幕变化
2. 500ms 防抖等待（macOS 会连续触发多次事件）
3. 保存当前窗口位置快照到旧屏幕配置
4. 执行应用规则（规则匹配的应用移到目标屏幕）
5. 恢复新屏幕配置的历史快照（非规则应用）
6. 保存新的布局状态

应用启动时，如果匹配规则，会在短暂延迟后自动移动到目标屏幕。

### 数据存储

- 配置：`~/.config/screenanchor/config.json`
- 快照：`~/.config/screenanchor/snapshots/`

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| 提示需要辅助功能权限 | 系统设置 > 隐私与安全性 > 辅助功能 > 启用 ScreenAnchor |
| 窗口没有移动 | 确保应用已签名（`bundle.sh` 会自动进行 ad-hoc 签名） |
| 屏幕名称不匹配 | 在菜单栏下拉菜单中查看屏幕名称，更新配置中的 `nameContains` |

## License

MIT
