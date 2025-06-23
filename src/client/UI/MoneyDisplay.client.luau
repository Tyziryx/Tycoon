local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local StringUtils = require(ReplicatedStorage.Shared.Utils.StringUtils)

local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats:WaitForChild("Money")

local moneyDisplay = player.PlayerGui:WaitForChild("MoneyDisplay")
local frame = moneyDisplay:WaitForChild("MoneyBar")
local moneyText = frame:WaitForChild("TextLabel")

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
