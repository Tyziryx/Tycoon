local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local StringUtils = require(ReplicatedStorage.Shared.Utils.StringUtils)

local leaderstats = player:WaitForChild("leaderstats")
local pollution = leaderstats:WaitForChild("Pollution")

local pollutionDisplay = player.PlayerGui:WaitForChild("MoneyDisplay")
local frame = pollutionDisplay:WaitForChild("Bar")
local pollutionText = frame:WaitForChild("TextLabel")

local function updatePollutionText()
	local formattedPollution = StringUtils.formatMoney(pollution.Value)

	formattedPollution = string.gsub(formattedPollution, "%$", "")

	pollutionText.Text = formattedPollution
end

pollution.Changed:Connect(updatePollutionText)

updatePollutionText()
