-- Auditoría de COHERENCIA DEL MAPA, con Lune, sobre el mapa ya construido (docs/mapa/revision/revision-mapa.md).
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
--   lune run scripts/test-mapcoherence.luau X.rbxl [--json SALIDA.json] [--list] [--top N]
--
--   --json   escribe todos los problemas (con coordenadas) para dibujarlos encima de la vista cenital:
--            python3 scripts/map/vista_cenital.py DIR/parts.tsv SALIDA.png --issues SALIDA.json --heat
--   --list   imprime todos los problemas, no solo el resumen
--
-- Busca en TODA la isla (Town del archivo):
--   1. CALLES  trozos de calzada sueltos (no unidos a la red: componentes conexos de la calzada de
--              Streets y MainRoads) y calles cortadas (un extremo de la calzada que no sigue en otra
--              calle, rotonda o carretera: «calle que no va a ninguna parte»; si acaba DENTRO de una
--              manzana, es crítico)
--   2. ACCESO  edificios, casas, negocios, aparcamientos, pistas y sitios sin calle ni acera cerca
--   3. SOLAPES edificios metidos unos dentro de otros, suelos de un uso encima de otro (parque sobre
--              aparcamiento, aparcamiento bajo un edificio…), cosas encima de la calzada
--   4. MANZANAS manzanas con demasiado construido para su distrito o con usos que no pegan juntos
--              (casas + torres + aparcamiento + pista en una manzana pequeña)
--   5. ZONAS VERDES / OCIO  los sitios de zonas verdes y de ocio (parques vivos, Jardines de la Plaza
--              Mayor, huertos, lago, camping, mercadillo, vóley playa, polideportivo, karting,
--              skatepark) y el puerto espacial del islote y el portal de la playa: ni sobre calles ni
--              dentro de manzanas ajenas
--
-- Gravedad (umbrales en la sección UMBRALES, explicados en docs/mapa/revision/revision-mapa.md):
--   crítico  rompe el mapa (la prueba falla si hay alguno)
--   aviso    raro pero aceptable (se informa)
--   info     curiosidad (solo con --list)

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("./lib/ModuleLoader")
local Enum = roblox.Enum

local placePath = process.args[1]
if not placePath or string.sub(placePath, 1, 2) == "--" then
	print("Uso: lune run scripts/test-mapcoherence.luau X.rbxl [--json SALIDA.json] [--list] [--top N]")
	process.exit(1)
end
local function argValue(flag: string): string?
	local i = table.find(process.args, flag)
	return if i then process.args[i + 1] else nil
end
local JSON_OUT = argValue("--json")
local LIST = table.find(process.args, "--list") ~= nil
local TOP = tonumber(argValue("--top") or "20") :: number

local CityPlan = L.load("src/shared/CityPlan")
local OcioSitios = L.load("src/shared/OcioSitios")
local Access = L.load("src/shared/Cosmos/Access")

---------------------------------------------------------------------
-- UMBRALES
---------------------------------------------------------------------
local U = {
	ROAD_CELL = 4, -- rejilla de la calzada (studs)
	FRAGMENT_CRIT = 0.25, -- trozo suelto de calzada: crítico si no es parte de la red (salvo islas)
	ACCESS_WARN = 22, -- studs desde el borde de un edificio a la acera/calzada más cercana: aviso
	ACCESS_CRIT = 30, -- … y crítico
	OVERLAP_MIN = 30, -- studs² de solape entre dos edificios para contarlo
	OVERLAP_CRIT = 120, -- studs² (o un 15 % del más pequeño): crítico
	OVERLAP_FRAC = 0.15,
	ROAD_INTRUSION_CRIT = 48, -- studs² de calzada tapados por un edificio o el suelo de un sitio
	SURFACE_OVERLAP_MIN = 150, -- studs² de suelo de un uso sobre el de otro (parque sobre aparcamiento…)
	SURFACE_OVERLAP_CRIT = 600,
	COVERAGE_CRIT = 0.72, -- parte de la manzana ocupada por edificios: crítico
	COVERAGE_RATIO = 2.0, -- más del doble de lo normal en su distrito (y > COVERAGE_MIN): aviso
	COVERAGE_MIN = 0.45,
	MIX_SMALL = 260 * 260, -- una manzana «pequeña» (studs²): 4 usos fuertes en ella es crítico
	SITE_BLOCK_CRIT = 150, -- studs² de un sitio verde/ocio metidos en una manzana ajena
}

---------------------------------------------------------------------
-- Problemas
---------------------------------------------------------------------
type Issue = { kind: string, severity: string, x: number, z: number, r: number, district: string, msg: string }
local issues: { Issue } = {}

local TOWN_HALF = 400
local function districtName(x: number, z: number): string
	for name, c in CityPlan.Towns do
		if math.abs(x - c[1]) < TOWN_HALF and math.abs(z - c[2]) < TOWN_HALF and name ~= "Valmar Centro" then
			return name
		end
	end
	if math.abs(x) < 420 and z > -262 and z < 300 then
		return "Valmar Centro"
	end
	local d = CityPlan.districtAt(x, z)
	return if d then d.Name else "Fuera de los distritos"
end

local function add(kind: string, severity: string, x: number, z: number, r: number, msg: string)
	table.insert(issues, { kind = kind, severity = severity, x = math.floor(x + 0.5), z = math.floor(z + 0.5), r = math.floor(r + 0.5), district = districtName(x, z), msg = msg })
end

---------------------------------------------------------------------
-- Geometría en planta
---------------------------------------------------------------------
type OBB = { cx: number, cz: number, ax: number, az: number, bx: number, bz: number, ha: number, hb: number }
-- (eje a = (ax, az) con media longitud ha; eje b = (bx, bz) perpendicular, media longitud hb)

local function obbCorners(o: OBB): { { number } }
	local out = {}
	for _, s in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		table.insert(out, { o.cx + o.ax * o.ha * s[1] + o.bx * o.hb * s[2], o.cz + o.az * o.ha * s[1] + o.bz * o.hb * s[2] })
	end
	return out
end

local function obbAabb(o: OBB): (number, number, number, number)
	local ex = math.abs(o.ax) * o.ha + math.abs(o.bx) * o.hb
	local ez = math.abs(o.az) * o.ha + math.abs(o.bz) * o.hb
	return o.cx - ex, o.cx + ex, o.cz - ez, o.cz + ez
end

local function obbInside(o: OBB, x: number, z: number, margin: number?): boolean
	local dx, dz = x - o.cx, z - o.cz
	local m = margin or 0
	return math.abs(dx * o.ax + dz * o.az) <= o.ha + m and math.abs(dx * o.bx + dz * o.bz) <= o.hb + m
end

