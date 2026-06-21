local TweenService = game:GetService("TweenService")

local VisualEffectsService = {}

local CAMPFIRE_LEVELS = {
	[1] = {
		FireSize = 3.5,
		FireHeat = 7,
		SmokeSize = 2,
		SmokeOpacity = 0.3,
		SmokeRise = 4,
		LightRange = 10,
		LightBrightness = 1.1,
		EmberRate = 3,
		AshRate = 1,
	},
	[2] = {
		FireSize = 6,
		FireHeat = 12,
		SmokeSize = 4,
		SmokeOpacity = 0.5,
		SmokeRise = 6,
		LightRange = 15,
		LightBrightness = 2,
		EmberRate = 8,
		AshRate = 4,
	},
	[3] = {
		FireSize = 9,
		FireHeat = 17,
		SmokeSize = 6,
		SmokeOpacity = 0.7,
		SmokeRise = 8,
		LightRange = 22,
		LightBrightness = 3.25,
		EmberRate = 16,
		AshRate = 8,
	},
}

local FIRE_TARGET_PARTS = { "FireAnchor", "Fire", "FIRE", "Flames", "Center", "PrimaryPart", "FirstBasePart" }
local SMOKE_TARGET_PARTS = { "SmokeAnchor", "FireAnchor", "Fire", "FIRE", "Flames", "Center", "PrimaryPart", "FirstBasePart" }
local LEGACY_GENERATED_FOLDERS = { "ScorchMark", "ScorchMarks", "AshFlecks", "CampfirePollutionProps" }

local function getLevelConfig(level)
	return CAMPFIRE_LEVELS[level] or CAMPFIRE_LEVELS[1]
end

local function applyProperties(instance, properties)
	for property, value in pairs(properties) do
		pcall(function()
			instance[property] = value
		end)
	end
end

