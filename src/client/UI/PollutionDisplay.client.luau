local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local StringUtils = require(ReplicatedStorage.Shared.Utils.StringUtils)

local leaderstats = player:WaitForChild("leaderstats")
local pollution = leaderstats:WaitForChild("Pollution")

local pollutionDisplay = player.PlayerGui:WaitForChild("ScreenGUI")
local header = pollutionDisplay:WaitForChild("Header")
local pollutionBar = header:WaitForChild("PollutionBar")
local pollutionText = pollutionBar:WaitForChild("TextLabel")

local function updatePollutionText()
	local formattedPollution = StringUtils.formatMoney(pollution.Value)

	formattedPollution = string.gsub(formattedPollution, "%$", "")

	pollutionText.Text = formattedPollution
end

pollution.Changed:Connect(updatePollutionText)

updatePollutionText()
