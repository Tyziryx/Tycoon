local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local RandomMachineConfig = require(ReplicatedStorage.Shared.Config.RandomMachineConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getInventoryRemote = ReplicatedStorage:WaitForChild("GetMachineInventoryRemote")
local rollRemote = ReplicatedStorage:WaitForChild("RollMachineRemote")
local placeRemote = ReplicatedStorage:WaitForChild("PlaceMachineRemote")
local unplaceRemote = ReplicatedStorage:WaitForChild("UnplaceMachineRemote")
local sellRemote = ReplicatedStorage:WaitForChild("SellMachineRemote")
local recycleRemote = ReplicatedStorage:WaitForChild("RecycleMachineRemote")
local fuseRemote = ReplicatedStorage:WaitForChild("FuseMachineRemote")
local toggleLockRemote = ReplicatedStorage:WaitForChild("ToggleMachineLockRemote")
local updatedRemote = ReplicatedStorage:WaitForChild("MachineInventoryUpdated")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MachineInventoryGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 70
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleMachineInventory"
toggleButton.AnchorPoint = Vector2.new(1, 1)
toggleButton.Position = UDim2.new(1, -18, 1, -66)
toggleButton.Size = UDim2.fromOffset(128, 42)
toggleButton.BackgroundColor3 = Color3.fromRGB(28, 35, 34)
toggleButton.BorderSizePixel = 0
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "MACHINES"
toggleButton.TextColor3 = Color3.fromRGB(198, 255, 224)
toggleButton.TextSize = 15
toggleButton.ZIndex = 10
toggleButton.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "MachinePanel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -18, 1, -116)
panel.Size = UDim2.fromOffset(430, 500)
panel.BackgroundColor3 = Color3.fromRGB(17, 22, 21)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 20
panel.Parent = screenGui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -32, 0, 26)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "INVENTAIRE MACHINES"
title.TextColor3 = Color3.fromRGB(198, 255, 224)
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 21
title.Parent = panel

local resourceLabel = Instance.new("TextLabel")
resourceLabel.Name = "Resources"
resourceLabel.Position = UDim2.fromOffset(16, 40)
resourceLabel.Size = UDim2.new(1, -32, 0, 20)
resourceLabel.BackgroundTransparency = 1
resourceLabel.Font = Enum.Font.GothamBold
resourceLabel.Text = ""
resourceLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
resourceLabel.TextSize = 13
resourceLabel.TextXAlignment = Enum.TextXAlignment.Left
resourceLabel.ZIndex = 21
resourceLabel.Parent = panel

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.Position = UDim2.fromOffset(16, 62)
messageLabel.Size = UDim2.new(1, -32, 0, 20)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.Gotham
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(215, 215, 215)
messageLabel.TextSize = 12
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.ZIndex = 21
messageLabel.Parent = panel

local function makeButton(name, text, position, size, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(42, 67, 60)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235, 255, 245)
	button.TextSize = 12
	button.TextWrapped = true
	button.ZIndex = 23
	button.Parent = parent
	return button
end

local function makeLabel(name, position, size, parent)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = ""
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.ZIndex = 23
	label.Parent = parent
	return label
end

local rollButton = makeButton("Roll", "", UDim2.fromOffset(300, 38), UDim2.fromOffset(112, 34), panel)

local controls = Instance.new("Frame")
controls.Name = "SelectedControls"
controls.Position = UDim2.fromOffset(12, 88)
controls.Size = UDim2.new(1, -24, 0, 96)
controls.BackgroundColor3 = Color3.fromRGB(28, 34, 32)
controls.BorderSizePixel = 0
controls.ZIndex = 22
controls.Parent = panel

local selectedLabel = makeLabel("Selected", UDim2.fromOffset(12, 8), UDim2.new(1, -92, 0, 38), controls)
local gridLabel = makeLabel("Grid", UDim2.fromOffset(12, 46), UDim2.new(1, -24, 0, 18), controls)

