--[[
	Lumen v2.0 - one library, glass hub UI for Roblox (Luau)

	Window  : CreateWindow{ Name, Subtitle, Theme, Accent, Language, Labels, Size, ToggleKey, KeySystem, MobileButton }
	Tabs    : Window:CreateTab(name, icon) | Window:CreateHomeTab() | Tab:Split(leftWidth) -> left, right
	Controls: CreateSection, CreateLabel, CreateParagraph, CreateDivider, CreateButton, CreateToggle,
	          CreateSlider, CreateDropdown (search + multi), CreateInput, CreateKeybind, CreateColorPicker,
	          CreateProgress
	Widgets : CreateProfileCard, CreateClockCard, CreateAnniversaryCard, CreateGameCard,
	          CreateAccountDetails, CreateInfoRow
	Built-in: CreateUISettings (theme / accent / scale / transparency / toggle key), CreateConfigManager
	Keys    : KeySystem = { Keys = {..}, KeyUrl = "raw url, one key per line", Check = function(key) end, Link = "get-key url",
	          SaveKey = true, ExpireHours = 24, MaxAttempts = 3, Cooldown = 15, CaseInsensitive = false, OnSuccess = function(key) end }
	Window  : Dialog{Title, Content, Buttons = {{Name, Primary, Callback}}}, AutoLoad(name), AutoSave(name, seconds)
	Window  : Notify{Title, Content, Duration, Type}, SetTheme, SetAccent, SetUIScale, SetTransparency,
	          SetToggleKey, SetVisible, Toggle, Minimize, Destroy
	Library : Lumen:SaveConfig/LoadConfig/DeleteConfig/ListConfigs, Lumen:Notify
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService")

local Lumen = { Version = "2.0.0", Flags = {}, Options = {}, Windows = {}, Listening = false }

local rgb = Color3.fromRGB
local C = {
	White = Color3.new(1, 1, 1), Black = Color3.new(0, 0, 0),
	Green = rgb(72, 182, 128), Purple = rgb(128, 108, 205), Pink = rgb(206, 88, 126),
	Gold = rgb(214, 174, 72), Red = rgb(204, 78, 86),
}

Lumen.Accents = {
	Blue = rgb(66, 120, 214), Violet = rgb(124, 104, 210), Emerald = rgb(48, 168, 120),
	Crimson = rgb(206, 78, 100), Gold = rgb(208, 160, 58), Cyan = rgb(54, 166, 196),
}

Lumen.Themes = {
	Glass = {
		Window1 = rgb(34, 42, 68), Window2 = rgb(14, 18, 30), WinT = 0.12, Panel = rgb(14, 18, 30),
		Card = rgb(10, 14, 26), CardT = 0.3, Text = rgb(214, 220, 236), Sub = rgb(134, 143, 170),
		Off = rgb(58, 66, 92), Line = C.White, LineT = 0.86, Accent = Lumen.Accents.Blue,
	},
	Midnight = {
		Window1 = rgb(18, 18, 24), Window2 = rgb(8, 8, 12), WinT = 0.05, Panel = rgb(12, 12, 18),
		Card = rgb(20, 20, 28), CardT = 0.2, Off = rgb(52, 52, 68), Accent = Lumen.Accents.Violet,
	},
	Ocean = {
		Window1 = rgb(20, 46, 66), Window2 = rgb(8, 22, 34), Panel = rgb(10, 26, 40), Card = rgb(10, 30, 46),
		Sub = rgb(140, 175, 195), Off = rgb(40, 70, 92), Accent = Lumen.Accents.Cyan,
	},
	Rose = {
		Window1 = rgb(60, 32, 44), Window2 = rgb(26, 14, 20), Panel = rgb(30, 18, 24), Card = rgb(34, 20, 28),
		Sub = rgb(190, 150, 165), Off = rgb(84, 56, 68), Accent = Lumen.Accents.Crimson,
	},
	Light = {
		Window1 = rgb(246, 247, 251), Window2 = rgb(226, 229, 238), WinT = 0.04, Panel = rgb(255, 255, 255),
		Card = rgb(255, 255, 255), CardT = 0.25, Text = rgb(28, 32, 46), Sub = rgb(100, 106, 124),
		Off = rgb(200, 205, 218), Line = rgb(120, 128, 160), LineT = 0.7, Accent = Lumen.Accents.Violet,
	},
}
for name, th in pairs(Lumen.Themes) do
	for k, v in pairs(Lumen.Themes.Glass) do
		if th[k] == nil then th[k] = v end
	end
end

Lumen.Languages = {
	id = {
		Days = { "Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu" },
		Months = { "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember" },
		["Account details"] = "Detail akun", ["Created"] = "Dibuat", ["Account age"] = "Umur akun",
		["Locale"] = "Locale", ["Team"] = "Team", ["Device"] = "Device", ["Executor"] = "Pelaksana",
		["FRIENDS"] = "TEMAN", ["Account anniversary"] = "Ulang tahun akun",
		["%d days left (year %d)"] = "%d hari lagi (tahun ke-%d)", ["session %s"] = "sesi %s",
		["%d/%d players - up %s"] = "%d/%d pemain - hidup %s", ["by %s"] = "oleh %s",
		["%dy %dm"] = "%d th %d bln", ["%d days"] = "%d hari",
		["%dy %dm %dd (%d days)"] = "%d tahun %d bulan %d hari (%d hari)",
		["None"] = "Tidak ada", ["Search..."] = "Cari...", ["Hidden"] = "Disembunyikan",
		["Press %s to reopen."] = "Tekan %s untuk membuka lagi.",
		["Tap the button to reopen."] = "Ketuk tombol untuk membuka lagi.",
		["Appearance"] = "Tampilan", ["Theme"] = "Tema", ["Accent"] = "Aksen", ["UI scale"] = "Skala UI",
		["Transparency"] = "Transparansi", ["Toggle key"] = "Tombol UI", ["Destroy UI"] = "Hapus UI",
		["Configs"] = "Konfigurasi", ["Config name"] = "Nama konfigurasi", ["Saved configs"] = "Tersimpan",
		["Save"] = "Simpan", ["Load"] = "Muat", ["Delete"] = "Hapus", ["Refresh"] = "Segarkan",
		["Saved"] = "Tersimpan", ["Loaded"] = "Dimuat", ["Deleted"] = "Dihapus", ["Copied"] = "Disalin",
		["Wrong key"] = "Kunci salah", ["Are you sure?"] = "Yakin?", ["Cancel"] = "Batal", ["Paste"] = "Tempel", ["Key accepted"] = "Kunci diterima", ["Submit"] = "Kirim", ["Get key"] = "Ambil kunci", ["Enter key"] = "Masukkan kunci",
	},
}

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function New(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	if parent then inst.Parent = parent end
	return inst
end
local function Tween(i, props, t, style, dir)
	local tw = TweenService:Create(i, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function Corner(r) return New("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function Pad(l, t, r, b)
	return New("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) })
end
local function List(pad, horizontal)
	return New("UIListLayout", {
		Padding = UDim.new(0, pad or 6), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
	})
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function round(n, inc)
	inc = inc or 1
	local r = math.floor(n / inc + 0.5) * inc
	return tonumber(string.format("%.10g", r))
end
local function safe(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[Lumen] callback error: " .. tostring(err)) end
end
local function guiParent()
	local ok, ui = pcall(function() return gethui and gethui() end)
	if ok and ui then return ui end
	local ok2, core = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and core and pcall(function() Instance.new("Folder").Parent = core end) then return core end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end
local function fmtDuration(s)
	s = math.floor(s)
	local h, m, sec = math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60
	if h > 0 then return string.format("%dh %dm %ds", h, m, sec) end
	return string.format("%dm %ds", m, sec)
end
local function fsOK()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end
local function ensureFolder()
	pcall(function() if makefolder and not isfolder("Lumen") then makefolder("Lumen") end end)
end

----------------------------------------------------------------------
-- Config
----------------------------------------------------------------------
local function enc(v) if typeof(v) == "Color3" then return { __c3 = { v.R, v.G, v.B } } end return v end
local function dec(v) if type(v) == "table" and v.__c3 then return Color3.new(v.__c3[1], v.__c3[2], v.__c3[3]) end return v end

function Lumen:SaveConfig(name)
	if not fsOK() then warn("[Lumen] file system unavailable") return false end
	local d = {}
	for k, v in pairs(Lumen.Flags) do d[k] = enc(v) end
	ensureFolder()
	return (pcall(writefile, "Lumen/" .. name .. ".json", HttpService:JSONEncode(d)))
end
function Lumen:LoadConfig(name)
	if not fsOK() then warn("[Lumen] file system unavailable") return false end
	local path = "Lumen/" .. name .. ".json"
	if not isfile(path) then return false end
	local ok, d = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok then return false end
	for k, v in pairs(d) do
		local o = Lumen.Options[k]
		if o and o.Set then pcall(o.Set, o, dec(v)) end
	end
	return true
end
function Lumen:DeleteConfig(name)
	if type(delfile) ~= "function" then return false end
	return (pcall(delfile, "Lumen/" .. name .. ".json"))
end
function Lumen:ListConfigs()
	local out = {}
	if type(listfiles) ~= "function" then return out end
	local ok, files = pcall(listfiles, "Lumen")
	if ok and type(files) == "table" then
		for _, p in ipairs(files) do
			local n = p:match("([^/\\]+)%.json$")
			if n then out[#out + 1] = n end
		end
	end
	table.sort(out)
	return out
end
function Lumen:Notify(n)
	local w = Lumen.Windows[#Lumen.Windows]
	if w then w:Notify(n) end
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function Lumen:CreateWindow(cfg)
	cfg = cfg or {}
	local W = { Tabs = {} }
	local lp = Players.LocalPlayer

	-- language ----------------------------------------------------------
	local Labels = cfg.Labels or Lumen.Languages[cfg.Language or ""] or {}
	local function L(k, ...)
		local s = Labels[k] or k
		if select("#", ...) > 0 then
			local ok, r = pcall(string.format, s, ...)
			return ok and r or s
		end
		return s
	end
	local function fmtDate(t)
		local d = os.date("*t", t)
		local dn = Labels.Days and Labels.Days[d.wday] or os.date("%A", t)
		local mn = Labels.Months and Labels.Months[d.month] or os.date("%B", t)
		return string.format("%s, %d %s %d", dn, d.day, mn, d.year)
	end
	local function dayName(t)
		local d = os.date("*t", t)
		return Labels.Days and Labels.Days[d.wday] or os.date("%A", t)
	end

	-- theme ---------------------------------------------------------------
	local accentOverride = typeof(cfg.Accent) == "Color3" and cfg.Accent or Lumen.Accents[cfg.Accent or ""]
	local winTOverride
	local themeName = "Glass"
	local T = {}
	local function loadTheme(name)
		local p = Lumen.Themes[name]
		if not p then name = "Glass" p = Lumen.Themes.Glass end
		themeName = name
		T = {}
		for k, v in pairs(p) do T[k] = v end
		T.Accent = accentOverride or p.Accent
		if winTOverride then T.WinT = winTOverride end
	end
	loadTheme(cfg.Theme or "Glass")

	local conns, binds, themeFns, ticks = {}, {}, {}, {}
	local Gui
	local function conn(c) conns[#conns + 1] = c return c end
	local function bind(inst, prop, key)
		inst[prop] = T[key]
		binds[#binds + 1] = { inst, prop, key }
		return inst
	end
	local function onTheme(fn) themeFns[#themeFns + 1] = fn end
	local function refresh()
		for i = #binds, 1, -1 do
			local b = binds[i]
			if b[1]:IsDescendantOf(Gui) then Tween(b[1], { [b[2]] = T[b[3]] }, 0.3) else table.remove(binds, i) end
		end
		for _, fn in ipairs(themeFns) do pcall(fn) end
	end

	-- gui -------------------------------------------------------------------
	local parent = guiParent()
	if cfg.Name then
		for _, g in ipairs(parent:GetChildren()) do
			if g:GetAttribute("LumenId") == cfg.Name then g:Destroy() end
		end
	end
	Gui = New("ScreenGui", {
		Name = "Lumen_" .. HttpService:GenerateGUID(false):sub(1, 6), ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true, Parent = parent,
	})
	Gui:SetAttribute("LumenId", cfg.Name or "Lumen")
	W.Gui = Gui

	-- shared builders -------------------------------------------------------
	local function text(par, t, size, font, color, pos, sz, align)
		local l = New("TextLabel", {
			BackgroundTransparency = 1, Position = pos or UDim2.fromOffset(12, 0), Size = sz or UDim2.new(1, -24, 1, 0),
			Font = font or Enum.Font.GothamMedium, TextSize = math.max((size or 13) - 1, 9), TextXAlignment = align or Enum.TextXAlignment.Left,
			Text = t, Parent = par,
		})
		if typeof(color) == "Color3" then l.TextColor3 = color else bind(l, "TextColor3", color or "Text") end
		return l
	end
	local function hit(par, h)
		return New("TextButton", {
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			Size = h and UDim2.new(1, 0, 0, h) or UDim2.fromScale(1, 1), Parent = par,
		})
	end
	local function makeIcon(par, ic, w, h, pos)
		local isImg = type(ic) == "number" or (type(ic) == "string" and (ic:find("^rbxasset") ~= nil or ic:find("^rbxthumb") ~= nil))
		if isImg then
			local s = 18
			return New("ImageLabel", {
				BackgroundTransparency = 1, Size = UDim2.fromOffset(s, s),
				Position = UDim2.new(pos.X.Scale, pos.X.Offset + (w - s) / 2, pos.Y.Scale, pos.Y.Offset + (h - s) / 2),
				Image = type(ic) == "number" and ("rbxassetid://" .. ic) or ic, Parent = par,
			})
		end
		return New("TextLabel", {
			BackgroundTransparency = 1, Position = pos, Size = UDim2.fromOffset(w, h), Font = Enum.Font.GothamMedium,
			TextSize = 14, Text = tostring(ic or "-"), Parent = par,
		})
	end
	local function loadAvatar(img)
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok then img.Image = url end
		end)
	end
	local function onTick(fn)
		ticks[#ticks + 1] = fn
		pcall(fn)
	end

	-- live stats (fps / ping) + 1 second ticker --------------------------------
	local Live = { FPS = 0, Ping = 0 }
	do
		local frames, last = 0, os.clock()
		conn(RunService.Heartbeat:Connect(function() frames = frames + 1 end))
		task.spawn(function()
			while Gui.Parent do
				task.wait(1)
				local now = os.clock()
				Live.FPS = math.floor(frames / math.max(now - last, 0.001) + 0.5)
				frames, last = 0, now
				local ok, ping = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
				if ok then Live.Ping = math.floor(ping + 0.5) end
				for _, fn in ipairs(ticks) do pcall(fn) end
			end
		end)
	end

	-- main frame ----------------------------------------------------------------
	local WIDTH = cfg.Size and cfg.Size.X or 660
	local HEIGHT = cfg.Size and cfg.Size.Y or 380
	local TOP = 58
	local hidden, minimized, userScale = true, false, 1
	local locked = false
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift

	local Main = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 14), Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundColor3 = C.White, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, Active = true, Parent = Gui,
	}, { Corner(18) })
	bind(Main, "BackgroundTransparency", "WinT")
	local grad = New("UIGradient", { Rotation = 135, Color = ColorSequence.new(T.Window1, T.Window2), Parent = Main })
	onTheme(function() grad.Color = ColorSequence.new(T.Window1, T.Window2) end)
	local mainStroke = New("UIStroke", { Thickness = 1.5, Parent = Main })
	bind(mainStroke, "Color", "Line")
	mainStroke.Transparency = 0.82
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
			if not hidden then Scale.Scale = fit() end
		end))
	end

	-- topbar --------------------------------------------------------------------
	local Topbar = New("Frame", { Size = UDim2.new(1, 0, 0, TOP), BackgroundTransparency = 1, Parent = Main })
	local titleX = 20
	if cfg.Icon then
		makeIcon(Topbar, cfg.Icon, 28, 28, UDim2.fromOffset(16, 14))
		titleX = 52
	end
	text(Topbar, cfg.Name or "Lumen", 20, Enum.Font.GothamBold, "Text", UDim2.fromOffset(titleX, 10), UDim2.new(0.6, 0, 0, 24))
	text(Topbar, string.upper(cfg.Subtitle or "Premium - Glass - Interface"), 10, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(titleX, 33), UDim2.new(0.6, 0, 0, 14))
	local line = New("Frame", { Position = UDim2.new(0, 16, 1, -1), Size = UDim2.new(1, -32, 0, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0.88, BorderSizePixel = 0, Parent = Topbar })
	bind(line, "BackgroundColor3", "Line")

	local function circleBtn(label, xOff)
		local b = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(30, 30), AutoButtonColor = false,
			BackgroundTransparency = 0.88, Font = Enum.Font.GothamMedium, TextSize = 13, Text = label, Parent = Topbar,
		}, { Corner(15) })
		bind(b, "BackgroundColor3", "Line")
		bind(b, "TextColor3", "Text")
		b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.7 }, 0.15) end)
		b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 0.88 }, 0.15) end)
		return b
	end
	local HideBtn = circleBtn("▢", -14)
	local MinBtn = circleBtn("–", -50)

	do -- dragging (left of the buttons only)
		local dragging, sm, sp = false, nil, nil
		conn(Topbar.InputBegan:Connect(function(i)
			if isPress(i) and i.Position.X < MinBtn.AbsolutePosition.X - 4 then
				dragging, sm, sp = true, i.Position, Main.Position
			end
		end))
		conn(UIS.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = i.Position - sm
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				local ox = sp.X.Offset + d.X
				local oy = sp.Y.Offset + d.Y
				-- keep at least part of the window on screen
				local maxX = vp.X * (1 - sp.X.Scale) - 60
				local minX = -vp.X * sp.X.Scale + 60
				local maxY = vp.Y * (1 - sp.Y.Scale) - 40
				local minY = -vp.Y * sp.Y.Scale + 40
				Main.Position = UDim2.new(sp.X.Scale, math.clamp(ox, minX, maxX), sp.Y.Scale, math.clamp(oy, minY, maxY))
			end
		end))
		conn(UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
	end

	-- body: sidebar + pages ------------------------------------------------------------
	local Body = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TOP + 8), Size = UDim2.new(1, 0, 1, -(TOP + 8)), Parent = Main })
	local SideWrap = New("Frame", {
		Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0, 150, 1, -14), BackgroundTransparency = 0.5, BorderSizePixel = 0,
		ClipsDescendants = true, Parent = Body,
	}, { Corner(14) })
	bind(SideWrap, "BackgroundColor3", "Card")
	local sideStroke = New("UIStroke", { Thickness = 1.2, Parent = SideWrap })
	bind(sideStroke, "Color", "Line")
	bind(sideStroke, "Transparency", "LineT")
	local showChip = cfg.SidebarProfile ~= false
	local Sidebar = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, showChip and -52 or 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = SideWrap,
	}, { Pad(8, 8, 8, 8), List(6) })
	if showChip then
		local chip = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = SideWrap })
		local cl = New("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 0.88, BorderSizePixel = 0, Parent = chip })
		bind(cl, "BackgroundColor3", "Line")
		local av = New("ImageLabel", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = chip }, { Corner(16) })
		bind(av, "BackgroundColor3", "Panel")
		loadAvatar(av)
		text(chip, lp.DisplayName, 12, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(50, 9), UDim2.new(1, -56, 0, 16)).TextTruncate = Enum.TextTruncate.AtEnd
		text(chip, "v" .. Lumen.Version, 10, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(50, 26), UDim2.new(1, -56, 0, 14))
	end
	local Pages = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(172, 0), Size = UDim2.new(1, -186, 1, -14), Parent = Body })

	----------------------------------------------------------------------
	-- Notifications
	----------------------------------------------------------------------
	local NotifHolder = New("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(290, 500), BackgroundTransparency = 1, Parent = Gui,
	}, { New("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })
	local TYPE_COLORS = { Success = C.Green, Warning = C.Gold, Error = C.Red }

	function W:Notify(n)
		if type(n) ~= "table" then n = { Content = tostring(n) } end
		local content = n.Content or ""
		-- keep at most 5 visible; drop the oldest
		local live = {}
		for _, ch in ipairs(NotifHolder:GetChildren()) do
			if ch:IsA("Frame") then live[#live + 1] = ch end
		end
		if #live >= 5 then live[1]:Destroy() end
		local bodyH = 0
		if content ~= "" then
			local ok, size = pcall(function() return TextService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(256, 1000)) end)
			bodyH = ok and size.Y or 15 * math.ceil(#content / 38)
		end
		local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 30 + bodyH + 14), BackgroundTransparency = 1, Parent = NotifHolder })
		local c = New("TextButton", {
			Text = "", AutoButtonColor = false, Position = UDim2.new(1, 320, 0, 0), Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0.08, BorderSizePixel = 0, ClipsDescendants = true, Parent = wrap,
		}, { Corner(12) })
		bind(c, "BackgroundColor3", "Panel")
		local st = New("UIStroke", { Thickness = 1.2, Parent = c })
		bind(st, "Color", "Line")
		bind(st, "Transparency", "LineT")
		local tc = TYPE_COLORS[n.Type]
		local bar = New("Frame", { Position = UDim2.fromOffset(8, 10), Size = UDim2.new(0, 3, 1, -20), BorderSizePixel = 0, Parent = c }, { Corner(2) })
		local timer = New("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, BackgroundTransparency = 0.3, Parent = c })
		if tc then bar.BackgroundColor3 = tc timer.BackgroundColor3 = tc
		else bind(bar, "BackgroundColor3", "Accent") bind(timer, "BackgroundColor3", "Accent") end
		text(c, n.Title or "Notice", 14, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(20, 8), UDim2.new(1, -30, 0, 18))
		if content ~= "" then
			local b = text(c, content, 12, Enum.Font.Gotham, "Sub", UDim2.fromOffset(20, 28), UDim2.new(1, -34, 0, bodyH))
			b.TextWrapped = true
			b.TextYAlignment = Enum.TextYAlignment.Top
		end
		local gone = false
		local function dismiss()
			if gone or not c.Parent then return end
			gone = true
			Tween(c, { Position = UDim2.new(1, 320, 0, 0) }, 0.3)
			task.delay(0.3, function() wrap:Destroy() end)
		end
		c.MouseButton1Click:Connect(dismiss)
		local dur = n.Duration or 4
		Tween(c, { Position = UDim2.new() }, 0.4, Enum.EasingStyle.Back)
		Tween(timer, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
		task.delay(dur, dismiss)
	end

	----------------------------------------------------------------------
	-- Element builders (shared by tabs and split columns)
	----------------------------------------------------------------------
	local function attachElements(host, container)
		local function card(h, neon)
			local f = New("Frame", { Size = UDim2.new(1, 0, 0, h), BorderSizePixel = 0, ClipsDescendants = true, Parent = container }, { Corner(10) })
			bind(f, "BackgroundColor3", "Card")
			bind(f, "BackgroundTransparency", "CardT")
			local s = New("UIStroke", { Thickness = 1.5, Parent = f })
			if neon == "accent" then
				bind(s, "Color", "Accent")
				s.Transparency = 0.72
			elseif typeof(neon) == "Color3" then
				s.Color = neon
				s.Transparency = 0.62
			else
				bind(s, "Color", "Line")
				bind(s, "Transparency", "LineT")
			end
			return f, s
		end
		local function hover(f, h)
			h.MouseEnter:Connect(function() Tween(f, { BackgroundTransparency = math.max(T.CardT - 0.18, 0) }, 0.15) end)
			h.MouseLeave:Connect(function() Tween(f, { BackgroundTransparency = T.CardT }, 0.15) end)
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
			function o:Destroy() f:Destroy() end
			function o:SetVisible(v) f.Visible = v end
			return o
		end
		local function reg(flag, obj, val)
			if flag then Lumen.Flags[flag] = val Lumen.Options[flag] = obj end
		end
		local function drag(inputFrame, ref, onMove)
			local active = false
			local function upd(i)
				-- input positions exclude the top inset, AbsolutePosition includes it (IgnoreGuiInset = true)
				local pos = Vector2.new(i.Position.X, i.Position.Y) + (Gui.IgnoreGuiInset and GuiService:GetGuiInset() or Vector2.zero)
				local p, s = ref.AbsolutePosition, ref.AbsoluteSize
				onMove(math.clamp((pos.X - p.X) / math.max(s.X, 1), 0, 1), math.clamp((pos.Y - p.Y) / math.max(s.Y, 1), 0, 1))
			end
			local function lock(v) if container:IsA("ScrollingFrame") then container.ScrollingEnabled = v end end
			conn(inputFrame.InputBegan:Connect(function(i)
				if isPress(i) then active = true lock(false) upd(i) end
			end))
			conn(UIS.InputChanged:Connect(function(i) if active and isMove(i) then upd(i) end end))
			conn(UIS.InputEnded:Connect(function(i)
				if active and isPress(i) then active = false lock(true) end
			end))
		end

		-- section header / label / paragraph / divider ---------------------------
		function host:CreateSection(title, neon)
			local f = card(30, neon or C.Pink)
			New("Frame", { Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(3, 16), BackgroundColor3 = neon or C.Pink, BorderSizePixel = 0, Parent = f }, { Corner(2) })
			text(f, string.upper(title or "Section"), 11, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(22, 0), UDim2.new(1, -30, 1, 0))
			return base(f, {})
		end
		function host:CreateLabel(t)
			local f = card(32)
			local l = text(f, t, 12, Enum.Font.Gotham, "Sub")
			return base(f, { Set = function(_, v) l.Text = v end })
		end
		function host:CreateParagraph(c)
			local f = card(0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.Size = UDim2.new(1, 0, 0, 0)
			Pad(12, 10, 12, 10).Parent = f
			List(4).Parent = f
			local t = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = c.Title or "", Parent = f })
			bind(t, "TextColor3", "Text")
			local b = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = c.Content or "", Parent = f })
			bind(b, "TextColor3", "Sub")
			return base(f, { Set = function(_, n) t.Text = n.Title or t.Text b.Text = n.Content or b.Text end })
		end
		function host:CreateDivider()
			local d = New("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = container })
			bind(d, "BackgroundColor3", "Line")
			d.BackgroundTransparency = 0.8
			return base(d, {})
		end
		function host:CreateInfoRow(icon, key, value, neon)
			local f = card(40, neon or "accent")
			text(f, icon or "•", 15, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(10, 0), UDim2.fromOffset(24, 40), Enum.TextXAlignment.Center)
			text(f, key, 11, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(40, 0), UDim2.fromOffset(86, 40)).TextTruncate = Enum.TextTruncate.AtEnd
			local v = text(f, tostring(value), 12, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(132, 0), UDim2.new(1, -142, 1, 0))
			v.TextTruncate = Enum.TextTruncate.AtEnd
			return base(f, { Set = function(_, nv) v.Text = tostring(nv) end })
		end

		-- button -----------------------------------------------------------------------
		function host:CreateButton(c)
			local f = card(c.Description and 54 or 40, c.Neon)
			named(f, c.Name or "Button", c.Description, 36)
			local ch = text(f, "›", 20, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -28, 0, 0), UDim2.new(0, 16, 1, 0), Enum.TextXAlignment.Center)
			local ring = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(), BackgroundTransparency = 1, Parent = f }, { Corner(100) })
			local btn = hit(f)
			hover(f, btn)
			local function fire()
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
				safe(c.Callback)
			end
			btn.MouseButton1Click:Connect(fire)
			return base(f, { Fire = fire })
		end

		-- toggle -----------------------------------------------------------------------
		function host:CreateToggle(c)
			local f = card(c.Description and 54 or 40, c.Neon)
			named(f, c.Name or "Toggle", c.Description, 60)
			local track = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(42, 22), BorderSizePixel = 0, Parent = f }, { Corner(11) })
			local knob = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = track }, { Corner(8) })
			local h = hit(f)
			hover(f, h)
			local o = { CurrentValue = c.CurrentValue == true }
			local function render(instant)
				local d = instant and 0 or 0.2
				Tween(track, { BackgroundColor3 = o.CurrentValue and T.Accent or T.Off }, d)
				Tween(knob, { Position = o.CurrentValue and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, d, Enum.EasingStyle.Back)
			end
			onTheme(function() render(true) end)
			function o:Set(v, silent)
				o.CurrentValue = v and true or false
				if c.Flag then Lumen.Flags[c.Flag] = o.CurrentValue end
				render()
				if not silent then safe(c.Callback, o.CurrentValue) end
			end
			function o:Get() return o.CurrentValue end
			h.MouseButton1Click:Connect(function() o:Set(not o.CurrentValue) end)
			reg(c.Flag, o, o.CurrentValue)
			render(true)
			if o.CurrentValue then safe(c.Callback, true) end
			return base(f, o)
		end

		-- slider -----------------------------------------------------------------------
		function host:CreateSlider(c)
			local min = c.Range and c.Range[1] or 0
			local max = c.Range and c.Range[2] or 100
			local inc = c.Increment or 1
			local f = card(56, c.Neon)
			text(f, c.Name or "Slider", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 6), UDim2.new(0.6, 0, 0, 20))
			local val = text(f, "", 12, Enum.Font.GothamMedium, "Sub", UDim2.new(0.4, -12, 0, 6), UDim2.new(0.6, 0, 0, 20), Enum.TextXAlignment.Right)
			local track = New("Frame", { Position = UDim2.new(0, 12, 1, -20), Size = UDim2.new(1, -24, 0, 7), BorderSizePixel = 0, Parent = f }, { Corner(4) })
			bind(track, "BackgroundColor3", "Off")
			local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track }, { Corner(4) })
			bind(fill, "BackgroundColor3", "Accent")
			New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = fill }, { Corner(7) })
			local o = { CurrentValue = c.CurrentValue or min }
			function o:Set(v, silent)
				v = math.clamp(round(v, inc), min, max)
				o.CurrentValue = v
				local a = max > min and (v - min) / (max - min) or 0
				Tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.08)
				val.Text = tostring(v) .. (c.Suffix and (" " .. c.Suffix) or "")
				if c.Flag then Lumen.Flags[c.Flag] = v end
				if not silent then safe(c.Callback, v) end
			end
			function o:Get() return o.CurrentValue end
			local area = New("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Position = UDim2.new(0, 0, 1, -34), Size = UDim2.new(1, 0, 0, 34), Parent = f })
			drag(area, track, function(x) o:Set(min + (max - min) * x) end)
			reg(c.Flag, o, o.CurrentValue)
			o:Set(o.CurrentValue, true)
			return base(f, o)
		end

		-- progress ---------------------------------------------------------------------
		function host:CreateProgress(c)
			local f = card(48, c.Neon)
			text(f, c.Name or "Progress", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 5), UDim2.new(0.6, 0, 0, 20))
			local val = text(f, "", 12, Enum.Font.GothamMedium, "Sub", UDim2.new(0.4, -12, 0, 5), UDim2.new(0.6, 0, 0, 20), Enum.TextXAlignment.Right)
			local track = New("Frame", { Position = UDim2.new(0, 12, 1, -16), Size = UDim2.new(1, -24, 0, 7), BorderSizePixel = 0, Parent = f }, { Corner(4) })
			bind(track, "BackgroundColor3", "Off")
			local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = c.Color or C.Green, BorderSizePixel = 0, Parent = track }, { Corner(4) })
			local o = {}
			function o:Set(v, label)
				v = math.clamp(v, 0, 1)
				Tween(fill, { Size = UDim2.fromScale(v, 1) }, 0.25)
				val.Text = label or (math.floor(v * 100 + 0.5) .. "%")
			end
			o:Set(c.Value or 0, c.Label)
			return base(f, o)
		end

		-- dropdown (single / multi / search) ----------------------------------------------
		function host:CreateDropdown(c)
			local multi = c.MultipleOptions == true
			local options = c.Options or {}
			local f = card(40, c.Neon)
			text(f, c.Name or "Dropdown", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 0, 40))
			local cur = text(f, "", 12, Enum.Font.GothamMedium, "Sub", UDim2.new(0.5, -34, 0, 0), UDim2.new(0.5, 0, 0, 40), Enum.TextXAlignment.Right)
			cur.TextTruncate = Enum.TextTruncate.AtEnd
			local arrow = text(f, "▾", 14, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -26, 0, 0), UDim2.fromOffset(16, 40), Enum.TextXAlignment.Center)
			local search = New("TextBox", {
				Position = UDim2.fromOffset(8, 44), Size = UDim2.new(1, -16, 0, 26), BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 11,
				PlaceholderText = L("Search..."), Text = "", ClearTextOnFocus = false, Visible = false, BackgroundTransparency = 0.2, Parent = f,
			}, { Corner(6), Pad(8, 0, 8, 0) })
			bind(search, "BackgroundColor3", "Panel")
			bind(search, "TextColor3", "Text")
			bind(search, "PlaceholderColor3", "Sub")
			local list = New("ScrollingFrame", {
				BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -12, 0, 0), Parent = f,
			}, { List(3) })
			local head = hit(f, 40)
			hover(f, head)

			local o = { Open = false, Options = options }
			local sel, buttons, visibleCount = {}, {}, 0
			if type(c.CurrentOption) == "table" then
				for _, v in ipairs(c.CurrentOption) do sel[v] = true end
			elseif c.CurrentOption ~= nil then
				sel[c.CurrentOption] = true
			end
			local function value()
				if multi then
					local t = {}
					for _, op in ipairs(o.Options) do if sel[op] then t[#t + 1] = op end end
					return t
				end
				for _, op in ipairs(o.Options) do if sel[op] then return op end end
				return nil
			end
			local function style()
				local v = value()
				if multi then cur.Text = #v == 0 and L("None") or table.concat(v, ", ")
				else cur.Text = v ~= nil and tostring(v) or L("None") end
				for op, b in pairs(buttons) do
					Tween(b, { TextColor3 = sel[op] and T.Accent or T.Text }, 0.15)
				end
			end
			onTheme(style)
			local function listHeight() return math.min(visibleCount * 31, 150) end
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
						if show then visibleCount = visibleCount + 1 end
					end
				end
				layout()
			end
			search:GetPropertyChangedSignal("Text"):Connect(applyFilter)
			local function commit(silent)
				style()
				local v = value()
				if c.Flag then Lumen.Flags[c.Flag] = v end
				if not silent then safe(c.Callback, v) end
			end
			local function build()
				for _, b in pairs(buttons) do b:Destroy() end
				buttons = {}
				for i, op in ipairs(o.Options) do
					local b = New("TextButton", {
						LayoutOrder = i, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = tostring(op),
						Font = Enum.Font.GothamMedium, TextSize = 11, AutoButtonColor = false, Parent = list,
					}, { Corner(6) })
					b.BackgroundColor3 = C.White
					b.TextColor3 = T.Text
					b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.88 }, 0.1) end)
					b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 1 }, 0.1) end)
					b.MouseButton1Click:Connect(function()
						if multi then
							sel[op] = (not sel[op]) or nil
						else
							sel = { [op] = true }
							o.Open = false
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
				if type(v) == "table" then for _, x in ipairs(v) do sel[x] = true end
				elseif v ~= nil then sel[v] = true end
				commit(silent)
			end
			function o:Refresh(opts)
				o.Options = opts
				sel = {}
				search.Text = ""
				build()
				layout()
			end
			function o:Get() return value() end
			function o:Close()
				if o.Open then o.Open = false layout() end
			end
			W._dropdowns = W._dropdowns or {}
			W._dropdowns[#W._dropdowns + 1] = o
			head.MouseButton1Click:Connect(function()
				if not o.Open then
					for _, other in ipairs(W._dropdowns) do
						if other ~= o and other.Frame and other.Frame.Parent then other:Close() end
					end
				end
				o.Open = not o.Open
				layout()
			end)
			build()
			reg(c.Flag, o, value())
			return base(f, o)
		end

		-- input ------------------------------------------------------------------------
		function host:CreateInput(c)
			local f = card(40, c.Neon)
			text(f, c.Name or "Input", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 1, 0))
			local box = New("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.42, 0, 0, 26),
				BackgroundTransparency = 0.2, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false,
				PlaceholderText = c.PlaceholderText or "Type here...", Text = c.CurrentValue or "", Parent = f,
			}, { Corner(6), Pad(8, 0, 8, 0) })
			bind(box, "BackgroundColor3", "Panel")
			bind(box, "TextColor3", "Text")
			bind(box, "PlaceholderColor3", "Sub")
			local s = New("UIStroke", { Thickness = 1, Transparency = 0.85, Parent = box })
			bind(s, "Color", "Line")
			box.Focused:Connect(function() Tween(s, { Color = T.Accent, Transparency = 0 }, 0.15) end)
			local o = { CurrentValue = box.Text }
			box.FocusLost:Connect(function()
				Tween(s, { Color = T.Line, Transparency = 0.85 }, 0.15)
				local v = box.Text
				if c.Numeric then
					local n = tonumber(v)
					if n == nil then box.Text = o.CurrentValue return end
					v = tostring(n)
					box.Text = v
				end
				o.CurrentValue = v
				if c.Flag then Lumen.Flags[c.Flag] = v end
				safe(c.Callback, v)
				if c.RemoveTextAfterFocusLost then box.Text = "" end
			end)
			function o:Set(t, silent)
				box.Text = t
				o.CurrentValue = t
				if c.Flag then Lumen.Flags[c.Flag] = t end
				if not silent then safe(c.Callback, t) end
			end
			function o:Get() return o.CurrentValue end
			reg(c.Flag, o, o.CurrentValue)
			return base(f, o)
		end

		-- keybind ----------------------------------------------------------------------
		function host:CreateKeybind(c)
			local f = card(40, c.Neon)
			named(f, c.Name or "Keybind", nil, 90)
			local h = hit(f)
			hover(f, h)
			local b = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(70, 24),
				BackgroundTransparency = 0.2, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 10, Text = c.CurrentKeybind or "None", Parent = f,
			}, { Corner(6) })
			bind(b, "BackgroundColor3", "Panel")
			bind(b, "TextColor3", "Sub")
			local o = { CurrentKeybind = c.CurrentKeybind, Listening = false }
			function o:Set(k)
				o.CurrentKeybind = k
				b.Text = k or "None"
				if c.Flag then Lumen.Flags[c.Flag] = k end
			end
			function o:Get() return o.CurrentKeybind end
			h.MouseButton1Click:Connect(function()
				o.Listening = true
				Lumen.Listening = true
				b.Text = "..."
			end)
			conn(UIS.InputBegan:Connect(function(i, gpe)
				if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
				if o.Listening then
					o.Listening = false
					task.defer(function() Lumen.Listening = false end)
					local k = i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode.Name or nil
					o:Set(k)
					safe(c.ChangedCallback, k)
				elseif not gpe and not Lumen.Listening and o.CurrentKeybind and i.KeyCode.Name == o.CurrentKeybind then
					safe(c.Callback)
				end
			end))
			reg(c.Flag, o, o.CurrentKeybind)
			return base(f, o)
		end

		-- color picker (HSV + hex) ---------------------------------------------------------
		function host:CreateColorPicker(c)
			local f = card(40, c.Neon)
			named(f, c.Name or "Color", nil, 60)
			local sw = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(34, 20), BorderSizePixel = 0, Parent = f }, { Corner(6) })
			local sv = New("Frame", { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -52, 0, 100), BorderSizePixel = 0, Parent = f }, { Corner(6) })
			New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = sv }, { Corner(6), New("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
			New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Black, BorderSizePixel = 0, Parent = sv }, { Corner(6), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
			local dot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 5, Parent = sv }, { Corner(5), New("UIStroke", { Thickness = 2, Color = C.White }) })
			local svHit = New("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = sv })
			local seq = {}
			for i = 0, 6 do seq[#seq + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1)) end
			local hue = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 48), Size = UDim2.fromOffset(20, 100), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = f }, { Corner(6), New("UIGradient", { Rotation = 90, Color = ColorSequence.new(seq) }) })
			local hdot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = hue }, { Corner(2) })
			local hueHit = New("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = hue })
			local hex = New("TextBox", {
				Position = UDim2.fromOffset(12, 156), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 0.2, BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium, TextSize = 11, ClearTextOnFocus = false, Text = "", Parent = f,
			}, { Corner(6), Pad(8, 0, 8, 0) })
			bind(hex, "BackgroundColor3", "Panel")
			bind(hex, "TextColor3", "Text")
			local header = hit(f, 40)
			hover(f, header)

			local h, s, v = (c.Color or C.White):ToHSV()
			local o = { Open = false }
			local function apply(silent)
				local col = Color3.fromHSV(h, s, v)
				o.CurrentColor = col
				sw.BackgroundColor3 = col
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				dot.Position = UDim2.fromScale(s, 1 - v)
				hdot.Position = UDim2.fromScale(0.5, h)
				hex.Text = "#" .. col:ToHex():upper()
				if c.Flag then Lumen.Flags[c.Flag] = col end
				if not silent then safe(c.Callback, col) end
			end
			drag(svHit, sv, function(x, y) s, v = x, 1 - y apply() end)
			drag(hueHit, hue, function(_, y) h = math.clamp(y, 0, 0.999) apply() end)
			hex.FocusLost:Connect(function()
				local str = hex.Text:gsub("#", "")
				local ok, col = pcall(Color3.fromHex, "#" .. str)
				if ok and col then h, s, v = col:ToHSV() end
				apply()
			end)
			function o:Set(col, silent) h, s, v = col:ToHSV() apply(silent) end
			function o:Get() return o.CurrentColor end
			header.MouseButton1Click:Connect(function()
				o.Open = not o.Open
				Tween(f, { Size = UDim2.new(1, 0, 0, o.Open and 192 or 40) }, 0.25)
			end)
			reg(c.Flag, o, c.Color or C.White)
			apply(true)
			return base(f, o)
		end

		----------------------------------------------------------------
		-- Profile widgets
		----------------------------------------------------------------
		local ageDays = lp.AccountAge
		local createdAt = os.time() - ageDays * 86400

		function host:CreateProfileCard(c)
			c = c or {}
			local f = card(268)
			local banner = New("Frame", { Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = f }, { Corner(10) })
			local bg = New("UIGradient", { Rotation = 20, Color = ColorSequence.new(C.Purple:Lerp(C.Black, 0.45), T.Accent:Lerp(C.Black, 0.45)), Parent = banner })
			onTheme(function() bg.Color = ColorSequence.new(C.Purple:Lerp(C.Black, 0.45), T.Accent:Lerp(C.Black, 0.45)) end)
			if c.Badge ~= false then
				New("TextLabel", {
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(110, 24), BackgroundColor3 = rgb(20, 20, 40),
					BackgroundTransparency = 0.3, Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = C.Gold, Text = c.Badge or "PREMIUM", Parent = f,
				}, { Corner(12), New("UIStroke", { Thickness = 1.5, Color = C.Gold }) })
			end
			local avatar = New("ImageLabel", { Position = UDim2.fromOffset(12, 36), Size = UDim2.fromOffset(84, 84), BorderSizePixel = 0, Parent = f }, { Corner(42) })
			bind(avatar, "BackgroundColor3", "Panel")
			local ast = New("UIStroke", { Thickness = 3, Color = C.White, Parent = avatar })
			New("UIGradient", { Rotation = 45, Color = ColorSequence.new(C.Green, C.Purple), Parent = ast })
			loadAvatar(avatar)
			local dotf = New("Frame", { Position = UDim2.fromOffset(78, 100), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = C.Green, BorderSizePixel = 0, ZIndex = 3, Parent = f }, { Corner(8) })
			local dstroke = New("UIStroke", { Thickness = 2, Parent = dotf })
			bind(dstroke, "Color", "Card")
			text(f, lp.DisplayName, 16, Enum.Font.GothamBold, "Text", UDim2.fromOffset(106, 86), UDim2.new(1, -116, 0, 20)).TextTruncate = Enum.TextTruncate.AtEnd
			text(f, "@" .. lp.Name, 11, Enum.Font.GothamMedium, C.Pink, UDim2.fromOffset(106, 106), UDim2.new(1, -116, 0, 14)).TextTruncate = Enum.TextTruncate.AtEnd
			local idp = New("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 126), Size = UDim2.new(1, -24, 0, 22), BackgroundTransparency = 0.2,
				Font = Enum.Font.GothamMedium, TextSize = 10, AutoButtonColor = false, Text = "ID  " .. lp.UserId, Parent = f,
			}, { Corner(11) })
			bind(idp, "BackgroundColor3", "Panel")
			bind(idp, "TextColor3", "Text")
			local idStroke = New("UIStroke", { Thickness = 1.2, Transparency = 0.7, Parent = idp })
			bind(idStroke, "Color", "Line")
			idp.MouseButton1Click:Connect(function()
				if type(setclipboard) == "function" then
					pcall(setclipboard, tostring(lp.UserId))
					W:Notify({ Title = L("Copied"), Content = tostring(lp.UserId), Duration = 2, Type = "Success" })
				end
			end)

			local y, m = math.floor(ageDays / 365), math.floor((ageDays % 365) / 30)
			local chips = New("Frame", { Position = UDim2.fromOffset(12, 156), Size = UDim2.new(1, -24, 0, 22), BackgroundTransparency = 1, Parent = f }, { List(5, true) })
			local chipData = c.Chips or { dayName(createdAt), L("%dy %dm", y, m), L("%d days", ageDays) }
			for i, t in ipairs(chipData) do
				local ch = New("TextLabel", {
					LayoutOrder = i, Size = UDim2.new(1 / #chipData, -4, 1, 0), BackgroundTransparency = 0.3, Font = Enum.Font.GothamMedium, TextSize = 10, Text = t, Parent = chips,
				}, { Corner(11), New("UIStroke", { Thickness = 1, Color = C.Green, Transparency = 0.68 }) })
				bind(ch, "BackgroundColor3", "Panel")
				bind(ch, "TextColor3", "Text")
			end

			local stats = New("Frame", { Position = UDim2.fromOffset(12, 188), Size = UDim2.new(1, -24, 0, 56), BackgroundTransparency = 1, Parent = f }, { List(8, true) })
			local defs = c.Stats or {
				{ Label = L("FRIENDS"), Color = C.Green, Value = "…" },
				{ Label = "PING", Color = C.Pink, Value = "…" },
				{ Label = "FPS", Color = C.Purple, Value = "…" },
			}
			local vls = {}
			for i, d in ipairs(defs) do
				local b = New("Frame", { LayoutOrder = i, Size = UDim2.new(1 / #defs, -math.ceil(8 * (#defs - 1) / #defs), 1, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = stats }, {
					Corner(10), New("UIStroke", { Thickness = 1.2, Color = d.Color, Transparency = 0.55 }),
				})
				bind(b, "BackgroundColor3", "Panel")
				vls[i] = New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.GothamBold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = d.Color, Text = type(d.Value) == "function" and "…" or tostring(d.Value), Parent = b })
				text(b, d.Label, 9, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 14), Enum.TextXAlignment.Center)
			end
			if c.Stats then
				onTick(function()
					for i, d in ipairs(defs) do
						if type(d.Value) == "function" then vls[i].Text = tostring(d.Value()) end
					end
				end)
			else
				task.spawn(function()
					local ok, count = pcall(function()
						local pages, n = Players:GetFriendsAsync(lp.UserId), 0
						while true do
							n = n + #pages:GetCurrentPage()
							if pages.IsFinished then break end
							pages:AdvanceToNextPageAsync()
						end
						return n
					end)
					vls[1].Text = ok and tostring(count) or "-"
				end)
				onTick(function()
					vls[2].Text = Live.Ping > 0 and (Live.Ping .. "ms") or "-"
					vls[3].Text = tostring(Live.FPS)
				end)
			end
			return base(f, {})
		end

		function host:CreateClockCard()
			local f = card(70, "accent")
			local t = text(f, "", 22, Enum.Font.GothamBold, "Text", UDim2.fromOffset(12, 8), UDim2.new(0.6, 0, 0, 28))
			local d = text(f, "", 11, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(12, 40), UDim2.new(1, -24, 0, 16))
			local sess = text(f, "", 11, Enum.Font.GothamMedium, C.Green, UDim2.new(0.4, 0, 0, 12), UDim2.new(0.6, -12, 0, 16), Enum.TextXAlignment.Right)
			local started = os.clock()
			onTick(function()
				t.Text = os.date("%H:%M:%S")
				d.Text = fmtDate(os.time())
				sess.Text = "● " .. L("session %s", fmtDuration(os.clock() - started))
			end)
			return base(f, {})
		end

		function host:CreateAnniversaryCard()
			local f = card(70, C.Green)
			text(f, "🎂 " .. L("Account anniversary"), 12, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 8), UDim2.new(0.55, 0, 0, 18))
			local left = 365 - (ageDays % 365)
			text(f, L("%d days left (year %d)", left, math.floor(ageDays / 365) + 1), 11, Enum.Font.GothamMedium, "Sub", UDim2.new(0.45, 0, 0, 8), UDim2.new(0.55, -12, 0, 18), Enum.TextXAlignment.Right)
			local bar = New("Frame", { Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -24, 0, 8), BorderSizePixel = 0, Parent = f }, { Corner(4) })
			bind(bar, "BackgroundColor3", "Off")
			local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Green, BorderSizePixel = 0, Parent = bar }, { Corner(4) })
			Tween(fill, { Size = UDim2.fromScale((ageDays % 365) / 365, 1) }, 0.8)
			return base(f, {})
		end

		function host:CreateGameCard()
			local f = card(70, "accent")
			local icon = New("ImageLabel", {
				Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(54, 54), BorderSizePixel = 0,
				Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150", Parent = f,
			}, { Corner(8) })
			bind(icon, "BackgroundColor3", "Panel")
			local name = text(f, "…", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(72, 8), UDim2.new(1, -80, 0, 18))
			name.TextTruncate = Enum.TextTruncate.AtEnd
			local by = text(f, "", 10, Enum.Font.Gotham, "Sub", UDim2.fromOffset(72, 26), UDim2.new(1, -80, 0, 14))
			local live = text(f, "", 11, Enum.Font.GothamMedium, C.Green, UDim2.fromOffset(72, 44), UDim2.new(1, -80, 0, 16))
			task.spawn(function()
				local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
				if ok and info then
					name.Text = info.Name
					by.Text = L("by %s", (info.Creator and info.Creator.Name) or "?")
				else
					name.Text = game.Name
				end
			end)
			onTick(function()
				live.Text = "● " .. L("%d/%d players - up %s", #Players:GetPlayers(), Players.MaxPlayers, fmtDuration(time()))
			end)
			return base(f, {})
		end

		function host:CreateAccountDetails()
			host:CreateSection(L("Account details"), C.Pink)
			local device = "PC"
			if UIS.TouchEnabled and not UIS.KeyboardEnabled then device = "Phone / Tablet"
			elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then device = "Console" end
			local cam = workspace.CurrentCamera
			if cam then device = device .. " - " .. math.floor(cam.ViewportSize.X) .. "x" .. math.floor(cam.ViewportSize.Y) end
			local locale = "-"
			pcall(function() locale = LocalizationService.RobloxLocaleId end)
			local exec = "-"
			pcall(function()
				if identifyexecutor then
					local a, b = identifyexecutor()
					exec = tostring(a) .. (b and (" " .. tostring(b)) or "")
				end
			end)
			local y, m, d = math.floor(ageDays / 365), math.floor((ageDays % 365) / 30), ageDays % 30
			host:CreateInfoRow("📅", L("Created"), fmtDate(createdAt))
			host:CreateInfoRow("⌛", L("Account age"), L("%dy %dm %dd (%d days)", y, m, d, ageDays))
			host:CreateInfoRow("🌐", L("Locale"), locale)
			host:CreateInfoRow("👥", L("Team"), lp.Team and lp.Team.Name or "-")
			host:CreateInfoRow("💻", L("Device"), device)
			host:CreateInfoRow("🔧", L("Executor"), exec)
		end

		----------------------------------------------------------------
		-- Built-in panels
		----------------------------------------------------------------
		function host:CreateUISettings()
			host:CreateSection(L("Appearance"), C.Purple)
			local themes, accents = {}, {}
			for n in pairs(Lumen.Themes) do themes[#themes + 1] = n end
			for n in pairs(Lumen.Accents) do accents[#accents + 1] = n end
			table.sort(themes)
			table.sort(accents)
			host:CreateDropdown({ Name = L("Theme"), Options = themes, CurrentOption = themeName, Flag = "Lumen_Theme", Callback = function(v) if v then W:SetTheme(v) end end })
			host:CreateDropdown({ Name = L("Accent"), Options = accents, Flag = "Lumen_Accent", Callback = function(v) if v then W:SetAccent(v) end end })
			host:CreateSlider({ Name = L("UI scale"), Range = { 60, 120 }, Increment = 5, Suffix = "%", CurrentValue = 100, Flag = "Lumen_Scale", Callback = function(v) W:SetUIScale(v / 100) end })
			host:CreateSlider({ Name = L("Transparency"), Range = { 0, 60 }, Increment = 1, Suffix = "%", CurrentValue = math.floor(T.WinT * 100 + 0.5), Flag = "Lumen_Transparency", Callback = function(v) W:SetTransparency(v / 100) end })
			host:CreateKeybind({ Name = L("Toggle key"), CurrentKeybind = toggleKey.Name, Flag = "Lumen_ToggleKey", ChangedCallback = function(k) if k then W:SetToggleKey(k) end end })
			host:CreateButton({ Name = L("Destroy UI"), Neon = C.Red, Callback = function()
				W:Dialog({ Title = L("Destroy UI"), Content = L("Are you sure?"), Buttons = {
					{ Name = L("Delete"), Primary = true, Callback = function() W:Destroy() end },
					{ Name = L("Cancel") },
				} })
			end })
		end

		function host:CreateConfigManager()
			host:CreateSection(L("Configs"), C.Purple)
			local nameInput = host:CreateInput({ Name = L("Config name"), PlaceholderText = "default", CurrentValue = "default" })
			local dd
			dd = host:CreateDropdown({
				Name = L("Saved configs"), Options = Lumen:ListConfigs(),
				Callback = function(v) if v then nameInput:Set(v, true) end end,
			})
			local function current()
				local n = nameInput:Get()
				if n == nil or n == "" then n = dd:Get() end
				return (n and n ~= "") and n or nil
			end
			host:CreateButton({ Name = L("Save"), Callback = function()
				local n = current() or "default"
				local ok = Lumen:SaveConfig(n)
				dd:Refresh(Lumen:ListConfigs())
				W:Notify({ Title = L("Configs"), Content = L("Saved") .. ": " .. n, Type = ok and "Success" or "Error" })
			end })
			host:CreateButton({ Name = L("Load"), Callback = function()
				local n = current()
				if not n then return end
				local ok = Lumen:LoadConfig(n)
				W:Notify({ Title = L("Configs"), Content = L("Loaded") .. ": " .. n, Type = ok and "Success" or "Error" })
			end })
			host:CreateButton({ Name = L("Delete"), Neon = C.Red, Callback = function()
				local n = current()
				if not n then return end
				Lumen:DeleteConfig(n)
				dd:Refresh(Lumen:ListConfigs())
				W:Notify({ Title = L("Configs"), Content = L("Deleted") .. ": " .. n })
			end })
			host:CreateButton({ Name = L("Refresh"), Callback = function() dd:Refresh(Lumen:ListConfigs()) end })
		end
	end

	----------------------------------------------------------------------
	-- Tabs
	----------------------------------------------------------------------
	function W:CreateTab(name, icon)
		local Tab = { Name = name }
		local btn = New("TextButton", {
			LayoutOrder = #W.Tabs + 1, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.Off, BackgroundTransparency = 0.65,
			Text = "", AutoButtonColor = false, Parent = Sidebar,
		}, { Corner(10) })
		local bar = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = btn }, { Corner(2) })
		local ic = makeIcon(btn, icon or "•", 24, 40, UDim2.fromOffset(12, 0))
		local tx = New("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -48, 1, 0), Font = Enum.Font.GothamMedium,
			TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = name, Parent = btn,
		})

		local page = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = Pages })
		local Scroll = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = page,
		}, { List(10), Pad(3, 3, 7, 10) })
		Tab.Page = page
		attachElements(Tab, Scroll)

		function Tab:Split(leftWidth)
			Scroll.Visible = false
			leftWidth = leftWidth or 0.46
			local function col(pos, size)
				local s = New("ScrollingFrame", {
					Position = pos, Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
					CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = page,
				}, { List(10), Pad(3, 3, 7, 10) })
				local h = {}
				attachElements(h, s)
				return h
			end
			return col(UDim2.new(0, 0, 0, 0), UDim2.new(leftWidth, -5, 1, 0)), col(UDim2.new(leftWidth, 5, 0, 0), UDim2.new(1 - leftWidth, -5, 1, 0))
		end

		local function paint(active, instant)
			local d = instant and 0 or 0.25
			Tween(btn, { BackgroundColor3 = active and T.Accent or T.Off, BackgroundTransparency = active and 0.42 or 0.75 }, d)
			Tween(bar, { Size = UDim2.fromOffset(3, active and 18 or 0), BackgroundTransparency = active and 0 or 1 }, d)
			local col = active and C.White or T.Sub
			if ic:IsA("TextLabel") then Tween(ic, { TextColor3 = col }, d) else Tween(ic, { ImageColor3 = col }, d) end
			Tween(tx, { TextColor3 = col }, d)
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
		end
		onTheme(function() paint(W.ActiveTab == Tab, true) end)
		btn.MouseButton1Click:Connect(function() Tab:Select() end)
		btn.MouseEnter:Connect(function() if W.ActiveTab ~= Tab then Tween(btn, { BackgroundTransparency = 0.6 }, 0.12) end end)
		btn.MouseLeave:Connect(function() if W.ActiveTab ~= Tab then Tween(btn, { BackgroundTransparency = 0.75 }, 0.12) end end)

		W.Tabs[#W.Tabs + 1] = Tab
		if #W.Tabs == 1 then Tab:Select() end
		return Tab
	end

	function W:CreateHomeTab(name, icon)
		local tab = W:CreateTab(name or "Home", icon or "🏠")
		local left, right = tab:Split(0.46)
		left:CreateProfileCard()
		left:CreateClockCard()
		left:CreateAnniversaryCard()
		right:CreateGameCard()
		right:CreateAccountDetails()
		return tab, left, right
	end

	----------------------------------------------------------------------
	-- Window controls
	----------------------------------------------------------------------
	function W:SetVisible(v)
		if locked and v then return end
		hidden = not v
		if v then
			if not Main.Visible then Scale.Scale = fit() * 0.9 end
			Main.Visible = true
			Tween(Scale, { Scale = fit() }, 0.35, Enum.EasingStyle.Back)
		else
			Tween(Scale, { Scale = fit() * 0.9 }, 0.2)
			task.delay(0.2, function() if hidden then Main.Visible = false end end)
		end
	end
	function W:Toggle() W:SetVisible(hidden) end
	function W:Minimize()
		minimized = not minimized
		Body.Visible = not minimized
		Tween(Main, { Size = UDim2.fromOffset(WIDTH, minimized and TOP or HEIGHT) }, 0.25)
	end
	function W:SetTheme(name)
		if not Lumen.Themes[name] then return end
		loadTheme(name)
		refresh()
	end
	function W:SetAccent(a)
		local col = typeof(a) == "Color3" and a or Lumen.Accents[a]
		if not col then return end
		accentOverride = col
		T.Accent = col
		refresh()
	end
	function W:SetTransparency(t)
		winTOverride = math.clamp(t, 0, 0.9)
		T.WinT = winTOverride
		refresh()
	end
	function W:SetUIScale(s)
		userScale = math.clamp(s, 0.5, 1.5)
		if not hidden then Tween(Scale, { Scale = fit() }, 0.2) end
	end
	function W:SetToggleKey(k)
		if typeof(k) == "EnumItem" then toggleKey = k
		else
			local ok, kc = pcall(function() return Enum.KeyCode[k] end)
			if ok and kc then toggleKey = kc end
		end
	end
	function W:Destroy()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		Gui:Destroy()
		for i, w in ipairs(Lumen.Windows) do
			if w == W then table.remove(Lumen.Windows, i) break end
		end
	end

	-- config helpers -----------------------------------------------------------------
	function W:AutoLoad(name) return Lumen:LoadConfig(name or "autosave") end
	function W:AutoSave(name, interval)
		name = name or "autosave"
		local last
		task.spawn(function()
			while Gui.Parent do
				task.wait(interval or 10)
				local d = {}
				for k, v in pairs(Lumen.Flags) do d[k] = enc(v) end
				local ok, json = pcall(function() return HttpService:JSONEncode(d) end)
				if ok and json ~= last then
					last = json
					Lumen:SaveConfig(name)
				end
			end
		end)
	end

	-- modal dialog ---------------------------------------------------------------------
	function W:Dialog(d)
		d = d or {}
		local overlay = New("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Black,
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50, Parent = Gui,
		})
		Tween(overlay, { BackgroundTransparency = 0.55 }, 0.2)
		local content = d.Content or ""
		local ok, size = pcall(function() return TextService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(260, 1000)) end)
		local bodyH = content == "" and 0 or (ok and size.Y or 30)
		local H = 20 + 22 + 8 + bodyH + 18 + 34 + 16
		local box = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, H),
			BackgroundColor3 = C.White, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 51, Parent = overlay,
		}, { Corner(14), New("UIGradient", { Rotation = 135, Color = ColorSequence.new(T.Window1, T.Window2) }) })
		local bs = New("UIStroke", { Thickness = 1.2, Transparency = 0.8, Parent = box })
		bind(bs, "Color", "Line")
		local sc = New("UIScale", { Parent = box })
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local fitS = math.min(0.9, (vp.X - 40) / 300, (vp.Y - 40) / H)
		sc.Scale = fitS * 0.9
		Tween(sc, { Scale = fitS }, 0.25, Enum.EasingStyle.Back)
		text(box, d.Title or "Notice", 15, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 22))
		if content ~= "" then
			local b = text(box, content, 12, Enum.Font.Gotham, "Sub", UDim2.fromOffset(20, 48), UDim2.new(1, -40, 0, bodyH))
			b.TextWrapped = true
			b.TextYAlignment = Enum.TextYAlignment.Top
		end
		local function close()
			Tween(overlay, { BackgroundTransparency = 1 }, 0.15)
			Tween(sc, { Scale = fitS * 0.9 }, 0.15)
			task.delay(0.16, function() overlay:Destroy() end)
		end
		local btns = d.Buttons or { { Name = "OK", Primary = true } }
		local n = #btns
		local w = (260 - 8 * (n - 1)) / n
		for i, bd in ipairs(btns) do
			local b = New("TextButton", {
				Position = UDim2.fromOffset(20 + (i - 1) * (w + 8), H - 16 - 34), Size = UDim2.fromOffset(w, 34),
				BackgroundTransparency = bd.Primary and 0 or 0.3, Font = Enum.Font.GothamMedium, TextSize = 12,
				Text = bd.Name or "OK", TextColor3 = C.White, AutoButtonColor = false, ZIndex = 52, Parent = box,
			}, { Corner(10) })
			bind(b, "BackgroundColor3", bd.Primary and "Accent" or "Off")
			b.MouseButton1Click:Connect(function()
				close()
				safe(bd.Callback)
			end)
		end
		return { Close = close }
	end

	MinBtn.MouseButton1Click:Connect(function() W:Minimize() end)
	HideBtn.MouseButton1Click:Connect(function()
		W:SetVisible(false)
		local hint = UIS.TouchEnabled and L("Tap the button to reopen.") or L("Press %s to reopen.", toggleKey.Name)
		W:Notify({ Title = L("Hidden"), Content = hint, Duration = 3 })
	end)
	conn(UIS.InputBegan:Connect(function(i, gpe)
		if gpe or Lumen.Listening then return end
		if i.KeyCode == toggleKey then W:Toggle() end
	end))

	if cfg.MobileButton ~= false and UIS.TouchEnabled then
		local mb = New("TextButton", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(44, 44),
			BackgroundTransparency = 0.15, Text = "◆", Font = Enum.Font.GothamMedium, TextSize = 16, TextColor3 = C.White, AutoButtonColor = false, Parent = Gui,
		}, { Corner(22) })
		bind(mb, "BackgroundColor3", "Panel")
		local mbs = New("UIStroke", { Thickness = 2, Parent = mb })
		bind(mbs, "Color", "Accent")
		local startIn, startPos, moved
		mb.InputBegan:Connect(function(i)
			if isPress(i) then startIn, startPos, moved = i.Position, mb.Position, false end
		end)
		conn(UIS.InputChanged:Connect(function(i)
			if startIn and isMove(i) then
				local d = i.Position - startIn
				if d.Magnitude > 8 then moved = true end
				if moved then mb.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end
			end
		end))
		conn(UIS.InputEnded:Connect(function(i)
			if startIn and isPress(i) then
				if not moved then W:Toggle() end
				startIn = nil
			end
		end))
	end

	----------------------------------------------------------------------
	-- Key system (blocks CreateWindow until a valid key is entered)
	----------------------------------------------------------------------
	local function runKeyGate(ks)
		local function trim(x) return (tostring(x):gsub("^%s+", ""):gsub("%s+$", "")) end
		local function norm(x)
			x = trim(x)
			if ks.CaseInsensitive then x = x:lower() end
			return x
		end
		local remote
		local function remoteKeys()
			if remote then return remote end
			remote = {}
			if ks.KeyUrl then
				local ok, body = pcall(function() return game:HttpGet(ks.KeyUrl) end)
				if ok and type(body) == "string" then
					for line in body:gmatch("[^\r\n]+") do
						if trim(line) ~= "" then remote[#remote + 1] = line end
					end
				end
			end
			return remote
		end
		local function check(input)
			local raw = trim(input)
			if raw == "" then return false end
			if type(ks.Check) == "function" then
				local ok, r = pcall(ks.Check, raw)
				if ok and r == true then return true end
			end
			local want = norm(raw)
			for _, k in ipairs(ks.Keys or {}) do
				if norm(k) == want then return true end
			end
			if ks.KeyUrl then
				for _, k in ipairs(remoteKeys()) do
					if norm(k) == want then return true end
				end
			end
			return false
		end

		-- saved key (optionally expiring)
		local file = "Lumen/key_" .. ((cfg.Name or "ui"):gsub("[^%w_]", "_")) .. ".txt"
		if ks.SaveKey and fsOK() then
			local ok, saved = pcall(function() if isfile(file) then return readfile(file) end end)
			if ok and type(saved) == "string" then
				local ts, key = saved:match("^(%d+)\n(.*)$")
				if not ts then ts, key = tostring(os.time()), saved end
				local fresh = not ks.ExpireHours or (os.time() - tonumber(ts)) < ks.ExpireHours * 3600
				if fresh and check(key) then
					safe(ks.OnSuccess, trim(key))
					return true
				end
			end
		end

		locked = true
		local done = Instance.new("BindableEvent")
		local GW, GH = 340, 224
		local gate = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(GW, GH),
			BackgroundColor3 = C.White, BackgroundTransparency = 0.08, BorderSizePixel = 0, Active = true, Parent = Gui,
		}, { Corner(16), New("UIGradient", { Rotation = 135, Color = ColorSequence.new(T.Window1, T.Window2) }) })
		local gs = New("UIStroke", { Thickness = 1.5, Transparency = 0.8, Parent = gate })
		bind(gs, "Color", "Line")
		local gsc = New("UIScale", { Parent = gate })
		do
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
			gsc.Scale = math.min(0.9, (vp.X - 40) / GW, (vp.Y - 40) / GH)
		end
		text(gate, ks.Title or (cfg.Name or "Lumen"), 17, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(20, 14), UDim2.new(1, -60, 0, 24))
		local note = text(gate, ks.Note or L("Enter key"), 12, Enum.Font.Gotham, "Sub", UDim2.fromOffset(20, 40), UDim2.new(1, -40, 0, 30))
		note.TextWrapped = true
		note.TextYAlignment = Enum.TextYAlignment.Top
		local closeB = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamMedium, TextSize = 16, Parent = gate })
		bind(closeB, "TextColor3", "Sub")

		local canPaste = type(getclipboard) == "function"
		local box = New("TextBox", {
			Position = UDim2.fromOffset(20, 80), Size = UDim2.fromOffset(canPaste and 208 or 300, 34), BackgroundTransparency = 0.2, BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium, TextSize = 12, PlaceholderText = L("Enter key"), Text = "", ClearTextOnFocus = false, Parent = gate,
		}, { Corner(8), Pad(10, 0, 10, 0) })
		bind(box, "BackgroundColor3", "Panel")
		bind(box, "TextColor3", "Text")
		bind(box, "PlaceholderColor3", "Sub")
		local status = text(gate, "", 11, Enum.Font.GothamMedium, C.Red, UDim2.fromOffset(20, 120), UDim2.new(1, -40, 0, 16))

		local function gbtn(label, x, y, w, h, accent)
			local b = New("TextButton", {
				Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = accent and 0 or 0.3,
				Font = Enum.Font.GothamMedium, TextSize = 12, Text = label, AutoButtonColor = false, TextColor3 = C.White, Parent = gate,
			}, { Corner(10) })
			bind(b, "BackgroundColor3", accent and "Accent" or "Off")
			return b
		end
		if canPaste then
			gbtn(L("Paste"), 236, 80, 84, 34, false).MouseButton1Click:Connect(function()
				local ok, clip = pcall(getclipboard)
				if ok and clip then box.Text = trim(clip) end
			end)
		end
		local hasLink = ks.Link ~= nil
		local bw = hasLink and 146 or 300
		local submit = gbtn(L("Submit"), 20, GH - 52, bw, 36, true)
		if hasLink then
			gbtn(L("Get key"), 174, GH - 52, bw, 36, false).MouseButton1Click:Connect(function()
				if type(setclipboard) == "function" then
					pcall(setclipboard, ks.Link)
					status.TextColor3 = C.Green
					status.Text = L("Copied")
				else
					status.TextColor3 = C.Gold
					status.Text = ks.Link
				end
			end)
		end

		local attempts, lockedUntil = 0, 0
		local busy = false
		local function try()
			if busy or os.clock() < lockedUntil then return end
			busy = true
			if check(box.Text) then
				if ks.SaveKey and fsOK() then
					ensureFolder()
					pcall(writefile, file, os.time() .. "\n" .. trim(box.Text))
				end
				status.TextColor3 = C.Green
				status.Text = L("Key accepted")
				task.wait(0.35)
				done:Fire(true)
				return
			end
			attempts = attempts + 1
			status.TextColor3 = C.Red
			if ks.MaxAttempts and attempts >= ks.MaxAttempts then
				attempts = 0
				lockedUntil = os.clock() + (ks.Cooldown or 15)
				task.spawn(function()
					while os.clock() < lockedUntil and gate.Parent do
						status.Text = L("Wrong key") .. " - " .. math.ceil(lockedUntil - os.clock()) .. "s"
						task.wait(0.25)
					end
					if gate.Parent then status.Text = "" end
				end)
			else
				status.Text = L("Wrong key") .. (ks.MaxAttempts and (" (" .. (ks.MaxAttempts - attempts) .. ")") or "")
			end
			local p = gate.Position
			for _, dx in ipairs({ 8, -8, 5, -5, 0 }) do
				Tween(gate, { Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset) }, 0.05)
				task.wait(0.05)
			end
			busy = false
		end
		submit.MouseButton1Click:Connect(try)
		box.FocusLost:Connect(function(enter) if enter then try() end end)
		closeB.MouseButton1Click:Connect(function() done:Fire(false) end)
		local ok = done.Event:Wait()
		done:Destroy()
		if not ok then
			W:Destroy()
			error("[Lumen] key window closed", 0)
		end
		gate:Destroy()
		locked = false
		safe(ks.OnSuccess, trim(box.Text))
		return true
	end

	if cfg.KeySystem then runKeyGate(cfg.KeySystem) end

	Lumen.Windows[#Lumen.Windows + 1] = W
	task.defer(function() W:SetVisible(true) end)
	return W
end

return Lumen
