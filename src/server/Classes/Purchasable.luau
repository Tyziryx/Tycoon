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
	self.isUnlocked = false
	return self
end

-- Méthodes communes à tous les achetables
function Purchasable:canPurchase(player)
	-- Vérifier les zones débloquées
	local unlockedZones = player.Data.UnlockedZones
	if not unlockedZones:GetChildren()[self.zoneRequired] then
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
	if self.isUnlocked then
		return false, "Déjà acheté"
	end

	local canPurchase, reason = self:canPurchase(player)
	if not canPurchase then
		return false, reason
	end

	-- Déduire le coût
	local MoneyService = require(script.Parent.Parent.Services.MoneyService)
	MoneyService.removeMoney(player, self.baseCost)

	-- Créer l'objet dans le monde
	self:spawn(tycoon)

	-- Marquer comme débloqué
	self.isUnlocked = true

	-- Ajouter aux données du joueur
	self:addToPlayerData(player)

	return true, "Acheté avec succès"
end

-- Méthodes abstraites à surcharger par les classes filles
function Purchasable:spawn(tycoon)
	error("Méthode abstraite - doit être implémentée par la classe fille")
end

function Purchasable:addToPlayerData(player)
	error("Méthode abstraite - doit être implémentée par la classe fille")
end

function Purchasable:getAssetModel()
	error("Méthode abstraite - doit être implémentée par la classe fille")
end

return Purchasable
