import { Networking } from "@flamework/networking";
import { PlayerData, PurchaseResult } from "../types";

// Server -> Client events
interface ServerToClientEvents {
	// Stats updates
	updateMoney(amount: number): void;
	updatePollution(amount: number): void;

	// Tycoon updates
	machineUnlocked(machineId: number): void;
	machineUpgraded(machineId: number, newLevel: number): void;
	decorationUnlocked(decorationId: number): void;
	zoneUnlocked(zoneId: number): void;

	// Notifications
	notify(message: string, notificationType: "success" | "error" | "info"): void;

	// Initial data sync
	syncPlayerData(data: PlayerData): void;
}

// Client -> Server events
interface ClientToServerEvents {
	// Purchase requests
	requestPurchase(itemId: number, itemType: "machine" | "decoration" | "zone"): void;
	requestUpgrade(machineId: number): void;

	// Manual actions
	activateMachine(machineId: number): void;
	convertPollution(): void;
}

// Server -> Client functions (with return values)
interface ServerToClientFunctions {}

// Client -> Server functions (with return values)
interface ClientToServerFunctions {
	// Get player data
	getPlayerData(): PlayerData;

	// Purchase with result
	purchase(itemId: number, itemType: "machine" | "decoration" | "zone"): PurchaseResult;
	upgrade(machineId: number): PurchaseResult;
}

// Create network handlers
export const GlobalEvents = Networking.createEvent<ServerToClientEvents, ClientToServerEvents>();
export const GlobalFunctions = Networking.createFunction<ServerToClientFunctions, ClientToServerFunctions>();
