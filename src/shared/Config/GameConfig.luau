local GameConfig = {
	-- Valeur de debug nécessaire pour tester la progression complète sans grind.
	-- Ne pas l'enlever tant que l'équilibrage final n'est pas prêt.
	STARTING_MONEY = 250000,
	GENERATION_INTERVAL = 1,
	POLLUTION_TO_MONEY_RATE = 1,
	REBIRTH = {
		MIN_RUN_POLLUTION = 1000,
		ASH_BASE = 1,
		ASH_GROWTH = 4,
	},
}

return GameConfig
