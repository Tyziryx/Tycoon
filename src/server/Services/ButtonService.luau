local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local DecorationConfig = require(ReplicatedStorage.Shared.Config.DecorationConfig)

local Workspace = game:GetService("Workspace")
local TycoonService = require(script.Parent.TycoonService)
local PurchasableService = require(script.Parent.PurchasableService)
local MoneyService = require(script.Parent.MoneyService)
local ButtonService = {}

local redButton = Color3.fromRGB(196, 81, 81)
local greenButton = Color3.fromRGB(42, 221, 42)
local blueButton = Color3.fromRGB(100, 150, 255)

function ButtonService.init()
	-- Écouter l'événement pour mettre à jour les boutons immédiatement
	local updateButtonsEvent = ReplicatedStorage:WaitForChild("UpdateButtons")
	updateButtonsEvent.Event:Connect(function()
		ButtonService.updateButton()
	end)

	for _, Button in CollectionService:GetTagged("TycoonButton") do
		local buttonId = Button:GetAttribute("machineId")
		if not buttonId then
			warn("Button mal configuré:", buttonId)
			continue
		end

		-- Obtenir les infos en fonction du type
		local cost, name
		if buttonId < 1000 then
			local machineConfig = MachineConfig[buttonId]
			cost = machineConfig.BaseCost
			name = machineConfig.Name
		elseif buttonId >= 1000 then
			local decorationConfig = DecorationConfig[buttonId]
			cost = decorationConfig.BaseCost
			name = decorationConfig.Name
		end

		Button.Cost:GetChildren()[1].Text = name .. " " .. cost .. " $"

		Button.Touched:Connect(function(hit)
			if Button:GetAttribute("Unlocked") then
				return
			end

			-- Vérifier si le bouton est temporairement désactivé
			if Button:GetAttribute("TempDisabled") then
				return
			end

			-- Protection anti-spam : éviter les clics multiples rapides
			local lastClickTime = Button:GetAttribute("LastClickTime") or 0
			local currentTime = tick()
			if currentTime - lastClickTime < 0.5 then -- Délai de 1 seconde
				return
			end
			Button:SetAttribute("LastClickTime", currentTime)
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local tycoon = TycoonService.getTycoon(player)
			if not tycoon then
				return
			end
			if not Button:IsDescendantOf(tycoon) then
				return
			end

			local targetId
			if buttonId < 1000 then
				targetId = buttonId
			else
				targetId = buttonId - 1000
			end

			-- Vérifier si le joueur possède cette machine
			local playerOwnsMachine = ButtonService.playerOwnsMachine(player, targetId)

			if not playerOwnsMachine then
				-- ACHAT - Le joueur ne possède pas encore cette machine
				local success = PurchasableService.unlockMachine(player, targetId)
				if success then
					-- Désactiver temporairement le bouton pour éviter les clics multiples
					Button:SetAttribute("TempDisabled", true)

					ButtonService.convertToUpgradeButton(Button, targetId)
					ButtonService.showNextButton(Button, player)

					-- Réactiver le bouton après 1 seconde
					wait(1)
					Button:SetAttribute("TempDisabled", false)
				end
			else
				-- UPGRADE - Le joueur possède déjà cette machine
				ButtonService.handleUpgrade(Button, player, targetId)
			end
		end)

		-- Afficher le premier bouton par défaut
		if buttonId == 1 or buttonId == 1001 then -- Premier bouton machine ou décoration
			ButtonService.showButton(Button)
		else
			ButtonService.hideButton(Button)
		end
	end
end

