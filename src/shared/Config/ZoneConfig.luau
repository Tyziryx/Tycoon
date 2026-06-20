local ZoneConfig = {
	[1] = {
		Name = "Zone de démarrage",
		PollutionThreshold = 0,
	},
	[2] = {
		Name = "Zone industrielle",
		PollutionThreshold = 1000,
	},
	[3] = {
		Name = "Zone charbon",
		PollutionThreshold = 10000,
	},
	[4] = {
		Name = "Zone toxique",
		PollutionThreshold = 100000,
	},
	[5] = {
		Name = "Zone apocalypse",
		PollutionThreshold = 1000000,
	},
}

return ZoneConfig
