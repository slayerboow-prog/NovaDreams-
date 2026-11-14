-- Derelicts: los PECIOS de la Deriva (naves abandonadas que se recorren a pie; expansión «La Deriva»,
-- docs/espacio-aaa/expansion-15h.md §4.C). Cuentas puras: las usan el servidor (Services/DerivaService y
-- World/DerelictBuilder), el cliente (Controllers/DerelictClient: linterna y luces) y las pruebas
-- (scripts/test-deriva.luau).
--
-- Primer pecio: la MISERICORDIA, nave hospital de Ovilla (la luna de Tefra, tras la guerra). Flota en la
-- columna del espacio, lejos de estaciones y campos. Se atraca en su esclusa (aro azul) como en una
-- estación: te bajas y andas por dentro (gravedad de emergencia). Por dentro, una cubierta con pasillo
-- central, salas a los lados y el puente al fondo:
--
--        x = -140 ············································· +140
--   z-28 ┌ PUENTE ┬── TRIAJE ──┬─── ALMACÉN ───┬── COMUNICACIONES ──┐
--        │ (puerta│  fusible 1  │               │                    │
--   z -6 │  sin   ├──·──────────┴──·──────╫─────┴─────────·──────────┤  ╫ = barrera láser
--        │ luz)   │  ═════════ PASILLO CENTRAL ═════════════════════ │
--   z +6 │        ├──────·──────┬─────────╫────·────────┬─────·──────┤
--        │        │  ESCLUSA    │   CUARENTENA          │  MÁQUINAS  │
--   z+28 └────────┴─(entrada)───┴── fusible 2 ──────────┴ fusible 3 ─┘ (chispas)
--
-- Coordenadas LOCALES: X a lo largo de la nave, Z de lado, Y hacia arriba; (0, 0, 0) es el suelo en el
-- centro de la cubierta. Derelicts.world(d, v) las pasa al mundo.

local Derelicts = {}

export type Box = { C: Vector3, S: Vector3 } -- centro y tamaño (local)
export type Spot = { Id: string, Name: string, P: Vector3, Radius: number? }

local V = Vector3.new

Derelicts.Misericordia = {
	Id = "Misericordia",
	Name = "Misericordia",
	Title = "La Misericordia, nave hospital de Ovilla",
	Origin = V(-4800, 6600, 4400), -- el suelo de la cubierta, en el centro (mundo)
	Deck = { HalfX = 140, HalfZ = 28, Height = 16, Wall = 2 },
	-- El casco por fuera (para que la nave choque y no lo atraviese): una caja que envuelve la cubierta,
	-- más la sala de máquinas de popa
	Hull = {
		{ C = V(0, 8, 0), S = V(300, 26, 66) },
		{ C = V(170, 6, 0), S = V(44, 30, 50) },
	},
	-- La esclusa: el aro de fuera donde se atraca y dónde apareces dentro
	Dock = V(0, 6, 64), -- (fuera del casco, por el lado de la esclusa)
	DockRadius = 70,
	ApproachRadius = 900, -- desde aquí, «has llegado»
	Entry = V(0, 3, 18), -- dentro, en la esclusa
	EntryLook = V(0, 0, -1),
	Launch = V(0, 6, 120), -- dónde sale tu nave al volver (fuera, mirando hacia fuera)
	LaunchLook = V(0, 0, 1),
	-- Salas (para el constructor, las luces y saber en qué sala estás)
	Rooms = {
		{ Id = "Enfermeria", Name = "Enfermería", C = V(-66, 0, 17), S = V(92, 0, 22), Door = V(-66, 0, 6), Fuse = 1 },
		{ Id = "Esclusa", Name = "Esclusa", C = V(0, 0, 17), S = V(40, 0, 22), Door = V(0, 0, 6), Fuse = 0 },
		{ Id = "Cuarentena", Name = "Cuarentena", C = V(57.5, 0, 17), S = V(75, 0, 22), Door = V(57.5, 0, 6), Fuse = 2 },
		{ Id = "Maquinas", Name = "Máquinas", C = V(117.5, 0, 17), S = V(45, 0, 22), Door = V(117.5, 0, 6), Fuse = 3 },
		{ Id = "Triaje", Name = "Triaje", C = V(-70, 0, -17), S = V(84, 0, 22), Door = V(-70, 0, -6), Fuse = 1 },
		{ Id = "Almacen", Name = "Almacén", C = V(16, 0, -17), S = V(88, 0, 22), Door = V(16, 0, -6), Fuse = 2 },
		{ Id = "Comunicaciones", Name = "Comunicaciones", C = V(100, 0, -17), S = V(80, 0, 22), Door = V(100, 0, -6), Fuse = 3 },
		{ Id = "Pasillo", Name = "Pasillo", C = V(14, 0, 0), S = V(252, 0, 12), Door = nil, Fuse = 0 },
		{ Id = "Puente", Name = "Puente", C = V(-126, 0, 0), S = V(28, 0, 56), Door = V(-112, 0, 0), Fuse = 3 },
	},
	-- Tabiques entre salas (x) a cada lado del pasillo
	Dividers = { South = { -20, 20, 95 }, North = { -28, 60 } },
	BridgeX = -112,
	-- Los tres fusibles (restaurar la corriente) y su sala
	Fuses = {
		{ N = 1, Room = "Triaje", P = V(-104, 3, -24) },
		{ N = 2, Room = "Cuarentena", P = V(50, 3, 24) }, -- (delante de la mampara precintada)
		{ N = 3, Room = "Maquinas", P = V(132, 3, 22) },
	},
	-- Puerta del puente: cerrada hasta que vuelve la corriente
	BridgeDoor = { C = V(-112, 0, 0), HalfZ = 6 },
	-- Barreras láser del sistema de seguridad (siguen activas): cruzan el pasillo
	Lasers = {
		{ X = -40, Phase = 0 },
		{ X = 46, Phase = 1.6 },
	},
	LaserOn = 2.2, -- segundos encendida
	LaserOff = 1.8, -- segundos apagada (para cruzar)
	LaserDamage = 20,
	-- Chispas en Máquinas: cada SparkEvery s, aviso SparkWarn s antes y daño si estás dentro
	Sparks = { C = V(118, 0, 18), Radius = 9, Every = 4.5, Warn = 1.1, Damage = 15 },
	MinHealth = 15, -- nada de lo que hay dentro te deja por debajo de esto
	-- Registros que se leen (los tres cuentan los últimos días de la nave)
	Logs = {
		{ Id = "Triaje", Room = "Triaje", P = V(-40, 3, -24), Scene = "Deriva_Registro_Triaje" },
		{ Id = "Cuarentena", Room = "Cuarentena", P = V(36, 3, 24), Scene = "Deriva_Registro_Cuarentena" },
		{ Id = "Comunicaciones", Room = "Comunicaciones", P = V(128, 3, -24), Scene = "Deriva_Registro_Comunicaciones" },
	},
	Core = V(-137.5, 4.6, 0), -- el núcleo de datos, encima de la consola del puente
	Exit = V(0, 3, 22), -- «Volver a la nave», en la esclusa
	-- Sitios de la historia (marcas StorySpot que pone World/DerelictBuilder: Locations «Deriva_<Id>»)
	Spots = {
		{ Id = "Esclusa", Name = "La esclusa de la Misericordia", P = V(0, 0, 16), Radius = 10 },
		{ Id = "Pasillo", Name = "El pasillo de la Misericordia", P = V(-20, 0, 0), Radius = 10 },
		{ Id = "Triaje", Name = "La sala de triaje", P = V(-70, 0, -17), Radius = 12 },
		{ Id = "Puente", Name = "El puente de la Misericordia", P = V(-126, 0, 0), Radius = 10 },
		{ Id = "Holograma", Name = "El último registro", P = V(-129, 0, 0), Radius = 6 },
	},
	-- Hilanderos que esperan fuera al salir con el núcleo
	AmbushKinds = { "Aguja", "Aguja", "Interceptor" },
	AmbushRadius = 420,
	DeliverStation = "Alba",
}

