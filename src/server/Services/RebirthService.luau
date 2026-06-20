local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MoneyService = require(script.Parent.MoneyService)
local PollutionService = require(script.Parent.PollutionService)
local PurchasableService = require(script.Parent.PurchasableService)
local ZoneService = require(script.Parent.ZoneService)

local RebirthService = {}

local requestRemote = nil
local completedRemote = nil
local deniedRemote = nil
local connectedPrompts = {}

local function ensureRemoteEvent(name)
	local remoteEvent = ReplicatedStorage:FindFirstChild(name)
	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = name
		remoteEvent.Parent = ReplicatedStorage
	end
	return remoteEvent
end

local function ensureRemotes()
	requestRemote = requestRemote or ensureRemoteEvent("RequestRebirth")
	completedRemote = completedRemote or ensureRemoteEvent("RebirthCompleted")
	deniedRemote = deniedRemote or ensureRemoteEvent("RebirthDenied")
end

local function getRebirthConfig()
	return GameConfig.REBIRTH or {
		MIN_RUN_POLLUTION = 1000,
		ASH_BASE = 1,
		ASH_GROWTH = 4,
	}
end

local function getCendresValue(player)
	return player.Data and player.Data:FindFirstChild("Cendres")
end

local function getTycoonForInstance(instance)
	local tycoons = Workspace:FindFirstChild("Tycoons")
	if not tycoons then
		return nil
	end

	for _, tycoon in tycoons:GetChildren() do
		if instance:IsDescendantOf(tycoon) then
			return tycoon
		end
	end

	return nil
end

local function getPromptFromInstance(instance)
	if instance:IsA("ProximityPrompt") then
		return instance
	end

	local prompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		return prompt
	end

	if instance:IsA("BasePart") then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "RebirthPrompt"
		prompt.ActionText = "Rebirth"
		prompt.ObjectText = "Cendres"
		prompt.HoldDuration = 1
		prompt.MaxActivationDistance = 12
		prompt.Parent = instance
		return prompt
	end

	return nil
end

local function connectPrompt(prompt)
	if connectedPrompts[prompt] then
		return
	end

	connectedPrompts[prompt] = prompt.Triggered:Connect(function(player)
		local tycoon = getTycoonForInstance(prompt)
		if tycoon and tycoon:GetAttribute("UserId") ~= player.UserId then
			return
		end

		RebirthService.tryRebirth(player)
	end)
end

local function setupPromptInstance(instance)
	local prompt = getPromptFromInstance(instance)
	if prompt then
		connectPrompt(prompt)
	end
end

local function scanWorkspacePrompts()
	local tycoons = Workspace:FindFirstChild("Tycoons")
	if not tycoons then
		return
	end

	for _, instance in tycoons:GetDescendants() do
		if instance.Name == "RebirthPrompt" or instance:GetAttribute("IsRebirthPrompt") then
			setupPromptInstance(instance)
		end
	end
end

function RebirthService.setupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cendres = Instance.new("IntValue")
	cendres.Name = "Cendres"
	local dataValue = getCendresValue(player)
	cendres.Value = dataValue and dataValue.Value or 0
	cendres.Parent = leaderstats

	return cendres
end

function RebirthService.getCendres(player)
	local cendres = getCendresValue(player)
	return cendres and cendres.Value or 0
end

function RebirthService.addCendres(player, amount)
	local cendres = getCendresValue(player)
	if not cendres then
		return
	end

	cendres.Value = cendres.Value + amount
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cendres") then
		player.leaderstats.Cendres.Value = cendres.Value
	end
end

function RebirthService.calculateCendres(player)
	local config = getRebirthConfig()
	local zoneReached = ZoneService.getCurrentZone(player)
	return math.floor(config.ASH_BASE * (config.ASH_GROWTH ^ (zoneReached - 1)))
end

function RebirthService.canRebirth(player)
	local config = getRebirthConfig()
	local runPollution = PollutionService.getRunPollution(player)
	if runPollution < config.MIN_RUN_POLLUTION then
		return false, "Pollution du run insuffisante"
	end

	return true, "Rebirth disponible"
end

function RebirthService.tryRebirth(player)
	ensureRemotes()

	local canRebirth, reason = RebirthService.canRebirth(player)
	if not canRebirth then
		deniedRemote:FireClient(player, reason, getRebirthConfig().MIN_RUN_POLLUTION)
		return false, reason
	end

	local cendresGain = RebirthService.calculateCendres(player)
	RebirthService.addCendres(player, cendresGain)

	MoneyService.setMoney(player, GameConfig.STARTING_MONEY)
	PollutionService.setPollution(player, 0)
	PollutionService.setRunPollution(player, 0)
	ZoneService.resetPlayer(player)
	PurchasableService.resetPlayerMachines(player)

	local ButtonService = require(script.Parent.ButtonService)
	ButtonService.resetMachineButtonsForPlayer(player)

	completedRemote:FireClient(player, cendresGain, RebirthService.getCendres(player))
	return true, "Rebirth effectué", cendresGain
end

function RebirthService.init()
	ensureRemotes()

	requestRemote.OnServerEvent:Connect(function(player)
		RebirthService.tryRebirth(player)
	end)

	for _, tagName in { "RebirthPrompt", "RebirthButton" } do
		for _, instance in CollectionService:GetTagged(tagName) do
			setupPromptInstance(instance)
		end

		CollectionService:GetInstanceAddedSignal(tagName):Connect(setupPromptInstance)
	end

	scanWorkspacePrompts()
end

return RebirthService