local placeButton = makeButton("Place", "PLACER", UDim2.fromOffset(12, 66), UDim2.fromOffset(70, 24), controls)
local unplaceButton = makeButton("Unplace", "RANGER", UDim2.fromOffset(88, 66), UDim2.fromOffset(70, 24), controls)
local sellButton = makeButton("Sell", "VENDRE", UDim2.fromOffset(164, 66), UDim2.fromOffset(68, 24), controls)
local recycleButton = makeButton("Recycle", "RECYCLE", UDim2.fromOffset(238, 66), UDim2.fromOffset(70, 24), controls)
local fuseButton = makeButton("Fuse", "FUSION", UDim2.fromOffset(314, 66), UDim2.fromOffset(74, 24), controls)
local lockButton = makeButton("Lock", "LOCK", UDim2.new(1, -78, 0, 10), UDim2.fromOffset(66, 24), controls)

local list = Instance.new("ScrollingFrame")
list.Name = "MachineList"
list.Position = UDim2.fromOffset(12, 194)
list.Size = UDim2.new(1, -24, 1, -206)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.fromOffset(0, 0)
list.ScrollBarThickness = 6
list.ZIndex = 21
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
end)

local rollOverlay = Instance.new("Frame")
rollOverlay.Name = "RollOverlay"
rollOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
rollOverlay.Position = UDim2.fromScale(0.5, 0.45)
rollOverlay.Size = UDim2.fromOffset(680, 210)
rollOverlay.BackgroundColor3 = Color3.fromRGB(13, 16, 15)
rollOverlay.BackgroundTransparency = 0.04
rollOverlay.BorderSizePixel = 0
rollOverlay.Visible = false
rollOverlay.ZIndex = 80
rollOverlay.Parent = screenGui

local rollerTitle = Instance.new("TextLabel")
rollerTitle.Name = "RollTitle"
rollerTitle.Position = UDim2.fromOffset(20, 12)
rollerTitle.Size = UDim2.new(1, -40, 0, 26)
rollerTitle.BackgroundTransparency = 1
rollerTitle.Font = Enum.Font.GothamBlack
rollerTitle.Text = "CONTENEUR MACHINE"
rollerTitle.TextColor3 = Color3.fromRGB(235, 255, 245)
rollerTitle.TextSize = 18
rollerTitle.ZIndex = 81
rollerTitle.Parent = rollOverlay

local rollerWindow = Instance.new("Frame")
rollerWindow.Name = "RollWindow"
rollerWindow.Position = UDim2.fromOffset(20, 54)
rollerWindow.Size = UDim2.new(1, -40, 0, 118)
rollerWindow.BackgroundColor3 = Color3.fromRGB(22, 28, 26)
rollerWindow.BorderSizePixel = 0
rollerWindow.ClipsDescendants = true
rollerWindow.ZIndex = 81
rollerWindow.Parent = rollOverlay

local rollerStrip = Instance.new("Frame")
rollerStrip.Name = "RollStrip"
rollerStrip.Position = UDim2.fromOffset(0, 0)
rollerStrip.Size = UDim2.fromOffset(4000, 118)
rollerStrip.BackgroundTransparency = 1
rollerStrip.ZIndex = 82
rollerStrip.Parent = rollerWindow

local centerMarker = Instance.new("Frame")
centerMarker.Name = "CenterMarker"
centerMarker.AnchorPoint = Vector2.new(0.5, 0)
centerMarker.Position = UDim2.fromScale(0.5, 0)
centerMarker.Size = UDim2.fromOffset(4, 118)
centerMarker.BackgroundColor3 = Color3.fromRGB(255, 235, 120)
centerMarker.BorderSizePixel = 0
centerMarker.ZIndex = 86
centerMarker.Parent = rollerWindow

local rollResultLabel = Instance.new("TextLabel")
rollResultLabel.Name = "RollResult"
rollResultLabel.Position = UDim2.fromOffset(20, 178)
rollResultLabel.Size = UDim2.new(1, -40, 0, 22)
rollResultLabel.BackgroundTransparency = 1
rollResultLabel.Font = Enum.Font.GothamBold
rollResultLabel.Text = ""
rollResultLabel.TextColor3 = Color3.fromRGB(235, 255, 245)
rollResultLabel.TextSize = 14
rollResultLabel.ZIndex = 81
rollResultLabel.Parent = rollOverlay

