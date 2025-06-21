local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MoneyService = require(script.Parent.MoneyService)
local DefaultPlayerData = require(script.Parent.Parent.Data.PlayerData)
local ButtonService = require(script.Parent.ButtonService)

local PlayerService = {}

function PlayerService.OnPlayerAdded(player)
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
		print("Money set to " .. GameConfig.STARTING_MONEY)
	end

	MoneyService.SetupLeaderstats(player)

	ButtonService.CreateButton(player, Vector3.new(0, 8, 0), 100)
	ButtonService.CreateButton(player, Vector3.new(6, 8, 0), 200)
end

function PlayerService.Init()
	Players.PlayerAdded:Connect(PlayerService.OnPlayerAdded)
end

function PlayerService.UpdatePlayer()
	for _, player in Players:GetPlayers() do
		MoneyService.AddMoney(player, 20)
	end
end

return PlayerService