Derelicts.List = { Derelicts.Misericordia }

-- Local → mundo (sin giro: la nave está alineada con los ejes)
function Derelicts.world(d: any, v: Vector3): Vector3
	return d.Origin + v
end

-- Mundo → local
function Derelicts.toLocal(d: any, p: Vector3): Vector3
	return p - d.Origin
end

-- ¿Toca una esfera (pos, radio) el casco de algún pecio? (para que la nave choque: shared/Cosmos/Zone)
function Derelicts.hullHit(pos: Vector3, radius: number): any?
	for _, d in Derelicts.List do
		local l = pos - d.Origin
		if l.Magnitude < 260 + radius then
			for _, box in d.Hull do
				local h = box.S / 2
				local q = l - box.C
				local out = Vector3.new(math.max(math.abs(q.X) - h.X, 0), math.max(math.abs(q.Y) - h.Y, 0), math.max(math.abs(q.Z) - h.Z, 0))
				if out.Magnitude <= radius then
					return d
				end
			end
		end
	end
	return nil
end

-- ¿Está la nave en el aro de la esclusa de algún pecio?
function Derelicts.dockAt(pos: Vector3): any?
	for _, d in Derelicts.List do
		if (pos - Derelicts.world(d, d.Dock)).Magnitude <= d.DockRadius then
			return d
		end
	end
	return nil
end

-- ¿Está una persona dentro de la cubierta? (con margen)
function Derelicts.inside(d: any, p: Vector3, margin: number?): boolean
	local l = p - d.Origin
	local m = margin or 0
	return math.abs(l.X) <= d.Deck.HalfX + m and math.abs(l.Z) <= d.Deck.HalfZ + m and l.Y >= -4 - m and l.Y <= d.Deck.Height + 6 + m
end

-- La sala donde está (local)
function Derelicts.roomAt(d: any, p: Vector3): string?
	local l = p - d.Origin
	for _, r in d.Rooms do
		if math.abs(l.X - r.C.X) <= r.S.X / 2 and math.abs(l.Z - r.C.Z) <= r.S.Z / 2 then
			return r.Id
		end
	end
	return nil
end

