local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local DecorationConfig = require(ReplicatedStorage.Shared.Config.DecorationConfig)

local TycoonService = require(script.Parent.TycoonService)
local PurchasableService = require(script.Parent.PurchasableService)
local MoneyService = require(script.Parent.MoneyService)

local ButtonService = {}

local redButton = Color3.fromRGB(196, 81, 81)
local greenButton = Color3.fromRGB(42, 221, 42)
local blueButton = Color3.fromRGB(100, 150, 255)
local yellowButton = Color3.fromRGB(235, 190, 70)

local ButtonSounds = {
	Purchase = {
		Name = "PurchaseSound",
		SoundId = "rbxasset://sounds/button.wav",
		Volume = 0.7,
		PlaybackSpeed = 1.15,
	},
	Denied = {
		Name = "DeniedSound",
		SoundId = "rbxasset://sounds/bass.wav",
		Volume = 0.45,
		PlaybackSpeed = 1.4,
	},
}

local function setButtonText(button, text)
	local costGui = button:FindFirstChild("Cost")
	if not costGui then
		return
	end

	local label = costGui:GetChildren()[1]
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function getButtonInfo(buttonId)
	if buttonId < 1000 then
		return {
			itemType = "Machine",
			targetId = buttonId,
			config = MachineConfig[buttonId],
		}
	end

	local decorationId = buttonId - 1000
	return {
		itemType = "Decoration",
		targetId = decorationId,
		config = DecorationConfig[decorationId],
	}
end

local function getTycoonForButton(button)
	for _, tycoon in Workspace.Tycoons:GetChildren() do
		if button:IsDescendantOf(tycoon) then
			return tycoon
		end
	end

	return nil
end

local function getPlayerForButton(button)
	local tycoon = getTycoonForButton(button)
	local playerId = tycoon and tycoon:GetAttribute("UserId")
	if type(playerId) ~= "number" then
		return nil
	end

	return Players:GetPlayerByUserId(playerId)
end

local function getCostGuiEnabled(button)
	local costGui = button:FindFirstChild("Cost")
	return costGui and costGui.Enabled
end

local function setupButtonSound(button, soundConfig)
	local sound = button:FindFirstChild(soundConfig.Name)
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = soundConfig.Name
		sound.Parent = button
	end

	sound.SoundId = soundConfig.SoundId
	sound.Volume = soundConfig.Volume
	sound.PlaybackSpeed = soundConfig.PlaybackSpeed
	sound.RollOffMaxDistance = 35
	return sound
end

local function setupButtonSounds(button)
	setupButtonSound(button, ButtonSounds.Purchase)
	setupButtonSound(button, ButtonSounds.Denied)
end

local function playButtonSound(button, soundType)
	local soundConfig = ButtonSounds[soundType]
	if not soundConfig then
		return
	end

	local sound = button:FindFirstChild(soundConfig.Name) or setupButtonSound(button, soundConfig)
	sound:Stop()
	sound:Play()
end

function ButtonService.init()
	local updateButtonsEvent = ReplicatedStorage:WaitForChild("UpdateButtons")
	updateButtonsEvent.Event:Connect(function()
		ButtonService.updateButton()
	end)

	for _, button in CollectionService:GetTagged("TycoonButton") do
		local buttonId = button:GetAttribute("machineId")
		if not buttonId then
			warn("Button mal configure:", buttonId)
			continue
		end

		local info = getButtonInfo(buttonId)
		if not info.config then
			warn("Config introuvable pour bouton:", buttonId)
			continue
		end

		setupButtonSounds(button)
		setButtonText(button, info.config.Name .. " " .. info.config.BaseCost .. " $")

		button.Touched:Connect(function(hit)
			ButtonService.handleTouch(button, buttonId, hit)
		end)

		if buttonId == 1 or buttonId == 1001 then
			ButtonService.showButton(button)
		else
			ButtonService.hideButton(button)
		end
	end
end

