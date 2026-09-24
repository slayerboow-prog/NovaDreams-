-- RoleService: quién cubre cada puesto en ESTE servidor, un jugador o un NPC.
--
--   RoleService.setOnDuty(player, "Profesor", { Subject = "Matematicas" })  -- el jugador ficha
--   RoleService.offDuty(player, "Profesor")                                 -- deja el turno
--   local who = RoleService.assign("Profesor", { Subject = "Matematicas" })
--     -> { Kind = "Player", Player = p }  si hay un jugador libre que encaje
--     -> { Kind = "NPC", Npc = "Npc_Profesor" }  si no (nunca se queda nadie esperando)
--   RoleService.release(who)                                                -- al terminar
--
-- El estado es de cada servidor (los jugadores de otro servidor no pueden dar clase aquí).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roles = require(ReplicatedStorage.Shared.Roles)

local RoleService = {}

export type Assignment = {
	Kind: "Player" | "NPC",
	RoleId: string,
	Player: Player?,
	Npc: string?,
}

type Duty = { Info: { [string]: any }, Clients: number }
local duties: { [string]: { [Player]: Duty } } = {}

function RoleService.setOnDuty(player: Player, roleId: string, info: { [string]: any }?)
	if not Roles[roleId] then
		warn("[RoleService] Rol desconocido:", roleId)
		return
	end
	duties[roleId] = duties[roleId] or {}
	duties[roleId][player] = { Info = info or {}, Clients = 0 }
	player:SetAttribute("Duty_" .. roleId, true)
end

-- Sin roleId: deja todos sus turnos (al salir del juego)
function RoleService.offDuty(player: Player, roleId: string?)
	for id, list in duties do
		if (roleId == nil or id == roleId) and list[player] then
			list[player] = nil
			player:SetAttribute("Duty_" .. id, nil)
		end
	end
end

function RoleService.isOnDuty(player: Player, roleId: string): boolean
	return duties[roleId] ~= nil and duties[roleId][player] ~= nil
end

-- Los roles en los que está de servicio el jugador (lo usa la historia para sus requisitos)
function RoleService.dutiesOf(player: Player): { [string]: boolean }
	local result = {}
	for id, list in duties do
		if list[player] then
			result[id] = true
		end
	end
	return result
end

function RoleService.onDuty(roleId: string): { Player }
	local result = {}
	for player in duties[roleId] or {} do
		table.insert(result, player)
	end
	return result
end

local function matches(info: { [string]: any }, filter: { [string]: any }?): boolean
	for key, value in filter or {} do
		if info[key] ~= nil and info[key] ~= value then
			return false
		end
	end
	return true
end

-- Elige al jugador de servicio más libre que encaje; si no hay, el NPC del puesto.
function RoleService.assign(roleId: string, filter: { [string]: any }?, exclude: Player?): Assignment
	local role = Roles[roleId]
	local best: Player? = nil
	local bestLoad = math.huge
	for player, duty in duties[roleId] or {} do
		if player ~= exclude and player.Parent and duty.Clients < role.MaxClients and matches(duty.Info, filter) then
			if duty.Clients < bestLoad then
				best, bestLoad = player, duty.Clients
			end
		end
	end
	if best then
		duties[roleId][best].Clients += 1
		return { Kind = "Player", RoleId = roleId, Player = best }
	end
	return { Kind = "NPC", RoleId = roleId, Npc = if role then role.Npc else "Npc_Generico" }
end

function RoleService.release(assignment: Assignment)
	if assignment.Kind ~= "Player" or not assignment.Player then
		return
	end
	local duty = duties[assignment.RoleId] and duties[assignment.RoleId][assignment.Player]
	if duty then
		duty.Clients = math.max(0, duty.Clients - 1)
	end
end

function RoleService.init()
	Players.PlayerRemoving:Connect(function(player)
		RoleService.offDuty(player)
	end)
end

return RoleService
