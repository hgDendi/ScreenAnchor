# ScreenAnchor

macOS menu bar app for multi-screen window management. Automatically saves and restores window layouts when displays are connected/disconnected.

## Features

- **Layout Snapshots**: Remembers window positions for each screen configuration
- **App Rules**: Pin specific apps to specific screens (e.g., terminal always on left portrait display)
- **Auto-restore**: When screens change, automatically restores the last known layout for that configuration
- **Profile Overrides**: Different rules for 2-screen vs 3-screen setups
- **Hot-reload Config**: Edit the JSON config file and changes apply immediately
- **Launch at Login**: Optional auto-start on boot

## Requirements

- macOS 13+ (Ventura)
- Apple Silicon or Intel Mac
- Accessibility permission (prompted on first run)

## Install

### Build from source

```bash
git clone <repo-url> && cd ScreenAnchor

# Build + bundle + install to ~/Applications
make install

# Or just build and run
make bundle
open ScreenAnchor.app
```

### Manual

```bash
swift build -c release
bash Scripts/bundle.sh
cp -R ScreenAnchor.app ~/Applications/
```

## Configuration

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
      "profileOverrides": {
        "2-screen": "macbook"
      }
    }
  ],
  "profiles": {
    "3-screen": { "screenCount": 3 },
    "2-screen": { "screenCount": 2 }
  }
}
```

### Screen aliases

Map display names to short aliases. `nameContains` does a case-insensitive substring match against `NSScreen.localizedName`.

### Rules

- `app.bundleId`: The app's bundle identifier (find via `osascript -e 'id of app "AppName"'`)
- `targetScreen`: Which screen alias to move the app to
- `profileOverrides`: Override the target screen for specific screen-count profiles

### Finding bundle IDs

```bash
# By app name
osascript -e 'id of app "Google Chrome"'

# List all running apps
lsappinfo list | grep bundleID
```

## How it works

1. **Screen change detected** (via `CGDisplayReconfigurationCallback`)
2. Wait 500ms debounce (screens fire multiple events)
3. Save current window positions as a snapshot for the old screen profile
4. Apply app rules (move rule-matched apps to target screens)
5. Restore saved snapshot for the new screen profile (non-rule apps)
6. Save the new layout state

When an app launches, if it matches a rule, it's moved to the target screen after a short delay.

## Data storage

- Config: `~/.config/screenanchor/config.json`
- Snapshots: `~/.config/screenanchor/snapshots/`

## Troubleshooting

**"Accessibility Permission Required"**
Go to System Settings > Privacy & Security > Accessibility and enable ScreenAnchor.

**Windows not moving**
Ensure the app is properly signed. The `bundle.sh` script applies ad-hoc signing which is required for stable Accessibility permissions.

**Screen names don't match**
Check your screen names in the menu bar dropdown and update `nameContains` in config accordingly.

## License

MIT
