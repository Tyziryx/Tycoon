-- src/server/init.server.luau
-- Point d'entrée principal du serveur

print("Hello world, from server!")

-- 1. Charger les configurations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
-- local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)
-- local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local PlayerService = require(script.Services.PlayerService)
local ButtonService = require(script.Services.ButtonService)
local TycoonService = require(script.Services.TycoonService)
local PurchasableService = require(script.Services.PurchasableService)
local ZoneService = require(script.Services.ZoneService)
local RebirthService = require(script.Services.RebirthService)
local ShopService = require(script.Services.ShopService)
local MachineInventoryService = require(script.Services.MachineInventoryService)

ZoneService.init()
RebirthService.init()
ShopService.init()
MachineInventoryService.init()
PlayerService.init()
TycoonService.init()
PurchasableService.init()
ButtonService.init()

print("Serveur initialisé avec succès!")

while true do
	PlayerService.updatePlayer()
	ButtonService.updateButton()
	task.wait(GameConfig.GENERATION_INTERVAL)
end
