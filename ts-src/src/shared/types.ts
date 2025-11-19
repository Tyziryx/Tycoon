// Player Data Types
export interface PlayerData {
	money: number;
	pollution: number;
	unlockedZones: number[];
	ownedMachines: Map<number, MachineData>;
	ownedDecorations: number[];
	stats: PlayerStats;
}

export interface MachineData {
	level: number;
	position?: CFrame;
}

export interface PlayerStats {
	totalMoneyEarned: number;
	playTime: number;
}

// Configuration Types
export interface MachineConfig {
	name: string;
	baseCost: number;
	baseIncome: number;
	zoneRequired: number;
	maxLevel: number;
	nextButton?: number;
	upgradeMultipliers: number[];
	pollutionPerCycle: number;
}

export interface DecorationConfig {
	name: string;
	baseCost: number;
	zoneRequired: number;
	nextButton?: number;
}

export interface ZoneConfig {
	name: string;
	unlockCost: number;
	prerequisites: number[];
}

// Game State Types
export interface TycoonData {
	owner?: Player;
	plot: BasePart;
	machines: Map<number, Model>;
	decorations: Map<number, Model>;
}

// Purchasable Types
export type PurchasableType = "machine" | "decoration" | "zone";

export interface PurchaseResult {
	success: boolean;
	message?: string;
}

// Button Types
export interface ButtonData {
	id: number;
	type: PurchasableType;
	isUnlocked: boolean;
	cost: number;
}
