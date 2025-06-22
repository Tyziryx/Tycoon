local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)

local MoneyService = require(script.Parent.MoneyService)
local DefaultPlayerData = require(script.Parent.Parent.Data.PlayerData)
local TyconnService = require(script.Parent.TycoonService)

local PlayerService = {}

function PlayerService.OnPlayerAdded(player)
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

	MoneyService.SetupLeaderstats(player)
	TyconnService.AssignTycoon(player)
end

function PlayerService.Init()
	Players.PlayerAdded:Connect(PlayerService.OnPlayerAdded)
end

function PlayerService.UpdatePlayer()
	for _, player in Players:GetPlayers() do
		if player == nil then
			warn("Player is nil")
			return
		end
		local totalIncome = 0
		local ownedMachines = player.Data.OwnedMachines
		for _, machine in ownedMachines:GetChildren() do
			local machineId = machine.Value
			local machineConfig = MachineConfig[machineId]
			local income = machineConfig.BaseIncome
			totalIncome = totalIncome + income
		end
		MoneyService.AddMoney(player, totalIncome)
	end
end

return PlayerService
