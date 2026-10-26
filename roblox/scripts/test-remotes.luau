-- test-remotes: lo que mandan los clientes por los remotos y el servidor NO debe creerse
-- (auditoría de seguridad, docs/auditoria-skills/informe.md).
--
--   * ActionService.vault: un salto de parkour con duración NaN o infinita no vale (con NaN,
--     «x < 0,2 or x > 2,5» da falso y la duración rota acababa en el atributo «Vault» de todos).
--   * ActionService.flashlight: la linterna no se puede encender y apagar sin límite (cada cambio
--     replica dos luces y un atributo a TODOS los jugadores).
--
-- Uso (desde roblox/): lune run scripts/test-remotes.luau

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local check = L.check

print("ActionService (saltos de parkour y linterna)")

local serverNow = 1000
L.globals.workspace = {
	GetServerTimeNow = function()
		return serverNow
	end,
}
L.services.Players = {
	PlayerAdded = { Connect = function() end },
	PlayerRemoving = { Connect = function() end },
	GetPlayers = function()
		return {}
	end,
}
L.services.ReplicatedStorage.Remotes = { Actions = { FireClient = function() end } }

local ActionService = L.load("src/server/Services/ActionService")

-- Un jugador de pie, con su personaje (para la linterna, un HumanoidRootPart de verdad)
local function newPlayer(name: string, id: number)
	local p = L.player(name, id)
	local character = roblox.Instance.new("Model")
	local root = roblox.Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Parent = character
	local humanoid = {
		Health = 100,
		SeatPart = nil,
		Sit = false,
		GetState = function()
			return roblox.Enum.HumanoidStateType.Running
		end,
	}
	p.Character = {
		FindFirstChild = function(_, n)
			return character:FindFirstChild(n)
		end,
		FindFirstChildOfClass = function(_, class)
			if class == "Humanoid" then
				return humanoid
			end
			return nil
		end,
	}
	p:SetAttribute("LifeStage", "Adulto")
	return p, root
end

local function sleep(seconds: number)
	local t = os.clock() + seconds
	while os.clock() < t do
	end
end

-- 1) Saltos: lo normal vale; NaN, infinito y fuera de rango, no
local ana = newPlayer("Ana", 101)
check(ActionService.vault(ana, { Kind = "Speed", Duration = 0.8 }) == true, "un salto normal (0,8 s) vale")
check(type(ana:GetAttribute("Vault")) == "string" and ana:GetAttribute("Vault"):find("^Speed|") ~= nil, "y se publica en el atributo Vault")
sleep(0.35)
local nan = 0 / 0
ana:SetAttribute("Vault", nil)
check(ActionService.vault(ana, { Kind = "Speed", Duration = nan }) == false, "duración NaN: no vale")
check(ana:GetAttribute("Vault") == nil, "…y no toca el atributo")
sleep(0.35)
check(ActionService.vault(ana, { Kind = "Kong", Duration = math.huge }) == false, "duración infinita: no vale")
check(ActionService.vault(ana, { Kind = "Kong", Duration = -math.huge }) == false, "duración -infinita: no vale")
check(ActionService.vault(ana, { Kind = "Kong", Duration = 9 }) == false, "duración de 9 s (fuera de rango): no vale")
check(ActionService.vault(ana, { Kind = "Volar", Duration = 1 }) == false, "un tipo de salto que no existe: no vale")
check(ActionService.vault(ana, "Speed") == false, "algo que no es una tabla: no vale")
check(ana:GetAttribute("Vault") == nil, "ningún salto roto ha llegado al atributo")
-- Inicio NaN: el salto vale, pero con la hora del servidor
sleep(0.35)
check(ActionService.vault(ana, { Kind = "Climb", Duration = 1, Start = nan }) == true, "inicio NaN: el salto vale…")
local vault = ana:GetAttribute("Vault") :: string
local startText = vault and vault:match("^Climb|([^|]+)|")
check(startText == ("%.3f"):format(serverNow), "…con la hora del servidor, no la NaN del cliente")
check(vault ~= nil and not vault:lower():find("nan") and not vault:lower():find("inf"), "el atributo Vault no lleva nan ni inf")

-- 2) Linterna: se enciende y se apaga, pero no más de una vez cada FLASHLIGHT_GAP
local bea, root = newPlayer("Bea", 102)
ActionService.flashlight(bea, true)
check(bea:GetAttribute("Flashlight") == true, "la linterna se enciende")
local attachment = root:FindFirstChild("Flashlight")
check(attachment ~= nil and attachment:FindFirstChild("Beam") ~= nil, "con su luz en el pecho")
local changes = 0
for i = 1, 200 do
	local before = bea:GetAttribute("Flashlight")
	ActionService.flashlight(bea, i % 2 == 0)
	if bea:GetAttribute("Flashlight") ~= before then
		changes += 1
	end
end
check(changes == 0, ("200 cambios seguidos de un tramposo: ninguno pasa (pasaron %d)"):format(changes))
sleep(ActionService.FLASHLIGHT_GAP + 0.05)
ActionService.flashlight(bea, false)
check(bea:GetAttribute("Flashlight") == false, "pasado el respiro, apagarla funciona")
check(attachment ~= nil and (attachment:FindFirstChild("Beam") :: any).Enabled == false, "…y la luz se apaga de verdad")

L.finish("test-remotes")