local function tween(instance, duration, properties, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
	local activeTween = TweenService:Create(instance, tweenInfo, properties)
	activeTween:Play()
	return activeTween
end

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function getPivotCFrame(machine)
	local ok, pivot = pcall(function()
		return machine:GetPivot()
	end)

	if ok then
		return pivot
	end

	return CFrame.new()
end

local function isInsideTierVisuals(instance)
	local parent = instance.Parent
	while parent do
		if parent.Name == "TierVisuals" then
			return true
		end
		parent = parent.Parent
	end

	return false
end

local function setEffectsEnabled(machine, enabled)
	for _, child in machine:GetDescendants() do
		if child:IsA("Fire") or child:IsA("Smoke") or child:IsA("ParticleEmitter") or child:IsA("PointLight") then
			child.Enabled = enabled
		end
	end
end

local function cleanupLegacyGeneratedProps(machine)
	for _, name in LEGACY_GENERATED_FOLDERS do
		local child = machine:FindFirstChild(name)
		if child then
			child:Destroy()
		end
	end
end

local function cacheRenderableOriginals(instance)
	if instance:IsA("BasePart") then
		if instance:GetAttribute("OriginalTransparency") == nil then
			instance:SetAttribute("OriginalTransparency", instance.Transparency)
		end
		if instance:GetAttribute("OriginalCanCollide") == nil then
			instance:SetAttribute("OriginalCanCollide", instance.CanCollide)
		end
		if instance:GetAttribute("OriginalCanTouch") == nil then
			instance:SetAttribute("OriginalCanTouch", instance.CanTouch)
		end
		if instance:GetAttribute("OriginalCanQuery") == nil then
			instance:SetAttribute("OriginalCanQuery", instance.CanQuery)
		end
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		if instance:GetAttribute("OriginalTransparency") == nil then
			instance:SetAttribute("OriginalTransparency", instance.Transparency)
		end
	elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
		if instance:GetAttribute("OriginalEnabled") == nil then
			instance:SetAttribute("OriginalEnabled", instance.Enabled)
		end
	end
end

local function setRenderableVisible(instance, visible)
	cacheRenderableOriginals(instance)

	if instance:IsA("BasePart") then
		if visible then
			instance.Transparency = instance:GetAttribute("OriginalTransparency") or 0
			instance.CanCollide = instance:GetAttribute("OriginalCanCollide") == true
			instance.CanTouch = instance:GetAttribute("OriginalCanTouch") == true
			instance.CanQuery = instance:GetAttribute("OriginalCanQuery") == true
		else
			instance.Transparency = 1
			instance.CanCollide = false
			instance.CanTouch = false
			instance.CanQuery = false
		end
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		instance.Transparency = visible and (instance:GetAttribute("OriginalTransparency") or 0) or 1
	elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
		instance.Enabled = visible and (instance:GetAttribute("OriginalEnabled") ~= false)
	elseif instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("ParticleEmitter") or instance:IsA("PointLight") then
		instance.Enabled = visible
	end
end

local function setVisualTreeVisible(root, visible)
	setRenderableVisible(root, visible)
	for _, descendant in root:GetDescendants() do
		setRenderableVisible(descendant, visible)
	end
end

local function getTierLevel(child)
	local level = child:GetAttribute("Level")
	if type(level) == "number" then
		return level
	end

	return tonumber(child.Name:match("^Level(%d+)$"))
end

local function getTierVisualsFolder(machine)
	local folder = machine:FindFirstChild("TierVisuals", true)
	if folder and folder:IsA("Folder") then
		return folder
	end

	return nil
end

local function getOrCreateTierFolder(machine)
	local folder = getTierVisualsFolder(machine)
	if folder then
		return folder
	end

	return getOrCreate(machine, "Folder", "TierVisuals")
end

local function getMarkerCFrame(machine, firePart, level)
	if firePart and firePart:IsA("BasePart") then
		return firePart.CFrame * CFrame.new(0, level == 2 and 1.7 or 2.25, -1.6)
	end

	local cf, size = machine:GetBoundingBox()
	return cf * CFrame.new(0, math.max(1, size.Y * 0.5), -math.max(1.5, size.Z * 0.4))
end

local function setupLevelMarker(levelFolder, machine, firePart, level, color)
	local marker = levelFolder:FindFirstChild("DebugLevel" .. level .. "Marker")
	if not marker then
		marker = Instance.new("Part")
		marker.Name = "DebugLevel" .. level .. "Marker"
		marker.Size = Vector3.new(1, 1, 1)
		marker.Transparency = 1
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
		marker.Parent = levelFolder
	end

	marker.CFrame = getMarkerCFrame(machine, firePart, level)

	local billboard = marker:FindFirstChild("LevelMarkerGui")
	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "LevelMarkerGui"
		billboard.Size = UDim2.fromOffset(150, 48)
		billboard.AlwaysOnTop = true
		billboard.Parent = marker
	end
	billboard.Enabled = true

	local label = billboard:FindFirstChild("Label")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BorderSizePixel = 0
		label.Size = UDim2.fromScale(1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.Parent = billboard
	end

	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(25, 22, 18)
	label.Text = "NIVEAU " .. level
	label.TextColor3 = color
end

local function ensureDebugLevelMarkers(machine, firePart)
	local tierVisuals = getOrCreateTierFolder(machine)
	getOrCreate(tierVisuals, "Folder", "Level1")
	local level2 = getOrCreate(tierVisuals, "Folder", "Level2")
	local level3 = getOrCreate(tierVisuals, "Folder", "Level3")

	setupLevelMarker(level2, machine, firePart, 2, Color3.fromRGB(255, 199, 88))
	setupLevelMarker(level3, machine, firePart, 3, Color3.fromRGB(255, 84, 48))
end

local function applyTierVisuals(machine, level)
	local folder = getTierVisualsFolder(machine)
	if not folder then
		return
	end

	for _, child in folder:GetChildren() do
		local tierLevel = getTierLevel(child)
		if tierLevel then
			-- Tiers are additive: Level2 and Level3 folders contain only extra pieces.
			setVisualTreeVisible(child, tierLevel <= level)
		end
	end
end

local function animateTierReveal(machine, level)
	local folder = getTierVisualsFolder(machine)
	if not folder then
		return
	end

	local tierFolder = folder:FindFirstChild("Level" .. level)
	if not tierFolder then
		return
	end

	for _, descendant in tierFolder:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 then
			local originalSize = descendant.Size
			descendant.Size = originalSize * 0.82
			tween(descendant, 0.45, { Size = originalSize }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end
end

function VisualEffectsService.findTargetPart(machine, targetParts)
	for _, partName in targetParts do
		if partName == "PrimaryPart" and machine.PrimaryPart then
			return machine.PrimaryPart
		elseif partName == "FirstBasePart" then
			for _, child in machine:GetDescendants() do
				if child:IsA("BasePart") and not isInsideTierVisuals(child) then
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
	anchor.CanQuery = false
	anchor.CFrame = getPivotCFrame(machine)
	anchor.Parent = machine

	return anchor
end

local function setupFire(firePart, levelConfig)
	local fire = getOrCreate(firePart, "Fire", "Fire")
	applyProperties(fire, {
		Size = levelConfig.FireSize,
		Heat = levelConfig.FireHeat,
		Color = Color3.fromRGB(255, 118, 31),
		SecondaryColor = Color3.fromRGB(255, 40, 0),
		Enabled = true,
	})
end

local function setupSmoke(smokePart, levelConfig)
	local smoke = getOrCreate(smokePart, "Smoke", "Smoke")
	applyProperties(smoke, {
		Size = levelConfig.SmokeSize,
		Opacity = levelConfig.SmokeOpacity,
		RiseVelocity = levelConfig.SmokeRise,
		Color = Color3.fromRGB(28, 27, 25),
		Enabled = true,
	})
end

local function setupLight(firePart, levelConfig)
	local light = getOrCreate(firePart, "PointLight", "CampfireGlow")
	applyProperties(light, {
		Color = Color3.fromRGB(255, 128, 45),
		Range = levelConfig.LightRange,
		Brightness = levelConfig.LightBrightness,
		Shadows = true,
		Enabled = true,
	})
end

local function setupEmitter(parent, name, properties)
	local emitter = getOrCreate(parent, "ParticleEmitter", name)
	applyProperties(emitter, properties)
	return emitter
end

local function setupCampfireEmitters(firePart, smokePart, levelConfig)
	setupEmitter(firePart, "DirtyEmbers", {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 185, 62)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 77, 26)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 30, 24)),
		}),
		LightEmission = 0.45,
		Lifetime = NumberRange.new(0.55, 1.2),
		Rate = levelConfig.EmberRate,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-90, 90),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.35, 0.18),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(55, 55),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.75, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Acceleration = Vector3.new(0, 7, 0),
		Drag = 4,
		Enabled = true,
	})

	setupEmitter(smokePart, "BlackAsh", {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(20, 19, 18), Color3.fromRGB(75, 70, 60)),
		LightEmission = 0,
		Lifetime = NumberRange.new(1.2, 2.6),
		Rate = levelConfig.AshRate,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-35, 35),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.18),
			NumberSequenceKeypoint.new(0.6, 0.28),
			NumberSequenceKeypoint.new(1, 0.06),
		}),
		Speed = NumberRange.new(0.75, 2),
		SpreadAngle = Vector2.new(25, 25),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Acceleration = Vector3.new(0, 5, 0),
		Drag = 2,
		Enabled = true,
	})