function ButtonService.updateButton()
	for _, button in CollectionService:GetTagged("TycoonButton") do
		-- Vérifications
		if not button:IsDescendantOf(Workspace.Tycoons) then
			continue
		end
		local buttonId = button:GetAttribute("machineId")
		if not buttonId then
			continue
		end

		-- Obtenir le coût en fonction du type
		local cost
		if buttonId < 1000 then
			cost = MachineConfig[buttonId].BaseCost
		elseif buttonId >= 1000 then
			cost = DecorationConfig[buttonId].BaseCost
		end

		local playerId = button.Parent.Parent:GetAttribute("UserId")
		if playerId == nil or type(playerId) ~= "number" then
			return
		end

		local player = game.Players:GetPlayerByUserId(playerId)
		local isUpgradeButton = button:GetAttribute("IsUpgradeButton")

		if isUpgradeButton then
			-- Logique pour boutons d'upgrade
			local machine = PurchasableService.getMachine(buttonId)
			if player and machine and machine:canUpgrade() then
				local upgradeCost = machine:getUpgradeCost()
				if MoneyService.canAfford(player, upgradeCost) then
					button.Color = blueButton -- Bleu si peut upgrade
				else
					button.Color = redButton -- Rouge si pas assez d'argent
				end
			end
		else
			-- Logique pour boutons d'achat
			if cost and player then
				if MoneyService.canAfford(player, cost) then
					button.Color = greenButton
				else
					button.Color = redButton
				end
			end
		end
	end
end

function ButtonService.hideButton(button)
	if button == nil then
		warn("Button is nil")
		return
	end
	if button:IsA("BasePart") then
		button.Transparency = 1
		if button:FindFirstChild("Base") then
			button.Base.Transparency = 1
		end
		button.Cost.Enabled = false
		if button:FindFirstChild("ClickDetector") then
			button.ClickDetector.MaxActivationDistance = 0
		end
	end
end

function ButtonService.showButton(button)
	if button == nil then
		warn("Button is nil")
		return
	end
	if button:IsA("BasePart") then
		button.Transparency = 0
		if button:FindFirstChild("Base") then
			button.Base.Transparency = 0
		end
		button.Cost.Enabled = true
		if button:FindFirstChild("ClickDetector") then
			button.ClickDetector.MaxActivationDistance = 32
		end
	end
end
function ButtonService.getButton(machineId)
	for _, button in CollectionService:GetTagged("TycoonButton") do
		if button:GetAttribute("machineId") == machineId then
			return button
		end
	end
	return nil
end

function ButtonService.showNextButton(parentButton, player)
	if parentButton == nil then
		warn("ParentButton is nil")
		return
	end
	if player == nil then
		warn("Player is nil")
		return
	end
	local machineId = parentButton:GetAttribute("machineId")
	local requiredButtonId = MachineConfig[machineId].NextButton
	local childButton = ButtonService.getButton(requiredButtonId)
	if childButton then
		ButtonService.showButton(childButton)
	end
end

function ButtonService.convertToUpgradeButton(button, machineId)
	-- Changer l'apparence
	button.Color = redButton

	-- Changer le texte
	ButtonService.updateUpgradeButtonText(button, machineId)

	-- Marquer comme bouton d'upgrade
	button:SetAttribute("IsUpgradeButton", true)
end

function ButtonService.updateUpgradeButtonText(button, machineId)
	local machine = PurchasableService.getMachine(machineId)

	local name
	local machineConfig = MachineConfig[machineId]
	name = machineConfig.Name
	if machine:canUpgrade() then
		local upgradeCost = machine:getUpgradeCost()
		local nextLevel = machine.currentLevel + 1
		button.Cost:GetChildren()[1].Text = "Upgrade " .. name .. " Lvl." .. nextLevel .. " - " .. upgradeCost .. "$"
	end
end

function ButtonService.handleUpgrade(button, player, machineId)
	local machine = PurchasableService.getMachine(machineId)

	if not machine:canUpgrade() then
		return
	end

	local success = PurchasableService.upgradeMachine(player, machineId)
	-- Vérifier si la machine a atteint le niveau maximum après l'upgrade
	if machine.currentLevel >= machine.maxLevel then
		button:Destroy()
		return
	end

	if success then
		ButtonService.updateUpgradeButtonText(button, machineId)
	end
end

function ButtonService.playerOwnsMachine(player, machineId)
	local ownedMachines = player.Data.OwnedMachines

	for _, machineData in ownedMachines:GetChildren() do
		if machineData.Value == machineId then
			return true
		end
	end
	return false
end

return ButtonService
