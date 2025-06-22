local MachineService = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)
local TycoonService = require(script.Parent.TycoonService)
local MoneyService = require(script.Parent.MoneyService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Machines = ReplicatedStorage:WaitForChild("Machines")

-- local function getMachine(machineId)
function MachineService.GetMachine(machineId)
	if machineId == nil then
		warn("MachineId is nil")
		return nil
	end
	for _, Machine in Machines:GetChildren() do
		if Machine:GetAttribute("Id") == machineId then
			return Machine
		end
	end
	return nil
end
function MachineService.UnlockMachine(player, machineId)
	local tycoon = TycoonService.GetTycoon(player)
	if not tycoon or machineId == nil or player == nil then
		return
	end
	local machineConfig = MachineConfig[machineId]
	local UnlockedZones = player.Data.UnlockedZones
	local zoneId = machineConfig.ZoneRequired
	local zoneConfig = ZoneConfig[zoneId]
	if not UnlockedZones:GetChildren()[zoneId] then
		return false
	end
	local Machine = MachineService.GetMachine(machineId):Clone()
	local Cost = machineConfig.BaseCost

	if not MoneyService.CanAfford(player, Cost) then
		return false
	end
	MoneyService.RemoveMoney(player, Cost) -- Deduct the cost from the player's money

	local RelativeCF = TycoonService.GetRelativeCFrame(machineId) -- Get the relative CFrame for the machine

	local WorldCF = tycoon.PrimaryPart.CFrame:toWorldSpace(RelativeCF)

	Machine:PivotTo(WorldCF)
	Machine.Parent = tycoon.Machines

	-- Ajout de la machine au dossier des machines du joueur
	local machine = Instance.new("IntValue")
	machine.Name = Machine.Name
	machine.Value = machineId
	machine.Parent = player.Data.OwnedMachines

	return true
end

return MachineService
