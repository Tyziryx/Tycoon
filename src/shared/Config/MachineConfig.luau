local MachineConfig = {
	[1] = {
		Name = "CampFire",
		BaseCost = 0,
		BaseIncome = 10,
		NextButton = 2,
		ZoneRequired = 1,
		MaxLevel = 3,
	},
	[2] = {
		Name = "CampFire",
		NextButton = 3,
		BaseCost = 30,
		BaseIncome = 10,
		ZoneRequired = 1,
		MaxLevel = 3,
	},
	[3] = {
		Name = "CampFire",
		BaseCost = 60,
		BaseIncome = 10,
		ZoneRequired = 1,
		MaxLevel = 3,
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
