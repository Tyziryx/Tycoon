import { Service, OnStart, OnInit } from "@flamework/core";
import { Players } from "@rbxts/services";
import ProfileService from "@rbxts/profileservice";
import { Profile } from "@rbxts/profileservice/globals";
import { PlayerData, MachineData } from "shared/types";
import { GameConstants, DataStoreKeys } from "shared/constants";
import { GlobalEvents } from "shared/network";

// Default player data template
const DEFAULT_PLAYER_DATA: PlayerData = {
	money: GameConstants.STARTING_MONEY,
	pollution: GameConstants.STARTING_POLLUTION,
	unlockedZones: [1],
	ownedMachines: new Map<number, MachineData>(),
	ownedDecorations: [],
	stats: {
		totalMoneyEarned: 0,
		playTime: 0,
	},
};

type PlayerProfile = Profile<PlayerData>;

@Service()
export class DataService implements OnInit, OnStart {
	private profileStore = ProfileService.GetProfileStore(DataStoreKeys.PLAYER_DATA, DEFAULT_PLAYER_DATA);
	private profiles = new Map<Player, PlayerProfile>();

	onInit() {
		// Set up player connections
		Players.PlayerAdded.Connect((player) => this.onPlayerAdded(player));
		Players.PlayerRemoving.Connect((player) => this.onPlayerRemoving(player));

		// Handle players already in game
		for (const player of Players.GetPlayers()) {
			task.spawn(() => this.onPlayerAdded(player));
		}
	}

	onStart() {
		// Auto-save loop
		task.spawn(() => {
			while (true) {
				task.wait(GameConstants.AUTO_SAVE_INTERVAL);
				this.saveAllProfiles();
			}
		});
	}

	private onPlayerAdded(player: Player) {
		const profile = this.profileStore.LoadProfileAsync(`Player_${player.UserId}`);

		if (!profile) {
			player.Kick("Failed to load your data. Please rejoin.");
			return;
		}

		profile.AddUserId(player.UserId);
		profile.Reconcile();

		profile.ListenToRelease(() => {
			this.profiles.delete(player);
			player.Kick("Your data was loaded on another server. Please rejoin.");
		});

		if (!player.IsDescendantOf(Players)) {
			profile.Release();
			return;
		}

		this.profiles.set(player, profile);

		// Sync data to client
		GlobalEvents.server.syncPlayerData(player, profile.Data);
	}

	private onPlayerRemoving(player: Player) {
		const profile = this.profiles.get(player);
		if (profile) {
			profile.Release();
			this.profiles.delete(player);
		}
	}

	private saveAllProfiles() {
		for (const [player, profile] of this.profiles) {
			if (profile && player.IsDescendantOf(Players)) {
				// ProfileService auto-saves, but we can force it here if needed
			}
		}
	}

	// Public API
	public getProfile(player: Player): PlayerProfile | undefined {
		return this.profiles.get(player);
	}

	public getData(player: Player): PlayerData | undefined {
		const profile = this.profiles.get(player);
		return profile?.Data;
	}

	public updateData<K extends keyof PlayerData>(player: Player, key: K, value: PlayerData[K]): boolean {
		const profile = this.profiles.get(player);
		if (!profile) return false;

		profile.Data[key] = value;
		return true;
	}

	public getMoney(player: Player): number {
		return this.getData(player)?.money ?? 0;
	}

	public setMoney(player: Player, amount: number): boolean {
		const result = this.updateData(player, "money", amount);
		if (result) {
			GlobalEvents.server.updateMoney(player, amount);
		}
		return result;
	}

	public addMoney(player: Player, amount: number): boolean {
		const current = this.getMoney(player);
		const success = this.setMoney(player, current + amount);

		if (success && amount > 0) {
			const data = this.getData(player);
			if (data) {
				data.stats.totalMoneyEarned += amount;
			}
		}

		return success;
	}

	public getPollution(player: Player): number {
		return this.getData(player)?.pollution ?? 0;
	}

	public setPollution(player: Player, amount: number): boolean {
		const result = this.updateData(player, "pollution", amount);
		if (result) {
			GlobalEvents.server.updatePollution(player, amount);
		}
		return result;
	}

	public addPollution(player: Player, amount: number): boolean {
		const current = this.getPollution(player);
		return this.setPollution(player, current + amount);
	}

	public getOwnedMachines(player: Player): Map<number, MachineData> {
		return this.getData(player)?.ownedMachines ?? new Map();
	}

	public addOwnedMachine(player: Player, machineId: number, data: MachineData): boolean {
		const playerData = this.getData(player);
		if (!playerData) return false;

		playerData.ownedMachines.set(machineId, data);
		return true;
	}

	public getMachineLevel(player: Player, machineId: number): number {
		const machines = this.getOwnedMachines(player);
		return machines.get(machineId)?.level ?? 0;
	}

	public setMachineLevel(player: Player, machineId: number, level: number): boolean {
		const machines = this.getOwnedMachines(player);
		const machineData = machines.get(machineId);

		if (!machineData) return false;

		machineData.level = level;
		return true;
	}

	public getUnlockedZones(player: Player): number[] {
		return this.getData(player)?.unlockedZones ?? [];
	}

	public unlockZone(player: Player, zoneId: number): boolean {
		const data = this.getData(player);
		if (!data) return false;

		if (!data.unlockedZones.includes(zoneId)) {
			data.unlockedZones.push(zoneId);
		}

		return true;
	}

	public hasZone(player: Player, zoneId: number): boolean {
		return this.getUnlockedZones(player).includes(zoneId);
	}

	public getOwnedDecorations(player: Player): number[] {
		return this.getData(player)?.ownedDecorations ?? [];
	}

	public addOwnedDecoration(player: Player, decorationId: number): boolean {
		const data = this.getData(player);
		if (!data) return false;

		if (!data.ownedDecorations.includes(decorationId)) {
			data.ownedDecorations.push(decorationId);
		}

		return true;
	}
}
