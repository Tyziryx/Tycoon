local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
screenGui.DisplayOrder = 65
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
panel.Size = UDim2.fromOffset(430, 520)
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
controls.Name = "PlacementControls"
controls.Position = UDim2.fromOffset(12, 88)
controls.Size = UDim2.new(1, -24, 0, 118)
controls.BackgroundColor3 = Color3.fromRGB(28, 34, 32)
controls.BorderSizePixel = 0
controls.ZIndex = 22
controls.Parent = panel

local selectedLabel = makeLabel("Selected", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 22), controls)
local gridLabel = makeLabel("Grid", UDim2.fromOffset(12, 30), UDim2.new(1, -24, 0, 18), controls)

local xMinus = makeButton("XMinus", "X-", UDim2.fromOffset(12, 56), UDim2.fromOffset(42, 24), controls)
local xValue = makeLabel("XValue", UDim2.fromOffset(58, 58), UDim2.fromOffset(48, 20), controls)
local xPlus = makeButton("XPlus", "X+", UDim2.fromOffset(108, 56), UDim2.fromOffset(42, 24), controls)

local zMinus = makeButton("ZMinus", "Z-", UDim2.fromOffset(164, 56), UDim2.fromOffset(42, 24), controls)
local zValue = makeLabel("ZValue", UDim2.fromOffset(210, 58), UDim2.fromOffset(48, 20), controls)
local zPlus = makeButton("ZPlus", "Z+", UDim2.fromOffset(260, 56), UDim2.fromOffset(42, 24), controls)
local rotateButton = makeButton("Rotate", "90", UDim2.fromOffset(316, 56), UDim2.fromOffset(78, 24), controls)

local placeButton = makeButton("Place", "PLACER", UDim2.fromOffset(12, 86), UDim2.fromOffset(72, 24), controls)
local unplaceButton = makeButton("Unplace", "RANGER", UDim2.fromOffset(90, 86), UDim2.fromOffset(72, 24), controls)
local sellButton = makeButton("Sell", "VENDRE", UDim2.fromOffset(168, 86), UDim2.fromOffset(70, 24), controls)
local recycleButton = makeButton("Recycle", "RECYCLE", UDim2.fromOffset(244, 86), UDim2.fromOffset(70, 24), controls)
local fuseButton = makeButton("Fuse", "FUSION", UDim2.fromOffset(320, 86), UDim2.fromOffset(74, 24), controls)

local lockButton = makeButton("Lock", "LOCK", UDim2.fromOffset(328, 8), UDim2.fromOffset(66, 24), controls)

local list = Instance.new("ScrollingFrame")
list.Name = "MachineList"
list.Position = UDim2.fromOffset(12, 216)
list.Size = UDim2.new(1, -24, 1, -228)
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

local state = nil
local selectedInstanceId = nil
local selectedX = 0
local selectedZ = 0
local selectedRotation = 0
local busy = false

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

local function clampPlacement()
	if not state then
		return
	end

	selectedX = math.clamp(selectedX, 0, math.max(0, state.Placement.MaxColumns - 1))
	selectedZ = math.clamp(selectedZ, 0, math.max(0, state.Placement.MaxRows - 1))
	selectedRotation = selectedRotation % 360
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
		selectedX = math.max(0, machine.PlotX)
		selectedZ = math.max(0, machine.PlotZ)
		selectedRotation = machine.Rotation
	else
		selectedX = 0
		selectedZ = 0
		selectedRotation = 0
	end
	clampPlacement()
end

local renderState

local function callRemote(remote, ...)
	if busy then
		return
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
end

local function createMachineRow(machine, index)
	local row = Instance.new("Frame")
	row.Name = machine.InstanceId
	row.LayoutOrder = index
	row.Size = UDim2.new(1, -8, 0, 94)
	row.BackgroundColor3 = machine.RarityColor:Lerp(Color3.fromRGB(20, 24, 23), 0.55)
	row.BorderSizePixel = 0
	row.ZIndex = 22
	row.Parent = list

	local selectedMarker = Instance.new("Frame")
	selectedMarker.Name = "SelectedMarker"
	selectedMarker.Position = UDim2.fromOffset(0, 0)
	selectedMarker.Size = UDim2.fromOffset(4, 94)
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
	detail.Size = UDim2.new(1, -96, 0, 40)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.Gotham
	local placedText = machine.Placed and ("X" .. machine.PlotX .. " Z" .. machine.PlotZ .. " R" .. machine.Rotation)
		or "Inventaire"
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

	local selectButton = makeButton("Select", "SELECT", UDim2.new(1, -82, 0, 12), UDim2.fromOffset(70, 30), row)
	selectButton.MouseButton1Click:Connect(function()
		selectMachine(machine)
		renderState(state)
	end)

	local lockText = machine.Locked and "LOCK" or ""
	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockState"
	lockLabel.AnchorPoint = Vector2.new(1, 1)
	lockLabel.Position = UDim2.new(1, -12, 1, -10)
	lockLabel.Size = UDim2.fromOffset(70, 20)
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

	clampPlacement()
	local selected = findSelectedInstance()
	resourceLabel.Text = state.ScrapName .. ": " .. formatNumber(state.Scrap)
	rollButton.Text = "ROLL $" .. formatNumber(state.RollCost)
	gridLabel.Text = "Grille " .. state.Placement.MaxColumns .. "x" .. state.Placement.MaxRows .. " | Palier " .. state.CurrentZone
	xValue.Text = "X " .. selectedX
	zValue.Text = "Z " .. selectedZ
	rotateButton.Text = tostring(selectedRotation) .. "°"

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
	callRemote(rollRemote)
end)

xMinus.MouseButton1Click:Connect(function()
	selectedX -= 1
	clampPlacement()
	renderState(state)
end)

xPlus.MouseButton1Click:Connect(function()
	selectedX += 1
	clampPlacement()
	renderState(state)
end)

zMinus.MouseButton1Click:Connect(function()
	selectedZ -= 1
	clampPlacement()
	renderState(state)
end)

zPlus.MouseButton1Click:Connect(function()
	selectedZ += 1
	clampPlacement()
	renderState(state)
end)

rotateButton.MouseButton1Click:Connect(function()
	selectedRotation = (selectedRotation + 90) % 360
	renderState(state)
end)

placeButton.MouseButton1Click:Connect(function()
	if selectedInstanceId then
		callRemote(placeRemote, selectedInstanceId, selectedX, selectedZ, selectedRotation)
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
	panel.Visible = not panel.Visible
	if panel.Visible then
		refresh()
	end
end)

updatedRemote.OnClientEvent:Connect(function(nextState)
	if panel.Visible then
		renderState(nextState)
	end
end)
