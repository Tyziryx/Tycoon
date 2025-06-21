local MachineService = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local TycoonService = require(script.Parent.TycoonService)
local MoneyService = require(script.Parent.MoneyService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Machines = ReplicatedStorage:WaitForChild("Machines")

-- local function getMachine(machineId)
function MachineService.GetMachine(machineId)
	for _, Machine in Machines:GetChildren() do
		if Machine:GetAttribute("Id") == machineId then
			return Machine
		end
	end
end
function MachineService.UnlockMachine(player, machineId)
	local tycoon = TycoonService.GetTycoon(player)
	if not tycoon then
		return
	end
	local Machine = MachineService.GetMachine(machineId):Clone()
	local Cost = Machine:GetAttribute("Cost")

	if MoneyService.GetMoney(player) < Cost then
		return false
	end
	MoneyService.RemoveMoney(player, Cost) -- Deduct the cost from the player's money

	local RelativeCF = TycoonService.GetRelativeCFrame(machineId) -- Get the relative CFrame for the machine

	local WorldCF = tycoon.PrimaryPart.CFrame:toWorldSpace(RelativeCF)

	Machine:PivotTo(WorldCF)
	Machine.Parent = tycoon.Machines

	return true
end

return MachineService
