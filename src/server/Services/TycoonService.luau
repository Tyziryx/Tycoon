local Tycoons = game.Workspace:WaitForChild("Tycoons")
local TycoonService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceholderTycoon = ReplicatedStorage:WaitForChild("Tycoon")
local CollectionService = game:GetService("CollectionService")
function TycoonService.Init()
	for _, Tycoon in CollectionService:GetTagged("Tycoon") do
		if Tycoon:IsDescendantOf(ReplicatedStorage) then
			continue
		end
		Tycoon.Machines:ClearAllChildren()
	end
end

function TycoonService.AssignTycoon(player)
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("Taken") then
			continue
		end
		tycoon:SetAttribute("Taken", true)
		tycoon:SetAttribute("UserId", player.UserId)
		return tycoon
	end
	return nil
end

function TycoonService.GetTycoon(player)
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("UserId") == player.UserId then
			return tycoon
		end
	end
end

function getMachineInTycoonById(machineId)
	for _, Machine in PlaceholderTycoon.Machines:GetChildren() do
		if Machine:GetAttribute("Id") == machineId then
			return Machine
		end
	end
end

function TycoonService.GetRelativeCFrame(machineId)
	local Machines = getMachineInTycoonById(machineId)

	local RelativeCF = PlaceholderTycoon.PrimaryPart.CFrame:toObjectSpace(Machines:GetPivot())
	return RelativeCF
end

return TycoonService