end

local function setupCampfireVisuals(machine, level)
	cleanupLegacyGeneratedProps(machine)

	local levelConfig = getLevelConfig(level)
	local firePart = VisualEffectsService.findTargetPart(machine, FIRE_TARGET_PARTS)
	local smokePart = VisualEffectsService.findTargetPart(machine, SMOKE_TARGET_PARTS)

	ensureDebugLevelMarkers(machine, firePart)
	applyTierVisuals(machine, level)
	setupFire(firePart, levelConfig)
	setupSmoke(smokePart, levelConfig)
	setupLight(firePart, levelConfig)
	setupCampfireEmitters(firePart, smokePart, levelConfig)

	machine:SetAttribute("EffectsConfigured", true)
	machine:SetAttribute("EffectsMachineName", "CampFire")
	machine:SetAttribute("FireTargetName", firePart.Name)
	machine:SetAttribute("SmokeTargetName", smokePart.Name)
end

function VisualEffectsService.setupMachineEffects(machine, machineName, level)
	if machineName == "CampFire" then
		setupCampfireVisuals(machine, level or 1)
	end
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

	local levelConfig = effectConfig.levelScaling and effectConfig.levelScaling[level]
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
	VisualEffectsService.playUpgradePulse(machine, newLevel)
	animateTierReveal(machine, newLevel)
end

