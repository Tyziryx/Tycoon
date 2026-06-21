local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local cendres = leaderstats:WaitForChild("Cendres")

local getShopRemote = ReplicatedStorage:WaitForChild("GetPrestigeShopRemote")
local purchaseRemote = ReplicatedStorage:WaitForChild("PurchasePrestigeUpgradeRemote")
local shopUpdatedRemote = ReplicatedStorage:WaitForChild("PrestigeShopUpdated")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PrestigeShopGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 55
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "TogglePrestigeShop"
toggleButton.AnchorPoint = Vector2.new(1, 1)
toggleButton.Position = UDim2.new(1, -18, 1, -18)
toggleButton.Size = UDim2.fromOffset(128, 42)
toggleButton.BackgroundColor3 = Color3.fromRGB(37, 33, 29)
toggleButton.BorderSizePixel = 0
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "PRESTIGE"
toggleButton.TextColor3 = Color3.fromRGB(255, 230, 170)
toggleButton.TextSize = 16
toggleButton.ZIndex = 10
toggleButton.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "PrestigePanel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -18, 1, -70)
panel.Size = UDim2.fromOffset(360, 430)
panel.BackgroundColor3 = Color3.fromRGB(20, 18, 16)
panel.BackgroundTransparency = 0.05
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
title.Text = "BOUTIQUE CENDRES"
title.TextColor3 = Color3.fromRGB(255, 230, 170)
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 21
title.Parent = panel

local cendresLabel = Instance.new("TextLabel")
cendresLabel.Name = "Cendres"
cendresLabel.Position = UDim2.fromOffset(16, 40)
cendresLabel.Size = UDim2.new(1, -32, 0, 22)
cendresLabel.BackgroundTransparency = 1
cendresLabel.Font = Enum.Font.GothamBold
cendresLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
cendresLabel.TextSize = 14
cendresLabel.TextXAlignment = Enum.TextXAlignment.Left
cendresLabel.ZIndex = 21
cendresLabel.Parent = panel

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.Position = UDim2.fromOffset(16, 64)
messageLabel.Size = UDim2.new(1, -32, 0, 20)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.Gotham
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
messageLabel.TextSize = 12
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.ZIndex = 21
messageLabel.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "UpgradeList"
list.Position = UDim2.fromOffset(12, 92)
list.Size = UDim2.new(1, -24, 1, -104)
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

local isPurchasing = false

local function formatNumber(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(math.floor(amount))
end

local function clearRows()
	for _, child in list:GetChildren() do
		if child ~= layout then
			child:Destroy()
		end
	end
end

local function createUpgradeRow(upgrade, index)
	local row = Instance.new("Frame")
	row.Name = upgrade.Id
	row.LayoutOrder = index
	row.Size = UDim2.new(1, -8, 0, 76)
	row.BackgroundColor3 = Color3.fromRGB(35, 31, 27)
	row.BorderSizePixel = 0
	row.ZIndex = 22
	row.Parent = list

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.fromOffset(12, 8)
	name.Size = UDim2.new(1, -138, 0, 20)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Text = upgrade.Name .. "  Lv." .. upgrade.Level .. "/" .. upgrade.MaxLevel
	name.TextColor3 = Color3.fromRGB(245, 245, 245)
	name.TextSize = 14
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 23
	name.Parent = row

	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Position = UDim2.fromOffset(12, 30)
	description.Size = UDim2.new(1, -138, 0, 34)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.Text = upgrade.Description
	description.TextColor3 = Color3.fromRGB(205, 205, 205)
	description.TextSize = 12
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.ZIndex = 23
	description.Parent = row

	local purchaseButton = Instance.new("TextButton")
	purchaseButton.Name = "Purchase"
	purchaseButton.AnchorPoint = Vector2.new(1, 0.5)
	purchaseButton.Position = UDim2.new(1, -10, 0.5, 0)
	purchaseButton.Size = UDim2.fromOffset(112, 40)
	purchaseButton.BackgroundColor3 = Color3.fromRGB(72, 55, 26)
	purchaseButton.BorderSizePixel = 0
	purchaseButton.Font = Enum.Font.GothamBold
	purchaseButton.TextColor3 = Color3.fromRGB(255, 232, 180)
	purchaseButton.TextSize = 12
	purchaseButton.ZIndex = 23
	purchaseButton.Parent = row

	if upgrade.NextCost then
		purchaseButton.Text = formatNumber(upgrade.NextCost) .. " C"
	else
		purchaseButton.Text = "MAX"
		purchaseButton.AutoButtonColor = false
		purchaseButton.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
	end

	purchaseButton.MouseButton1Click:Connect(function()
		if isPurchasing or not upgrade.NextCost then
			return
		end

		isPurchasing = true
		messageLabel.Text = ""
		local result = purchaseRemote:InvokeServer(upgrade.Id)
		if result then
			messageLabel.Text = result.Message or ""
			if result.ShopState then
				clearRows()
				for rowIndex, rowUpgrade in ipairs(result.ShopState.Upgrades) do
					createUpgradeRow(rowUpgrade, rowIndex)
				end
				cendresLabel.Text = "Cendres: " .. formatNumber(result.ShopState.Cendres)
			end
		end
		isPurchasing = false
	end)
end

local function renderShop(shopState)
	if not shopState then
		return
	end

	cendresLabel.Text = "Cendres: " .. formatNumber(shopState.Cendres)
	clearRows()

	for index, upgrade in ipairs(shopState.Upgrades) do
		createUpgradeRow(upgrade, index)
	end
end

local function refreshShop()
	local shopState = getShopRemote:InvokeServer()
	renderShop(shopState)
end

toggleButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refreshShop()
	end
end)

cendres.Changed:Connect(function()
	cendresLabel.Text = "Cendres: " .. formatNumber(cendres.Value)
	if panel.Visible then
		refreshShop()
	end
end)

shopUpdatedRemote.OnClientEvent:Connect(function(shopState)
	if panel.Visible then
		renderShop(shopState)
	end
end)

cendresLabel.Text = "Cendres: " .. formatNumber(cendres.Value)
