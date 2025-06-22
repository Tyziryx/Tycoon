local MachineService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local TycoonService = require(script.Parent.TycoonService)
local MoneyService = require(script.Parent.MoneyService)
local Machines = ReplicatedStorage:WaitForChild("Machines")

-- local function getMachine(machineId)
function MachineService.getMachine(machineId)
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
function MachineService.unlockMachine(player, machineId)
	local tycoon = TycoonService.getTycoon(player)
	if not tycoon or machineId == nil or player == nil then
		return
	end
	local machineConfig = MachineConfig[machineId]
	local UnlockedZones = player.Data.UnlockedZones
	local zoneId = machineConfig.ZoneRequired
	if not UnlockedZones:GetChildren()[zoneId] then
		return false
	end
	local Machine = MachineService.getMachine(machineId):Clone()
	local Cost = machineConfig.BaseCost

	if not MoneyService.canAfford(player, Cost) then
		return false
	end
	MoneyService.removeMoney(player, Cost) -- Deduct the cost from the player's money

	local RelativeCF = TycoonService.getRelativeCFrame(machineId) -- Get the relative CFrame for the machine

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
