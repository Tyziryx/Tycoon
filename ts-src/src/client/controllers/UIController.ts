import { Controller, OnStart } from "@flamework/core";
import { Players, StarterGui } from "@rbxts/services";
import { GlobalEvents } from "shared/network";
import { PlayerData } from "shared/types";

@Controller()
export class UIController implements OnStart {
	private player = Players.LocalPlayer;
	private playerGui = this.player.WaitForChild("PlayerGui") as PlayerGui;
	private playerData?: PlayerData;

	// UI Elements
	private moneyLabel?: TextLabel;
	private pollutionLabel?: TextLabel;
	private notificationFrame?: Frame;

	onStart() {
		// Set up UI references
		this.setupUIReferences();

		// Connect to server events
		this.connectEvents();

		print("[UIController] UI Controller started");
	}

	private setupUIReferences() {
		// Wait for UI to load
		const mainGui = this.playerGui.WaitForChild("MainGui", 5) as ScreenGui;
		if (!mainGui) {
			warn("[UIController] MainGui not found");
			return;
		}

		// Find money display
		this.moneyLabel = mainGui.FindFirstChild("MoneyLabel", true) as TextLabel;

		// Find pollution display
		this.pollutionLabel = mainGui.FindFirstChild("PollutionLabel", true) as TextLabel;

		// Find notification frame
		this.notificationFrame = mainGui.FindFirstChild("NotificationFrame", true) as Frame;
	}

	private connectEvents() {
		// Money updates
		GlobalEvents.client.connect("updateMoney", (amount) => {
			this.updateMoneyDisplay(amount);
		});

		// Pollution updates
		GlobalEvents.client.connect("updatePollution", (amount) => {
			this.updatePollutionDisplay(amount);
		});

		// Initial data sync
		GlobalEvents.client.connect("syncPlayerData", (data) => {
			this.playerData = data;
			this.updateMoneyDisplay(data.money);
			this.updatePollutionDisplay(data.pollution);
		});

		// Notifications
		GlobalEvents.client.connect("notify", (message, notificationType) => {
			this.showNotification(message, notificationType);
		});

		// Purchase confirmations
		GlobalEvents.client.connect("machineUnlocked", (machineId) => {
			print(`[UIController] Machine ${machineId} unlocked`);
		});

		GlobalEvents.client.connect("machineUpgraded", (machineId, newLevel) => {
			print(`[UIController] Machine ${machineId} upgraded to level ${newLevel}`);
		});

		GlobalEvents.client.connect("decorationUnlocked", (decorationId) => {
			print(`[UIController] Decoration ${decorationId} unlocked`);
		});

		GlobalEvents.client.connect("zoneUnlocked", (zoneId) => {
			print(`[UIController] Zone ${zoneId} unlocked`);
		});
	}

	private updateMoneyDisplay(amount: number) {
		if (this.moneyLabel) {
			this.moneyLabel.Text = `$${this.formatNumber(amount)}`;
		}
	}

	private updatePollutionDisplay(amount: number) {
		if (this.pollutionLabel) {
			this.pollutionLabel.Text = `Pollution: ${this.formatNumber(amount)}`;
		}
	}

	private formatNumber(num: number): string {
		if (num >= 1000000) {
			return `${(num / 1000000).toFixed(1)}M`;
		} else if (num >= 1000) {
			return `${(num / 1000).toFixed(1)}K`;
		}
		return tostring(num);
	}

	private showNotification(message: string, notificationType: "success" | "error" | "info") {
		// Create notification UI
		const notification = new Instance("TextLabel");
		notification.Size = new UDim2(0.3, 0, 0, 40);
		notification.Position = new UDim2(0.35, 0, 0.1, 0);
		notification.AnchorPoint = new Vector2(0, 0);
		notification.BackgroundTransparency = 0.3;
		notification.TextColor3 = Color3.fromRGB(255, 255, 255);
		notification.TextSize = 16;
		notification.Font = Enum.Font.GothamBold;
		notification.Text = message;

		// Set color based on type
		switch (notificationType) {
			case "success":
				notification.BackgroundColor3 = Color3.fromRGB(46, 204, 113);
				break;
			case "error":
				notification.BackgroundColor3 = Color3.fromRGB(231, 76, 60);
				break;
			case "info":
				notification.BackgroundColor3 = Color3.fromRGB(52, 152, 219);
				break;
		}

		// Add to screen
		const screenGui = this.playerGui.FindFirstChild("MainGui") as ScreenGui;
		if (screenGui) {
			notification.Parent = screenGui;

			// Animate out and destroy
			task.delay(3, () => {
				notification.Destroy();
			});
		}
	}

	// Public methods for other controllers to use
	public getPlayerData(): PlayerData | undefined {
		return this.playerData;
	}

	public getMoney(): number {
		return this.playerData?.money ?? 0;
	}

	public getPollution(): number {
		return this.playerData?.pollution ?? 0;
	}
}
