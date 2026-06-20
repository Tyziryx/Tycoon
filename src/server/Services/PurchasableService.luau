local PurchasableService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local DecorationConfig = require(ReplicatedStorage.Shared.Config.DecorationConfig)

local Machine = require(script.Parent.Parent.Classes.Machine)
local Decoration = require(script.Parent.Parent.Classes.Decoration)

local purchasableInstances = {}

function PurchasableService.init()
	for id, config in pairs(MachineConfig) do
		local machine = Machine.new(id, config)
		purchasableInstances[id] = machine
	end

	for id, config in pairs(DecorationConfig) do
		local decorationId = id + 1000
		local decoration = Decoration.new(decorationId, config)
		purchasableInstances[decorationId] = decoration
	end
end

function PurchasableService.getPurchasable(id)
	return purchasableInstances[id]
end

function PurchasableService.getMachine(machineId)
	local purchasable = purchasableInstances[machineId]
	if purchasable and purchasable.purchasableType == "Machine" then
		return purchasable
	end
	return nil
end

function PurchasableService.getMachineData(player, machineId)
	local ownedMachines = player.Data:FindFirstChild("OwnedMachines")
	if not ownedMachines then
		return nil
	end

	local machineData = ownedMachines:FindFirstChild(tostring(machineId))
	if machineData and machineData:IsA("Folder") then
		return machineData
	end

	for _, legacyMachineData in ownedMachines:GetChildren() do
		if legacyMachineData:IsA("IntValue") and legacyMachineData.Value == machineId then
			return legacyMachineData
		end
	end

	return nil
end

function PurchasableService.playerOwnsMachine(player, machineId)
	return PurchasableService.getMachineData(player, machineId) ~= nil
end

function PurchasableService.getMachineLevel(player, machineId)
	local machine = PurchasableService.getMachine(machineId)
	if not machine then
		return 0
	end

	return machine:getLevel(player)
end

function PurchasableService.getDecoration(decorationId)
	local purchasable = purchasableInstances[decorationId]
	if purchasable and purchasable.purchasableType == "Decoration" then
		return purchasable
	end
	return nil
end

function PurchasableService.unlockMachine(player, machineId)
	local machine = PurchasableService.getMachine(machineId)
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
	local decoration = PurchasableService.getDecoration(decorationId + 1000)
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
	local machine = PurchasableService.getMachine(machineId)
	if not machine then
		return false, "Machine introuvable"
	end

	return machine:upgrade(player)
end

function PurchasableService.calculateTotalIncome(player)
	local totalIncome = 0
	local ownedMachines = player.Data.OwnedMachines

	for _, machineData in ownedMachines:GetChildren() do
		local machineId = tonumber(machineData.Name)
		local level = 1
		if machineData:IsA("Folder") then
			local levelValue = machineData:FindFirstChild("Level")
			level = levelValue and levelValue.Value or 1
		elseif machineData:IsA("IntValue") then
			machineId = machineData.Value
		end

		local machine = PurchasableService.getMachine(machineId)
		if machine then
			totalIncome += machine:generateIncome(level)
		end
	end

	return totalIncome
end

function PurchasableService.resetPlayerMachines(player)
	local ownedMachines = player.Data:FindFirstChild("OwnedMachines")
	if ownedMachines then
		ownedMachines:ClearAllChildren()
	end

	local TycoonService = require(script.Parent.TycoonService)
	local tycoon = TycoonService.getTycoon(player)
	local machines = tycoon and tycoon:FindFirstChild("Machines")
	if machines then
		machines:ClearAllChildren()
	end
end

function PurchasableService.getAllMachines()
	local machines = {}
	for id, purchasable in pairs(purchasableInstances) do
		if purchasable.purchasableType == "Machine" then
			machines[id] = purchasable
		end
	end
	return machines
end

function PurchasableService.getAllDecorations()
	local decorations = {}
	for id, purchasable in pairs(purchasableInstances) do
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

return PurchasableService
