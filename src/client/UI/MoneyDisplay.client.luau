local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local StringUtils = require(ReplicatedStorage.Shared.Utils.StringUtils)

local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats:WaitForChild("Money")

local moneyDisplay = player.PlayerGui:WaitForChild("ScreenGUI")
local header = moneyDisplay:WaitForChild("Header")
local moneyBar = header:WaitForChild("MoneyBar")
local moneyText = moneyBar:WaitForChild("TextLabel")
local backgroundImage = moneyBar:WaitForChild("Anim")

-- Fonction pour mettre à jour le texte avec formatage
local function updateMoneyText()
	-- Récupérer le texte formaté
	local formattedMoney = StringUtils.formatMoney(money.Value)

	-- Supprimer le symbole $ en le remplaçant par une chaîne vide
	formattedMoney = string.gsub(formattedMoney, "%$", "")

	-- Mettre à jour le texte
	moneyText.Text = formattedMoney
end
money.Changed:Connect(updateMoneyText)

updateMoneyText()

local function rotateImage()
	local rotationSpeed = 0.5

	while true do
		backgroundImage.Rotation = (backgroundImage.Rotation + rotationSpeed) % 360

		task.wait()
	end
end

task.spawn(rotateImage)
