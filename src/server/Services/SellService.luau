local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SellService = {}

-- Créer un événement pour notifier les mises à jour
local updateButtonsEvent = Instance.new("BindableEvent")
updateButtonsEvent.Name = "UpdateButtons"
updateButtonsEvent.Parent = ReplicatedStorage

function SellService.init(tycoon)
	if tycoon == nil then
		warn("Player is nil")
		return
	end

	if tycoon == nil then
		warn("Tycoon is nil")
		return
	end
	local Decoration = tycoon:FindFirstChild("Decoration")
	if Decoration == nil then
		warn("Decorations is nil")
		return
	end
	local Mafia = Decoration:FindFirstChild("Mafia")
	if Mafia == nil then
		warn("Mafia is nil")
		return
	end
	local PromptBlock = Mafia:FindFirstChild("PromptBlock")
	if PromptBlock == nil then
		warn("PromptBlock is nil")
		return
	end
	local Prompt = PromptBlock:FindFirstChild("ProximityPrompt")
	if Prompt == nil then
		warn("ProximityPrompt is nil")
		return
	end
	Prompt.Triggered:Connect(function(player)
		if player == nil then
			warn("Player is nil")
			return
		end
		local pollution = PollutionService.getPollution(player)
		if pollution == nil then
			warn("Pollution is nil")
			return
		end
		PollutionService.removePollution(player, pollution)
		MoneyService.addMoney(player, pollution)
		updateButtonsEvent:Fire()
	end)
end

return SellService
