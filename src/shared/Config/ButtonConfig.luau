-- Configuration unifiée des boutons pour machines et décorations
local ButtonConfig = {
	-- Boutons pour machines (IDs 1-999)
	[1] = {
		Type = "Machine",
		TargetId = 1,
		Position = CFrame.new(0, 0, 0),
		Text = "Feu de camp GRATUIT",
	},
	[2] = {
		Type = "Machine",
		TargetId = 2,
		Position = CFrame.new(5, 0, 0),
		Text = "Feu de camp - 30$",
	},
	[3] = {
		Type = "Machine",
		TargetId = 3,
		Position = CFrame.new(10, 0, 0),
		Text = "Feu de camp - 60$",
	},

	-- Boutons pour décorations (IDs 1001-1999)
	[1001] = {
		Type = "Decoration",
		TargetId = 1, -- ID de la décoration (sans offset)
		Position = CFrame.new(-5, 0, 5),
		Text = "Banc - 50$",
	},
	[1002] = {
		Type = "Decoration",
		TargetId = 2,
		Position = CFrame.new(-10, 0, 5),
		Text = "Pot de fleurs - 75$",
	},
	[1003] = {
		Type = "Decoration",
		TargetId = 3,
		Position = CFrame.new(-15, 0, 5),
		Text = "Lampadaire - 120$",
	},
	[1004] = {
		Type = "Decoration",
		TargetId = 4,
		Position = CFrame.new(-20, 0, 5),
		Text = "Statue - 200$",
	},
}

return ButtonConfig
