local Purchasable = require(script.Parent.Purchasable)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classe Decoration hérite de Purchasable
local Decoration = setmetatable({}, { __index = Purchasable })
Decoration.__index = Decoration

function Decoration.new(id, config)
	local self = Purchasable.new(id, config, "Decoration")
	setmetatable(self, Decoration)

	-- Propriétés spécifiques aux décorations
	self.category = config.Category or "Generic"
	self.description = config.Description or "Une belle décoration"

	return self
end

function Decoration:spawn(tycoon)
	local decorationModel = self:getAssetModel()
	if not decorationModel then
		warn("Modèle de décoration introuvable pour ID:", self.id)
		return false
	end

	local clonedDecoration = decorationModel:Clone()

	-- Pour les décorations, on pourrait avoir un système de placement différent
	-- Pour l'instant, on utilise le même système que les machines
	local TycoonService = require(script.Parent.Parent.Services.TycoonService)
	local relativeCF = TycoonService.getRelativeDecorationCFrame(self.id)

	if relativeCF then
		local worldCF = tycoon.PrimaryPart.CFrame:toWorldSpace(relativeCF)
		clonedDecoration:PivotTo(worldCF)
	else
		-- Position par défaut si pas de position spécifique
		local defaultPosition = tycoon.PrimaryPart.CFrame + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
		clonedDecoration:PivotTo(defaultPosition)
	end

	-- Créer le dossier Decorations s'il n'existe pas
	local decorationsFolder = tycoon:FindFirstChild("Decorations")
	if not decorationsFolder then
		decorationsFolder = Instance.new("Folder")
		decorationsFolder.Name = "Decorations"
		decorationsFolder.Parent = tycoon
	end

	clonedDecoration.Parent = decorationsFolder

	print("Décoration spawnée:", self.name, "Catégorie:", self.category)
	return true
end

function Decoration:addToPlayerData(player)
	-- Créer le dossier OwnedDecorations s'il n'existe pas
	local ownedDecorations = player.Data:FindFirstChild("OwnedDecorations")
	if not ownedDecorations then
		ownedDecorations = Instance.new("Folder")
		ownedDecorations.Name = "OwnedDecorations"
		ownedDecorations.Parent = player.Data
	end

	local decoration = Instance.new("IntValue")
	decoration.Name = self.name
	decoration.Value = self.id
	decoration.Parent = ownedDecorations
end

function Decoration:getAssetModel()
	local decorations = ReplicatedStorage:FindFirstChild("Decorations")
	if not decorations then
		warn("Dossier Decorations introuvable dans ReplicatedStorage")
		return nil
	end

	for _, decorationModel in decorations:GetChildren() do
		if decorationModel:GetAttribute("Id") == self.id then
			return decorationModel
		end
	end
	return nil
end

-- Méthodes spécifiques aux décorations
function Decoration:getBeautyValue()
	-- Les décorations pourraient ajouter une valeur "beauté" au tycoon
	local baseBeauty = 1
	if self.category == "Art" then
		baseBeauty = 5
	elseif self.category == "Plants" then
		baseBeauty = 3
	elseif self.category == "Lighting" then
		baseBeauty = 2
	end

	return baseBeauty
end

function Decoration:applyEffect(tycoon)
	-- Les décorations pourraient avoir des effets spéciaux
	-- Par exemple, améliorer le moral des visiteurs, augmenter les revenus, etc.

	if self.category == "Lighting" then
		-- Améliorer la visibilité la nuit
		print("Éclairage amélioré pour le tycoon")
	elseif self.category == "Plants" then
		-- Réduire légèrement la pollution
		print("Pollution réduite grâce aux plantes")
	end
end

return Decoration
