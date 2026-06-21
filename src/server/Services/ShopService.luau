local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrestigeConfig = require(ReplicatedStorage.Shared.Config.PrestigeConfig)

local ShopService = {}

local getShopRemote = nil
local purchaseRemote = nil
local shopUpdatedRemote = nil

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
	getShopRemote = getShopRemote or ensureRemoteFunction("GetPrestigeShopRemote")
	purchaseRemote = purchaseRemote or ensureRemoteFunction("PurchasePrestigeUpgradeRemote")
	shopUpdatedRemote = shopUpdatedRemote or ensureRemoteEvent("PrestigeShopUpdated")
end

local function ensurePrestigeFolder(player)
	local prestigeFolder = player.Data:FindFirstChild("PrestigeUpgrades")
	if not prestigeFolder then
		prestigeFolder = Instance.new("Folder")
		prestigeFolder.Name = "PrestigeUpgrades"
		prestigeFolder.Parent = player.Data
	end

	for upgradeId in pairs(PrestigeConfig.Upgrades) do
		if not prestigeFolder:FindFirstChild(upgradeId) then
			local level = Instance.new("IntValue")
			level.Name = upgradeId
			level.Value = 0
			level.Parent = prestigeFolder
		end
	end

	return prestigeFolder
end

local function getCendresValue(player)
	return player.Data and player.Data:FindFirstChild("Cendres")
end

local function updateCendresLeaderstat(player)
	local cendres = getCendresValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local leaderstat = leaderstats and leaderstats:FindFirstChild("Cendres")
	if cendres and leaderstat then
		leaderstat.Value = cendres.Value
	end
end

function ShopService.setupPlayer(player)
	ensurePrestigeFolder(player)
end

function ShopService.getUpgradeLevel(player, upgradeId)
	local prestigeFolder = ensurePrestigeFolder(player)
	local level = prestigeFolder:FindFirstChild(upgradeId)
	if level then
		return level.Value
	end
	return 0
end

function ShopService.getUpgradeCost(player, upgradeId)
	local upgradeConfig = PrestigeConfig.Upgrades[upgradeId]
	if not upgradeConfig then
		return nil
	end

	local level = ShopService.getUpgradeLevel(player, upgradeId)
	if level >= upgradeConfig.MaxLevel then
		return nil
	end

	return math.max(1, math.floor(upgradeConfig.BaseCost * (upgradeConfig.CostGrowth ^ level)))
end

function ShopService.getUpgradeValue(player, upgradeId)
	local upgradeConfig = PrestigeConfig.Upgrades[upgradeId]
	if not upgradeConfig then
		return 1
	end

	local level = ShopService.getUpgradeLevel(player, upgradeId)
	if upgradeConfig.ValueType == "additiveMultiplier" then
		return upgradeConfig.BaseValue + (upgradeConfig.ValuePerLevel * level)
	elseif upgradeConfig.ValueType == "decayMultiplier" then
		return math.max(upgradeConfig.MinValue or 0, upgradeConfig.BaseValue * (upgradeConfig.ValuePerLevel ^ level))
	elseif upgradeConfig.ValueType == "flat" then
		return upgradeConfig.BaseValue + (upgradeConfig.ValuePerLevel * level)
	end

	return upgradeConfig.BaseValue
end

function ShopService.getIncomeMultiplier(player)
	return ShopService.getUpgradeValue(player, "IncomeMultiplier")
end

function ShopService.getSellMultiplier(player)
	return ShopService.getUpgradeValue(player, "SellMultiplier")
end

function ShopService.getCostMultiplier(player)
	return ShopService.getUpgradeValue(player, "CostReduction")
end

function ShopService.getManualBurnMultiplier(player)
	return ShopService.getUpgradeValue(player, "ManualBurnBoost")
end

function ShopService.getStarterCash(player)
	return ShopService.getUpgradeValue(player, "StarterCash")
end

function ShopService.getPrestigeGainMultiplier(player)
	return ShopService.getUpgradeValue(player, "PrestigeGain")
end

function ShopService.getStartingMoney(player, baseMoney)
	return baseMoney + ShopService.getStarterCash(player)
end

function ShopService.applyCostReduction(player, baseCost)
	return math.max(0, math.floor(baseCost * ShopService.getCostMultiplier(player)))
end

function ShopService.getCendres(player)
	local cendres = getCendresValue(player)
	return cendres and cendres.Value or 0
end

function ShopService.addCendres(player, amount)
	local cendres = getCendresValue(player)
	if not cendres then
		return
	end

	cendres.Value = cendres.Value + amount
	updateCendresLeaderstat(player)
	ensureRemotes()
	shopUpdatedRemote:FireClient(player, ShopService.getShopState(player))
end

function ShopService.getShopState(player)
	ensurePrestigeFolder(player)

	local upgrades = {}
	for _, upgradeId in ipairs(PrestigeConfig.UpgradeOrder) do
		local upgradeConfig = PrestigeConfig.Upgrades[upgradeId]
		local level = ShopService.getUpgradeLevel(player, upgradeId)
		local nextCost = ShopService.getUpgradeCost(player, upgradeId)

		table.insert(upgrades, {
			Id = upgradeId,
			Name = upgradeConfig.Name,
			Description = upgradeConfig.Description,
			Level = level,
			MaxLevel = upgradeConfig.MaxLevel,
			NextCost = nextCost,
			Value = ShopService.getUpgradeValue(player, upgradeId),
		})
	end

	return {
		Cendres = ShopService.getCendres(player),
		Upgrades = upgrades,
	}
end

function ShopService.purchaseUpgrade(player, upgradeId)
	local upgradeConfig = PrestigeConfig.Upgrades[upgradeId]
	if not upgradeConfig then
		return {
			Success = false,
			Message = "Amélioration inconnue",
			ShopState = ShopService.getShopState(player),
		}
	end

	local cost = ShopService.getUpgradeCost(player, upgradeId)
	if not cost then
		return {
			Success = false,
			Message = "Niveau maximum atteint",
			ShopState = ShopService.getShopState(player),
		}
	end

	local cendres = getCendresValue(player)
	if not cendres or cendres.Value < cost then
		return {
			Success = false,
			Message = "Pas assez de Cendres",
			ShopState = ShopService.getShopState(player),
		}
	end

	local prestigeFolder = ensurePrestigeFolder(player)
	local level = prestigeFolder:FindFirstChild(upgradeId)
	if not level then
		return {
			Success = false,
			Message = "Données prestige introuvables",
			ShopState = ShopService.getShopState(player),
		}
	end

	cendres.Value = cendres.Value - cost
	level.Value = level.Value + 1
	updateCendresLeaderstat(player)

	local shopState = ShopService.getShopState(player)
	ensureRemotes()
	shopUpdatedRemote:FireClient(player, shopState)

	return {
		Success = true,
		Message = "Amélioration achetée",
		ShopState = shopState,
	}
end

function ShopService.init()
	ensureRemotes()

	getShopRemote.OnServerInvoke = function(player)
		return ShopService.getShopState(player)
	end

	purchaseRemote.OnServerInvoke = function(player, upgradeId)
		return ShopService.purchaseUpgrade(player, upgradeId)
	end
end

return ShopService
