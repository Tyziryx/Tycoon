local Purchasable = require(script.Parent.Purchasable)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classe Machine hérite de Purchasable
local Machine = setmetatable({}, { __index = Purchasable })
Machine.__index = Machine

function Machine.new(id, config)
	local self = Purchasable.new(id, config, "Machine")
	setmetatable(self, Machine)

	-- Propriétés spécifiques aux machines
	self.baseCost = config.BaseCost or 0
	self.baseIncome = config.BaseIncome or 0
	self.maxLevel = config.MaxLevel or 1
	-- Tiers d'amélioration : { [niveau] = { Cost = ..., Multiplier = ... } }
	self.upgrades = config.Upgrades or {}

	return self
end

local function getMachineData(player, machineId)
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

function Machine:getLevel(player)
	local machineData = getMachineData(player, self.id)
	if not machineData then
		return 0
	end

	if machineData:IsA("Folder") then
		local level = machineData:FindFirstChild("Level")
		return level and level.Value or 1
	end

	return 1
end

function Machine:spawn(tycoon, player)
	local machineModel = self:getAssetModel()
	if not machineModel then
		warn("Modèle de machine introuvable pour ID:", self.id)
		return false
	end

	local clonedMachine = machineModel:Clone()
	local currentLevel = player and self:getLevel(player) or 1
	if currentLevel <= 0 then
		currentLevel = 1
	end

	-- Obtenir la position relative depuis TycoonService
	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local relativeCF = TycoonService.getRelativeCFrame(self.id)
	local worldCF = tycoon.PrimaryPart.CFrame:toWorldSpace(relativeCF)

	clonedMachine:PivotTo(worldCF)
	local machinesFolder = tycoon:FindFirstChild("Machines")
	if not machinesFolder then
		machinesFolder = Instance.new("Folder")
		machinesFolder.Name = "Machines"
		machinesFolder.Parent = tycoon
	end
	clonedMachine.Parent = machinesFolder

	-- Sauvegarder le niveau en attribut pour accès externe
	clonedMachine:SetAttribute("Id", self.id)
	clonedMachine:SetAttribute("CurrentLevel", currentLevel)
	clonedMachine:SetAttribute("IsBuilding", true)

	-- Configurer les effets visuels
	local VisualEffectsService = require(script.Parent.Parent.Services.VisualEffectsService)
	VisualEffectsService.setupMachineEffects(clonedMachine, self.name, currentLevel)
	VisualEffectsService.playBuildAnimation(clonedMachine, self.config.BuildTime or 0)

	-- Configurer le brûleur manuel si c'est un feu de camp
	local ManualBurnerService = require(script.Parent.Parent.Services.ManualBurnerService)
	ManualBurnerService.onMachineSpawned(clonedMachine, tycoon, self.id)

	return true
end

function Machine:addToPlayerData(player)
	local ownedMachines = player.Data:FindFirstChild("OwnedMachines")
	if not ownedMachines then
		ownedMachines = Instance.new("Folder")
		ownedMachines.Name = "OwnedMachines"
		ownedMachines.Parent = player.Data
	end

	local existingMachine = ownedMachines:FindFirstChild(tostring(self.id))
	if existingMachine then
		return existingMachine
	end

	local machine = Instance.new("Folder")
	machine.Name = tostring(self.id)
	machine.Parent = ownedMachines

	local machineId = Instance.new("IntValue")
	machineId.Name = "Id"
	machineId.Value = self.id
	machineId.Parent = machine

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = machine

	return machine
end

function Machine:getAssetModel()
	local tycoon = ReplicatedStorage:WaitForChild("Tycoon")
	local machines = tycoon:WaitForChild("Machines")
	for _, machineModel in machines:GetChildren() do
		if machineModel:GetAttribute("Id") == self.id then
			return machineModel
		end
	end
	return nil
end

function Machine:generateIncome(level)
	if level <= 0 then
		return 0
	end

	-- Pollution générée par seconde = revenu de base × multiplicateur du tier courant.
	-- Le niveau 1 n'a pas de tier dans la config => multiplicateur ×1.
	local multiplier = 1
	local tier = self.upgrades[level]
	if tier and tier.Multiplier then
		multiplier = tier.Multiplier
	end
	return self.baseIncome * multiplier
end

function Machine:canUpgrade(player)
	local currentLevel = self:getLevel(player)
	return currentLevel > 0 and currentLevel < self.maxLevel
end

function Machine:getUpgradeCost(player)
	if not self:canUpgrade(player) then
		return nil
	end
	-- Le coût provient du tier suivant défini dans MachineConfig.
	local currentLevel = self:getLevel(player)
	local nextTier = self.upgrades[currentLevel + 1]
	if nextTier and nextTier.Cost then
		local ShopService = require(script.Parent.Parent.Services.ShopService)
		return ShopService.applyCostReduction(player, nextTier.Cost)
	end
	return nil
end

function Machine:updateLevelAttributes(player)
	-- Mettre à jour l'attribut CurrentLevel uniquement sur le tycoon du joueur.
	local VisualEffectsService = require(script.Parent.Parent.Services.VisualEffectsService)
	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local tycoon = TycoonService.getTycoon(player)
	if not tycoon then
		return
	end

	local currentLevel = self:getLevel(player)
	local machines = tycoon:FindFirstChild("Machines")
	if machines then
		for _, machine in machines:GetChildren() do
			if machine:GetAttribute("Id") == self.id then
				machine:SetAttribute("CurrentLevel", currentLevel)
				VisualEffectsService.updateMachineEffects(machine, currentLevel)
			end
		end
	end
end

function Machine:upgrade(player)
	if not self:canUpgrade(player) then
		return false, "Niveau maximum atteint"
	end

	local cost = self:getUpgradeCost(player)
	if not cost then
		return false, "Coût d'amélioration non défini"
	end

	local machineData = getMachineData(player, self.id)
	if not machineData or not machineData:IsA("Folder") then
		return false, "Machine non possédée"
	end

	local MoneyService = require(script.Parent.Parent.Services.MoneyService)
	if not MoneyService.canAfford(player, cost) then
		return false, "Pas assez d'argent pour améliorer"
	end
	MoneyService.removeMoney(player, cost)

	local level = machineData:FindFirstChild("Level")
	if not level then
		level = Instance.new("IntValue")
		level.Name = "Level"
		level.Value = 1
		level.Parent = machineData
	end
	level.Value = level.Value + 1

	-- Mettre à jour l'attribut sur toutes les instances de cette machine dans le monde
	self:updateLevelAttributes(player)

	return true, "Machine améliorée au niveau " .. level.Value
end

return Machine
