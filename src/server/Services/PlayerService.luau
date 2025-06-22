local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
-- local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)

local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)
local DefaultPlayerData = require(ReplicatedStorage.Shared.Config.PlayerData)
local TyconnService = require(script.Parent.TycoonService)

local PlayerService = {}

function PlayerService.onPlayerAdded(player)
	if player == nil then
		warn("Player is nil")
		return
	end
	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "Data"
	dataFolder.Parent = player

	for key, value in pairs(DefaultPlayerData) do
		if type(value) == "table" then
			local subFolder = Instance.new("Folder")
			subFolder.Name = key
			subFolder.Parent = dataFolder

			for subKey, subValue in pairs(value) do
				local valueObject
				if type(subValue) == "number" then
					valueObject = Instance.new("NumberValue")
				elseif type(subValue) == "string" then
					valueObject = Instance.new("StringValue")
				elseif type(subValue) == "boolean" then
					valueObject = Instance.new("BoolValue")
				else
					valueObject = Instance.new("StringValue")
					subValue = tostring(subValue)
				end
				valueObject.Name = subKey
				valueObject.Value = subValue
				valueObject.Parent = subFolder
			end
		else
			local valueObject
			if type(value) == "number" then
				valueObject = Instance.new("NumberValue")
			elseif type(value) == "string" then
				valueObject = Instance.new("StringValue")
			elseif type(value) == "boolean" then
				valueObject = Instance.new("BoolValue")
			else
				valueObject = Instance.new("StringValue")
				value = tostring(value)
			end
			valueObject.Name = key
			valueObject.Value = value
			valueObject.Parent = dataFolder
		end
	end

	local moneyValue = dataFolder:FindFirstChild("Money")
	if moneyValue then
		moneyValue.Value = GameConfig.STARTING_MONEY
	end

	MoneyService.setupLeaderstats(player)
	PollutionService.setupLeaderstats(player)
	TyconnService.assignTycoon(player)
end

function PlayerService.init()
	Players.PlayerAdded:Connect(PlayerService.onPlayerAdded)
end

function PlayerService.updatePlayer()
	for _, player in Players:GetPlayers() do
		if player == nil then
			warn("Player is nil")
			return
		end

		-- Utiliser le nouveau système pour calculer les revenus
		local PurchasableService = require(script.Parent.PurchasableService)
		local totalIncome = PurchasableService.calculateTotalIncome(player)
		PollutionService.addPollution(player, totalIncome)
	end
end

return PlayerService
