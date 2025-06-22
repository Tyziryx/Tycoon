local Tycoons = game.Workspace:WaitForChild("Tycoons")
local TycoonService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceholderTycoon = ReplicatedStorage:WaitForChild("Tycoon")
local CollectionService = game:GetService("CollectionService")
local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)

-- Créer un événement pour notifier les mises à jour des boutons
local updateButtonsEvent = Instance.new("BindableEvent")
updateButtonsEvent.Name = "UpdateButtons"
updateButtonsEvent.Parent = ReplicatedStorage

function TycoonService.init()
	for _, Tycoon in CollectionService:GetTagged("Tycoon") do
		if Tycoon:IsDescendantOf(ReplicatedStorage) then
			continue
		end
		Tycoon.Machines:ClearAllChildren()
	end
end

function TycoonService.assignTycoon(player)
	if player == nil then
		warn("Player is nil")
		return nil
	end
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("Taken") then
			continue
		end
		tycoon:SetAttribute("Taken", true)
		tycoon:SetAttribute("UserId", player.UserId)

		TycoonService.initializeSellPoint(tycoon)
		return tycoon
	end
	return nil
end

function TycoonService.getTycoon(player)
	if player == nil then
		warn("Player is nil")
		return nil
	end
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("UserId") == player.UserId then
			return tycoon
		end
	end
	return nil
end

function TycoonService.getMachineInTycoonById(machineId)
	if machineId == nil then
		warn("MachineId is nil")
		return nil
	end
	for _, Machine in PlaceholderTycoon.Machines:GetChildren() do
		if Machine:GetAttribute("Id") == machineId then
			return Machine
		end
	end
	warn("Machine not found")
	return nil
end

function TycoonService.getRelativeCFrame(machineId)
	if machineId == nil then
		warn("MachineId is nil")
		return nil
	end
	local Machines = TycoonService.getMachineInTycoonById(machineId)

	local RelativeCF = PlaceholderTycoon.PrimaryPart.CFrame:toObjectSpace(Machines:GetPivot())
	return RelativeCF
end

function TycoonService.getRelativeDecorationCFrame(decorationId)
	if decorationId == nil then
		warn("DecorationId is nil")
		return nil
	end

	-- Pour l'instant, on utilise des positions prédéfinies
	-- Plus tard, vous pourrez avoir un système de positionnement plus sophistiqué
	local decorationPositions = {
		[1] = CFrame.new(5, 0, 5), -- BasicBench
		[2] = CFrame.new(-3, 0, 8), -- FlowerPot
		[3] = CFrame.new(10, 0, -5), -- StreetLamp
		[4] = CFrame.new(0, 0, 12), -- FancyStatue
	}

	return decorationPositions[decorationId]
end

function TycoonService.initializeSellPoint(tycoon)
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

return TycoonService
