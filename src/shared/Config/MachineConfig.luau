-- Configuration gameplay des machines.
--
-- Les IDs sont stables et servent de contrat avec Studio :
-- - modèle dans ReplicatedStorage.Tycoon.Machines avec Attribute Id = machineId ;
-- - bouton TycoonButton avec Attribute machineId = machineId.
--
-- Si le modèle ou le bouton Studio n'existe pas encore, le serveur crée un placeholder
-- remplaçable pour garder toute la progression jouable.

local PALIER_COLORS = {
	[1] = Color3.fromRGB(120, 83, 48),
	[2] = Color3.fromRGB(128, 128, 128),
	[3] = Color3.fromRGB(190, 117, 41),
	[4] = Color3.fromRGB(92, 166, 82),
	[5] = Color3.fromRGB(150, 36, 33),
}

local MachineSpecs = {
	{ "CampFire", "Feu de camp industriel", 0, 1, 1 },
	{ "CampFire", "Baril incinérateur", 30, 2, 1 },
	{ "CampFire", "Tas de pneus brûlés", 80, 3, 1 },
	{ "BraseroDeDechets", "Brasero de déchets", 180, 5, 1 },
	{ "FosseDeBrulage", "Fosse de brûlage", 400, 8, 1 },
	{ "GenerateurDiesel", "Générateur diesel fuyant", 900, 12, 1 },
	{ "FourDeChantier", "Four de chantier", 1800, 18, 1 },
	{ "BroyeurPlastique", "Broyeur plastique manuel", 3500, 26, 1 },
	{ "CompacteurFerraille", "Compacteur de ferraille sale", 7000, 38, 1 },
	{ "MiniIncinerateur", "Mini-incinérateur", 14000, 55, 1 },

	{ "FosseCombustion", "Fosse à combustion", 30000, 90, 2 },
	{ "ConvoyeurDechets", "Convoyeur à déchets", 55000, 130, 2 },
	{ "CompacteurRouille", "Compacteur rouillé", 95000, 190, 2 },
	{ "BroyeurPalettes", "Broyeur de palettes", 160000, 280, 2 },
	{ "StationHuileUsee", "Station d'huile usée", 260000, 420, 2 },
	{ "FourAPneus", "Four à pneus", 420000, 620, 2 },
	{ "MicroUsineDestruction", "Micro-usine de destruction", 680000, 900, 2 },
	{ "PompeGoudron", "Pompe à goudron", 1100000, 1300, 2 },
	{ "PresseFerraille", "Presse à ferraille", 1800000, 1900, 2 },
	{ "CremateurIndustriel", "Crémateur industriel", 3000000, 2800, 2 },

	{ "CompacteurBruleur", "Compacteur brûleur", 5000000, 4500, 3 },
	{ "ChaudiereCharbon", "Chaudière à charbon", 8000000, 6500, 3 },
	{ "LocomotiveCharbon", "Locomotive à charbon statique", 13000000, 9500, 3 },
	{ "FourACoke", "Four à coke", 21000000, 14000, 3 },
	{ "BroyeurCharbon", "Broyeur de charbon", 34000000, 20000, 3 },
	{ "SoufflerieCendres", "Soufflerie à cendres", 55000000, 29000, 3 },
	{ "GenerateurVapeurSale", "Générateur vapeur sale", 90000000, 42000, 3 },
	{ "ReseauTuyauxBrulants", "Réseau de tuyaux brûlants", 145000000, 60000, 3 },
	{ "IncinerateurWagons", "Incinérateur de wagons", 230000000, 86000, 3 },
	{ "CentraleCharbonMiniature", "Centrale charbon miniature", 370000000, 125000, 3 },

	{ "RaffineriePrimitive", "Raffinerie primitive", 600000000, 190000, 4 },
	{ "BassinAcide", "Bassin d'acide", 950000000, 280000, 4 },
	{ "StationThermoPolluante", "Station thermo-polluante", 1500000000, 420000, 4 },
	{ "CraqueurPetrolier", "Craqueur pétrolier", 2400000000, 620000, 4 },
	{ "TorchereGaz", "Torchère de gaz", 3800000000, 900000, 4 },
	{ "ReacteurChimique", "Réacteur chimique instable", 6000000000, 1300000, 4 },
	{ "BrasRobotToxique", "Bras robot à rejets toxiques", 9500000000, 1900000, 4 },
	{ "CamionCiterneFuite", "Camion-citerne en fuite", 15000000000, 2800000, 4 },
	{ "PompePetroleLourd", "Pompe à pétrole lourd", 24000000000, 4100000, 4 },
	{ "TourDistillationSale", "Tour de distillation sale", 38000000000, 6000000, 4 },

	{ "ReacteurCombustion", "Réacteur de combustion", 60000000000, 9000000, 5 },
	{ "FourPlasmaSale", "Four plasma sale", 95000000000, 13000000, 5 },
	{ "VortexCendres", "Vortex de cendres", 150000000000, 19000000, 5 },
	{ "TrouNoirIndustriel", "Trou noir industriel", 240000000000, 28000000, 5 },
	{ "EventGeothermique", "Évent géothermique polluant", 380000000000, 41000000, 5 },
	{ "MegaIncinerateur", "Méga-incinérateur", 600000000000, 60000000, 5 },
	{ "CentraleSmogRouge", "Centrale à smog rouge", 950000000000, 88000000, 5 },
	{ "BroyeurDimensionnel", "Broyeur dimensionnel", 1500000000000, 130000000, 5 },
	{ "NoyauFusionInstable", "Noyau de fusion instable", 2400000000000, 190000000, 5 },
	{ "ExtracteurVideToxique", "Extracteur de vide toxique", 3800000000000, 280000000, 5 },
}

local function getUpgradeCosts(baseCost)
	if baseCost <= 0 then
		return 100, 200
	end

	return math.max(1, math.floor(baseCost * 5)), math.max(1, math.floor(baseCost * 10))
end

local MachineConfig = {}

for id, spec in ipairs(MachineSpecs) do
	local internalName = spec[1]
	local displayName = spec[2]
	local baseCost = spec[3]
	local baseIncome = spec[4]
	local palier = spec[5]
	local tier2Cost, tier3Cost = getUpgradeCosts(baseCost)

	MachineConfig[id] = {
		Name = internalName,
		DisplayName = displayName,
		BaseCost = baseCost,
		BaseIncome = baseIncome,
		ZoneRequired = palier,
		NextButton = MachineSpecs[id + 1] and id + 1 or -1,
		MaxLevel = 3,
		BuildTime = math.min(8, 1.25 + palier + (((id - 1) % 10) * 0.25)),
		UnlockDelay = id == 1 and 0 or math.min(5, ((id - 1) % 10) * 0.25),
		PlaceholderColor = PALIER_COLORS[palier],
		FootprintX = palier >= 4 and 2 or 1,
		FootprintZ = palier >= 4 and 2 or 1,
		ManualBurner = internalName == "CampFire",
		ManualPollution = math.max(1, math.floor(baseIncome * 0.6)),
		ManualLevelMultiplier = 2,
		Upgrades = {
			[2] = { Cost = tier2Cost, Multiplier = 1.5 },
			[3] = { Cost = tier3Cost, Multiplier = 2 },
		},
	}
end

return MachineConfig
