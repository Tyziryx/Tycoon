local Tycoons = game.Workspace:WaitForChild("Tycoons")
local TycoonService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)

-- Table pour stocker les positions relatives originales des machines
local originalMachinePositions = {}

-- Créer un événement pour notifier les mises à jour des boutons
local updateButtonsEvent = Instance.new("BindableEvent")
updateButtonsEvent.Name = "UpdateButtons"
updateButtonsEvent.Parent = ReplicatedStorage

function TycoonService.init()
	-- Sauvegarder les positions relatives des machines originales avant de les supprimer
	for _, Tycoon in CollectionService:GetTagged("Tycoon") do
		if Tycoon:IsDescendantOf(ReplicatedStorage) then
			continue
		end

		-- Sauvegarder les positions relatives des machines par rapport au tycoon
		for _, machine in Tycoon.Machines:GetChildren() do
			local machineId = machine:GetAttribute("Id")
			if machineId and Tycoon.PrimaryPart then
				-- Calculer la position relative de la machine par rapport au tycoon
				local relativeCFrame = Tycoon.PrimaryPart.CFrame:toObjectSpace(machine:GetPivot())
				originalMachinePositions[machineId] = relativeCFrame
				print("Position sauvegardée pour machine", machineId, ":", relativeCFrame)
			end
		end

		-- Maintenant supprimer les machines
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

-- Fonction supprimée car plus nécessaire avec le système de configuration statique

function TycoonService.getRelativeCFrame(machineId)
	if machineId == nil then
		warn("MachineId is nil")
		return CFrame.new(0, 0, 0)
	end

	-- Utiliser la position originale sauvegardée de la machine
	local originalPosition = originalMachinePositions[machineId]
	if originalPosition then
		return originalPosition
	end

	-- Fallback: positions par défaut si la position originale n'est pas trouvée
	local defaultPositions = {
		[1] = CFrame.new(0, 0, 0), -- Premier campfire
		[2] = CFrame.new(8, 0, 0), -- Deuxième campfire
		[3] = CFrame.new(16, 0, 0), -- Troisième campfire
	}

	warn("Position originale non trouvée pour machine ID:", machineId, "- Utilisation position par défaut")
	return defaultPositions[machineId] or CFrame.new(0, 0, 0)
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

		local moneyToAdd = math.floor(pollution / 10)
		if pollution > 0 and moneyToAdd == 0 then
			moneyToAdd = 1
		end
		PollutionService.removePollution(player, pollution)
		MoneyService.addMoney(player, moneyToAdd)
		updateButtonsEvent:Fire()
	end)
end

-- Fonction pour récupérer les positions originales sauvegardées (utile pour debug)
function TycoonService.getOriginalMachinePositions()
	return originalMachinePositions
end

return TycoonService
