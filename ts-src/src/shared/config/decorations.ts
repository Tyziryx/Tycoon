import { DecorationConfig } from "../types";

export const DecorationConfigs: Map<number, DecorationConfig> = new Map([
	[
		1,
		{
			name: "Banc",
			baseCost: 50,
			zoneRequired: 1,
		},
	],
	[
		2,
		{
			name: "Pot de fleurs",
			baseCost: 75,
			zoneRequired: 1,
		},
	],
]);

// Helper functions
export function getDecorationConfig(id: number): DecorationConfig | undefined {
	return DecorationConfigs.get(id);
}
