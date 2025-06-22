local MachineConfig = {
	[1] = {
		Name = "CampFire",
		BaseCost = 100,
		BaseIncome = 10,
		ZoneRequired = 1,
		MaxLevel = 3,
		UpgradeCost = function(level)
			return 100 * level
		end,
		UpgradeIncome = function(level)
			return 1 * level
		end,
	},
	[2] = {
		Name = "CampFire",
		BaseCost = 200,
		BaseIncome = 20,
		ZoneRequired = 1,
		MaxLevel = 3,
		UpgradeCost = function(level)
			return 100 * level
		end,
		UpgradeIncome = function(level)
			return 1 * level
		end,
	},
	[3] = {
		Name = "CampFire",
		BaseCost = 300,
		BaseIncome = 30,
		ZoneRequired = 2,
		MaxLevel = 3,
		UpgradeCost = function(level)
			return 100 * level
		end,
		UpgradeIncome = function(level)
			return 1 * level
		end,
	},
	["Machine4"] = {
		Name = "Machine4",
		BaseCost = 100,
		BaseIncome = 1,
		ZoneRequired = 2,
		MaxLevel = 3,
		UpgradeCost = function(level)
			return 100 * level
		end,
		UpgradeIncome = function(level)
			return 1 * level
		end,
	},
}

return MachineConfig
