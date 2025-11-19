import { Service, OnStart, Dependency } from "@flamework/core";
import { Players } from "@rbxts/services";
import { DataService } from "./DataService";
import { GameConstants } from "shared/constants";
import { GlobalEvents } from "shared/network";
import { getMachineIncome, MachineConfigs } from "shared/config";

@Service()
export class StatService implements OnStart {
	private dataService = Dependency<DataService>();

	onStart() {
		// Income generation loop
		task.spawn(() => {
			while (true) {
				task.wait(GameConstants.GENERATION_INTERVAL);
				this.generateIncomeForAllPlayers();
			}
		});
	}

	private generateIncomeForAllPlayers() {
		for (const player of Players.GetPlayers()) {
			this.generateIncome(player);
		}
	}

	private generateIncome(player: Player) {
		const ownedMachines = this.dataService.getOwnedMachines(player);
		let totalIncome = 0;
		let totalPollution = 0;

		for (const [machineId, machineData] of ownedMachines) {
			const config = MachineConfigs.get(machineId);
			if (!config) continue;

			// Calculate income based on machine level
			const income = getMachineIncome(machineId, machineData.level);
			totalIncome += income;

			// Calculate pollution
			totalPollution += config.pollutionPerCycle;
		}

		if (totalIncome > 0) {
			this.dataService.addMoney(player, totalIncome);
		}

		if (totalPollution > 0) {
			this.dataService.addPollution(player, totalPollution);
		}
	}

	public convertPollution(player: Player): { success: boolean; moneyGained: number } {
		const pollution = this.dataService.getPollution(player);

		if (pollution <= 0) {
			return { success: false, moneyGained: 0 };
		}

		const moneyGained = math.floor(pollution / GameConstants.POLLUTION_CONVERSION_RATE);

		if (moneyGained > 0) {
			this.dataService.addMoney(player, moneyGained);
			this.dataService.setPollution(player, 0);

			GlobalEvents.server.notify(player, `Pollution convertie: +${moneyGained}$`, "success");

			return { success: true, moneyGained };
		}

		return { success: false, moneyGained: 0 };
	}

	public calculateTotalIncome(player: Player): number {
		const ownedMachines = this.dataService.getOwnedMachines(player);
		let totalIncome = 0;

		for (const [machineId, machineData] of ownedMachines) {
			totalIncome += getMachineIncome(machineId, machineData.level);
		}

		return totalIncome;
	}
}
