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
local ManualBurnerService = require(script.Services.ManualBurnerService)
local VisualEffectsService = require(script.Services.VisualEffectsService)

PlayerService.init()
TycoonService.init()
PurchasableService.init()
VisualEffectsService.init()
ManualBurnerService.init()
wait(2)
ButtonService.init()

print("Serveur initialisé avec succès!")

while true do
	PlayerService.updatePlayer()
	ButtonService.updateButton()
	task.wait(GameConfig.GENERATION_INTERVAL)
end
