local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TycoonService = require(script.Parent.TycoonService)
local MachineService = require(script.Parent.MachineService)
local MoneyService = require(script.Parent.MoneyService)
local ButtonService = {}

function ButtonService.Init()
	for _, Button in CollectionService:GetTagged("TycoonButton") do
		Button.Touched:Connect(function(hit)
			print("Touched by: ", hit:GetFullName())
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

			local success = MachineService.UnlockMachine(player, Button:GetAttribute("machineId"))
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
		local cost = tonumber(button:GetAttribute("Cost"))
		print(button.Parent.Parent:GetAttribute("UserId"))
		local playerId = button.Parent.Parent:GetAttribute("UserId")
		print("Button: ", button.Name, " Cost: ", cost, " PlayerId: ", playerId, "Parent ", button.Parent.Parent)

		if playerId == nil and playerId.IsA(string) then
			return
		end
		local player = game.Players:GetPlayerByUserId(playerId)
		print("Player: ", player and player.Name or "nil")
		if cost and player then
			print(cost, player.leaderstats.Money.Value)
			if MoneyService.CanAfford(player, cost) then
				button.Color = Color3.fromRGB(42, 221, 42)
			else
				button.Color = Color3.fromRGB(196, 40, 28)
			end
		end
	end
end

return ButtonService
