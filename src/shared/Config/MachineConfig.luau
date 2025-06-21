local MachineConfig = {
	["CampFire"] = {
		Name = "CampFire",
		BaseCost = 100,
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
	["Machine2"] = {
		Name = "Machine2",
		BaseCost = 100,
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
	["Machine3"] = {
		Name = "Machine3",
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
