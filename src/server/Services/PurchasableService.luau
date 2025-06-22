local PurchasableService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import des configurations
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local DecorationConfig = require(ReplicatedStorage.Shared.Config.DecorationConfig)

-- Import des classes
local Machine = require(script.Parent.Parent.Classes.Machine)
local Decoration = require(script.Parent.Parent.Classes.Decoration)

-- Stockage des instances d'objets achetables
local purchasableInstances = {}

function PurchasableService.init()
	-- Créer les instances de machines
	for id, config in pairs(MachineConfig) do
		local machine = Machine.new(id, config)
		purchasableInstances[id] = machine
	end

	-- Créer les instances de décorations
	for id, config in pairs(DecorationConfig) do
		-- Utiliser des IDs différents pour éviter les conflits (ajouter 1000)
		local decorationId = id + 1000
		local decoration = Decoration.new(decorationId, config)
		purchasableInstances[decorationId] = decoration
	end

	print("PurchasableService initialisé avec", #purchasableInstances, "objets achetables")
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
	local decoration = PurchasableService.getDecoration(decorationId + 1000) -- Ajuster l'ID
	if not decoration then
		warn("Décoration introuvable:", decorationId)
		return false, "Décoration introuvable"
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
		local machineId = machineData.Value
		local machine = PurchasableService.getMachine(machineId)
		if machine then
			totalIncome = totalIncome + machine:generateIncome()
		end
	end

	return totalIncome
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

-- Fonction de compatibilité avec l'ancien MachineService
function PurchasableService.getMachineModel(machineId)
	local machine = PurchasableService.getMachine(machineId)
	if machine then
		return machine:getAssetModel()
	end
	return nil
end

return PurchasableService
