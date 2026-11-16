-- Lumen v2.1 | Glass + Blue Only | Cleaned
-- Layout:
--   1. Services & constants
--   2. Helpers
--   3. Config (save/load)
--   4. Lumen:CreateWindow
--        window shell, notifications, element factory, tabs,
--        window methods, dialogs, palette, key gate

----------------------------------------------------------------------
-- 1. Services & constants
----------------------------------------------------------------------
local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local UIS                 = game:GetService("UserInputService")
local HttpService         = game:GetService("HttpService")
local RunService          = game:GetService("RunService")
local TextService         = game:GetService("TextService")
local MarketplaceService  = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService")

local Lumen = {
	Version   = "2.1.0",
	Flags     = {},
	Options   = {},
	Windows   = {},
	Listening = false,
}

local rgb  = Color3.fromRGB
local BLUE = rgb(76, 130, 230)

local C = {
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	Green = rgb(72, 182, 128),
	Gold  = rgb(214, 174, 72),
	Red   = rgb(204, 78, 86),
}

local T = {
	Window1 = rgb(96, 116, 166),
	Window2 = rgb(30, 38, 68),
	WinT    = 0.4,
	Panel   = rgb(16, 22, 44),
	PanT    = 0.5,
	Card    = rgb(12, 18, 38),
	CardT   = 0.32,
	Text    = rgb(252, 253, 255),
	Sub     = rgb(200, 208, 228),
	Off     = rgb(84, 98, 140),
	Line    = C.White,
	LineT   = 0.8,
	Accent  = BLUE,
}

