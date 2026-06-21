local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local RandomMachineConfig = require(ReplicatedStorage.Shared.Config.RandomMachineConfig)

local MoneyService = require(script.Parent.MoneyService)
local ZoneService = require(script.Parent.ZoneService)

local MachineInventoryService = {}

local rng = Random.new()

local remotes = {}

local function ensureRemoteFunction(name)
	local remoteFunction = ReplicatedStorage:FindFirstChild(name)
	if not remoteFunction then
		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = name
		remoteFunction.Parent = ReplicatedStorage
	end
	return remoteFunction
end

local function ensureRemoteEvent(name)
	local remoteEvent = ReplicatedStorage:FindFirstChild(name)
	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = name
		remoteEvent.Parent = ReplicatedStorage
	end
	return remoteEvent
end

local function ensureRemotes()
	remotes.GetState = remotes.GetState or ensureRemoteFunction("GetMachineInventoryRemote")
	remotes.Roll = remotes.Roll or ensureRemoteFunction("RollMachineRemote")
	remotes.Place = remotes.Place or ensureRemoteFunction("PlaceMachineRemote")
	remotes.Unplace = remotes.Unplace or ensureRemoteFunction("UnplaceMachineRemote")
	remotes.Sell = remotes.Sell or ensureRemoteFunction("SellMachineRemote")
	remotes.Recycle = remotes.Recycle or ensureRemoteFunction("RecycleMachineRemote")
	remotes.Fuse = remotes.Fuse or ensureRemoteFunction("FuseMachineRemote")
	remotes.ToggleLock = remotes.ToggleLock or ensureRemoteFunction("ToggleMachineLockRemote")
	remotes.Updated = remotes.Updated or ensureRemoteEvent("MachineInventoryUpdated")
end

local function createValue(parent, className, name, value)
	local valueObject = parent:FindFirstChild(name)
	if not valueObject or valueObject.ClassName ~= className then
		if valueObject then
			valueObject:Destroy()
		end

		valueObject = Instance.new(className)
		valueObject.Name = name
		valueObject.Parent = parent
	end

	valueObject.Value = value
	return valueObject
end

local function getValue(parent, name, defaultValue)
	local valueObject = parent and parent:FindFirstChild(name)
	if valueObject then
		return valueObject.Value
	end
	return defaultValue
end

local function setChildValue(parent, name, value)
	local valueType = typeof(value)
	if valueType == "number" then
		return createValue(parent, "NumberValue", name, value)
	elseif valueType == "boolean" then
		return createValue(parent, "BoolValue", name, value)
	end

	return createValue(parent, "StringValue", name, tostring(value))
end

local function getInventoryFolder(player)
	return player.Data and player.Data:FindFirstChild("MachineInventory")
end

local function ensureInventoryFolder(player)
	local inventory = getInventoryFolder(player)
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "MachineInventory"
		inventory.Parent = player.Data
	end
	return inventory
end

local function ensureCollectionFolder(player)
	local collection = player.Data:FindFirstChild("MachineCollection")
	if not collection then
		collection = Instance.new("Folder")
		collection.Name = "MachineCollection"
		collection.Parent = player.Data
	end
	return collection
end

