local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local DecorationConfig = require(ReplicatedStorage.Shared.Config.DecorationConfig)
local ButtonConfig = require(ReplicatedStorage.Shared.Config.ButtonConfig)

local Workspace = game:GetService("Workspace")
local TycoonService = require(script.Parent.TycoonService)
local PurchasableService = require(script.Parent.PurchasableService)
local MoneyService = require(script.Parent.MoneyService)
local ButtonService = {}

function ButtonService.init()
	-- Écouter l'événement pour mettre à jour les boutons immédiatement
	local updateButtonsEvent = ReplicatedStorage:WaitForChild("UpdateButtons")
	updateButtonsEvent.Event:Connect(function()
		ButtonService.updateButton()
	end)

	for _, Button in CollectionService:GetTagged("TycoonButton") do
		local buttonId = Button:GetAttribute("machineId")
		if not buttonId or not ButtonConfig[buttonId] then
			warn("Button mal configuré:", buttonId)
			continue
		end

		local buttonConfig = ButtonConfig[buttonId]
		local buttonType = buttonConfig.Type
		local targetId = buttonConfig.TargetId

		-- Obtenir les infos en fonction du type
		local cost, name
		if buttonType == "Machine" then
			local machineConfig = MachineConfig[targetId]
			cost = machineConfig.BaseCost
			name = machineConfig.Name
		elseif buttonType == "Decoration" then
			local decorationConfig = DecorationConfig[targetId]
			cost = decorationConfig.BaseCost
			name = decorationConfig.Name
		end

		Button.Cost:GetChildren()[1].Text = buttonConfig.Text or (name .. " " .. cost .. " $")

		Button.Touched:Connect(function(hit)
			if Button:GetAttribute("Unlocked") then
				return
			end

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

			local success = false
			if buttonType == "Machine" then
				success = PurchasableService.unlockMachine(player, targetId)
			elseif buttonType == "Decoration" then
				success = PurchasableService.unlockDecoration(player, targetId)
			end

			if not success then
				return
			end

			ButtonService.hideButton(Button)
			Button:SetAttribute("Unlocked", true)
			ButtonService.requireButton(Button, player)
		end)

		-- Afficher le premier bouton par défaut
		if buttonId == 1 or buttonId == 1001 then -- Premier bouton machine ou décoration
			ButtonService.buttonShow(Button)
		else
			ButtonService.hideButton(Button)
		end
	end
end

function ButtonService.updateButton()
	for _, button in CollectionService:GetTagged("TycoonButton") do
		if not button:IsDescendantOf(Workspace.Tycoons) then
			continue
		end

		local buttonId = button:GetAttribute("machineId")
		if not buttonId or not ButtonConfig[buttonId] then
			continue
		end

		local buttonConfig = ButtonConfig[buttonId]
		local buttonType = buttonConfig.Type
		local targetId = buttonConfig.TargetId

		-- Obtenir le coût en fonction du type
		local cost
		if buttonType == "Machine" then
			cost = MachineConfig[targetId].BaseCost
		elseif buttonType == "Decoration" then
			cost = DecorationConfig[targetId].BaseCost
		end

		local playerId = button.Parent.Parent:GetAttribute("UserId")
		print("playerId: " .. playerId)
		if playerId == nil or type(playerId) ~= "number" then
			return
		end

		local player = game.Players:GetPlayerByUserId(playerId)
		if cost and player then
			if MoneyService.canAfford(player, cost) then
				button.Color = Color3.fromRGB(42, 221, 42)
			else
				button.Color = Color3.fromRGB(196, 40, 28)
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

function ButtonService.buttonShow(button)
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

function ButtonService.requireButton(parentButton, player)
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
		if parentButton:GetAttribute("Unlocked") then
			ButtonService.buttonShow(childButton)
		else
			ButtonService.hideButton(childButton)
		end
	end
end

return ButtonService
