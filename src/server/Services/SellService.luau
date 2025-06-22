local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)
local SellService = {}

function SellService.Init(tycoon)
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
		local pollution = PollutionService.GetPollution(player)
		if pollution == nil then
			warn("Pollution is nil")
			return
		end
		PollutionService.RemovePollution(player, pollution)
		MoneyService.AddMoney(player, pollution)
	end)
end

return SellService
