local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Purchasable = require(script.Parent.Purchasable)

local Machine = setmetatable({}, { __index = Purchasable })
Machine.__index = Machine

function Machine.new(id, config)
	local self = Purchasable.new(id, config, "Machine")
	setmetatable(self, Machine)

	self.baseCost = config.BaseCost or 0
	self.baseIncome = config.BaseIncome or 0
	self.maxLevel = config.MaxLevel or 1
	self.currentLevel = 1
	self.upgrades = config.Upgrades or {}

	return self
end

function Machine:spawn(tycoon)
	local machineModel = self:getAssetModel()
	if not machineModel then
		warn("Modele de machine introuvable pour ID:", self.id)
		return false
	end

	local clonedMachine = machineModel:Clone()

	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local relativeCF = TycoonService.getRelativeCFrame(self.id)
	local worldCF = tycoon.PrimaryPart.CFrame:toWorldSpace(relativeCF)

	clonedMachine:PivotTo(worldCF)
	clonedMachine.Parent = tycoon.Machines

	clonedMachine:SetAttribute("CurrentLevel", self.currentLevel)
	clonedMachine:SetAttribute("IsBuilding", true)

	local VisualEffectsService = require(script.Parent.Parent.Services.VisualEffectsService)
	VisualEffectsService.setupMachineEffects(clonedMachine, self.name, self.currentLevel)
	VisualEffectsService.playBuildAnimation(clonedMachine, self.config.BuildTime or 0)

	local ManualBurnerService = require(script.Parent.Parent.Services.ManualBurnerService)
	ManualBurnerService.onMachineSpawned(clonedMachine, tycoon, self.id)

	return true
end

function Machine:addToPlayerData(player)
	local machine = Instance.new("IntValue")
	machine.Name = self.name
	machine.Value = self.id
	machine.Parent = player.Data.OwnedMachines
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

function Machine:generateIncome()
	if not self.isUnlocked then
		return 0
	end

	local multiplier = 1
	local tier = self.upgrades[self.currentLevel]
	if tier and tier.Multiplier then
		multiplier = tier.Multiplier
	end

	return self.baseIncome * multiplier
end

function Machine:canUpgrade()
	return self.currentLevel < self.maxLevel
end

function Machine:getUpgradeCost()
	if not self:canUpgrade() then
		return nil
	end

	local nextTier = self.upgrades[self.currentLevel + 1]
	if nextTier and nextTier.Cost then
		return nextTier.Cost
	end

	return nil
end

function Machine:updateLevelAttributes(player)
	local VisualEffectsService = require(script.Parent.Parent.Services.VisualEffectsService)
	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local tycoon = TycoonService.getTycoon(player)
	if not tycoon then
		return
	end

	local machines = tycoon:FindFirstChild("Machines")
	if not machines then
		return
	end

	for _, machine in machines:GetChildren() do
		if machine:GetAttribute("Id") == self.id then
			machine:SetAttribute("CurrentLevel", self.currentLevel)
			VisualEffectsService.updateMachineEffects(machine, self.currentLevel)
		end
	end
end

function Machine:upgrade(player)
	if not self:canUpgrade() then
		return false, "Niveau maximum atteint"
	end

	local cost = self:getUpgradeCost()
	if not cost then
		return false, "Cout d'amelioration non defini"
	end

	local MoneyService = require(script.Parent.Parent.Services.MoneyService)
	if not MoneyService.canAfford(player, cost) then
		return false, "Pas assez d'argent pour ameliorer"
	end

	MoneyService.removeMoney(player, cost)
	self.currentLevel += 1
	self:updateLevelAttributes(player)

	return true, "Machine amelioree au niveau " .. self.currentLevel
end

return Machine
