local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tycoons = game.Workspace:WaitForChild("Tycoons")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)
local ShopService = require(script.Parent.ShopService)

local TycoonService = {}

local CLAIM_PORTAL_NAME = "ClaimPortal"
local originalMachinePositions = {}

local updateButtonsEvent = Instance.new("BindableEvent")
updateButtonsEvent.Name = "UpdateButtons"
updateButtonsEvent.Parent = ReplicatedStorage

local function findBasePart(model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function makePart(name, size, cframe, color, transparency, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
	return part
end

local function getPortalCFrame(tycoon)
	local base = findBasePart(tycoon)
	if not base then
		return tycoon:GetPivot()
	end

	return base.CFrame * CFrame.new(0, (base.Size.Y * 0.5) + 0.18, (-base.Size.Z * 0.5) - 4)
end

local function setPortalLabel(portal, text)
	for _, descendant in portal:GetDescendants() do
		if descendant.Name == "ClaimLabel" and descendant:IsA("TextLabel") then
			descendant.Text = text
		end
	end
end

local function setPartColor(portal, color)
	for _, descendant in portal:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:GetAttribute("StaticPortalColor") ~= true then
			descendant.Color = color
		end
	end
end

local function createSignSurface(sign, face)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ClaimSurface"
	surfaceGui.Face = face
	surfaceGui.CanvasSize = Vector2.new(700, 220)
	surfaceGui.LightInfluence = 0
	surfaceGui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "ClaimLabel"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBlack
	label.Text = "CLAIM\nZONE"
	label.TextColor3 = Color3.fromRGB(255, 245, 210)
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = surfaceGui
end

local function connectPortalClaim(portal, tycoon)
	local prompt = portal:FindFirstChild("ClaimPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(player)
			TycoonService.claimTycoon(player, tycoon)
		end)
	end

	local pad = portal:FindFirstChild("ClaimPad", true)
	if pad and pad:IsA("BasePart") then
		pad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				TycoonService.claimTycoon(player, tycoon)
			end
		end)
	end
end

function TycoonService.updateClaimPortal(tycoon)
	local portal = tycoon:FindFirstChild(CLAIM_PORTAL_NAME)
	if not portal then
		return
	end

	local taken = tycoon:GetAttribute("Taken") == true
	local userId = tycoon:GetAttribute("UserId")
	local prompt = portal:FindFirstChild("ClaimPrompt", true)

	if taken then
		local owner = type(userId) == "number" and Players:GetPlayerByUserId(userId) or nil
		local ownerName = owner and owner.Name or "OCCUPEE"
		setPortalLabel(portal, "ZONE DE\n" .. ownerName)
		setPartColor(portal, Color3.fromRGB(255, 134, 55))

		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = false
		end
	else
		setPortalLabel(portal, "CLAIM\nZONE")
		setPartColor(portal, Color3.fromRGB(92, 255, 132))

		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = true
			prompt.ActionText = "Claim"
			prompt.ObjectText = "Zone libre"
		end
	end
end

function TycoonService.createClaimPortal(tycoon)
	local existing = tycoon:FindFirstChild(CLAIM_PORTAL_NAME)
	if existing and existing:GetAttribute("GeneratedByTycoonService") == true then
		existing:Destroy()
	end

	local portal = Instance.new("Model")
	portal.Name = CLAIM_PORTAL_NAME
	portal:SetAttribute("GeneratedByTycoonService", true)
	portal.Parent = tycoon

	local portalCF = getPortalCFrame(tycoon)
	local freeColor = Color3.fromRGB(92, 255, 132)
	local darkColor = Color3.fromRGB(18, 24, 18)

	local pad = makePart("ClaimPad", Vector3.new(8, 0.25, 4), portalCF, freeColor, 0.2, portal)
	pad.CanTouch = true

	makePart("LeftPillar", Vector3.new(0.55, 5, 0.55), portalCF * CFrame.new(-3.25, 2.5, 0), freeColor, 0, portal)
	makePart("RightPillar", Vector3.new(0.55, 5, 0.55), portalCF * CFrame.new(3.25, 2.5, 0), freeColor, 0, portal)
	local topBeam = makePart("TopBeam", Vector3.new(7.1, 0.55, 0.55), portalCF * CFrame.new(0, 5, 0), freeColor, 0, portal)
	makePart("PortalGlow", Vector3.new(6.5, 4.2, 0.18), portalCF * CFrame.new(0, 2.6, 0.05), freeColor, 0.65, portal)
	local sign = makePart("ClaimSign", Vector3.new(5.8, 1.45, 0.18), portalCF * CFrame.new(0, 4.08, -0.38), darkColor, 0, portal)
	sign.Material = Enum.Material.SmoothPlastic
	sign:SetAttribute("StaticPortalColor", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimPrompt"
	prompt.ActionText = "Claim"
	prompt.ObjectText = "Zone libre"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	createSignSurface(sign, Enum.NormalId.Front)
	createSignSurface(sign, Enum.NormalId.Back)

	connectPortalClaim(portal, tycoon)
	TycoonService.updateClaimPortal(tycoon)
	return portal
end

function TycoonService.init()
	for _, tycoon in Tycoons:GetChildren() do
		if not tycoon:IsA("Model") then
			continue
		end

		tycoon:SetAttribute("Taken", false)
		tycoon:SetAttribute("UserId", nil)

		local machines = tycoon:FindFirstChild("Machines")
		if machines then
			for _, machine in machines:GetChildren() do
				local machineId = machine:GetAttribute("Id")
				if machineId and tycoon.PrimaryPart then
					originalMachinePositions[machineId] = tycoon.PrimaryPart.CFrame:toObjectSpace(machine:GetPivot())
				end
			end

			machines:ClearAllChildren()
		end

		TycoonService.createClaimPortal(tycoon)
	end
end

function TycoonService.claimTycoon(player, tycoon)
	if not player or not tycoon then
		return nil
	end

	local existingTycoon = TycoonService.getTycoon(player)
	if existingTycoon then
		return existingTycoon
	end

	if tycoon:GetAttribute("Taken") then
		return nil
	end

	tycoon:SetAttribute("Taken", true)
	tycoon:SetAttribute("UserId", player.UserId)

	TycoonService.initializeSellPoint(tycoon)
	TycoonService.updateClaimPortal(tycoon)
	return tycoon
end

function TycoonService.assignTycoon(player)
	if player == nil then
		warn("Player is nil")
		return nil
	end

	for _, tycoon in Tycoons:GetChildren() do
		if not tycoon:GetAttribute("Taken") then
			return TycoonService.claimTycoon(player, tycoon)
		end
	end

	return nil
end

function TycoonService.getTycoon(player)
	if player == nil then
		warn("Player is nil")
		return nil
	end

	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("UserId") == player.UserId then
			return tycoon
		end
	end

	return nil
end

function TycoonService.getRelativeCFrame(machineId)
	if machineId == nil then
		warn("MachineId is nil")
		return CFrame.new(0, 0, 0)
	end

	local originalPosition = originalMachinePositions[machineId]
	if originalPosition then
		return originalPosition
	end

	local defaultPositions = {
		[1] = CFrame.new(0, 0, 0),
		[2] = CFrame.new(8, 0, 0),
		[3] = CFrame.new(16, 0, 0),
	}

	warn("Position originale non trouvee pour machine ID:", machineId, "- utilisation fallback")
	return defaultPositions[machineId] or CFrame.new(0, 0, 0)
end

function TycoonService.getRelativeDecorationCFrame(decorationId)
	if decorationId == nil then
		warn("DecorationId is nil")
		return nil
	end

	local decorationPositions = {
		[1] = CFrame.new(5, 0, 5),
		[2] = CFrame.new(-3, 0, 8),
		[3] = CFrame.new(10, 0, -5),
		[4] = CFrame.new(0, 0, 12),
	}

	return decorationPositions[decorationId]
end

function TycoonService.initializeSellPoint(tycoon)
	if tycoon == nil then
		warn("Tycoon is nil")
		return
	end

	if tycoon:GetAttribute("SellPointInitialized") == true then
		return
	end

	local decoration = tycoon:FindFirstChild("Decoration")
	if decoration == nil then
		warn("Decorations is nil")
		return
	end

	local mafia = decoration:FindFirstChild("Mafia")
	if mafia == nil then
		warn("Mafia is nil")
		return
	end

	local promptBlock = mafia:FindFirstChild("PromptBlock")
	if promptBlock == nil then
		warn("PromptBlock is nil")
		return
	end

	local prompt = promptBlock:FindFirstChild("ProximityPrompt")
	if prompt == nil then
		warn("ProximityPrompt is nil")
		return
	end

	local conversionSound = mafia:FindFirstChild("ConversionSound")
	if not conversionSound then
		conversionSound = Instance.new("Sound")
		conversionSound.Name = "ConversionSound"
		conversionSound.SoundId = "rbxassetid://133292918309565"
		conversionSound.Volume = 0.8
		conversionSound.Parent = mafia
	end

	prompt.Triggered:Connect(function(player)
		if player == nil then
			warn("Player is nil")
			return
		end

		local pollution = PollutionService.getPollution(player)
		if pollution == nil then
			warn("Pollution is nil")
			return
		end

		local moneyToAdd = math.floor(pollution * GameConfig.POLLUTION_TO_MONEY_RATE * ShopService.getSellMultiplier(player))
		if pollution > 0 and moneyToAdd == 0 then
			moneyToAdd = 1
		end

		PollutionService.removePollution(player, pollution)
		MoneyService.addMoney(player, moneyToAdd)
		conversionSound:Play()

		local sparkles = Instance.new("Sparkles")
		sparkles.Parent = promptBlock
		sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
		task.delay(2, function()
			sparkles:Destroy()
		end)

		updateButtonsEvent:Fire()
	end)

	tycoon:SetAttribute("SellPointInitialized", true)
end

function TycoonService.getOriginalMachinePositions()
	return originalMachinePositions
end

return TycoonService
