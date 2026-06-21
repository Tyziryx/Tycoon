local DefaultPlayerData = {
	Money = 0,
	Pollution = 0,
	Cendres = 0,
	Scrap = 0,
	CurrentZone = 1,
	UnlockedZones = {
		["1"] = true,
	},
	PrestigeUpgrades = {
		IncomeMultiplier = 0,
		SellMultiplier = 0,
		CostReduction = 0,
		ManualBurnBoost = 0,
		StarterCash = 0,
		PrestigeGain = 0,
	},
	MachineInventory = {},
	MachineCollection = {},
	OwnedMachines = {},
	OwnedDecorations = {},
	RandomStats = {
		RollCount = 0,
		PityCounter = 0,
	},
	Stats = {
		RunPollution = 0,
		TotalMoneyEarned = 0,
		TotalPollution = 0,
		PlayTime = 0,
	},
}

return DefaultPlayerData
