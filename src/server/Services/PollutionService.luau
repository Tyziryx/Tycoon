local PollutionService = {}

function PollutionService.SetupLeaderstats(player)
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

	return pollution
end

function PollutionService.AddPollution(player, amount)
	if player == nil then
		warn("Player is nil")
		return
	end
	local pollutionValue = player.Data:FindFirstChild("Pollution")

	if pollutionValue then
		pollutionValue.Value = pollutionValue.Value + amount
		-- Update leaderstats
		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Pollution") then
			player.leaderstats.Pollution.Value = pollutionValue.Value
		end
	end
end

function PollutionService.RemovePollution(player, amount)
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

function PollutionService.GetPollution(player)
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

function PollutionService.CanAfford(player, cost)
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
