local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
-- local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)

local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)
local DefaultPlayerData = require(ReplicatedStorage.Shared.Config.PlayerData)
local ZoneService = require(script.Parent.ZoneService)
local RebirthService = require(script.Parent.RebirthService)
local ShopService = require(script.Parent.ShopService)
local MachineInventoryService = require(script.Parent.MachineInventoryService)

local PlayerService = {}

local function createValueObject(name, value, parent)
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

	valueObject.Name = tostring(name)
	valueObject.Value = value
	valueObject.Parent = parent
	return valueObject
end

local function populateDataFolder(parent, data)
	for key, value in pairs(data) do
		if type(value) == "table" then
			local subFolder = Instance.new("Folder")
			subFolder.Name = tostring(key)
			subFolder.Parent = parent
			populateDataFolder(subFolder, value)
		else
			createValueObject(key, value, parent)
		end
	end
end

function PlayerService.onPlayerAdded(player)
	if player == nil then
		warn("Player is nil")
		return
	end
	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "Data"
	dataFolder.Parent = player

	populateDataFolder(dataFolder, DefaultPlayerData)
	ShopService.setupPlayer(player)
	MachineInventoryService.setupPlayer(player)

	local moneyValue = dataFolder:FindFirstChild("Money")
	if moneyValue then
		moneyValue.Value = GameConfig.STARTING_MONEY
	end

	MoneyService.setupLeaderstats(player)
	PollutionService.setupLeaderstats(player)
	RebirthService.setupLeaderstats(player)
	MachineInventoryService.setupLeaderstats(player)
	ZoneService.setupPlayer(player)
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

		local PurchasableService = require(script.Parent.PurchasableService)
		local totalIncome = PurchasableService.calculateTotalIncome(player)
		PollutionService.addPollution(player, totalIncome)
	end
end

return PlayerService
