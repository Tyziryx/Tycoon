local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
-- local buttonModel = Workspace.Template.Button

local ButtonService = {}

function ButtonService.Init() 
	for  _, Button in CollectionService:GetTagged("TycoonButton") do
		if Button:IsA("BasePart") then
			Button.Transparency = 0
			Button.CanCollide = false
			Button.Anchored = true
		end
	end

function ButtonService.UpdateButton()
	-- for _, button in CollectionService:GetTagged("TycoonButton") do
	-- 	local cost = button:GetAttribute("Cost")
	-- 	local playerId = button:GetAttribute("Player")
	-- 	local player = game.Players:GetPlayerByUserId(playerId)
	-- 	if cost and player then
	-- 		print(cost, player.leaderstats.Money.Value)
	-- 		if cost > player.leaderstats.Money.Value then
	-- 			button.Color = Color3.fromRGB(196, 40, 28)
	-- 		else
	-- 			button.Color = Color3.fromRGB(42, 221, 42)
	-- 		end
	-- 	end
	-- end
end

return ButtonService
