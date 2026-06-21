local RandomMachineConfig = {
	Roll = {
		BaseCost = 2500,
		PityThreshold = 20,
		PityMinimumRarity = "Rare",
		TraitChance = 0.35,
		MaxTraits = 2,
	},

	Placement = {
		CellSize = 5,
		OriginX = -22.5,
		OriginZ = -8,
		MaxColumns = 10,
		RowsPerPalier = 4,
		DefaultRotation = 0,
	},

	Sell = {
		RefundRate = 0.25,
		MinimumBaseValue = 100,
	},

	Recycle = {
		BaseYield = 1,
		ResourceName = "Scrap",
		DisplayName = "Ferraille",
	},

	Fusion = {
		RequiredDuplicates = 3,
		IncomeMultiplierPerLevel = 0.15,
		ValueMultiplierPerLevel = 0.25,
	},

	RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" },

	Rarities = {
		Common = {
			Name = "Commune",
			Weight = 7000,
			SellMultiplier = 1,
			RecycleMultiplier = 1,
			Color = Color3.fromRGB(180, 180, 180),
		},
		Uncommon = {
			Name = "Peu commune",
			Weight = 2000,
			SellMultiplier = 1.2,
			RecycleMultiplier = 2,
			Color = Color3.fromRGB(80, 205, 110),
		},
		Rare = {
			Name = "Rare",
			Weight = 800,
			SellMultiplier = 1.6,
			RecycleMultiplier = 5,
			Color = Color3.fromRGB(80, 150, 255),
		},
		Epic = {
			Name = "Epique",
			Weight = 180,
			SellMultiplier = 2.6,
			RecycleMultiplier = 15,
			Color = Color3.fromRGB(185, 100, 255),
		},
		Legendary = {
			Name = "Legendaire",
			Weight = 20,
			SellMultiplier = 5,
			RecycleMultiplier = 50,
			Color = Color3.fromRGB(255, 195, 55),
		},
	},

	VariantOrder = { "Standard", "Rusted", "Toxic", "Mafia", "Unstable", "Golden", "Prototype" },

	Variants = {
		Standard = {
			Name = "Standard",
			MinimumRarity = "Common",
			Weight = 5000,
			IncomeMultiplier = 1,
			SellMultiplier = 1,
			RecycleMultiplier = 1,
			Color = Color3.fromRGB(160, 160, 160),
		},
		Rusted = {
			Name = "Rouillee",
			MinimumRarity = "Common",
			Weight = 2200,
			IncomeMultiplier = 1.08,
			SellMultiplier = 0.9,
			RecycleMultiplier = 1.2,
			Color = Color3.fromRGB(150, 82, 45),
		},
		Toxic = {
			Name = "Toxique",
			MinimumRarity = "Rare",
			Weight = 900,
			IncomeMultiplier = 1.25,
			SellMultiplier = 1.1,
			RecycleMultiplier = 2,
			Color = Color3.fromRGB(90, 235, 90),
		},
		Mafia = {
			Name = "Mafia",
			MinimumRarity = "Rare",
			Weight = 650,
			IncomeMultiplier = 1.12,
			SellMultiplier = 1.6,
			RecycleMultiplier = 1.4,
			Color = Color3.fromRGB(35, 35, 35),
		},
		Unstable = {
			Name = "Instable",
			MinimumRarity = "Epic",
			Weight = 220,
			IncomeMultiplier = 1.55,
			SellMultiplier = 1.2,
			RecycleMultiplier = 2.5,
			Color = Color3.fromRGB(255, 95, 65),
		},
		Golden = {
			Name = "Doree",
			MinimumRarity = "Legendary",
			Weight = 80,
			IncomeMultiplier = 2,
			SellMultiplier = 2,
			RecycleMultiplier = 5,
			Color = Color3.fromRGB(255, 215, 70),
		},
		Prototype = {
			Name = "Prototype",
			MinimumRarity = "Epic",
			Weight = 120,
			IncomeMultiplier = 1.8,
			SellMultiplier = 1.3,
			RecycleMultiplier = 3,
			Color = Color3.fromRGB(90, 255, 230),
		},
	},

	TraitOrder = { "Overclocked", "CheapMaintenance", "DirtySmoke", "Compact", "RecyclerBonus" },

	Traits = {
		Overclocked = {
			Name = "Overclockee",
			Weight = 250,
			IncomeMultiplier = 1.18,
			SellMultiplier = 1,
			RecycleMultiplier = 1,
		},
		CheapMaintenance = {
			Name = "Economique",
			Weight = 220,
			IncomeMultiplier = 1.05,
			SellMultiplier = 1.08,
			RecycleMultiplier = 1,
		},
		DirtySmoke = {
			Name = "Fumee sale",
			Weight = 220,
			IncomeMultiplier = 1.1,
			SellMultiplier = 1,
			RecycleMultiplier = 1.1,
		},
		Compact = {
			Name = "Compacte",
			Weight = 160,
			IncomeMultiplier = 1,
			SellMultiplier = 1.05,
			RecycleMultiplier = 1,
			FootprintBonus = -1,
		},
		RecyclerBonus = {
			Name = "Recyclable",
			Weight = 150,
			IncomeMultiplier = 1,
			SellMultiplier = 1,
			RecycleMultiplier = 1.6,
		},
	},
}

return RandomMachineConfig
