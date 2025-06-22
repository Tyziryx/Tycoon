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
local MachineService = require(script.Services.MachineService)

PlayerService.init()
TycoonService.init()
wait(2)
ButtonService.init()

print("Serveur initialisé avec succès!")

while true do
	PlayerService.updatePlayer()
	ButtonService.updateButton()
	task.wait(GameConfig.GENERATION_INTERVAL)
end
