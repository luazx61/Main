# Lumen UI

A glass-style, blue-accent UI library for Roblox executors, built for mobile and desktop.

## Features
- Tabs with `rbxassetid` icons (tinted to the theme)
- Elements: Section, Folder, Label, Paragraph, Divider, InfoRow, Button, Toggle, Slider, Progress, Dropdown (search + multi-select), Input, Keybind, Image, Avatar
- Configs and per-game profiles with auto-load
- Notifications: 3 styles (Default, Compact, Banner), 5 positions, history
- Loading screen with your avatar
- Built-in config tab (configs, profiles, notifications, UI scale, accent color)
- Drag the window from any edge (top, bottom, left, right), the top bar or the status bar; optional position lock
- UI sounds (click, toggle, notification, error) with on/off and volume
- Minimize, saved position and scale, floating reopen button

## Install
```lua
local BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/lumen-ui/main/"
local Lumen = loadstring(game:HttpGet(BASE .. "Lumen.lua"))()
```
Replace `YOUR_USERNAME` with your GitHub name.

## Quick start
```lua
local Win = Lumen:CreateWindow({ Name = "Lumen", Subtitle = "v2.1" })
local Main = Win:CreateTab("Main", "home")
Main:CreateToggle({ Name = "Enabled", Flag = "enabled", Callback = print })
Main:CreateButton({ Name = "Notify", Callback = function()
	Lumen:Notify({ Title = "Hi", Content = "Works", Type = "Success" })
end })
Win:CreateConfigTab()
```
See [`examples/Example.lua`](examples/Example.lua) for every element.

## Icons
Tabs and the window logo accept an asset id (`123456`), an `rbxassetid://` string, or a registered name:
```lua
Lumen:SetIcons({ home = 1234567890, settings = 1234567891, player = 1234567892 })
Win:CreateTab("Home", "home")
```
Built-in names: `home settings player players combat visuals teleport misc config info`. Unset names show a letter instead. Edit [`icons/Icons.lua`](icons/Icons.lua) with your own ids. White or transparent PNGs tint best.

## Window options
| Option | Default | Notes |
|---|---|---|
| `Name`, `Subtitle`, `Icon` | | Title text and logo |
| `ToggleKey` | RightShift | Show/hide key |
| `Size` | 660x400 | `Vector2` size |
| `Scale` | 0.8 | Base scale |
| `Blur` | true | Background blur |
| `StatusBar` | true | FPS, ping, players |
| `Loading` / `LoadTime` | true / 1.8 | Loading screen |
| `AutoLoadProfile` | true | Load this game's auto profile |
| `NotifyPosition` / `NotifyStyle` | BottomRight / Default | |

## Sounds
```lua
Lumen:SetSounds({ click = 1234567890, notify = "rbxassetid://1234567891" })
CreateWindow({ Sounds = true, SoundVolume = 0.5 })
Win:PlaySound("click")
```
Defaults use Roblox built-in sound files. If one is silent on your executor, set your own ids. Sound on/off and volume are also in the config tab.

## Dragging
Hold and drag within about 14px of any window edge, or use the top bar and status bar. The middle stays free for scrolling. Turn on "Lock window position" in the config tab to stop accidental moves, or call `Win:SetLocked(true)`.

## Configs and profiles
Elements with a `Flag` are saved. Needs an executor with `writefile`/`readfile`.
```lua
Lumen:SaveConfig("name")      Lumen:LoadConfig("name")
Lumen:SaveProfile("name")     Lumen:LoadProfile("name")
Lumen:SetAutoLoad("name")     -- loads on start in this game
```

## Notes
Tested layout targets Delta on mobile. Web images in `CreateImage` need `getcustomasset`; asset ids always work.

## License
MIT
