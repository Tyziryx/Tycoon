import { Component, BaseComponent, Dependency } from "@flamework/components";
import { OnStart } from "@flamework/core";
import { PurchaseService } from "../services/PurchaseService";
import { DataService } from "../services/DataService";
import { getMachineConfig } from "shared/config/machines";
import { getDecorationConfig } from "shared/config/decorations";
import { GameConstants } from "shared/constants";

interface ButtonAttributes {
	ButtonId: number;
	ButtonType: "machine" | "decoration" | "zone";
	NextButtonId?: number;
}

@Component({
	tag: "TycoonButton",
})
export class ButtonComponent extends BaseComponent<ButtonAttributes, BasePart> implements OnStart {
	private purchaseService = Dependency<PurchaseService>();
	private dataService = Dependency<DataService>();
	private clickDetector?: ClickDetector;

	onStart() {
		// Create or get click detector
		this.clickDetector = this.instance.FindFirstChildOfClass("ClickDetector");
		if (!this.clickDetector) {
			this.clickDetector = new Instance("ClickDetector");
			this.clickDetector.Parent = this.instance;
		}

		this.clickDetector.MaxActivationDistance = GameConstants.BUTTON_MAX_ACTIVATION_DISTANCE;

		// Connect click event
		this.clickDetector.MouseClick.Connect((player) => this.onClicked(player));

		// Set initial visual state
		this.updateVisual();
	}

	private onClicked(player: Player) {
		const buttonId = this.attributes.ButtonId;
		const buttonType = this.attributes.ButtonType;

		const result = this.purchaseService.handlePurchase(player, buttonId, buttonType);

		if (result.success) {
			// Hide this button
			this.instance.Transparency = 1;
			if (this.clickDetector) {
				this.clickDetector.MaxActivationDistance = 0;
			}

			// Show next button if exists
			if (this.attributes.NextButtonId) {
				this.showNextButton(this.attributes.NextButtonId);
			}
		}
	}

	private showNextButton(nextButtonId: number) {
		// Find and enable the next button in the tycoon
		const parent = this.instance.Parent;
		if (!parent) return;

		for (const child of parent.GetChildren()) {
			if (child.IsA("BasePart") && child.GetAttribute("ButtonId") === nextButtonId) {
				child.Transparency = 0;
				const detector = child.FindFirstChildOfClass("ClickDetector");
				if (detector) {
					detector.MaxActivationDistance = GameConstants.BUTTON_MAX_ACTIVATION_DISTANCE;
				}
				break;
			}
		}
	}

	private updateVisual() {
		const buttonType = this.attributes.ButtonType;
		const buttonId = this.attributes.ButtonId;

		let cost = 0;

		if (buttonType === "machine") {
			const config = getMachineConfig(buttonId);
			cost = config?.baseCost ?? 0;
		} else if (buttonType === "decoration") {
			const config = getDecorationConfig(buttonId);
			cost = config?.baseCost ?? 0;
		}

		// Set button color based on cost
		if (cost === 0) {
			this.instance.Color = GameConstants.COLORS.BUTTON_GREEN;
		} else {
			this.instance.Color = GameConstants.COLORS.BUTTON_BLUE;
		}

		// Update BillboardGui if exists
		const gui = this.instance.FindFirstChildOfClass("BillboardGui");
		if (gui) {
			const textLabel = gui.FindFirstChildOfClass("TextLabel");
			if (textLabel) {
				textLabel.Text = cost === 0 ? "FREE" : `$${cost}`;
			}
		}
	}
}
