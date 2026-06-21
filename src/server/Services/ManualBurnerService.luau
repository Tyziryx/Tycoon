local ManualBurnerService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local PollutionService = require(script.Parent.PollutionService)

local BurnerConfig = {
	COOLDOWN_TIME = 0.8,
	BASE_POLLUTION = 1,
	LEVEL_MULTIPLIER = 2,
}

function ManualBurnerService.isCampFire(machineId)
	local config = MachineConfig[machineId]
	return config and (config.ManualBurner == true or config.Name == "CampFire")
end

function ManualBurnerService.onMachineSpawned(machine, tycoon, machineId)
	if ManualBurnerService.isCampFire(machineId) then
		ManualBurnerService.setupBurner(machine, tycoon)
	end
end

function ManualBurnerService.setupBurner(campfire, tycoon)
	local clickTarget = campfire.PrimaryPart or campfire:FindFirstChildWhichIsA("BasePart", true) or campfire
	local clickDetector = clickTarget:FindFirstChild("ClickDetector")
	if not clickDetector then
		clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 15
		clickDetector.Parent = clickTarget
	end

	clickDetector.MouseClick:Connect(function(player)
		ManualBurnerService.handleBurn(player, campfire, tycoon)
	end)
end

function ManualBurnerService.handleBurn(player, campfire, tycoon)
	if campfire:GetAttribute("IsBuilding") then
		return
	end

	if tycoon:GetAttribute("UserId") ~= player.UserId then
		return
	end

	local lastBurnTime = campfire:GetAttribute("LastBurnTime") or 0
	local currentTime = os.clock()
	if currentTime - lastBurnTime < BurnerConfig.COOLDOWN_TIME then
		return
	end

	campfire:SetAttribute("LastBurnTime", currentTime)

	local level = campfire:GetAttribute("CurrentLevel") or 1
	local machineId = campfire:GetAttribute("Id")
	local machineConfig = MachineConfig[machineId] or {}
	local basePollution = machineConfig.ManualPollution or BurnerConfig.BASE_POLLUTION
	local levelMultiplier = machineConfig.ManualLevelMultiplier or BurnerConfig.LEVEL_MULTIPLIER
	local pollutionGenerated = math.floor(basePollution * (levelMultiplier ^ (level - 1)))

	PollutionService.addPollution(player, pollutionGenerated)
	ManualBurnerService.createFloatingText(campfire, "+" .. pollutionGenerated .. " Pollution")

	local VisualEffectsService = require(script.Parent.VisualEffectsService)
	VisualEffectsService.playBurnerBurst(campfire, level)
end

function ManualBurnerService.createFloatingText(campfire, text)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.fromOffset(200, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Parent = campfire

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Parent = billboardGui

	local riseTween = TweenService:Create(
		billboardGui,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = Vector3.new(0, 6, 0) }
	)

	local fadeTween = TweenService:Create(
		textLabel,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)

	riseTween:Play()
	fadeTween:Play()

	fadeTween.Completed:Connect(function()
		billboardGui:Destroy()
	end)
end

return ManualBurnerService
