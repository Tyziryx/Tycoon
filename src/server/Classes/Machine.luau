local Purchasable = require(script.Parent.Purchasable)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RandomMachineConfig = require(ReplicatedStorage.Shared.Config.RandomMachineConfig)

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

local function createAnchoredPart(name, size, cframe, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.Metal
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.Parent = parent
	return part
end

local function createPlaceholderLabel(parent, displayName, machineId)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlaceholderLabel"
	billboard.Size = UDim2.fromOffset(220, 58)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = "#" .. machineId .. " " .. displayName
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.TextScaled = true
	label.TextWrapped = true
	label.TextStrokeTransparency = 0.35
	label.Parent = billboard
end

local function getMachineData(player, machineId)
	local MachineInventoryService = require(script.Parent.Parent.Services.MachineInventoryService)
	local inventoryMachineData = MachineInventoryService.findPlacedMachineData(player, machineId)
	if inventoryMachineData then
		return inventoryMachineData
	end

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

local function getDataValue(machineData, name, defaultValue)
	local value = machineData and machineData:FindFirstChild(name)
	if value then
		return value.Value
	end
	return defaultValue
end

local function tintPlaceholderVariant(model, variantId, rarityId)
	if model:GetAttribute("IsPlaceholder") ~= true then
		return
	end

	local variant = RandomMachineConfig.Variants[variantId]
	local rarity = RandomMachineConfig.Rarities[rarityId]
	local tintColor = (variant and variant.Color) or (rarity and rarity.Color)
	if not tintColor then
		return
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 then
			descendant.Color = descendant.Color:Lerp(tintColor, 0.35)
		end
	end
end

function Machine:isOwnedByPlayer(player)
	return getMachineData(player, self.id) ~= nil
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

function Machine:spawn(tycoon, player, machineData)
	local machineModel = self:getAssetModel()
	if not machineModel then
		warn("Modèle de machine introuvable pour ID:", self.id)
		return false
	end

	local clonedMachine = machineModel:Clone()
	local currentLevel = machineData and getDataValue(machineData, "Level", 1) or (player and self:getLevel(player) or 1)
	if currentLevel <= 0 then
		currentLevel = 1
	end

	-- Obtenir la position relative depuis TycoonService
	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local MachineInventoryService = require(script.Parent.Parent.Services.MachineInventoryService)
	local relativeCF = machineData and MachineInventoryService.getPlacementRelativeCFrame(machineData)
		or TycoonService.getRelativeCFrame(self.id)
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
	if machineData then
		local variantId = getDataValue(machineData, "VariantId", "Standard")
		local rarityId = getDataValue(machineData, "Rarity", "Common")
		clonedMachine:SetAttribute("InstanceId", machineData.Name)
		clonedMachine:SetAttribute("VariantId", variantId)
		clonedMachine:SetAttribute("Rarity", rarityId)
		clonedMachine:SetAttribute("FusionLevel", getDataValue(machineData, "FusionLevel", 0))
		tintPlaceholderVariant(clonedMachine, variantId, rarityId)
	end
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

function Machine:purchase(player, _tycoon)
	if self:isOwnedByPlayer(player) then
		return false, "Déjà acheté"
	end

	local canPurchase, reason = self:canPurchase(player)
	if not canPurchase then
		return false, reason
	end

	local machineData = self:addToPlayerData(player)
	if not machineData then
		return false, "Création impossible"
	end

	local MoneyService = require(script.Parent.Parent.Services.MoneyService)
	if not MoneyService.removeMoney(player, self:getPurchaseCost(player)) then
		local MachineInventoryService = require(script.Parent.Parent.Services.MachineInventoryService)
		MachineInventoryService.unplaceMachine(player, machineData.Name, true)
		machineData:Destroy()
		return false, "Pas assez d'argent"
	end

	local MachineInventoryService = require(script.Parent.Parent.Services.MachineInventoryService)
	MachineInventoryService.fireUpdated(player)
	return true, "Acheté avec succès"
end

function Machine:addToPlayerData(player)
	local MachineInventoryService = require(script.Parent.Parent.Services.MachineInventoryService)
	local machineData, reason = MachineInventoryService.createMachineInstance(player, self.id, {
		Rarity = "Common",
		VariantId = "Standard",
		Source = "Purchase",
		Placed = true,
	})

	if not machineData then
		warn("Création de machine impossible:", reason)
	end

	return machineData
end

function Machine:getAssetModel()
	local tycoon = ReplicatedStorage:FindFirstChild("Tycoon")
	if not tycoon then
		tycoon = Instance.new("Folder")
		tycoon.Name = "Tycoon"
		tycoon.Parent = ReplicatedStorage
	end

	local machines = tycoon:FindFirstChild("Machines")
	if not machines then
		machines = Instance.new("Folder")
		machines.Name = "Machines"
		machines.Parent = tycoon
	end

	for _, machineModel in machines:GetChildren() do
		if machineModel:GetAttribute("Id") == self.id then
			return machineModel
		end
	end

	local placeholder = Instance.new("Model")
	placeholder.Name = "PlaceholderMachine_" .. self.id
	placeholder:SetAttribute("Id", self.id)
	placeholder:SetAttribute("IsPlaceholder", true)
	placeholder:SetAttribute("DisplayName", self.config.DisplayName or self.name)

	local color = self.config.PlaceholderColor or Color3.fromRGB(125, 125, 125)
	local base = createAnchoredPart("Body", Vector3.new(4, 3, 4), CFrame.new(0, 1.5, 0), color, placeholder)
	placeholder.PrimaryPart = base

	local top = createAnchoredPart(
		"Stack",
		Vector3.new(1.2, 3, 1.2),
		CFrame.new(0, 4.5, 0),
		color:Lerp(Color3.fromRGB(25, 25, 25), 0.35),
		placeholder
	)
	top.CanTouch = false

	local fireAnchor = createAnchoredPart(
		"FireAnchor",
		Vector3.new(0.5, 0.5, 0.5),
		CFrame.new(0, 3.1, 0),
		Color3.fromRGB(255, 125, 35),
		placeholder
	)
	fireAnchor.Transparency = 1
	fireAnchor.CanCollide = false
	fireAnchor.CanTouch = false
	fireAnchor.CanQuery = false

	local smokeAnchor = createAnchoredPart(
		"SmokeAnchor",
		Vector3.new(0.5, 0.5, 0.5),
		CFrame.new(0, 6.1, 0),
		Color3.fromRGB(25, 25, 25),
		placeholder
	)
	smokeAnchor.Transparency = 1
	smokeAnchor.CanCollide = false
	smokeAnchor.CanTouch = false
	smokeAnchor.CanQuery = false

	createPlaceholderLabel(base, self.config.DisplayName or self.name, self.id)
	placeholder.Parent = machines

	return placeholder
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

function Machine:updateLevelAttributes(player, machineData)
	-- Mettre à jour l'attribut CurrentLevel uniquement sur le tycoon du joueur.
	local VisualEffectsService = require(script.Parent.Parent.Services.VisualEffectsService)
	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local tycoon = TycoonService.getTycoon(player)
	if not tycoon then
		return
	end

	local currentLevel = machineData and getDataValue(machineData, "Level", 1) or self:getLevel(player)
	local instanceId = machineData and machineData.Name
	local machines = tycoon:FindFirstChild("Machines")
	if machines then
		for _, machine in machines:GetChildren() do
			if (instanceId and machine:GetAttribute("InstanceId") == instanceId) or (not instanceId and machine:GetAttribute("Id") == self.id) then
				machine:SetAttribute("CurrentLevel", currentLevel)
				if machineData then
					machine:SetAttribute("FusionLevel", getDataValue(machineData, "FusionLevel", 0))
				end
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
	self:updateLevelAttributes(player, machineData)

	return true, "Machine améliorée au niveau " .. level.Value
end

return Machine