function ButtonService.handleTouch(button, buttonId, hit)
	if button:GetAttribute("Unlocked") or button:GetAttribute("TempDisabled") or not getCostGuiEnabled(button) then
		return
	end

	local lastClickTime = button:GetAttribute("LastClickTime") or 0
	local currentTime = os.clock()
	if currentTime - lastClickTime < 0.5 then
		return
	end
	button:SetAttribute("LastClickTime", currentTime)

	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end

	local tycoon = TycoonService.getTycoon(player)
	if not tycoon or not button:IsDescendantOf(tycoon) then
		return
	end

	local info = getButtonInfo(buttonId)
	if not info.config then
		return
	end

	if ButtonService.playerOwnsItem(player, info.itemType, info.targetId) then
		if info.itemType == "Machine" then
			ButtonService.handleUpgrade(button, player, info.targetId)
		end
		return
	end

	local success = false
	if info.itemType == "Machine" then
		success = PurchasableService.unlockMachine(player, info.targetId)
	else
		success = PurchasableService.unlockDecoration(player, info.targetId)
	end

	if not success then
		playButtonSound(button, "Denied")
		return
	end

	playButtonSound(button, "Purchase")
	ButtonService.startBuildState(button, player, info)
end

function ButtonService.startBuildState(button, player, info)
	button:SetAttribute("TempDisabled", true)
	button.Color = yellowButton
	setButtonText(button, "Building...")

	local buildTime = info.config.BuildTime or 0
	task.delay(buildTime, function()
		if not button.Parent then
			return
		end

		if info.itemType == "Machine" then
			if not ButtonService.playerOwnsItem(player, info.itemType, info.targetId) then
				button:SetAttribute("TempDisabled", false)
				return
			end

			ButtonService.convertToUpgradeButton(button, info.targetId, player)
			ButtonService.showNextButton(button, player)
		else
			button:SetAttribute("Unlocked", true)
			ButtonService.hideButton(button)
		end

		button:SetAttribute("TempDisabled", false)
	end)
end

function ButtonService.updateButton()
	for _, button in CollectionService:GetTagged("TycoonButton") do
		if not button:IsDescendantOf(Workspace.Tycoons) then
			continue
		end

		if button:GetAttribute("TempDisabled") or not getCostGuiEnabled(button) then
			continue
		end

		local buttonId = button:GetAttribute("machineId")
		if not buttonId then
			continue
		end

		local info = getButtonInfo(buttonId)
		if not info.config then
			continue
		end

		local tycoon = getTycoonForButton(button)
		local playerId = tycoon and tycoon:GetAttribute("UserId")
		if type(playerId) ~= "number" then
			continue
		end

		local player = game.Players:GetPlayerByUserId(playerId)
		if not player then
			continue
		end

		local isUpgradeButton = button:GetAttribute("IsUpgradeButton")
		if isUpgradeButton and info.itemType == "Machine" then
			local machine = PurchasableService.getMachine(info.targetId)
			if machine and machine:canUpgrade(player) then
				local upgradeCost = machine:getUpgradeCost(player)
				if upgradeCost then
					button.Color = MoneyService.canAfford(player, upgradeCost) and blueButton or redButton
				end
			end
		else
			button.Color = MoneyService.canAfford(player, info.config.BaseCost) and greenButton or redButton
		end
	end
end

function ButtonService.hideButton(button)
	if button == nil then
		warn("Button is nil")
		return
	end

	if button:IsA("BasePart") then
		button.Transparency = 1
		if button:FindFirstChild("Base") then
			button.Base.Transparency = 1
		end
		if button:FindFirstChild("Cost") then
			button.Cost.Enabled = false
		end
		if button:FindFirstChild("ClickDetector") then
			button.ClickDetector.MaxActivationDistance = 0
		end
		button.CanTouch = false
	end
end

function ButtonService.showButton(button)
	if button == nil then
		warn("Button is nil")
		return
	end

	if button:IsA("BasePart") then
		button.Transparency = 0
		if button:FindFirstChild("Base") then
			button.Base.Transparency = 0
		end
		if button:FindFirstChild("Cost") then
			button.Cost.Enabled = true
		end
		if button:FindFirstChild("ClickDetector") then
			button.ClickDetector.MaxActivationDistance = 32
		end
		button.CanTouch = true
	end
end

function ButtonService.getButtonByTycoon(machineId, tycoon)
	if not tycoon then
		return nil
	end

	for _, button in CollectionService:GetTagged("TycoonButton") do
		if button:IsDescendantOf(tycoon) and button:GetAttribute("machineId") == machineId then
			return button
		end
	end

	return nil
end

