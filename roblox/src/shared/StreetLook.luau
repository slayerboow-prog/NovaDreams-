-- StreetLook: qué aspecto lleva cada calle de Valmar con los materiales PBR de la Tienda que eligió el
-- dueño, y dónde van las señales y las tapas de alcantarilla del «Realistic road pack». Lo aplica en
-- vivo el servidor (World/StreetDress) justo después de cargar los packs (World/UserMaterials).
--
-- Cuentas puras (sin Instances): se prueban fuera de Roblox (scripts/test-streetlook.luau).
--
--   * Los packs de materiales ponen UN variant por material en toda la ciudad (shared/UserMaterialChoice).
--     Aquí se da variedad pieza a pieza (part.MaterialVariant) según el TIPO de calle:
--       - avenidas y autovía (y las dos grandes calles del centro): asfalto nuevo y oscuro
--       - calles de barrio: asfalto gastado, con la gravilla a la vista (y los parches de CityDetail)
--       - casco antiguo (los pueblos de San Roque y Villaverde): adoquín
--       - afueras y campo (fuera de los 6 distritos): asfalto viejo
--       - aceras: baldosa en el centro, losas de piedra en el casco y las plazas, hormigón en el campo
--   * Un variant cargado de la Tienda NO deja cambiar su BaseMaterial (probado en un servidor real).
--     Por eso cada candidato dice su BaseMaterial del doc (From) y solo se usa si coincide con el
--     material de la pieza... o si se puede cambiar el material de la pieza sin romper nada
--     (Convertible: acera Pavement -> Concrete y calzada Asphalt -> Cobblestone; el servidor le deja
--     las propiedades físicas de antes, así los coches agarran igual y nada pesa distinto).
--   * Solo se tocan la calzada y la acera (Road, Junction, Sidewalk, RingSidewalk, KerbRamp) y los
--     suelos de plaza. Las marcas viales (pintura vial), los pasos de cebra, los bordillos, las
--     medianas, los parches y las tapas siguen como están.
--   * Elección solo por NOMBRE (las texturas no se pueden mirar desde un script): cada fila dice por qué.

local CityPlan = require(script.Parent.CityPlan)

local StreetLook = {}

-- Packs que carga además de los de shared/UserMaterialChoice
StreetLook.Packs = {
	-- 27 MaterialVariant (docs/assets-usuario-3.md): el «Concrete Tile 1» de las aceras del campo y otro adoquín
	Variants = { Id = 13752145820, Short = "RPacks", Title = "Realistic Packs (27 MaterialVariant)" },
	-- Señales y alcantarillas (docs/assets-usuario-3.md). Sin el cartel c17billboard, el puente ni el GAZ-Volga
	Road = { Id = 15004077857, Short = "Vial", Title = "Realistic road pack" },
}

---------------------------------------------------------------------
-- Aspectos
---------------------------------------------------------------------

export type Candidate = { Pack: string, Name: string, From: string }
export type Look = {
	Surface: "Road" | "Walk" | "Plaza",
	Candidates: { Candidate },
	Studs: number?, -- StudsPerTile (solo si el variant es solo de las calles: no se toca el global)
	Pattern: ("Regular" | "Organic")?,
	Whiten: number, -- cuánto se aclara el color de la pieza (las texturas traen su color; ver UserMaterialChoice)
	Why: string,
}

local function c(pack: string, name: string, from: string): Candidate
	return { Pack = pack, Name = name, From = from }
end

-- Material de la pieza -> materiales a los que se puede pasar sin romper nada (sonido parecido, la
-- física se deja como estaba y ninguna prueba ni sistema mira el material de la calzada o la acera).
StreetLook.Convertible = {
	Pavement = { Concrete = true }, -- las «Pavement» de Tyler son aceras de exterior sobre Concrete
	Asphalt = { Cobblestone = true }, -- adoquín del casco antiguo
} :: { [string]: { [string]: boolean } }

-- Material que espera cada superficie
StreetLook.SurfaceMaterial = { Road = "Asphalt", Walk = "Pavement", Plaza = "Pavement" }