local function ensureRandomStats(player)
	local stats = player.Data:FindFirstChild("RandomStats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "RandomStats"
		stats.Parent = player.Data
	end

	if not stats:FindFirstChild("RollCount") then
		createValue(stats, "NumberValue", "RollCount", 0)
	end
	if not stats:FindFirstChild("PityCounter") then
		createValue(stats, "NumberValue", "PityCounter", 0)
	end

	return stats
end

local function ensureScrapValue(player)
	local scrap = player.Data:FindFirstChild(RandomMachineConfig.Recycle.ResourceName)
	if not scrap then
		scrap = Instance.new("NumberValue")
		scrap.Name = RandomMachineConfig.Recycle.ResourceName
		scrap.Value = 0
		scrap.Parent = player.Data
	end
	return scrap
end

local function updateScrapLeaderstat(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local scrapLeaderstat = leaderstats and leaderstats:FindFirstChild(RandomMachineConfig.Recycle.DisplayName)
	if scrapLeaderstat then
		scrapLeaderstat.Value = ensureScrapValue(player).Value
	end
end

local function addScrap(player, amount)
	local scrap = ensureScrapValue(player)
	scrap.Value += amount
	updateScrapLeaderstat(player)
end

local function getRarityIndex(rarityId)
	for index, currentRarityId in ipairs(RandomMachineConfig.RarityOrder) do
		if currentRarityId == rarityId then
			return index
		end
	end
	return 1
end

local function getTraitIds(machineData)
	local traitsFolder = machineData:FindFirstChild("Traits")
	local traitIds = {}
	if not traitsFolder then
		return traitIds
	end

	for _, traitValue in traitsFolder:GetChildren() do
		if traitValue:IsA("BoolValue") and traitValue.Value == true then
			table.insert(traitIds, traitValue.Name)
		end
	end

	table.sort(traitIds)
	return traitIds
end

local function weightedChoice(entries, getWeight)
	local totalWeight = 0
	for _, entry in ipairs(entries) do
		totalWeight += getWeight(entry)
	end

	if totalWeight <= 0 then
		return entries[1]
	end

	local pick = rng:NextInteger(1, totalWeight)
	local cursor = 0
	for _, entry in ipairs(entries) do
		cursor += getWeight(entry)
		if pick <= cursor then
			return entry
		end
	end

	return entries[#entries]
end

local function rollRarity(player)
	local stats = ensureRandomStats(player)
	local pityCounter = getValue(stats, "PityCounter", 0)
	local rarityId = weightedChoice(RandomMachineConfig.RarityOrder, function(currentRarityId)
		return RandomMachineConfig.Rarities[currentRarityId].Weight
	end)

	local minimumIndex = getRarityIndex(RandomMachineConfig.Roll.PityMinimumRarity)
	if pityCounter >= RandomMachineConfig.Roll.PityThreshold and getRarityIndex(rarityId) < minimumIndex then
		rarityId = RandomMachineConfig.Roll.PityMinimumRarity
	end

	if getRarityIndex(rarityId) >= minimumIndex then
		setChildValue(stats, "PityCounter", 0)
	else
		setChildValue(stats, "PityCounter", pityCounter + 1)
	end

	setChildValue(stats, "RollCount", getValue(stats, "RollCount", 0) + 1)
	return rarityId
end

local function rollVariant(rarityId)
	local rarityIndex = getRarityIndex(rarityId)
	local eligibleVariants = {}

	for _, variantId in ipairs(RandomMachineConfig.VariantOrder) do
		local variant = RandomMachineConfig.Variants[variantId]
		if getRarityIndex(variant.MinimumRarity) <= rarityIndex then
			table.insert(eligibleVariants, variantId)
		end
	end

	return weightedChoice(eligibleVariants, function(variantId)
		return RandomMachineConfig.Variants[variantId].Weight
	end)
end

local function rollTraits()
	local traitIds = {}
	local picked = {}

	while #traitIds < RandomMachineConfig.Roll.MaxTraits do
		if rng:NextNumber() > RandomMachineConfig.Roll.TraitChance then
			break
		end

		local eligibleTraits = {}
		for _, traitId in ipairs(RandomMachineConfig.TraitOrder) do
			if not picked[traitId] then
				table.insert(eligibleTraits, traitId)
			end
		end

		if #eligibleTraits == 0 then
			break
		end

		local traitId = weightedChoice(eligibleTraits, function(currentTraitId)
			return RandomMachineConfig.Traits[currentTraitId].Weight
		end)
		picked[traitId] = true
		table.insert(traitIds, traitId)
	end

	return traitIds
end

local function getMachinePool(player)
	local currentZone = ZoneService.getCurrentZone(player)
	local pool = {}

	for machineId, machineConfig in pairs(MachineConfig) do
		if (machineConfig.ZoneRequired or 1) <= currentZone then
			table.insert(pool, machineId)
		end
	end

	table.sort(pool)
	return pool
end

local function generateInstanceId(inventory)
	for _ = 1, 20 do
		local guid = HttpService:GenerateGUID(false):gsub("-", "")
		local instanceId = "m_" .. string.sub(guid, 1, 12)
		if not inventory:FindFirstChild(instanceId) then
			return instanceId
		end
	end

	return "m_" .. tostring(os.time()) .. "_" .. tostring(rng:NextInteger(1000, 9999))
end

local function getFootprint(machineId, traitIds)
	local machineConfig = MachineConfig[machineId]
	local footprintX = machineConfig and machineConfig.FootprintX or 1
	local footprintZ = machineConfig and machineConfig.FootprintZ or 1

	for _, traitId in ipairs(traitIds or {}) do
		local trait = RandomMachineConfig.Traits[traitId]
		if trait and trait.FootprintBonus then
			footprintX = math.max(1, footprintX + trait.FootprintBonus)
			footprintZ = math.max(1, footprintZ + trait.FootprintBonus)
		end
	end

	return footprintX, footprintZ
end

local function getPlacementLimits(player)
	local placement = RandomMachineConfig.Placement
	return placement.MaxColumns, math.max(placement.RowsPerPalier, ZoneService.getCurrentZone(player) * placement.RowsPerPalier)
end

local function normalizeRotation(rotation)
	local normalized = math.floor((tonumber(rotation) or 0) / 90) * 90
	normalized = normalized % 360
	return normalized
end

local function normalizeGridValue(value)
	return math.max(0, math.floor(tonumber(value) or 0))
end

local function isInsideGrid(player, machineId, traitIds, plotX, plotZ)
	local maxColumns, maxRows = getPlacementLimits(player)
	local footprintX, footprintZ = getFootprint(machineId, traitIds)
	return plotX >= 0 and plotZ >= 0 and plotX + footprintX <= maxColumns and plotZ + footprintZ <= maxRows
end

local function regionsOverlap(aX, aZ, aWidth, aDepth, bX, bZ, bWidth, bDepth)
	return aX < bX + bWidth and bX < aX + aWidth and aZ < bZ + bDepth and bZ < aZ + aDepth
end

local function isOccupied(player, instanceId, machineId, traitIds, plotX, plotZ)
	local inventory = getInventoryFolder(player)
	if not inventory then
		return false
	end

	local footprintX, footprintZ = getFootprint(machineId, traitIds)
	for _, otherData in inventory:GetChildren() do
		if otherData:IsA("Folder") and otherData.Name ~= instanceId and getValue(otherData, "Placed", false) == true then
			local otherMachineId = getValue(otherData, "MachineId", 0)
			local otherTraits = getTraitIds(otherData)
			local otherFootprintX, otherFootprintZ = getFootprint(otherMachineId, otherTraits)
			if regionsOverlap(
				plotX,
				plotZ,
				footprintX,
				footprintZ,
				getValue(otherData, "PlotX", 0),
				getValue(otherData, "PlotZ", 0),
				otherFootprintX,
				otherFootprintZ
			) then
				return true
			end
		end
	end

	return false
end

local function getFirstFreePlacement(player, instanceId, machineId, traitIds)
	local maxColumns, maxRows = getPlacementLimits(player)
	local footprintX, footprintZ = getFootprint(machineId, traitIds)

	for plotZ = 0, maxRows - footprintZ do
		for plotX = 0, maxColumns - footprintX do
			if not isOccupied(player, instanceId, machineId, traitIds, plotX, plotZ) then
				return plotX, plotZ, RandomMachineConfig.Placement.DefaultRotation
			end
		end
	end

	return nil, nil, nil
end

local function setTraits(machineData, traitIds)
	local traits = machineData:FindFirstChild("Traits")
	if not traits then
		traits = Instance.new("Folder")
		traits.Name = "Traits"
		traits.Parent = machineData
	else
		traits:ClearAllChildren()
	end

	for _, traitId in ipairs(traitIds or {}) do
		createValue(traits, "BoolValue", traitId, true)
	end
end

local function markDiscovered(player, machineId, variantId, rarityId)
	local collection = ensureCollectionFolder(player)
	local key = tostring(machineId) .. "_" .. variantId
	local discovered = collection:FindFirstChild(key)
	if not discovered then
		discovered = Instance.new("BoolValue")
		discovered.Name = key
		discovered.Parent = collection
	end
	discovered.Value = true
	discovered:SetAttribute("MachineId", machineId)
	discovered:SetAttribute("VariantId", variantId)
	discovered:SetAttribute("Rarity", rarityId)
end

local function fireUpdateButtons()
	local updateButtonsEvent = ReplicatedStorage:FindFirstChild("UpdateButtons")
	if updateButtonsEvent and updateButtonsEvent:IsA("BindableEvent") then
		updateButtonsEvent:Fire()
	end
end

local function removeSpawnedMachine(player, instanceId)
	local TycoonService = require(script.Parent.TycoonService)
	local tycoon = TycoonService.getTycoon(player)
	local machines = tycoon and tycoon:FindFirstChild("Machines")
	if not machines then
		return
	end

	for _, model in machines:GetChildren() do
		if model:GetAttribute("InstanceId") == instanceId then
			model:Destroy()
		end
	end
end

local function spawnMachine(player, machineData)
	local machineId = getValue(machineData, "MachineId", 0)
	local PurchasableService = require(script.Parent.PurchasableService)
	local TycoonService = require(script.Parent.TycoonService)
	local machine = PurchasableService.getMachine(machineId)
	local tycoon = TycoonService.getTycoon(player)
	if not machine or not tycoon then
		return false
	end

	removeSpawnedMachine(player, machineData.Name)
	return machine:spawn(tycoon, player, machineData)
end

local function getTraitMultiplier(machineData, multiplierName)
	local multiplier = 1
	for _, traitId in ipairs(getTraitIds(machineData)) do
		local trait = RandomMachineConfig.Traits[traitId]
		if trait and trait[multiplierName] then
			multiplier *= trait[multiplierName]
		end
	end
	return multiplier
end

local function getLevelMultiplier(level)
	return 1 + ((math.max(1, level) - 1) * 0.25)
end

local function getFusionValueMultiplier(machineData)
	local fusionLevel = getValue(machineData, "FusionLevel", 0)
	return 1 + (fusionLevel * RandomMachineConfig.Fusion.ValueMultiplierPerLevel)
end

function MachineInventoryService.setupPlayer(player)
	ensureInventoryFolder(player)
	ensureCollectionFolder(player)
	ensureRandomStats(player)
	ensureScrapValue(player)
end

function MachineInventoryService.setupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local scrap = leaderstats:FindFirstChild(RandomMachineConfig.Recycle.DisplayName)
	if not scrap then
		scrap = Instance.new("IntValue")
		scrap.Name = RandomMachineConfig.Recycle.DisplayName
		scrap.Parent = leaderstats
	end
	scrap.Value = ensureScrapValue(player).Value
	return scrap
end

function MachineInventoryService.getMachineDataByInstanceId(player, instanceId)
	local inventory = getInventoryFolder(player)
	local machineData = inventory and inventory:FindFirstChild(tostring(instanceId))
	if machineData and machineData:IsA("Folder") then
		return machineData
	end
	return nil
end

function MachineInventoryService.findPlacedMachineData(player, machineId)
	local inventory = getInventoryFolder(player)
	if not inventory then
		return nil
	end

	for _, machineData in inventory:GetChildren() do
		if
			machineData:IsA("Folder")
			and getValue(machineData, "Placed", false) == true
			and getValue(machineData, "MachineId", 0) == machineId
		then
			return machineData
		end
	end

	return nil
end

function MachineInventoryService.createMachineInstance(player, machineId, options)
	options = options or {}

	local inventory = ensureInventoryFolder(player)
	local machineConfig = MachineConfig[machineId]
	if not machineConfig then
		return nil, "Machine inconnue"
	end

	local rarityId = options.Rarity or "Common"
	local variantId = options.VariantId or "Standard"
	local traitIds = options.Traits or {}
	local instanceId = options.InstanceId or generateInstanceId(inventory)

	local machineData = Instance.new("Folder")
	machineData.Name = instanceId
	machineData.Parent = inventory

	setChildValue(machineData, "InstanceId", instanceId)
	setChildValue(machineData, "MachineId", machineId)
	setChildValue(machineData, "VariantId", variantId)
	setChildValue(machineData, "Rarity", rarityId)
	setChildValue(machineData, "Level", options.Level or 1)
	setChildValue(machineData, "FusionLevel", options.FusionLevel or 0)
	setChildValue(machineData, "Locked", options.Locked == true)
	setChildValue(machineData, "Placed", false)
	setChildValue(machineData, "PlotX", -1)
	setChildValue(machineData, "PlotZ", -1)
	setChildValue(machineData, "Rotation", RandomMachineConfig.Placement.DefaultRotation)
	setChildValue(machineData, "Source", options.Source or "Roll")
	setTraits(machineData, traitIds)

	if options.Placed == true then
		local plotX = options.PlotX
		local plotZ = options.PlotZ
		local rotation = options.Rotation
		if plotX == nil or plotZ == nil then
			plotX, plotZ, rotation = getFirstFreePlacement(player, instanceId, machineId, traitIds)
		end

		if plotX == nil or plotZ == nil then
			machineData:Destroy()
			return nil, "Aucune case libre"
		end

		local success, reason = MachineInventoryService.placeMachine(player, instanceId, plotX, plotZ, rotation, true)
		if not success then
			machineData:Destroy()
			return nil, reason
		end
	end

	markDiscovered(player, machineId, variantId, rarityId)
	return machineData
end

function MachineInventoryService.rollMachine(player)
	local cost = RandomMachineConfig.Roll.BaseCost
	if not MoneyService.canAfford(player, cost) then
		return {
			Success = false,
			Message = "Pas assez d'argent pour un conteneur",
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	local pool = getMachinePool(player)
	if #pool == 0 then
		return {
			Success = false,
			Message = "Aucune machine disponible",
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	local machineId = pool[rng:NextInteger(1, #pool)]
	local rarityId = rollRarity(player)
	local variantId = rollVariant(rarityId)
	local traitIds = rollTraits()

	local machineData, reason = MachineInventoryService.createMachineInstance(player, machineId, {
		Rarity = rarityId,
		VariantId = variantId,
		Traits = traitIds,
		Source = "Roll",
		Placed = false,
	})
	if not machineData then
		return {
			Success = false,
			Message = reason or "Roll impossible",
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	MoneyService.removeMoney(player, cost)
	MachineInventoryService.fireUpdated(player)

	local machineConfig = MachineConfig[machineId]
	local variant = RandomMachineConfig.Variants[variantId]
	local rarity = RandomMachineConfig.Rarities[rarityId]
	return {
		Success = true,
		Message = (rarity.Name or rarityId) .. " - " .. (variant.Name or variantId) .. " " .. machineConfig.DisplayName,
		State = MachineInventoryService.getInventoryState(player),
		InstanceId = machineData.Name,
	}
end

function MachineInventoryService.getPlacementRelativeCFrame(machineData)
	local placement = RandomMachineConfig.Placement
	local machineId = getValue(machineData, "MachineId", 0)
	local traitIds = getTraitIds(machineData)
	local footprintX, footprintZ = getFootprint(machineId, traitIds)
	local plotX = getValue(machineData, "PlotX", 0)
	local plotZ = getValue(machineData, "PlotZ", 0)
	local rotation = math.rad(getValue(machineData, "Rotation", 0))
	local x = placement.OriginX + ((plotX + ((footprintX - 1) * 0.5)) * placement.CellSize)
	local z = placement.OriginZ - ((plotZ + ((footprintZ - 1) * 0.5)) * placement.CellSize)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, rotation, 0)
end

function MachineInventoryService.placeMachine(player, instanceId, plotX, plotZ, rotation, skipUpdate)
	local machineData = MachineInventoryService.getMachineDataByInstanceId(player, instanceId)
	if not machineData then
		return false, "Machine inconnue"
	end

	local machineId = getValue(machineData, "MachineId", 0)
	local machineConfig = MachineConfig[machineId]
	if not machineConfig then
		return false, "Configuration introuvable"
	end

	local currentZone = ZoneService.getCurrentZone(player)
	if currentZone < (machineConfig.ZoneRequired or 1) then
		return false, "Palier requis non atteint"
	end

	local traitIds = getTraitIds(machineData)
	plotX = normalizeGridValue(plotX)
	plotZ = normalizeGridValue(plotZ)
	rotation = normalizeRotation(rotation)

	if not isInsideGrid(player, machineId, traitIds, plotX, plotZ) then
		return false, "Placement hors grille"
	end

	if isOccupied(player, machineData.Name, machineId, traitIds, plotX, plotZ) then
		return false, "Case occupee"
	end

	setChildValue(machineData, "Placed", true)
	setChildValue(machineData, "PlotX", plotX)
	setChildValue(machineData, "PlotZ", plotZ)
	setChildValue(machineData, "Rotation", rotation)

	local spawned = spawnMachine(player, machineData)
	if not spawned then
		setChildValue(machineData, "Placed", false)
		return false, "Spawn impossible"
	end

	if not skipUpdate then
		MachineInventoryService.fireUpdated(player)
		fireUpdateButtons()
	end
	return true, "Machine placee"
end

function MachineInventoryService.unplaceMachine(player, instanceId, skipUpdate)
	local machineData = MachineInventoryService.getMachineDataByInstanceId(player, instanceId)
	if not machineData then
		return false, "Machine inconnue"
	end

	removeSpawnedMachine(player, machineData.Name)
	setChildValue(machineData, "Placed", false)
	setChildValue(machineData, "PlotX", -1)
	setChildValue(machineData, "PlotZ", -1)

	if not skipUpdate then
		MachineInventoryService.fireUpdated(player)
		fireUpdateButtons()
	end
	return true, "Machine rangee"
end

function MachineInventoryService.resetPlacedMachines(player)
	local inventory = getInventoryFolder(player)
	if inventory then
		for _, machineData in inventory:GetChildren() do
			if machineData:IsA("Folder") then
				setChildValue(machineData, "Placed", false)
				setChildValue(machineData, "PlotX", -1)
				setChildValue(machineData, "PlotZ", -1)
			end
		end
	end
	MachineInventoryService.fireUpdated(player)
end

function MachineInventoryService.getInstanceIncome(player, machineData)
	if getValue(machineData, "Placed", false) ~= true then
		return 0
	end

	local machineId = getValue(machineData, "MachineId", 0)
	local machineConfig = MachineConfig[machineId]
	if not machineConfig or ZoneService.getCurrentZone(player) < (machineConfig.ZoneRequired or 1) then
		return 0
	end

	local level = getValue(machineData, "Level", 1)
	local tierMultiplier = 1
	local tier = machineConfig.Upgrades and machineConfig.Upgrades[level]
	if tier and tier.Multiplier then
		tierMultiplier = tier.Multiplier
	end

	local variant = RandomMachineConfig.Variants[getValue(machineData, "VariantId", "Standard")]
	local variantMultiplier = variant and variant.IncomeMultiplier or 1
	local fusionMultiplier = 1 + (getValue(machineData, "FusionLevel", 0) * RandomMachineConfig.Fusion.IncomeMultiplierPerLevel)
	local traitMultiplier = getTraitMultiplier(machineData, "IncomeMultiplier")
	return machineConfig.BaseIncome * tierMultiplier * variantMultiplier * fusionMultiplier * traitMultiplier
end

function MachineInventoryService.calculatePlacedIncome(player)
	local inventory = getInventoryFolder(player)
	if not inventory then
		return 0
	end

	local totalIncome = 0
	for _, machineData in inventory:GetChildren() do
		if machineData:IsA("Folder") then
			totalIncome += MachineInventoryService.getInstanceIncome(player, machineData)
		end
	end
	return totalIncome
end

function MachineInventoryService.getSellValue(machineData)
	local machineId = getValue(machineData, "MachineId", 0)
	local machineConfig = MachineConfig[machineId]
	local baseCost = machineConfig and math.max(machineConfig.BaseCost, RandomMachineConfig.Sell.MinimumBaseValue) or 0
	local rarity = RandomMachineConfig.Rarities[getValue(machineData, "Rarity", "Common")]
	local variant = RandomMachineConfig.Variants[getValue(machineData, "VariantId", "Standard")]
	local rarityMultiplier = rarity and rarity.SellMultiplier or 1
	local variantMultiplier = variant and variant.SellMultiplier or 1
	local levelMultiplier = getLevelMultiplier(getValue(machineData, "Level", 1))
	local traitMultiplier = getTraitMultiplier(machineData, "SellMultiplier")
	return math.floor(
		baseCost
			* RandomMachineConfig.Sell.RefundRate
			* rarityMultiplier
			* variantMultiplier
			* levelMultiplier
			* traitMultiplier
			* getFusionValueMultiplier(machineData)
	)
end

function MachineInventoryService.getRecycleYield(machineData)
	local rarity = RandomMachineConfig.Rarities[getValue(machineData, "Rarity", "Common")]
	local variant = RandomMachineConfig.Variants[getValue(machineData, "VariantId", "Standard")]
	local rarityMultiplier = rarity and rarity.RecycleMultiplier or 1
	local variantMultiplier = variant and variant.RecycleMultiplier or 1
	local levelMultiplier = getLevelMultiplier(getValue(machineData, "Level", 1))
	local traitMultiplier = getTraitMultiplier(machineData, "RecycleMultiplier")
	return math.max(
		1,
		math.floor(
			RandomMachineConfig.Recycle.BaseYield
				* rarityMultiplier
				* variantMultiplier
				* levelMultiplier
				* traitMultiplier
				* getFusionValueMultiplier(machineData)
		)
	)
end

function MachineInventoryService.sellMachine(player, instanceId)
	local machineData = MachineInventoryService.getMachineDataByInstanceId(player, instanceId)
	if not machineData then
		return false, "Machine inconnue"
	end
	if getValue(machineData, "Locked", false) == true then
		return false, "Machine verrouillee"
	end

	local sellValue = MachineInventoryService.getSellValue(machineData)
	if getValue(machineData, "Placed", false) == true then
		MachineInventoryService.unplaceMachine(player, instanceId, true)
	end

	machineData:Destroy()
	MoneyService.addMoney(player, sellValue)
	MachineInventoryService.fireUpdated(player)
	fireUpdateButtons()
	return true, "Machine vendue +" .. tostring(sellValue) .. "$"
end

function MachineInventoryService.recycleMachine(player, instanceId)
	local machineData = MachineInventoryService.getMachineDataByInstanceId(player, instanceId)
	if not machineData then
		return false, "Machine inconnue"
	end
	if getValue(machineData, "Locked", false) == true then
		return false, "Machine verrouillee"
	end

	local recycleYield = MachineInventoryService.getRecycleYield(machineData)
	if getValue(machineData, "Placed", false) == true then
		MachineInventoryService.unplaceMachine(player, instanceId, true)
	end

	machineData:Destroy()
	addScrap(player, recycleYield)
	MachineInventoryService.fireUpdated(player)
	fireUpdateButtons()
	return true, "Machine recyclee +" .. tostring(recycleYield) .. " " .. RandomMachineConfig.Recycle.DisplayName
end

function MachineInventoryService.fuseMachine(player, instanceId)
	local primary = MachineInventoryService.getMachineDataByInstanceId(player, instanceId)
	if not primary then
		return false, "Machine inconnue"
	end

	local machineId = getValue(primary, "MachineId", 0)
	local rarityId = getValue(primary, "Rarity", "Common")
	local inventory = getInventoryFolder(player)
	local candidates = {}

	for _, machineData in inventory:GetChildren() do
		if
			machineData:IsA("Folder")
			and machineData ~= primary
			and getValue(machineData, "Locked", false) == false
			and getValue(machineData, "MachineId", 0) == machineId
			and getValue(machineData, "Rarity", "Common") == rarityId
		then
			table.insert(candidates, machineData)
		end
	end

	local needed = RandomMachineConfig.Fusion.RequiredDuplicates - 1
	if #candidates < needed then
		return false, "Pas assez de doublons"
	end

	table.sort(candidates, function(a, b)
		if getValue(a, "Placed", false) ~= getValue(b, "Placed", false) then
			return getValue(a, "Placed", false) == false
		end
		return a.Name < b.Name
	end)

	for index = 1, needed do
		local consumed = candidates[index]
		if getValue(consumed, "Placed", false) == true then
			MachineInventoryService.unplaceMachine(player, consumed.Name, true)
		end
		consumed:Destroy()
	end

	setChildValue(primary, "FusionLevel", getValue(primary, "FusionLevel", 0) + 1)
	if getValue(primary, "Placed", false) == true then
		spawnMachine(player, primary)
	end

	MachineInventoryService.fireUpdated(player)
	fireUpdateButtons()
	return true, "Fusion reussie"
end

function MachineInventoryService.toggleLock(player, instanceId)
	local machineData = MachineInventoryService.getMachineDataByInstanceId(player, instanceId)
	if not machineData then
		return false, "Machine inconnue"
	end

	local locked = not getValue(machineData, "Locked", false)
	setChildValue(machineData, "Locked", locked)
	MachineInventoryService.fireUpdated(player)
	return true, locked and "Machine verrouillee" or "Machine deverrouillee"
end

function MachineInventoryService.getInventoryState(player)
	local inventory = ensureInventoryFolder(player)
	local maxColumns, maxRows = getPlacementLimits(player)
	local instances = {}

	for _, machineData in inventory:GetChildren() do
		if machineData:IsA("Folder") then
			local machineId = getValue(machineData, "MachineId", 0)
			local machineConfig = MachineConfig[machineId]
			local variantId = getValue(machineData, "VariantId", "Standard")
			local rarityId = getValue(machineData, "Rarity", "Common")
			local variant = RandomMachineConfig.Variants[variantId]
			local rarity = RandomMachineConfig.Rarities[rarityId]
			local traitIds = getTraitIds(machineData)
			local footprintX, footprintZ = getFootprint(machineId, traitIds)
			local traits = {}

			for _, traitId in ipairs(traitIds) do
				local trait = RandomMachineConfig.Traits[traitId]
				table.insert(traits, {
					Id = traitId,
					Name = trait and trait.Name or traitId,
				})
			end

			table.insert(instances, {
				InstanceId = machineData.Name,
				MachineId = machineId,
				MachineName = machineConfig and (machineConfig.DisplayName or machineConfig.Name) or "Machine inconnue",
				VariantId = variantId,
				VariantName = variant and variant.Name or variantId,
				Rarity = rarityId,
				RarityName = rarity and rarity.Name or rarityId,
				RarityColor = rarity and rarity.Color or Color3.fromRGB(180, 180, 180),
				Level = getValue(machineData, "Level", 1),
				FusionLevel = getValue(machineData, "FusionLevel", 0),
				Locked = getValue(machineData, "Locked", false),
				Placed = getValue(machineData, "Placed", false),
				PlotX = getValue(machineData, "PlotX", -1),
				PlotZ = getValue(machineData, "PlotZ", -1),
				Rotation = getValue(machineData, "Rotation", 0),
				FootprintX = footprintX,
				FootprintZ = footprintZ,
				Income = MachineInventoryService.getInstanceIncome(player, machineData),
				SellValue = MachineInventoryService.getSellValue(machineData),
				RecycleYield = MachineInventoryService.getRecycleYield(machineData),
				Traits = traits,
			})
		end
	end

	table.sort(instances, function(a, b)
		if a.Placed ~= b.Placed then
			return a.Placed
		end
		if a.MachineId ~= b.MachineId then
			return a.MachineId < b.MachineId
		end
		return a.InstanceId < b.InstanceId
	end)

	return {
		Instances = instances,
		RollCost = RandomMachineConfig.Roll.BaseCost,
		Scrap = ensureScrapValue(player).Value,
		ScrapName = RandomMachineConfig.Recycle.DisplayName,
		CurrentZone = ZoneService.getCurrentZone(player),
		Placement = {
			MaxColumns = maxColumns,
			MaxRows = maxRows,
		},
	}
end

function MachineInventoryService.fireUpdated(player)
	ensureRemotes()
	remotes.Updated:FireClient(player, MachineInventoryService.getInventoryState(player))
end

function MachineInventoryService.init()
	ensureRemotes()

	remotes.GetState.OnServerInvoke = function(player)
		return MachineInventoryService.getInventoryState(player)
	end

	remotes.Roll.OnServerInvoke = function(player)
		return MachineInventoryService.rollMachine(player)
	end

	remotes.Place.OnServerInvoke = function(player, instanceId, plotX, plotZ, rotation)
		local success, message = MachineInventoryService.placeMachine(player, instanceId, plotX, plotZ, rotation)
		return {
			Success = success,
			Message = message,
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	remotes.Unplace.OnServerInvoke = function(player, instanceId)
		local success, message = MachineInventoryService.unplaceMachine(player, instanceId)
		return {
			Success = success,
			Message = message,
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	remotes.Sell.OnServerInvoke = function(player, instanceId)
		local success, message = MachineInventoryService.sellMachine(player, instanceId)
		return {
			Success = success,
			Message = message,
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	remotes.Recycle.OnServerInvoke = function(player, instanceId)
		local success, message = MachineInventoryService.recycleMachine(player, instanceId)
		return {
			Success = success,
			Message = message,
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	remotes.Fuse.OnServerInvoke = function(player, instanceId)
		local success, message = MachineInventoryService.fuseMachine(player, instanceId)
		return {
			Success = success,
			Message = message,
			State = MachineInventoryService.getInventoryState(player),
		}
	end

	remotes.ToggleLock.OnServerInvoke = function(player, instanceId)
		local success, message = MachineInventoryService.toggleLock(player, instanceId)
		return {
			Success = success,
			Message = message,
			State = MachineInventoryService.getInventoryState(player),
		}
	end
end

return MachineInventoryService
