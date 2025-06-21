local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local buttonModel = Workspace.Template.Button

local ButtonService = {}

function ButtonService.Init() end

-- function ButtonService.CreateButton(player, position, cost)
-- 	local button = buttonModel:Clone()
-- 	button.Parent = Workspace.World
-- 	button.Position = position
-- 	button.Transparency = 0
-- 	button.CanCollide = false
-- 	button.Anchored = true

-- 	button:SetAttribute("Cost", cost)
-- 	button:SetAttribute("Player", player.UserId)

-- 	button.Touched:Connect(function(hit)
-- 		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
-- 		if player then
-- 			print(player.Name .. " a touché le bouton rouge!")
-- 		end
-- 	end)

-- 	local BillBoardGui = button:FindFirstChild("Cost")
-- 	local Label = BillBoardGui:FindFirstChild("Label")
-- 	Label.Text = cost .. " $"
-- 	BillBoardGui.Enabled = true
-- end

function ButtonService.UpdateButton()
	for _, button in CollectionService:GetTagged("TycoonButton") do
		local cost = button:GetAttribute("Cost")
		local playerId = button:GetAttribute("Player")
		local player = game.Players:GetPlayerByUserId(playerId)
		if cost and player then
			print(cost, player.leaderstats.Money.Value)
			if cost > player.leaderstats.Money.Value then
				button.Color = Color3.fromRGB(196, 40, 28)
			else
				button.Color = Color3.fromRGB(42, 221, 42)
			end
		end
	end
end

return ButtonService
