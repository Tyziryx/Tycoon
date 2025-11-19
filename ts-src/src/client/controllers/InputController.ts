import { Controller, OnStart } from "@flamework/core";
import { UserInputService } from "@rbxts/services";
import { GlobalEvents } from "shared/network";

@Controller()
export class InputController implements OnStart {
	onStart() {
		// Set up keybinds
		UserInputService.InputBegan.Connect((input, gameProcessed) => {
			if (gameProcessed) return;

			this.handleInput(input);
		});

		print("[InputController] Input Controller started");
	}

	private handleInput(input: InputObject) {
		// E key - Convert pollution
		if (input.KeyCode === Enum.KeyCode.E) {
			GlobalEvents.client.convertPollution();
		}
	}
}
