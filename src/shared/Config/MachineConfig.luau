-- Configuration des machines (source de vérité : docs/DESIGN.md, Palier 1).
--
-- Chaque machine est entièrement pilotée par les données.
--
-- Économie (cf. docs/DESIGN.md, table « Machines — Palier 1 ») :
--   BaseCost     : coût d'achat (niveau 1)
--   BaseIncome   : pollution générée par seconde au niveau 1
--   MaxLevel     : nombre de tiers (niveaux)
--   NextButton   : machineId du bouton à révéler après l'achat (chaîne d'achats)
--   Upgrades     : { [niveau] = { Cost = coût pour atteindre ce niveau,
--                                 Multiplier = multiplicateur de rendement } }
--
-- Feedback / progression du feu de camp (cf. PR « campfire progression ») :
--   BuildTime             : durée (s) de l'animation de construction
--   UnlockDelay           : délai (s) avant de révéler le bouton suivant
--   ManualPollution       : pollution de base par clic (burner manuel)
--   ManualLevelMultiplier : facteur par niveau pour le burner manuel
--
-- Pour ajouter une machine, voir docs/DESIGN.md ("Ajouter une nouvelle machine").

local MachineConfig = {
	[1] = {
		Name = "CampFire",
		BaseCost = 0,
		BaseIncome = 1,
		ZoneRequired = 1,
		NextButton = 2,
		MaxLevel = 3,
		BuildTime = 2,
		UnlockDelay = 0,
		ManualPollution = 1,
		ManualLevelMultiplier = 2,
		Upgrades = {
			[2] = { Cost = 100, Multiplier = 1.5 },
			[3] = { Cost = 200, Multiplier = 2 },
		},
	},
	[2] = {
		Name = "CampFire",
		BaseCost = 30,
		BaseIncome = 1,
		ZoneRequired = 1,
		NextButton = 3,
		MaxLevel = 3,
		BuildTime = 4,
		UnlockDelay = 10,
		ManualPollution = 3,
		ManualLevelMultiplier = 2,
		Upgrades = {
			[2] = { Cost = 150, Multiplier = 1.5 },
			[3] = { Cost = 300, Multiplier = 2 },
		},
	},
	[3] = {
		Name = "CampFire",
		BaseCost = 60,
		BaseIncome = 1,
		ZoneRequired = 1,
		-- Pas de NextButton : dernière machine du Palier 1 actuellement versionnée
		MaxLevel = 3,
		BuildTime = 6,
		UnlockDelay = 20,
		ManualPollution = 8,
		ManualLevelMultiplier = 2,
		Upgrades = {
			[2] = { Cost = 300, Multiplier = 1.5 },
			[3] = { Cost = 600, Multiplier = 2 },
		},
	},

	-- ┌──────────────────────────────────────────────────────────────────┐
	-- │ MODÈLE pour une future machine (Palier 2, etc.). Décommenter +     │
	-- │ placer le modèle + le bouton correspondants dans Studio.           │
	-- └──────────────────────────────────────────────────────────────────┘
	-- [4] = {
	-- 	Name = "Usine",
	-- 	BaseCost = 1000,
	-- 	BaseIncome = 5,
	-- 	ZoneRequired = 2,
	-- 	MaxLevel = 3,
	-- 	BuildTime = 8,
	-- 	UnlockDelay = 30,
	-- 	ManualPollution = 20,
	-- 	ManualLevelMultiplier = 2,
	-- 	Upgrades = {
	-- 		[2] = { Cost = 2000, Multiplier = 1.5 },
	-- 		[3] = { Cost = 4000, Multiplier = 2 },
	-- 	},
	-- },
}

return MachineConfig
