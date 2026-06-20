local MachineConfig = {
	[1] = {
		Name = "CampFire",
		BaseCost = 0,
		BaseIncome = 1,
		NextButton = 2,
		ZoneRequired = 1,
		MaxLevel = 3,
		BuildTime = 2,
		UnlockDelay = 0,
		ManualPollution = 1,
		ManualLevelMultiplier = 2,
		IncomeLevelMultipliers = {
			[1] = 1,
			[2] = 2,
			[3] = 4,
		},
		UpgradeCosts = {
			[1] = 10,
			[2] = 25,
		},
	},
	[2] = {
		Name = "CampFire",
		NextButton = 3,
		BaseCost = 50,
		BaseIncome = 4,
		ZoneRequired = 1,
		MaxLevel = 3,
		BuildTime = 4,
		UnlockDelay = 10,
		ManualPollution = 3,
		ManualLevelMultiplier = 2,
		IncomeLevelMultipliers = {
			[1] = 1,
			[2] = 2,
			[3] = 4,
		},
		UpgradeCosts = {
			[1] = 75,
			[2] = 150,
		},
	},
	[3] = {
		Name = "CampFire",
		BaseCost = 250,
		BaseIncome = 12,
		ZoneRequired = 1,
		MaxLevel = 3,
		BuildTime = 6,
		UnlockDelay = 20,
		ManualPollution = 8,
		ManualLevelMultiplier = 2,
		IncomeLevelMultipliers = {
			[1] = 1,
			[2] = 2,
			[3] = 4,
		},
		UpgradeCosts = {
			[1] = 350,
			[2] = 800,
		},
	},
	["Machine4"] = {
		Name = "Machine4",
		BaseCost = 100,
		BaseIncome = 1,
		ZoneRequired = 2,
		MaxLevel = 3,
	},
}

return MachineConfig
