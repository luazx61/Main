-- Lumen v2.1 | Glass + Blue | Fixed
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local MarketplaceService = game:GetService("MarketplaceService")

local Lumen = {
	Version = "2.1.0",
	Flags = {},
	Options = {},
	Windows = {},
}

local rgb = Color3.fromRGB
local C = {
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	Green = rgb(72, 182, 128),
	Gold = rgb(214, 174, 72),
	Red = rgb(204, 78, 86),
}
local BLUE = rgb(76, 130, 230)

local T = {
	Window1 = rgb(96, 116, 166),
	Window2 = rgb(30, 38, 68),
	WinT = 0.4,
	Panel = rgb(16, 22, 44),
	PanT = 0.5,
	Card = rgb(12, 18, 38),
	CardT = 0.32,
	Text = rgb(252, 253, 255),
	Sub = rgb(200, 208, 228),
	Off = rgb(84, 98, 140),
	Line = C.White,
	LineT = 0.8,
	Accent = BLUE,
}

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
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Tween(i, props, t, style, dir)
	local tw = TweenService:Create(i, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Corner(r)
	return New("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function Pad(l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
	})
end

local function List(pad, hor)
	return New("UIListLayout", {
		Padding = UDim.new(0, pad or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = hor and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
	})
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
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

local function fsOK()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function ensureFolder()
	pcall(function()
		if makefolder and isfolder and not isfolder("Lumen") then
			makefolder("Lumen")
		end
	end)
end

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

local function cfgPath(name)
	return "Lumen/" .. (tostring(name):gsub("[^%w_%- ]", "_")) .. ".json"
end

-- Icon registry: name -> rbxassetid number (fill these in, or pass ids directly).
-- Entries left at 0 fall back to a letter glyph.
Lumen.Icons = {
	home = 0,
	settings = 0,
	player = 0,
	players = 0,
	combat = 0,
	visuals = 0,
	teleport = 0,
	misc = 0,
	config = 0,
	info = 0,
}

Lumen.IconGlyphs = {
	home = "H",
	settings = "S",
	player = "P",
	players = "P",
	combat = "C",
	visuals = "V",
	teleport = "T",
	misc = "M",
	config = "C",
	info = "i",
}

function Lumen:SetIcons(map)
	for k, v in pairs(map or {}) do
		Lumen.Icons[tostring(k):lower()] = v
	end
end

-- Sound registry: name -> sound id (number, rbxassetid:// or rbxasset:// path).
-- Defaults use Roblox built-in files; override them if one is silent on your executor.
Lumen.Sounds = {
	click = "rbxasset://sounds/switch.wav",
	toggle = "rbxasset://sounds/switch.wav",
	notify = "rbxasset://sounds/electronicpingshort.wav",
	error = "rbxasset://sounds/electronicpingshort.wav",
}

function Lumen:SetSounds(map)
	for k, v in pairs(map or {}) do
		Lumen.Sounds[tostring(k):lower()] = v
	end
end

function Lumen:SaveConfig(name)
	if not fsOK() then
		return false
	end
	local d = {}
	for k, v in pairs(Lumen.Flags) do
		d[k] = enc(v)
	end
	ensureFolder()
	return (pcall(writefile, cfgPath(name), HttpService:JSONEncode(d)))
end

function Lumen:LoadConfig(name)
	if not fsOK() then
		return false
	end
	local path = cfgPath(name)
	if not isfile(path) then
		return false
	end
	local ok, d = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok then
		return false
	end
	for k, v in pairs(d) do
		local o = Lumen.Options[k]
		if o and o.Set then
			pcall(o.Set, o, dec(v))
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
		for _, p in ipairs(files) do
			local n = p:match("([^/\\]+)%.json$")
			if n and not n:find("^window_") and not n:find("^profile_") and n ~= "autoload" then
				out[#out + 1] = n
			end
		end
	end
	table.sort(out)
	return out
end

local function writeFlags(path)
	if not fsOK() then
		return false
	end
	local d = {}
	for k, v in pairs(Lumen.Flags) do
		d[k] = enc(v)
	end
	ensureFolder()
	return (pcall(writefile, path, HttpService:JSONEncode(d)))
end

local function applyFlags(path)
	if not fsOK() or not isfile(path) then
		return false
	end
	local ok, d = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(d) ~= "table" then
		return false
	end
	for k, v in pairs(d) do
		local o = Lumen.Options[k]
		if o and o.Set then
			pcall(o.Set, o, dec(v))
		end
	end
	return true
end

local function profilePath(name)
	return cfgPath("profile_" .. tostring(game.PlaceId) .. "_" .. tostring(name))
end

local AUTOLOAD_FILE = "Lumen/autoload.json"

function Lumen:SaveProfile(name)
	return writeFlags(profilePath(name))
end

function Lumen:LoadProfile(name)
	return applyFlags(profilePath(name))
end

function Lumen:DeleteProfile(name)
	if type(delfile) ~= "function" then
		return false
	end
	return (pcall(delfile, profilePath(name)))
end

function Lumen:ListProfiles()
	local out = {}
	if type(listfiles) ~= "function" then
		return out
	end
	local prefix = "profile_" .. tostring(game.PlaceId) .. "_"
	local ok, files = pcall(listfiles, "Lumen")
	if ok and type(files) == "table" then
		for _, p in ipairs(files) do
			local n = p:match("([^/\\]+)%.json$")
			if n and n:sub(1, #prefix) == prefix then
				out[#out + 1] = n:sub(#prefix + 1)
			end
		end
	end
	table.sort(out)
	return out
end

local function readAuto()
	if not fsOK() or not isfile(AUTOLOAD_FILE) then
		return {}
	end
	local ok, d = pcall(function()
		return HttpService:JSONDecode(readfile(AUTOLOAD_FILE))
	end)
	if ok and type(d) == "table" then
		return d
	end
	return {}
end

function Lumen:GetAutoLoad()
	return readAuto()[tostring(game.PlaceId)]
end

function Lumen:SetAutoLoad(name)
	if not fsOK() then
		return false
	end
	local d = readAuto()
	d[tostring(game.PlaceId)] = name
	ensureFolder()
	return (pcall(writefile, AUTOLOAD_FILE, HttpService:JSONEncode(d)))
end

function Lumen:LoadAutoProfile()
	local name = Lumen:GetAutoLoad()
	if name and Lumen:LoadProfile(name) then
		return name
	end
	return nil
end

function Lumen:Notify(n)
	local w = Lumen.Windows[#Lumen.Windows]
	if w then
		w:Notify(n)
	end
end

function Lumen:CreateWindow(cfg)
	cfg = cfg or {}
	local W = { Tabs = {} }
	local lp = Players.LocalPlayer

	local conns, binds, themeFns, ticks = {}, {}, {}, {}
	local Gui
	local paletteItems = {}

	local function conn(c)
		conns[#conns + 1] = c
		return c
	end

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
			if b[1] and b[1]:IsDescendantOf(Gui) then
				Tween(b[1], { [b[2]] = T[b[3]] }, 0.3)
			else
				table.remove(binds, i)
			end
		end
		for _, fn in ipairs(themeFns) do
			pcall(fn)
		end
		local at = W.ActiveTab
		if at then
			Tween(at.Label, { TextColor3 = T.Text }, 0.3)
			if at.Icon then
				Tween(at.Icon, { [at.Icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"] = T.Text }, 0.3)
			end
		end
	end

	local function regPalette(name, fn, kind)
		if name and fn then
			paletteItems[#paletteItems + 1] = { Name = tostring(name), Fn = fn, Kind = kind or "Action" }
		end
	end

	-- saved window state
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
		Name = "Lumen_" .. HttpService:GenerateGUID(false):sub(1, 6) .. tostring(math.random(1000, 9999)),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
		IgnoreGuiInset = true,
		Parent = parent,
	})
	Gui:SetAttribute("LumenId", cfg.Name or "Lumen")
	W.Gui = Gui

	local saveWin
	local soundOn = cfg.Sounds ~= false
	local soundVol = cfg.SoundVolume or 0.5
	if winState and winState.sound ~= nil then
		soundOn = winState.sound
	end
	if winState and winState.volume then
		soundVol = math.clamp(winState.volume, 0, 1)
	end
	local soundCache = {}

	local function playSound(name)
		if not soundOn then
			return
		end
		local id = Lumen.Sounds[name]
		if not id then
			return
		end
		pcall(function()
			local snd = soundCache[name]
			if not snd or snd.Parent == nil then
				snd = Instance.new("Sound")
				snd.SoundId = type(id) == "number" and ("rbxassetid://" .. id) or tostring(id)
				snd.Parent = Gui
				soundCache[name] = snd
			end
			snd.Volume = soundVol
			snd.TimePosition = 0
			snd:Play()
		end)
	end

	function W:PlaySound(name)
		playSound(name or "click")
	end
	function W:SetSoundEnabled(v)
		soundOn = v and true or false
		saveWin()
	end
	function W:SetSoundVolume(v)
		soundVol = math.clamp(v, 0, 1)
		saveWin()
	end

	local function text(par, t, size, font, color, pos, sz, align)
		local l = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = pos or UDim2.fromOffset(12, 0),
			Size = sz or UDim2.new(1, -24, 1, 0),
			Font = font or Enum.Font.GothamMedium,
			TextSize = math.max((size or 13) - 1, 9),
			TextXAlignment = align or Enum.TextXAlignment.Left,
			Text = t,
			Parent = par,
		})
		if typeof(color) == "Color3" then
			l.TextColor3 = color
		else
			bind(l, "TextColor3", color or "Text")
		end
		return l
	end

	local function hit(par, h)
		return New("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = h and UDim2.new(1, 0, 0, h) or UDim2.fromScale(1, 1),
			Parent = par,
		})
	end

	local function makeIcon(par, ic, w, h, pos, colorKey)
		colorKey = colorKey or "Sub"
		local glyph
		if type(ic) == "string" then
			local key = ic:lower()
			if Lumen.Icons[key] ~= nil then
				local id = Lumen.Icons[key]
				glyph = Lumen.IconGlyphs[key] or string.sub(ic, 1, 1):upper()
				ic = (type(id) == "number" and id > 0) and id or (type(id) == "string" and id ~= "" and id) or nil
			end
		end
		if type(ic) == "string" and tonumber(ic) and not ic:find("^rbx") then
			ic = tonumber(ic)
		end
		local isImg = type(ic) == "number" or (type(ic) == "string" and (ic:find("^rbxasset") ~= nil or ic:find("^rbxthumb") ~= nil))
		if isImg then
			local img = New("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.new(pos.X.Scale, pos.X.Offset + (w - 18) / 2, pos.Y.Scale, pos.Y.Offset + (h - 18) / 2),
				Image = type(ic) == "number" and ("rbxassetid://" .. ic) or ic,
				ScaleType = Enum.ScaleType.Fit,
				Parent = par,
			})
			bind(img, "ImageColor3", colorKey)
			return img
		end
		local lbl = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = pos,
			Size = UDim2.fromOffset(w, h),
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			Text = tostring(glyph or ic or "-"),
			Parent = par,
		})
		bind(lbl, "TextColor3", colorKey)
		return lbl
	end

	local function loadAvatar(img)
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok then
				img.Image = url
			end
		end)
	end

	local function onTick(fn)
		ticks[#ticks + 1] = fn
		pcall(fn)
	end

	-- live stats
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

	local WIDTH = cfg.Size and cfg.Size.X or 660
	local HEIGHT = cfg.Size and cfg.Size.Y or 400
	local TOP = 58
	local hidden, minimized, userScale = true, false, 1
	if winState and winState.scale then
		userScale = math.clamp(winState.scale, 0.5, 1.5)
	end

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

	local Main = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = startPos,
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Active = true,
		Parent = Gui,
	}, { Corner(24) })
	bind(Main, "BackgroundTransparency", "WinT")

	New("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(T.Window1, T.Window2),
		Parent = Main,
	})

	local mainStroke = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1.5,
		Parent = Main,
	})
	bind(mainStroke, "Color", "Line")
	mainStroke.Transparency = 0.7

	local Scale = New("UIScale", { Parent = Main })

	local function fit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local touch = UIS.TouchEnabled
		local mx, my = touch and 120 or 60, touch and 100 or 70
		return math.min(userScale * (cfg.Scale or 0.8), (vp.X - mx) / WIDTH, (vp.Y - my) / HEIGHT)
	end

	Scale.Scale = fit() * 0.9
	if workspace.CurrentCamera then
		conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if not hidden then
				Scale.Scale = fit()
			end
		end))
	end

	function saveWin()
		if not fsOK() then
			return
		end
		ensureFolder()
		local d = {
			px = Main.Position.X.Scale,
			po = Main.Position.X.Offset,
			py = Main.Position.Y.Scale,
			yo = Main.Position.Y.Offset,
			scale = userScale,
			tab = W.ActiveTab and W.ActiveTab.Name or nil,
			npos = W.NotifyPos,
			nstyle = W.NotifyStyle,
			sound = soundOn,
			volume = soundVol,
		}
		pcall(writefile, winFile, HttpService:JSONEncode(d))
	end

	-- top bar
	local Topbar = New("Frame", {
		Size = UDim2.new(1, 0, 0, TOP),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local titleX = 20
	if cfg.Icon then
		makeIcon(Topbar, cfg.Icon, 28, 28, UDim2.fromOffset(16, 14), "Text")
		titleX = 52
	end

	text(Topbar, cfg.Name or "Lumen", 20, Enum.Font.GothamBold, "Text", UDim2.fromOffset(titleX, cfg.Subtitle and 10 or 17), UDim2.new(0.6, 0, 0, 24))
	text(Topbar, string.upper(cfg.Subtitle or ""), 10, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(titleX, 33), UDim2.new(0.6, 0, 0, 14))

	local line = New("Frame", {
		Position = UDim2.new(0, 16, 1, -1),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Parent = Topbar,
	})
	bind(line, "BackgroundColor3", "Line")

	local function circleBtn(label, xOff)
		local b = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOff, 0.5, 0),
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
		b.MouseEnter:Connect(function()
			Tween(b, { BackgroundTransparency = 0.7 }, 0.15)
		end)
		b.MouseLeave:Connect(function()
			Tween(b, { BackgroundTransparency = 0.88 }, 0.15)
		end)
		return b
	end

	local HideBtn = circleBtn("x", -14)
	local MinBtn = circleBtn("-", -50)

	-- dragging (any edge, the top bar and the status bar)
	local locked = false
	function W:SetLocked(v)
		locked = v and true or false
	end

	do
		local EDGE = 14
		local dragging, sm, sp = false, nil, nil
		local StatusRef

		local function inside(gui, pos)
			if not gui or not gui.Parent then
				return false
			end
			local p, sz = gui.AbsolutePosition, gui.AbsoluteSize
			return pos.X >= p.X and pos.X <= p.X + sz.X and pos.Y >= p.Y and pos.Y <= p.Y + sz.Y
		end

		local function grabbable(pos)
			local p, sz = Main.AbsolutePosition, Main.AbsoluteSize
			local e = EDGE * Scale.Scale
			if pos.X - p.X < e or p.X + sz.X - pos.X < e or pos.Y - p.Y < e or p.Y + sz.Y - pos.Y < e then
				return true
			end
			if inside(Topbar, pos) then
				return pos.X < MinBtn.AbsolutePosition.X - 4
			end
			return inside(W.StatusBar, pos)
		end

		conn(Main.InputBegan:Connect(function(i)
			if locked or not isPress(i) then
				return
			end
			if grabbable(i.Position) then
				dragging, sm, sp = true, i.Position, Main.Position
			end
		end))

		conn(UIS.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = i.Position - sm
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				Main.Position = UDim2.new(
					sp.X.Scale,
					math.clamp(sp.X.Offset + d.X, -vp.X * sp.X.Scale + 60, vp.X * (1 - sp.X.Scale) - 60),
					sp.Y.Scale,
					math.clamp(sp.Y.Offset + d.Y, -vp.Y * sp.Y.Scale + 40, vp.Y * (1 - sp.Y.Scale) - 40)
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

	-- body
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

	if showChip then
		local chip = New("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundTransparency = 1,
			Parent = SideWrap,
		})
		local cl = New("Frame", {
			Size = UDim2.new(1, -16, 0, 1),
			Position = UDim2.fromOffset(8, 0),
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			Parent = chip,
		})
		bind(cl, "BackgroundColor3", "Line")

		local av = New("ImageLabel", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(32, 32),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = chip,
		}, { Corner(16) })
		bind(av, "BackgroundColor3", "Panel")
		loadAvatar(av)

		text(chip, lp.DisplayName, 12, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(50, 9), UDim2.new(1, -56, 0, 16)).TextTruncate = Enum.TextTruncate.AtEnd
		text(chip, "v" .. Lumen.Version, 10, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(50, 26), UDim2.new(1, -56, 0, 14))
	end

	local Pages = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(172, 0),
		Size = UDim2.new(1, -186, 1, -14 - FOOT),
		Parent = Body,
	})

	local gameName = game.Name
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if ok and info and info.Name then
			gameName = info.Name
		end
	end)

	-- status bar
	if FOOT > 0 then
		local sb = New("Frame", {
			Position = UDim2.new(0, 14, 1, -38),
			Size = UDim2.new(1, -28, 0, 26),
			BorderSizePixel = 0,
			Parent = Body,
		}, { Corner(13) })
		bind(sb, "BackgroundColor3", "Card")
		W.StatusBar = sb
		bind(sb, "BackgroundTransparency", "PanT")

		local sbs = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.2,
			Parent = sb,
		})
		bind(sbs, "Color", "Line")
		bind(sbs, "Transparency", "LineT")

		local lbl = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -28, 1, 0),
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			RichText = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "",
			Parent = sb,
		})
		bind(lbl, "TextColor3", "Sub")

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
			lbl.Text = table.concat({
				string.format('<font color="%s">%d</font> FPS', tint(fps >= 50, fps >= 30), fps),
				ping > 0 and string.format('<font color="%s">%d</font> ms', tint(ping < 100, ping < 200), ping) or "- ms",
				string.format("%d/%d players", #Players:GetPlayers(), Players.MaxPlayers),
				"Account age " .. ageText(),
				gameName,
			}, "  |  ")
		end)
	end

	-- notifications
	local function has(list, v)
		for _, x in ipairs(list) do
			if x == v then
				return true
			end
		end
		return false
	end

	local NOTIFY_POS = {
		BottomRight = { Anchor = Vector2.new(1, 1), Pos = UDim2.new(1, -16, 1, -16), V = Enum.VerticalAlignment.Bottom, Side = 1 },
		BottomLeft = { Anchor = Vector2.new(0, 1), Pos = UDim2.new(0, 16, 1, -16), V = Enum.VerticalAlignment.Bottom, Side = -1 },
		TopRight = { Anchor = Vector2.new(1, 0), Pos = UDim2.new(1, -16, 0, 60), V = Enum.VerticalAlignment.Top, Side = 1 },
		TopLeft = { Anchor = Vector2.new(0, 0), Pos = UDim2.new(0, 16, 0, 60), V = Enum.VerticalAlignment.Top, Side = -1 },
		TopCenter = { Anchor = Vector2.new(0.5, 0), Pos = UDim2.new(0.5, 0, 0, 60), V = Enum.VerticalAlignment.Top, Side = 0 },
	}

	local NotifHolder = New("Frame", {
		Size = UDim2.fromOffset(290, 500),
		BackgroundTransparency = 1,
		Parent = Gui,
	})
	local NotifLayout = New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = NotifHolder,
	})

	W.NotifyPositions = { "BottomRight", "BottomLeft", "TopRight", "TopLeft", "TopCenter" }
	W.NotifyStyles = { "Default", "Compact", "Banner" }
	W.NotifHistory = {}
	W.NotifyPos = cfg.NotifyPosition or (winState and winState.npos) or "BottomRight"
	W.NotifyStyle = cfg.NotifyStyle or (winState and winState.nstyle) or "Default"
	if not NOTIFY_POS[W.NotifyPos] then
		W.NotifyPos = "BottomRight"
	end
	if not has(W.NotifyStyles, W.NotifyStyle) then
		W.NotifyStyle = "Default"
	end

	function W:SetNotifyPosition(name, silent)
		local p = NOTIFY_POS[name]
		if not p then
			return
		end
		W.NotifyPos = name
		NotifHolder.AnchorPoint = p.Anchor
		NotifHolder.Position = p.Pos
		NotifLayout.VerticalAlignment = p.V
		if not silent then
			saveWin()
		end
	end

	function W:SetNotifyStyle(name, silent)
		if not has(W.NotifyStyles, name) then
			return
		end
		W.NotifyStyle = name
		if not silent then
			saveWin()
		end
	end

	W:SetNotifyPosition(W.NotifyPos, true)

	local TYPE_COLORS = { Success = C.Green, Warning = C.Gold, Error = C.Red }

	function W:Notify(n)
		if type(n) ~= "table" then
			n = { Content = tostring(n) }
		end
		local content = n.Content or ""
		local title = n.Title or "Notice"
		local style = has(W.NotifyStyles, n.Style) and n.Style or W.NotifyStyle
		local compact, banner = style == "Compact", style == "Banner"
		playSound(n.Type == "Error" and "error" or "notify")
		local tc = TYPE_COLORS[n.Type]
		local col = tc or T.Accent
		local side = NOTIFY_POS[W.NotifyPos].Side
		local out = side == 1 and UDim2.new(1, 320, 0, 0) or (side == -1 and UDim2.new(-1, -320, 0, 0) or UDim2.new(0, 0, 0, -80))

		table.insert(W.NotifHistory, 1, { Title = title, Content = content, Type = n.Type, Time = os.time() })
		if #W.NotifHistory > 30 then
			table.remove(W.NotifHistory)
		end

		local live = {}
		for _, ch in ipairs(NotifHolder:GetChildren()) do
			if ch:IsA("Frame") then
				live[#live + 1] = ch
			end
		end
		if #live >= 5 then
			live[1]:Destroy()
		end

		local bodyH = 0
		if not compact and content ~= "" then
			local ok, size = pcall(function()
				return TextService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(256, 1000))
			end)
			bodyH = ok and size.Y or 15 * math.ceil(#content / 38)
		end
		local height = compact and 34 or (30 + bodyH + 14)

		local wrap = New("Frame", {
			Size = UDim2.new(1, 0, 0, height),
			BackgroundTransparency = 1,
			Parent = NotifHolder,
		})

		local c = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Position = out,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = wrap,
		}, { Corner(compact and 17 or 12) })

		if banner then
			c.BackgroundColor3 = col
			c.BackgroundTransparency = 0.12
		else
			bind(c, "BackgroundColor3", "Panel")
		end

		local st = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.2,
			Parent = c,
		})
		bind(st, "Color", "Line")
		bind(st, "Transparency", "LineT")

		local timer
		if compact then
			local dot = New("Frame", {
				Position = UDim2.fromOffset(12, 13),
				Size = UDim2.fromOffset(8, 8),
				BorderSizePixel = 0,
				Parent = c,
			}, { Corner(4) })
			if tc then
				dot.BackgroundColor3 = tc
			else
				bind(dot, "BackgroundColor3", "Accent")
			end
			local line = title .. (content ~= "" and ("  -  " .. content) or "")
			local l = text(c, line, 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(28, 0), UDim2.new(1, -40, 1, 0))
			l.TextTruncate = Enum.TextTruncate.AtEnd
		else
			if not banner then
				local bar = New("Frame", {
					Position = UDim2.fromOffset(8, 10),
					Size = UDim2.new(0, 3, 1, -20),
					BorderSizePixel = 0,
					Parent = c,
				}, { Corner(2) })
				if tc then
					bar.BackgroundColor3 = tc
				else
					bind(bar, "BackgroundColor3", "Accent")
				end
			end

			timer = New("Frame", {
				Position = UDim2.new(0, 0, 1, -2),
				Size = UDim2.new(1, 0, 0, 2),
				BorderSizePixel = 0,
				BackgroundTransparency = banner and 0.5 or 0.3,
				Parent = c,
			})
			if banner then
				timer.BackgroundColor3 = C.White
			elseif tc then
				timer.BackgroundColor3 = tc
			else
				bind(timer, "BackgroundColor3", "Accent")
			end

			local tx = banner and 14 or 20
			text(c, title, 14, Enum.Font.GothamMedium, banner and C.White or "Text", UDim2.fromOffset(tx, 8), UDim2.new(1, -tx - 10, 0, 18))
			if content ~= "" then
				local b = text(c, content, 12, Enum.Font.Gotham, banner and rgb(236, 241, 255) or "Sub", UDim2.fromOffset(tx, 28), UDim2.new(1, -tx - 14, 0, bodyH))
				b.TextWrapped = true
				b.TextYAlignment = Enum.TextYAlignment.Top
			end
		end

		local gone = false
		local function dismiss()
			if gone or not c.Parent then
				return
			end
			gone = true
			Tween(c, { Position = out }, 0.3)
			task.delay(0.3, function()
				wrap:Destroy()
			end)
		end

		c.MouseButton1Click:Connect(dismiss)
		local dur = n.Duration or (compact and 3 or 4)
		Tween(c, { Position = UDim2.new() }, 0.4, Enum.EasingStyle.Back)
		if timer then
			Tween(timer, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
		end
		task.delay(dur, dismiss)
	end

	-- confirm dialog (yields until answered, returns boolean)
	function W:Confirm(c)
		c = c or {}
		local ev = Instance.new("BindableEvent")
		local overlay = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Black,
			BackgroundTransparency = 0.5,
			ZIndex = 50,
			Parent = Main,
		})
		local box = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(280, 130),
			BorderSizePixel = 0,
			ZIndex = 51,
			Parent = overlay,
		}, { Corner(14) })
		bind(box, "BackgroundColor3", "Panel")
		local t1 = text(box, c.Title or "Confirm", 15, Enum.Font.GothamBold, "Text", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 22))
		t1.ZIndex = 52
		local t2 = text(box, c.Content or "Are you sure?", 12, Enum.Font.Gotham, "Sub", UDim2.fromOffset(16, 38), UDim2.new(1, -32, 0, 30))
		t2.ZIndex = 52
		t2.TextWrapped = true
		t2.TextYAlignment = Enum.TextYAlignment.Top

		local function mk(label, x, accent)
			local b = New("TextButton", {
				Position = UDim2.new(x, x == 0 and 16 or -16, 1, -16),
				AnchorPoint = Vector2.new(x, 1),
				Size = UDim2.new(0.5, -24, 0, 30),
				Text = label,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				ZIndex = 52,
				Parent = box,
			}, { Corner(8) })
			b.TextColor3 = T.Text
			b.BackgroundColor3 = accent and T.Accent or T.Off
			return b
		end
		local no = mk("Cancel", 0, false)
		local yes = mk("Confirm", 1, true)
		no.MouseButton1Click:Connect(function()
			ev:Fire(false)
		end)
		yes.MouseButton1Click:Connect(function()
			ev:Fire(true)
		end)
		local result = ev.Event:Wait()
		overlay:Destroy()
		ev:Destroy()
		return result
	end

	------------------------------------------------------------------
	-- ELEMENTS
	------------------------------------------------------------------
	local function attachElements(host, container)
		local function card(h, neon)
			local f = New("Frame", {
				Size = UDim2.new(1, 0, 0, h),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = container,
			}, { Corner(10) })
			bind(f, "BackgroundColor3", "Card")
			bind(f, "BackgroundTransparency", "CardT")

			local s = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1.5,
				Parent = f,
			})
			if neon == "accent" then
				bind(s, "Color", "Accent")
				s.Transparency = 0.4
			elseif typeof(neon) == "Color3" then
				s.Color = neon
				s.Transparency = 0.35
			else
				bind(s, "Color", "Line")
				bind(s, "Transparency", "LineT")
			end
			return f, s
		end

		local function hover(f, h)
			h.MouseEnter:Connect(function()
				Tween(f, { BackgroundTransparency = math.max(T.CardT - 0.18, 0) }, 0.15)
			end)
			h.MouseLeave:Connect(function()
				Tween(f, { BackgroundTransparency = T.CardT }, 0.15)
			end)
		end

		local function named(f, name, desc, rightPad)
			rightPad = rightPad or 24
			if desc then
				text(f, name, 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 8), UDim2.new(1, -rightPad - 12, 0, 18))
				local d = text(f, desc, 11, Enum.Font.Gotham, "Sub", UDim2.fromOffset(12, 28), UDim2.new(1, -rightPad - 12, 0, 16))
				d.TextTruncate = Enum.TextTruncate.AtEnd
				return
			end
			text(f, name, 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(1, -rightPad - 12, 1, 0))
		end

		local function base(f, o)
			o.Frame = f
			function o:Destroy()
				f:Destroy()
			end
			function o:SetVisible(v)
				f.Visible = v
			end
			return o
		end

		local function reg(flag, obj, val)
			if flag then
				Lumen.Flags[flag] = val
				Lumen.Options[flag] = obj
			end
		end

		local function drag(inputFrame, ref, onMove)
			local active = false
			local function upd(i)
				local p, s = ref.AbsolutePosition, ref.AbsoluteSize
				onMove(
					math.clamp((i.Position.X - p.X) / math.max(s.X, 1), 0, 1),
					math.clamp((i.Position.Y - p.Y) / math.max(s.Y, 1), 0, 1)
				)
			end
			local function lock(v)
				local sc = container:IsA("ScrollingFrame") and container or container:FindFirstAncestorOfClass("ScrollingFrame")
				if sc then
					sc.ScrollingEnabled = v
				end
			end
			conn(inputFrame.InputBegan:Connect(function(i)
				if isPress(i) then
					active = true
					lock(false)
					upd(i)
				end
			end))
			conn(UIS.InputChanged:Connect(function(i)
				if active and isMove(i) then
					upd(i)
				end
			end))
			conn(UIS.InputEnded:Connect(function(i)
				if active and isPress(i) then
					active = false
					lock(true)
				end
			end))
		end

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
			text(f, string.upper(title or "Section"), 11, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(22, 0), UDim2.new(1, -30, 1, 0))
			return base(f, {})
		end

		function host:CreateFolder(name, startOpen)
			local f = card(36)
			local open = startOpen == true
			text(f, tostring(name), 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(1, -44, 0, 36))
			local arrow = text(f, "v", 14, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -26, 0, 0), UDim2.fromOffset(16, 36), Enum.TextXAlignment.Center)
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

			local fh = { Frame = f }
			attachElements(fh, inner)

			function fh:Open()
				open = true
				apply(true)
			end
			function fh:Close()
				open = false
				apply(true)
			end
			function fh:Toggle()
				open = not open
				apply(true)
			end
			function fh:Destroy()
				f:Destroy()
			end

			apply(false)
			return fh
		end

		function host:CreateLabel(t)
			local f = card(32)
			local l = text(f, tostring(t), 12, Enum.Font.Gotham, "Sub")
			return base(f, {
				Set = function(_, v)
					l.Text = v
				end,
			})
		end

		function host:CreateParagraph(c)
			c = c or {}
			local f = card(0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.Size = UDim2.new(1, 0, 0, 0)
			Pad(12, 10, 12, 10).Parent = f
			List(4).Parent = f

			local t = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = c.Title or "",
				Parent = f,
			})
			bind(t, "TextColor3", "Text")

			local b = New("TextLabel", {
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
			bind(b, "TextColor3", "Sub")

			return base(f, {
				Set = function(_, n)
					t.Text = n.Title or t.Text
					b.Text = n.Content or b.Text
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
			local kx = 12
			if icon then
				text(f, icon, 15, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(10, 0), UDim2.fromOffset(24, 40), Enum.TextXAlignment.Center)
				kx = 40
			end
			text(f, key, 11, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(kx, 0), UDim2.fromOffset(86, 40)).TextTruncate = Enum.TextTruncate.AtEnd
			local v = text(f, tostring(value), 12, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(kx + 92, 0), UDim2.new(1, -(kx + 102), 1, 0))
			v.TextTruncate = Enum.TextTruncate.AtEnd
			return base(f, {
				Set = function(_, nv)
					v.Text = tostring(nv)
				end,
			})
		end

		function host:CreateButton(c)
			c = c or {}
			local f = card(c.Description and 54 or 40, c.Neon)
			named(f, c.Name or "Button", c.Description, 36)
			local ch = text(f, ">", 18, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -28, 0, 0), UDim2.new(0, 16, 1, 0), Enum.TextXAlignment.Center)
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
				local rel = 0.5
				if UIS:GetLastInputType() ~= Enum.UserInputType.Touch then
					rel = math.clamp((UIS:GetMouseLocation().X - f.AbsolutePosition.X) / math.max(f.AbsoluteSize.X, 1), 0, 1)
				end
				ring.Position = UDim2.new(rel, 0, 0.5, 0)
				ring.BackgroundColor3 = T.Accent
				ring.BackgroundTransparency = 0.6
				ring.Size = UDim2.new()
				Tween(ring, { Size = UDim2.fromOffset(600, 600), BackgroundTransparency = 1 }, 0.5)
				Tween(ch, { Position = UDim2.new(1, -22, 0, 0) }, 0.1).Completed:Connect(function()
					Tween(ch, { Position = UDim2.new(1, -28, 0, 0) }, 0.15)
				end)
				playSound("click")
				safe(c.Callback)
			end

			btn.MouseButton1Click:Connect(fire)
			regPalette(c.Name, fire, "Button")
			return base(f, { Fire = fire })
		end

		function host:CreateToggle(c)
			c = c or {}
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

			local h = hit(f)
			hover(f, h)

			local o = { CurrentValue = c.CurrentValue == true }

			local function render(instant)
				local d = instant and 0 or 0.2
				Tween(track, { BackgroundColor3 = o.CurrentValue and T.Accent or T.Off }, d)
				Tween(knob, {
					Position = o.CurrentValue and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				}, d, Enum.EasingStyle.Back)
			end

			onTheme(function()
				render(true)
			end)

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

			function o:Get()
				return o.CurrentValue
			end

			h.MouseButton1Click:Connect(function()
				playSound("toggle")
				o:Set(not o.CurrentValue)
			end)

			reg(c.Flag, o, o.CurrentValue)
			regPalette(c.Name, function()
				o:Set(not o.CurrentValue)
			end, "Toggle")
			render(true)
			if o.CurrentValue then
				safe(c.Callback, true)
			end
			return base(f, o)
		end

		function host:CreateSlider(c)
			c = c or {}
			local min = c.Range and c.Range[1] or 0
			local max = c.Range and c.Range[2] or 100
			local inc = c.Increment or 1
			local f = card(56, c.Neon)

			text(f, c.Name or "Slider", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 6), UDim2.new(0.6, 0, 0, 20))

			local val = New("TextBox", {
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
			bind(val, "TextColor3", "Sub")

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

			val.Focused:Connect(function()
				val.Text = tostring(o.CurrentValue)
			end)

			function o:Set(v, silent)
				v = math.clamp(round(v, inc), min, max)
				o.CurrentValue = v
				local a = max > min and (v - min) / (max - min) or 0
				Tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.08)
				val.Text = tostring(v) .. (c.Suffix and (" " .. c.Suffix) or "")
				if c.Flag then
					Lumen.Flags[c.Flag] = v
				end
				if not silent then
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

			function o:Get()
				return o.CurrentValue
			end

			val.FocusLost:Connect(function()
				local n = tonumber(val.Text)
				if n then
					o:Set(n)
				else
					o:Set(o.CurrentValue, true)
				end
			end)

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
			c = c or {}
			local f = card(48, c.Neon)
			text(f, c.Name or "Progress", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 5), UDim2.new(0.6, 0, 0, 20))
			local val = text(f, "", 12, Enum.Font.GothamMedium, "Sub", UDim2.new(0.4, -12, 0, 5), UDim2.new(0.6, 0, 0, 20), Enum.TextXAlignment.Right)

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
				val.Text = label or (math.floor(v * 100 + 0.5) .. "%")
			end
			o:Set(c.Value or 0, c.Label)
			return base(f, o)
		end

		function host:CreateDropdown(c)
			c = c or {}
			local multi = c.MultipleOptions == true
			local options = c.Options or {}
			local f = card(40, c.Neon)

			text(f, c.Name or "Dropdown", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 0, 40))
			local cur = text(f, "", 12, Enum.Font.GothamMedium, "Sub", UDim2.new(0.5, -34, 0, 0), UDim2.new(0.5, 0, 0, 40), Enum.TextXAlignment.Right)
			cur.TextTruncate = Enum.TextTruncate.AtEnd
			local arrow = text(f, "v", 14, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -26, 0, 0), UDim2.fromOffset(16, 40), Enum.TextXAlignment.Center)

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
			local sel, buttons, visibleCount = {}, {}, 0

			if type(c.CurrentOption) == "table" then
				for _, v in ipairs(c.CurrentOption) do
					sel[v] = true
				end
			elseif c.CurrentOption ~= nil then
				sel[c.CurrentOption] = true
			end

			local function value()
				if multi then
					local t = {}
					for _, op in ipairs(o.Options) do
						if sel[op] then
							t[#t + 1] = op
						end
					end
					return t
				end
				for _, op in ipairs(o.Options) do
					if sel[op] then
						return op
					end
				end
				return nil
			end

			local function style()
				local v = value()
				if multi then
					cur.Text = #v == 0 and "None" or ((c.MaxPick and ("(" .. #v .. "/" .. c.MaxPick .. ") ") or "") .. table.concat(v, ", "))
				else
					cur.Text = v ~= nil and tostring(v) or "None"
				end
				for op, b in pairs(buttons) do
					Tween(b, { TextColor3 = sel[op] and T.Accent or T.Text }, 0.15)
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
					b.MouseEnter:Connect(function()
						Tween(b, { BackgroundTransparency = 0.88 }, 0.1)
					end)
					b.MouseLeave:Connect(function()
						Tween(b, { BackgroundTransparency = 1 }, 0.1)
					end)
					b.MouseButton1Click:Connect(function()
						playSound("click")
						if multi then
							if not sel[op] and c.MaxPick then
								local n = 0
								for _ in pairs(sel) do
									n += 1
								end
								if n >= c.MaxPick then
									return
								end
							end
							sel[op] = (not sel[op]) or nil
						else
							sel = { [op] = true }
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
				sel = {}
				if type(v) == "table" then
					for _, x in ipairs(v) do
						sel[x] = true
					end
				elseif v ~= nil then
					sel[v] = true
				end
				commit(silent)
			end

			function o:Refresh(opts)
				o.Options = opts
				sel = {}
				search.Text = ""
				build()
				layout()
			end

			function o:Clear(silent)
				sel = {}
				commit(silent)
			end

			function o:Get()
				return value()
			end

			function o:Close()
				if o.Open then
					o.Open = false
					search.Text = ""
					layout()
				end
			end

			W._dropdowns = W._dropdowns or {}
			W._dropdowns[#W._dropdowns + 1] = o

			head.MouseButton1Click:Connect(function()
				playSound("click")
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
			c = c or {}
			local f = card(40, c.Neon)
			text(f, c.Name or "Input", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 1, 0))

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

			local o = { CurrentValue = tostring(c.CurrentValue or "") }

			bind(box, "BackgroundColor3", "Panel")
			bind(box, "TextColor3", "Text")
			bind(box, "PlaceholderColor3", "Sub")

			local s = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1,
				Transparency = 0.85,
				Parent = box,
			})
			bind(s, "Color", "Line")

			box.Focused:Connect(function()
				Tween(s, { Color = T.Accent, Transparency = 0 }, 0.15)
				if c.Password then
					box.Text = o.CurrentValue
				end
			end)

			local clr = New("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 20, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Text = "x",
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				AutoButtonColor = false,
				Visible = box.Text ~= "",
				Parent = box,
			})
			bind(clr, "TextColor3", "Sub")

			box:GetPropertyChangedSignal("Text"):Connect(function()
				clr.Visible = box.Text ~= ""
			end)

			clr.MouseButton1Click:Connect(function()
				box.Text = ""
				box:CaptureFocus()
			end)

			box.FocusLost:Connect(function()
				Tween(s, { Color = T.Line, Transparency = 0.85 }, 0.15)
				local v = box.Text
				if c.Numeric then
					local n = tonumber(v)
					if n == nil then
						box.Text = c.Password and string.rep("*", #o.CurrentValue) or o.CurrentValue
						return
					end
					v = tostring(n)
				end
				o.CurrentValue = v
				box.Text = c.Password and string.rep("*", #v) or v
				if c.Flag then
					Lumen.Flags[c.Flag] = v
				end
				safe(c.Callback, v)
				if c.RemoveTextAfterFocusLost then
					box.Text = ""
				end
			end)

			function o:Set(t, silent)
				t = tostring(t)
				o.CurrentValue = t
				box.Text = c.Password and string.rep("*", #t) or t
				if c.Flag then
					Lumen.Flags[c.Flag] = t
				end
				if not silent then
					safe(c.Callback, t)
				end
			end

			function o:Get()
				return o.CurrentValue
			end

			if c.Password then
				box.Text = string.rep("*", #o.CurrentValue)
			end

			reg(c.Flag, o, o.CurrentValue)
			return base(f, o)
		end

		function host:CreateKeybind(c)
			c = c or {}
			local f = card(40, c.Neon)
			named(f, c.Name or "Keybind", nil, 90)
			local h = hit(f)
			hover(f, h)

			local b = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(70, 24),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				TextSize = 10,
				Text = "None",
				Parent = f,
			}, { Corner(6) })
			bind(b, "BackgroundColor3", "Panel")
			bind(b, "TextColor3", "Sub")

			local o = { CurrentKeybind = nil }
			local listening = false

			local function toKey(v)
				if typeof(v) == "EnumItem" then
					return v
				end
				if type(v) == "string" and Enum.KeyCode[v] then
					return Enum.KeyCode[v]
				end
				return nil
			end

			function o:Set(v, silent)
				local k = toKey(v)
				o.CurrentKeybind = k
				b.Text = k and k.Name or "None"
				if c.Flag then
					Lumen.Flags[c.Flag] = k and k.Name or nil
				end
				if not silent then
					safe(c.OnChange, k)
				end
			end

			function o:Get()
				return o.CurrentKeybind
			end

			h.MouseButton1Click:Connect(function()
				listening = true
				b.Text = "..."
			end)

			conn(UIS.InputBegan:Connect(function(i, gpe)
				if i.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end
				if listening then
					listening = false
					if i.KeyCode == Enum.KeyCode.Escape then
						o:Set(nil)
					else
						o:Set(i.KeyCode)
					end
					return
				end
				if not gpe and o.CurrentKeybind and i.KeyCode == o.CurrentKeybind then
					safe(c.Callback, o.CurrentKeybind)
				end
			end))

			o:Set(c.CurrentKeybind, true)
			reg(c.Flag, o, o.CurrentKeybind and o.CurrentKeybind.Name or nil)
			return base(f, o)
		end

		function host:CreateImage(c)
			c = c or {}
			local h = c.Height or 120
			local f = card(h + 16 + (c.Caption and 24 or 0), c.Neon)
			local img = New("ImageLabel", {
				Position = UDim2.fromOffset(8, 8),
				Size = UDim2.new(1, -16, 0, h),
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
				ScaleType = Enum.ScaleType[c.ScaleType or "Crop"] or Enum.ScaleType.Crop,
				Parent = f,
			}, { Corner(8) })
			bind(img, "BackgroundColor3", "Panel")

			local cap
			if c.Caption then
				cap = text(f, c.Caption, 11, Enum.Font.Gotham, "Sub", UDim2.fromOffset(12, h + 12), UDim2.new(1, -24, 0, 18))
				cap.TextTruncate = Enum.TextTruncate.AtEnd
			end

			local o = {}

			function o:Set(src)
				if type(src) == "number" then
					img.Image = "rbxassetid://" .. src
				elseif type(src) == "string" and src:find("^https?://") then
					task.spawn(function()
						local getAsset = getcustomasset or getsynasset
						if type(getAsset) ~= "function" or not fsOK() then
							warn("[Lumen] Executor cannot load web images; use an asset id instead")
							return
						end
						local hsh = 5381
						for i = 1, #src do
							hsh = (hsh * 33 + string.byte(src, i)) % 4294967296
						end
						local path = "Lumen/img_" .. hsh .. ".png"
						local ok, err = pcall(function()
							if not isfile(path) then
								ensureFolder()
								writefile(path, game:HttpGet(src))
							end
							img.Image = getAsset(path)
						end)
						if not ok then
							warn("[Lumen] Image failed: " .. tostring(err))
						end
					end)
				elseif type(src) == "string" then
					img.Image = src
				end
			end

			function o:SetCaption(t)
				if cap then
					cap.Text = tostring(t)
				end
			end

			o:Set(c.Image)
			return base(f, o)
		end

		function host:CreateAvatar(c)
			c = c or {}
			local f = card(72, c.Neon)
			local av = New("ImageLabel", {
				Position = UDim2.fromOffset(10, 10),
				Size = UDim2.fromOffset(52, 52),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Parent = f,
			}, { Corner(26) })
			bind(av, "BackgroundColor3", "Panel")

			local avStroke = New("UIStroke", { Thickness = 2, Parent = av })
			bind(avStroke, "Color", "Accent")

			local nameL = text(f, "", 13, Enum.Font.GothamBold, "Text", UDim2.fromOffset(72, 10), UDim2.new(1, -84, 0, 18))
			nameL.TextTruncate = Enum.TextTruncate.AtEnd
			local userL = text(f, "", 11, Enum.Font.Gotham, "Sub", UDim2.fromOffset(72, 30), UDim2.new(1, -84, 0, 16))
			userL.TextTruncate = Enum.TextTruncate.AtEnd
			local infoL = text(f, "", 11, Enum.Font.Gotham, "Sub", UDim2.fromOffset(72, 46), UDim2.new(1, -84, 0, 16))
			infoL.TextTruncate = Enum.TextTruncate.AtEnd

			local o = {}

			function o:Set(target)
				task.spawn(function()
					local id = target
					if typeof(target) == "Instance" then
						id = target.UserId
					elseif type(target) == "string" then
						local ok, r = pcall(function()
							return Players:GetUserIdFromNameAsync(target)
						end)
						if not ok then
							nameL.Text = "Not found"
							userL.Text = tostring(target)
							infoL.Text = ""
							return
						end
						id = r
					end
					if type(id) ~= "number" then
						return
					end
					local okT, url = pcall(function()
						return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
					end)
					if okT then
						av.Image = url
					end
					local plr = Players:GetPlayerByUserId(id)
					local okN, uname = pcall(function()
						return Players:GetNameFromUserIdAsync(id)
					end)
					uname = okN and uname or (plr and plr.Name) or "unknown"
					nameL.Text = plr and plr.DisplayName or uname
					userL.Text = "@" .. uname
					if c.Info then
						infoL.Text = tostring(c.Info)
					elseif plr then
						infoL.Text = "Account age: " .. plr.AccountAge .. " days"
					else
						infoL.Text = "User ID: " .. id
					end
				end)
			end

			o:Set(c.UserId or c.Username or lp)
			return base(f, o)
		end
	end

	------------------------------------------------------------------
	-- TABS
	------------------------------------------------------------------
	function W:SelectTab(tab)
		if W.ActiveTab == tab then
			return
		end
		if W.ActiveTab then
			W.ActiveTab.Page.Visible = false
			Tween(W.ActiveTab.Button, { BackgroundTransparency = 1 }, 0.2)
			Tween(W.ActiveTab.Label, { TextColor3 = T.Sub }, 0.2)
			local oi = W.ActiveTab.Icon
			if oi then
				Tween(oi, { [oi:IsA("ImageLabel") and "ImageColor3" or "TextColor3"] = T.Sub }, 0.2)
			end
		end
		W.ActiveTab = tab
		tab.Page.Visible = true
		Tween(tab.Button, { BackgroundTransparency = 0.55 }, 0.2)
		Tween(tab.Label, { TextColor3 = T.Text }, 0.2)
		if tab.Icon then
			Tween(tab.Icon, { [tab.Icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"] = T.Text }, 0.2)
		end
		saveWin()
	end

	function W:CreateTab(name, icon)
		local btn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = T.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = #W.Tabs + 1,
			Parent = Sidebar,
		}, { Corner(10) })
		bind(btn, "BackgroundColor3", "Accent")
		btn.BackgroundTransparency = 1

		local lx = 12
		local tabIcon
		if icon then
			tabIcon = makeIcon(btn, icon, 24, 36, UDim2.fromOffset(8, 0), "Sub")
			lx = 36
		end
		local label = text(btn, tostring(name), 12, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(lx, 0), UDim2.new(1, -lx - 6, 1, 0))
		label.TextTruncate = Enum.TextTruncate.AtEnd

		local page = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = Pages,
		}, { List(8), Pad(0, 0, 6, 8) })
		bind(page, "ScrollBarImageColor3", "Accent")

		local tab = { Name = tostring(name), Button = btn, Label = label, Page = page, Icon = tabIcon }
		attachElements(tab, page)

		btn.MouseButton1Click:Connect(function()
			if W.ActiveTab ~= tab then
				playSound("click")
			end
			W:SelectTab(tab)
		end)
		btn.MouseEnter:Connect(function()
			if W.ActiveTab ~= tab then
				Tween(btn, { BackgroundTransparency = 0.85 }, 0.15)
			end
		end)
		btn.MouseLeave:Connect(function()
			if W.ActiveTab ~= tab then
				Tween(btn, { BackgroundTransparency = 1 }, 0.15)
			end
		end)

		W.Tabs[#W.Tabs + 1] = tab
		if #W.Tabs == 1 or (winState and winState.tab == tab.Name) then
			W:SelectTab(tab)
		end
		return tab
	end

	function W:CreateConfigTab(name, icon)
		local tab = W:CreateTab(name or "Config", icon or "settings")

		local function needFS()
			if not fsOK() then
				W:Notify({ Title = "No file access", Content = "Your executor does not support writefile/readfile.", Type = "Error" })
				return true
			end
			return false
		end

		-- Configs
		tab:CreateSection("Configs")
		local cname = ""
		local cin = tab:CreateInput({
			Name = "Config name",
			PlaceholderText = "my-config",
			Callback = function(v)
				cname = v
			end,
		})
		local cdd = tab:CreateDropdown({
			Name = "Saved configs",
			Options = Lumen:ListConfigs(),
			Callback = function(v)
				if v then
					cname = v
					cin:Set(v, true)
				end
			end,
		})
		local function cpick()
			local n = cname
			if n == "" then
				n = cdd:Get() or ""
			end
			return n
		end
		local function crefresh(sel)
			cdd:Refresh(Lumen:ListConfigs())
			if sel then
				cdd:Set(sel, true)
			end
		end
		tab:CreateButton({
			Name = "Save config",
			Callback = function()
				if needFS() then return end
				local n = cpick()
				if n == "" then
					return W:Notify({ Title = "Config", Content = "Enter a config name first.", Type = "Warning" })
				end
				local ok = Lumen:SaveConfig(n)
				W:Notify({ Title = ok and "Saved" or "Failed", Content = n, Type = ok and "Success" or "Error" })
				crefresh(n)
			end,
		})
		tab:CreateButton({
			Name = "Load config",
			Callback = function()
				if needFS() then return end
				local n = cpick()
				if n == "" then
					return W:Notify({ Title = "Config", Content = "Pick or type a config.", Type = "Warning" })
				end
				local ok = Lumen:LoadConfig(n)
				W:Notify({ Title = ok and "Loaded" or "Not found", Content = n, Type = ok and "Success" or "Error" })
			end,
		})
		tab:CreateButton({
			Name = "Delete config",
			Confirm = true,
			Callback = function()
				if needFS() then return end
				local n = cpick()
				if n == "" then
					return W:Notify({ Title = "Config", Content = "Pick a config to delete.", Type = "Warning" })
				end
				local ok = Lumen:DeleteConfig(n)
				W:Notify({ Title = ok and "Deleted" or "Failed", Content = n, Type = ok and "Success" or "Error" })
				cname = ""
				cin:Set("", true)
				crefresh()
			end,
		})

		-- Profiles (per game)
		tab:CreateSection("Profiles (this game)")
		tab:CreateInfoRow("#", "Place ID", tostring(game.PlaceId))
		local autoRow = tab:CreateInfoRow("*", "Auto-load", Lumen:GetAutoLoad() or "None")
		local pname = "default"
		local pin = tab:CreateInput({
			Name = "Profile name",
			CurrentValue = "default",
			Callback = function(v)
				pname = v
			end,
		})
		local pdd = tab:CreateDropdown({
			Name = "Profiles",
			Options = Lumen:ListProfiles(),
			Callback = function(v)
				if v then
					pname = v
					pin:Set(v, true)
				end
			end,
		})
		local function ppick()
			local n = pname
			if n == "" then
				n = pdd:Get() or ""
			end
			return n
		end
		local function prefresh(sel)
			pdd:Refresh(Lumen:ListProfiles())
			if sel then
				pdd:Set(sel, true)
			end
		end
		tab:CreateButton({
			Name = "Save profile",
			Callback = function()
				if needFS() then return end
				local n = ppick()
				if n == "" then
					return W:Notify({ Title = "Profile", Content = "Enter a profile name.", Type = "Warning" })
				end
				local ok = Lumen:SaveProfile(n)
				W:Notify({ Title = ok and "Profile saved" or "Failed", Content = n, Type = ok and "Success" or "Error" })
				prefresh(n)
			end,
		})
		tab:CreateButton({
			Name = "Load profile",
			Callback = function()
				if needFS() then return end
				local n = ppick()
				local ok = n ~= "" and Lumen:LoadProfile(n)
				W:Notify({ Title = ok and "Profile loaded" or "Not found", Content = n, Type = ok and "Success" or "Error" })
			end,
		})
		tab:CreateButton({
			Name = "Delete profile",
			Confirm = true,
			Callback = function()
				if needFS() then return end
				local n = ppick()
				if n == "" then return end
				local ok = Lumen:DeleteProfile(n)
				if Lumen:GetAutoLoad() == n then
					Lumen:SetAutoLoad(nil)
					autoRow:Set("None")
				end
				W:Notify({ Title = ok and "Profile deleted" or "Failed", Content = n, Type = ok and "Success" or "Error" })
				pname = ""
				pin:Set("", true)
				prefresh()
			end,
		})
		tab:CreateButton({
			Name = "Set as auto-load",
			Description = "Loads this profile when the UI starts in this game",
			Callback = function()
				if needFS() then return end
				local n = ppick()
				if n == "" then
					return W:Notify({ Title = "Profile", Content = "Pick a profile first.", Type = "Warning" })
				end
				if not table.find(Lumen:ListProfiles(), n) then
					Lumen:SaveProfile(n)
					prefresh(n)
				end
				Lumen:SetAutoLoad(n)
				autoRow:Set(n)
				W:Notify({ Title = "Auto-load set", Content = n, Type = "Success" })
			end,
		})
		tab:CreateButton({
			Name = "Clear auto-load",
			Callback = function()
				if needFS() then return end
				Lumen:SetAutoLoad(nil)
				autoRow:Set("None")
				W:Notify({ Title = "Auto-load cleared", Type = "Success" })
			end,
		})

		-- Notifications
		tab:CreateSection("Notifications")
		tab:CreateDropdown({
			Name = "Position",
			Options = W.NotifyPositions,
			CurrentOption = W.NotifyPos,
			Callback = function(v)
				if v then
					W:SetNotifyPosition(v)
				end
			end,
		})
		tab:CreateDropdown({
			Name = "Style",
			Options = W.NotifyStyles,
			CurrentOption = W.NotifyStyle,
			Callback = function(v)
				if v then
					W:SetNotifyStyle(v)
				end
			end,
		})
		tab:CreateButton({
			Name = "Test notification",
			Callback = function()
				W:Notify({ Title = "Test", Content = W.NotifyStyle .. " | " .. W.NotifyPos, Type = "Success" })
			end,
		})
		tab:CreateButton({
			Name = "Test all types",
			Callback = function()
				W:Notify({ Title = "Success", Content = "Everything worked.", Type = "Success" })
				task.delay(0.25, function()
					W:Notify({ Title = "Warning", Content = "Something looks off.", Type = "Warning" })
				end)
				task.delay(0.5, function()
					W:Notify({ Title = "Error", Content = "Something failed.", Type = "Error" })
				end)
				task.delay(0.75, function()
					W:Notify({ Title = "Info", Content = "Plain notice." })
				end)
			end,
		})

		-- Interface
		tab:CreateSection("Interface")
		tab:CreateToggle({
			Name = "UI sounds",
			CurrentValue = soundOn,
			Callback = function(v)
				W:SetSoundEnabled(v)
			end,
		})
		tab:CreateSlider({
			Name = "Sound volume",
			Range = { 0, 100 },
			Increment = 5,
			Suffix = "%",
			CurrentValue = math.floor(soundVol * 100 + 0.5),
			Callback = function(v)
				W:SetSoundVolume(v / 100)
			end,
		})
		tab:CreateToggle({
			Name = "Lock window position",
			Description = "Stops accidental dragging",
			CurrentValue = false,
			Callback = function(v)
				W:SetLocked(v)
			end,
		})
		tab:CreateSlider({
			Name = "UI scale",
			Range = { 50, 150 },
			Increment = 5,
			Suffix = "%",
			CurrentValue = math.floor(userScale * 100 + 0.5),
			Callback = function(v)
				userScale = v / 100
				if not hidden then
					Tween(Scale, { Scale = fit() }, 0.15)
				end
				saveWin()
			end,
		})
		local ACCENTS = {
			Blue = BLUE,
			Purple = rgb(150, 100, 235),
			Pink = rgb(230, 100, 170),
			Cyan = rgb(60, 190, 220),
			Green = C.Green,
			Gold = C.Gold,
			Red = C.Red,
		}
		tab:CreateDropdown({
			Name = "Accent color",
			Options = { "Blue", "Purple", "Pink", "Cyan", "Green", "Gold", "Red" },
			CurrentOption = "Blue",
			Callback = function(v)
				if v and ACCENTS[v] then
					W:SetAccent(ACCENTS[v])
				end
			end,
		})
		tab:CreateButton({
			Name = "Destroy UI",
			Confirm = true,
			Callback = function()
				W:Destroy()
			end,
		})

		return tab
	end

	------------------------------------------------------------------
	-- WINDOW CONTROL
	------------------------------------------------------------------
	local loadingActive = false

	function W:Show()
		if not hidden then
			return
		end
		hidden = false
		Main.Visible = true
		Scale.Scale = fit() * 0.9
		Tween(Scale, { Scale = fit() }, 0.3, Enum.EasingStyle.Back)
		if blur then
			Tween(blur, { Size = 14 }, 0.3)
		end
	end

	function W:Hide()
		if hidden then
			return
		end
		hidden = true
		Tween(Scale, { Scale = fit() * 0.9 }, 0.2)
		if blur then
			Tween(blur, { Size = 0 }, 0.2)
		end
		task.delay(0.2, function()
			if hidden then
				Main.Visible = false
			end
		end)
	end

	function W:Toggle()
		if loadingActive then
			return
		end
		if hidden then
			W:Show()
		else
			W:Hide()
		end
	end

	function W:SetAccent(col)
		T.Accent = col
		refresh()
	end

	function W:Destroy()
		for _, c in ipairs(conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		if blur then
			blur:Destroy()
		end
		for i, w in ipairs(Lumen.Windows) do
			if w == W then
				table.remove(Lumen.Windows, i)
				break
			end
		end
		Gui:Destroy()
	end

	HideBtn.MouseButton1Click:Connect(function()
		W:Hide()
		W:Notify({ Title = "Hidden", Content = "Press " .. toggleKey.Name .. " or the floating button to reopen.", Duration = 3 })
	end)

	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		Body.Visible = not minimized
		Tween(Main, { Size = UDim2.fromOffset(WIDTH, minimized and TOP or HEIGHT) }, 0.25)
	end)

	conn(UIS.InputBegan:Connect(function(i, gpe)
		if not gpe and i.KeyCode == toggleKey then
			W:Toggle()
		end
	end))

	-- floating reopen button (useful on mobile)
	do
		local fb = New("TextButton", {
			Position = UDim2.new(0, 12, 0.5, -20),
			Size = UDim2.fromOffset(40, 40),
			Text = cfg.Icon and "" or string.sub(cfg.Name or "L", 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			AutoButtonColor = false,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Parent = Gui,
		}, { Corner(20) })
		bind(fb, "BackgroundColor3", "Panel")
		bind(fb, "TextColor3", "Accent")
		fb.MouseButton1Click:Connect(function()
			W:Toggle()
		end)
	end

	Lumen.Windows[#Lumen.Windows + 1] = W

	local function runSplash()
		loadingActive = true
		local total = math.max(cfg.LoadTime or 1.8, 0.6)

		local back = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Black,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 100,
			Parent = Gui,
		})

		local card = New("CanvasGroup", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 24),
			Size = UDim2.fromOffset(300, 196),
			BorderSizePixel = 0,
			BackgroundTransparency = 0.1,
			GroupTransparency = 1,
			ZIndex = 101,
			Parent = Gui,
		}, { Corner(22) })
		bind(card, "BackgroundColor3", "Panel")

		local cs = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.5,
			Parent = card,
		})
		bind(cs, "Color", "Line")
		bind(cs, "Transparency", "LineT")

		local av = New("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 18),
			Size = UDim2.fromOffset(64, 64),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = card,
		}, { Corner(32) })
		bind(av, "BackgroundColor3", "Card")
		loadAvatar(av)
		local avs = New("UIStroke", { Thickness = 2, Parent = av })
		bind(avs, "Color", "Accent")

		text(card, cfg.Name or "Lumen", 17, Enum.Font.GothamBold, "Text", UDim2.fromOffset(0, 90), UDim2.new(1, 0, 0, 22), Enum.TextXAlignment.Center)
		text(card, "Welcome, " .. lp.DisplayName, 12, Enum.Font.Gotham, "Sub", UDim2.fromOffset(0, 113), UDim2.new(1, 0, 0, 16), Enum.TextXAlignment.Center)

		local track = New("Frame", {
			Position = UDim2.new(0, 24, 0, 150),
			Size = UDim2.new(1, -48, 0, 6),
			BorderSizePixel = 0,
			Parent = card,
		}, { Corner(3) })
		bind(track, "BackgroundColor3", "Off")
		local fill = New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BorderSizePixel = 0,
			Parent = track,
		}, { Corner(3) })
		bind(fill, "BackgroundColor3", "Accent")

		local status = text(card, "Starting", 11, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(0, 164), UDim2.new(1, 0, 0, 16), Enum.TextXAlignment.Center)

		Tween(back, { BackgroundTransparency = 0.55 }, 0.3)
		Tween(card, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.4, Enum.EasingStyle.Back)

		local steps = {
			{ "Loading modules", 0.35 },
			{ "Applying profile", 0.7 },
			{ "Finishing up", 0.95 },
			{ "Ready", 1 },
		}
		local profileName
		for _, st in ipairs(steps) do
			if not Gui.Parent then
				return
			end
			status.Text = st[1]
			Tween(fill, { Size = UDim2.fromScale(st[2], 1) }, total * 0.2)
			if st[1] == "Applying profile" and cfg.AutoLoadProfile ~= false then
				profileName = Lumen:LoadAutoProfile()
				if profileName then
					status.Text = "Profile: " .. profileName
				end
			end
			task.wait(total * 0.25)
		end

		if not Gui.Parent then
			return
		end
		Tween(back, { BackgroundTransparency = 1 }, 0.3)
		Tween(card, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -16) }, 0.3)
		task.wait(0.3)
		back:Destroy()
		card:Destroy()
		loadingActive = false
		W:Show()
		if profileName then
			W:Notify({ Title = "Profile loaded", Content = profileName, Type = "Success" })
		end
	end

	if cfg.Loading == false then
		task.defer(function()
			if cfg.AutoLoadProfile ~= false then
				Lumen:LoadAutoProfile()
			end
			W:Show()
		end)
	else
		task.spawn(runSplash)
	end

	return W
end

return Lumen
