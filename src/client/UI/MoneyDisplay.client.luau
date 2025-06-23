local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local StringUtils = require(ReplicatedStorage.Shared.Utils.StringUtils)

-- Attendre que les leaderstats soient chargés
local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats:WaitForChild("Money")

-- Récupérer l'interface existante
-- Supposons que l'interface est déjà dans PlayerGui et s'appelle "MoneyDisplay"
local moneyDisplay = player.PlayerGui:WaitForChild("MoneyDisplay")
local frame = moneyDisplay:WaitForChild("Frame")
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

-- Mettre à jour l'affichage quand l'argent change
money.Changed:Connect(updateMoneyText)

-- Initialiser l'affichage
updateMoneyText()