----------------------------------------------------------------------
-- 2. Helpers
----------------------------------------------------------------------
local function New(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Tween(inst, props, time, style, dir)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function Corner(radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function Pad(l, t, r, b)
	return New("UIPadding", {
		PaddingLeft   = UDim.new(0, l),
		PaddingTop    = UDim.new(0, t),
		PaddingRight  = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
	})
end

local function List(pad, horizontal)
	return New("UIListLayout", {
		Padding       = UDim.new(0, pad or 6),
		SortOrder     = Enum.SortOrder.LayoutOrder,
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
	})
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function round(n, inc)
	inc = inc or 1
	local r = math.floor(n / inc + 0.5) * inc
	return tonumber(string.format("%.10g", r))
end

local function safe(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Lumen] " .. tostring(err))
	end
end

local function guiParent()
	local ok, ui = pcall(function()
		return gethui and gethui()
	end)
	if ok and ui then
		return ui
	end

	local ok2, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and core and pcall(function()
		local f = Instance.new("Folder")
		f.Parent = core
		f:Destroy()
	end) then
		return core
	end

	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function fmtDuration(s)
	s = math.floor(s)
	local h, m, sec = math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60
	if h > 0 then
		return string.format("%dh %dm %ds", h, m, sec)
	end
	return string.format("%dm %ds", m, sec)
end

-- File system helpers
local function fsOK()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
end

local function ensureFolder()
	pcall(function()
		if makefolder and not isfolder("Lumen") then
			makefolder("Lumen")
		end
	end)
end

local function hashKey(s)
	local h = 2166136261
	for i = 1, #s do
		h = (h * 16777619) % 4294967296
		h = bit32.bxor(h, string.byte(s, i))
	end
	return string.format("%08x", h)
end

-- Config (de)serialisation: Color3 values need wrapping for JSON
local function enc(v)
	if typeof(v) == "Color3" then
		return { __c3 = { v.R, v.G, v.B } }
	end
	return v
end

local function dec(v)
	if type(v) == "table" and v.__c3 then
		return Color3.new(v.__c3[1], v.__c3[2], v.__c3[3])
	end
	return v
end

----------------------------------------------------------------------
-- 3. Config API
----------------------------------------------------------------------
local function cfgPath(name)
	return "Lumen/" .. (tostring(name):gsub("[^%w_%- ]", "_")) .. ".json"
end

function Lumen:SaveConfig(name)
	if not fsOK() then
		return false
	end
	local data = {}
	for k, v in pairs(Lumen.Flags) do
		data[k] = enc(v)
	end
	ensureFolder()
	return (pcall(writefile, cfgPath(name), HttpService:JSONEncode(data)))
end

function Lumen:LoadConfig(name)
	if not fsOK() then
		return false
	end
	local path = cfgPath(name)
	if not isfile(path) then
		return false
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok then
		return false
	end

	for k, v in pairs(data) do
		local option = Lumen.Options[k]
		if option and option.Set then
			pcall(option.Set, option, dec(v))
		end
	end
	return true
end

function Lumen:DeleteConfig(name)
	if type(delfile) ~= "function" then
		return false
	end
	return (pcall(delfile, cfgPath(name)))
end

function Lumen:ListConfigs()
	local out = {}
	if type(listfiles) ~= "function" then
		return out
	end

	local ok, files = pcall(listfiles, "Lumen")
	if ok and type(files) == "table" then
		for _, path in ipairs(files) do
			local n = path:match("([^/\\]+)%.json$")
			if n then
				out[#out + 1] = n
			end
		end
	end
	table.sort(out)
	return out
end

function Lumen:Notify(n)
	local w = Lumen.Windows[#Lumen.Windows]
	if w then
		w:Notify(n)
	end
end

----------------------------------------------------------------------
-- 4. Window
----------------------------------------------------------------------
function Lumen:CreateWindow(cfg)
	cfg = cfg or {}

	local W = { Tabs = {} }
	local lp = Players.LocalPlayer

	------------------------------------------------------------------
	-- Window-local helpers & state
	------------------------------------------------------------------
	local function L(fmt, ...)
		if select("#", ...) > 0 then
			local ok, r = pcall(string.format, fmt, ...)
			return ok and r or fmt
		end
		return fmt
	end

	local function fmtDate(t)
		return os.date("%A, %d %B %Y", t)
	end

	local function dayName(t)
		return os.date("%A", t)
	end

	local conns, binds, themeFns, ticks = {}, {}, {}, {}
	local paletteItems = {}
	local Gui

	local function conn(c)
		conns[#conns + 1] = c
		return c
	end

	-- Bind an instance property to a theme key so refresh() can re-tween it
	local function bind(inst, prop, key)
		inst[prop] = T[key]
		binds[#binds + 1] = { inst, prop, key }
		return inst
	end

	local function onTheme(fn)
		themeFns[#themeFns + 1] = fn
	end

	local function refresh()
		for i = #binds, 1, -1 do
			local b = binds[i]
			if b[1]:IsDescendantOf(Gui) then
				Tween(b[1], { [b[2]] = T[b[3]] }, 0.3)
			else
				table.remove(binds, i)
			end
		end
		for _, fn in ipairs(themeFns) do
			pcall(fn)
		end
	end

	local function regPalette(name, fn, kind)
		if name and fn then
			paletteItems[#paletteItems + 1] = {
				Name = tostring(name),
				Fn   = fn,
				Kind = kind or "Action",
			}
		end
	end

	local function onTick(fn)
		ticks[#ticks + 1] = fn
		pcall(fn)
	end

	------------------------------------------------------------------
	-- Saved window state
	------------------------------------------------------------------
	local winFile = "Lumen/window_" .. ((cfg.Name or "ui"):gsub("[^%w_]", "_")) .. ".json"
	local winState = nil

	if fsOK() then
		local ok, raw = pcall(function()
			if isfile(winFile) then
				return readfile(winFile)
			end
		end)
		if ok and raw then
			local ok2, d = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			if ok2 and type(d) == "table" then
				winState = d
			end
		end
	end

	------------------------------------------------------------------
	-- ScreenGui (replaces any previous instance with the same name)
	------------------------------------------------------------------
	local parent = guiParent()

	if cfg.Name then
		for _, g in ipairs(parent:GetChildren()) do
			if g:GetAttribute("LumenId") == cfg.Name then
				g:Destroy()
			end
		end
		pcall(function()
			for _, b in ipairs(game:GetService("Lighting"):GetChildren()) do
				if b.Name == "LumenBlur" then
					b:Destroy()
				end
			end
		end)
	end

	Gui = New("ScreenGui", {
		Name           = "Lumen_" .. HttpService:GenerateGUID(false):sub(1, 6) .. tostring(math.random(1000, 9999)),
		ResetOnSpawn   = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder   = 999,
		IgnoreGuiInset = true,
		Parent         = parent,
	})
	Gui:SetAttribute("LumenId", cfg.Name or "Lumen")
	W.Gui = Gui

	------------------------------------------------------------------
	-- Text / icon / avatar helpers (need Gui + bind)
	------------------------------------------------------------------
	local function text(par, str, size, font, color, pos, sz, align)
		local label = New("TextLabel", {
			BackgroundTransparency = 1,
			Position       = pos or UDim2.fromOffset(12, 0),
			Size           = sz or UDim2.new(1, -24, 1, 0),
			Font           = font or Enum.Font.GothamMedium,
			TextSize       = math.max((size or 13) - 1, 9),
			TextXAlignment = align or Enum.TextXAlignment.Left,
			Text           = str,
			Parent         = par,
		})
		if typeof(color) == "Color3" then
			label.TextColor3 = color
		else
			bind(label, "TextColor3", color or "Text")
		end
		return label
	end

	local function hit(par, height)
		return New("TextButton", {
			BackgroundTransparency = 1,
			Text            = "",
			AutoButtonColor = false,
			Size            = height and UDim2.new(1, 0, 0, height) or UDim2.fromScale(1, 1),
			Parent          = par,
		})
	end

	local function makeIcon(par, icon, w, h, pos)
		local isImage = type(icon) == "number"
			or (type(icon) == "string" and (icon:find("^rbxasset") ~= nil or icon:find("^rbxthumb") ~= nil))

		if isImage then
			return New("ImageLabel", {
				BackgroundTransparency = 1,
				Size     = UDim2.fromOffset(18, 18),
				Position = UDim2.new(
					pos.X.Scale, pos.X.Offset + (w - 18) / 2,
					pos.Y.Scale, pos.Y.Offset + (h - 18) / 2
				),
				Image  = type(icon) == "number" and ("rbxassetid://" .. icon) or icon,
				Parent = par,
			})
		end

		return New("TextLabel", {
			BackgroundTransparency = 1,
			Position = pos,
			Size     = UDim2.fromOffset(w, h),
			Font     = Enum.Font.GothamMedium,
			TextSize = 14,
			Text     = tostring(icon or "-"),
			Parent   = par,
		})
	end

	local function loadAvatar(img)
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(
					lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150
				)
			end)
			if ok then
				img.Image = url
			end
		end)
	end

	------------------------------------------------------------------
	-- Live stats (FPS / ping) + tick loop
	------------------------------------------------------------------
	local Live = { FPS = 0, Ping = 0 }

	do
		local frames, last = 0, os.clock()

		conn(RunService.Heartbeat:Connect(function()
			frames += 1
		end))

		task.spawn(function()
			while Gui.Parent do
				task.wait(1)

				local now = os.clock()
				Live.FPS = math.floor(frames / math.max(now - last, 0.001) + 0.5)
				frames, last = 0, now

				local ok, ping = pcall(function()
					return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				if ok then
					Live.Ping = math.floor(ping + 0.5)
				end

				for _, fn in ipairs(ticks) do
					pcall(fn)
				end
			end
		end)
	end

	------------------------------------------------------------------
	-- Window sizing / state
	------------------------------------------------------------------
	local WIDTH  = cfg.Size and cfg.Size.X or 660
	local HEIGHT = cfg.Size and cfg.Size.Y or 400
	local TOP    = 58

	local hidden, minimized, userScale = true, false, 1
	if winState and winState.scale then
		userScale = math.clamp(winState.scale, 0.5, 1.5)
	end

	local locked = false
	local blur
	if cfg.Blur ~= false then
		pcall(function()
			blur = Instance.new("BlurEffect")
			blur.Name = "LumenBlur"
			blur.Size = 0
			blur.Parent = game:GetService("Lighting")
		end)
	end

	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift

	local startPos = UDim2.new(0.5, 0, 0.5, 14)
	if winState and winState.px then
		startPos = UDim2.new(winState.px or 0.5, winState.po or 0, winState.py or 0.5, winState.yo or 14)
	end

	------------------------------------------------------------------
	-- Main frame
	------------------------------------------------------------------
	local Main = New("Frame", {
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = startPos,
		Size             = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundColor3 = C.White,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		Visible          = false,
		Active           = true,
		Parent           = Gui,
	}, { Corner(24) })
	bind(Main, "BackgroundTransparency", "WinT")

	New("UIGradient", {
		Rotation = 135,
		Color    = ColorSequence.new(T.Window1, T.Window2),
		Parent   = Main,
	})

	local mainStroke = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness       = 1.5,
		Parent          = Main,
	})
	bind(mainStroke, "Color", "Line")
	mainStroke.Transparency = 0.7

	local Scale = New("UIScale", { Parent = Main })

	local function fit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local touch = UIS.TouchEnabled
		local marginX, marginY = touch and 120 or 60, touch and 100 or 70
		return math.min(
			userScale * (cfg.Scale or 0.8),
			(vp.X - marginX) / WIDTH,
			(vp.Y - marginY) / HEIGHT
		)
	end

	Scale.Scale = fit() * 0.9

	if workspace.CurrentCamera then
		conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if not hidden then
				Scale.Scale = fit()
			end
		end))
	end

	local function saveWin()
		if not fsOK() then
			return
		end
		ensureFolder()
		local data = {
			px    = Main.Position.X.Scale,
			po    = Main.Position.X.Offset,
			py    = Main.Position.Y.Scale,
			yo    = Main.Position.Y.Offset,
			scale = userScale,
			tab   = W.ActiveTab and W.ActiveTab.Name or nil,
		}
		pcall(writefile, winFile, HttpService:JSONEncode(data))
	end

	------------------------------------------------------------------
	-- Top bar
	------------------------------------------------------------------
	local Topbar = New("Frame", {
		Size = UDim2.new(1, 0, 0, TOP),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local titleX = 20
	if cfg.Icon then
		local ti = makeIcon(Topbar, cfg.Icon, 28, 28, UDim2.fromOffset(16, 14))
		if ti:IsA("TextLabel") then
			bind(ti, "TextColor3", "Text")
		end
		titleX = 52
	end

	text(Topbar, cfg.Name or "Lumen", 20, Enum.Font.GothamBold, "Text",
		UDim2.fromOffset(titleX, cfg.Subtitle and 10 or 17), UDim2.new(0.6, 0, 0, 24))
	text(Topbar, string.upper(cfg.Subtitle or ""), 10, Enum.Font.GothamMedium, "Sub",
		UDim2.fromOffset(titleX, 33), UDim2.new(0.6, 0, 0, 14))

	local topLine = New("Frame", {
		Position = UDim2.new(0, 16, 1, -1),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Parent = Topbar,
	})
	bind(topLine, "BackgroundColor3", "Line")

	local function circleBtn(label, xOffset)
		local b = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			AutoButtonColor = false,
			BackgroundTransparency = 0.88,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			Text = label,
			Parent = Topbar,
		}, { Corner(15) })
		bind(b, "BackgroundColor3", "Line")
		bind(b, "TextColor3", "Text")
		b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.7 }, 0.15) end)
		b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 0.88 }, 0.15) end)
		return b
	end

	local HideBtn = circleBtn("▢", -14)
	local MinBtn  = circleBtn("–", -50)

	-- Dragging by the top bar
	do
		local dragging, startMouse, startWinPos = false, nil, nil

		conn(Topbar.InputBegan:Connect(function(i)
			if isPress(i) and i.Position.X < MinBtn.AbsolutePosition.X - 4 then
				dragging, startMouse, startWinPos = true, i.Position, Main.Position
			end
		end))

		conn(UIS.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = i.Position - startMouse
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				Main.Position = UDim2.new(
					startWinPos.X.Scale,
					math.clamp(startWinPos.X.Offset + d.X, -vp.X * startWinPos.X.Scale + 60, vp.X * (1 - startWinPos.X.Scale) - 60),
					startWinPos.Y.Scale,
					math.clamp(startWinPos.Y.Offset + d.Y, -vp.Y * startWinPos.Y.Scale + 40, vp.Y * (1 - startWinPos.Y.Scale) - 40)
				)
			end
		end))

		conn(UIS.InputEnded:Connect(function(i)
			if isPress(i) and dragging then
				dragging = false
				saveWin()
			end
		end))
	end

	------------------------------------------------------------------
	-- Body: sidebar, pages, status bar
	------------------------------------------------------------------
	local FOOT = cfg.StatusBar == false and 0 or 32

	local Body = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TOP + 8),
		Size = UDim2.new(1, 0, 1, -(TOP + 8)),
		Parent = Main,
	})

	local SideWrap = New("Frame", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0, 150, 1, -14 - FOOT),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = Body,
	}, { Corner(18) })
	bind(SideWrap, "BackgroundColor3", "Card")
	bind(SideWrap, "BackgroundTransparency", "PanT")

	local sideStroke = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1.2,
		Parent = SideWrap,
	})
	bind(sideStroke, "Color", "Line")
	bind(sideStroke, "Transparency", "LineT")

	local showChip = cfg.SidebarProfile ~= false

	local Sidebar = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, showChip and -52 or 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = SideWrap,
	}, { Pad(8, 8, 8, 8), List(6) })

	-- Profile chip at the bottom of the sidebar
	if showChip then
		local chip = New("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundTransparency = 1,
			Parent = SideWrap,
		})

		local chipLine = New("Frame", {
			Size = UDim2.new(1, -16, 0, 1),
			Position = UDim2.fromOffset(8, 0),
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			Parent = chip,
		})
		bind(chipLine, "BackgroundColor3", "Line")

		local avatar = New("ImageLabel", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(32, 32),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = chip,
		}, { Corner(16) })
		bind(avatar, "BackgroundColor3", "Panel")
		loadAvatar(avatar)

		local nameLabel = text(chip, lp.DisplayName, 12, Enum.Font.GothamMedium, "Text",
			UDim2.fromOffset(50, 9), UDim2.new(1, -56, 0, 16))
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

		text(chip, "v" .. Lumen.Version, 10, Enum.Font.GothamMedium, "Sub",
			UDim2.fromOffset(50, 26), UDim2.new(1, -56, 0, 14))
	end

	local Pages = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(172, 0),
		Size = UDim2.new(1, -186, 1, -14 - FOOT),
		Parent = Body,
	})

	-- Status bar
	local gameName = game.Name
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if ok and info and info.Name then
			gameName = info.Name
		end
	end)

	if FOOT > 0 then
		local bar = New("Frame", {
			Position = UDim2.new(0, 14, 1, -38),
			Size = UDim2.new(1, -28, 0, 26),
			BorderSizePixel = 0,
			Parent = Body,
		}, { Corner(13) })
		bind(bar, "BackgroundColor3", "Card")
		bind(bar, "BackgroundTransparency", "PanT")

		local barStroke = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.2,
			Parent = bar,
		})
		bind(barStroke, "Color", "Line")
		bind(barStroke, "Transparency", "LineT")

		local label = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -28, 1, 0),
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			RichText = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "",
			Parent = bar,
		})
		bind(label, "TextColor3", "Sub")

		local function tint(good, ok)
			return "#" .. (good and C.Green or (ok and C.Gold or C.Red)):ToHex()
		end

		local function ageText()
			local d = lp.AccountAge
			if d >= 365 then
				return string.format("%dy %dm", math.floor(d / 365), math.floor((d % 365) / 30))
			end
			return d .. "d"
		end

		onTick(function()
			local fps, ping = Live.FPS, Live.Ping
			label.Text = table.concat({
				string.format('<font color="%s">%d</font> FPS', tint(fps >= 50, fps >= 30), fps),
				ping > 0
					and string.format('<font color="%s">%d</font> ms', tint(ping < 100, ping < 200), ping)
					or "- ms",
				string.format("%d/%d players", #Players:GetPlayers(), Players.MaxPlayers),
				"Account age " .. ageText(),
				gameName,
			}, "  |  ")
		end)
	end

	------------------------------------------------------------------
	-- Notifications
	------------------------------------------------------------------
	local NotifHolder = New("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(290, 500),
		BackgroundTransparency = 1,
		Parent = Gui,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local TYPE_COLORS = { Success = C.Green, Warning = C.Gold, Error = C.Red }

	function W:Notify(n)
		if type(n) ~= "table" then
			n = { Content = tostring(n) }
		end
		local content = n.Content or ""

		-- Keep at most 5 notifications on screen
		local live = {}
		for _, child in ipairs(NotifHolder:GetChildren()) do
			if child:IsA("Frame") then
				live[#live + 1] = child
			end
		end
		if #live >= 5 then
			live[1]:Destroy()
		end

		local bodyH = 0
		if content ~= "" then
			local ok, size = pcall(function()
				return TextService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(256, 1000))
			end)
			bodyH = ok and size.Y or 15 * math.ceil(#content / 38)
		end

		local wrap = New("Frame", {
			Size = UDim2.new(1, 0, 0, 30 + bodyH + 14),
			BackgroundTransparency = 1,
			Parent = NotifHolder,
		})

		local card = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Position = UDim2.new(1, 320, 0, 0),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = wrap,
		}, { Corner(12) })
		bind(card, "BackgroundColor3", "Panel")

		local stroke = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.2,
			Parent = card,
		})
		bind(stroke, "Color", "Line")
		bind(stroke, "Transparency", "LineT")

		local typeColor = TYPE_COLORS[n.Type]

		local accentBar = New("Frame", {
			Position = UDim2.fromOffset(8, 10),
			Size = UDim2.new(0, 3, 1, -20),
			BorderSizePixel = 0,
			Parent = card,
		}, { Corner(2) })

		local timer = New("Frame", {
			Position = UDim2.new(0, 0, 1, -2),
			Size = UDim2.new(1, 0, 0, 2),
			BorderSizePixel = 0,
			BackgroundTransparency = 0.3,
			Parent = card,
		})

		if typeColor then
			accentBar.BackgroundColor3 = typeColor
			timer.BackgroundColor3 = typeColor
		else
			bind(accentBar, "BackgroundColor3", "Accent")
			bind(timer, "BackgroundColor3", "Accent")
		end

		text(card, n.Title or "Notice", 14, Enum.Font.GothamMedium, "Text",
			UDim2.fromOffset(20, 8), UDim2.new(1, -30, 0, 18))

		if content ~= "" then
			local body = text(card, content, 12, Enum.Font.Gotham, "Sub",
				UDim2.fromOffset(20, 28), UDim2.new(1, -34, 0, bodyH))
			body.TextWrapped = true
			body.TextYAlignment = Enum.TextYAlignment.Top
		end

		local gone = false
		local function dismiss()
			if gone or not card.Parent then
				return
			end
			gone = true
			Tween(card, { Position = UDim2.new(1, 320, 0, 0) }, 0.3)
			task.delay(0.3, function()
				wrap:Destroy()
			end)
		end

		card.MouseButton1Click:Connect(dismiss)

		local duration = n.Duration or 4
		Tween(card, { Position = UDim2.new() }, 0.4, Enum.EasingStyle.Back)
		Tween(timer, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
		task.delay(duration, dismiss)
	end

	------------------------------------------------------------------
	-- Element factory
	-- attachElements(host, container) adds Create* methods to `host`
	-- that build their elements inside `container`.
	------------------------------------------------------------------
	local function attachElements(host, container)

		---------------- shared building blocks ----------------
		local function card(height, neon)
			local f = New("Frame", {
				Size = UDim2.new(1, 0, 0, height),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = container,
			}, { Corner(10) })
			bind(f, "BackgroundColor3", "Card")
			bind(f, "BackgroundTransparency", "CardT")

			local stroke = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1.5,
				Parent = f,
			})

			if neon == "accent" then
				bind(stroke, "Color", "Accent")
				stroke.Transparency = 0.4
			elseif typeof(neon) == "Color3" then
				stroke.Color = neon
				stroke.Transparency = 0.35
			else
				bind(stroke, "Color", "Line")
				bind(stroke, "Transparency", "LineT")
			end

			return f, stroke
		end

		local function hover(frame, button)
			button.MouseEnter:Connect(function()
				Tween(frame, { BackgroundTransparency = math.max(T.CardT - 0.18, 0) }, 0.15)
			end)
			button.MouseLeave:Connect(function()
				Tween(frame, { BackgroundTransparency = T.CardT }, 0.15)
			end)
		end

		-- Name (and optional description) on the left of a card
		local function named(f, name, desc, rightPad)
			rightPad = rightPad or 24
			if desc then
				text(f, name, 13, Enum.Font.GothamMedium, "Text",
					UDim2.fromOffset(12, 8), UDim2.new(1, -rightPad - 12, 0, 18))
				local d = text(f, desc, 11, Enum.Font.Gotham, "Sub",
					UDim2.fromOffset(12, 28), UDim2.new(1, -rightPad - 12, 0, 16))
				d.TextTruncate = Enum.TextTruncate.AtEnd
				return
			end
			text(f, name, 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 0), UDim2.new(1, -rightPad - 12, 1, 0))
		end

		-- Attach Frame / Destroy / SetVisible to an element object
		local function base(f, obj)
			obj.Frame = f
			function obj:Destroy() f:Destroy() end
			function obj:SetVisible(v) f.Visible = v end
			return obj
		end

		-- Register an element in the flag/option tables
		local function reg(flag, obj, value)
			if flag then
				Lumen.Flags[flag] = value
				Lumen.Options[flag] = obj
			end
		end

		-- Generic drag helper: onMove receives normalized (x, y) in [0, 1]
		local function drag(inputFrame, ref, onMove)
			local active = false

			local function update(input)
				local p, s = ref.AbsolutePosition, ref.AbsoluteSize
				onMove(
					math.clamp((input.Position.X - p.X) / math.max(s.X, 1), 0, 1),
					math.clamp((input.Position.Y - p.Y) / math.max(s.Y, 1), 0, 1)
				)
			end

			local function lockScroll(enabled)
				local sc = container:IsA("ScrollingFrame") and container
					or container:FindFirstAncestorOfClass("ScrollingFrame")
				if sc then
					sc.ScrollingEnabled = enabled
				end
			end

			conn(inputFrame.InputBegan:Connect(function(i)
				if isPress(i) then
					active = true
					lockScroll(false)
					update(i)
				end
			end))
			conn(UIS.InputChanged:Connect(function(i)
				if active and isMove(i) then
					update(i)
				end
			end))
			conn(UIS.InputEnded:Connect(function(i)
				if active and isPress(i) then
					active = false
					lockScroll(true)
				end
			end))
		end

		---------------- layout elements ----------------
		function host:CreateSection(title, neon)
			local f = card(30, neon or "accent")

			local bar = New("Frame", {
				Position = UDim2.fromOffset(10, 7),
				Size = UDim2.fromOffset(3, 16),
				BackgroundColor3 = typeof(neon) == "Color3" and neon or T.Accent,
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(2) })
			if typeof(neon) ~= "Color3" then
				bind(bar, "BackgroundColor3", "Accent")
			end

			text(f, string.upper(title or "Section"), 11, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(22, 0), UDim2.new(1, -30, 1, 0))
			return base(f, {})
		end

		function host:CreateFolder(name, startOpen)
			local f = card(36)
			local open = startOpen == true

			text(f, tostring(name), 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 0), UDim2.new(1, -44, 0, 36))
			local arrow = text(f, "▾", 14, Enum.Font.GothamMedium, "Sub",
				UDim2.new(1, -26, 0, 0), UDim2.fromOffset(16, 36), Enum.TextXAlignment.Center)

			local inner = New("Frame", {
				Position = UDim2.fromOffset(0, 40),
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				Parent = f,
			})
			local layout = List(8)
			layout.Parent = inner
			Pad(8, 0, 8, 0).Parent = inner

			local head = hit(f, 36)
			hover(f, head)

			local function apply(animate)
				local h = open and (40 + layout.AbsoluteContentSize.Y + 10) or 36
				if animate then
					Tween(f, { Size = UDim2.new(1, 0, 0, h) }, 0.25)
				else
					f.Size = UDim2.new(1, 0, 0, h)
				end
				Tween(arrow, { Rotation = open and 180 or 0 }, animate and 0.25 or 0)
			end

			layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				if open then
					apply(false)
				end
			end)
			head.MouseButton1Click:Connect(function()
				open = not open
				apply(true)
			end)

			local folder = { Frame = f }
			attachElements(folder, inner)

			function folder:Open()    open = true;      apply(true) end
			function folder:Close()   open = false;     apply(true) end
			function folder:Toggle()  open = not open;  apply(true) end
			function folder:Destroy() f:Destroy() end

			apply(false)
			return folder
		end

		function host:CreateLabel(str)
			local f = card(32)
			local label = text(f, tostring(str), 12, Enum.Font.Gotham, "Sub")
			return base(f, { Set = function(_, v) label.Text = v end })
		end

		function host:CreateParagraph(c)
			local f = card(0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.Size = UDim2.new(1, 0, 0, 0)
			Pad(12, 10, 12, 10).Parent = f
			List(4).Parent = f

			local title = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = c.Title or "",
				Parent = f,
			})
			bind(title, "TextColor3", "Text")

			local body = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Text = c.Content or "",
				Parent = f,
			})
			bind(body, "TextColor3", "Sub")

			return base(f, {
				Set = function(_, n)
					title.Text = n.Title or title.Text
					body.Text = n.Content or body.Text
				end,
			})
		end

		function host:CreateDivider()
			local d = New("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				Parent = container,
			})
			bind(d, "BackgroundColor3", "Line")
			d.BackgroundTransparency = 0.8
			return base(d, {})
		end

		function host:CreateInfoRow(icon, key, value, neon)
			local f = card(40, neon or "accent")
			local keyX = 12

			if icon then
				text(f, icon, 15, Enum.Font.GothamMedium, "Text",
					UDim2.fromOffset(10, 0), UDim2.fromOffset(24, 40), Enum.TextXAlignment.Center)
				keyX = 40
			end

			local keyLabel = text(f, key, 11, Enum.Font.GothamMedium, "Sub",
				UDim2.fromOffset(keyX, 0), UDim2.fromOffset(86, 40))
			keyLabel.TextTruncate = Enum.TextTruncate.AtEnd

			local valueLabel = text(f, tostring(value), 12, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(keyX + 92, 0), UDim2.new(1, -(keyX + 102), 1, 0))
			valueLabel.TextTruncate = Enum.TextTruncate.AtEnd

			return base(f, { Set = function(_, v) valueLabel.Text = tostring(v) end })
		end

		---------------- interactive elements ----------------
		function host:CreateButton(c)
			local f = card(c.Description and 54 or 40, c.Neon)
			named(f, c.Name or "Button", c.Description, 36)

			local chevron = text(f, "›", 20, Enum.Font.GothamMedium, "Sub",
				UDim2.new(1, -28, 0, 0), UDim2.new(0, 16, 1, 0), Enum.TextXAlignment.Center)

			local ring = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(),
				BackgroundTransparency = 1,
				Parent = f,
			}, { Corner(100) })

			local btn = hit(f)
			hover(f, btn)

			local function fire()
				if c.Confirm then
					local ok = W:Confirm({ Title = c.Name or "Confirm", Content = "Are you sure?" })
					if not ok then
						return
					end
				end

				-- Ripple originates at the cursor (or centre on touch)
				local rel = 0.5
				if UIS:GetLastInputType() ~= Enum.UserInputType.Touch then
					rel = math.clamp((UIS:GetMouseLocation().X - f.AbsolutePosition.X) / math.max(f.AbsoluteSize.X, 1), 0, 1)
				end
				ring.Position = UDim2.new(rel, 0, 0.5, 0)
				ring.BackgroundColor3 = T.Accent
				ring.BackgroundTransparency = 0.6
				ring.Size = UDim2.new()
				Tween(ring, { Size = UDim2.fromOffset(600, 600), BackgroundTransparency = 1 }, 0.5)

				Tween(chevron, { Position = UDim2.new(1, -22, 0, 0) }, 0.1).Completed:Connect(function()
					Tween(chevron, { Position = UDim2.new(1, -28, 0, 0) }, 0.15)
				end)

				safe(c.Callback)
			end

			btn.MouseButton1Click:Connect(fire)
			regPalette(c.Name, fire, "Button")
			return base(f, { Fire = fire })
		end

		function host:CreateToggle(c)
			local f = card(c.Description and 54 or 40, c.Neon)
			named(f, c.Name or "Toggle", c.Description, 60)

			local track = New("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(42, 22),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(11) })

			local knob = New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = C.White,
				BorderSizePixel = 0,
				Parent = track,
			}, { Corner(8) })

			local button = hit(f)
			hover(f, button)

			local o = { CurrentValue = c.CurrentValue == true }

			local function render(instant)
				local d = instant and 0 or 0.2
				Tween(track, { BackgroundColor3 = o.CurrentValue and T.Accent or T.Off }, d)
				Tween(knob, {
					Position = o.CurrentValue and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				}, d, Enum.EasingStyle.Back)
			end
			onTheme(function() render(true) end)

			function o:Set(v, silent)
				o.CurrentValue = v and true or false
				if c.Flag then
					Lumen.Flags[c.Flag] = o.CurrentValue
				end
				render()
				if not silent then
					safe(c.Callback, o.CurrentValue)
				end
			end
			function o:Get() return o.CurrentValue end

			button.MouseButton1Click:Connect(function()
				o:Set(not o.CurrentValue)
			end)

			reg(c.Flag, o, o.CurrentValue)
			regPalette(c.Name, function() o:Set(not o.CurrentValue) end, "Toggle")

			render(true)
			if o.CurrentValue then
				safe(c.Callback, true)
			end
			return base(f, o)
		end

		function host:CreateSlider(c)
			local min = c.Range and c.Range[1] or 0
			local max = c.Range and c.Range[2] or 100
			local inc = c.Increment or 1

			local f = card(56, c.Neon)
			text(f, c.Name or "Slider", 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 6), UDim2.new(0.6, 0, 0, 20))

			local valueBox = New("TextBox", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.4, -12, 0, 6),
				Size = UDim2.new(0.6, 0, 0, 20),
				Font = Enum.Font.GothamMedium,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
				ClearTextOnFocus = true,
				Text = "",
				Parent = f,
			})
			bind(valueBox, "TextColor3", "Sub")

			local track = New("Frame", {
				Position = UDim2.new(0, 12, 1, -20),
				Size = UDim2.new(1, -24, 0, 7),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(4) })
			bind(track, "BackgroundColor3", "Off")

			local fill = New("Frame", {
				Size = UDim2.fromScale(0, 1),
				BorderSizePixel = 0,
				Parent = track,
			}, { Corner(4) })
			bind(fill, "BackgroundColor3", "Accent")

			New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = C.White,
				BorderSizePixel = 0,
				Parent = fill,
			}, { Corner(7) })

			local o = { CurrentValue = c.CurrentValue or min }
			local lastFire, fireId = 0, 0

			valueBox.Focused:Connect(function()
				valueBox.Text = tostring(o.CurrentValue)
			end)
			valueBox.FocusLost:Connect(function()
				local n = tonumber(valueBox.Text)
				if n then
					o:Set(n)
				else
					o:Set(o.CurrentValue, true)
				end
			end)

			function o:Set(v, silent)
				v = math.clamp(round(v, inc), min, max)
				o.CurrentValue = v

				local alpha = max > min and (v - min) / (max - min) or 0
				Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.08)
				valueBox.Text = tostring(v) .. (c.Suffix and (" " .. c.Suffix) or "")

				if c.Flag then
					Lumen.Flags[c.Flag] = v
				end

				if not silent then
					-- Throttle callbacks to ~16/s; always deliver the final value
					local now = os.clock()
					if now - lastFire < 0.06 then
						fireId += 1
						local id = fireId
						task.delay(0.06, function()
							if id == fireId then
								safe(c.Callback, o.CurrentValue)
							end
						end)
					else
						lastFire = now
						safe(c.Callback, v)
					end
				end
			end
			function o:Get() return o.CurrentValue end

			local area = New("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Position = UDim2.new(0, 0, 1, -34),
				Size = UDim2.new(1, 0, 0, 34),
				Parent = f,
			})
			drag(area, track, function(x)
				o:Set(min + (max - min) * x)
			end)

			reg(c.Flag, o, o.CurrentValue)
			o:Set(o.CurrentValue, true)
			return base(f, o)
		end

		function host:CreateProgress(c)
			local f = card(48, c.Neon)
			text(f, c.Name or "Progress", 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 5), UDim2.new(0.6, 0, 0, 20))
			local valueLabel = text(f, "", 12, Enum.Font.GothamMedium, "Sub",
				UDim2.new(0.4, -12, 0, 5), UDim2.new(0.6, 0, 0, 20), Enum.TextXAlignment.Right)

			local track = New("Frame", {
				Position = UDim2.new(0, 12, 1, -16),
				Size = UDim2.new(1, -24, 0, 7),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(4) })
			bind(track, "BackgroundColor3", "Off")

			local fill = New("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = c.Color or T.Accent,
				BorderSizePixel = 0,
				Parent = track,
			}, { Corner(4) })
			if not c.Color then
				bind(fill, "BackgroundColor3", "Accent")
			end

			local o = {}
			function o:Set(v, label)
				v = math.clamp(v, 0, 1)
				Tween(fill, { Size = UDim2.fromScale(v, 1) }, 0.25)
				valueLabel.Text = label or (math.floor(v * 100 + 0.5) .. "%")
			end

			o:Set(c.Value or 0, c.Label)
			return base(f, o)
		end

		function host:CreateDropdown(c)
			local multi = c.MultipleOptions == true
			local options = c.Options or {}

			local f = card(40, c.Neon)
			text(f, c.Name or "Dropdown", 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 0, 40))

			local current = text(f, "", 12, Enum.Font.GothamMedium, "Sub",
				UDim2.new(0.5, -34, 0, 0), UDim2.new(0.5, 0, 0, 40), Enum.TextXAlignment.Right)
			current.TextTruncate = Enum.TextTruncate.AtEnd

			local arrow = text(f, "▾", 14, Enum.Font.GothamMedium, "Sub",
				UDim2.new(1, -26, 0, 0), UDim2.fromOffset(16, 40), Enum.TextXAlignment.Center)

			local search = New("TextBox", {
				Position = UDim2.fromOffset(8, 44),
				Size = UDim2.new(1, -16, 0, 26),
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				PlaceholderText = "Search...",
				Text = "",
				ClearTextOnFocus = false,
				Visible = false,
				BackgroundTransparency = 0.2,
				Parent = f,
			}, { Corner(6), Pad(8, 0, 8, 0) })
			bind(search, "BackgroundColor3", "Panel")
			bind(search, "TextColor3", "Text")
			bind(search, "PlaceholderColor3", "Sub")

			local list = New("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 2,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -12, 0, 0),
				Parent = f,
			}, { List(3) })

			local head = hit(f, 40)
			hover(f, head)

			local o = { Open = false, Options = options }
			local selected, buttons, visibleCount = {}, {}, 0

			if type(c.CurrentOption) == "table" then
				for _, v in ipairs(c.CurrentOption) do
					selected[v] = true
				end
			elseif c.CurrentOption ~= nil then
				selected[c.CurrentOption] = true
			end

			local function value()
				if multi then
					local t = {}
					for _, op in ipairs(o.Options) do
						if selected[op] then
							t[#t + 1] = op
						end
					end
					return t
				end
				for _, op in ipairs(o.Options) do
					if selected[op] then
						return op
					end
				end
				return nil
			end

			local function style()
				local v = value()
				if multi then
					current.Text = #v == 0 and "None"
						or ((c.MaxPick and ("(" .. #v .. "/" .. c.MaxPick .. ") ") or "") .. table.concat(v, ", "))
				else
					current.Text = v ~= nil and tostring(v) or "None"
				end
				for op, b in pairs(buttons) do
					Tween(b, { TextColor3 = selected[op] and T.Accent or T.Text }, 0.15)
				end
			end
			onTheme(style)

			local function listHeight()
				return math.min(visibleCount * 31, 150)
			end

			local function layout()
				search.Visible = #o.Options > 7
				local top = 44 + (search.Visible and 32 or 0)
				list.Position = UDim2.fromOffset(6, top)
				Tween(f, { Size = UDim2.new(1, 0, 0, o.Open and (top + listHeight() + 8) or 40) }, 0.25)
				Tween(list, { Size = UDim2.new(1, -12, 0, o.Open and listHeight() or 0) }, 0.25)
				Tween(arrow, { Rotation = o.Open and 180 or 0 }, 0.25)
			end

			local function applyFilter()
				local q = search.Text:lower()
				visibleCount = 0
				for _, op in ipairs(o.Options) do
					local b = buttons[op]
					if b then
						local show = q == "" or tostring(op):lower():find(q, 1, true) ~= nil
						b.Visible = show
						if show then
							visibleCount += 1
						end
					end
				end
				layout()
			end
			search:GetPropertyChangedSignal("Text"):Connect(applyFilter)

			local function commit(silent)
				style()
				local v = value()
				if c.Flag then
					Lumen.Flags[c.Flag] = v
				end
				if not silent then
					safe(c.Callback, v)
				end
			end

			local function build()
				for _, b in pairs(buttons) do
					b:Destroy()
				end
				buttons = {}

				for i, op in ipairs(o.Options) do
					local b = New("TextButton", {
						LayoutOrder = i,
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundTransparency = 1,
						Text = tostring(op),
						Font = Enum.Font.GothamMedium,
						TextSize = 11,
						AutoButtonColor = false,
						Parent = list,
					}, { Corner(6) })
					b.BackgroundColor3 = C.White
					b.TextColor3 = T.Text

					b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.88 }, 0.1) end)
					b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 1 }, 0.1) end)

					b.MouseButton1Click:Connect(function()
						if multi then
							if not selected[op] and c.MaxPick then
								local n = 0
								for _ in pairs(selected) do
									n += 1
								end
								if n >= c.MaxPick then
									return
								end
							end
							selected[op] = (not selected[op]) or nil
						else
							selected = { [op] = true }
							o.Open = false
							search.Text = ""
							layout()
						end
						commit()
					end)

					buttons[op] = b
				end

				visibleCount = #o.Options
				commit(true)
			end

			function o:Set(v, silent)
				selected = {}
				if type(v) == "table" then
					for _, x in ipairs(v) do
						selected[x] = true
					end
				elseif v ~= nil then
					selected[v] = true
				end
				commit(silent)
			end
			function o:Refresh(opts)
				o.Options = opts
				selected = {}
				search.Text = ""
				build()
				layout()
			end
			function o:Clear(silent)
				selected = {}
				commit(silent)
			end
			function o:Get() return value() end
			function o:Close()
				if o.Open then
					o.Open = false
					search.Text = ""
					layout()
				end
			end

			-- Only one dropdown open at a time
			W._dropdowns = W._dropdowns or {}
			W._dropdowns[#W._dropdowns + 1] = o

			head.MouseButton1Click:Connect(function()
				if not o.Open then
					for _, other in ipairs(W._dropdowns) do
						if other ~= o and other.Frame and other.Frame.Parent then
							other:Close()
						end
					end
				end
				o.Open = not o.Open
				layout()
			end)

			build()
			reg(c.Flag, o, value())
			return base(f, o)
		end

		function host:CreateInput(c)
			local f = card(40, c.Neon)
			text(f, c.Name or "Input", 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 1, 0))

			local box = New("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.new(0.42, 0, 0, 26),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				ClearTextOnFocus = false,
				PlaceholderText = c.PlaceholderText or "Type here...",
				Text = tostring(c.CurrentValue or ""),
				Parent = f,
			}, { Corner(6), Pad(8, 0, 24, 0) })

			if c.Password then
				box.Text = string.rep("•", #box.Text)
			end

			bind(box, "BackgroundColor3", "Panel")
			bind(box, "TextColor3", "Text")
			bind(box, "PlaceholderColor3", "Sub")

			local stroke = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1,
				Transparency = 0.85,
				Parent = box,
			})
			bind(stroke, "Color", "Line")

			box.Focused:Connect(function()
				Tween(stroke, { Color = T.Accent, Transparency = 0 }, 0.15)
			end)

			local clear = New("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 20, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Text = "×",
				Font = Enum.Font.GothamMedium,
				TextSize = 14,
				AutoButtonColor = false,
				Visible = box.Text ~= "",
				Parent = box,
			})
			bind(clear, "TextColor3", "Sub")

			box:GetPropertyChangedSignal("Text"):Connect(function()
				clear.Visible = box.Text ~= ""
			end)
			clear.MouseButton1Click:Connect(function()
				box.Text = ""
				box:CaptureFocus()
			end)

			local o = { CurrentValue = c.CurrentValue or "" }

			box.FocusLost:Connect(function()
				Tween(stroke, { Color = T.Line, Transparency = 0.85 }, 0.15)

				local v = box.Text
				if c.Password then
					v = o.CurrentValue
				end

				if c.Numeric then
					local n = tonumber(v)
					if n == nil then
						box.Text = o.CurrentValue
						return
					end
					v = tostring(n)
					box.Text = v
				end

				o.CurrentValue = v
				if c.Flag then
					Lumen.Flags[c.Flag] = v
				end
				safe(c.Callback, v)

				if c.RemoveTextAfterFocusLost then
					box.Text = ""
				end
			end)

			function o:Set(str, silent)
				str = tostring(str)
				o.CurrentValue = str
				box.Text = c.Password and string.rep("•", #str) or str
				if c.Flag then
					Lumen.Flags[c.Flag] = str
				end
				if not silent then
					safe(c.Callback, str)
				end
			end
			function o:Get() return o.CurrentValue end

			reg(c.Flag, o, o.CurrentValue)
			return base(f, o)
		end

		function host:CreateKeybind(c)
			local f = card(40, c.Neon)
			named(f, c.Name or "Keybind", nil, 90)

			local button = hit(f)
			hover(f, button)

			local keyLabel = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(70, 24),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				TextSize = 10,
				Text = c.CurrentKeybind or "None",
				Parent = f,
			}, { Corner(6) })
			bind(keyLabel, "BackgroundColor3", "Panel")
			bind(keyLabel, "TextColor3", "Sub")

			local o = { CurrentKeybind = c.CurrentKeybind, Listening = false }

			function o:Set(key, silent)
				o.CurrentKeybind = key
				keyLabel.Text = key or "None"
				if c.Flag then
					Lumen.Flags[c.Flag] = key
				end
				if not silent then
					safe(c.ChangedCallback, key)
				end
			end
			function o:Get() return o.CurrentKeybind end

			button.MouseButton1Click:Connect(function()
				o.Listening = true
				Lumen.Listening = true
				keyLabel.Text = "..."
			end)

			conn(UIS.InputBegan:Connect(function(i, gpe)
				if i.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end

				if o.Listening then
					o.Listening = false
					task.defer(function()
						Lumen.Listening = false
					end)
					o:Set(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode.Name or nil)
				elseif not gpe and not Lumen.Listening
					and o.CurrentKeybind and i.KeyCode.Name == o.CurrentKeybind then
					safe(c.Callback, c.Mode == "Hold" and true or nil)
				end
			end))

			if c.Mode == "Hold" then
				conn(UIS.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.Keyboard
						and o.CurrentKeybind and i.KeyCode.Name == o.CurrentKeybind then
						safe(c.Callback, false)
					end
				end))
			end

			reg(c.Flag, o, o.CurrentKeybind)
			return base(f, o)
		end

		function host:CreateColorPicker(c)
			local f = card(40, c.Neon)
			named(f, c.Name or "Color", nil, 60)

			local swatch = New("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(34, 20),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(6) })

			-- Saturation / value square
			local sv = New("Frame", {
				Position = UDim2.fromOffset(12, 48),
				Size = UDim2.new(1, -52, 0, 100),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(6) })

			New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = C.White,
				BorderSizePixel = 0,
				Parent = sv,
			}, { Corner(6), New("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })

			New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = C.Black,
				BorderSizePixel = 0,
				Parent = sv,
			}, { Corner(6), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })

			local dot = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(10, 10),
				BackgroundTransparency = 1,
				ZIndex = 5,
				Parent = sv,
			}, {
				Corner(5),
				New("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 2,
					Color = C.White,
				}),
			})

			local svHit = New("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 6,
				Parent = sv,
			})

			-- Hue bar
			local hueKeys = {}
			for i = 0, 6 do
				hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1))
			end

			local hue = New("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 48),
				Size = UDim2.fromOffset(20, 100),
				BackgroundColor3 = C.White,
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(6), New("UIGradient", { Rotation = 90, Color = ColorSequence.new(hueKeys) }) })

			local hueDot = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(1, 4, 0, 4),
				BackgroundColor3 = C.White,
				BorderSizePixel = 0,
				Parent = hue,
			}, { Corner(2) })

			local hueHit = New("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 6,
				Parent = hue,
			})

			local hex = New("TextBox", {
				Position = UDim2.fromOffset(12, 156),
				Size = UDim2.new(1, -24, 0, 26),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				TextSize = 11,
				ClearTextOnFocus = false,
				Text = "",
				Parent = f,
			}, { Corner(6), Pad(8, 0, 8, 0) })
			bind(hex, "BackgroundColor3", "Panel")
			bind(hex, "TextColor3", "Text")

			local header = hit(f, 40)
			hover(f, header)

			local h, s, v = (c.Color or C.White):ToHSV()
			local o = { Open = false }

			local function apply(silent)
				local color = Color3.fromHSV(h, s, v)
				o.CurrentColor = color
				swatch.BackgroundColor3 = color
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				dot.Position = UDim2.fromScale(s, 1 - v)
				hueDot.Position = UDim2.fromScale(0.5, h)
				hex.Text = "#" .. color:ToHex():upper()
				if c.Flag then
					Lumen.Flags[c.Flag] = color
				end
				if not silent then
					safe(c.Callback, color)
				end
			end

			drag(svHit, sv, function(x, y)
				s, v = x, 1 - y
				apply()
			end)
			drag(hueHit, hue, function(_, y)
				h = math.clamp(y, 0, 0.999)
				apply()
			end)

			hex.FocusLost:Connect(function()
				local str = hex.Text:gsub("#", "")
				local ok, color = pcall(Color3.fromHex, "#" .. str)
				if ok and color then
					h, s, v = color:ToHSV()
				end
				apply()
			end)

			function o:Set(color, silent)
				h, s, v = color:ToHSV()
				apply(silent)
			end
			function o:Get() return o.CurrentColor end

			header.MouseButton1Click:Connect(function()
				o.Open = not o.Open
				Tween(f, { Size = UDim2.new(1, 0, 0, o.Open and 192 or 40) }, 0.25)
			end)

			reg(c.Flag, o, c.Color or C.White)
			apply(true)
			return base(f, o)
		end

		---------------- info / dashboard cards ----------------
		local ageDays = lp.AccountAge
		local createdAt = os.time() - ageDays * 86400

		function host:CreateProfileCard(c)
			c = c or {}
			local f = card(268)

			New("Frame", {
				Size = UDim2.new(1, 0, 0, 80),
				BackgroundColor3 = T.Accent:Lerp(C.Black, 0.5),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(10) })

			if type(c.Badge) == "string" then
				New("TextLabel", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -10, 0, 10),
					Size = UDim2.fromOffset(110, 24),
					BackgroundColor3 = rgb(20, 20, 40),
					BackgroundTransparency = 0.3,
					Font = Enum.Font.GothamMedium,
					TextSize = 10,
					TextColor3 = T.Text,
					Text = c.Badge,
					Parent = f,
				}, {
					Corner(12),
					New("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = 1.2,
						Color = T.Accent,
					}),
				})
			end

			local avatar = New("ImageLabel", {
				Position = UDim2.fromOffset(12, 36),
				Size = UDim2.fromOffset(84, 84),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(42) })
			bind(avatar, "BackgroundColor3", "Panel")

			local avatarStroke = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 3,
				Color = C.White,
				Parent = avatar,
			})
			bind(avatarStroke, "Color", "Accent")
			loadAvatar(avatar)

			-- Online dot
			local onlineDot = New("Frame", {
				Position = UDim2.fromOffset(78, 100),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = C.Green,
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = f,
			}, { Corner(8) })
			local dotStroke = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 2,
				Parent = onlineDot,
			})
			bind(dotStroke, "Color", "Card")

			text(f, lp.DisplayName, 16, Enum.Font.GothamBold, "Text",
				UDim2.fromOffset(106, 86), UDim2.new(1, -116, 0, 20)).TextTruncate = Enum.TextTruncate.AtEnd
			text(f, "@" .. lp.Name, 11, Enum.Font.GothamMedium, "Sub",
				UDim2.fromOffset(106, 106), UDim2.new(1, -116, 0, 14)).TextTruncate = Enum.TextTruncate.AtEnd

			-- Click-to-copy user id pill
			local idPill = New("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 126),
				Size = UDim2.new(1, -24, 0, 22),
				BackgroundTransparency = 0.2,
				Font = Enum.Font.GothamMedium,
				TextSize = 10,
				AutoButtonColor = false,
				Text = "ID  " .. lp.UserId,
				Parent = f,
			}, { Corner(11) })
			bind(idPill, "BackgroundColor3", "Panel")
			bind(idPill, "TextColor3", "Text")

			local idStroke = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1.2,
				Transparency = 0.7,
				Parent = idPill,
			})
			bind(idStroke, "Color", "Line")

			idPill.MouseButton1Click:Connect(function()
				if type(setclipboard) == "function" then
					pcall(setclipboard, tostring(lp.UserId))
					W:Notify({ Title = "Copied", Content = tostring(lp.UserId), Duration = 2, Type = "Success" })
				end
			end)

			-- Chips: weekday created / age / days
			local years, months = math.floor(ageDays / 365), math.floor((ageDays % 365) / 30)
			local chips = New("Frame", {
				Position = UDim2.fromOffset(12, 156),
				Size = UDim2.new(1, -24, 0, 22),
				BackgroundTransparency = 1,
				Parent = f,
			}, { List(5, true) })

			local chipData = c.Chips or {
				dayName(createdAt),
				L("%dy %dm", years, months),
				L("%d days", ageDays),
			}

			for i, label in ipairs(chipData) do
				local chip = New("TextLabel", {
					LayoutOrder = i,
					Size = UDim2.new(1 / #chipData, -4, 1, 0),
					BackgroundTransparency = 0.3,
					Font = Enum.Font.GothamMedium,
					TextSize = 10,
					Text = label,
					Parent = chips,
				}, {
					Corner(11),
					New("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = 1,
						Color = C.White,
						Transparency = 0.8,
					}),
				})
				bind(chip, "BackgroundColor3", "Panel")
				bind(chip, "TextColor3", "Text")
			end

			-- Stat boxes
			local stats = New("Frame", {
				Position = UDim2.fromOffset(12, 188),
				Size = UDim2.new(1, -24, 0, 56),
				BackgroundTransparency = 1,
				Parent = f,
			}, { List(8, true) })

			local defs = c.Stats or {
				{ Label = "FRIENDS", Color = T.Sub, Value = "…" },
				{ Label = "PING",    Color = T.Sub, Value = "…" },
				{ Label = "FPS",     Color = T.Sub, Value = "…" },
			}

			local valueLabels = {}
			for i, d in ipairs(defs) do
				local box = New("Frame", {
					LayoutOrder = i,
					Size = UDim2.new(1 / #defs, -math.ceil(8 * (#defs - 1) / #defs), 1, 0),
					BackgroundTransparency = 0.35,
					BorderSizePixel = 0,
					Parent = stats,
				}, {
					Corner(10),
					New("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = 1.4,
						Color = d.Color,
						Transparency = 0.3,
					}),
				})
				bind(box, "BackgroundColor3", "Panel")

				valueLabels[i] = New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 6),
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.GothamBold,
					TextSize = 15,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextColor3 = T.Text,
					Text = type(d.Value) == "function" and "…" or tostring(d.Value),
					Parent = box,
				})

				text(box, d.Label, 9, Enum.Font.GothamMedium, "Text",
					UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 14), Enum.TextXAlignment.Center)
			end

			if c.Stats then
				onTick(function()
					for i, d in ipairs(defs) do
						if type(d.Value) == "function" then
							valueLabels[i].Text = tostring(d.Value())
						end
					end
				end)
			else
				-- Default stats: friend count / ping / fps
				task.spawn(function()
					local ok, count = pcall(function()
						local pages, n = Players:GetFriendsAsync(lp.UserId), 0
						while true do
							n += #pages:GetCurrentPage()
							if pages.IsFinished then
								break
							end
							pages:AdvanceToNextPageAsync()
						end
						return n
					end)
					valueLabels[1].Text = ok and tostring(count) or "-"
				end)

				onTick(function()
					valueLabels[2].Text = Live.Ping > 0 and (Live.Ping .. "ms") or "-"
					valueLabels[3].Text = tostring(Live.FPS)
				end)
			end

			return base(f, {})
		end

		function host:CreateClockCard()
			local f = card(70, "accent")

			local time = text(f, "", 22, Enum.Font.GothamBold, "Text",
				UDim2.fromOffset(12, 8), UDim2.new(0.6, 0, 0, 28))
			local date = text(f, "", 11, Enum.Font.GothamMedium, "Sub",
				UDim2.fromOffset(12, 40), UDim2.new(1, -24, 0, 16))
			local session = text(f, "", 11, Enum.Font.GothamMedium, C.Green,
				UDim2.new(0.4, 0, 0, 12), UDim2.new(0.6, -12, 0, 16), Enum.TextXAlignment.Right)

			local started = os.clock()
			onTick(function()
				time.Text = os.date("%H:%M:%S")
				date.Text = fmtDate(os.time())
				session.Text = "● " .. L("session %s", fmtDuration(os.clock() - started))
			end)

			return base(f, {})
		end

		-- Shared builder for the two bar graphs below
		local function barGraph(title, colorFn, maxValue, valueFn, summaryFn)
			local f = card(96, "accent")
			text(f, title, 12, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 6), UDim2.new(0.5, 0, 0, 18))
			local summary = text(f, "", 11, Enum.Font.GothamMedium, "Sub",
				UDim2.new(0.5, 0, 0, 6), UDim2.new(0.5, -12, 0, 18), Enum.TextXAlignment.Right)

			local N = 40
			local area = New("Frame", {
				Position = UDim2.fromOffset(12, 30),
				Size = UDim2.new(1, -24, 0, 56),
				BackgroundTransparency = 1,
				Parent = f,
			})

			local bars, history = {}, {}
			for i = 1, N do
				history[i] = 0
				bars[i] = New("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new((i - 1) / N, 0, 1, 0),
					Size = UDim2.new(1 / N, -2, 0.03, 0),
					BorderSizePixel = 0,
					Parent = area,
				}, { Corner(2) })
			end

			onTick(function()
				table.remove(history, 1)
				history[#history + 1] = valueFn()
				for i = 1, N do
					local v = history[i]
					bars[i].BackgroundColor3 = colorFn(v)
					bars[i].Size = UDim2.new(1 / N, -2, math.clamp(v / maxValue, 0.03, 1), 0)
				end
				summary.Text = summaryFn()
			end)

			return base(f, {})
		end

		function host:CreateFpsGraph()
			return barGraph(
				"Performance",
				function(v) return v >= 50 and C.Green or (v >= 30 and C.Gold or C.Red) end,
				120,
				function() return Live.FPS end,
				function() return Live.FPS .. " FPS  /  " .. (Live.Ping > 0 and (Live.Ping .. " ms") or "- ms") end
			)
		end

		function host:CreatePingGraph()
			return barGraph(
				"Ping",
				function(v) return v < 100 and C.Green or (v < 200 and C.Gold or C.Red) end,
				300,
				function() return Live.Ping end,
				function() return (Live.Ping > 0 and (Live.Ping .. " ms") or "- ms") .. "  |  " .. Live.FPS .. " FPS" end
			)
		end

		function host:CreatePlayerList(c)
			c = c or {}
			local f = card(260)

			text(f, c.Name or "Players", 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 20))

			local search = New("TextBox", {
				Position = UDim2.fromOffset(12, 32),
				Size = UDim2.new(1, -24, 0, 26),
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				PlaceholderText = "Search players...",
				Text = "",
				ClearTextOnFocus = false,
				BackgroundTransparency = 0.2,
				Parent = f,
			}, { Corner(6), Pad(8, 0, 8, 0) })
			bind(search, "BackgroundColor3", "Panel")
			bind(search, "TextColor3", "Text")
			bind(search, "PlaceholderColor3", "Sub")

			local list = New("ScrollingFrame", {
				Position = UDim2.fromOffset(12, 66),
				Size = UDim2.new(1, -24, 0, 182),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 2,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Parent = f,
			}, { List(4) })

			local function build()
				for _, child in ipairs(list:GetChildren()) do
					if child:IsA("Frame") or child:IsA("TextButton") then
						child:Destroy()
					end
				end

				local q = search.Text:lower()
				for _, plr in ipairs(Players:GetPlayers()) do
					local matches = q == ""
						or plr.Name:lower():find(q, 1, true)
						or plr.DisplayName:lower():find(q, 1, true)

					if matches then
						local row = New("TextButton", {
							Size = UDim2.new(1, 0, 0, 36),
							BackgroundTransparency = 0.35,
							Text = "",
							AutoButtonColor = false,
							Parent = list,
						}, { Corner(8) })
						bind(row, "BackgroundColor3", "Panel")

						local av = New("ImageLabel", {
							Position = UDim2.fromOffset(4, 4),
							Size = UDim2.fromOffset(28, 28),
							BackgroundTransparency = 0.4,
							Parent = row,
						}, { Corner(14) })

						task.spawn(function()
							local ok, url = pcall(function()
								return Players:GetUserThumbnailAsync(
									plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
								)
							end)
							if ok then
								av.Image = url
							end
						end)

						text(row, plr.DisplayName, 12, Enum.Font.GothamMedium, "Text",
							UDim2.fromOffset(38, 4), UDim2.new(1, -90, 0, 16)).TextTruncate = Enum.TextTruncate.AtEnd
						text(row, "@" .. plr.Name, 10, Enum.Font.Gotham, "Sub",
							UDim2.fromOffset(38, 20), UDim2.new(1, -90, 0, 12)).TextTruncate = Enum.TextTruncate.AtEnd

						row.MouseButton1Click:Connect(function()
							safe(c.Callback, plr)
							if type(setclipboard) == "function" and c.CopyOnClick ~= false then
								pcall(setclipboard, plr.Name)
								W:Notify({ Title = "Copied", Content = plr.Name, Type = "Success", Duration = 1.5 })
							end
						end)
					end
				end
			end

			search:GetPropertyChangedSignal("Text"):Connect(build)
			conn(Players.PlayerAdded:Connect(build))
			conn(Players.PlayerRemoved:Connect(build))
			build()

			local o = {}
			function o:Refresh() build() end
			return base(f, o)
		end

		function host:CreateServerCard()
			host:CreateSection("Server")

			local players = host:CreateInfoRow(nil, "Players", "-")
			local uptime  = host:CreateInfoRow(nil, "Server time", "-")
			host:CreateInfoRow(nil, "Place ID", tostring(game.PlaceId))

			local job = game.JobId
			host:CreateInfoRow(nil, "Job ID", job ~= "" and (job:sub(1, 8) .. "...") or "-")

			onTick(function()
				players:Set(#Players:GetPlayers() .. " / " .. Players.MaxPlayers)
				uptime:Set(fmtDuration(workspace.DistributedGameTime))
			end)

			host:CreateButton({
				Name = "Copy Job ID",
				Callback = function()
					if type(setclipboard) == "function" and job ~= "" then
						pcall(setclipboard, job)
						W:Notify({ Title = "Copied", Content = job, Type = "Success", Duration = 2 })
					end
				end,
			})

			host:CreateButton({
				Name = "Rejoin",
				Callback = function()
					W:Dialog({
						Title = "Rejoin",
						Content = "Are you sure?",
						Buttons = {
							{
								Name = "Rejoin",
								Primary = true,
								Callback = function()
									local TS = game:GetService("TeleportService")
									pcall(function()
										if job ~= "" then
											TS:TeleportToPlaceInstance(game.PlaceId, job, lp)
										else
											TS:Teleport(game.PlaceId, lp)
										end
									end)
								end,
							},
							{ Name = "Cancel" },
						},
					})
				end,
			})
		end

		function host:CreateAnniversaryCard()
			local f = card(70)

			text(f, "Account anniversary", 12, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(12, 8), UDim2.new(0.55, 0, 0, 18))

			local daysLeft = 365 - (ageDays % 365)
			text(f, L("%d days left (year %d)", daysLeft, math.floor(ageDays / 365) + 1), 11,
				Enum.Font.GothamMedium, "Sub",
				UDim2.new(0.45, 0, 0, 8), UDim2.new(0.55, -12, 0, 18), Enum.TextXAlignment.Right)

			local bar = New("Frame", {
				Position = UDim2.fromOffset(12, 44),
				Size = UDim2.new(1, -24, 0, 8),
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(4) })
			bind(bar, "BackgroundColor3", "Off")

			local fill = New("Frame", {
				Size = UDim2.fromScale(0, 1),
				BorderSizePixel = 0,
				Parent = bar,
			}, { Corner(4) })
			bind(fill, "BackgroundColor3", "Accent")

			Tween(fill, { Size = UDim2.fromScale((ageDays % 365) / 365, 1) }, 0.8)
			return base(f, {})
		end

		function host:CreateGameCard()
			local f = card(70, "accent")

			local icon = New("ImageLabel", {
				Position = UDim2.fromOffset(8, 8),
				Size = UDim2.fromOffset(54, 54),
				BorderSizePixel = 0,
				Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150",
				Parent = f,
			}, { Corner(8) })
			bind(icon, "BackgroundColor3", "Panel")

			local name = text(f, "…", 13, Enum.Font.GothamMedium, "Text",
				UDim2.fromOffset(72, 8), UDim2.new(1, -80, 0, 18))
			name.TextTruncate = Enum.TextTruncate.AtEnd

			local by = text(f, "", 10, Enum.Font.Gotham, "Sub",
				UDim2.fromOffset(72, 26), UDim2.new(1, -80, 0, 14))
			local live = text(f, "", 11, Enum.Font.GothamMedium, C.Green,
				UDim2.fromOffset(72, 44), UDim2.new(1, -80, 0, 16))

			task.spawn(function()
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfo(game.PlaceId)
				end)
				if ok and info then
					name.Text = info.Name
					by.Text = L("by %s", (info.Creator and info.Creator.Name) or "?")
				else
					name.Text = game.Name
				end
			end)

			onTick(function()
				live.Text = "● " .. L("%d/%d players - up %s",
					#Players:GetPlayers(), Players.MaxPlayers, fmtDuration(workspace.DistributedGameTime))
			end)

			return base(f, {})
		end

		function host:CreateAccountDetails()
			host:CreateSection("Account details")

			local device = "PC"
			if UIS.TouchEnabled and not UIS.KeyboardEnabled then
				device = "Phone / Tablet"
			elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then
				device = "Console"
			end
			local cam = workspace.CurrentCamera
			if cam then
				device = device .. " - " .. math.floor(cam.ViewportSize.X) .. "x" .. math.floor(cam.ViewportSize.Y)
			end

			local locale = "-"
			pcall(function()
				locale = LocalizationService.RobloxLocaleId
			end)

			local executor = "-"
			pcall(function()
				if identifyexecutor then
					local a, b = identifyexecutor()
					executor = tostring(a) .. (b and (" " .. tostring(b)) or "")
				end
			end)

			local y, m, d = math.floor(ageDays / 365), math.floor((ageDays % 365) / 30), ageDays % 30

			host:CreateInfoRow(nil, "Created", fmtDate(createdAt))
			host:CreateInfoRow(nil, "Account age", L("%dy %dm %dd (%d days)", y, m, d, ageDays))
			host:CreateInfoRow(nil, "Locale", locale)
			host:CreateInfoRow(nil, "Team", lp.Team and lp.Team.Name or "-")
			host:CreateInfoRow(nil, "Device", device)
			host:CreateInfoRow(nil, "Executor", executor)
		end

		---------------- prebuilt settings blocks ----------------
		function host:CreateUISettings()
			host:CreateSection("Appearance")

			host:CreateSlider({
				Name = "UI scale",
				Range = { 60, 120 },
				Increment = 5,
				Suffix = "%",
				CurrentValue = math.floor(userScale * 100 + 0.5),
				Flag = "Lumen_Scale",
				Callback = function(v) W:SetUIScale(v / 100) end,
			})

			host:CreateSlider({
				Name = "Transparency",
				Range = { 0, 60 },
				Increment = 1,
				Suffix = "%",
				CurrentValue = math.floor(T.WinT * 100 + 0.5),
				Flag = "Lumen_Transparency",
				Callback = function(v) W:SetTransparency(v / 100) end,
			})

			host:CreateKeybind({
				Name = "Toggle key",
				CurrentKeybind = toggleKey.Name,
				Flag = "Lumen_ToggleKey",
				ChangedCallback = function(k)
					if k then
						W:SetToggleKey(k)
					end
				end,
			})

			host:CreateButton({
				Name = "Destroy UI",
				Neon = C.Red,
				Callback = function()
					W:Dialog({
						Title = "Destroy UI",
						Content = "Are you sure?",
						Buttons = {
							{ Name = "Delete", Primary = true, Callback = function() W:Destroy() end },
							{ Name = "Cancel" },
						},
					})
				end,
			})
		end

		function host:CreateUtilities()
			host:CreateSection("Utilities")

			local afkConn
			host:CreateToggle({
				Name = "Anti-AFK",
				Description = "Stops the idle kick",
				Flag = "Lumen_AntiAFK",
				Callback = function(on)
					if afkConn then
						afkConn:Disconnect()
						afkConn = nil
					end
					if on then
						afkConn = conn(lp.Idled:Connect(function()
							pcall(function()
								local vu = game:GetService("VirtualUser")
								vu:CaptureController()
								vu:ClickButton2(Vector2.new())
							end)
						end))
					end
				end,
			})

			if type(setfpscap) == "function" then
				host:CreateSlider({
					Name = "FPS cap",
					Range = { 30, 240 },
					Increment = 10,
					CurrentValue = 60,
					Flag = "Lumen_FPSCap",
					Callback = function(v) pcall(setfpscap, v) end,
				})
			end

			host:CreateButton({
				Name = "Server hop",
				Description = "Joins a different public server",
				Callback = function()
					task.spawn(function()
						local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
							.. "/servers/Public?sortOrder=Asc&limit=100"

						local ok, data = pcall(function()
							return HttpService:JSONDecode(game:HttpGet(url))
						end)
						if not ok or type(data) ~= "table" or type(data.data) ~= "table" then
							W:Notify({ Title = "Server hop", Content = "Could not load servers", Type = "Error" })
							return
						end

						local choices = {}
						for _, sv in ipairs(data.data) do
							if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then
								choices[#choices + 1] = sv
							end
						end
						if #choices == 0 then
							W:Notify({ Title = "Server hop", Content = "No other servers found", Type = "Warning" })
							return
						end

						local pick = choices[math.random(#choices)]
						W:Notify({ Title = "Server hop", Content = pick.playing .. "/" .. pick.maxPlayers .. " players", Duration = 2 })
						pcall(function()
							game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, pick.id, lp)
						end)
					end)
				end,
			})

			host:CreateButton({
				Name = "Copy join script",
				Callback = function()
					if type(setclipboard) ~= "function" then
						return
					end
					local code = string.format(
						'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)',
						game.PlaceId, game.JobId
					)
					pcall(setclipboard, code)
					W:Notify({ Title = "Copied", Content = "Copy join script", Type = "Success", Duration = 2 })
				end,
			})
		end

		function host:CreateConfigManager()
			host:CreateSection("Configs")

			local nameInput = host:CreateInput({
				Name = "Config name",
				PlaceholderText = "default",
				CurrentValue = "default",
			})

			local dropdown
			dropdown = host:CreateDropdown({
				Name = "Saved configs",
				Options = Lumen:ListConfigs(),
				Callback = function(v)
					if v then
						nameInput:Set(v, true)
					end
				end,
			})

			local function currentName()
				local n = nameInput:Get()
				if n == nil or n == "" then
					n = dropdown:Get()
				end
				return (n and n ~= "") and n or nil
			end

			host:CreateButton({
				Name = "Save",
				Callback = function()
					local n = currentName() or "default"
					local ok = Lumen:SaveConfig(n)
					dropdown:Refresh(Lumen:ListConfigs())
					W:Notify({ Title = "Configs", Content = "Saved: " .. n, Type = ok and "Success" or "Error" })
				end,
			})

			host:CreateButton({
				Name = "Load",
				Callback = function()
					local n = currentName()
					if not n then
						return
					end
					local ok = Lumen:LoadConfig(n)
					W:Notify({ Title = "Configs", Content = "Loaded: " .. n, Type = ok and "Success" or "Error" })
				end,
			})

			host:CreateButton({
				Name = "Delete",
				Neon = C.Red,
				Callback = function()
					local n = currentName()
					if not n then
						return
					end
					Lumen:DeleteConfig(n)
					dropdown:Refresh(Lumen:ListConfigs())
					W:Notify({ Title = "Configs", Content = "Deleted: " .. n })
				end,
			})

			host:CreateButton({
				Name = "Refresh",
				Callback = function()
					dropdown:Refresh(Lumen:ListConfigs())
				end,
			})
		end
	end

	------------------------------------------------------------------
	-- Tabs
	------------------------------------------------------------------
	local sideOrder = 0
	local function nextOrder()
		sideOrder += 1
		return sideOrder
	end

	function W:CreateTabSection(title)
		local label = text(Sidebar, string.upper(title or ""), 9, Enum.Font.GothamMedium, "Sub",
			UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 18))
		label.LayoutOrder = nextOrder()
		label.TextTransparency = 0.25
		return label
	end

	function W:CreateTab(name, icon)
		local Tab = { Name = name }

		local btn = New("TextButton", {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = T.Off,
			BackgroundTransparency = 0.65,
			Text = "",
			AutoButtonColor = false,
			Parent = Sidebar,
		}, { Corner(10) })

		local indicator = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 4, 0.5, 0),
			Size = UDim2.fromOffset(3, 0),
			BackgroundColor3 = C.White,
			BorderSizePixel = 0,
			Parent = btn,
		}, { Corner(2) })

		local iconObj = makeIcon(btn, icon or "", 24, 40, UDim2.fromOffset(12, 0))

		local label = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(icon and 42 or 16, 0),
			Size = UDim2.new(1, icon and -48 or -22, 1, 0),
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = name,
			Parent = btn,
		})

		local page = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = Pages,
		})

		-- A glass panel containing a scrolling list
		local function makePanel(pos, size)
			local panel = New("Frame", {
				Position = pos,
				Size = size,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = page,
			}, { Corner(18) })
			bind(panel, "BackgroundColor3", "Card")
			bind(panel, "BackgroundTransparency", "PanT")

			local stroke = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1.2,
				Parent = panel,
			})
			bind(stroke, "Color", "Line")
			bind(stroke, "Transparency", "LineT")

			local scroll = New("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 2,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Parent = panel,
			}, { List(10), Pad(10, 10, 10, 12) })

			return scroll, panel
		end

		local Scroll, basePanel = makePanel(UDim2.new(), UDim2.fromScale(1, 1))
		Tab.Page = page
		attachElements(Tab, Scroll)

		-- Two-column layout; returns left, right element hosts
		function Tab:Split(leftWidth)
			basePanel.Visible = false
			leftWidth = leftWidth or 0.46

			local function column(pos, size)
				local scroll = makePanel(pos, size)
				local h = {}
				attachElements(h, scroll)
				return h
			end

			return column(UDim2.new(0, 0, 0, 0), UDim2.new(leftWidth, -5, 1, 0)),
				column(UDim2.new(leftWidth, 5, 0, 0), UDim2.new(1 - leftWidth, -5, 1, 0))
		end

		local function paint(active, instant)
			local d = instant and 0 or 0.25
			Tween(btn, {
				BackgroundColor3 = active and T.Accent or T.Off,
				BackgroundTransparency = active and 0.08 or 0.6,
			}, d)
			Tween(indicator, {
				Size = UDim2.fromOffset(3, active and 18 or 0),
				BackgroundTransparency = active and 0 or 1,
			}, d)

			local color = active and C.White or T.Sub
			if iconObj:IsA("TextLabel") then
				Tween(iconObj, { TextColor3 = color }, d)
			else
				Tween(iconObj, { ImageColor3 = color }, d)
			end
			Tween(label, { TextColor3 = color }, d)
		end

		paint(false, true)
		Tab._paint = paint

		function Tab:Select()
			for _, t in ipairs(W.Tabs) do
				t.Page.Visible = false
				t._paint(false)
			end
			page.Position = UDim2.fromOffset(0, 10)
			page.Visible = true
			Tween(page, { Position = UDim2.new() }, 0.25)
			paint(true)
			W.ActiveTab = Tab
			saveWin()
		end

		onTheme(function()
			paint(W.ActiveTab == Tab, true)
		end)

		btn.MouseButton1Click:Connect(function()
			Tab:Select()
		end)
		btn.MouseEnter:Connect(function()
			if W.ActiveTab ~= Tab then
				Tween(btn, { BackgroundTransparency = 0.45 }, 0.12)
			end
		end)
		btn.MouseLeave:Connect(function()
			if W.ActiveTab ~= Tab then
				Tween(btn, { BackgroundTransparency = 0.6 }, 0.12)
			end
		end)

		regPalette("Tab: " .. name, function() Tab:Select() end, "Tab")

		W.Tabs[#W.Tabs + 1] = Tab

		-- First tab is selected by default. If a saved tab exists it is
		-- restored later (CreateHomeTab) once all tabs have been built.
		if #W.Tabs == 1 then
			if winState and winState.tab then
				local found = false
				for _, t in ipairs(W.Tabs) do
					if t.Name == winState.tab then
						found = true
					end
				end
				if not found then
					Tab:Select()
				end
			else
				Tab:Select()
			end
		end

		return Tab
	end

	function W:CreateHomeTab(name, icon)
		local tab = W:CreateTab(name or "Home", icon)
		local left, right = tab:Split(0.46)

		left:CreateProfileCard()
		left:CreateFpsGraph()
		left:CreatePingGraph()
		left:CreateAnniversaryCard()

		right:CreateGameCard()
		right:CreateClockCard()
		right:CreateServerCard()
		right:CreateAccountDetails()

		if winState and winState.tab then
			for _, t in ipairs(W.Tabs) do
				if t.Name == winState.tab then
					t:Select()
					break
				end
			end
		end

		return tab, left, right
	end

	------------------------------------------------------------------
	-- Window methods
	------------------------------------------------------------------
	function W:SetVisible(v)
		if locked and v then
			return
		end
		hidden = not v

		if blur then
			Tween(blur, { Size = v and (cfg.BlurSize or 14) or 0 }, 0.3)
		end

		if v then
			if not Main.Visible then
				Scale.Scale = fit() * 0.9
			end
			Main.Visible = true
			Tween(Scale, { Scale = fit() }, 0.35, Enum.EasingStyle.Back)
		else
			Tween(Scale, { Scale = fit() * 0.9 }, 0.2)
			task.delay(0.2, function()
				if hidden then
					Main.Visible = false
				end
			end)
		end
	end

	function W:Toggle()
		W:SetVisible(hidden)
	end

	function W:Minimize()
		minimized = not minimized
		Body.Visible = not minimized
		Tween(Main, { Size = UDim2.fromOffset(WIDTH, minimized and TOP or HEIGHT) }, 0.25)
	end

	-- Kept for API compatibility (this build is glass + blue only)
	function W:SetTheme(_) end
	function W:SetAccent(_) end

	function W:SetTransparency(t)
		T.WinT = math.clamp(t, 0, 0.9)
		refresh()
	end

	function W:SetUIScale(s)
		userScale = math.clamp(s, 0.5, 1.5)
		if not hidden then
			Tween(Scale, { Scale = fit() }, 0.2)
		end
		saveWin()
	end

	function W:SetToggleKey(key)
		if typeof(key) == "EnumItem" then
			toggleKey = key
		else
			local ok, keyCode = pcall(function()
				return Enum.KeyCode[key]
			end)
			if ok and keyCode then
				toggleKey = keyCode
			end
		end
	end

	function W:Destroy()
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		Lumen.Listening = false
		if blur then
			blur:Destroy()
		end
		Gui:Destroy()
		for i, w in ipairs(Lumen.Windows) do
			if w == W then
				table.remove(Lumen.Windows, i)
				break
			end
		end
	end

	function W:CreateWatermark(label)
		local f = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 44),
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Active = true,
			Parent = Gui,
		}, { Corner(13), Pad(12, 0, 12, 0) })
		bind(f, "BackgroundColor3", "Panel")

		local stroke = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Transparency = 0.7,
			Parent = f,
		})
		bind(stroke, "Color", "Accent")

		local textLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			Text = "",
			Parent = f,
		})
		bind(textLabel, "TextColor3", "Text")

		onTick(function()
			textLabel.Text = (label or cfg.Name or "Lumen")
				.. "  |  " .. Live.FPS .. " fps"
				.. "  |  " .. Live.Ping .. " ms"
				.. "  |  " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
		end)

		-- Draggable
		local dragging, startMouse, startPos
		f.InputBegan:Connect(function(i)
			if isPress(i) then
				dragging, startMouse, startPos = true, i.Position, f.Position
			end
		end)
		conn(UIS.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = i.Position - startMouse
				f.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end))
		conn(UIS.InputEnded:Connect(function(i)
			if isPress(i) then
				dragging = false
			end
		end))

		return {
			Frame = f,
			SetVisible = function(_, v) f.Visible = v end,
			Destroy = function() f:Destroy() end,
		}
	end

	function W:AutoLoad(name)
		return Lumen:LoadConfig(name or "autosave")
	end

	function W:AutoSave(name, interval)
		name = name or "autosave"
		local last
		task.spawn(function()
			while Gui.Parent do
				task.wait(interval or 10)

				local data = {}
				for k, v in pairs(Lumen.Flags) do
					data[k] = enc(v)
				end

				local ok, json = pcall(function()
					return HttpService:JSONEncode(data)
				end)
				if ok and json ~= last then
					last = json
					Lumen:SaveConfig(name)
				end
			end
		end)
	end

	------------------------------------------------------------------
	-- Dialogs: Dialog (buttons), Confirm (yes/no), Prompt (text input)
	------------------------------------------------------------------
	local function dialogOverlay(zIndex)
		local overlay = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Black,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = zIndex,
			Parent = Gui,
		})
		Tween(overlay, { BackgroundTransparency = 0.55 }, 0.2)
		return overlay
	end

	local function dialogBox(overlay, height, zIndex)
		return New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(300, height),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			ZIndex = zIndex,
			Parent = overlay,
		}, {
			Corner(14),
			New("UIGradient", { Rotation = 135, Color = ColorSequence.new(T.Window1, T.Window2) }),
		})
	end

	local function dialogButton(box, label, x, y, w, primary, zIndex)
		local b = New("TextButton", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, 34),
			BackgroundTransparency = primary and 0 or 0.3,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			Text = label,
			TextColor3 = C.White,
			AutoButtonColor = false,
			ZIndex = zIndex,
			Parent = box,
		}, { Corner(10) })
		bind(b, "BackgroundColor3", primary and "Accent" or "Off")
		return b
	end

	function W:Dialog(d)
		d = d or {}
		local overlay = dialogOverlay(50)

		local content = d.Content or ""
		local ok, size = pcall(function()
			return TextService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(260, 1000))
		end)
		local bodyH = content == "" and 0 or (ok and size.Y or 30)
		local H = 20 + 22 + 8 + bodyH + 18 + 34 + 16

		local box = dialogBox(overlay, H, 51)

		local stroke = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.2,
			Transparency = 0.8,
			Parent = box,
		})
		bind(stroke, "Color", "Line")

		local scale = New("UIScale", { Parent = box })
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local fitScale = math.min(0.9, (vp.X - 40) / 300, (vp.Y - 40) / H)
		scale.Scale = fitScale * 0.9
		Tween(scale, { Scale = fitScale }, 0.25, Enum.EasingStyle.Back)

		text(box, d.Title or "Notice", 15, Enum.Font.GothamMedium, "Text",
			UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 22))

		if content ~= "" then
			local body = text(box, content, 12, Enum.Font.Gotham, "Sub",
				UDim2.fromOffset(20, 48), UDim2.new(1, -40, 0, bodyH))
			body.TextWrapped = true
			body.TextYAlignment = Enum.TextYAlignment.Top
		end

		local function close()
			Tween(overlay, { BackgroundTransparency = 1 }, 0.15)
			Tween(scale, { Scale = fitScale * 0.9 }, 0.15)
			task.delay(0.16, function()
				overlay:Destroy()
			end)
		end

		local buttons = d.Buttons or { { Name = "OK", Primary = true } }
		local n = #buttons
		local w = (260 - 8 * (n - 1)) / n

		for i, bd in ipairs(buttons) do
			local b = dialogButton(box, bd.Name or "OK", 20 + (i - 1) * (w + 8), H - 16 - 34, w, bd.Primary, 52)
			b.MouseButton1Click:Connect(function()
				close()
				safe(bd.Callback)
			end)
		end

		return { Close = close }
	end

	-- Yields until the user answers; returns true / false
	function W:Confirm(d)
		d = d or {}
		local done = Instance.new("BindableEvent")
		local overlay = dialogOverlay(60)

		local H = 20 + 22 + 8 + 30 + 18 + 34 + 16
		local box = dialogBox(overlay, H, 61)

		text(box, d.Title or "Confirm", 15, Enum.Font.GothamMedium, "Text",
			UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 22))

		local body = text(box, d.Content or "Are you sure?", 12, Enum.Font.Gotham, "Sub",
			UDim2.fromOffset(20, 48), UDim2.new(1, -40, 0, 30))
		body.TextWrapped = true
		body.TextYAlignment = Enum.TextYAlignment.Top

		local function close(result)
			Tween(overlay, { BackgroundTransparency = 1 }, 0.15)
			task.delay(0.15, function()
				overlay:Destroy()
				done:Fire(result)
			end)
		end

		dialogButton(box, d.YesText or "Yes", 20, H - 50, 126, true, 62)
			.MouseButton1Click:Connect(function() close(true) end)
		dialogButton(box, d.NoText or "No", 154, H - 50, 126, false, 62)
			.MouseButton1Click:Connect(function() close(false) end)

		local result = done.Event:Wait()
		done:Destroy()
		return result
	end

	-- Yields until the user answers; returns the text, or nil if cancelled
	function W:Prompt(d)
		d = d or {}
		local done = Instance.new("BindableEvent")
		local overlay = dialogOverlay(60)

		local H = 20 + 22 + 8 + 30 + 10 + 34 + 10 + 34 + 16
		local box = dialogBox(overlay, H, 61)

		text(box, d.Title or "Input", 15, Enum.Font.GothamMedium, "Text",
			UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 22))

		local label = text(box, d.Content or "", 12, Enum.Font.Gotham, "Sub",
			UDim2.fromOffset(20, 48), UDim2.new(1, -40, 0, 30))
		label.TextWrapped = true
		label.TextYAlignment = Enum.TextYAlignment.Top

		local input = New("TextBox", {
			Position = UDim2.fromOffset(20, 88),
			Size = UDim2.new(1, -40, 0, 34),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			PlaceholderText = d.Placeholder or "Type here...",
			Text = d.Default or "",
			ClearTextOnFocus = false,
			ZIndex = 62,
			Parent = box,
		}, { Corner(8), Pad(10, 0, 10, 0) })
		bind(input, "BackgroundColor3", "Panel")
		bind(input, "TextColor3", "Text")
		bind(input, "PlaceholderColor3", "Sub")

		local function close(result)
			Tween(overlay, { BackgroundTransparency = 1 }, 0.15)
			task.delay(0.15, function()
				overlay:Destroy()
				done:Fire(result)
			end)
		end

		dialogButton(box, d.SubmitText or "Submit", 20, H - 50, 126, true, 62)
			.MouseButton1Click:Connect(function() close(input.Text) end)
		dialogButton(box, "Cancel", 154, H - 50, 126, false, 62)
			.MouseButton1Click:Connect(function() close(nil) end)

		input.FocusLost:Connect(function(enter)
			if enter then
				close(input.Text)
			end
		end)

		task.delay(0.1, function()
			pcall(function() input:CaptureFocus() end)
		end)

		local result = done.Event:Wait()
		done:Destroy()
		return result
	end

	function W:CreateLoadingScreen(c)
		c = c or {}

		local overlay = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			ZIndex = 100,
			Parent = Gui,
		}, {
			Corner(0),
			New("UIGradient", { Rotation = 135, Color = ColorSequence.new(T.Window1, T.Window2) }),
		})

		local center = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(320, 180),
			BackgroundTransparency = 1,
			ZIndex = 101,
			Parent = overlay,
		})

		text(center, c.Title or (cfg.Name or "Lumen"), 22, Enum.Font.GothamBold, "Text",
			UDim2.fromOffset(0, 10), UDim2.new(1, 0, 0, 30), Enum.TextXAlignment.Center)
		local sub = text(center, c.Subtitle or "Loading... Please wait", 12, Enum.Font.Gotham, "Sub",
			UDim2.fromOffset(0, 44), UDim2.new(1, 0, 0, 20), Enum.TextXAlignment.Center)

		local track = New("Frame", {
			Position = UDim2.new(0, 20, 0, 90),
			Size = UDim2.new(1, -40, 0, 8),
			BorderSizePixel = 0,
			ZIndex = 102,
			Parent = center,
		}, { Corner(4) })
		bind(track, "BackgroundColor3", "Off")

		local fill = New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BorderSizePixel = 0,
			ZIndex = 103,
			Parent = track,
		}, { Corner(4) })
		bind(fill, "BackgroundColor3", "Accent")

		local pct = text(center, "0%", 11, Enum.Font.GothamMedium, "Sub",
			UDim2.fromOffset(0, 106), UDim2.new(1, 0, 0, 16), Enum.TextXAlignment.Center)

		local o = {}
		local closed = false

		function o:Set(v, label)
			if closed then
				return
			end
			v = math.clamp(v, 0, 1)
			Tween(fill, { Size = UDim2.fromScale(v, 1) }, 0.2)
			pct.Text = math.floor(v * 100) .. "% "
			if label then
				sub.Text = label
			end
		end

		function o:Close()
			if closed then
				return
			end
			closed = true
			Tween(overlay, { BackgroundTransparency = 1 }, 0.3)
			task.delay(0.3, function()
				overlay:Destroy()
			end)
		end

		if c.Duration then
			task.spawn(function()
				for i = 1, 20 do
					if closed then
						break
					end
					o:Set(i / 20, c.Subtitle or "Loading...")
					task.wait(c.Duration / 20)
				end
				o:Close()
			end)
		end

		return o
	end

	------------------------------------------------------------------
	-- Command palette (Ctrl + K)
	------------------------------------------------------------------
	local paletteGui = nil

	local function closePalette()
		if paletteGui then
			paletteGui:Destroy()
			paletteGui = nil
		end
	end

	local function togglePalette()
		if paletteGui and paletteGui.Parent then
			closePalette()
			return
		end

		local overlay = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Black,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 80,
			Parent = Gui,
		})
		paletteGui = overlay

		local box = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 120),
			Size = UDim2.fromOffset(380, 320),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			ZIndex = 81,
			Parent = overlay,
		}, {
			Corner(14),
			New("UIGradient", { Rotation = 135, Color = ColorSequence.new(T.Window1, T.Window2) }),
		})

		local search = New("TextBox", {
			Position = UDim2.fromOffset(14, 14),
			Size = UDim2.new(1, -28, 0, 34),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			PlaceholderText = "Search actions...  (Ctrl + K to close)",
			Text = "",
			ClearTextOnFocus = false,
			ZIndex = 82,
			Parent = box,
		}, { Corner(8), Pad(10, 0, 10, 0) })
		bind(search, "BackgroundColor3", "Panel")
		bind(search, "TextColor3", "Text")
		bind(search, "PlaceholderColor3", "Sub")

		local list = New("ScrollingFrame", {
			Position = UDim2.fromOffset(14, 56),
			Size = UDim2.new(1, -28, 0, 250),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 82,
			Parent = box,
		}, { List(4) })

		local function build()
			for _, child in ipairs(list:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			local q = search.Text:lower()
			for _, item in ipairs(paletteItems) do
				if q == "" or item.Name:lower():find(q, 1, true) then
					local b = New("TextButton", {
						Size = UDim2.new(1, 0, 0, 32),
						BackgroundTransparency = 0.35,
						Text = "",
						AutoButtonColor = false,
						ZIndex = 83,
						Parent = list,
					}, { Corner(8) })
					bind(b, "BackgroundColor3", "Panel")

					text(b, item.Name, 12, Enum.Font.GothamMedium, "Text",
						UDim2.fromOffset(12, 0), UDim2.new(1, -100, 1, 0))
					text(b, item.Kind, 10, Enum.Font.Gotham, "Sub",
						UDim2.new(1, -70, 0, 0), UDim2.new(0, 60, 1, 0), Enum.TextXAlignment.Right)

					b.MouseButton1Click:Connect(function()
						local fn = item.Fn
						closePalette()
						safe(fn)
					end)
				end
			end
		end

		search:GetPropertyChangedSignal("Text"):Connect(build)
		build()

		overlay.MouseButton1Click:Connect(closePalette)

		task.delay(0.05, function()
			pcall(function() search:CaptureFocus() end)
		end)

		conn(UIS.InputBegan:Connect(function(i)
			if i.KeyCode == Enum.KeyCode.Escape and paletteGui then
				closePalette()
			end
		end))
	end

	------------------------------------------------------------------
	-- Window wiring: buttons, hotkeys, mobile button
	------------------------------------------------------------------
	MinBtn.MouseButton1Click:Connect(function()
		W:Minimize()
	end)

	HideBtn.MouseButton1Click:Connect(function()
		W:SetVisible(false)
		local hint = UIS.TouchEnabled and "Tap the button to reopen."
			or L("Press %s to reopen.", toggleKey.Name)
		W:Notify({ Title = "Hidden", Content = hint, Duration = 3 })
	end)

	regPalette("Toggle UI",       function() W:Toggle() end,   "Window")
	regPalette("Destroy UI",      function() W:Destroy() end,  "Window")
	regPalette("Command Palette", function() togglePalette() end, "Window")

	conn(UIS.InputBegan:Connect(function(i, gpe)
		if gpe or Lumen.Listening then
			return
		end

		local ctrl = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
		if ctrl and i.KeyCode == Enum.KeyCode.K then
			togglePalette()
			return
		end

		if i.KeyCode == toggleKey then
			W:Toggle()
		end
	end))

	-- Draggable floating toggle button for touch devices
	if cfg.MobileButton ~= false and UIS.TouchEnabled then
		local mb = New("TextButton", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(44, 44),
			BackgroundTransparency = 0.15,
			Text = "◆",
			Font = Enum.Font.GothamMedium,
			TextSize = 16,
			TextColor3 = C.White,
			AutoButtonColor = false,
			Parent = Gui,
		}, { Corner(22) })
		bind(mb, "BackgroundColor3", "Panel")

		local mbStroke = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2,
			Parent = mb,
		})
		bind(mbStroke, "Color", "Accent")

		local startInput, startPos, moved
		mb.InputBegan:Connect(function(i)
			if isPress(i) then
				startInput, startPos, moved = i.Position, mb.Position, false
			end
		end)
		conn(UIS.InputChanged:Connect(function(i)
			if startInput and isMove(i) then
				local d = i.Position - startInput
				if d.Magnitude > 8 then
					moved = true
				end
				if moved then
					mb.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + d.X,
						startPos.Y.Scale, startPos.Y.Offset + d.Y
					)
				end
			end
		end))
		conn(UIS.InputEnded:Connect(function(i)
			if startInput and isPress(i) then
				if not moved then
					W:Toggle()
				end
				startInput = nil
			end
		end))
	end

	------------------------------------------------------------------
	-- Key gate (optional)
	------------------------------------------------------------------
	local function runKeyGate(ks)
		local function trim(x)
			return (tostring(x):gsub("^%s+", ""):gsub("%s+$", ""))
		end

		local function norm(x)
			x = trim(x)
			if ks.CaseInsensitive then
				x = x:lower()
			end
			return x
		end

		-- Remote key list (one key per line), fetched lazily and cached
		local remote
		local function remoteKeys()
			if remote then
				return remote
			end
			remote = {}
			if ks.KeyUrl then
				local ok, body = pcall(function()
					return game:HttpGet(ks.KeyUrl)
				end)
				if ok and type(body) == "string" then
					for line in body:gmatch("[^\r\n]+") do
						if trim(line) ~= "" then
							remote[#remote + 1] = line
						end
					end
				end
			end
			return remote
		end

		local function check(input)
			local raw = trim(input)
			if raw == "" then
				return false
			end

			if type(ks.Check) == "function" then
				local ok, result = pcall(ks.Check, raw)
				if ok and result == true then
					return true
				end
			end

			local want = norm(raw)
			for _, k in ipairs(ks.Keys or {}) do
				if norm(k) == want then
					return true
				end
			end
			if ks.KeyUrl then
				for _, k in ipairs(remoteKeys()) do
					if norm(k) == want then
						return true
					end
				end
			end
			return false
		end

		-- Previously saved key still valid?
		local file = "Lumen/key_" .. ((cfg.Name or "ui"):gsub("[^%w_]", "_")) .. ".txt"
		if ks.SaveKey and fsOK() then
			local ok, saved = pcall(function()
				if isfile(file) then
					return readfile(file)
				end
			end)
			if ok and type(saved) == "string" then
				local ts, keyHash = saved:match("^(%d+)\n(.*)$")
				if not ts then
					ts, keyHash = tostring(os.time()), saved
				end
				local fresh = not ks.ExpireHours or (os.time() - tonumber(ts)) < ks.ExpireHours * 3600
				if fresh and keyHash and keyHash ~= "" then
					safe(ks.OnSuccess, "")
					return true
				end
			end
		end

		locked = true
		local done = Instance.new("BindableEvent")
		local GW, GH = 340, 224

		local gate = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(GW, GH),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Active = true,
			Parent = Gui,
		}, {
			Corner(16),
			New("UIGradient", { Rotation = 135, Color = ColorSequence.new(T.Window1, T.Window2) }),
		})

		local gateStroke = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.5,
			Transparency = 0.8,
			Parent = gate,
		})
		bind(gateStroke, "Color", "Line")

		local gateScale = New("UIScale", { Parent = gate })
		do
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
			gateScale.Scale = math.min(0.9, (vp.X - 40) / GW, (vp.Y - 40) / GH)
		end

		text(gate, ks.Title or (cfg.Name or "Lumen"), 17, Enum.Font.GothamMedium, "Text",
			UDim2.fromOffset(20, 14), UDim2.new(1, -60, 0, 24))

		local note = text(gate, ks.Note or "Enter key", 12, Enum.Font.Gotham, "Sub",
			UDim2.fromOffset(20, 40), UDim2.new(1, -40, 0, 30))
		note.TextWrapped = true
		note.TextYAlignment = Enum.TextYAlignment.Top

		local closeBtn = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 10),
			Size = UDim2.fromOffset(26, 26),
			BackgroundTransparency = 1,
			Text = "×",
			Font = Enum.Font.GothamMedium,
			TextSize = 16,
			Parent = gate,
		})
		bind(closeBtn, "TextColor3", "Sub")

		local canPaste = type(getclipboard) == "function"

		local box = New("TextBox", {
			Position = UDim2.fromOffset(20, 80),
			Size = UDim2.fromOffset(canPaste and 208 or 300, 34),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			PlaceholderText = "Enter key",
			Text = "",
			ClearTextOnFocus = false,
			Parent = gate,
		}, { Corner(8), Pad(10, 0, 10, 0) })
		bind(box, "BackgroundColor3", "Panel")
		bind(box, "TextColor3", "Text")
		bind(box, "PlaceholderColor3", "Sub")

		local status = text(gate, "", 11, Enum.Font.GothamMedium, C.Red,
			UDim2.fromOffset(20, 120), UDim2.new(1, -40, 0, 16))

		local function gateButton(label, x, y, w, h, accent)
			local b = New("TextButton", {
				Position = UDim2.fromOffset(x, y),
				Size = UDim2.fromOffset(w, h),
				BackgroundTransparency = accent and 0 or 0.3,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				Text = label,
				AutoButtonColor = false,
				TextColor3 = C.White,
				Parent = gate,
			}, { Corner(10) })
			bind(b, "BackgroundColor3", accent and "Accent" or "Off")
			return b
		end

		if canPaste then
			gateButton("Paste", 236, 80, 84, 34, false).MouseButton1Click:Connect(function()
				local ok, clip = pcall(getclipboard)
				if ok and clip then
					box.Text = trim(clip)
				end
			end)
		end

		local hasLink = ks.Link ~= nil
		local buttonWidth = hasLink and 146 or 300
		local submit = gateButton("Submit", 20, GH - 52, buttonWidth, 36, true)

		if hasLink then
			gateButton("Get key", 174, GH - 52, buttonWidth, 36, false).MouseButton1Click:Connect(function()
				if type(setclipboard) == "function" then
					pcall(setclipboard, ks.Link)
					status.TextColor3 = C.Green
					status.Text = "Copied"
				else
					status.TextColor3 = C.Gold
					status.Text = ks.Link
				end
			end)
		end

		local attempts, lockedUntil = 0, 0
		local busy = false

		local function try()
			if busy or os.clock() < lockedUntil then
				return
			end
			busy = true

			if check(box.Text) then
				if ks.SaveKey and fsOK() then
					ensureFolder()
					pcall(writefile, file, os.time() .. "\n" .. hashKey(norm(box.Text)))
				end
				status.TextColor3 = C.Green
				status.Text = "Key accepted"
				task.wait(0.35)
				done:Fire(true)
				return
			end

			attempts += 1
			status.TextColor3 = C.Red

			if ks.MaxAttempts and attempts >= ks.MaxAttempts then
				attempts = 0
				lockedUntil = os.clock() + (ks.Cooldown or 15)
				task.spawn(function()
					while os.clock() < lockedUntil and gate.Parent do
						status.Text = "Wrong key - " .. math.ceil(lockedUntil - os.clock()) .. "s"
						task.wait(0.25)
					end
					if gate.Parent then
						status.Text = ""
					end
				end)
			else
				status.Text = "Wrong key" .. (ks.MaxAttempts and (" (" .. (ks.MaxAttempts - attempts) .. ")") or "")
			end

			-- Shake
			local p = gate.Position
			for _, dx in ipairs({ 8, -8, 5, -5, 0 }) do
				Tween(gate, { Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset) }, 0.05)
				task.wait(0.05)
			end

			busy = false
		end

		submit.MouseButton1Click:Connect(try)
		box.FocusLost:Connect(function(enter)
			if enter then
				try()
			end
		end)
		closeBtn.MouseButton1Click:Connect(function()
			done:Fire(false)
		end)

		local accepted = done.Event:Wait()
		done:Destroy()

		if not accepted then
			W:Destroy()
			error("[Lumen] key window closed", 0)
		end

		gate:Destroy()
		locked = false
		safe(ks.OnSuccess, trim(box.Text))
		return true
	end

	if cfg.KeySystem then
		runKeyGate(cfg.KeySystem)
	end

	------------------------------------------------------------------
	-- Finish
	------------------------------------------------------------------
	Lumen.Windows[#Lumen.Windows + 1] = W

	if cfg.Watermark then
		W:CreateWatermark(type(cfg.Watermark) == "string" and cfg.Watermark or nil)
	end

	task.defer(function()
		W:SetVisible(true)
	end)

	return W
end

return Lumen
