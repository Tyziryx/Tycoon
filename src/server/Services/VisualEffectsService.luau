local VisualEffectsService = {}

-- Configuration des effets par type de machine
local EffectsConfig = {
	-- Configuration pour les feux de camp
	CampFire = {
		-- Effets de particules à rechercher/créer
		effects = {
			{
				type = "Fire",
				properties = {
					Size = 5,
					Heat = 10,
					Color = Color3.fromRGB(255, 140, 0),
					SecondaryColor = Color3.fromRGB(255, 69, 0),
				},
				levelScaling = {
					[1] = { Rate = 10 },
					[2] = { Rate = 100 },
					[3] = { Rate = 10000 },
				},
			},
		},
		-- Parties où chercher/attacher les effets
		targetParts = { "FIRE", "Flames", "Center", "PrimaryPart", "FirstBasePart" },
	},

	-- Template pour futures machines
	-- Machine4 = {
	--     effects = {
	--         {
	--             type = "Smoke",
	--             properties = { ... },
	--             levelScaling = { ... }
	--         }
	--     },
	--     targetParts = {"Exhaust", "Chimney", "PrimaryPart"}
	-- }
}

-- Fonction principale pour configurer les effets d'une machine
function VisualEffectsService.setupMachineEffects(machine, machineName, level)
	level = level or 1

	local config = EffectsConfig[machineName]
	if not config then
		-- Pas d'effets configurés pour cette machine
		return
	end

	-- Trouver la partie cible pour les effets
	local targetPart = VisualEffectsService.findTargetPart(machine, config.targetParts)
	if not targetPart then
		warn("Impossible de trouver une partie cible pour", machineName)
		return
	end

	-- Configurer chaque effet
	for _, effectConfig in ipairs(config.effects) do
		VisualEffectsService.setupEffect(targetPart, effectConfig, level)
	end

	-- Sauvegarder les infos pour les mises à jour futures
	machine:SetAttribute("EffectsConfigured", true)
	machine:SetAttribute("EffectsMachineName", machineName)
end

-- Trouver la partie cible selon la priorité définie
function VisualEffectsService.findTargetPart(machine, targetParts)
	for _, partName in ipairs(targetParts) do
		if partName == "PrimaryPart" and machine.PrimaryPart then
			return machine.PrimaryPart
		elseif partName == "FirstBasePart" then
			-- Chercher la première BasePart
			for _, child in machine:GetChildren() do
				if child:IsA("BasePart") then
					return child
				end
			end
		else
			-- Chercher par nom
			local part = machine:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				return part
			end
		end
	end

	-- En dernier recours, créer une partie invisible
	local anchor = Instance.new("Part")
	anchor.Name = "EffectAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = machine:GetPivot()
	anchor.Parent = machine

	return anchor
end

-- Configurer un effet spécifique
function VisualEffectsService.setupEffect(targetPart, effectConfig, level)
	local effectType = effectConfig.type
	local existingEffect = targetPart:FindFirstChild(effectType)

	-- Créer l'effet s'il n'existe pas
	if not existingEffect then
		local effect = Instance.new(effectType)
		effect.Name = effectType

		-- Appliquer les propriétés de base
		for property, value in pairs(effectConfig.properties) do
			if effect[property] ~= nil then
				effect[property] = value
			end
		end

		effect.Parent = targetPart
		existingEffect = effect
	end

	-- Appliquer les modifications basées sur le niveau
	local levelConfig = effectConfig.levelScaling[level]
	if levelConfig then
		for property, value in pairs(levelConfig) do
			if existingEffect[property] ~= nil then
				existingEffect[property] = value
			end
		end
	end
end

-- Mettre à jour les effets quand le niveau change
function VisualEffectsService.updateMachineEffects(machine, newLevel)
	local machineName = machine:GetAttribute("EffectsMachineName")
	if not machineName then
		return
	end

	VisualEffectsService.setupMachineEffects(machine, machineName, newLevel)
end

-- Fonction pour intensifier temporairement les effets (pour les interactions)
function VisualEffectsService.intensifyEffects(machine, duration, multiplier)
	duration = duration or 1
	multiplier = multiplier or 1.5

	-- Trouver tous les effets dans la machine
	local effects = {}
	local function findEffects(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("Fire") then
				table.insert(effects, child)
			end
			if child:IsA("Model") or child:IsA("BasePart") then
				findEffects(child)
			end
		end
	end

	findEffects(machine)

	-- Intensifier les effets
	local originalValues = {}
	for _, effect in ipairs(effects) do
		originalValues[effect] = {}

		if effect:IsA("Fire") then
			originalValues[effect].Size = effect.Size
			effect.Size = effect.Size * multiplier
		end
	end

	-- Remettre à la normale après la durée
	spawn(function()
		wait(duration)
		for effect, values in pairs(originalValues) do
			if effect and effect.Parent then
				for property, value in pairs(values) do
					effect[property] = value
				end
			end
		end
	end)
end

-- Fonction pour ajouter facilement de nouveaux types de machines
function VisualEffectsService.registerMachineType(machineName, config)
	EffectsConfig[machineName] = config
end

return VisualEffectsService