local placementHud = Instance.new("Frame")
placementHud.Name = "PlacementHud"
placementHud.AnchorPoint = Vector2.new(0.5, 0)
placementHud.Position = UDim2.new(0.5, 0, 0, 20)
placementHud.Size = UDim2.fromOffset(520, 58)
placementHud.BackgroundColor3 = Color3.fromRGB(14, 18, 17)
placementHud.BackgroundTransparency = 0.08
placementHud.BorderSizePixel = 0
placementHud.Visible = false
placementHud.ZIndex = 70
placementHud.Parent = screenGui

local placementLabel = Instance.new("TextLabel")
placementLabel.Name = "PlacementLabel"
placementLabel.Position = UDim2.fromOffset(14, 8)
placementLabel.Size = UDim2.new(1, -28, 0, 42)
placementLabel.BackgroundTransparency = 1
placementLabel.Font = Enum.Font.GothamBold
placementLabel.Text = ""
placementLabel.TextColor3 = Color3.fromRGB(235, 255, 245)
placementLabel.TextSize = 14
placementLabel.TextWrapped = true
placementLabel.ZIndex = 71
placementLabel.Parent = placementHud

local state = nil
local selectedInstanceId = nil
local busy = false
local placementMode = false
local placementRotation = 0
local placementPreview = nil
local placementConnection = nil
local inputConnection = nil
local currentPlacement = nil

local function formatNumber(amount)
	if amount >= 1000000000000 then
		return string.format("%.1fT", amount / 1000000000000)
	elseif amount >= 1000000000 then
		return string.format("%.1fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(math.floor(amount))
end

local function findSelectedInstance()
	if not state then
		return nil
	end

	for _, machine in ipairs(state.Instances) do
		if machine.InstanceId == selectedInstanceId then
			return machine
		end
	end

	return nil
end

local function findInstance(instanceId)
	if not state then
		return nil
	end

	for _, machine in ipairs(state.Instances) do
		if machine.InstanceId == instanceId then
			return machine
		end
	end

	return nil
end

local function getPlayerTycoon()
	local tycoons = Workspace:FindFirstChild("Tycoons")
	if not tycoons then
		return nil
	end

	for _, tycoon in tycoons:GetChildren() do
		if tycoon:GetAttribute("UserId") == player.UserId then
			return tycoon
		end
	end

	return nil
end

local function clearRows()
	for _, child in list:GetChildren() do
		if child ~= layout then
			child:Destroy()
		end
	end
end

local function selectMachine(machine)
	selectedInstanceId = machine and machine.InstanceId or nil
	if machine then
		placementRotation = machine.Rotation or 0
	end
end

local renderState

local function callRemote(remote, ...)
	if busy then
		return nil
	end

	busy = true
	messageLabel.Text = ""
	local result = remote:InvokeServer(...)
	if result then
		messageLabel.Text = result.Message or ""
		if result.State then
			renderState(result.State)
		end
	end
	busy = false
	return result
end

local function getPlacementConfig()
	local placement = state and state.Placement
	return placement or RandomMachineConfig.Placement
end

local function getMachineRelativeCFrame(machine, plotX, plotZ, rotation)
	local placement = getPlacementConfig()
	local footprintX = machine.FootprintX or 1
	local footprintZ = machine.FootprintZ or 1
	local x = placement.OriginX + ((plotX + ((footprintX - 1) * 0.5)) * placement.CellSize)
	local z = placement.OriginZ - ((plotZ + ((footprintZ - 1) * 0.5)) * placement.CellSize)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rotation), 0)
end