-- Recorte de polígonos convexos (Sutherland–Hodgman) para el área de solape exacta
local function clip(subject: { { number } }, clipper: { { number } }): { { number } }
	local output = subject
	for i = 1, #clipper do
		local a, b = clipper[i], clipper[i % #clipper + 1]
		local input = output
		output = {}
		if #input == 0 then
			break
		end
		local function inside(p: { number }): boolean
			return (b[1] - a[1]) * (p[2] - a[2]) - (b[2] - a[2]) * (p[1] - a[1]) >= 0
		end
		local function inter(p: { number }, q: { number }): { number }
			local x1, y1, x2, y2 = p[1], p[2], q[1], q[2]
			local x3, y3, x4, y4 = a[1], a[2], b[1], b[2]
			local den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
			if math.abs(den) < 1e-9 then
				return q
			end
			local t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den
			return { x1 + t * (x2 - x1), y1 + t * (y2 - y1) }
		end
		local s = input[#input]
		for _, e in input do
			if inside(e) then
				if not inside(s) then
					table.insert(output, inter(s, e))
				end
				table.insert(output, e)
			elseif inside(s) then
				table.insert(output, inter(s, e))
			end
			s = e
		end
	end
	return output
end

local function polyArea(p: { { number } }): number
	local a = 0
	for i = 1, #p do
		local q, r = p[i], p[i % #p + 1]
		a += q[1] * r[2] - r[1] * q[2]
	end
	return math.abs(a) / 2
end

local function ccw(p: { { number } }): { { number } }
	local a = 0
	for i = 1, #p do
		local q, r = p[i], p[i % #p + 1]
		a += q[1] * r[2] - r[1] * q[2]
	end
	if a < 0 then
		local out = {}
		for i = #p, 1, -1 do
			table.insert(out, p[i])
		end
		return out
	end
	return p
end

local function overlapArea(a: OBB, b: OBB): number
	local ax0, ax1, az0, az1 = obbAabb(a)
	local bx0, bx1, bz0, bz1 = obbAabb(b)
	if ax1 <= bx0 or bx1 <= ax0 or az1 <= bz0 or bz1 <= az0 then
		return 0
	end
	local p = clip(ccw(obbCorners(a)), ccw(obbCorners(b)))
	return if #p >= 3 then polyArea(p) else 0
end

-- Huella de una pieza (caja girada) en planta: OBB con el eje más largo
local function partObb(part: any): OBB?
	local cf, s = part.CFrame, part.Size
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	-- los dos ejes más horizontales de la pieza
	local axes = { { r, s.X }, { u, s.Y }, { l, s.Z } }
	table.sort(axes, function(p, q)
		return math.abs(p[1].Y) < math.abs(q[1].Y)
	end)
	local a, b = axes[1], axes[2]
	local function flat(v: any, len: number): (number, number, number)
		local m = math.sqrt(v.X * v.X + v.Z * v.Z)
		if m < 1e-4 then
			return 1, 0, 0
		end
		return v.X / m, v.Z / m, len * m / 2
	end
	local ax, az, ha = flat(a[1], a[2])
	local _, _, hb0 = flat(b[1], b[2])
	-- (el tercer eje, casi vertical, también ensancha un poco si la pieza está inclinada)
	local c = axes[3]
	local cx2, cz2, hc = flat(c[1], c[2])
	local bx, bz = -az, ax
	local extraA = math.abs(cx2 * ax + cz2 * az) * hc
	local extraB = math.abs(cx2 * bx + cz2 * bz) * hc
	local hb = hb0 * math.abs((b[1].X * bx + b[1].Z * bz) / math.max(1e-4, math.sqrt(b[1].X ^ 2 + b[1].Z ^ 2))) + extraB
	return { cx = cf.Position.X, cz = cf.Position.Z, ax = ax, az = az, bx = bx, bz = bz, ha = ha + extraA, hb = hb }
end

---------------------------------------------------------------------
-- Rejilla de la calzada y las aceras
---------------------------------------------------------------------
local B = CityPlan.Bounds
local RC = U.ROAD_CELL
local NX = math.ceil((B.MaxX - B.MinX) / RC)
local NZ = math.ceil((B.MaxZ - B.MinZ) / RC)
local roadGrid = buffer.create(NX * NZ) -- 0 nada, 1 calzada, 2 acera/bordillo
local mainGrid = buffer.create(NX * NZ) -- 1 calzada de una carretera principal (MainRoads)
local function gidx(gx: number, gz: number): number
	return gz * NX + gx
end
local function cellOf(x: number, z: number): (number, number)
	return math.floor((x - B.MinX) / RC), math.floor((z - B.MinZ) / RC)
end
local function roadAt(x: number, z: number): number
	local gx, gz = cellOf(x, z)
	if gx < 0 or gz < 0 or gx >= NX or gz >= NZ then
		return 0
	end
	return buffer.readu8(roadGrid, gidx(gx, gz))
end

local function rasterObb(o: OBB, value: number, main: boolean?)
	local x0, x1, z0, z1 = obbAabb(o)
	local g0x, g0z = cellOf(x0, z0)
	local g1x, g1z = cellOf(x1, z1)
	for gz = math.max(0, g0z), math.min(NZ - 1, g1z) do
		local z = B.MinZ + (gz + 0.5) * RC
		for gx = math.max(0, g0x), math.min(NX - 1, g1x) do
			local x = B.MinX + (gx + 0.5) * RC
			if obbInside(o, x, z) then
				local i = gidx(gx, gz)
				local cur = buffer.readu8(roadGrid, i)
				if value == 1 or cur == 0 then
					buffer.writeu8(roadGrid, i, value)
				end
				if main and value == 1 then
					buffer.writeu8(mainGrid, i, 1)
				end
			end
		end
	end
end
local function rasterDisc(cx: number, cz: number, radius: number, value: number)
	local g0x, g0z = cellOf(cx - radius, cz - radius)
	local g1x, g1z = cellOf(cx + radius, cz + radius)
	for gz = math.max(0, g0z), math.min(NZ - 1, g1z) do
		local z = B.MinZ + (gz + 0.5) * RC
		for gx = math.max(0, g0x), math.min(NX - 1, g1x) do
			local x = B.MinX + (gx + 0.5) * RC
			if (x - cx) ^ 2 + (z - cz) ^ 2 <= radius * radius then
				local i = gidx(gx, gz)
				if value == 1 or buffer.readu8(roadGrid, i) == 0 then
					buffer.writeu8(roadGrid, i, value)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Lectura del mapa
---------------------------------------------------------------------
print("▶ Leyendo " .. placePath)
local game = roblox.deserializePlace(fs.readFile(placePath))
local town = game:GetService("Workspace"):FindFirstChild("Town")
if not town then
	print("❌ El archivo no tiene la ciudad (Workspace.Town): ejecuta antes scripts/build-place.luau")
	process.exit(1)
end

local ROAD_NAMES = { Road = 1, Junction = 1, BridgeDeck = 1 }
local WALK_NAMES = { Sidewalk = 2, Curb = 2, RingSidewalk = 2, RingCurb = 2, RoadKerb = 2, KerbRamp = 2 }
type RoadPiece = { obb: OBB, part: any, main: boolean }
local roadPieces: { RoadPiece } = {}

-- (las aceras que unen una manzana con la carretera de al lado, Kit/Districts: AceraManzana)
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "AceraManzana" then
		local o = partObb(d)
		if o then
			rasterObb(o, 2)
		end
	end
end
for _, root in { town:FindFirstChild("Streets"), town:FindFirstChild("MainRoads") } do
	if root then
		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				local v = ROAD_NAMES[d.Name] or WALK_NAMES[d.Name]
				if v then
					local isDisc = d:IsA("Part") and d.Shape == Enum.PartType.Cylinder and math.abs(d.CFrame.RightVector.Y) > 0.9
					if isDisc then
						rasterDisc(d.CFrame.Position.X, d.CFrame.Position.Z, math.min(d.Size.Y, d.Size.Z) / 2, v)
					else
						local o = partObb(d)
						if o then
							rasterObb(o, v, root.Name == "MainRoads")
							if v == 1 and d.Name == "Road" then
								table.insert(roadPieces, { obb = o, part = d, main = root.Name == "MainRoads" })
							end
						end
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Unidades (un uso cada una: un edificio, una casa, un aparcamiento, un parque, un sitio…)
---------------------------------------------------------------------
type Rect = { X0: number, X1: number, Z0: number, Z1: number }
type Block = { rect: Rect, kind: string, name: string, units: { any } }
type Unit = { id: number, name: string, path: string, model: any, use: string, structures: { any }, surfaces: { any }, block: Block?, site: boolean, ownBlock: Block?, x: number, z: number, access: number? }
local blocks: { Block } = {}
local units: { Unit } = {}

-- Infraestructura que no es un «uso» de una parcela
local SKIP_ROOT = {
	Ground = true, River = true, Lake = true, Sea = true, Streets = true, MainRoads = true, Campo = true,
	Naturaleza = true, ParadasBus = true, StreetLife = true, Aviones = true, IslandPreview = true,
	HillPreview = true, BlockGround = true, TrashBags = true, Table = true,
}
local SKIP_TOWN = { Bienvenida = true, BusStop = true, BiciPublica = true, TravelPoint = true, BlockGround = true }
local TOWN_CONTAINERS = { Manzana = true, Viviendas = true, CasasFamiliares = true }

local function useOf(name: string, model: any): string
	local n = string.lower(name)
	if string.find(n, "aparcamiento") or n == "parking" then
		return "aparcamiento"
	elseif n == "vivienda" or n == "villa" or string.find(n, "casa") or n == "cosmehouse" then
		return "vivienda"
	elseif n == "rascacielos" or n == "torre" or n == "torres" or n == "plazafinanciera" then
		return "torre"
	elseif n == "nave" or n == "industrial" or n == "taller" then
		return "industria"
	elseif n == "jardin" or n == "parque" or n == "parquevivo" or n == "huerta" or n == "plaza" or string.find(n, "jardines") or string.find(n, "huertos") or string.find(n, "orilla") or string.find(n, "camping") or n == "playa" or n == "granja" then
		return "verde"
	elseif string.find(n, "estadio") or string.find(n, "deporte") or string.find(n, "pitch") or string.find(n, "polideportivo") or n == "ocio_campus" or n == "ocio_skate" or n == "ocio_karting" or n == "ocio_playa" then
		return "deporte"
	elseif n == "colegio" or n == "hospital" or n == "centrosalud" or n == "serviciosemergencia" or n == "bomberos" or n == "policia" or n == "facultad" or string.find(n, "comisaria") or string.find(n, "colegio") or string.find(n, "clinica") or string.find(n, "instituto") or n == "ayuntamiento" or n == "museo" or n == "teatro" or string.find(n, "estacion") then
		return "equipamiento"
	elseif n == "bloque" or n == "edificio" then
		local shop = model and model:GetAttribute("ShopId")
		return if shop then "comercio" else "pisos"
	elseif n == "ocio_local" or n == "ocio" or n == "centrocomercial" or n == "gasolinera" or string.find(n, "super") or string.find(n, "hiper") or n == "oficinas" or n == "cafeteria" or n == "correos" or n == "megaburger" or n == "restaurante" or n == "hotel" or string.find(n, "armeria") or n == "tiendapesca" or n == "ocio_feria" then
		return "comercio"
	end
	return "otro"
end

local unitOf: { [any]: Unit } = {}
local function newUnit(model: any, block: Block?, site: boolean): Unit
	local u: Unit = {
		id = #units + 1, name = model.Name, path = model:GetFullName(), model = model, use = useOf(model.Name, model),
		structures = {}, surfaces = {}, block = block, site = site, ownBlock = nil, x = 0, z = 0,
	}
	table.insert(units, u)
	unitOf[model] = u
	return u
end

local function rectOfGround(g: any, shrink: number): Rect
	local p, s = g.CFrame.Position, g.Size
	return { X0 = p.X - s.X / 2 + shrink, X1 = p.X + s.X / 2 - shrink, Z0 = p.Z - s.Z / 2 + shrink, Z1 = p.Z + s.Z / 2 - shrink }
end

local SITE_ROOTS = { ZonasVerdes = true, ZonasOcio = true }
for _, child in town:GetChildren() do
	if SKIP_ROOT[child.Name] or string.match(child.Name, "^JobBoard") then
		if child.Name == "BlockGround" and child:IsA("BasePart") then
			table.insert(blocks, { rect = rectOfGround(child, 0), kind = "ValmarCentro", name = "Valmar Centro", units = {} })
		end
		continue
	end
	if child.Name == "Region" then
		for _, townModel in child:GetChildren() do
			for _, c in townModel:GetChildren() do
				if c.Name == "BlockGround" and c:IsA("BasePart") then
					table.insert(blocks, { rect = rectOfGround(c, 0), kind = "Barrio", name = townModel.Name, units = {} })
				elseif SKIP_TOWN[c.Name] then
					continue
				elseif TOWN_CONTAINERS[c.Name] and c:IsA("Model") then
					for _, u in c:GetChildren() do
						if u:IsA("Model") then
							newUnit(u, nil, false)
						end
					end
				elseif c:IsA("Model") then
					newUnit(c, nil, false)
				end
			end
		end
	elseif child.Name == "Distritos" then
		for _, district in child:GetChildren() do
			for _, manzana in district:GetChildren() do
				local ground = manzana:FindFirstChild("BlockGround")
				local kind = string.gsub(manzana.Name, "^Manzana_", "")
				local block: Block? = nil
				if ground then
					block = { rect = rectOfGround(ground, 2), kind = kind, name = district.Name .. "/" .. manzana.Name, units = {} }
					table.insert(blocks, block :: Block)
				end
				local loose = nil
				for _, u in manzana:GetChildren() do
					if u:IsA("Model") then
						newUnit(u, block, false)
					elseif u:IsA("BasePart") and u.Name ~= "BlockGround" then
						-- piezas sueltas de la manzana (la plaza de las torres, el campo de deporte…)
						loose = loose or newUnit(manzana, block, false)
						loose.use = useOf(kind, nil)
					end
				end
			end
		end
	elseif child.Name == "Edificios" or child.Name == "Plots" or SITE_ROOTS[child.Name] or child.Name == "Metro" or child.Name == "Cercanias" then
		for _, u in child:GetChildren() do
			if u:IsA("Model") then
				local unit = newUnit(u, nil, SITE_ROOTS[child.Name] == true)
				if child.Name == "Metro" or child.Name == "Cercanias" then
					unit.use = "transporte"
				end
				if child.Name == "Plots" then
					unit.use = "vivienda"
				end
			end
		end
	elseif child:IsA("Model") then
		local unit = newUnit(child, nil, false)
		if child.Name == "Aeropuerto" or child.Name == "Aerodromo" or child.Name == "Puerto" or child.Name == "Marina" then
			unit.use = "transporte"
		elseif child.Name == "Protectora" or child.Name == "CampoAnimales" or child.Name == "CentroPenitenciario" then
			unit.use = "equipamiento"
		elseif child.Name == "Faro" or child.Name == "Mirador" or string.match(child.Name, "^ZonaPesca") then
			unit.use = "verde"
		end
	end
end
print(("  %d unidades, %d manzanas"):format(#units, #blocks))

-- Piezas de cada unidad: «estructuras» (modelos con paredes de verdad) y «suelos» (losas grandes a ras)
local NOT_CORE_SHAPE = { Ball = true, Cylinder = true }
local function unitFor(inst: any): Unit?
	local p = inst.Parent
	while p and p ~= town do
		local u = unitOf[p]
		if u then
			return u
		end
		p = p.Parent
	end
	return nil
end

type Structure = { unit: Unit, model: any, obb: OBB, area: number, top: number, parts: { OBB } }
local structures: { Structure } = {}
local surfaces: { { unit: Unit, obb: OBB, area: number, name: string } } = {}
local structParts: { [any]: { any } } = {}

local SURFACE_SKIP = { BlockGround = true, Road = true, Sidewalk = true, Curb = true, Floor = true, Ceiling = true, Roof = true }
local count = 0
for _, d in town:GetDescendants() do
	if not d:IsA("BasePart") then
		continue
	end
	count += 1
	if d.Transparency >= 0.95 and not d.CanCollide then
		continue
	end
	local cf, s = d.CFrame, d.Size
	local hy = (math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z) / 2
	local top, bottom = cf.Position.Y + hy, cf.Position.Y - hy
	if bottom > 900 or top < -3 then
		continue -- (salas del cielo, metro)
	end
	local unit = unitFor(d)
	if not unit then
		continue
	end
	local shape = if d:IsA("Part") then d.Shape.Name else "Block"
	local o = partObb(d)
	if not o then
		continue
	end
	local area = 4 * o.ha * o.hb
	if top >= 7 and top - math.max(bottom, 0) >= 4 and not NOT_CORE_SHAPE[shape] and area >= 6 and d.CanCollide then
		local owner = d.Parent
		while owner and not owner:IsA("Model") do
			owner = owner.Parent
		end
		local list = structParts[owner]
		if not list then
			list = {}
			structParts[owner] = list
		end
		table.insert(list, d)
	elseif top <= 1.8 and top - bottom <= 2.5 and area >= 150 and not SURFACE_SKIP[d.Name] and math.abs(cf.UpVector.Y) > 0.95 then
		table.insert(surfaces, { unit = unit, obb = o, area = area, name = d.Name })
	end
end

-- Cada modelo con paredes es una estructura: caja girada según su pieza más grande
-- (ni árboles ni farolas; ni vehículos aparcados en la calle, como el autobús escolar; ni los
--  tabiques del interior de una casa, que están dentro de su fachada)
local NOT_STRUCTURE = { Tree = true, Arbol = true, Palm = true, StreetLamp = true, TrafficLight = true, Bench = true, Car = true, Coche = true, SchoolBus = true, Bus = true, Autobus = true, Truck = true, Camion = true, Taxi = true }
for model, list in structParts do
	if NOT_STRUCTURE[model.Name] or string.find(model:GetFullName(), ".Interior", 1, true) then
		continue
	end
	local unit = unitFor(list[1]) :: Unit
	local best, bestArea = nil, -1
	for _, p in list do
		local a = p.Size.X * p.Size.Z
		if a > bestArea then
			best, bestArea = p, a
		end
	end
	local ob = partObb(best) :: OBB
	local ax, az, bx, bz = ob.ax, ob.az, ob.bx, ob.bz
	local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
	local topMax = 0
	local partBoxes = {}
	for _, p in list do
		local o = partObb(p) :: OBB
		table.insert(partBoxes, o)
		for _, c in obbCorners(o) do
			local da, db = c[1] * ax + c[2] * az, c[1] * bx + c[2] * bz
			amin, amax = math.min(amin, da), math.max(amax, da)
			bmin, bmax = math.min(bmin, db), math.max(bmax, db)
		end
		topMax = math.max(topMax, p.CFrame.Position.Y + p.Size.Y / 2)
	end
	local ca, cb = (amin + amax) / 2, (bmin + bmax) / 2
	local obb = { cx = ca * ax + cb * bx, cz = ca * az + cb * bz, ax = ax, az = az, bx = bx, bz = bz, ha = (amax - amin) / 2, hb = (bmax - bmin) / 2 }
	local area = 4 * obb.ha * obb.hb
	if area >= 40 then
		local st = { unit = unit, model = model, obb = obb, area = area, top = topMax, parts = partBoxes }
		table.insert(structures, st)
		table.insert(unit.structures, st)
	end
end
for _, sf in surfaces do
	table.insert(sf.unit.surfaces, sf)
end
print(("  %d piezas, %d estructuras, %d suelos"):format(count, #structures, #surfaces))

-- Centro de cada unidad y su manzana
local function blockAt(x: number, z: number): Block?
	for _, b in blocks do
		local r = b.rect
		if x >= r.X0 and x <= r.X1 and z >= r.Z0 and z <= r.Z1 then
			return b
		end
	end
	return nil
end
for _, u in units do
	local sx, sz, w = 0, 0, 0
	for _, st in u.structures do
		sx += st.obb.cx * st.area
		sz += st.obb.cz * st.area
		w += st.area
	end
	for _, sf in u.surfaces do
		sx += sf.obb.cx * sf.area * 0.25
		sz += sf.obb.cz * sf.area * 0.25
		w += sf.area * 0.25
	end
	if w > 0 then
		u.x, u.z = sx / w, sz / w
	else
		local ok, pivot = pcall(function()
			return u.model:GetPivot().Position
		end)
		if ok then
			u.x, u.z = pivot.X, pivot.Z
		end
	end
	u.ownBlock = u.block
	if not u.block and not u.site then
		u.block = blockAt(u.x, u.z)
	end
	if u.block then
		table.insert(u.block.units, u)
	end
end

-- ¿Es «a» antepasado de «b» (o al revés)? (una estructura dentro de otra del mismo edificio)
local function related(a: any, b: any): boolean
	return a:IsAncestorOf(b) or b:IsAncestorOf(a)
end

---------------------------------------------------------------------
-- 1. Calles: trozos sueltos y calles que no van a ninguna parte
---------------------------------------------------------------------
print("▶ Calles")
local comp = buffer.create(NX * NZ * 4)
local comps: { { size: number, x: number, z: number, x0: number, x1: number, z0: number, z1: number } } = {}
do
	local stack = {}
	for gz = 0, NZ - 1 do
		for gx = 0, NX - 1 do
			local i = gidx(gx, gz)
			if buffer.readu8(roadGrid, i) == 1 and buffer.readi32(comp, i * 4) == 0 then
				local id = #comps + 1
				local info = { size = 0, x = 0, z = 0, x0 = gx, x1 = gx, z0 = gz, z1 = gz }
				table.insert(comps, info)
				buffer.writei32(comp, i * 4, id)
				local n = 1
				stack[1] = i
				while n > 0 do
					local j = stack[n]
					n -= 1
					local cx, cz = j % NX, j // NX
					info.size += 1
					info.x += cx
					info.z += cz
					info.x0, info.x1 = math.min(info.x0, cx), math.max(info.x1, cx)
					info.z0, info.z1 = math.min(info.z0, cz), math.max(info.z1, cz)
					for dz = -1, 1 do
						for dx = -1, 1 do
							local nx, nz = cx + dx, cz + dz
							if nx >= 0 and nz >= 0 and nx < NX and nz < NZ then
								local k = gidx(nx, nz)
								if buffer.readu8(roadGrid, k) == 1 and buffer.readi32(comp, k * 4) == 0 then
									buffer.writei32(comp, k * 4, id)
									n += 1
									stack[n] = k
								end
							end
						end
					end
				end
			end
		end
	end
end
local mainId, mainSize = 0, 0
for id, c in comps do
	if c.size > mainSize then
		mainId, mainSize = id, c.size
	end
end
local function onIsland(x: number, z: number): string?
	for _, isl in CityPlan.Islands do
		if math.sqrt((x - isl.X) ^ 2 + (z - isl.Z) ^ 2) < isl.R + 200 then
			return isl.Name
		end
	end
	return nil
end
local fragmentCount = 0
for id, c in comps do
	if id ~= mainId then
		local x = B.MinX + (c.x / c.size + 0.5) * RC
		local z = B.MinZ + (c.z / c.size + 0.5) * RC
		local area = c.size * RC * RC
		local radius = math.max(c.x1 - c.x0, c.z1 - c.z0) * RC / 2 + 10
		local island = onIsland(x, z)
		if island then
			add("calle_suelta", "info", x, z, radius, ("trozo de calzada de %d studs² en %s (sin coche hasta allí: vale)"):format(area, island))
		else
			fragmentCount += 1
			add("calle_suelta", "critical", x, z, radius, ("trozo de calzada de %d studs² que no se une a la red de calles"):format(area))
		end
	end
end
print(("  red principal: %d studs² de calzada; %d trozos sueltos"):format(mainSize * RC * RC, fragmentCount))

-- Calles cortadas: cada trozo de calzada de las calles (Streets) sigue en otra calzada por sus lados.
-- Un trozo normal sigue por dos lados (delante y detrás; los otros dos son bordillos), un cruce por 3
-- o 4. Si solo sigue por UN lado, ahí acaba la calle: el otro lado es un final sin salida.
local deadEnds = 0
local function continues(o: OBB, dirA: number, dirB: number): boolean
	-- lado (dirA, dirB): (±1, 0) por el eje a, (0, ±1) por el eje b
	local h = if dirA ~= 0 then o.ha else o.hb
	local w = if dirA ~= 0 then o.hb else o.ha
	local nx, nz = o.ax * dirA + o.bx * dirB, o.az * dirA + o.bz * dirB
	local tx, tz = -nz, nx
	local hits = 0
	for _, lat in { -0.6, 0, 0.6 } do
		local hit = false
		for _, beyond in { 3, 6 } do
			local x = o.cx + nx * (h + beyond) + tx * w * lat
			local z = o.cz + nz * (h + beyond) + tz * w * lat
			if roadAt(x, z) == 1 then
				hit = true
			end
		end
		if hit then
			hits += 1
		end
	end
	return hits >= 2
end
for _, piece in roadPieces do
	if piece.main then
		continue
	end
	local o = piece.obb
	local sides = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	local open = {}
	for _, s in sides do
		if continues(o, s[1], s[2]) then
			table.insert(open, s)
		end
	end
	if #open == 1 then
		deadEnds += 1
		local s = open[1]
		local h = if s[1] ~= 0 then o.ha else o.hb
		local nx, nz = -(o.ax * s[1] + o.bx * s[2]), -(o.az * s[1] + o.bz * s[2])
		local ex, ez = o.cx + nx * h, o.cz + nz * h
		-- (si acaba dentro de la calzada de una carretera principal, es un cruce en T: vale)
		local gx, gz = cellOf(ex - nx * 3, ez - nz * 3)
		if gx >= 0 and gz >= 0 and gx < NX and gz < NZ and buffer.readu8(mainGrid, gidx(gx, gz)) == 1 then
			deadEnds -= 1
			continue
		end
		local inBlock = blockAt(ex + nx * 14, ez + nz * 14)
		if inBlock then
			add("calle_cortada", "critical", ex, ez, 24, ("la calle acaba dentro de una manzana (%s)"):format(inBlock.name))
		else
			local island = onIsland(ex, ez)
			add("calle_cortada", if island then "info" else "warning", ex, ez, 24, "la calle se corta sin llegar a otra calle")
		end
	end
end
print(("  %d extremos de calle sin salida"):format(deadEnds))

-- Calles dobles: dos tramos de calle paralelos con los ejes a 30-60 studs (las aceras pegadas, sin
-- sitio para una manzana entre ellos)
local doubles = 0
do
	local long = {}
	for _, piece in roadPieces do
		local o = piece.obb
		if not piece.main and math.max(o.ha, o.hb) >= 30 then
			table.insert(long, piece)
		end
	end
	local seen = {}
	for i, p in long do
		for j = i + 1, #long do
			local q = long[j]
			local a, b = p.obb, q.obb
			-- eje a lo largo de cada tramo
			local ax, az = if a.ha >= a.hb then a.ax else a.bx, if a.ha >= a.hb then a.az else a.bz
			local bx, bz = if b.ha >= b.hb then b.ax else b.bx, if b.ha >= b.hb then b.az else b.bz
			if math.abs(ax * bx + az * bz) > 0.99 then
				local dx, dz = b.cx - a.cx, b.cz - a.cz
				local lateral = math.abs(dx * -az + dz * ax)
				local along = math.abs(dx * ax + dz * az)
				local la, lb = math.max(a.ha, a.hb), math.max(b.ha, b.hb)
				if lateral >= 30 and lateral <= 60 and along < la + lb - 40 then
					local key = math.floor((a.cx + b.cx) / 200) .. "," .. math.floor((a.cz + b.cz) / 200)
					if not seen[key] then
						seen[key] = true
						doubles += 1
						add("calle_doble", "warning", (a.cx + b.cx) / 2, (a.cz + b.cz) / 2, 40, ("dos calles paralelas a %d studs (las aceras pegadas)"):format(math.floor(lateral)))
					end
				end
			end
		end
	end
end
print(("  %d tramos de calles dobles"):format(doubles))

---------------------------------------------------------------------
-- 2. Acceso: edificios, casas, negocios, aparcamientos y sitios con calle o acera cerca
---------------------------------------------------------------------
print("▶ Acceso a la calle")
local NEEDS_ACCESS = { vivienda = true, pisos = true, torre = true, comercio = true, industria = true, aparcamiento = true, equipamiento = true, deporte = true }
local function accessDistance(o: OBB, maxD: number): number
	-- distancia (aprox. a la celda) desde el borde de la caja a la acera o calzada más cercana
	local x0, x1, z0, z1 = obbAabb(o)
	local g0x, g0z = cellOf(x0 - maxD, z0 - maxD)
	local g1x, g1z = cellOf(x1 + maxD, z1 + maxD)
	local best = math.huge
	for gz = math.max(0, g0z), math.min(NZ - 1, g1z) do
		local z = B.MinZ + (gz + 0.5) * RC
		for gx = math.max(0, g0x), math.min(NX - 1, g1x) do
			if buffer.readu8(roadGrid, gidx(gx, gz)) ~= 0 then
				local x = B.MinX + (gx + 0.5) * RC
				local dx, dz = x - o.cx, z - o.cz
				local da = math.max(0, math.abs(dx * o.ax + dz * o.az) - o.ha)
				local db = math.max(0, math.abs(dx * o.bx + dz * o.bz) - o.hb)
				local d = math.sqrt(da * da + db * db)
				if d < best then
					best = d
					if best <= RC then
						return best
					end
				end
			end
		end
	end
	return best
end
local noAccess = 0
local pendingAccess = {}
for _, u in units do
	if not (NEEDS_ACCESS[u.use] or u.use == "verde") then
		continue
	end
	if onIsland(u.x, u.z) then
		continue
	end
	-- La parcela entera: sus edificios y sus suelos (la puerta puede dar a cualquier lado, y una casa
	-- con jardín delante da a la calle por su parcela), y el camino de acceso de un sitio de ocio
	local best = math.huge
	local shapes = {}
	for _, st in u.structures do
		table.insert(shapes, st.obb)
	end
	for _, sf in u.surfaces do
		table.insert(shapes, sf.obb)
	end
	local siteId = u.model:GetAttribute("OcioSite")
	if siteId then
		for _, other in units do
			if other.model:GetAttribute("AccessFor") == siteId then
				for _, sf in other.surfaces do
					table.insert(shapes, sf.obb)
				end
			end
		end
	end
	if #shapes == 0 then
		continue
	end
	for _, o in shapes do
		best = math.min(best, accessDistance(o, U.ACCESS_CRIT + 4))
		if best <= U.ACCESS_WARN then
			break
		end
	end
	u.access = best
	if best > U.ACCESS_WARN then
		table.insert(pendingAccess, u)
	end
end
-- Un edificio que da a su propio aparcamiento o a su plaza (y estos a la calle) también tiene acceso:
-- el súper al fondo de su aparcamiento, el ayuntamiento en medio de su plaza…
local function shapesOf(u: Unit): { OBB }
	local list = {}
	for _, st in u.structures do
		table.insert(list, st.obb)
	end
	for _, sf in u.surfaces do
		table.insert(list, sf.obb)
	end
	return list
end
local function near(a: { OBB }, b: { OBB }, gap: number): boolean
	for _, p in a do
		for _, q in b do
			if overlapArea({ cx = p.cx, cz = p.cz, ax = p.ax, az = p.az, bx = p.bx, bz = p.bz, ha = p.ha + gap, hb = p.hb + gap }, q) > 0 then
				return true
			end
		end
	end
	return false
end
for _, u in pendingAccess do
	if u.use == "verde" then
		continue -- (un parque o un jardín no necesita calle: se llega andando)
	end
	local best = u.access :: number
	if u.block then
		for _, other in u.block.units do
			if other ~= u and (other.use == "aparcamiento" or other.use == "verde") and (other.access or math.huge) <= U.ACCESS_WARN and near(shapesOf(u), shapesOf(other), 8) then
				best = math.min(best, U.ACCESS_WARN)
			end
		end
	end
	if best > U.ACCESS_CRIT then
		noAccess += 1
		add("sin_acceso", "critical", u.x, u.z, 30, ("%s (%s) sin calle ni acera a menos de %d studs"):format(u.name, u.use, U.ACCESS_CRIT))
	elseif best > U.ACCESS_WARN then
		add("sin_acceso", "warning", u.x, u.z, 24, ("%s (%s) a %d studs de la acera"):format(u.name, u.use, math.floor(best)))
	end
end
print(("  %d unidades sin acceso"):format(noAccess))

---------------------------------------------------------------------
-- 3. Solapes: edificios dentro de otros, usos encima de otros, cosas sobre la calzada
---------------------------------------------------------------------
print("▶ Solapes")
local HASH = 64
local function hashKey(gx: number, gz: number): number
	return (gx + 1000) * 10000 + gz + 1000
end
local function bucketize(list: { any }, getObb: (any) -> OBB): { [number]: { any } }
	local map = {}
	for _, item in list do
		local x0, x1, z0, z1 = obbAabb(getObb(item))
		for gx = math.floor(x0 / HASH), math.floor(x1 / HASH) do
			for gz = math.floor(z0 / HASH), math.floor(z1 / HASH) do
				local k = hashKey(gx, gz)
				map[k] = map[k] or {}
				table.insert(map[k], item)
			end
		end
	end
	return map
end
local stBuckets = bucketize(structures, function(s)
	return s.obb
end)

-- (encoge 0,5 studs: dos edificios en hilera que se tocan no cuentan)
local function shrunk(o: OBB, by: number): OBB
	return { cx = o.cx, cz = o.cz, ax = o.ax, az = o.az, bx = o.bx, bz = o.bz, ha = math.max(0, o.ha - by), hb = math.max(0, o.hb - by) }
end
-- Solape de verdad entre dos estructuras: celdas de 2 studs dentro de alguna pieza de las dos
local function partsOverlap(a: Structure, b: Structure): number
	local ax0, ax1, az0, az1 = obbAabb(a.obb)
	local bx0, bx1, bz0, bz1 = obbAabb(b.obb)
	local x0, x1, z0, z1 = math.max(ax0, bx0), math.min(ax1, bx1), math.max(az0, bz0), math.min(az1, bz1)
	if x1 <= x0 or z1 <= z0 then
		return 0
	end
	local function inAny(list: { OBB }, x: number, z: number): boolean
		for _, o in list do
			if obbInside(o, x, z, -0.5) then
				return true
			end
		end
		return false
	end
	local n = 0
	local x = x0 + 1
	while x < x1 do
		local z = z0 + 1
		while z < z1 do
			if inAny(a.parts, x, z) and inAny(b.parts, x, z) then
				n += 1
			end
			z += 2
		end
		x += 2
	end
	return n * 4
end

local overlapCount = 0
local seenPairs = {}
for _, a in structures do
	local x0, x1, z0, z1 = obbAabb(a.obb)
	for gx = math.floor(x0 / HASH), math.floor(x1 / HASH) do
		for gz = math.floor(z0 / HASH), math.floor(z1 / HASH) do
			for _, b in stBuckets[hashKey(gx, gz)] or {} do
				if a == b or related(a.model, b.model) then
					continue
				end
				local key = if tostring(a) < tostring(b) then tostring(a) .. tostring(b) else tostring(b) .. tostring(a)
				if seenPairs[key] then
					continue
				end
				seenPairs[key] = true
				local area = overlapArea(shrunk(a.obb, 0.5), shrunk(b.obb, 0.5))
				if area >= U.OVERLAP_MIN then
					area = partsOverlap(a, b)
				end
				if area >= U.OVERLAP_MIN then
					local small = math.min(a.area, b.area)
					local crit = area >= U.OVERLAP_CRIT or area >= small * U.OVERLAP_FRAC
					local same = a.unit == b.unit
					overlapCount += 1
					local x = (a.obb.cx + b.obb.cx) / 2
					local z = (a.obb.cz + b.obb.cz) / 2
					add("solape_edificios", if crit then "critical" else "warning", x, z, 30, ("%s y %s se meten uno en otro (%d studs²)%s"):format(a.model:GetFullName():gsub("^.-Town%.", ""), b.model:GetFullName():gsub("^.-Town%.", ""), math.floor(area), if same then " [mismo conjunto]" else ""))
				end
			end
		end
	end
end
print(("  %d pares de edificios solapados"):format(overlapCount))

-- Suelos de un uso bajo los edificios de otro, y suelos de usos distintos uno encima de otro
local sfOverStruct, sfOverSf = 0, 0
local sfBuckets = bucketize(surfaces, function(s)
	return s.obb
end)
for _, sf in surfaces do
	local x0, x1, z0, z1 = obbAabb(sf.obb)
	local seen = {}
	for gx = math.floor(x0 / HASH), math.floor(x1 / HASH) do
		for gz = math.floor(z0 / HASH), math.floor(z1 / HASH) do
			for _, st in stBuckets[hashKey(gx, gz)] or {} do
				if seen[st] or st.unit == sf.unit or related(st.unit.model, sf.unit.model) then
					continue
				end
				seen[st] = true
				local area = overlapArea(shrunk(sf.obb, 1), shrunk(st.obb, 1))
				if area >= U.SURFACE_OVERLAP_MIN then
					sfOverStruct += 1
					add("solape_usos", if area >= U.SURFACE_OVERLAP_CRIT then "critical" else "warning", (sf.obb.cx + st.obb.cx) / 2, (sf.obb.cz + st.obb.cz) / 2, 30, ("%s (%s de %s) bajo el edificio %s (%d studs²)"):format(sf.name, sf.unit.use, sf.unit.name, st.model.Name, math.floor(area)))
				end
			end
			for _, other in sfBuckets[hashKey(gx, gz)] or {} do
				if seen[other] or other == sf or other.unit == sf.unit or related(other.unit.model, sf.unit.model) or tostring(other) < tostring(sf) then
					continue
				end
				seen[other] = true
				-- (un parque vivo viste su propio parque: no es un solape)
				local a, b = sf.unit, other.unit
				local dress = (a.name == "ParqueVivo" or b.name == "ParqueVivo") and (a.use == "verde" and b.use == "verde")
				if dress or a.use == b.use then
					continue
				end
				local area = overlapArea(shrunk(sf.obb, 1), shrunk(other.obb, 1))
				if area >= U.SURFACE_OVERLAP_MIN then
					sfOverSf += 1
					add("solape_usos", if area >= U.SURFACE_OVERLAP_CRIT then "critical" else "warning", (sf.obb.cx + other.obb.cx) / 2, (sf.obb.cz + other.obb.cz) / 2, 30, ("%s (%s) encima de %s (%s) (%d studs²)"):format(a.name, a.use, b.name, b.use, math.floor(area)))
				end
			end
		end
	end
end
print(("  %d suelos bajo edificios ajenos, %d suelos de usos distintos solapados"):format(sfOverStruct, sfOverSf))

-- Edificios y suelos sobre la calzada
local function roadArea(o: OBB): number
	local x0, x1, z0, z1 = obbAabb(o)
	local g0x, g0z = cellOf(x0, z0)
	local g1x, g1z = cellOf(x1, z1)
	local n = 0
	for gz = math.max(0, g0z), math.min(NZ - 1, g1z) do
		local z = B.MinZ + (gz + 0.5) * RC
		for gx = math.max(0, g0x), math.min(NX - 1, g1x) do
			if buffer.readu8(roadGrid, gidx(gx, gz)) == 1 then
				local x = B.MinX + (gx + 0.5) * RC
				if obbInside(o, x, z) then
					n += 1
				end
			end
		end
	end
	return n * RC * RC
end
local onRoad = 0
for _, st in structures do
	if st.unit.use == "transporte" then
		continue
	end
	local area = 0
	if roadArea(shrunk(st.obb, 1)) > 0 then
		for _, o in st.parts do
			area += roadArea(shrunk(o, 0.5))
		end
	end
	if area >= U.ROAD_INTRUSION_CRIT then
		onRoad += 1
		add("sobre_calzada", "critical", st.obb.cx, st.obb.cz, 30, ("el edificio %s (%s) tapa %d studs² de calzada"):format(st.model.Name, st.unit.name, area))
	end
end
for _, sf in surfaces do
	if sf.unit.use == "transporte" then
		continue
	end
	local area = roadArea(shrunk(sf.obb, 2))
	if area >= U.ROAD_INTRUSION_CRIT then
		onRoad += 1
		add("sobre_calzada", if sf.unit.site then "critical" else "critical", sf.obb.cx, sf.obb.cz, 30, ("el suelo %s de %s (%s) tapa %d studs² de calzada"):format(sf.name, sf.unit.name, sf.unit.use, area))
	end
end
print(("  %d cosas encima de la calzada"):format(onRoad))

---------------------------------------------------------------------
-- 4. Manzanas: densidad y mezcla de usos
---------------------------------------------------------------------
print("▶ Manzanas")
local STRONG = { vivienda = true, pisos = true, torre = true, comercio = true, aparcamiento = true, deporte = true, industria = true }
type BlockStat = { block: Block, coverage: number, uses: { [string]: number }, strong: number, district: string }
local stats: { BlockStat } = {}
local byDistrictKind: { [string]: { number } } = {}
for _, b in blocks do
	local r = b.rect
	local area = (r.X1 - r.X0) * (r.Z1 - r.Z0)
	if area <= 0 then
		continue
	end
	-- (lo construido: celdas de 4 studs de la manzana dentro de alguna pared de verdad)
	local covered = {}
	local nCovered = 0
	local uses: { [string]: number } = {}
	for _, u in b.units do
		local has = false
		for _, st in u.structures do
			has = true
			for _, o in st.parts do
				local x0, x1, z0, z1 = obbAabb(o)
				x0, x1, z0, z1 = math.max(x0, r.X0), math.min(x1, r.X1), math.max(z0, r.Z0), math.min(z1, r.Z1)
				for gx = math.floor(x0 / 4), math.floor(x1 / 4) do
					for gz = math.floor(z0 / 4), math.floor(z1 / 4) do
						local k = gx * 100000 + gz
						if not covered[k] and obbInside(o, gx * 4 + 2, gz * 4 + 2, 1) then
							covered[k] = true
							nCovered += 1
						end
					end
				end
			end
		end
		if has or #u.surfaces > 0 then
			uses[u.use] = (uses[u.use] or 0) + 1
		end
	end
	local strong = 0
	for use in uses do
		if STRONG[use] then
			strong += 1
		end
	end
	local cx, cz = (r.X0 + r.X1) / 2, (r.Z0 + r.Z1) / 2
	local st = { block = b, coverage = nCovered * 16 / area, uses = uses, strong = strong, district = districtName(cx, cz) }
	table.insert(stats, st)
	local key = st.district .. "|" .. b.kind
	byDistrictKind[key] = byDistrictKind[key] or {}
	table.insert(byDistrictKind[key], st.coverage)
end
local function median(list: { number }): number
	local t = table.clone(list)
	table.sort(t)
	return t[math.max(1, math.ceil(#t / 2))]
end
local crowded, mixed = 0, 0
for _, st in stats do
	local r = st.block.rect
	local cx, cz = (r.X0 + r.X1) / 2, (r.Z0 + r.Z1) / 2
	local radius = math.max(r.X1 - r.X0, r.Z1 - r.Z0) / 2
	local norm = median(byDistrictKind[st.district .. "|" .. st.block.kind])
	if st.coverage > U.COVERAGE_CRIT then
		crowded += 1
		add("manzana_llena", "critical", cx, cz, radius, ("manzana %s con el %d %% construido"):format(st.block.name, math.floor(st.coverage * 100)))
	elseif st.coverage > U.COVERAGE_MIN and st.coverage > norm * U.COVERAGE_RATIO then
		crowded += 1
		add("manzana_llena", "warning", cx, cz, radius, ("manzana %s con el %d %% construido (lo normal en su distrito: %d %%)"):format(st.block.name, math.floor(st.coverage * 100), math.floor(norm * 100)))
	end
	local list = {}
	for use in st.uses do
		if STRONG[use] then
			table.insert(list, use)
		end
	end
	table.sort(list)
	local area = (r.X1 - r.X0) * (r.Z1 - r.Z0)
	local clash = (st.uses.vivienda and st.uses.torre) or (st.uses.vivienda and st.uses.industria) or (st.uses.deporte and st.uses.aparcamiento and st.uses.torre)
	if st.strong >= 4 or clash then
		mixed += 1
		local crit = (st.strong >= 4 and area <= U.MIX_SMALL) or clash
		add("manzana_mezclada", if crit then "critical" else "warning", cx, cz, radius, ("manzana %s mezcla %s"):format(st.block.name, table.concat(list, " + ")))
	end
end

-- Zonificación del centro: rascacielos solo en la franja norte (junto al Distrito Financiero) y nada
-- de manzanas enteras de aparcamiento sueltas entre los bloques
for _, st in stats do
	local r = st.block.rect
	local cx, cz = (r.X0 + r.X1) / 2, (r.Z0 + r.Z1) / 2
	if st.district == "Distrito Centro" then
		if st.block.kind == "Towers" and cz > -450 then
			mixed += 1
			add("zonificacion", "warning", cx, cz, 120, ("rascacielos sueltos entre los bloques del centro (%s)"):format(st.block.name))
		elseif st.block.kind == "Parking" then
			mixed += 1
			add("zonificacion", "warning", cx, cz, 120, ("una manzana entera de aparcamiento entre los bloques del centro (%s)"):format(st.block.name))
		end
	end
end

print(("  %d manzanas demasiado llenas, %d con usos que no pegan o fuera de su zona"):format(crowded, mixed))

-- Edificios sueltos fuera de toda manzana (ni sitio, ni lugar especial)
local loose = 0
for _, u in units do
	if not u.block and not u.site and (u.use == "vivienda" or u.use == "pisos" or u.use == "comercio" or u.use == "torre") and #u.structures > 0 then
		loose += 1
		add("fuera_de_manzana", "info", u.x, u.z, 20, ("%s (%s) fuera de toda manzana"):format(u.name, u.use))
	end
end

---------------------------------------------------------------------
-- 5. Zonas verdes y de ocio: ni en calles ni dentro de manzanas ajenas
---------------------------------------------------------------------
print("▶ Zonas verdes y de ocio")
local siteIssues = 0
for _, u in units do
	if not u.site then
		continue
	end
	-- El parque vivo viste su propia manzana (atributo Park = la manzana)
	local parkOf = u.model:GetAttribute("Park")
	local shapes = {}
	for _, st in u.structures do
		table.insert(shapes, st.obb)
	end
	for _, sf in u.surfaces do
		table.insert(shapes, sf.obb)
	end
	for _, b in blocks do
		if parkOf and string.find(parkOf, b.name:gsub("^.*/", ""), 1, true) and string.find(parkOf, (b.name:gsub("/.*$", "")), 1, true) then
			-- (es su parque si el centro cae dentro)
			if u.x >= b.rect.X0 and u.x <= b.rect.X1 and u.z >= b.rect.Z0 and u.z <= b.rect.Z1 then
				continue
			end
		end
		local r = b.rect
		local rectObb = { cx = (r.X0 + r.X1) / 2, cz = (r.Z0 + r.Z1) / 2, ax = 1, az = 0, bx = 0, bz = 1, ha = (r.X1 - r.X0) / 2, hb = (r.Z1 - r.Z0) / 2 }
		local area = 0
		for _, o in shapes do
			area += overlapArea(shrunk(o, 1), rectObb)
		end
		if area >= U.SITE_BLOCK_CRIT then
			-- un parque vivo dentro de un parque (Lite.park) de la misma manzana no cuenta
			if u.name == "ParqueVivo" and (b.kind == "Parque" or b.kind == "Barrio") then
				continue
			end
			siteIssues += 1
			add("sitio_en_manzana", "critical", u.x, u.z, 40, ("el sitio %s se mete %d studs² en la manzana %s"):format(u.name, math.floor(area), b.name))
		end
	end
end
-- Los suelos de los sitios no tapan calzadas ni aceras
local function walkArea(o: OBB): number
	local x0, x1, z0, z1 = obbAabb(o)
	local g0x, g0z = cellOf(x0, z0)
	local g1x, g1z = cellOf(x1, z1)
	local n = 0
	for gz = math.max(0, g0z), math.min(NZ - 1, g1z) do
		local z = B.MinZ + (gz + 0.5) * RC
		for gx = math.max(0, g0x), math.min(NX - 1, g1x) do
			if buffer.readu8(roadGrid, gidx(gx, gz)) ~= 0 then
				local x = B.MinX + (gx + 0.5) * RC
				if obbInside(o, x, z) then
					n += 1
				end
			end
		end
	end
	return n * RC * RC
end
for _, u in units do
	if not u.site or u.model:GetAttribute("AccessFor") then
		continue
	end
	local area = 0
	for _, sf in u.surfaces do
		area += walkArea(shrunk(sf.obb, 2))
	end
	if area >= U.ROAD_INTRUSION_CRIT then
		siteIssues += 1
		add("sitio_en_calle", "critical", u.x, u.z, 40, ("el sitio %s tapa %d studs² de calzada o acera"):format(u.name, area))
	end
end
-- Sitios de ocio (shared/OcioSitios): el rectángulo entero, sin calzada ni manzanas
for _, s in OcioSitios.List do
	local o = { cx = s.Center[1], cz = s.Center[2], ax = 1, az = 0, bx = 0, bz = 1, ha = s.Size[1] / 2, hb = s.Size[2] / 2 }
	local area = roadArea(o)
	if area >= U.ROAD_INTRUSION_CRIT then
		siteIssues += 1
		add("sitio_en_calle", "critical", o.cx, o.cz, math.max(o.ha, o.hb), ("el sitio de ocio %s pisa %d studs² de calzada"):format(s.Id, area))
	end
end
-- Puerto espacial (islote) y portal de la playa
do
	local islote
	for _, isl in CityPlan.Islands do
		if isl.Name == "Islote" then
			islote = isl
		end
	end
	if islote then
		local d = math.sqrt((Access.Port.X - islote.X) ^ 2 + (Access.Port.Z - islote.Z) ^ 2)
		if d > islote.R then
			siteIssues += 1
			add("sitio_en_calle", "critical", Access.Port.X, Access.Port.Z, 40, "el puerto espacial no está en el islote")
		end
		for _, st in structures do
			if math.sqrt((st.obb.cx - islote.X) ^ 2 + (st.obb.cz - islote.Z) ^ 2) < islote.R + 10 then
				siteIssues += 1
				add("sitio_en_manzana", "critical", st.obb.cx, st.obb.cz, 30, "hay un edificio de la ciudad en el islote del puerto espacial: " .. st.model.Name)
			end
		end
	end
	-- El portal de la playa: al menos uno de los sitios de la lista está libre de calles y manzanas
	local free = 0
	for _, xz in Access.BeachSpots do
		if roadAt(xz[1], xz[2]) == 0 and not blockAt(xz[1], xz[2]) then
			free += 1
		end
	end
	if free == 0 then
		siteIssues += 1
		add("sitio_en_calle", "critical", Access.BeachSpots[1][1], Access.BeachSpots[1][2], 40, "ningún sitio del portal de la playa queda libre de calles y manzanas")
	end
end
print(("  %d problemas de sitios"):format(siteIssues))

---------------------------------------------------------------------
-- Resumen
---------------------------------------------------------------------
local KINDS = { "calle_suelta", "calle_cortada", "calle_doble", "sin_acceso", "solape_edificios", "solape_usos", "sobre_calzada", "manzana_llena", "manzana_mezclada", "zonificacion", "sitio_en_manzana", "sitio_en_calle", "fuera_de_manzana" }
local totals = { critical = 0, warning = 0, info = 0 }
local perDistrict: { [string]: { [string]: number } } = {}
for _, i in issues do
	totals[i.severity] += 1
	if i.severity ~= "info" then
		local d = perDistrict[i.district]
		if not d then
			d = { critical = 0, warning = 0 }
			perDistrict[i.district] = d
		end
		d[i.severity] += 1
		d[i.kind] = (d[i.kind] or 0) + 1
	end
end
print("")
print("Problemas por distrito (críticos / avisos; por tipo):")
local names = {}
for name in perDistrict do
	table.insert(names, name)
end
table.sort(names)
for _, name in names do
	local d = perDistrict[name]
	local parts = {}
	for _, k in KINDS do
		if d[k] then
			table.insert(parts, k .. "=" .. d[k])
		end
	end
	print(("  %-24s %4d / %4d   %s"):format(name, d.critical, d.warning, table.concat(parts, " ")))
end

-- Los peores sitios: problemas agrupados en celdas de 250 studs (crítico 3, aviso 1)
local W = { critical = 3, warning = 1, info = 0 }
local cells: { [number]: { score: number, x: number, z: number, n: number, kinds: { [string]: number } } } = {}
for _, i in issues do
	local k = hashKey(math.floor(i.x / 250), math.floor(i.z / 250))
	local c = cells[k]
	if not c then
		c = { score = 0, x = 0, z = 0, n = 0, kinds = {} }
		cells[k] = c
	end
	c.score += W[i.severity]
	c.x += i.x
	c.z += i.z
	c.n += 1
	if i.severity ~= "info" then
		c.kinds[i.kind] = (c.kinds[i.kind] or 0) + 1
	end
end
local worst = {}
for _, c in cells do
	if c.score > 0 then
		table.insert(worst, c)
	end
end
table.sort(worst, function(a, b)
	return a.score > b.score
end)
print("")
print(("Los %d peores sitios (x, z):"):format(math.min(TOP, #worst)))
local worstOut = {}
for i = 1, math.min(TOP, #worst) do
	local c = worst[i]
	local x, z = math.floor(c.x / c.n), math.floor(c.z / c.n)
	local parts = {}
	for k, n in c.kinds do
		table.insert(parts, k .. "×" .. n)
	end
	table.sort(parts)
	print(("  %2d. (%5d, %5d) %-22s puntos %3d  %s"):format(i, x, z, districtName(x, z), c.score, table.concat(parts, ", ")))
	table.insert(worstOut, { x = x, z = z, score = c.score, district = districtName(x, z), kinds = c.kinds })
end

if LIST then
	print("")
	table.sort(issues, function(a, b)
		if a.severity ~= b.severity then
			return a.severity < b.severity
		end
		return a.kind < b.kind
	end)
	for _, i in issues do
		print(("  [%s] %s (%d, %d) %s: %s"):format(i.severity, i.kind, i.x, i.z, i.district, i.msg))
	end
end

if JSON_OUT then
	fs.writeFile(JSON_OUT, serde.encode("json", { issues = issues, worst = worstOut, totals = totals, perDistrict = perDistrict, thresholds = U }, true))
	print("  → " .. JSON_OUT)
end

print("")
print(("Total: %d críticos, %d avisos, %d info"):format(totals.critical, totals.warning, totals.info))
if totals.critical > 0 then
	print("❌ El mapa tiene problemas críticos de coherencia")
	process.exit(1)
end
print("✅ Mapa coherente: 0 problemas críticos")
