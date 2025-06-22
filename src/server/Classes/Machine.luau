local Purchasable = require(script.Parent.Purchasable)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classe Machine hérite de Purchasable
local Machine = setmetatable({}, { __index = Purchasable })
Machine.__index = Machine

function Machine.new(id, config)
	local self = Purchasable.new(id, config, "Machine")
	setmetatable(self, Machine)

	-- Propriétés spécifiques aux machines
	self.baseIncome = config.BaseIncome or 0
	self.maxLevel = config.MaxLevel or 1
	self.currentLevel = 1
	self.upgradeCost = config.UpgradeCost
	self.upgradeIncome = config.UpgradeIncome

	return self
end

function Machine:spawn(tycoon)
	local machineModel = self:getAssetModel()
	if not machineModel then
		warn("Modèle de machine introuvable pour ID:", self.id)
		return false
	end

	local clonedMachine = machineModel:Clone()

	-- Obtenir la position relative depuis TycoonService
	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local relativeCF = TycoonService.getRelativeCFrame(self.id)
	local worldCF = tycoon.PrimaryPart.CFrame:toWorldSpace(relativeCF)

	clonedMachine:PivotTo(worldCF)
	clonedMachine.Parent = tycoon.Machines

	print("Machine spawnée:", self.name)
	return true
end

function Machine:addToPlayerData(player)
	local machine = Instance.new("IntValue")
	machine.Name = self.name
	machine.Value = self.id
	machine.Parent = player.Data.OwnedMachines
end

function Machine:getAssetModel()
	local machines = ReplicatedStorage:WaitForChild("Machines")
	for _, machineModel in machines:GetChildren() do
		if machineModel:GetAttribute("Id") == self.id then
			return machineModel
		end
	end
	return nil
end

function Machine:generateIncome()
	if not self.isUnlocked then
		return 0
	end

	local baseIncome = self.baseIncome
	if self.upgradeIncome then
		baseIncome = self.upgradeIncome(self.currentLevel)
	end

	return baseIncome
end

function Machine:canUpgrade()
	return self.currentLevel < self.maxLevel
end

function Machine:getUpgradeCost()
	if not self:canUpgrade() then
		return nil
	end

	if self.upgradeCost then
		return self.upgradeCost(self.currentLevel + 1)
	end

	return nil
end

function Machine:upgrade(player)
	if not self:canUpgrade() then
		return false, "Niveau maximum atteint"
	end

	local cost = self:getUpgradeCost()
	if not cost then
		return false, "Coût d'amélioration non défini"
	end

	local MoneyService = require(script.Parent.Parent.Services.MoneyService)
	if not MoneyService.canAfford(player, cost) then
		return false, "Pas assez d'argent pour améliorer"
	end

	MoneyService.removeMoney(player, cost)
	self.currentLevel = self.currentLevel + 1

	return true, "Machine améliorée au niveau " .. self.currentLevel
end

return Machine
