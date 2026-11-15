-- GearService: lo que LLEVAS PUESTO (shared/Crafting.stats: lo mejor de cada hueco de tu mochila, con sus
-- mejoras) se ve en tu personaje y marca tu estilo de golpe.
--
--   * Cada poco mira tu equipo; si ha cambiado (o has llegado a un planeta, o has reaparecido), lo vuelve a
--     poner con World/Kit/GearLook. En un planeta se ve; en Valmar no (tu ropa de siempre).
--   * Atributos del jugador: EstiloArma (shared/Combat.WeaponStyles: Cuchillo, Hacha, Lanza o Espada; vacío =
--     puños) que leen CombatService, CombatController y BeastService; NivelCazador.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crafting = require(ReplicatedStorage.Shared.Crafting)
local Combat = require(ReplicatedStorage.Shared.Combat)

local GearService = {}

GearService.Every = 1.5
local shown: { [Player]: string } = {}

local function dataOf(player: Player): { [string]: any }?
	local ok, d = pcall(function()
		return (require(script.Parent.DataService) :: any).get(player)
	end)
	return if ok then d else nil
end

-- La firma del equipo puesto (para no rehacerlo si no cambia)
function GearService.signature(worn: { [string]: string }, refine: { [string]: any }?, planet: boolean, character: Instance?): string
	local parts = {}
	for _, slot in Crafting.Slots do
		local id = worn[slot]
		if id then
			table.insert(parts, ("%s=%s+%d"):format(slot, id, Crafting.refineOf(refine, id)))
		end
	end
	return table.concat(parts, ";") .. (if planet then "|P" else "|V") .. tostring(character)
end

function GearService.update(player: Player)
	local d = dataOf(player)
	if not d then
		return
	end
	local stats = Crafting.stats(d.Items, d.Refine)
	local worn = stats.Worn
	-- (el estilo de arma solo cuenta en los planetas: en Valmar peleas como siempre)
	local style = if type(player:GetAttribute("Planeta")) == "string" then Combat.styleOfWeapon(worn.Arma) else ""
	if player:GetAttribute("EstiloArma") ~= style then
		player:SetAttribute("EstiloArma", style)
	end
	player:SetAttribute("NivelCazador", Crafting.hunterLevel(type(d.Hunter) == "table" and d.Hunter.Xp or 0))
	local character = player.Character
	local onPlanet = type(player:GetAttribute("Planeta")) == "string"
	local sig = GearService.signature(worn, d.Refine, onPlanet, character)
	if shown[player] == sig then
		return
	end
	shown[player] = sig
	if not character then
		return
	end
	local GearLook = require(script.Parent.Parent.World.Kit.GearLook) :: any
	if onPlanet then
		pcall(GearLook.apply, character, worn, d.Refine)
	else
		GearLook.clear(character)
	end
end

function GearService.init()
	task.spawn(function()
		while true do
			task.wait(GearService.Every)
			for _, p in Players:GetPlayers() do
				local ok, err = pcall(GearService.update, p)
				if not ok then
					warn("[GearService] " .. tostring(err))
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		shown[p] = nil
	end)
end

return GearService