StreetLook.Looks = {
	Avenida = {
		Surface = "Road",
		-- El Asphalt del pack de piedras: el más realista que tenemos (el que ya puso el dueño en toda la
		-- ciudad y se ha visto bien en un servidor real). En las avenidas se aclara menos: asfalto
		-- nuevo, más oscuro, donde las marcas blancas resaltan. Respaldo: «Pebbled Asphalt» del Mega Pack.
		Candidates = { c("Real", "Asphalt", "Asphalt"), c("Mega", "Pebbled Asphalt", "Asphalt") },
		Whiten = 0.52,
		Why = "asfalto nuevo y oscuro (Asphalt del pack de piedras)",
	},
	Barrio = {
		Surface = "Road",
		-- «Pebbled Asphalt»: asfalto con la gravilla a la vista, el de una calle con años (los parches y
		-- las grietas de Kit/CityDetail siguen encima). Los «Painted…» del Mega Pack no: traen pintura
		-- en la textura (rayas falsas); los «Lab» son de colores. Orgánico: sin repetición visible.
		Candidates = { c("Mega", "Pebbled Asphalt", "Asphalt"), c("Mega", "Rocky Asphalt", "Asphalt") },
		Studs = 14,
		Pattern = "Organic",
		Whiten = 0.64,
		Why = "asfalto gastado con gravilla (Pebbled Asphalt)",
	},
	Campo = {
		Surface = "Road",
		-- «Rocky Asphalt»: asfalto viejo con la piedra suelta, el de una carretera comarcal. Más claro
		-- (descolorido por el sol).
		Candidates = { c("Mega", "Rocky Asphalt", "Asphalt"), c("Mega", "Pebbled Asphalt", "Asphalt") },
		Studs = 16,
		Pattern = "Organic",
		Whiten = 0.72,
		Why = "asfalto viejo de carretera comarcal (Rocky Asphalt)",
	},
	Casco = {
		Surface = "Road",
		-- «Cobblestone Curved»: adoquín colocado en abanico, el de las calles de los cascos antiguos
		-- mediterráneos. Respaldos: «CobblestoneRoad…» (adoquín de calzada), el de Realistic Packs y el
		-- del pack de piedras. Van sobre Cobblestone: la calzada pasa a Cobblestone (física de asfalto).
		Candidates = {
			c("Mega", "Cobblestone Curved", "Cobblestone"),
			c("Mega", "CobblestoneRoad RoughBumpyRockyMaterial", "Cobblestone"),
			c("RPacks", "Cobblestone", "Cobblestone"),
			c("Real", "Cobblestone", "Cobblestone"),
		},
		Studs = 12,
		Whiten = 0.62,
		Why = "adoquín en abanico del casco antiguo (Cobblestone Curved)",
	},
	AceraCentro = {
		Surface = "Walk",
		-- «Pavement2» de Tyler: baldosa de acera de exterior con juntas, 10 studs (la que el dueño eligió
		-- primero para las aceras; va sobre Concrete y no se le puede cambiar: la acera pasa a Concrete).
		Candidates = { c("Tyler", "Pavement2", "Concrete"), c("Tyler", "Pavement6", "Concrete") },
		Pattern = "Regular",
		Whiten = 0.45,
		Why = "baldosa de acera del centro (Pavement2 de Tyler)",
	},
	AceraBarrio = {
		Surface = "Walk",
		-- Otra baldosa de exterior de Tyler, más grande (13 studs): que la acera del barrio no sea la del centro
		Candidates = { c("Tyler", "Pavement3", "Concrete"), c("Tyler", "Pavement9", "Concrete") },
		Pattern = "Regular",
		Whiten = 0.45,
		Why = "baldosa de acera de barrio (Pavement3 de Tyler)",
	},
	AceraCasco = {
		Surface = "Walk",
		-- «Stone Tiles» del Mega Pack: losas de piedra (va sobre Pavement: sin cambiar nada)
		Candidates = { c("Mega", "Stone Tiles", "Pavement"), c("Tyler", "Pavement4", "Concrete") },
		Whiten = 0.4,
		Why = "losas de piedra del casco antiguo (Stone Tiles)",
	},
	AceraCampo = {
		Surface = "Walk",
		-- Losas de hormigón («Concrete Tile 1»), las de las aceras de las afueras. Respaldo: el mismo del
		-- Mega Pack y el hormigón del pack de piedras.
		Candidates = { c("RPacks", "Concrete Tile 1", "Concrete"), c("Mega", "Concrete Tile 1", "Concrete"), c("Real", "Concrete", "Concrete") },
		Whiten = 0.4,
		Why = "losas de hormigón de las afueras (Concrete Tile 1)",
	},
	Plaza = {
		Surface = "Plaza",
		-- Plazas: las mismas losas de piedra que el casco (Stone Tiles); respaldo, las losas grandes de Tyler
		Candidates = { c("Mega", "Stone Tiles", "Pavement"), c("Tyler", "Pavement4", "Concrete") },
		Whiten = 0.35,
		Why = "losas de piedra de plaza (Stone Tiles)",
	},
} :: { [string]: Look }

