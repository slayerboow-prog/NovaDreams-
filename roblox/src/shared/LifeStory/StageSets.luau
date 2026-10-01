-- StageSets: los DECORADOS POR FASE de la historia. Qué se pone en el mundo (o se quita) según lo que
-- ha vivido cada jugador: el cráter que dejó la estrella fugaz, la criatura que se quedó a vivir en él,
-- un portal abierto, un cartel caído… Datos puros (los prueba scripts/test-worldmemory.luau).
--
--   Decorado = {
--     Scope    "Player": solo lo ve ese jugador; se construye en SU pantalla (Controllers/StageSetsClient).
--              "Global": de todos; lo construye el servidor una vez con TODAS sus variantes (una carpeta
--              por estado) y cada cliente enseña solo la de su historia (como SceneClient: invisible y
--              sin choque solo para ti). Así no hay un decorado por jugador.
--     Builder  cómo se dibuja: shared/StageBuilders (Crater, Resident, Marker…)
--     Place    lugar de Locations (+ Offset, como los objetos de las misiones: así coincide con ellos)
--     Position posición fija (en vez de Place), para los globales
--     Params   lo que necesita el dibujo (radio, criatura, ruta…)
--     StateFor { { If = condiciones, State = "Nombre" }, … }: la primera que se cumple decide; si ninguna,
--              el decorado no está. Las condiciones son las de siempre (Completed, Flags…) más World.
--     States   { [Estado] = parámetros extra de ese estado } (humo sí/no, brillo…)
--   }
--
-- El servidor (server/Services/WorldMemoryService) calcula el estado de cada decorado del jugador al
-- entrar, al cambiar su memoria del mundo y cada pocos segundos, y lo publica en su atributo StageSets
-- (JSON): { [id] = { S = estado, P = { x, y, z }, R = giro } }. El cliente lo dibuja o lo quita.

local Conditions = require(script.Parent.Conditions)

local StageSets = {}

local V = Vector3.new

export type SetDef = { [string]: any }

StageSets.Scopes = { Player = true, Global = true }

StageSets.Defs = {
	---------------------------------------------------------------------
	-- Saga de la Grieta · Saga_02_Grieta: tres estrellas fugaces verdes caen de la Grieta
	-- (Happenings/Cielo: Grieta_Caen). Cada una deja un cráter donde está lo que trajo.
	-- Humeante: recién caído (humo y brillo verde). Frio: ya recogiste lo que había (se queda para siempre).
	---------------------------------------------------------------------
	CraterParque = {
		Scope = "Player",
		Builder = "Crater",
		Place = "FuenteParque",
		Offset = V(-3, 0, 3),
		Params = { Radius = 3.4, Seed = 3 },
		StateFor = {
			{ If = { World = { ["Cielo.Crater.Parque"] = "Humeante" } }, State = "Humeante" },
			{ If = { World = { ["Cielo.Crater.Parque"] = "Frio" } }, State = "Frio" },
			{ If = { Completed = { "Saga_02_Grieta" } }, State = "Frio" }, -- (partidas de antes del motor)
		},
		States = { Humeante = { Smoke = true, Glow = true }, Frio = { Smoke = false, Glow = false } },
	},
	CraterPatio = {
		Scope = "Player",
		Builder = "Crater",
		Place = "JuegosColegio",
		Offset = V(3, 0, 3),
		Params = { Radius = 3, Seed = 5 },
		StateFor = {
			{ If = { World = { ["Cielo.Crater.Patio"] = "Humeante" } }, State = "Humeante" },
			{ If = { World = { ["Cielo.Crater.Patio"] = "Frio" } }, State = "Frio" },
			{ If = { Completed = { "Saga_02_Grieta" } }, State = "Frio" }, -- (partidas de antes del motor)
		},
		States = { Humeante = { Smoke = true, Glow = true }, Frio = { Smoke = false, Glow = false } },
	},
	CraterCamino = {
		Scope = "Player",
		Builder = "Crater",
		Place = "CaminoAlCole",
		Offset = V(2, 0, 2),
		Params = { Radius = 2.8, Seed = 9 },
		StateFor = {
			{ If = { World = { ["Cielo.Crater.Camino"] = "Humeante" } }, State = "Humeante" },
			{ If = { World = { ["Cielo.Crater.Camino"] = "Frio" } }, State = "Frio" },
			{ If = { Completed = { "Saga_02_Grieta" } }, State = "Frio" }, -- (partidas de antes del motor)
		},
		States = { Humeante = { Smoke = true, Glow = true }, Frio = { Smoke = false, Glow = false } },
	},
	-- Chispa, la criatura que trajo la estrella del parque, se queda a vivir en su cráter: da vueltas,
	-- se asoma y salta (una rutina). Aparece al acabar Saga_02 (Rewards.World = { ["Cielo.Chispa"] = "Parque" }).
	ChispaParque = {
		Scope = "Player",
		Builder = "Resident",
		Place = "FuenteParque",
		Offset = V(-3, 0, 3),
		Params = { Creature = "Chispa", Routine = { { 2.2, 0 }, { 0, 2.4 }, { -2.2, 0.4 }, { -0.4, -2.3 } }, Pause = 1.6 },
		StateFor = {
			{ If = { World = { ["Cielo.Chispa"] = "Parque" } }, State = "Vive" },
			{ If = { Completed = { "Saga_02_Grieta" }, NotWorld = { "Cielo.Chispa" } }, State = "Vive" }, -- (partidas de antes)
		},
		States = { Vive = {} },
	},
}

