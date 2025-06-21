local Tycoons = game.Workspace:WaitForChild("Tycoons")

local TyconnService = {}

function TyconnService.Init() end

function TyconnService.AssignTycoon(player)
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("Taken") then
			continue
		end
		tycoon:SetAttribute("Taken", true)
		tycoon:SetAttribute("Player", player.UserId)
		return tycoon
	end
	return nil
end

function TyconnService.GetTycoon(player)
	for _, tycoon in Tycoons:GetChildren() do
		if tycoon:GetAttribute("Player") == player.UserId then
			return tycoon
		end
	end
end

return TyconnService
