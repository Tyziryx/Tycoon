local TweenService = game:GetService("TweenService")

local VisualEffectsService = {}

local EffectsConfig = {
	CampFire = {
		effects = {
			{
				type = "Fire",
				properties = {
					Size = 4,
					Heat = 8,
					Color = Color3.fromRGB(255, 140, 0),
					SecondaryColor = Color3.fromRGB(255, 69, 0),
				},
				levelScaling = {
					[1] = { Size = 4, Heat = 8 },
					[2] = { Size = 6, Heat = 12 },
					[3] = { Size = 9, Heat = 16 },
				},
			},
			{
				type = "Smoke",
				properties = {
					Size = 2,
					Opacity = 0.35,
					RiseVelocity = 5,
					Color = Color3.fromRGB(45, 45, 45),
				},
				levelScaling = {
					[1] = { Size = 2, Opacity = 0.35 },
					[2] = { Size = 3, Opacity = 0.45 },
					[3] = { Size = 4, Opacity = 0.55 },
				},
			},
		},
		targetParts = { "Fire", "FIRE", "Flames", "Center", "PrimaryPart", "FirstBasePart" },
	},
}

local function applyProperties(instance, properties)
	for property, value in pairs(properties) do
		pcall(function()
			instance[property] = value
		end)
	end
end

local function setEffectsEnabled(machine, enabled)
	for _, child in machine:GetDescendants() do
		if child:IsA("Fire") or child:IsA("Smoke") or child:IsA("ParticleEmitter") then
			child.Enabled = enabled
		end
	end
end

function VisualEffectsService.setupMachineEffects(machine, machineName, level)
	level = level or 1

	local config = EffectsConfig[machineName]
	if not config then
		return
	end

	local targetPart = VisualEffectsService.findTargetPart(machine, config.targetParts)
	if not targetPart then
		warn("Impossible de trouver une partie cible pour", machineName)
		return
	end

	for _, effectConfig in ipairs(config.effects) do
		VisualEffectsService.setupEffect(targetPart, effectConfig, level)
	end

	machine:SetAttribute("EffectsConfigured", true)
	machine:SetAttribute("EffectsMachineName", machineName)
end

function VisualEffectsService.findTargetPart(machine, targetParts)
	for _, partName in ipairs(targetParts) do
		if partName == "PrimaryPart" and machine.PrimaryPart then
			return machine.PrimaryPart
		elseif partName == "FirstBasePart" then
			for _, child in machine:GetDescendants() do
				if child:IsA("BasePart") then
					return child
				end
			end
		else
			local part = machine:FindFirstChild(partName, true)
			if part and part:IsA("BasePart") then
				return part
			end
		end
	end

	local anchor = Instance.new("Part")
	anchor.Name = "EffectAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CFrame = machine:GetPivot()
	anchor.Parent = machine

	return anchor
end

function VisualEffectsService.setupEffect(targetPart, effectConfig, level)
	local effectType = effectConfig.type
	local existingEffect = targetPart:FindFirstChild(effectType)

	if not existingEffect then
		local effect = Instance.new(effectType)
		effect.Name = effectType
		applyProperties(effect, effectConfig.properties)
		effect.Parent = targetPart
		existingEffect = effect
	end

	local levelConfig = effectConfig.levelScaling[level]
	if levelConfig then
		applyProperties(existingEffect, levelConfig)
	end
end

function VisualEffectsService.updateMachineEffects(machine, newLevel)
	local machineName = machine:GetAttribute("EffectsMachineName")
	if not machineName then
		return
	end

	VisualEffectsService.setupMachineEffects(machine, machineName, newLevel)
end

function VisualEffectsService.intensifyEffects(machine, duration, multiplier)
	duration = duration or 1
	multiplier = multiplier or 1.5

	local effects = {}
	for _, child in machine:GetDescendants() do
		if child:IsA("Fire") or child:IsA("Smoke") then
			table.insert(effects, child)
		end
	end

	local originalValues = {}
	for _, effect in ipairs(effects) do
		originalValues[effect] = {}

		if effect:IsA("Fire") then
			originalValues[effect].Size = effect.Size
			effect.Size = effect.Size * multiplier
		elseif effect:IsA("Smoke") then
			originalValues[effect].Size = effect.Size
			originalValues[effect].Opacity = effect.Opacity
			effect.Size = effect.Size * multiplier
			effect.Opacity = math.min(1, effect.Opacity * multiplier)
		end
	end

	task.spawn(function()
		task.wait(duration)
		for effect, values in pairs(originalValues) do
			if effect and effect.Parent then
				applyProperties(effect, values)
			end
		end
	end)
end

function VisualEffectsService.playBuildAnimation(machine, buildTime)
	buildTime = buildTime or 0
	if buildTime <= 0 then
		machine:SetAttribute("IsBuilding", false)
		setEffectsEnabled(machine, true)
		return
	end

	setEffectsEnabled(machine, false)

	local parts = {}
	local partOriginals = {}
	for _, child in machine:GetDescendants() do
		if child:IsA("BasePart") then
			table.insert(parts, child)
			partOriginals[child] = {
				Transparency = child.Transparency,
				Size = child.Size,
			}

			child.Transparency = 1
			child.Size = child.Size * 0.75
		end
	end

	local tweenDuration = math.max(0.15, buildTime * 0.55)
	for index, part in ipairs(parts) do
		local values = partOriginals[part]
		local delayTime = (#parts > 1) and ((index - 1) / (#parts - 1)) * buildTime * 0.45 or 0

		task.delay(delayTime, function()
			if part.Parent then
				local tween = TweenService:Create(
					part,
					TweenInfo.new(tweenDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{
						Transparency = values.Transparency,
						Size = values.Size,
					}
				)
				tween:Play()
			end
		end)
	end

	task.delay(buildTime * 0.75, function()
		if machine.Parent then
			setEffectsEnabled(machine, true)
		end
	end)

	task.delay(buildTime, function()
		if machine.Parent then
			machine:SetAttribute("IsBuilding", false)
		end
	end)
end

function VisualEffectsService.registerMachineType(machineName, config)
	EffectsConfig[machineName] = config
end

return VisualEffectsService
