local Tycoons = game.Workspace:WaitForChild("Tycoons")
local TycoonService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceholderTycoon = ReplicatedStorage:WaitForChild("Tycoon")
local CollectionService = game:GetService("CollectionService")
local SellService = require(script.Parent.SellService)

function TycoonService.init()
	for _, Tycoon in CollectionService:GetTagged("Tycoon") do
		if Tycoon:IsDescendantOf(ReplicatedStorage) then
			continue
		end
		Tycoon.Machines:ClearAllChildren()
	end
end

function TycoonService.assignTycoon(player)
	if player == nil then
		warn("Player is nil")
		return nil
	end
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("Taken") then
			continue
		end
		tycoon:SetAttribute("Taken", true)
		tycoon:SetAttribute("UserId", player.UserId)

		SellService.init(tycoon)
		return tycoon
	end
	return nil
end

function TycoonService.getTycoon(player)
	if player == nil then
		warn("Player is nil")
		return nil
	end
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("UserId") == player.UserId then
			return tycoon
		end
	end
	return nil
end

function TycoonService.getMachineInTycoonById(machineId)
	if machineId == nil then
		warn("MachineId is nil")
		return nil
	end
	for _, Machine in PlaceholderTycoon.Machines:GetChildren() do
		if Machine:GetAttribute("Id") == machineId then
			return Machine
		end
	end
	warn("Machine not found")
	return nil
end

function TycoonService.getRelativeCFrame(machineId)
	if machineId == nil then
		warn("MachineId is nil")
		return nil
	end
	local Machines = TycoonService.getMachineInTycoonById(machineId)

	local RelativeCF = PlaceholderTycoon.PrimaryPart.CFrame:toObjectSpace(Machines:GetPivot())
	return RelativeCF
end

return TycoonService
