local ZoneConfig = {
	[1] = {
		Name = "Zone de démarrage",
		UnlockCost = 0,
		Prerequisites = {},
	},
	[2] = {
		Name = "Zone industrielle",
		UnlockCost = 1000,
		Prerequisites = { 1 },
	},
}

return ZoneConfig