local function clampGrid(machine, plotX, plotZ)
	local placement = getPlacementConfig()
	local maxX = math.max(0, placement.MaxColumns - (machine.FootprintX or 1))
	local maxZ = math.max(0, placement.MaxRows - (machine.FootprintZ or 1))
	return math.clamp(plotX, 0, maxX), math.clamp(plotZ, 0, maxZ)
end

local function regionsOverlap(aX, aZ, aWidth, aDepth, bX, bZ, bWidth, bDepth)
	return aX < bX + bWidth and bX < aX + aWidth and aZ < bZ + bDepth and bZ < aZ + aDepth
end

local function isClientOccupied(machine, plotX, plotZ)
	if not state then
		return false
	end

	for _, other in ipairs(state.Instances) do
		if other.Placed and other.InstanceId ~= machine.InstanceId then
			if regionsOverlap(
				plotX,
				plotZ,
				machine.FootprintX or 1,
				machine.FootprintZ or 1,
				other.PlotX,
				other.PlotZ,
				other.FootprintX or 1,
				other.FootprintZ or 1
			) then
				return true
			end
		end
	end

	return false
end

local function getMouseGrid(machine, tycoon)
	local camera = Workspace.CurrentCamera
	local primaryPart = tycoon and tycoon.PrimaryPart
	if not camera or not primaryPart then
		return nil
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	if math.abs(ray.Direction.Y) < 0.001 then
		return nil
	end

	local distance = (primaryPart.Position.Y - ray.Origin.Y) / ray.Direction.Y
	if distance < 0 then
		return nil
	end

	local worldPoint = ray.Origin + (ray.Direction * distance)
	local localPoint = primaryPart.CFrame:PointToObjectSpace(worldPoint)
	local placement = getPlacementConfig()
	local plotX = math.floor((localPoint.X - placement.OriginX + (placement.CellSize * 0.5)) / placement.CellSize)
	local plotZ = math.floor((placement.OriginZ - localPoint.Z + (placement.CellSize * 0.5)) / placement.CellSize)
	return clampGrid(machine, plotX, plotZ)
end

local function destroyPlacementPreview()
	if placementPreview then
		placementPreview:Destroy()
		placementPreview = nil
	end
end

local function createPlacementPreview(machine)
	destroyPlacementPreview()

	local placement = getPlacementConfig()
	local model = Instance.new("Model")
	model.Name = "PlacementPreview"

	local plate = Instance.new("Part")
	plate.Name = "Footprint"
	plate.Size = Vector3.new(
		((machine.FootprintX or 1) * placement.CellSize) - 0.35,
		0.35,
		((machine.FootprintZ or 1) * placement.CellSize) - 0.35
	)
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanTouch = false
	plate.CanQuery = false
	plate.Material = Enum.Material.Neon
	plate.Transparency = 0.45
	plate.Parent = model
	model.PrimaryPart = plate

	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "PreviewLabel"
	labelGui.Size = UDim2.fromOffset(220, 48)
	labelGui.StudsOffset = Vector3.new(0, 2.6, 0)
	labelGui.AlwaysOnTop = true
	labelGui.Parent = plate

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(12, 14, 13)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = machine.MachineName
	label.TextColor3 = Color3.fromRGB(235, 255, 245)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = labelGui

	model.Parent = Workspace
	placementPreview = model
end

local function setPreviewValidity(isValid)
	if not placementPreview or not placementPreview.PrimaryPart then
		return
	end

	placementPreview.PrimaryPart.Color = isValid and Color3.fromRGB(80, 240, 120) or Color3.fromRGB(240, 75, 75)
end

