-- src/server/init.server.luau
-- Point d'entrée principal du serveur

print("Hello world, from server!")

-- 1. Charger les configurations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ZoneConfig = require(ReplicatedStorage.Shared.Config.ZoneConfig)
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local PlayerService = require(script.Services.PlayerService)
local ButtonService = require(script.Services.ButtonService)
local TycoonService = require(script.Services.TycoonService)
local MachineService = require(script.Services.MachineService)

PlayerService.Init()
TycoonService.Init()
wait(2)
ButtonService.Init()

print("Serveur initialisé avec succès!")

while true do
	PlayerService.UpdatePlayer()
	ButtonService.UpdateButton()
	task.wait(GameConfig.GENERATION_INTERVAL)
end
