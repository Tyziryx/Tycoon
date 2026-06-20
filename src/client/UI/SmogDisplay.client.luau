-- Smog progressif : plus la Pollution Totale (à vie) du joueur est élevée,
-- plus l'atmosphère devient dense et jaunâtre. C'est une récompense visuelle
-- qui valorise la pollution (cf. docs/DESIGN.md, "Mécaniques polluer plus").

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ── Réglages (à ajuster librement) ───────────────────────────────────────────
local MAX_POLLUTION = 2000 -- Pollution Totale pour atteindre le smog maximal
local SMOG_COLOR = Color3.fromRGB(180, 170, 140) -- teinte sale/jaunâtre au max
local MAX_DENSITY = 0.7 -- densité d'atmosphère au max (0..1)
local MAX_HAZE = 10 -- brume au max (0..10)
local TWEEN_TIME = 2 -- transition douce en secondes
-- ─────────────────────────────────────────────────────────────────────────────

local leaderstats = player:WaitForChild("leaderstats")
local totalPollution = leaderstats:WaitForChild("Pollution Totale")

-- Utiliser l'Atmosphere existante si présente (pour ne pas écraser l'ambiance
-- artistique du place), sinon en créer une.
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
end

-- Valeurs de base = état du monde à 0 pollution. Le smog ne fait qu'intensifier
-- à partir de là.
local baseDensity = atmosphere.Density
local baseHaze = atmosphere.Haze
local baseColor = atmosphere.Color

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function updateSmog()
	local alpha = math.clamp(totalPollution.Value / MAX_POLLUTION, 0, 1)

	local goalDensity = lerp(baseDensity, math.max(baseDensity, MAX_DENSITY), alpha)
	local goalHaze = lerp(baseHaze, math.max(baseHaze, MAX_HAZE), alpha)
	local goalColor = baseColor:Lerp(SMOG_COLOR, alpha)

	TweenService:Create(atmosphere, TweenInfo.new(TWEEN_TIME), {
		Density = goalDensity,
		Haze = goalHaze,
		Color = goalColor,
	}):Play()
end

totalPollution.Changed:Connect(updateSmog)
updateSmog()
