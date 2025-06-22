local MachineConfig = {
	[1] = {
		Name = "CampFire",
		BaseCost = 0,
		BaseIncome = 1,
		NextButton = 2,
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
		NextButton = 3,
		BaseCost = 30,
		BaseIncome = 1,
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
		ButtonRequired = 2,
		BaseCost = 60,
		BaseIncome = 1,
		ZoneRequired = 1,
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