function VisualEffectsService.intensifyEffects(machine, duration, multiplier)
	duration = duration or 1
	multiplier = multiplier or 1.5

	local effects = {}
	for _, child in machine:GetDescendants() do
		if child:IsA("Fire") or child:IsA("Smoke") or child:IsA("PointLight") then
			table.insert(effects, child)
		end
	end

	local originalValues = {}
	for _, effect in effects do
		originalValues[effect] = {}

		if effect:IsA("Fire") then
			originalValues[effect].Size = effect.Size
			originalValues[effect].Heat = effect.Heat
			effect.Size = effect.Size * multiplier
			effect.Heat = effect.Heat * multiplier
		elseif effect:IsA("Smoke") then
			originalValues[effect].Size = effect.Size
			originalValues[effect].Opacity = effect.Opacity
			effect.Size = effect.Size * multiplier
			effect.Opacity = math.min(1, effect.Opacity * multiplier)
		elseif effect:IsA("PointLight") then
			originalValues[effect].Brightness = effect.Brightness
			effect.Brightness = effect.Brightness * multiplier
		end
	end

	task.spawn(function()
		task.wait(duration)
		for effect, values in originalValues do
			if effect and effect.Parent then
				applyProperties(effect, values)
			end
		end
	end)
end

function VisualEffectsService.playBurnerBurst(machine, level)
	level = level or machine:GetAttribute("CurrentLevel") or 1
	local levelConfig = getLevelConfig(level)
	local firePart = VisualEffectsService.findTargetPart(machine, FIRE_TARGET_PARTS)
	local smokePart = VisualEffectsService.findTargetPart(machine, SMOKE_TARGET_PARTS)

	local embers = firePart:FindFirstChild("DirtyEmbers")
	if embers and embers:IsA("ParticleEmitter") then
		embers:Emit(8 + level * 8)
	end

	local ash = smokePart:FindFirstChild("BlackAsh")
	if ash and ash:IsA("ParticleEmitter") then
		ash:Emit(4 + level * 6)
	end

	local smoke = smokePart:FindFirstChild("Smoke")
	if smoke and smoke:IsA("Smoke") then
		local originalOpacity = smoke.Opacity
		local originalSize = smoke.Size
		smoke.Opacity = math.min(1, levelConfig.SmokeOpacity + 0.25)
		smoke.Size = levelConfig.SmokeSize * 1.35
		task.delay(0.45, function()
			if smoke.Parent then
				tween(smoke, 0.35, {
					Opacity = originalOpacity,
					Size = originalSize,
				})
			end
		end)
	end

	local light = firePart:FindFirstChild("CampfireGlow")
	if light and light:IsA("PointLight") then
		local originalBrightness = light.Brightness
		light.Brightness = originalBrightness * 1.8
		tween(light, 0.45, { Brightness = originalBrightness })
	end

	VisualEffectsService.intensifyEffects(machine, 0.35, 1.25)
end

function VisualEffectsService.playUpgradePulse(machine, level)
	local firePart = VisualEffectsService.findTargetPart(machine, FIRE_TARGET_PARTS)
	local smokePart = VisualEffectsService.findTargetPart(machine, SMOKE_TARGET_PARTS)

	local embers = firePart:FindFirstChild("DirtyEmbers")
	if embers and embers:IsA("ParticleEmitter") then
		embers:Emit(18 + level * 12)
	end

	local ash = smokePart:FindFirstChild("BlackAsh")
	if ash and ash:IsA("ParticleEmitter") then
		ash:Emit(10 + level * 8)
	end
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
		if child:IsA("BasePart") and child.Transparency < 1 then
			table.insert(parts, child)
			partOriginals[child] = {
				Transparency = child.Transparency,
				Size = child.Size,
			}

			child.Transparency = 1
			child.Size = child.Size * 0.68
		end
	end

	table.sort(parts, function(left, right)
		return left.Position.Y < right.Position.Y
	end)

	local tweenDuration = math.max(0.18, buildTime * 0.5)
	for index, part in parts do
		local values = partOriginals[part]
		local delayTime = (#parts > 1) and ((index - 1) / (#parts - 1)) * buildTime * 0.5 or 0

		task.delay(delayTime, function()
			if part.Parent then
				tween(part, tweenDuration, {
					Transparency = values.Transparency,
					Size = values.Size,
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end)
	end

	task.delay(buildTime * 0.75, function()
		if machine.Parent then
			setEffectsEnabled(machine, true)
			VisualEffectsService.playBurnerBurst(machine, machine:GetAttribute("CurrentLevel") or 1)
		end
	end)

	task.delay(buildTime, function()
		if machine.Parent then
			machine:SetAttribute("IsBuilding", false)
		end
	end)
end

function VisualEffectsService.registerMachineType(_machineName, _config)
	-- Kept for compatibility with older code paths.
end

return VisualEffectsService
