-- Lumen UI example
local BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/lumen-ui/main/"
local Lumen = loadstring(game:HttpGet(BASE .. "Lumen.lua"))()
loadstring(game:HttpGet(BASE .. "icons/Icons.lua"))()(Lumen)

local Win = Lumen:CreateWindow({
	Name = "Lumen",
	Subtitle = "example",
	Icon = "home",              -- name from the icon registry, or an asset id
	ToggleKey = Enum.KeyCode.RightShift,
	NotifyPosition = "TopRight", -- BottomRight, BottomLeft, TopRight, TopLeft, TopCenter
	NotifyStyle = "Default",     -- Default, Compact, Banner
	LoadTime = 1.8,              -- loading screen length (Loading = false to skip)
})

-- Home
local Home = Win:CreateTab("Home", "home")
Home:CreateSection("You")
Home:CreateAvatar({})
Home:CreateInfoRow("#", "Place ID", tostring(game.PlaceId))
Home:CreateImage({ Image = 0, Height = 100, Caption = "Preview" }) -- put an asset id here

-- Player
local Player = Win:CreateTab("Player", "player")
Player:CreateSection("Movement")
Player:CreateSlider({
	Name = "WalkSpeed",
	Range = { 16, 100 },
	Increment = 1,
	CurrentValue = 16,
	Flag = "walkspeed",
	Callback = function(v)
		local h = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if h then h.WalkSpeed = v end
	end,
})
Player:CreateToggle({
	Name = "Show notifications",
	CurrentValue = true,
	Flag = "notify_on",
	Callback = function(v)
		print("notifications:", v)
	end,
})
Player:CreateDropdown({
	Name = "Mode",
	Options = { "Legit", "Rage", "Custom" },
	CurrentOption = "Legit",
	Flag = "mode",
	Callback = function(v) print("mode:", v) end,
})
Player:CreateInput({
	Name = "Target",
	PlaceholderText = "Username",
	Flag = "target",
	Callback = function(v) print("target:", v) end,
})
Player:CreateKeybind({
	Name = "Action key",
	CurrentKeybind = Enum.KeyCode.E,
	Flag = "action_key",
	Callback = function() Lumen:Notify({ Title = "Keybind", Content = "Pressed!" }) end,
})
Player:CreateButton({
	Name = "Test notification",
	Description = "Shows a success notification",
	Callback = function()
		Lumen:Notify({ Title = "Hello", Content = "Lumen works.", Type = "Success" })
	end,
})

-- Settings (configs, profiles, notification style, UI scale, accent)
Win:CreateConfigTab("Settings", "settings")
