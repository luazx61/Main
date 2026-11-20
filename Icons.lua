-- Lumen icon pack: maps names to rbxassetid numbers.
-- Replace the 0s with your own uploaded icon IDs (white/transparent PNGs tint best).
-- Usage:
--   local Lumen = loadstring(game:HttpGet(BASE .. "Lumen.lua"))()
--   loadstring(game:HttpGet(BASE .. "icons/Icons.lua"))()(Lumen)
return function(Lumen)
	Lumen:SetIcons({
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
	})
end