-- Nombres de pieza que se visten (por superficie). Lo demás (Marking, Zebra, Curb, RoadKerb,
-- AsphaltPatch, Manhole, Median…) nunca se toca.
StreetLook.Names = {
	Road = "Road",
	Junction = "Road",
	Sidewalk = "Walk",
	RingSidewalk = "Walk",
	KerbRamp = "Walk",
	PlazaFloor = "Plaza",
	Plaza = "Plaza",
} :: { [string]: string }

-- Carpetas de calles (las piezas de Road/Sidewalk de otros sitios, como el aeropuerto, no se tocan)
StreetLook.Containers = { Streets = true, MainRoads = true }

---------------------------------------------------------------------
-- Zonas y tipos de calle
---------------------------------------------------------------------

-- Casco antiguo: los pueblos de estilo «Popular» (World/Region): San Roque y Villaverde, hasta su
-- calle de circunvalación (a 380 del centro).
StreetLook.OldTowns = { "San Roque", "Villaverde" }
StreetLook.OLD_HALF = 384

-- Distritos con aceras de baldosa de centro (el resto de distritos: barrio)
StreetLook.Downtown = { Centro = true, Este = true }

function StreetLook.zoneAt(x: number, z: number): string
	for _, name in StreetLook.OldTowns do
		local p = CityPlan.Towns[name]
		if p and math.abs(x - p[1]) <= StreetLook.OLD_HALF and math.abs(z - p[2]) <= StreetLook.OLD_HALF then
			return "Casco"
		end
	end
	local d = CityPlan.districtAt(x, z)
	if not d then
		return "Campo"
	end
	return if StreetLook.Downtown[d.Id] then "Centro" else "Barrio"
end

-- Tipo (Autovia, Avenida, Calle) de la carretera principal más cercana (CityPlan.Roads) y su distancia
function StreetLook.mainKindAt(x: number, z: number): (string?, number)
	local best, kind = math.huge, nil
	for _, road in CityPlan.Roads do
		for i = 1, #road.Points - 1 do
			local a, b = road.Points[i], road.Points[i + 1]
			local d = CityPlan.segmentDistance(x, z, a[1], a[2], b[1], b[2])
			if d < best then
				best, kind = d, road.Kind
			end
		end
	end
	return kind, best
end

export type Line = { Axis: string, At: number, From: number, To: number }

-- ¿Está en una de las calles grandes de la cuadrícula (World/Region.Highways)?
function StreetLook.onHighway(x: number, z: number, highways: { Line }?): boolean
	for _, h in highways or {} do
		local u = if h.Axis == "X" then x else z
		local w = if h.Axis == "X" then z else x
		if math.abs(w - h.At) <= 20.5 and u >= h.From - 20 and u <= h.To + 20 then
			return true
		end
	end
	return false
end

export type PartInfo = {
	Name: string,
	Material: string, -- Enum.Material.Name
	Variant: string?, -- MaterialVariant que ya lleva ("" o nil = ninguno)
	Container: string?, -- "Streets", "MainRoads" u otra cosa (carpeta de calles en la que está)
	X: number,
	Z: number,
}

-- Qué aspecto lleva una pieza (nil = no se toca)
function StreetLook.classify(info: PartInfo, highways: { Line }?): string?
	local surface = StreetLook.Names[info.Name]
	if not surface or (info.Variant ~= nil and info.Variant ~= "") then
		return nil
	end
	if info.Material ~= StreetLook.SurfaceMaterial[surface] then
		return nil
	end
	if surface == "Plaza" then
		return "Plaza"
	end
	if not (info.Container and StreetLook.Containers[info.Container]) then
		return nil
	end
	local zone = StreetLook.zoneAt(info.X, info.Z)
	if surface == "Walk" then
		if zone == "Casco" then
			return "AceraCasco"
		elseif zone == "Campo" then
			return "AceraCampo"
		elseif zone == "Centro" then
			return "AceraCentro"
		end
		return "AceraBarrio"
	end
	-- Calzada
	if info.Container == "MainRoads" then
		local kind = StreetLook.mainKindAt(info.X, info.Z)
		if kind ~= "Calle" then
			return "Avenida" -- (autovía, avenidas y sus rotondas)
		end
	elseif StreetLook.onHighway(info.X, info.Z, highways) then
		return "Avenida"
	end
	if zone == "Casco" then
		return if info.Container == "Streets" then "Casco" else "Barrio"
	elseif zone == "Campo" then
		return "Campo"
	end
	return "Barrio"
end

---------------------------------------------------------------------
-- Elección del variant
---------------------------------------------------------------------

