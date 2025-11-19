import { MachineConfig } from "../types";

export const MachineConfigs: Map<number, MachineConfig> = new Map([
	[
		1,
		{
			name: "CampFire",
			baseCost: 0,
			baseIncome: 10,
			nextButton: 2,
			zoneRequired: 1,
			maxLevel: 3,
			upgradeMultipliers: [1, 1.5, 2],
			pollutionPerCycle: 1,
		},
	],
	[
		2,
		{
			name: "CampFire",
			baseCost: 30,
			baseIncome: 10,
			nextButton: 3,
			zoneRequired: 1,
			maxLevel: 3,
			upgradeMultipliers: [1, 1.5, 2],
			pollutionPerCycle: 1,
		},
	],
	[
		3,
		{
			name: "CampFire",
			baseCost: 60,
			baseIncome: 10,
			zoneRequired: 1,
			maxLevel: 3,
			upgradeMultipliers: [1, 1.5, 2],
			pollutionPerCycle: 1,
		},
	],
	[
		4,
		{
			name: "Machine4",
			baseCost: 100,
			baseIncome: 1,
			zoneRequired: 2,
			maxLevel: 3,
			upgradeMultipliers: [1, 1.5, 2],
			pollutionPerCycle: 2,
		},
	],
]);

// Helper functions
export function getMachineConfig(id: number): MachineConfig | undefined {
	return MachineConfigs.get(id);
}

export function getMachineUpgradeCost(id: number, currentLevel: number): number {
	const config = MachineConfigs.get(id);
	if (!config) return 0;

	const multiplier = config.upgradeMultipliers[currentLevel] ?? 1;
	return math.floor(config.baseCost * (currentLevel + 1) * multiplier);
}

export function getMachineIncome(id: number, level: number): number {
	const config = MachineConfigs.get(id);
	if (!config) return 0;

	const multiplier = config.upgradeMultipliers[level - 1] ?? 1;
	return math.floor(config.baseIncome * multiplier);
}