local function updatePlacementPreview()
	local machine = findSelectedInstance()
	local tycoon = getPlayerTycoon()
	if not placementMode or not machine or not tycoon or not placementPreview then
		currentPlacement = nil
		return
	end

	local plotX, plotZ = getMouseGrid(machine, tycoon)
	if not plotX or not plotZ then
		setPreviewValidity(false)
		currentPlacement = nil
		return
	end

	local isOccupied = isClientOccupied(machine, plotX, plotZ)
	local relativeCF = getMachineRelativeCFrame(machine, plotX, plotZ, placementRotation)
	local worldCF = tycoon.PrimaryPart.CFrame:ToWorldSpace(relativeCF) * CFrame.new(0, 0.25, 0)
	placementPreview:PivotTo(worldCF)
	setPreviewValidity(not isOccupied)
	currentPlacement = {
		PlotX = plotX,
		PlotZ = plotZ,
		Rotation = placementRotation,
		IsValid = not isOccupied,
	}
	placementLabel.Text = machine.MachineName
		.. " | clic gauche: placer | clic droit/R: rotation "
		.. placementRotation
		.. "° | Esc: annuler"
end

local function endPlacementMode()
	placementMode = false
	placementHud.Visible = false
	currentPlacement = nil
	destroyPlacementPreview()

	if placementConnection then
		placementConnection:Disconnect()
		placementConnection = nil
	end
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
end

local function submitCurrentPlacement()
	if not currentPlacement or not currentPlacement.IsValid or not selectedInstanceId or busy then
		return
	end

	busy = true
	local result = placeRemote:InvokeServer(
		selectedInstanceId,
		currentPlacement.PlotX,
		currentPlacement.PlotZ,
		currentPlacement.Rotation
	)
	if result then
		messageLabel.Text = result.Message or ""
		if result.State then
			renderState(result.State)
		end
		if result.Success then
			endPlacementMode()
			panel.Visible = true
		end
	end
	busy = false
end

local function beginPlacementMode(machine)
	if not machine then
		return
	end

	local tycoon = getPlayerTycoon()
	if not tycoon or not tycoon.PrimaryPart then
		messageLabel.Text = "Claim un terrain avant de placer."
		return
	end

	endPlacementMode()
	selectMachine(machine)
	placementMode = true
	panel.Visible = false
	placementHud.Visible = true
	placementRotation = machine.Rotation or 0
	createPlacementPreview(machine)
	updatePlacementPreview()

	placementConnection = RunService.RenderStepped:Connect(updatePlacementPreview)
	inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			submitCurrentPlacement()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.R then
			placementRotation = (placementRotation + 90) % 360
			updatePlacementPreview()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			endPlacementMode()
			panel.Visible = true
		end
	end)
end

local function createRollCard(parent, index, machine)
	local cardWidth = 126
	local gap = 8
	local card = Instance.new("Frame")
	card.Name = "RollCard_" .. index
	card.Position = UDim2.fromOffset((index - 1) * (cardWidth + gap), 8)
	card.Size = UDim2.fromOffset(cardWidth, 102)
	card.BackgroundColor3 = machine.RarityColor:Lerp(Color3.fromRGB(12, 14, 13), 0.35)
	card.BorderSizePixel = 0
	card.ZIndex = 83
	card.Parent = parent

	local rarity = Instance.new("TextLabel")
	rarity.Name = "Rarity"
	rarity.Position = UDim2.fromOffset(8, 8)
	rarity.Size = UDim2.new(1, -16, 0, 18)
	rarity.BackgroundTransparency = 1
	rarity.Font = Enum.Font.GothamBlack
	rarity.Text = machine.RarityName
	rarity.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarity.TextSize = 12
	rarity.ZIndex = 84
	rarity.Parent = card

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.fromOffset(8, 30)
	name.Size = UDim2.new(1, -16, 0, 56)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Text = machine.VariantName .. "\n" .. machine.MachineName
	name.TextColor3 = Color3.fromRGB(235, 255, 245)
	name.TextSize = 12
	name.TextWrapped = true
	name.ZIndex = 84
	name.Parent = card
end

