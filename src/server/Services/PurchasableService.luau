local PurchasableService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local DecorationConfig = require(ReplicatedStorage.Shared.Config.DecorationConfig)

local Machine = require(script.Parent.Parent.Classes.Machine)
local Decoration = require(script.Parent.Parent.Classes.Decoration)

local purchasableTemplates = {}
local playerPurchasables = {}

local function getPlayerBucket(player)
	local userId = player.UserId
	playerPurchasables[userId] = playerPurchasables[userId] or {}
	return playerPurchasables[userId]
end

function PurchasableService.init()
	for id, config in pairs(MachineConfig) do
		purchasableTemplates[id] = Machine.new(id, config)
	end

	for id, config in pairs(DecorationConfig) do
		local decorationId = id + 1000
		purchasableTemplates[decorationId] = Decoration.new(decorationId, config)
	end
end

function PurchasableService.getPurchasable(id)
	return purchasableTemplates[id]
end

function PurchasableService.getMachine(machineId)
	local purchasable = purchasableTemplates[machineId]
	if purchasable and purchasable.purchasableType == "Machine" then
		return purchasable
	end

	return nil
end

function PurchasableService.getPlayerMachine(player, machineId)
	if not player then
		return nil
	end

	local config = MachineConfig[machineId]
	if not config then
		return nil
	end

	local bucket = getPlayerBucket(player)
	if not bucket[machineId] then
		bucket[machineId] = Machine.new(machineId, config)
	end

	return bucket[machineId]
end

function PurchasableService.getDecoration(decorationId)
	local purchasable = purchasableTemplates[decorationId]
	if purchasable and purchasable.purchasableType == "Decoration" then
		return purchasable
	end

	return nil
end

function PurchasableService.getPlayerDecoration(player, decorationId)
	if not player then
		return nil
	end

	local configId = decorationId - 1000
	local config = DecorationConfig[configId]
	if not config then
		return nil
	end

	local bucket = getPlayerBucket(player)
	if not bucket[decorationId] then
		bucket[decorationId] = Decoration.new(decorationId, config)
	end

	return bucket[decorationId]
end

function PurchasableService.unlockMachine(player, machineId)
	local machine = PurchasableService.getPlayerMachine(player, machineId)
	if not machine then
		warn("Machine introuvable:", machineId)
		return false, "Machine introuvable"
	end

	local TycoonService = require(script.Parent.TycoonService)
	local tycoon = TycoonService.getTycoon(player)
	if not tycoon then
		return false, "Tycoon introuvable"
	end

	return machine:purchase(player, tycoon)
end

function PurchasableService.unlockDecoration(player, decorationId)
	local decoration = PurchasableService.getPlayerDecoration(player, decorationId + 1000)
	if not decoration then
		warn("Decoration introuvable:", decorationId)
		return false, "Decoration introuvable"
	end

	local TycoonService = require(script.Parent.TycoonService)
	local tycoon = TycoonService.getTycoon(player)
	if not tycoon then
		return false, "Tycoon introuvable"
	end

	return decoration:purchase(player, tycoon)
end

function PurchasableService.upgradeMachine(player, machineId)
	local machine = PurchasableService.getPlayerMachine(player, machineId)
	if not machine then
		return false, "Machine introuvable"
	end

	return machine:upgrade(player)
end

function PurchasableService.calculateTotalIncome(player)
	local totalIncome = 0
	local ownedMachines = player.Data.OwnedMachines

	for _, machineData in ownedMachines:GetChildren() do
		local machineId = machineData.Value
		local machine = PurchasableService.getPlayerMachine(player, machineId)
		if machine then
			totalIncome += machine:generateIncome()
		end
	end

	return totalIncome
end

function PurchasableService.getAllMachines()
	local machines = {}
	for id, purchasable in pairs(purchasableTemplates) do
		if purchasable.purchasableType == "Machine" then
			machines[id] = purchasable
		end
	end

	return machines
end

function PurchasableService.getAllDecorations()
	local decorations = {}
	for id, purchasable in pairs(purchasableTemplates) do
		if purchasable.purchasableType == "Decoration" then
			decorations[id] = purchasable
		end
	end

	return decorations
end

function PurchasableService.getMachineModel(machineId)
	local machine = PurchasableService.getMachine(machineId)
	if machine then
		return machine:getAssetModel()
	end

	return nil
end

function PurchasableService.clearPlayer(player)
	if player then
		playerPurchasables[player.UserId] = nil
	end
end

return PurchasableService
