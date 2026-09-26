-- Roles: puestos que puede ocupar un JUGADOR real o, si no hay ninguno, un NPC.
-- Es la regla de oro del multijugador: la vida de nadie se bloquea por falta de jugadores.
--   Profesor jugador conectado y de servicio  -> da él la clase
--   Nadie de servicio                          -> la da un NPC cualificado
-- Lo mismo para médicos, policías, bomberos… y para los trabajos que ya existen.

export type Role = {
	NameKey: string,
	Npc: string, -- NPC que cubre el puesto si no hay jugadores
	MaxClients: number, -- a cuántas personas puede atender un jugador a la vez
}

local Roles: { [string]: Role } = {
	-- Trabajos de la v0.1 (ya marcan quién está de servicio)
	Barista = { NameKey = "ROLE.BARISTA", Npc = "Npc_Barista", MaxClients = 4 },
	Reponedor = { NameKey = "ROLE.REPONEDOR", Npc = "Npc_Reponedor", MaxClients = 1 },
	Basurero = { NameKey = "ROLE.BASURERO", Npc = "Npc_Basurero", MaxClients = 1 },
	Repartidor = { NameKey = "ROLE.REPARTIDOR", Npc = "Npc_Repartidor", MaxClients = 1 },
	Taquillero = { NameKey = "ROLE.TAQUILLERO", Npc = "Npc_Taquillero", MaxClients = 4 },
	Recepcionista = { NameKey = "ROLE.RECEPCIONISTA", Npc = "Npc_Recepcionista", MaxClients = 3 },

	-- Roles de la campaña (fases 6 y siguientes)
	Profesor = { NameKey = "ROLE.PROFESOR", Npc = "Npc_Profesor", MaxClients = 24 },
	ProfesorUniversidad = { NameKey = "ROLE.PROFESOR_UNI", Npc = "Npc_ProfesorUni", MaxClients = 40 },
	Entrenador = { NameKey = "ROLE.ENTRENADOR", Npc = "Npc_Entrenador", MaxClients = 16 },
	Medico = { NameKey = "ROLE.MEDICO", Npc = "Npc_Medico", MaxClients = 1 },
	Policia = { NameKey = "ROLE.POLICIA", Npc = "Npc_Policia", MaxClients = 1 },
	Bombero = { NameKey = "ROLE.BOMBERO", Npc = "Npc_Bombero", MaxClients = 1 },
}

return Roles