-- ¿Puede una pieza de este material llevar un variant de este BaseMaterial?
function StreetLook.canUse(partMaterial: string, variantBase: string): boolean
	if partMaterial == variantBase then
		return true
	end
	local list = StreetLook.Convertible[partMaterial]
	return list ~= nil and list[variantBase] == true
end

-- Candidatos de un aspecto que se pueden usar, en orden. available[pack][nombre] = BaseMaterial del
-- variant cargado (el de verdad, no el del doc).
function StreetLook.candidates(key: string, available: { [string]: { [string]: string } }): { Candidate }
	local look = StreetLook.Looks[key]
	local out = {}
	if not look then
		return out
	end
	local material = StreetLook.SurfaceMaterial[look.Surface]
	for _, cand in look.Candidates do
		local pack = available[cand.Pack]
		local base = pack and pack[cand.Name]
		if base and StreetLook.canUse(material, base) then
			table.insert(out, { Pack = cand.Pack, Name = cand.Name, From = base })
		end
	end
	return out
end

---------------------------------------------------------------------
-- Señales y alcantarillas (Realistic road pack)
---------------------------------------------------------------------

-- Imágenes de los Decals del pack (docs/assets-usuario-3.md: se han mirado)
StreetLook.Decals = {
	Stop = 8612134288,
	Peatones = 8615143034,
	Velocidad30 = 8612136088,
	Velocidad20 = 8615141417,
	Manhole = 264036689, -- tapa «STORM DRAIN»
	Drain = 2472723275, -- rejilla
} :: { [string]: number }

-- Del pack no se usa nada más (y esto nunca): cartel de City 17 y puente de Half-Life 2, coche de marca real
StreetLook.Banned = { "c17billboard", "canal_bridge", "bridge_railing", "handrail", "GAZ", "Volga" }

function StreetLook.banned(name: string): boolean
	local low = string.lower(name)
	for _, word in StreetLook.Banned do
		if string.find(low, string.lower(word), 1, true) then
			return true
		end
	end
	return false
end

-- ¿De qué señal es esta imagen? (Texture = "rbxassetid://…" o "http://www.roblox.com/asset/?id=…")
function StreetLook.decalKind(texture: string): string?
	local id = tonumber(string.match(texture, "(%d+)%s*$") or "")
	if not id then
		return nil
	end
	for kind, n in StreetLook.Decals do
		if n == id then
			return kind
		end
	end
	return nil
end

-- Topes (móviles): cuántas de cada cosa como mucho en toda la ciudad
StreetLook.Caps = { Stop = 60, Peatones = 40, Velocidad = 40, Manhole = 220, Drain = 120 }

-- Medidas de las señales (studs: una persona ~5)
StreetLook.SIGN_SIZE = 2.4 -- la placa
StreetLook.SIGN_HEIGHT = 6.6 -- centro de la placa sobre la acera
StreetLook.POLE = 0.26 -- grosor del poste
-- Forma del respaldo metálico (detrás de la imagen, un poco más pequeño para que no asome)
StreetLook.Backing = { Stop = { Disc = true, Size = 2.12 }, Velocidad30 = { Disc = true, Size = 2.1 }, Velocidad20 = { Disc = true, Size = 2.1 }, Peatones = { Disc = false, Size = 2.2 } }

-- Azar fijo según el sitio (0..1)
function StreetLook.hash(x: number, z: number, salt: number): number
	local v = math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	v -= math.floor(v)
	local w = math.sin(v * 91.345 + salt * 3.117 + x * 0.013) * 24634.6345
	return w - math.floor(w)
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- A la derecha de quien va en dirección d (X = este, Z = sur: mirando al norte, la derecha es el este)
function StreetLook.rightOf(d: Vector3): Vector3
	return Vector3.new(-d.Z, 0, d.X)
end

export type Crossing = { Center: Vector3, WalkDir: Vector3, Length: number, Depth: number }
export type Sign = { Kind: string, Position: Vector3, Facing: Vector3, Group: string }

-- ¿p cae dentro de un paso de cebra (con margen)?
function StreetLook.inCrossing(p: Vector3, crossings: { Crossing }, margin: number): boolean
	for _, cr in crossings do
		local d = flat(p - cr.Center)
		local w = flat(cr.WalkDir).Unit
		local a = math.abs(d:Dot(w))
		local b = math.abs(d:Dot(StreetLook.rightOf(w)))
		if a <= cr.Length / 2 + margin and b <= cr.Depth / 2 + margin then
			return true
		end
	end
	return false
end