local function makeFakeRollMachine(index)
	local rarityId = RandomMachineConfig.RarityOrder[((index - 1) % #RandomMachineConfig.RarityOrder) + 1]
	local variantId = RandomMachineConfig.VariantOrder[((index * 3) % #RandomMachineConfig.VariantOrder) + 1]
	local rarity = RandomMachineConfig.Rarities[rarityId]
	local variant = RandomMachineConfig.Variants[variantId]
	return {
		RarityName = rarity.Name,
		VariantName = variant.Name,
		MachineName = "Machine",
		RarityColor = rarity.Color,
	}
end

local function playRollAnimation(rolledMachine)
	if not rolledMachine then
		return
	end

	for _, child in rollerStrip:GetChildren() do
		child:Destroy()
	end

	local cardWidth = 126
	local gap = 8
	local targetIndex = 26
	local totalCards = 34
	for index = 1, totalCards do
		createRollCard(rollerStrip, index, index == targetIndex and rolledMachine or makeFakeRollMachine(index))
	end

	rollerStrip.Position = UDim2.fromOffset(0, 0)
	rollResultLabel.Text = ""
	rollOverlay.Visible = true

	local targetCenter = ((targetIndex - 1) * (cardWidth + gap)) + (cardWidth * 0.5)
	local windowCenter = rollerWindow.AbsoluteSize.X * 0.5
	local finalOffset = windowCenter - targetCenter
	local tween = TweenService:Create(
		rollerStrip,
		TweenInfo.new(3.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(finalOffset, 0) }
	)
	tween:Play()
	tween.Completed:Wait()

	rollResultLabel.Text = rolledMachine.RarityName .. " " .. rolledMachine.VariantName .. " - " .. rolledMachine.MachineName
	task.wait(0.8)
	rollOverlay.Visible = false
end

local function createMachineRow(machine, index)
	local row = Instance.new("Frame")
	row.Name = machine.InstanceId
	row.LayoutOrder = index
	row.Size = UDim2.new(1, -8, 0, 96)
	row.BackgroundColor3 = machine.RarityColor:Lerp(Color3.fromRGB(20, 24, 23), 0.55)
	row.BorderSizePixel = 0
	row.ZIndex = 22
	row.Parent = list

	local selectedMarker = Instance.new("Frame")
	selectedMarker.Name = "SelectedMarker"
	selectedMarker.Position = UDim2.fromOffset(0, 0)
	selectedMarker.Size = UDim2.fromOffset(4, 96)
	selectedMarker.BackgroundColor3 = machine.InstanceId == selectedInstanceId and Color3.fromRGB(255, 236, 120)
		or Color3.fromRGB(62, 72, 68)
	selectedMarker.BorderSizePixel = 0
	selectedMarker.ZIndex = 23
	selectedMarker.Parent = row

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.fromOffset(12, 8)
	name.Size = UDim2.new(1, -96, 0, 34)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Text = machine.RarityName .. " " .. machine.VariantName .. " - " .. machine.MachineName
	name.TextColor3 = Color3.fromRGB(245, 245, 245)
	name.TextSize = 13
	name.TextWrapped = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextYAlignment = Enum.TextYAlignment.Top
	name.ZIndex = 23
	name.Parent = row

	local detail = Instance.new("TextLabel")
	detail.Name = "Detail"
	detail.Position = UDim2.fromOffset(12, 44)
	detail.Size = UDim2.new(1, -96, 0, 42)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.Gotham
	local placedText = machine.Placed and ("Placee X" .. machine.PlotX .. " Z" .. machine.PlotZ) or "Inventaire"
	detail.Text = placedText
		.. " | Lv."
		.. machine.Level
		.. " F+"
		.. machine.FusionLevel
		.. " | "
		.. formatNumber(machine.Income)
		.. "/s | $"
		.. formatNumber(machine.SellValue)
		.. " | R "
		.. formatNumber(machine.RecycleYield)
	detail.TextColor3 = Color3.fromRGB(218, 224, 220)
	detail.TextSize = 11
	detail.TextWrapped = true
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextYAlignment = Enum.TextYAlignment.Top
	detail.ZIndex = 23
	detail.Parent = row

	local selectButton = makeButton("Select", "SELECT", UDim2.new(1, -82, 0, 10), UDim2.fromOffset(70, 28), row)
	selectButton.MouseButton1Click:Connect(function()
		selectMachine(machine)
		renderState(state)
	end)

	local placeRowButton = makeButton("PlaceNow", "PLACER", UDim2.new(1, -82, 0, 44), UDim2.fromOffset(70, 28), row)
	placeRowButton.MouseButton1Click:Connect(function()
		beginPlacementMode(machine)
	end)

	local lockText = machine.Locked and "LOCK" or ""
	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockState"
	lockLabel.AnchorPoint = Vector2.new(1, 1)
	lockLabel.Position = UDim2.new(1, -12, 1, -6)
	lockLabel.Size = UDim2.fromOffset(70, 18)
	lockLabel.BackgroundTransparency = 1
	lockLabel.Font = Enum.Font.GothamBold
	lockLabel.Text = lockText
	lockLabel.TextColor3 = Color3.fromRGB(255, 235, 150)
	lockLabel.TextSize = 11
	lockLabel.TextXAlignment = Enum.TextXAlignment.Right
	lockLabel.ZIndex = 23
	lockLabel.Parent = row
end

function renderState(nextState)
	state = nextState
	if not state then
		return
	end

	if selectedInstanceId and not findSelectedInstance() then
		selectedInstanceId = nil
	end

	if not selectedInstanceId and #state.Instances > 0 then
		selectMachine(state.Instances[1])
	end

	local selected = findSelectedInstance()
	resourceLabel.Text = state.ScrapName .. ": " .. formatNumber(state.Scrap)
	rollButton.Text = "ROLL $" .. formatNumber(state.RollCost)
	gridLabel.Text = "Terrain " .. state.Placement.MaxColumns .. "x" .. state.Placement.MaxRows .. " | Palier " .. state.CurrentZone

	if selected then
		selectedLabel.Text = selected.RarityName .. " " .. selected.VariantName .. " - " .. selected.MachineName
		lockButton.Text = selected.Locked and "UNLOCK" or "LOCK"
	else
		selectedLabel.Text = "Aucune machine"
		lockButton.Text = "LOCK"
	end

	clearRows()
	for index, machine in ipairs(state.Instances) do
		createMachineRow(machine, index)
	end
end

local function refresh()
	local nextState = getInventoryRemote:InvokeServer()
	renderState(nextState)
end

rollButton.MouseButton1Click:Connect(function()
	if busy then
		return
	end

	busy = true
	messageLabel.Text = ""
	local result = rollRemote:InvokeServer()
	if result then
		if result.State then
			renderState(result.State)
		end
		messageLabel.Text = result.Message or ""

		if result.Success and result.InstanceId then
			local rolledMachine = findInstance(result.InstanceId)
			selectMachine(rolledMachine)
			playRollAnimation(rolledMachine)
			renderState(state)
			beginPlacementMode(rolledMachine)
		end
	end
	busy = false
end)

placeButton.MouseButton1Click:Connect(function()
	local selected = findSelectedInstance()
	if selected then
		beginPlacementMode(selected)
	end
end)

unplaceButton.MouseButton1Click:Connect(function()
	if selectedInstanceId then
		callRemote(unplaceRemote, selectedInstanceId)
	end
end)

sellButton.MouseButton1Click:Connect(function()
	if selectedInstanceId then
		callRemote(sellRemote, selectedInstanceId)
	end
end)

recycleButton.MouseButton1Click:Connect(function()
	if selectedInstanceId then
		callRemote(recycleRemote, selectedInstanceId)
	end
end)

fuseButton.MouseButton1Click:Connect(function()
	if selectedInstanceId then
		callRemote(fuseRemote, selectedInstanceId)
	end
end)

lockButton.MouseButton1Click:Connect(function()
	if selectedInstanceId then
		callRemote(toggleLockRemote, selectedInstanceId)
	end
end)

toggleButton.MouseButton1Click:Connect(function()
	if placementMode then
		endPlacementMode()
	end

	panel.Visible = not panel.Visible
	if panel.Visible then
		refresh()
	end
end)

updatedRemote.OnClientEvent:Connect(function(nextState)
	if panel.Visible or placementMode then
		renderState(nextState)
	end
end)