-- ¿Está encendida la barrera láser i en el instante t? (la misma cuenta en el servidor y en el cliente:
-- t es la hora del servidor, workspace:GetServerTimeNow)
function Derelicts.laserOn(d: any, i: number, t: number): boolean
	local L = d.Lasers[i]
	if not L then
		return false
	end
	local cycle = d.LaserOn + d.LaserOff
	local k = (t + L.Phase) % cycle
	return k < d.LaserOn
end

-- ¿Cruza una persona la barrera i? (franja estrecha a lo ancho del pasillo)
function Derelicts.inLaser(d: any, i: number, p: Vector3): boolean
	local L = d.Lasers[i]
	local l = p - d.Origin
	return L ~= nil and math.abs(l.X - L.X) <= 1.6 and math.abs(l.Z) <= 6.5 and l.Y < 12
end

-- Chispas: "Warn" (aviso), "Burst" (daño) o nil
function Derelicts.sparkState(d: any, t: number): string?
	local S = d.Sparks
	local k = t % S.Every
	if k >= S.Every - S.Warn then
		return "Warn"
	elseif k < 0.5 then
		return "Burst"
	end
	return nil
end

-- El daño que se aplica sin bajar de MinHealth (nadie muere dentro)
function Derelicts.damageFor(d: any, health: number, amount: number): number
	return math.max(0, math.min(amount, health - d.MinHealth))
end

---------------------------------------------------------------------
-- La misión «La nave hospital» (shared/LifeStory/Misiones/Deriva_ActoI) y su progreso
---------------------------------------------------------------------
Derelicts.MissionId = "Deriva_01_Misericordia"
-- Los pasos del motor de historia, en orden (Fuses es un grupo de 3; Entrada y Registro son cinemáticas)
Derelicts.Steps = { "Approach", "Board", "Entrada", "Fuses", "Bridge", "Registro", "Core", "Launch", "Ambush", "Delivered" }

export type Phase = { Step: string, Index: number, Fuses: { [number]: boolean } }

-- En qué paso está (story = data.Story) o nil
function Derelicts.phaseOf(story: { [string]: any }?): Phase?
	local active = story and story.Active
	local prog = type(active) == "table" and active[Derelicts.MissionId] or nil
	if type(prog) ~= "table" then
		return nil
	end
	local idx = math.floor(tonumber(prog.Step) or 1)
	local step = Derelicts.Steps[idx]
	if not step then
		return nil
	end
	-- (los fusibles hechos: el motor guarda los sub-pasos del grupo en Sub = { [i] = true })
	local fuses = {}
	local sub = type(prog.Sub) == "table" and prog.Sub or (type(prog.Group) == "table" and prog.Group) or {}
	for i = 1, 3 do
		fuses[i] = sub[i] == true or sub[tostring(i)] == true
	end
	return { Step = step, Index = idx, Fuses = fuses }
end

-- Cuántos fusibles lleva (para las luces y la puerta del puente)
function Derelicts.power(phase: Phase?): number
	if not phase then
		return 0
	end
	local fusesIdx = table.find(Derelicts.Steps, "Fuses") :: number
	if phase.Index > fusesIdx then
		return 3
	end
	if phase.Index < fusesIdx then
		return 0
	end
	local n = 0
	for i = 1, 3 do
		if phase.Fuses[i] then
			n += 1
		end
	end
	return n
end

-- ¿Se le ofrece la misión al atracar? (después del prólogo de Varkun; una vez)
function Derelicts.offer(story: { [string]: any }?): boolean
	if not story or type(story.Completed) ~= "table" then
		return false
	end
	if story.Completed[Derelicts.MissionId] or (type(story.Active) == "table" and story.Active[Derelicts.MissionId]) then
		return false
	end
	return story.Completed["Varkun_02_Escarcha"] ~= nil
end

-- La fila de misión del HUD de la nave: { Title, Progress, Target, TargetName }
function Derelicts.row(phase: Phase?, stationDock: Vector3?): { [string]: any }?
	if not phase then
		return nil
	end
	local d = Derelicts.Misericordia
	local title = "✚ La nave hospital"
	local s = phase.Step
	if s == "Approach" then
		return { Title = title, Progress = "Sigue la baliza médica", Target = Derelicts.world(d, d.Dock), TargetName = d.Name }
	elseif s == "Board" then
		return { Title = title, Progress = "Atraca en la esclusa (aro azul)", Target = Derelicts.world(d, d.Dock), TargetName = "Esclusa" }
	elseif s == "Ambush" then
		return { Title = title, Progress = "Derriba a los Hilanderos", Target = Derelicts.world(d, d.Dock), TargetName = d.Name }
	elseif s == "Delivered" then
		return { Title = title, Progress = "Lleva el núcleo a Alba", Target = stationDock, TargetName = "Estación Alba" }
	elseif s == "Launch" then
		return { Title = title, Progress = "Vuelve a tu nave por la esclusa", Target = Derelicts.world(d, d.Dock), TargetName = "Esclusa" }
	end
	return { Title = title, Progress = "Dentro de la Misericordia", Target = Derelicts.world(d, d.Dock), TargetName = d.Name }
end

return Derelicts