-- Señales de una boca (calle que desemboca en otra sin semáforo, Kit/Bocacalles). El paso de cebra va
-- por la acera de la calle que recibe (WalkDir = a lo largo de ella); la calle que llega sale hacia
-- fuera (out). probe(p) -> "Streets" | "MainRoads" | nil: qué acera hay en p (nil = no es acera).
--   * STOP: para quien sale de la calle que llega, a su derecha, justo antes del paso de cebra
--   * Paso de peatones: para quien va por la calle que recibe, en su acera, antes del paso
--   * 30 (20 en el casco antiguo): al entrar en una calle de barrio, a la derecha
-- Si out no se sabe (nil) se prueban los dos lados: el bueno es el que tiene acera para el STOP.
function StreetLook.mouthSigns(cr: Crossing, probe: (Vector3) -> string?, out: Vector3?): { Sign }
	local w = flat(cr.WalkDir).Unit
	local tries = if out then { flat(out).Unit } else { StreetLook.rightOf(w), -StreetLook.rightOf(w) }
	for _, o in tries do
		local signs: { Sign } = {}
		local inward = -o
		-- STOP
		local stop = cr.Center + o * (cr.Depth / 2 + 2) + StreetLook.rightOf(inward) * (cr.Length / 2 + 1.2)
		local arriving = probe(stop)
		if arriving then
			table.insert(signs, { Kind = "Stop", Position = flat(stop), Facing = o, Group = "Stop" })
			-- Paso de peatones, para quien circula por la calle que recibe pegado a esta acera
			local t = Vector3.new(o.Z, 0, -o.X) -- (su derecha es o)
			local walk = cr.Center - t * (cr.Length / 2 + 2.5) - o * (cr.Depth / 2 - 1.1)
			if probe(walk) then
				table.insert(signs, { Kind = "Peatones", Position = flat(walk), Facing = -t, Group = "Peatones" })
			end
			-- Límite de velocidad al entrar en una calle de barrio
			if arriving == "Streets" then
				local zone = StreetLook.zoneAt(cr.Center.X, cr.Center.Z)
				if zone ~= "Campo" then
					local speed = cr.Center + o * (cr.Depth / 2 + 14) + StreetLook.rightOf(o) * (cr.Length / 2 + 1.2)
					if probe(speed) == "Streets" then
						table.insert(signs, { Kind = if zone == "Casco" then "Velocidad20" else "Velocidad30", Position = flat(speed), Facing = -o, Group = "Velocidad" })
					end
				end
			end
			return signs
		end
	end
	return {}
end

export type Obstacle = { Position: Vector3, Radius: number }

-- ¿Hay sitio en p? (lejos de farolas, semáforos, paradas, bancos, árboles, puertas… y de los pasos)
function StreetLook.clear(p: Vector3, obstacles: { Obstacle }, crossings: { Crossing }, margin: number): boolean
	for _, ob in obstacles do
		local d = flat(p - ob.Position).Magnitude
		if d < ob.Radius + margin then
			return false
		end
	end
	return not StreetLook.inCrossing(p, crossings, margin)
end

-- Reparto fijo por toda la ciudad: como mucho cap, elegidos por el azar de su sitio (no los primeros
-- que salen: así no se juntan todos en un barrio). list: cosas con Position.
function StreetLook.spread<T>(list: { T }, cap: number, salt: number?): { T }
	local keyed = {}
	for i, item in list do
		local p = (item :: any).Position
		table.insert(keyed, { Item = item, Key = StreetLook.hash(p.X, p.Z, salt or 7) + i * 1e-9 })
	end
	table.sort(keyed, function(a, b)
		return a.Key < b.Key
	end)
	local out = {}
	for i = 1, math.min(cap, #keyed) do
		table.insert(out, keyed[i].Item)
	end
	return out
end

-- Rejilla para buscar obstáculos cercanos deprisa
local CELL = 16
function StreetLook.grid(obstacles: { Obstacle }): { [string]: { Obstacle } }
	local cells = {}
	for _, ob in obstacles do
		local r = ob.Radius + 3 -- (con el margen de StreetLook.clear)
		local x0, x1 = math.floor((ob.Position.X - r) / CELL), math.floor((ob.Position.X + r) / CELL)
		local z0, z1 = math.floor((ob.Position.Z - r) / CELL), math.floor((ob.Position.Z + r) / CELL)
		for gx = x0, x1 do
			for gz = z0, z1 do
				local k = gx .. ":" .. gz
				cells[k] = cells[k] or {}
				table.insert(cells[k], ob)
			end
		end
	end
	return cells
end

function StreetLook.near(cells: { [string]: { Obstacle } }, p: Vector3): { Obstacle }
	return cells[math.floor(p.X / CELL) .. ":" .. math.floor(p.Z / CELL)] or {}
end

return StreetLook
