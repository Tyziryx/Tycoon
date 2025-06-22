local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)

local Workspace = game:GetService("Workspace")
local TycoonService = require(script.Parent.TycoonService)
local MachineService = require(script.Parent.MachineService)
local MoneyService = require(script.Parent.MoneyService)
local ButtonService = {}

function ButtonService.init()
	-- Écouter l'événement pour mettre à jour les boutons immédiatement
	local updateButtonsEvent = ReplicatedStorage:WaitForChild("UpdateButtons")
	updateButtonsEvent.Event:Connect(function()
		ButtonService.updateButton()
	end)

	for _, Button in CollectionService:GetTagged("TycoonButton") do
		local machineId = Button:GetAttribute("machineId")
		local Cost = MachineConfig[machineId].BaseCost
		local MachineName = MachineConfig[machineId].Name

		Button.Cost:GetChildren()[1].Text = MachineName .. " " .. Cost .. " $"

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

			local success = MachineService.unlockMachine(player, machineId)
			if not success then
				return
			end

			ButtonService.hideButton(Button)
			Button:SetAttribute("Unlocked", true)
			ButtonService.requireButton(Button, player)
		end)
		if machineId == 1 then
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
		local machineId = button:GetAttribute("machineId")
		local cost = MachineConfig[machineId].BaseCost
		local playerId = button.Parent.Parent:GetAttribute("UserId")

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
