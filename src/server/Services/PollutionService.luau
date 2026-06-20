local PollutionService = {}

function PollutionService.setupLeaderstats(player)
	if player == nil then
		warn("Player is nil")
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local pollution = Instance.new("IntValue")
	pollution.Name = "Pollution"
	-- Access pollution from the Data folder's Pollution ValueObject
	local pollutionValue = player.Data:FindFirstChild("Pollution")
	if pollutionValue then
		pollution.Value = pollutionValue.Value
	else
		pollution.Value = 0
	end
	pollution.Parent = leaderstats

	-- Compteur de pollution TOTALE (à vie) : c'est le score "plus gros pollueur".
	-- Contrairement à "Pollution", il ne redescend jamais (la vente ne l'affecte pas).
	local totalPollution = Instance.new("IntValue")
	totalPollution.Name = "Pollution Totale"
	local statsFolder = player.Data:FindFirstChild("Stats")
	local totalData = statsFolder and statsFolder:FindFirstChild("TotalPollution")
	totalPollution.Value = totalData and totalData.Value or 0
	totalPollution.Parent = leaderstats

	return pollution
end

function PollutionService.addPollution(player, amount)
	if player == nil then
		warn("Player is nil")
		return
	end
	if amount <= 0 then
		return
	end
	local pollutionValue = player.Data:FindFirstChild("Pollution")

	if pollutionValue then
		pollutionValue.Value = pollutionValue.Value + amount
		-- Update leaderstats
		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Pollution") then
			player.leaderstats.Pollution.Value = pollutionValue.Value
		end

		-- Incrémenter la pollution TOTALE (à vie). Elle ne redescend jamais,
		-- même après une vente à la Mafia : c'est le score du classement.
		local statsFolder = player.Data:FindFirstChild("Stats")
		local totalData = statsFolder and statsFolder:FindFirstChild("TotalPollution")
		if totalData then
			totalData.Value = totalData.Value + amount
			if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Pollution Totale") then
				player.leaderstats["Pollution Totale"].Value = totalData.Value
			end
		end

		local runData = statsFolder and statsFolder:FindFirstChild("RunPollution")
		if runData then
			runData.Value = runData.Value + amount
		end
	end
end

function PollutionService.setPollution(player, amount)
	if player == nil then
		warn("Player is nil")
		return
	end
	local pollutionValue = player.Data:FindFirstChild("Pollution")
	if pollutionValue then
		pollutionValue.Value = amount
		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Pollution") then
			player.leaderstats.Pollution.Value = pollutionValue.Value
		end
	end
end

function PollutionService.getRunPollution(player)
	if player == nil then
		warn("Player is nil")
		return 0
	end
	local statsFolder = player.Data:FindFirstChild("Stats")
	local runData = statsFolder and statsFolder:FindFirstChild("RunPollution")
	if runData then
		return runData.Value
	end
	return 0
end

function PollutionService.setRunPollution(player, amount)
	if player == nil then
		warn("Player is nil")
		return
	end
	local statsFolder = player.Data:FindFirstChild("Stats")
	local runData = statsFolder and statsFolder:FindFirstChild("RunPollution")
	if runData then
		runData.Value = amount
	end
end

function PollutionService.removePollution(player, amount)
	if player == nil then
		warn("Player is nil")
		return
	end
	local pollutionValue = player.Data:FindFirstChild("Pollution")
	if pollutionValue and pollutionValue.Value >= amount then
		pollutionValue.Value = pollutionValue.Value - amount
		-- Update leaderstats
		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Pollution") then
			player.leaderstats.Pollution.Value = pollutionValue.Value
		end
		return true
	end
	return false
end

function PollutionService.getPollution(player)
	if player == nil then
		warn("Player is nil")
		return
	end
	local pollutionValue = player.Data:FindFirstChild("Pollution")
	if pollutionValue then
		return pollutionValue.Value
	end
	return 0
end

function PollutionService.canAfford(player, cost)
	if player == nil then
		warn("Player is nil")
		return
	end
	local pollutionValue = player.Data:FindFirstChild("Pollution")
	if pollutionValue then
		return pollutionValue.Value >= cost
	end
	return false
end

return PollutionService
