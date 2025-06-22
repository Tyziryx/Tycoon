local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)

local Workspace = game:GetService("Workspace")
local TycoonService = require(script.Parent.TycoonService)
local MachineService = require(script.Parent.MachineService)
local MoneyService = require(script.Parent.MoneyService)
local ButtonService = {}

function ButtonService.Init()
	for _, Button in CollectionService:GetTagged("TycoonButton") do
		local machineId = Button:GetAttribute("machineId")
		local Machine = MachineService.GetMachine(machineId)
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

			local tycoon = TycoonService.GetTycoon(player)

			if not tycoon then
				return
			end
			if not Button:IsDescendantOf(tycoon) then
				return
			end

			local success = MachineService.UnlockMachine(player, machineId)
			if not success then
				return
			end
			Button.Transparency = 1
			Button.Cost.Enabled = false
			Button:SetAttribute("Unlocked", true)
			ButtonService.RequireButton(Button, player)
		end)
		if machineId == 1 then
			ButtonService.ButtonShow(Button)
		else
			ButtonService.HideButton(Button)
		end
	end
end

function ButtonService.UpdateButton()
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
			if MoneyService.CanAfford(player, cost) then
				button.Color = Color3.fromRGB(42, 221, 42)
			else
				button.Color = Color3.fromRGB(196, 40, 28)
			end
		end
	end
end

function ButtonService.HideButton(button)
	if button:IsA("BasePart") then
		button.Transparency = 1
		button.Cost.Enabled = false
		if button:FindFirstChild("ClickDetector") then
			button.ClickDetector.MaxActivationDistance = 0
		end
	end
end

function ButtonService.ButtonShow(button)
	if button:IsA("BasePart") then
		button.Transparency = 0
		button.Cost.Enabled = true
		if button:FindFirstChild("ClickDetector") then
			button.ClickDetector.MaxActivationDistance = 32
		end
	end
end
function ButtonService.GetButton(machineId)
	for _, button in CollectionService:GetTagged("TycoonButton") do
		if button:GetAttribute("machineId") == machineId then
			return button
		end
	end
	return nil
end

function ButtonService.RequireButton(parentButton, player)
	local machineId = parentButton:GetAttribute("machineId")
	local requiredButtonId = MachineConfig[machineId].NextButton
	local childButton = ButtonService.GetButton(requiredButtonId)
	if childButton then
		if parentButton:GetAttribute("Unlocked") then
			ButtonService.ButtonShow(childButton)
		else
			ButtonService.HideButton(childButton)
		end
	end
end

return ButtonService
