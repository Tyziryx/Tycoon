import { Service, OnStart, Dependency } from "@flamework/core";
import { DataService } from "./DataService";
import { TycoonService } from "./TycoonService";
import { PurchaseResult, MachineData } from "shared/types";
import { GlobalEvents, GlobalFunctions } from "shared/network";
import { getMachineConfig, getMachineUpgradeCost, MachineConfigs } from "shared/config/machines";
import { getDecorationConfig } from "shared/config/decorations";
import { getZoneConfig, canUnlockZone } from "shared/config/zones";
import { GameConstants } from "shared/constants";

@Service()
export class PurchaseService implements OnStart {
	private dataService = Dependency<DataService>();
	private tycoonService = Dependency<TycoonService>();
	private lastPurchaseTime = new Map<Player, number>();

	onStart() {
		// Register network handlers
		GlobalFunctions.server.setCallback("purchase", (player, itemId, itemType) => {
			return this.handlePurchase(player, itemId, itemType);
		});

		GlobalFunctions.server.setCallback("upgrade", (player, machineId) => {
			return this.handleUpgrade(player, machineId);
		});

		GlobalEvents.server.connect("requestPurchase", (player, itemId, itemType) => {
			this.handlePurchase(player, itemId, itemType);
		});

		GlobalEvents.server.connect("requestUpgrade", (player, machineId) => {
			this.handleUpgrade(player, machineId);
		});
	}

	private checkCooldown(player: Player): boolean {
		const now = os.clock();
		const lastTime = this.lastPurchaseTime.get(player) ?? 0;

		if (now - lastTime < GameConstants.BUTTON_CLICK_COOLDOWN) {
			return false;
		}

		this.lastPurchaseTime.set(player, now);
		return true;
	}

	public handlePurchase(
		player: Player,
		itemId: number,
		itemType: "machine" | "decoration" | "zone",
	): PurchaseResult {
		if (!this.checkCooldown(player)) {
			return { success: false, message: "Attendez avant d'acheter à nouveau" };
		}

		switch (itemType) {
			case "machine":
				return this.purchaseMachine(player, itemId);
			case "decoration":
				return this.purchaseDecoration(player, itemId);
			case "zone":
				return this.purchaseZone(player, itemId);
			default:
				return { success: false, message: "Type d'achat invalide" };
		}
	}

	public purchaseMachine(player: Player, machineId: number): PurchaseResult {
		const config = getMachineConfig(machineId);
		if (!config) {
			return { success: false, message: "Machine invalide" };
		}

		// Check if already owned
		const ownedMachines = this.dataService.getOwnedMachines(player);
		if (ownedMachines.has(machineId)) {
			return { success: false, message: "Machine déjà possédée" };
		}

		// Check zone requirement
		if (!this.dataService.hasZone(player, config.zoneRequired)) {
			return { success: false, message: "Zone non débloquée" };
		}

		// Check money
		const money = this.dataService.getMoney(player);
		if (money < config.baseCost) {
			return { success: false, message: "Pas assez d'argent" };
		}

		// Deduct money
		this.dataService.addMoney(player, -config.baseCost);

		// Add machine to player data
		const machineData: MachineData = { level: 1 };
		this.dataService.addOwnedMachine(player, machineId, machineData);

		// Spawn machine in world
		this.tycoonService.spawnMachine(player, machineId, 1);

		// Notify client
		GlobalEvents.server.machineUnlocked(player, machineId);
		GlobalEvents.server.notify(player, `${config.name} acheté!`, "success");

		return { success: true };
	}

	public purchaseDecoration(player: Player, decorationId: number): PurchaseResult {
		const config = getDecorationConfig(decorationId);
		if (!config) {
			return { success: false, message: "Décoration invalide" };
		}

		// Check if already owned
		const ownedDecorations = this.dataService.getOwnedDecorations(player);
		if (ownedDecorations.includes(decorationId)) {
			return { success: false, message: "Décoration déjà possédée" };
		}

		// Check zone requirement
		if (!this.dataService.hasZone(player, config.zoneRequired)) {
			return { success: false, message: "Zone non débloquée" };
		}

		// Check money
		const money = this.dataService.getMoney(player);
		if (money < config.baseCost) {
			return { success: false, message: "Pas assez d'argent" };
		}

		// Deduct money
		this.dataService.addMoney(player, -config.baseCost);

		// Add decoration to player data
		this.dataService.addOwnedDecoration(player, decorationId);

		// Spawn decoration in world
		this.tycoonService.spawnDecoration(player, decorationId);

		// Notify client
		GlobalEvents.server.decorationUnlocked(player, decorationId);
		GlobalEvents.server.notify(player, `${config.name} acheté!`, "success");

		return { success: true };
	}

	public purchaseZone(player: Player, zoneId: number): PurchaseResult {
		const config = getZoneConfig(zoneId);
		if (!config) {
			return { success: false, message: "Zone invalide" };
		}

		const unlockedZones = this.dataService.getUnlockedZones(player);
		const money = this.dataService.getMoney(player);

		const { canUnlock, reason } = canUnlockZone(zoneId, unlockedZones, money);
		if (!canUnlock) {
			return { success: false, message: reason };
		}

		// Deduct money
		this.dataService.addMoney(player, -config.unlockCost);

		// Unlock zone
		this.dataService.unlockZone(player, zoneId);

		// Notify client
		GlobalEvents.server.zoneUnlocked(player, zoneId);
		GlobalEvents.server.notify(player, `${config.name} débloquée!`, "success");

		return { success: true };
	}

	public handleUpgrade(player: Player, machineId: number): PurchaseResult {
		if (!this.checkCooldown(player)) {
			return { success: false, message: "Attendez avant d'améliorer à nouveau" };
		}

		const config = getMachineConfig(machineId);
		if (!config) {
			return { success: false, message: "Machine invalide" };
		}

		// Check if owned
		const currentLevel = this.dataService.getMachineLevel(player, machineId);
		if (currentLevel === 0) {
			return { success: false, message: "Machine non possédée" };
		}

		// Check max level
		if (currentLevel >= config.maxLevel) {
			return { success: false, message: "Niveau maximum atteint" };
		}

		// Calculate upgrade cost
		const upgradeCost = getMachineUpgradeCost(machineId, currentLevel);

		// Check money
		const money = this.dataService.getMoney(player);
		if (money < upgradeCost) {
			return { success: false, message: "Pas assez d'argent" };
		}

		// Deduct money
		this.dataService.addMoney(player, -upgradeCost);

		// Upgrade machine
		const newLevel = currentLevel + 1;
		this.dataService.setMachineLevel(player, machineId, newLevel);

		// Notify client
		GlobalEvents.server.machineUpgraded(player, machineId, newLevel);
		GlobalEvents.server.notify(player, `${config.name} amélioré au niveau ${newLevel}!`, "success");

		return { success: true };
	}
}
