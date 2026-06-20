local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)

local ZoneService = {}

local zoneReachedRemote = nil
local runPollutionConnections = {}

local function ensureZoneReachedRemote()
	if zoneReachedRemote then
		return zoneReachedRemote
	end

	zoneReachedRemote = ReplicatedStorage:FindFirstChild("ZoneReached")
	if not zoneReachedRemote then
		zoneReachedRemote = Instance.new("RemoteEvent")
		zoneReachedRemote.Name = "ZoneReached"
		zoneReachedRemote.Parent = ReplicatedStorage
	end

	return zoneReachedRemote
end

local function getStatsFolder(player)
	return player.Data and player.Data:FindFirstChild("Stats")
end

local function getRunPollutionValue(player)
	local statsFolder = getStatsFolder(player)
	return statsFolder and statsFolder:FindFirstChild("RunPollution")
end

local function ensureCurrentZoneValue(player)
	local currentZone = player.Data:FindFirstChild("CurrentZone")
	if not currentZone then
		currentZone = Instance.new("NumberValue")
		currentZone.Name = "CurrentZone"
		currentZone.Value = 1
		currentZone.Parent = player.Data
	end
	return currentZone
end

local function ensureUnlockedZonesFolder(player)
	local unlockedZones = player.Data:FindFirstChild("UnlockedZones")
	if not unlockedZones then
		unlockedZones = Instance.new("Folder")
		unlockedZones.Name = "UnlockedZones"
		unlockedZones.Parent = player.Data
	end
	return unlockedZones
end

local function setUnlockedZonesThrough(player, zoneId)
	local unlockedZones = ensureUnlockedZonesFolder(player)
	unlockedZones:ClearAllChildren()

	for id = 1, zoneId do
		local unlockedZone = Instance.new("BoolValue")
		unlockedZone.Name = tostring(id)
		unlockedZone.Value = true
		unlockedZone.Parent = unlockedZones
	end
end

function ZoneService.getZoneForPollution(runPollution)
	local currentZoneId = 1

	for zoneId, zoneData in ipairs(ZoneConfig) do
		if runPollution >= zoneData.PollutionThreshold then
			currentZoneId = zoneId
		end
	end

	return currentZoneId
end

function ZoneService.getCurrentZone(player)
	local currentZone = player.Data and player.Data:FindFirstChild("CurrentZone")
	return currentZone and currentZone.Value or 1
end

function ZoneService.setCurrentZone(player, zoneId, shouldFire)
	local currentZone = ensureCurrentZoneValue(player)
	local previousZone = currentZone.Value
	currentZone.Value = zoneId
	setUnlockedZonesThrough(player, zoneId)

	if shouldFire and zoneId ~= previousZone then
		ensureZoneReachedRemote():FireClient(player, zoneId)
	end
end

function ZoneService.syncPlayerZone(player, shouldFire)
	local runPollution = getRunPollutionValue(player)
	if not runPollution then
		return
	end

	local currentZone = ZoneService.getCurrentZone(player)
	local nextZone = ZoneService.getZoneForPollution(runPollution.Value)
	if nextZone ~= currentZone then
		ZoneService.setCurrentZone(player, nextZone, shouldFire and nextZone > currentZone)
	else
		setUnlockedZonesThrough(player, currentZone)
	end
end

function ZoneService.resetPlayer(player)
	ZoneService.setCurrentZone(player, 1, false)
end

function ZoneService.setupPlayer(player)
	ensureZoneReachedRemote()
	ensureCurrentZoneValue(player)
	setUnlockedZonesThrough(player, ZoneService.getCurrentZone(player))
	ZoneService.syncPlayerZone(player, false)

	if runPollutionConnections[player] then
		runPollutionConnections[player]:Disconnect()
	end

	local runPollution = getRunPollutionValue(player)
	if runPollution then
		runPollutionConnections[player] = runPollution.Changed:Connect(function()
			ZoneService.syncPlayerZone(player, true)
		end)
	end
end

function ZoneService.init()
	ensureZoneReachedRemote()
end

return ZoneService