function ButtonService.showNextButton(parentButton, player)
	if parentButton == nil or player == nil then
		return
	end

	local machineId = parentButton:GetAttribute("machineId")
	local machineConfig = MachineConfig[machineId]
	if not machineConfig or not machineConfig.NextButton or machineConfig.NextButton < 0 then
		return
	end

	local tycoon = TycoonService.getTycoon(player)
	local childButton = ButtonService.getButtonByTycoon(machineConfig.NextButton, tycoon)
	if not childButton then
		return
	end

	local nextConfig = MachineConfig[machineConfig.NextButton]
	local unlockDelay = nextConfig and nextConfig.UnlockDelay or 0
	task.delay(unlockDelay, function()
		if not ButtonService.playerOwnsMachine(player, machineId) then
			return
		end

		if childButton.Parent then
			ButtonService.showButton(childButton)
		end
	end)
end

function ButtonService.convertToUpgradeButton(button, machineId, player)
	button.Color = redButton
	ButtonService.updateUpgradeButtonText(button, machineId, player)
	button:SetAttribute("IsUpgradeButton", true)
end

function ButtonService.updateUpgradeButtonText(button, machineId, player)
	local machine = PurchasableService.getMachine(machineId)
	local machineConfig = MachineConfig[machineId]
	if not machine or not machineConfig then
		return
	end

	player = player or getPlayerForButton(button)
	if not player then
		return
	end

	if machine:canUpgrade(player) then
		local upgradeCost = machine:getUpgradeCost(player)
		local nextLevel = machine:getLevel(player) + 1
		setButtonText(button, "Upgrade " .. machineConfig.Name .. " Lvl." .. nextLevel .. " - " .. upgradeCost .. "$")
	else
		setButtonText(button, machineConfig.Name .. " Max")
	end
end

function ButtonService.handleUpgrade(button, player, machineId)
	local machine = PurchasableService.getMachine(machineId)
	if not machine or not machine:canUpgrade(player) then
		playButtonSound(button, "Denied")
		return
	end

	local upgradeCost = machine:getUpgradeCost(player)
	if not upgradeCost or not MoneyService.canAfford(player, upgradeCost) then
		playButtonSound(button, "Denied")
		return
	end

	local success = PurchasableService.upgradeMachine(player, machineId)
	if not success then
		playButtonSound(button, "Denied")
		return
	end

	playButtonSound(button, "Purchase")

	if machine:getLevel(player) >= machine.maxLevel then
		button:SetAttribute("Maxed", true)
		ButtonService.hideButton(button)
		return
	end

	ButtonService.updateUpgradeButtonText(button, machineId, player)
end

function ButtonService.playerOwnsItem(player, itemType, itemId)
	if itemType == "Machine" then
		return PurchasableService.playerOwnsMachine(player, itemId)
	end

	local folderName = itemType == "Decoration" and "OwnedDecorations" or "OwnedMachines"
	local ownedItems = player.Data:FindFirstChild(folderName)
	if not ownedItems then
		return false
	end

	for _, itemData in ownedItems:GetChildren() do
		if itemData.Value == itemId then
			return true
		end
	end

	return false
end

function ButtonService.playerOwnsMachine(player, machineId)
	return ButtonService.playerOwnsItem(player, "Machine", machineId)
end

function ButtonService.resetMachineButtonsForPlayer(player)
	local tycoon = TycoonService.getTycoon(player)
	if not tycoon then
		return
	end

	for _, button in CollectionService:GetTagged("TycoonButton") do
		if not button:IsDescendantOf(tycoon) then
			continue
		end

		local buttonId = button:GetAttribute("machineId")
		if type(buttonId) ~= "number" or buttonId >= 1000 then
			continue
		end

		local machineConfig = MachineConfig[buttonId]
		if not machineConfig then
			continue
		end

		button:SetAttribute("TempDisabled", false)
		button:SetAttribute("Unlocked", false)
		button:SetAttribute("IsUpgradeButton", false)
		button:SetAttribute("Maxed", false)
		setButtonText(button, machineConfig.Name .. " " .. machineConfig.BaseCost .. " $")

		if buttonId == 1 then
			ButtonService.showButton(button)
		else
			ButtonService.hideButton(button)
		end
	end

	ButtonService.updateButton()
end

return ButtonService
