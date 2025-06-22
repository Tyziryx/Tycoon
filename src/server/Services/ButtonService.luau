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
		end)
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

return ButtonService
