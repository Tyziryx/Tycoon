local ManualBurnerService = {}

local TweenService = game:GetService("TweenService")

local PollutionService = require(script.Parent.PollutionService)

-- Configuration pour les brûleurs manuels
local BurnerConfig = {
	COOLDOWN_TIME = 0.8, -- secondes entre chaque clic
	BASE_POLLUTION = 1, -- pollution générée par clic
	LEVEL_MULTIPLIER = 2, -- multiplicateur par niveau
}

-- Fonction pour vérifier si une machine est un feu de camp
function ManualBurnerService.isCampFire(machineId)
	return machineId == 1 or machineId == 2 or machineId == 3
end

-- Fonction appelée lors du spawn d'une machine pour configurer le brûleur si nécessaire
function ManualBurnerService.onMachineSpawned(machine, tycoon, machineId)
	if ManualBurnerService.isCampFire(machineId) then
		ManualBurnerService.setupBurner(machine, tycoon)
	end
end

function ManualBurnerService.setupBurner(campfire, tycoon)
	-- Ajouter un ClickDetector au feu de camp
	local clickDetector = campfire:FindFirstChild("ClickDetector")
	if not clickDetector then
		clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 15
		clickDetector.Parent = campfire
	end

	-- Créer des effets visuels de base
	ManualBurnerService.addVisualEffects(campfire)

	-- Connecter l'événement de clic
	clickDetector.MouseClick:Connect(function(player)
		ManualBurnerService.handleBurn(player, campfire, tycoon)
	end)
end

function ManualBurnerService.handleBurn(player, campfire, tycoon)
	-- Vérifier que c'est le bon joueur pour ce tycoon
	if tycoon:GetAttribute("UserId") ~= player.UserId then
		return
	end

	-- Vérifier le cooldown
	local lastBurnTime = campfire:GetAttribute("LastBurnTime") or 0
	local currentTime = tick()
	if currentTime - lastBurnTime < BurnerConfig.COOLDOWN_TIME then
		return
	end

	-- Enregistrer le temps du clic
	campfire:SetAttribute("LastBurnTime", currentTime)

	-- Calculer les récompenses basées sur le niveau de la machine
	local level = campfire:GetAttribute("CurrentLevel") or 1

	local pollutionGenerated = BurnerConfig.BASE_POLLUTION * (BurnerConfig.LEVEL_MULTIPLIER ^ (level - 1))

	-- Arrondir les valeurs
	pollutionGenerated = math.floor(pollutionGenerated)

	-- Donner les récompenses
	PollutionService.addPollution(player, pollutionGenerated)

	-- Effets visuels d'intensification temporaire
	local VisualEffectsService = require(script.Parent.VisualEffectsService)
	VisualEffectsService.intensifyEffects(campfire, 1, 1.5)
end

function ManualBurnerService.addVisualEffects(campfire)
	-- Trouver la bonne partie du feu de camp pour attacher les effets
	local targetPart = nil

	-- Chercher une partie nommée spécifiquement pour les effets
	local effectPart = campfire:FindFirstChild("Fire")
		or campfire:FindFirstChild("Flames")
		or campfire:FindFirstChild("Center")

	-- Si pas de partie spécifique, prendre la PrimaryPart ou la première BasePart trouvée
	if not effectPart then
		if campfire.PrimaryPart then
			targetPart = campfire.PrimaryPart
		else
			-- Trouver la première BasePart dans le modèle
			for _, child in campfire:GetChildren() do
				if child:IsA("BasePart") then
					targetPart = child
					break
				end
			end
		end
	else
		targetPart = effectPart
	end

	-- Si on n'a toujours pas de partie, créer une partie invisible au centre
	if not targetPart then
		targetPart = Instance.new("Part")
		targetPart.Name = "EffectAnchor"
		targetPart.Size = Vector3.new(1, 1, 1)
		targetPart.Transparency = 1
		targetPart.Anchored = true
		targetPart.CanCollide = false
		targetPart.CFrame = campfire:GetPivot()
		targetPart.Parent = campfire
	end

	-- Les effets visuels sont maintenant gérés par VisualEffectsService
	-- On n'a plus besoin de les créer manuellement ici
end

function ManualBurnerService.playBurnEffect(campfire, pollution)
	-- Trouver les effets dans le feu de camp (peuvent être sur différentes parties)
	local smoke = nil

	-- Chercher récursivement les effets dans tout le modèle
	local function findEffects(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("Smoke") and not smoke then
				smoke = child
			end
			-- Chercher dans les enfants si c'est un modèle ou une partie
			if child:IsA("Model") or child:IsA("BasePart") then
				findEffects(child)
			end
		end
	end

	findEffects(campfire)

	if smoke then
		local originalSize = smoke.Size
		smoke.Size = originalSize * 1.5

		-- Remettre à la normale après 1 seconde (non-bloquant)
		spawn(function()
			wait(1)
			if smoke and smoke.Parent then
				smoke.Size = originalSize
			end
		end)
	end

	if smoke then
		local originalOpacity = smoke.Opacity
		smoke.Opacity = math.min(1, originalOpacity * 1.5)

		-- Remettre à la normale après 0.5 seconde (non-bloquant)
		spawn(function()
			wait(0.5)
			if smoke and smoke.Parent then
				smoke.Opacity = originalOpacity
			end
		end)
	end

	-- Créer un texte flottant pour les récompenses
	ManualBurnerService.createFloatingText(campfire, "+" .. pollution .. " Pollution")
end

function ManualBurnerService.createFloatingText(campfire, text)
	-- Créer un GUI temporaire pour afficher les gains
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Parent = campfire

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Parent = billboardGui

	-- Animation de montée et disparition
	local tween = TweenService:Create(
		billboardGui,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = Vector3.new(0, 6, 0) }
	)

	local fadeTween = TweenService:Create(
		textLabel,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)

	tween:Play()
	fadeTween:Play()

	-- Supprimer après l'animation
	fadeTween.Completed:Connect(function()
		billboardGui:Destroy()
	end)
end

return ManualBurnerService