-- El estado que toca (nil = el decorado no está)
function StageSets.stateFor(def: SetDef, ctx: { [string]: any }): string?
	if def.StateFor then
		for _, rule in def.StateFor do
			if not rule.If or (Conditions.check(rule.If, ctx :: any)) then
				return rule.State
			end
		end
		return nil
	end
	if def.ShowIf == nil or (Conditions.check(def.ShowIf, ctx :: any)) then
		return "Default"
	end
	return nil
end

-- Los estados de todos los decorados de un ámbito ("Player" | "Global") para un contexto
function StageSets.resolveAll(defs: { [string]: SetDef }, ctx: { [string]: any }, scope: string?): { [string]: string }
	local out = {}
	for id, def in defs do
		if scope == nil or def.Scope == scope then
			local state = StageSets.stateFor(def, ctx)
			if state then
				out[id] = state
			end
		end
	end
	return out
end

-- Los parámetros para dibujarlo en ese estado (los del decorado + los del estado)
function StageSets.paramsFor(def: SetDef, state: string): { [string]: any }
	local out = table.clone(def.Params or {})
	for k, v in (def.States or {})[state] or {} do
		out[k] = v
	end
	return out
end

-- Errores de un decorado (ctx opcional: Places = Locations.Places, Builders = { [nombre] = true })
function StageSets.check(id: string, def: SetDef, ctx: { [string]: any }?): { string }
	local c = ctx or {}
	local errors = {}
	local function err(fmt: string, ...)
		table.insert(errors, ("decorado %s: " .. fmt):format(id, ...))
	end
	if not StageSets.Scopes[def.Scope] then
		err("Scope tiene que ser Player o Global")
	end
	if c.Builders and not c.Builders[def.Builder] then
		err("dibujo desconocido '%s'", tostring(def.Builder))
	end
	if def.Place == nil and def.Position == nil then
		err("falta Place o Position")
	end
	if def.Place and c.Places and not c.Places[def.Place] then
		err("lugar desconocido '%s'", tostring(def.Place))
	end
	if def.Scope == "Global" and def.Place then
		err("un decorado Global va en una Position fija (los lugares dependen de cada jugador)")
	end
	local states = def.States or {}
	for i, rule in def.StateFor or {} do
		if type(rule.State) ~= "string" then
			err("StateFor[%d] sin State", i)
		elseif next(states) ~= nil and states[rule.State] == nil then
			err("StateFor[%d]: estado '%s' que no está en States", i, rule.State)
		end
	end
	if def.Scope == "Global" and next(states) == nil then
		err("un decorado Global necesita States (una variante por estado)")
	end
	return errors
end

return StageSets
