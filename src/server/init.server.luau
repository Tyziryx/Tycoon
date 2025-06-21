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

PlayerService.Init()
ButtonService.Init()

print("Serveur initialisé avec succès!")

while true do
	ButtonService.UpdateButton()
	PlayerService.UpdatePlayer()
	task.wait(2)
end
