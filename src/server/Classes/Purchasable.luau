-- Classe de base pour tous les objets achetables (machines, décorations, etc.)
local Purchasable = {}
Purchasable.__index = Purchasable

function Purchasable.new(id, config, purchasableType)
	local self = setmetatable({}, Purchasable)
	self.id = id
	self.config = config
	self.purchasableType = purchasableType -- "Machine" ou "Decoration"
	self.name = config.Name
	self.baseCost = config.BaseCost
	self.zoneRequired = config.ZoneRequired
	self.nextButton = config.NextButton
	return self
end

local function getOwnedFolder(player, purchasableType)
	local folderName = purchasableType == "Decoration" and "OwnedDecorations" or "OwnedMachines"
	return player.Data:FindFirstChild(folderName)
end

-- Méthodes communes à tous les achetables
function Purchasable:isOwnedByPlayer(player)
	local ownedItems = getOwnedFolder(player, self.purchasableType)
	if not ownedItems then
		return false
	end

	for _, itemData in ownedItems:GetChildren() do
		if itemData:IsA("Folder") and tonumber(itemData.Name) == self.id then
			return true
		end
		if itemData:IsA("IntValue") and itemData.Value == self.id then
			return true
		end
	end

	return false
end

function Purchasable:canPurchase(player)
	-- Vérifier les zones débloquées
	local currentZone = player.Data:FindFirstChild("CurrentZone")
	if currentZone and self.zoneRequired and currentZone.Value < self.zoneRequired then
		return false, "Zone non débloquée"
	end

	-- Vérifier si le joueur a assez d'argent
	local MoneyService = require(script.Parent.Parent.Services.MoneyService)
	if not MoneyService.canAfford(player, self.baseCost) then
		return false, "Pas assez d'argent"
	end

	return true, "Peut acheter"
end

function Purchasable:purchase(player, tycoon)
	if self:isOwnedByPlayer(player) then
		return false, "Déjà acheté"
	end

	local canPurchase, reason = self:canPurchase(player)
	if not canPurchase then
		return false, reason
	end

	-- Créer l'objet dans le monde
	local spawned = self:spawn(tycoon, player)
	if spawned == false then
		return false, "Création impossible"
	end

	-- Déduire le coût
	local MoneyService = require(script.Parent.Parent.Services.MoneyService)
	MoneyService.removeMoney(player, self.baseCost)

	-- Ajouter aux données du joueur
	self:addToPlayerData(player)

	return true, "Acheté avec succès"
end

-- Méthodes abstraites à surcharger par les classes filles
function Purchasable:spawn()
	error("Méthode abstraite - doit être implémentée par la classe fille")
end

function Purchasable:addToPlayerData()
	error("Méthode abstraite - doit être implémentée par la classe fille")
end

function Purchasable:getAssetModel()
	error("Méthode abstraite - doit être implémentée par la classe fille")
end

return Purchasable
