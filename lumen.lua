-- Lumen v2.1 | Glass + Blue Only | Cleaned & Working
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService")

local Lumen = {
	Version = "2.1.0",
	Flags = {},
	Options = {},
	Windows = {},
	Listening = false
}

local rgb = Color3.fromRGB
local C = {
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	Green = rgb(72, 182, 128),
	Gold = rgb(214, 174, 72),
	Red = rgb(204, 78, 86)
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
	Accent = BLUE
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
		PaddingBottom = UDim.new(0, b)
	})
end

local function List(pad, hor)
	return New("UIListLayout", {
		Padding = UDim.new(0, pad or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = hor and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
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
	if type(fn) \~= "function" then
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

local function fsOK()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
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
	if type(delfile) \~= "function" then
		return false
	end
	return (pcall(delfile, cfgPath(name)))
end

function Lumen:ListConfigs()
	local out = {}
	if type(listfiles) \~= "function" then
		return out
	end
	local ok, files = pcall(listfiles, "Lumen")
	if ok and type(files) == "table" then
		for _, p in ipairs(files) do
			local n = p:match("([^/\\]+)%.json$")
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

function Lumen:CreateWindow(cfg)
	cfg = cfg or {}
	local W = { Tabs = {} }
	local lp = Players.LocalPlayer

	local function L(k, ...)
		if select("#", ...) > 0 then
			local ok, r = pcall(string.format, k, ...)
			return ok and r or k
		end
		return k
	end

	local function fmtDate(t)
		return os.date("%A, %d %B %Y", t)
	end

	local function dayName(t)
		return os.date("%A", t)
	end

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
				Fn = fn,
				Kind = kind or "Action"
			}
		end
	end

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
		Parent = parent
	})
	Gui:SetAttribute("LumenId", cfg.Name or "Lumen")
	W.Gui = Gui

	local function text(par, t, size, font, color, pos, sz, align)
		local l = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = pos or UDim2.fromOffset(12, 0),
			Size = sz or UDim2.new(1, -24, 1, 0),
			Font = font or Enum.Font.GothamMedium,
			TextSize = math.max((size or 13) - 1, 9),
			TextXAlignment = align or Enum.TextXAlignment.Left,
			Text = t,
			Parent = par
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
			Parent = par
		})
	end

	local function makeIcon(par, ic, w, h, pos)
		local isImg = type(ic) == "number" or (type(ic) == "string" and (ic:find("^rbxasset") \~= nil or ic:find("^rbxthumb") \~= nil))
		if isImg then
			return New("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.new(pos.X.Scale, pos.X.Offset + (w - 18) / 2, pos.Y.Scale, pos.Y.Offset + (h - 18) / 2),
				Image = type(ic) == "number" and ("rbxassetid://" .. ic) or ic,
				Parent = par
			})
		end
		return New("TextLabel", {
			BackgroundTransparency = 1,
			Position = pos,
			Size = UDim2.fromOffset(w, h),
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			Text = tostring(ic or "-"),
			Parent = par
		})
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
	local locked = false
	local blur
	if cfg.Blur \~= false then
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
		Parent = Gui
	}, { Corner(24) })
	bind(Main, "BackgroundTransparency", "WinT")

	local grad = New("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(T.Window1, T.Window2),
		Parent = Main
	})

	local mainStroke = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1.5,
		Parent = Main
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

	local function saveWin()
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
			tab = W.ActiveTab and W.ActiveTab.Name or nil
		}
		pcall(writefile, winFile, HttpService:JSONEncode(d))
	end

	local Topbar = New("Frame", {
		Size = UDim2.new(1, 0, 0, TOP),
		BackgroundTransparency = 1,
		Parent = Main
	})

	local titleX = 20
	if cfg.Icon then
		local ti = makeIcon(Topbar, cfg.Icon, 28, 28, UDim2.fromOffset(16, 14))
		if ti:IsA("TextLabel") then
			bind(ti, "TextColor3", "Text")
		end
		titleX = 52
	end

	text(Topbar, cfg.Name or "Lumen", 20, Enum.Font.GothamBold, "Text", UDim2.fromOffset(titleX, cfg.Subtitle and 10 or 17), UDim2.new(0.6, 0, 0, 24))
	text(Topbar, string.upper(cfg.Subtitle or ""), 10, Enum.Font.GothamMedium, "Sub", UDim2.fromOffset(titleX, 33), UDim2.new(0.6, 0, 0, 14))

	local line = New("Frame", {
		Position = UDim2.new(0, 16, 1, -1),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Parent = Topbar
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
			Parent = Topbar
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

	local HideBtn = circleBtn("▢", -14)
	local MinBtn = circleBtn("–", -50)

	do
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
				Main.Position = UDim2.new(
					sp.X.Scale,
					math.clamp(sp.X.Offset + d.X, -vp.X * sp.X.Scale + 60, vp.X * (1 - sp.X.Scale) - 60),
					sp.Y.Scale,
					math.clamp(sp.Y.Offset + d.Y, -vp.Y * sp.Y.Scale + 40, vp.Y * (1 - sp.Y.Scale) - 40)
				)
			end
		end))
		conn(UIS.InputEnded:Connect(function(i)
			if isPress(i) then
				if dragging then
					dragging = false
					saveWin()
				end
			end
		end))
	end

	local FOOT = cfg.StatusBar == false and 0 or 32
	local Body = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TOP + 8),
		Size = UDim2.new(1, 0, 1, -(TOP + 8)),
		Parent = Main
	})

	local SideWrap = New("Frame", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0, 150, 1, -14 - FOOT),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = Body
	}, { Corner(18) })
	bind(SideWrap, "BackgroundColor3", "Card")
	bind(SideWrap, "BackgroundTransparency", "PanT")

	local sideStroke = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1.2,
		Parent = SideWrap
	})
	bind(sideStroke, "Color", "Line")
	bind(sideStroke, "Transparency", "LineT")

	local showChip = cfg.SidebarProfile \~= false
	local Sidebar = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, showChip and -52 or 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = SideWrap
	}, { Pad(8, 8, 8, 8), List(6) })

	if showChip then
		local chip = New("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundTransparency = 1,
			Parent = SideWrap
		})
		local cl = New("Frame", {
			Size = UDim2.new(1, -16, 0, 1),
			Position = UDim2.fromOffset(8, 0),
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			Parent = chip
		})
		bind(cl, "BackgroundColor3", "Line")

		local av = New("ImageLabel", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(32, 32),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = chip
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
		Parent = Body
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

	if FOOT > 0 then
		local sb = New("Frame", {
			Position = UDim2.new(0, 14, 1, -38),
			Size = UDim2.new(1, -28, 0, 26),
			BorderSizePixel = 0,
			Parent = Body
		}, { Corner(13) })
		bind(sb, "BackgroundColor3", "Card")
		bind(sb, "BackgroundTransparency", "PanT")

		local sbs = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.2,
			Parent = sb
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
			Parent = sb
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
				gameName
			}, "  |  ")
		end)
	end

	local NotifHolder = New("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(290, 500),
		BackgroundTransparency = 1,
		Parent = Gui
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder
		})
	})

	local TYPE_COLORS = {
		Success = C.Green,
		Warning = C.Gold,
		Error = C.Red
	}

	function W:Notify(n)
		if type(n) \~= "table" then
			n = { Content = tostring(n) }
		end
		local content = n.Content or ""
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
		if content \~= "" then
			local ok, size = pcall(function()
				return TextService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(256, 1000))
			end)
			bodyH = ok and size.Y or 15 * math.ceil(#content / 38)
		end

		local wrap = New("Frame", {
			Size = UDim2.new(1, 0, 0, 30 + bodyH + 14),
			BackgroundTransparency = 1,
			Parent = NotifHolder
		})

		local c = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Position = UDim2.new(1, 320, 0, 0),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = wrap
		}, { Corner(12) })
		bind(c, "BackgroundColor3", "Panel")

		local st = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.2,
			Parent = c
		})
		bind(st, "Color", "Line")
		bind(st, "Transparency", "LineT")

		local tc = TYPE_COLORS[n.Type]
		local bar = New("Frame", {
			Position = UDim2.fromOffset(8, 10),
			Size = UDim2.new(0, 3, 1, -20),
			BorderSizePixel = 0,
			Parent = c
		}, { Corner(2) })

		local timer = New("Frame", {
			Position = UDim2.new(0, 0, 1, -2),
			Size = UDim2.new(1, 0, 0, 2),
			BorderSizePixel = 0,
			BackgroundTransparency = 0.3,
			Parent = c
		})

		if tc then
			bar.BackgroundColor3 = tc
			timer.BackgroundColor3 = tc
		else
			bind(bar, "BackgroundColor3", "Accent")
			bind(timer, "BackgroundColor3", "Accent")
		end

		text(c, n.Title or "Notice", 14, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(20, 8), UDim2.new(1, -30, 0, 18))
		if content \~= "" then
			local b = text(c, content, 12, Enum.Font.Gotham, "Sub", UDim2.fromOffset(20, 28), UDim2.new(1, -34, 0, bodyH))
			b.TextWrapped = true
			b.TextYAlignment = Enum.TextYAlignment.Top
		end

		local gone = false
		local function dismiss()
			if gone or not c.Parent then
				return
			end
			gone = true
			Tween(c, { Position = UDim2.new(1, 320, 0, 0) }, 0.3)
			task.delay(0.3, function()
				wrap:Destroy()
			end)
		end

		c.MouseButton1Click:Connect(dismiss)
		local dur = n.Duration or 4
		Tween(c, { Position = UDim2.new() }, 0.4, Enum.EasingStyle.Back)
		Tween(timer, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
		task.delay(dur, dismiss)
	end

	local function attachElements(host, container)
		local function card(h, neon)
			local f = New("Frame", {
				Size = UDim2.new(1, 0, 0, h),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = container
			}, { Corner(10) })
			bind(f, "BackgroundColor3", "Card")
			bind(f, "BackgroundTransparency", "CardT")

			local s = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1.5,
				Parent = f
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
				Parent = f
			}, { Corner(2) })
			if typeof(neon) \~= "Color3" then
				bind(bar, "BackgroundColor3", "Accent")
			end
			text(f, string.upper(title or "Section"), 11, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(22, 0), UDim2.new(1, -30, 1, 0))
			return base(f, {})
		end

		function host:CreateFolder(name, startOpen)
			local f = card(36)
			local open = startOpen == true
			text(f, tostring(name), 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(1, -44, 0, 36))
			local arrow = text(f, "▾", 14, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -26, 0, 0), UDim2.fromOffset(16, 36), Enum.TextXAlignment.Center)
			local inner = New("Frame", {
				Position = UDim2.fromOffset(0, 40),
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				Parent = f
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
				end
			})
		end

		function host:CreateParagraph(c)
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
				Parent = f
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
				Parent = f
			})
			bind(b, "TextColor3", "Sub")

			return base(f, {
				Set = function(_, n)
					t.Text = n.Title or t.Text
					b.Text = n.Content or b.Text
				end
			})
		end

		function host:CreateDivider()
			local d = New("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				Parent = container
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
				end
			})
		end

		function host:CreateButton(c)
			local f = card(c.Description and 54 or 40, c.Neon)
			named(f, c.Name or "Button", c.Description, 36)
			local ch = text(f, "›", 20, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -28, 0, 0), UDim2.new(0, 16, 1, 0), Enum.TextXAlignment.Center)
			local ring = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(),
				BackgroundTransparency = 1,
				Parent = f
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
				if UIS:GetLastInputType() \~= Enum.UserInputType.Touch then
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
				Parent = f
			}, { Corner(11) })

			local knob = New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = C.White,
				BorderSizePixel = 0,
				Parent = track
			}, { Corner(8) })

			local h = hit(f)
			hover(f, h)

			local o = { CurrentValue = c.CurrentValue == true }

			local function render(instant)
				local d = instant and 0 or 0.2
				Tween(track, { BackgroundColor3 = o.CurrentValue and T.Accent or T.Off }, d)
				Tween(knob, {
					Position = o.CurrentValue and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
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
				Parent = f
			})
			bind(val, "TextColor3", "Sub")

			local track = New("Frame", {
				Position = UDim2.new(0, 12, 1, -20),
				Size = UDim2.new(1, -24, 0, 7),
				BorderSizePixel = 0,
				Parent = f
			}, { Corner(4) })
			bind(track, "BackgroundColor3", "Off")

			local fill = New("Frame", {
				Size = UDim2.fromScale(0, 1),
				BorderSizePixel = 0,
				Parent = track
			}, { Corner(4) })
			bind(fill, "BackgroundColor3", "Accent")

			New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = C.White,
				BorderSizePixel = 0,
				Parent = fill
			}, { Corner(7) })

			local o = { CurrentValue = c.CurrentValue or min }
			local lastFire, fireId = 0, 0

			val.Focused:Connect(function()
				val.Text = tostring(o.CurrentValue)
			end)

			val.FocusLost:Connect(function()
				local n = tonumber(val.Text)
				if n then
					o:Set(n)
				else
					o:Set(o.CurrentValue, true)
				end
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

			local area = New("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Position = UDim2.new(0, 0, 1, -34),
				Size = UDim2.new(1, 0, 0, 34),
				Parent = f
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
			text(f, c.Name or "Progress", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 5), UDim2.new(0.6, 0, 0, 20))
			local val = text(f, "", 12, Enum.Font.GothamMedium, "Sub", UDim2.new(0.4, -12, 0, 5), UDim2.new(0.6, 0, 0, 20), Enum.TextXAlignment.Right)

			local track = New("Frame", {
				Position = UDim2.new(0, 12, 1, -16),
				Size = UDim2.new(1, -24, 0, 7),
				BorderSizePixel = 0,
				Parent = f
			}, { Corner(4) })
			bind(track, "BackgroundColor3", "Off")

			local fill = New("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = c.Color or T.Accent,
				BorderSizePixel = 0,
				Parent = track
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
			local multi = c.MultipleOptions == true
			local options = c.Options or {}
			local f = card(40, c.Neon)

			text(f, c.Name or "Dropdown", 13, Enum.Font.GothamMedium, "Text", UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 0, 40))
			local cur = text(f, "", 12, Enum.Font.GothamMedium, "Sub", UDim2.new(0.5, -34, 0, 0), UDim2.new(0.5, 0, 0, 40), Enum.TextXAlignment.Right)
			cur.TextTruncate = Enum.TextTruncate.AtEnd
			local arrow = text(f, "▾", 14, Enum.Font.GothamMedium, "Sub", UDim2.new(1, -26, 0, 0), UDim2.fromOffset(16, 40), Enum.TextXAlignment.Center)

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
				Parent = f
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
				Parent = f
			}, { List(3) })

			local head = hit(f, 40)
			hover(f, head)

			local o = { Open = false, Options = options }
			local sel, buttons, visibleCount = {}, {}, 0

			if type(c.CurrentOption) == "table" then
				for _, v in ipairs(c.CurrentOption) do
					sel[v] = true
				end
			elseif c.CurrentOption \~= nil then
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
					cur.Text = v \~= nil and tostring(v) or "None"
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
						local show = q == "" or tostring(op):lower():find(q, 1, true) \~= nil
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
						Parent = list
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
				elseif v \~= nil then
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
				if not o.Open then
					for _, other in ipairs(W._dropdowns) do
						if other \~= o and other.Frame and other.Frame.Parent then
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
				Parent = f
			}, { Corner(6), Pad(8, 0, 24, 0) })

			if c.Password then
				box.Text = string.rep("•", #box.Text)
			end

			bind(box, "BackgroundColor3", "Panel")
			bind(box, "TextColor3", "Text")
			bind(box, "PlaceholderColor3", "Sub")

			local s = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1,
				Transparency = 0.85,
				Parent = box
			})
			bind(s, "Color", "Line")

			box.Focused:Connect(function()
				Tween(s, { Color = T.Accent, Transparency = 0 }, 0.15)
			end)

			local clr = New("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 20, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Text = "×",
				Font = Enum.Font.GothamMedium,
				TextSize = 14,
				AutoButtonColor = false,
				Visible = box.Text \~= "",
				Parent = box
			})
			bind(clr, "TextColor3", "Sub")

			box:GetPropertyChangedSignal("Text"):Connect(function()
				clr.Visible = box.Text \~= ""
			end)

			clr.MouseButton1Click:Connect(function()
				box.Text = ""
				box:CaptureFocus()
			end)

			local o = { CurrentValue = c.CurrentValue or "" }

			box.FocusLost:Connect(function()
				Tween(s, { Color = T.Line, Transparency = 0.85 }, 0.15)
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

			function o:Set(t, silent)
				t = tostring(t)
				o.CurrentValue = t
				box.Text = c.Password and string.rep("•", #t) or t
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

			reg(c.Flag, o, o.CurrentValue)
			return base(f, o)
		end

		function host:CreateKeybind(c)
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
				Text = c.CurrentKeybind or "None",
				Parent = f
			}, { Corner(6) })
			bind(b, "BackgroundColor3", "Panel")
			bind(b, "TextColor3", "Sub")

			```lua
-- Lumen v2.1 | Glass + Blue Only | Cleaned & Working
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService")

local Lumen = {
	Version = "2.1.0",
	Flags = {},
	Options = {},
	Windows = {},
	Listening = false
}

local rgb = Color3.fromRGB
local C = {
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	Green = rgb(72, 182, 128),
	Gold = rgb(214, 174, 72),
	Red = rgb(204, 78, 86)
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
	Accent = BLUE
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
		PaddingBottom = UDim.new(0, b)
	})
end

local function List(pad, hor)
	return New("UIListLayout", {
		Padding = UDim.new(0, pad or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = hor and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
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
	if type(fn) \~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Lumen] " .. tostring(err))
	end
end

local function guiParent()
	local ok, ui = pcall(function()
		return gethui and gethui()
	end)
	if ok and ui then return ui end

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

local function fsOK()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
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

function Lumen:SaveConfig(name)
	if not fsOK() then return false end
	local d = {}
	for k, v in pairs(Lumen.Flags) do
		d[k] = enc(v)
	end
	ensureFolder()
	return (pcall(writefile, cfgPath(name), HttpService:JSONEncode(d)))
end

function Lumen:LoadConfig(name)
	if not fsOK() then return false end
	local path = cfgPath(name)
	if not isfile(path) then return false end
	local ok, d = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok then return false end
	for k, v in pairs(d) do
		local o = Lumen.Options[k]
		if o and o.Set then
			pcall(o.Set, o, dec(v))
		end
	end
	return true
end

function Lumen:DeleteConfig(name)
	if type(delfile) \~= "function" then return false end
	return (pcall(delfile, cfgPath(name)))
end

function Lumen:ListConfigs()
	local out = {}
	if type(listfiles) \~= "function" then return out end
	local ok, files = pcall(listfiles, "Lumen")
	if ok and type(files) == "table" then
		for _, p in ipairs(files) do
			local n = p:match("([^/\\]+)%.json$")
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

function Lumen:CreateWindow(cfg)
	cfg = cfg or {}
	local W = { Tabs = {} }
	local lp = Players.LocalPlayer

	local function L(k, ...)
		if select("#", ...) > 0 then
			local ok, r = pcall(string.format, k, ...)
			return ok and r or k
		end
		return k
	end

	local function fmtDate(t)
		return os.date("%A, %d %B %Y", t)
	end

	local function dayName(t)
		return os.date("%A", t)
	end

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
			if b[1]:IsDescendantOf(Gui20),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.TextDark,
        TextSize = 22
    })
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {TextColor3 = Theme.Error}, 0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {TextColor3 = Theme.TextDark}, 0.15) end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    local MinimizeBtn = Create("TextButton", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -64, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "–",
        TextColor3 = Theme.TextDark,
        TextSize = 20
    })

    MakeDraggable(Main, TitleBar)

    -- Tab Container
    local TabContainer = Create("Frame", {
        Parent = Main,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 140, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BorderSizePixel = 0
    })

    local TabList = Create("ScrollingFrame", {
        Parent = TabContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 8),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        BorderSizePixel = 0
    })
    Create("UIListLayout", {
        Parent = TabList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    local ContentContainer = Create("Frame", {
        Parent = Main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -150, 1, -52),
        Position = UDim2.new(0, 148, 0, 48),
        BorderSizePixel = 0
    })

    local Window = {
        Tabs = {},
        CurrentTab = nil,
        ScreenGui = ScreenGui,
        Main = Main
    }

    function Window:CreateTab(name, icon)
        local TabBtn = Create("TextButton", {
            Parent = TabList,
            BackgroundColor3 = Theme.Tertiary,
            Size = UDim2.new(0.9, 0, 0, 36),
            Font = Enum.Font.GothamMedium,
            Text = "  " .. (name or "Tab"),
            TextColor3 = Theme.TextDark,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 8)})

        local TabContent = Create("ScrollingFrame", {
            Parent = ContentContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false
        })
        local ContentLayout = Create("UIListLayout", {
            Parent = TabContent,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
        end)

        local Tab = {
            Button = TabBtn,
            Content = TabContent,
            Sections = {}
        }

        TabBtn.MouseButton1Click:Connect(function()
            if Window.CurrentTab then
                Window.CurrentTab.Content.Visible = false
                Tween(Window.CurrentTab.Button, {BackgroundColor3 = Theme.Tertiary, TextColor3 = Theme.TextDark}, 0.2)
            end
            TabContent.Visible = true
            Tween(TabBtn, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}, 0.2)
            Window.CurrentTab = Tab
        end)

        TabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab \~= Tab then
                Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(48, 48, 60)}, 0.15)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab \~= Tab then
                Tween(TabBtn, {BackgroundColor3 = Theme.Tertiary}, 0.15)
            end
        end)

        -- Auto select first tab
        if not Window.CurrentTab then
            TabContent.Visible = true
            TabBtn.BackgroundColor3 = Theme.Accent
            TabBtn.TextColor3 = Theme.Text
            Window.CurrentTab = Tab
        end

        function Tab:CreateSection(title)
            local Section = Create("Frame", {
                Parent = TabContent,
                BackgroundColor3 = Theme.Secondary,
                Size = UDim2.new(1, -10, 0, 40),
                BorderSizePixel = 0
            })
            Create("UICorner", {Parent = Section, CornerRadius = UDim.new(0, 10)})
            Create("UIStroke", {Parent = Section, Color = Theme.Border, Thickness = 1})

            local SectionTitle = Create("TextLabel", {
                Parent = Section,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 8),
                Size = UDim2.new(1, -28, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = title or "Section",
                TextColor3 = Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local SectionContent = Create("Frame", {
                Parent = Section,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 34),
                Size = UDim2.new(1, -20, 0, 0)
            })
            local SecLayout = Create("UIListLayout", {
                Parent = SectionContent,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8)
            })

            local function UpdateSectionSize()
                local h = SecLayout.AbsoluteContentSize.Y + 46
                Section.Size = UDim2.new(1, -10, 0, h)
                SectionContent.Size = UDim2.new(1, -20, 0, SecLayout.AbsoluteContentSize.Y)
            end
            SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSectionSize)

            local SectionAPI = {}

            function SectionAPI:AddLabel(text)
                local Label = Create("TextLabel", {
                    Parent = SectionContent,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    Font = Enum.Font.Gotham,
                    Text = text or "Label",
                    TextColor3 = Theme.TextDark,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                UpdateSectionSize()
                return Label
            end

            function SectionAPI:AddButton(text, callback)
                local Btn = Create("TextButton", {
                    Parent = SectionContent,
                    BackgroundColor3 = Theme.Tertiary,
                    Size = UDim2.new(1, 0, 0, 34),
                    Font = Enum.Font.GothamMedium,
                    Text = text or "Button",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                })
                Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 8)})

                Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.Accent}, 0.2) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.Tertiary}, 0.2) end)
                Btn.MouseButton1Click:Connect(function()
                    if callback then
                        task.spawn(callback)
                    end
                end)
                UpdateSectionSize()
                return Btn
            end

            function SectionAPI:AddToggle(text, default, callback)
                default = default or false
                local ToggleFrame = Create("Frame", {
                    Parent = SectionContent,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32)
                })

                local ToggleLabel = Create("TextLabel", {
                    Parent = ToggleFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = text or "Toggle",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local ToggleBtn = Create("Frame", {
                    Parent = ToggleFrame,
                    BackgroundColor3 = default and Theme.Accent or Theme.Tertiary,
                    Position = UDim2.new(1, -44, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20),
                    BorderSizePixel = 0
                })
                Create("UICorner", {Parent = ToggleBtn, CornerRadius = UDim.new(1, 0)})

                local Circle = Create("Frame", {
                    Parent = ToggleBtn,
                    BackgroundColor3 = Theme.Text,
                    Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16),
                    BorderSizePixel = 0
                })
                Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1, 0)})

                local toggled = default
                local ClickBtn = Create("TextButton", {
                    Parent = ToggleFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })

                ClickBtn.MouseButton1Click:Connect(function()
                    toggled = not toggled
                    Tween(ToggleBtn, {BackgroundColor3 = toggled and Theme.Accent or Theme.Tertiary}, 0.2)
                    Tween(Circle, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
                    if callback then
                        task.spawn(callback, toggled)
                    end
                end)

                UpdateSectionSize()
                return {
                    Set = function(val)
                        toggled = val
                        Tween(ToggleBtn, {BackgroundColor3 = toggled and Theme.Accent or Theme.Tertiary}, 0.2)
                        Tween(Circle, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
                    end,
                    Get = function() return toggled end
                }
            end

            function SectionAPI:AddSlider(text, min, max, default, callback)
                min = min or 0
                max = max or 100
                default = default or min

                local SliderFrame = Create("Frame", {
                    Parent = SectionContent,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 50)
                })

                local SliderLabel = Create("TextLabel", {
                    Parent = SliderFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = text or "Slider",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local ValueLabel = Create("TextLabel", {
                    Parent = SliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -45, 0, 0),
                    Size = UDim2.new(0, 45, 0, 20),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(default),
                    TextColor3 = Theme.Accent,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right
                })

                local Track = Create("Frame", {
                    Parent = SliderFrame,
                    BackgroundColor3 = Theme.Tertiary,
                    Position = UDim2.new(0, 0, 0, 28),
                    Size = UDim2.new(1, 0, 0, 8),
                    BorderSizePixel = 0
                })
                Create("UICorner", {Parent = Track, CornerRadius = UDim.new(1, 0)})

                local Fill = Create("Frame", {
                    Parent = Track,
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BorderSizePixel = 0
                })
                Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

                local Knob = Create("Frame", {
                    Parent = Track,
                    BackgroundColor3 = Theme.Text,
                    Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
                    Size = UDim2.new(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    ZIndex = 2
                })
                Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})

                local sliding = false
                local function Update(input)
                    local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + (max - min) * pos)
                    Fill.Size = UDim2.new(pos, 0, 1, 0)
                    Knob.Position = UDim2.new(pos, -6, 0.5, -6)
                    ValueLabel.Text = tostring(value)
                    if callback then
                        task.spawn(callback, value)
                    end
                end

                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        Update(input)
                    end
                end)
                Track.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        Update(input)
                    end
                end)

                UpdateSectionSize()
                return {
                    Set = function(val)
                        val = math.clamp(val, min, max)
                        local pos = (val - min) / (max - min)
                        Fill.Size = UDim2.new(pos, 0, 1, 0)
                        Knob.Position = UDim2.new(pos, -6, 0.5, -6)
                        ValueLabel.Text = tostring(val)
                    end
                }
            end

            function SectionAPI:AddDropdown(text, options, default, callback)
                options = options or {"Option 1", "Option 2"}
                default = default or options[1]

                local DropFrame = Create("Frame", {
                    Parent = SectionContent,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    ClipsDescendants = false
                })

                local DropBtn = Create("TextButton", {
                    Parent = DropFrame,
                    BackgroundColor3 = Theme.Tertiary,
                    Size = UDim2.new(1, 0, 0, 34),
                    Font = Enum.Font.Gotham,
                    Text = "  " .. (default or "Select"),
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                })
                Create("UICorner", {Parent = DropBtn, CornerRadius = UDim.new(0, 8)})

                local Arrow = Create("TextLabel", {
                    Parent = DropBtn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -28, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = "▼",
                    TextColor3 = Theme.TextDark,
                    TextSize = 10
                })

                local DropList = Create("Frame", {
                    Parent = DropFrame,
                    BackgroundColor3 = Theme.Secondary,
                    Position = UDim2.new(0, 0, 0, 38),
                    Size = UDim2.new(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 10,
                    Visible = false
                })
                Create("UICorner", {Parent = DropList, CornerRadius = UDim.new(0, 8)})
                Create("UIStroke", {Parent = DropList, Color = Theme.Border, Thickness = 1})

                local ListLayout = Create("UIListLayout", {
                    Parent = DropList,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2)
                })

                local open = false
                local function ToggleDrop()
                    open = not open
                    DropList.Visible = true
                    local targetH = open and (#options * 30 + 8) or 0
                    Tween(DropList, {Size = UDim2.new(1, 0, 0, targetH)}, 0.25)
                    Arrow.Text = open and "▲" or "▼"
                    if not open then
                        task.delay(0.25, function() DropList.Visible = false end)
                    end
                end

                DropBtn.MouseButton1Click:Connect(ToggleDrop)

                for _, opt in ipairs(options) do
                    local OptBtn = Create("TextButton", {
                        Parent = DropList,
                        BackgroundColor3 = Theme.Tertiary,
                        Size = UDim2.new(1, -6, 0, 28),
                        Position = UDim2.new(0, 3, 0, 0),
                        Font = Enum.Font.Gotham,
                        Text = "  " .. opt,
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        ZIndex = 11
                    })
                    Create("UICorner", {Parent = OptBtn, CornerRadius = UDim.new(0, 6)})

                    OptBtn.MouseEnter:Connect(function() Tween(OptBtn, {BackgroundColor3 = Theme.Accent}, 0.15) end)
                    OptBtn.MouseLeave:Connect(function() Tween(OptBtn, {BackgroundColor3 = Theme.Tertiary}, 0.15) end)
                    OptBtn.MouseButton1Click:Connect(function()
                        DropBtn.Text = "  " .. opt
                        ToggleDrop()
                        if callback then
                            task.spawn(callback, opt)
                        end
                    end)
                end

                UpdateSectionSize()
                return {
                    Set = function(val)
                        DropBtn.Text = "  " .. tostring(val)
                    end
                }
            end

            function SectionAPI:AddKeybind(text, default, callback)
                local KeyFrame = Create("Frame", {
                    Parent = SectionContent,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32)
                })

                local KeyLabel = Create("TextLabel", {
                    Parent = KeyFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -90, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = text or "Keybind",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local KeyBtn = Create("TextButton", {
                    Parent = KeyFrame,
                    BackgroundColor3 = Theme.Tertiary,
                    Position = UDim2.new(1, -80, 0.5, -12),
                    Size = UDim2.new(0, 76, 0, 24),
                    Font = Enum.Font.GothamMedium,
                    Text = default and default.Name or "None",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                })
                Create("UICorner", {Parent = KeyBtn, CornerRadius = UDim.new(0, 6)})

                local listening = false
                local currentKey = default

                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBtn.Text = "..."
                    KeyBtn.TextColor3 = Theme.Accent
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening and not gpe then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            KeyBtn.Text = input.KeyCode.Name
                            KeyBtn.TextColor3 = Theme.Text
                            listening = false
                            if callback then
                                task.spawn(callback, currentKey)
                            end
                        end
                    elseif currentKey and input.KeyCode == currentKey and not gpe then
                        if callback then
                            task.spawn(callback, currentKey)
                        end
                    end
                end)

                UpdateSectionSize()
                return {
                    Set = function(key)
                        currentKey = key
                        KeyBtn.Text = key and key.Name or "None"
                    end,
                    Get = function() return currentKey end
                }
            end

            UpdateSectionSize()
            table.insert(Tab.Sections, SectionAPI)
            return SectionAPI
        end

        table.insert(Window.Tabs, Tab)
        TabList.CanvasSize = UDim2.new(0, 0, 0, TabList.UIListLayout.AbsoluteContentSize.Y + 20)
        return Tab
    end

    -- Minimize logic
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(Main, {Size = UDim2.new(0, windowSize.X.Offset, 0, 42)}, 0.3)
        else
            Tween(Main, {Size = windowSize}, 0.3)
        end
    end)

    return Window
end

return Lumen
