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
	self.currentLevel = 1
	self.upgradeCost = config.BaseCost * (self.currentLevel - 1) * 5
	self.upgradeIncome = 0

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

	-- Sauvegarder le niveau en attribut pour accès externe
	clonedMachine:SetAttribute("CurrentLevel", self.currentLevel)

	-- Configurer les effets visuels
	local VisualEffectsService = require(script.Parent.Parent.Services.VisualEffectsService)
	VisualEffectsService.setupMachineEffects(clonedMachine, self.name, self.currentLevel)

	-- Configurer le brûleur manuel si c'est un feu de camp
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
	if self.currentLevel == 2 then
		baseIncome *= 1.5
	elseif self.currentLevel == 3 then
		baseIncome *= 2
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
	local cost = self.baseCost * self.currentLevel * 5
	if self.id == 1 and self.currentLevel == 1 then
		cost = 100
	elseif self.id == 1 and self.currentLevel == 2 then
		cost = 200
	end
	return cost
end

function Machine:updateLevelAttributes()
	-- Mettre à jour l'attribut CurrentLevel sur toutes les instances de cette machine
	local VisualEffectsService = require(script.Parent.Parent.Services.VisualEffectsService)

	for _, tycoon in game.Workspace.Tycoons:GetChildren() do
		local machines = tycoon:FindFirstChild("Machines")
		if machines then
			for _, machine in machines:GetChildren() do
				if machine:GetAttribute("Id") == self.id then
					machine:SetAttribute("CurrentLevel", self.currentLevel)
					-- Mettre à jour les effets visuels
					VisualEffectsService.updateMachineEffects(machine, self.currentLevel)
				end
			end
		end
	end
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

	-- Mettre à jour l'attribut sur toutes les instances de cette machine dans le monde
	self:updateLevelAttributes()

	return true, "Machine améliorée au niveau " .. self.currentLevel
end

return Machine
