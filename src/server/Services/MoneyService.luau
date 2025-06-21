local MoneyService = {}

function MoneyService.SetupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	-- Access money from the Data folder's Money ValueObject
	local moneyValue = player.Data:FindFirstChild("Money")
	if moneyValue then
		money.Value = moneyValue.Value
	else
		money.Value = 0
	end
	money.Parent = leaderstats

	return money
end

function MoneyService.AddMoney(player, amount)
	local moneyValue = player.Data:FindFirstChild("Money")
	if moneyValue then
		moneyValue.Value = moneyValue.Value + amount
		-- Update leaderstats
		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money") then
			player.leaderstats.Money.Value = moneyValue.Value
		end
	end
end

function MoneyService.RemoveMoney(player, amount)
	local moneyValue = player.Data:FindFirstChild("Money")
	if moneyValue and moneyValue.Value >= amount then
		moneyValue.Value = moneyValue.Value - amount
		-- Update leaderstats
		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money") then
			player.leaderstats.Money.Value = moneyValue.Value
		end
		return true
	end
	return false
end

function MoneyService.GetMoney(player)
	local moneyValue = player.Data:FindFirstChild("Money")
	if moneyValue then
		return moneyValue.Value
	end
	return 0
end

function MoneyService.CanAfford(player, cost)
	local moneyValue = player.Data:FindFirstChild("Money")
	if moneyValue then
		return moneyValue.Value >= cost
	end
	return false
end

return MoneyService
