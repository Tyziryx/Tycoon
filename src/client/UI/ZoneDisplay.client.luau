local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local dataFolder = player:WaitForChild("Data")
local statsFolder = dataFolder:WaitForChild("Stats")
local currentZone = dataFolder:WaitForChild("CurrentZone")
local runPollution = statsFolder:WaitForChild("RunPollution")
local zoneReachedRemote = ReplicatedStorage:WaitForChild("ZoneReached")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZoneProgressGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "ZoneProgress"
container.AnchorPoint = Vector2.new(0.5, 0)
container.Position = UDim2.new(0.5, 0, 0, 18)
container.Size = UDim2.fromOffset(320, 48)
container.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
container.BackgroundTransparency = 0.18
container.BorderSizePixel = 0
container.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(360, 48)
sizeConstraint.MinSize = Vector2.new(240, 48)
sizeConstraint.Parent = container

local zoneLabel = Instance.new("TextLabel")
zoneLabel.Name = "ZoneLabel"
zoneLabel.Position = UDim2.fromOffset(12, 4)
zoneLabel.Size = UDim2.new(1, -24, 0, 18)
zoneLabel.BackgroundTransparency = 1
zoneLabel.Font = Enum.Font.GothamBold
zoneLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
zoneLabel.TextSize = 14
zoneLabel.TextXAlignment = Enum.TextXAlignment.Left
zoneLabel.Parent = container

local progressBackground = Instance.new("Frame")
progressBackground.Name = "ProgressBackground"
progressBackground.Position = UDim2.fromOffset(12, 27)
progressBackground.Size = UDim2.new(1, -24, 0, 10)
progressBackground.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
progressBackground.BorderSizePixel = 0
progressBackground.Parent = container

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = Color3.fromRGB(198, 121, 48)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBackground

local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Position = UDim2.fromOffset(12, 36)
progressText.Size = UDim2.new(1, -24, 0, 10)
progressText.BackgroundTransparency = 1
progressText.Font = Enum.Font.Gotham
progressText.TextColor3 = Color3.fromRGB(225, 225, 225)
progressText.TextSize = 10
progressText.TextXAlignment = Enum.TextXAlignment.Right
progressText.Parent = container

local banner = Instance.new("TextLabel")
banner.Name = "ZoneBanner"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.34)
banner.Size = UDim2.fromOffset(360, 72)
banner.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
banner.BackgroundTransparency = 1
banner.BorderSizePixel = 0
banner.Font = Enum.Font.GothamBlack
banner.TextColor3 = Color3.fromRGB(255, 229, 168)
banner.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
banner.TextStrokeTransparency = 1
banner.TextTransparency = 1
banner.TextSize = 34
banner.Parent = screenGui

local function formatNumber(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(math.floor(amount))
end

local function updateProgress()
	local zoneId = currentZone.Value
	local zoneData = ZoneConfig[zoneId]
	local nextZoneData = ZoneConfig[zoneId + 1]

	zoneLabel.Text = "PALIER " .. zoneId .. " - " .. (zoneData and zoneData.Name or "")

	if not nextZoneData then
		progressFill.Size = UDim2.fromScale(1, 1)
		progressText.Text = "MAX"
		return
	end

	local startThreshold = zoneData and zoneData.PollutionThreshold or 0
	local nextThreshold = nextZoneData.PollutionThreshold
	local span = math.max(nextThreshold - startThreshold, 1)
	local progress = math.clamp((runPollution.Value - startThreshold) / span, 0, 1)

	progressFill:TweenSize(
		UDim2.fromScale(progress, 1),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.2,
		true
	)
	progressText.Text = formatNumber(runPollution.Value) .. " / " .. formatNumber(nextThreshold)
end

local function showZoneBanner(zoneId)
	banner.Text = "PALIER " .. zoneId
	banner.Size = UDim2.fromOffset(320, 64)

	TweenService:Create(banner, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.18,
		TextTransparency = 0,
		TextStrokeTransparency = 0.35,
		Size = UDim2.fromOffset(380, 78),
	}):Play()

	task.delay(1.4, function()
		TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)
end

currentZone.Changed:Connect(updateProgress)
runPollution.Changed:Connect(updateProgress)
zoneReachedRemote.OnClientEvent:Connect(function(zoneId)
	updateProgress()
	showZoneBanner(zoneId)
end)

updateProgress()
