import { ZoneConfig } from "../types";

export const ZoneConfigs: Map<number, ZoneConfig> = new Map([
	[
		1,
		{
			name: "Zone de démarrage",
			unlockCost: 0,
			prerequisites: [],
		},
	],
	[
		2,
		{
			name: "Zone industrielle",
			unlockCost: 1000,
			prerequisites: [1],
		},
	],
]);

// Helper functions
export function getZoneConfig(id: number): ZoneConfig | undefined {
	return ZoneConfigs.get(id);
}

export function canUnlockZone(
	zoneId: number,
	unlockedZones: number[],
	currentMoney: number,
): { canUnlock: boolean; reason?: string } {
	const config = ZoneConfigs.get(zoneId);
	if (!config) {
		return { canUnlock: false, reason: "Zone invalide" };
	}

	if (unlockedZones.includes(zoneId)) {
		return { canUnlock: false, reason: "Zone déjà débloquée" };
	}

	if (currentMoney < config.unlockCost) {
		return { canUnlock: false, reason: "Pas assez d'argent" };
	}

	for (const prereq of config.prerequisites) {
		if (!unlockedZones.includes(prereq)) {
			return { canUnlock: false, reason: "Prérequis non remplis" };
		}
	}

	return { canUnlock: true };
}
