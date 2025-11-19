import { Service, OnStart, OnInit, Dependency } from "@flamework/core";
import { Workspace, Players } from "@rbxts/services";
import { TycoonData } from "shared/types";
import { DataService } from "./DataService";

@Service()
export class TycoonService implements OnInit, OnStart {
	private dataService = Dependency<DataService>();
	private tycoons = new Map<number, TycoonData>();
	private playerTycoons = new Map<Player, number>();
	private tycoonFolder?: Folder;

	onInit() {
		// Find or create tycoons folder
		this.tycoonFolder = Workspace.FindFirstChild("Tycoons") as Folder;
		if (!this.tycoonFolder) {
			this.tycoonFolder = new Instance("Folder");
			this.tycoonFolder.Name = "Tycoons";
			this.tycoonFolder.Parent = Workspace;
		}

		// Initialize tycoon plots from workspace
		this.initializeTycoonPlots();
	}

	onStart() {
		// Handle player connections
		Players.PlayerAdded.Connect((player) => this.assignTycoon(player));
		Players.PlayerRemoving.Connect((player) => this.releaseTycoon(player));

		// Assign tycoons to existing players
		for (const player of Players.GetPlayers()) {
			task.spawn(() => this.assignTycoon(player));
		}
	}

	private initializeTycoonPlots() {
		if (!this.tycoonFolder) return;

		let plotIndex = 1;
		for (const child of this.tycoonFolder.GetChildren()) {
			if (child.IsA("Model") || child.IsA("Folder")) {
				const plot = child.FindFirstChild("Plot") as BasePart;
				if (plot) {
					this.tycoons.set(plotIndex, {
						owner: undefined,
						plot: plot,
						machines: new Map(),
						decorations: new Map(),
					});
					plotIndex++;
				}
			}
		}

		print(`[TycoonService] Initialized ${plotIndex - 1} tycoon plots`);
	}

	public assignTycoon(player: Player): boolean {
		// Check if player already has a tycoon
		if (this.playerTycoons.has(player)) {
			return true;
		}

		// Find an available tycoon
		for (const [tycoonId, tycoonData] of this.tycoons) {
			if (!tycoonData.owner) {
				tycoonData.owner = player;
				this.playerTycoons.set(player, tycoonId);

				// Initialize player's machines from saved data
				this.initializePlayerMachines(player, tycoonId);

				print(`[TycoonService] Assigned tycoon ${tycoonId} to ${player.Name}`);
				return true;
			}
		}

		warn(`[TycoonService] No available tycoons for ${player.Name}`);
		return false;
	}

	public releaseTycoon(player: Player): void {
		const tycoonId = this.playerTycoons.get(player);
		if (tycoonId === undefined) return;

		const tycoonData = this.tycoons.get(tycoonId);
		if (tycoonData) {
			// Clean up machines
			for (const [, model] of tycoonData.machines) {
				model.Destroy();
			}
			tycoonData.machines.clear();

			// Clean up decorations
			for (const [, model] of tycoonData.decorations) {
				model.Destroy();
			}
			tycoonData.decorations.clear();

			tycoonData.owner = undefined;
		}

		this.playerTycoons.delete(player);
		print(`[TycoonService] Released tycoon ${tycoonId} from ${player.Name}`);
	}

	private initializePlayerMachines(player: Player, tycoonId: number) {
		const tycoonData = this.tycoons.get(tycoonId);
		if (!tycoonData) return;

		const ownedMachines = this.dataService.getOwnedMachines(player);

		for (const [machineId, machineData] of ownedMachines) {
			// Spawn machine model at saved position or default position
			this.spawnMachine(player, machineId, machineData.level);
		}
	}

	public spawnMachine(player: Player, machineId: number, level: number): Model | undefined {
		const tycoonId = this.playerTycoons.get(player);
		if (tycoonId === undefined) return undefined;

		const tycoonData = this.tycoons.get(tycoonId);
		if (!tycoonData) return undefined;

		// Find machine template in workspace (you'd have a templates folder)
		const machineTemplate = this.getMachineTemplate(machineId);
		if (!machineTemplate) {
			warn(`[TycoonService] Machine template not found for ID ${machineId}`);
			return undefined;
		}

		const machine = machineTemplate.Clone();
		machine.Name = `Machine_${machineId}`;

		// Position machine relative to tycoon plot
		const position = this.getMachinePosition(machineId, tycoonData.plot);
		if (machine.PrimaryPart) {
			machine.SetPrimaryPartCFrame(position);
		}

		machine.Parent = tycoonData.plot.Parent;
		tycoonData.machines.set(machineId, machine);

		return machine;
	}

	public spawnDecoration(player: Player, decorationId: number): Model | undefined {
		const tycoonId = this.playerTycoons.get(player);
		if (tycoonId === undefined) return undefined;

		const tycoonData = this.tycoons.get(tycoonId);
		if (!tycoonData) return undefined;

		const decorationTemplate = this.getDecorationTemplate(decorationId);
		if (!decorationTemplate) {
			warn(`[TycoonService] Decoration template not found for ID ${decorationId}`);
			return undefined;
		}

		const decoration = decorationTemplate.Clone();
		decoration.Name = `Decoration_${decorationId}`;

		// Position decoration
		const position = this.getDecorationPosition(decorationId, tycoonData.plot);
		if (decoration.PrimaryPart) {
			decoration.SetPrimaryPartCFrame(position);
		}

		decoration.Parent = tycoonData.plot.Parent;
		tycoonData.decorations.set(decorationId, decoration);

		return decoration;
	}

	private getMachineTemplate(machineId: number): Model | undefined {
		// Look for machine templates in ReplicatedStorage or ServerStorage
		const templates = game.GetService("ServerStorage").FindFirstChild("MachineTemplates") as Folder;
		return templates?.FindFirstChild(`Machine_${machineId}`) as Model;
	}

	private getDecorationTemplate(decorationId: number): Model | undefined {
		const templates = game.GetService("ServerStorage").FindFirstChild("DecorationTemplates") as Folder;
		return templates?.FindFirstChild(`Decoration_${decorationId}`) as Model;
	}

	private getMachinePosition(machineId: number, plot: BasePart): CFrame {
		// Calculate position based on machine ID
		// This should be customized based on your tycoon layout
		const offset = new Vector3((machineId - 1) * 8, 0, 0);
		return plot.CFrame.add(offset);
	}

	private getDecorationPosition(decorationId: number, plot: BasePart): CFrame {
		const offset = new Vector3((decorationId - 1) * 4, 0, 10);
		return plot.CFrame.add(offset);
	}

	public getPlayerTycoon(player: Player): TycoonData | undefined {
		const tycoonId = this.playerTycoons.get(player);
		if (tycoonId === undefined) return undefined;
		return this.tycoons.get(tycoonId);
	}

	public getTycoonId(player: Player): number | undefined {
		return this.playerTycoons.get(player);
	}
}
