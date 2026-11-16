-- PlanetMetroBuilder (servidor): DIBUJA la ciudad grande de un planeta con su plano (shared/Cosmos/PlanetMetro)
-- y su estilo (shared/Cosmos/MetroStyles). Lo llama World/PlanetWorld después del barrio hecho a mano, poco a
-- poco (cede cada pocos edificios) y solo la primera vez que alguien se acerca al planeta: nada de esto está en
-- el archivo del juego.
--
--   * Cada edificio es un Model ligero (pocas piezas grandes: cuerpo, franjas de ventanas que se encienden de
--     noche, tejado y detalles de su tipo) con carga entera y versión de lejos (Builder.streamable): así la
--     ciudad se ve desde la nave.
--   * En tierra (Mode "Ground") las calles van pintadas en el terreno (PlanetMetro.streetAt → materialAt), así
--     que no cuestan piezas; los edificios llevan cimientos hasta el punto más bajo de su solar.
--   * En plataformas (Mode "Deck": Tálasa, Miasma) cada solar es una plataforma y las calles, pasarelas; donde
--     no hay nada al lado, barandilla. En Tálasa, escaleras de mano desde el agua; en Miasma, puntales.
--   * Farolas (StreetLamp: WorldService las enciende de noche), marcas de gente (CrowdSpot, grupo
--     «<Planeta>_M<n>») y un hito con el nombre de cada distrito.
--
-- API: PlanetMetroBuilder.build(parent, S, opts?) → (modelo?, resumen { Parts, Buildings, Lamps, Districts })

local Builder = require(script.Parent.Builder)
local PlanetCityBuilder = require(script.Parent.PlanetCityBuilder)

local PlanetMetroBuilder = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB
local FH = 10

local function mat(name: string?, fallback: Enum.Material?): Enum.Material
	if type(name) == "string" then
		local ok, m = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		if ok and m then
			return m
		end
	end
	return fallback or Enum.Material.SmoothPlastic
end

local function rng(seed: number): () -> number
	local s = math.floor(seed) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function darker(c: Color3, k: number): Color3
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

local TREE = { Tefra = "Dead", Siroco = "Palm", Talasa = "Coral", Nivalis = "Pine", Umbria = "Round", Miasma = "Fungus", Vertice = "Round" }
local BRANDS = {
	Vertice = { "CRÉDITO YA", "VÉRTICE BANK", "LUZ+", "NEXO", "AUTOPAGO", "HIPER 24H", "RASTRO", "HOLOVIA" },
	Siroco = { "AGUA FRESCA", "TALLER RAFA", "MOTORES", "CANTINA", "DUNAS" },
	Talasa = { "NÁCAR", "BUCEO", "ALGAS", "PRESIÓN" },
	Miasma = { "FILTROS", "GLOBOS", "GAS", "RACIONES" },
	Tefra = { "FORJA", "RACIONES", "GUARDIA", "AZUFRE" },
	Nivalis = { "LANA", "SOPA", "HIELO", "FAROLES" },
	Umbria = { "SAVIA", "SEMILLAS", "PLANEADORES" },
}

function PlanetMetroBuilder.build(parent: Instance, S: any, opts: { [string]: any }?): (Model?, { [string]: any })
	local M = S.Metro
	if not M then
		return nil, { Parts = 0, Buildings = 0 }
	end
	local options = opts or {}
	local yield = options.Yield
	local st = M.Style
	local L = st.Look
	local O = S.Origin
	local deck = M.Mode == "Deck"
	local planet = S.Id
	local prefix = (S.City and S.City.KeyPrefix) or S.Prefix or (planet .. "_")
	local wallMat = mat(L.WallMaterial, Enum.Material.Concrete)
	local trimMat = mat(L.TrimMaterial, Enum.Material.Metal)
	local treeKind = TREE[planet] or "Round"
	local brands = BRANDS[planet] or { "TIENDA" }

	-- Texturas PBR de las ciudades (MaterialVariant «Ciudad…» de shared/Cosmos/EspacioLook, hechas con
	-- scripts/espacio/gen_ciudad.py): fachadas con ventanas, chapa de paneles, sillares y losas de plaza. El color
	-- de la pieza las tiñe. Si la variante no está (un servidor sin ellas), la pieza se queda con su material.
	local okMs, MaterialService = pcall(function()
		return game:GetService("MaterialService")
	end)
	local SKIN_BASE = { CiudadPanel = Enum.Material.Metal, CiudadFachada = Enum.Material.Concrete, CiudadPiedra = Enum.Material.Sandstone, CiudadSuelo = Enum.Material.Pavement }
	local haveSkin: { [string]: boolean } = {}
	for name in SKIN_BASE do
		local okV, found = pcall(function()
			return (MaterialService :: any):FindFirstChild(name)
		end)
		haveSkin[name] = okMs and okV and found ~= nil
	end
	local BODY_SKIN = { Vertice = "CiudadFachada", Talasa = "CiudadFachada", Nivalis = "CiudadFachada", Miasma = "CiudadFachada", Tefra = "CiudadPiedra", Siroco = "CiudadPiedra" }
	local TECH_SKIN = { Tefra = "CiudadPiedra", Siroco = "CiudadPiedra" }
	local BODY_NAMES = { Cuerpo = true, Alto = true, Torre = true, Zocalo = true }
	local TECH_NAMES = { Muros = true, Nave = true, Base = true, Cobertizo = true, Tambor = true, Cimientos = true, Amarre = true, Arco = true, Techo = true }
	local FLOOR_NAMES = { Plataforma = true, Losas = true, Suelo = true, Pasarela = true, Orilla = true }
	local HOUSING = { Bloque = true, Torre = true, Rascacielos = true, Casa = true }
	local function skin(part: BasePart, name: string?): boolean
		if not name or not haveSkin[name] then
			return false
		end
		part.Material = SKIN_BASE[name]
		part.MaterialVariant = name
		if part.Transparency > 0 and part.Transparency < 1 then
			part.Transparency = 0
		end
		return true
	end
	-- Viste un edificio recién dibujado: cuerpo con fachada (o sillares), lo técnico con chapa, suelos con losas
	local function dress(m: Instance, kind: string?)
		local facade = false
		for _, ch in m:GetChildren() do
			if ch:IsA("BasePart") then
				if BODY_NAMES[ch.Name] then
					local want = if kind and HOUSING[kind] then BODY_SKIN[planet] else (TECH_SKIN[planet] or "CiudadPanel")
					if planet == "Umbria" and kind and HOUSING[kind] then
						want = nil -- (madera: se queda como está)
					end
					if skin(ch, want) and want == "CiudadFachada" then
						facade = true
					end
				elseif TECH_NAMES[ch.Name] then
					skin(ch, TECH_SKIN[planet] or "CiudadPanel")
				elseif FLOOR_NAMES[ch.Name] then
					skin(ch, "CiudadSuelo")
				end
			end
		end
		-- (la fachada ya trae sus ventanas: fuera las franjas de cristal de antes)
		if facade then
			for _, ch in m:GetChildren() do
				if ch.Name == "Ventanas" then
					ch:Destroy()
				end
			end
		end
	end

	local root = Builder.model("Metropoli", parent)
	local stats = { Parts = 0, Buildings = 0, Lamps = 0, Districts = 0, Bridges = 0, Meshes = 0, MeshBuildings = 0, Props = 0 }
	local folders: { [string]: Model } = {}
	local function folderFor(id: string): Model
		local f = folders[id]
		if not f then
			f = Builder.model("Distrito_" .. id, root)
			folders[id] = f
		end
		return f
	end

	-- Una pieza. cf en el mundo. o = { Shape, Class, Decor, Transparency, Tags, Attributes }
	local function mk(p: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material, o: { [string]: any }?): BasePart
		local props: { [string]: any } = { Name = name, CFrame = cf, Size = size, Color = color, Material = material, Parent = p }
		if o then
			if o.Shape then
				props.Shape = o.Shape
			end
			if o.Class then
				props.ClassName = o.Class
			end
			if o.Transparency then
				props.Transparency = o.Transparency
			end
			if o.Tags then
				props.Tags = o.Tags
			end
			if o.Attributes then
				props.Attributes = o.Attributes
			end
		end
		stats.Parts += 1
		if o and o.Decor then
			return Builder.decor(props)
		end
		return Builder.part(props)
	end
	local function W(lx: number, lz: number, y: number): Vector3
		return V3(O.X + lx, O.Y + y, O.Z + lz)
	end
	-- Cilindro de pie: base en el CFrame cf (local)
	local function column(p: Instance, name: string, cf: CFrame, height: number, diameter: number, color: Color3, material: Enum.Material, o: { [string]: any }?): BasePart
		local oo = o or {}
		oo.Shape = Enum.PartType.Cylinder
		return mk(p, name, cf * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), V3(height, diameter, diameter), color, material, oo)
	end
	local function ball(p: Instance, name: string, cf: CFrame, size: number, color: Color3, material: Enum.Material, o: { [string]: any }?): BasePart
		local oo = o or {}
		oo.Shape = Enum.PartType.Ball
		return mk(p, name, cf, V3(size, size, size), color, material, oo)
	end
	local function glow(part: BasePart)
		PlanetCityBuilder.nightGlow(part, part.Color, L.WindowNight or rgb(255, 210, 150))
	end

	---------------------------------------------------------------------
	-- Edificios y objetos de calle de Blender (World/PlanetCityMeshes): con detalle de cerca (zócalos, balcones,
	-- tuberías, toldos, azoteas con depósitos y antenas…). Si la malla no está, se queda el edificio de piezas.
	---------------------------------------------------------------------
	local MESH_OF: { [string]: { [string]: string } } = {
		Vertice = { Bloque = "VerticeBloque", Torre = "VerticeTorre", Rascacielos = "VerticeTorre", Casa = "VerticeCasa" },
		Tefra = { Bloque = "TefraBloque", Torre = "TefraBloque", Casa = "TefraCasa" },
		Siroco = { Bloque = "SirocoBloque", Casa = "SirocoCasa" },
		Talasa = { Bloque = "TalasaBloque", Casa = "TalasaCasa", Torre = "CiudadTorre" },
		Nivalis = { Bloque = "NivalisBloque", Casa = "NivalisCasa", Torre = "CiudadTorre" },
		Miasma = { Bloque = "MiasmaBloque", Torre = "MiasmaBloque", Casa = "MiasmaCasa" },
		Umbria = { Choza = "UmbriaChoza" },
	}
	-- (para todos los planetas: naves y hangares, y los edificios de cúpula)
	for _, map in MESH_OF do
		map.Nave = "CiudadNave"
		map.Cupula = "CiudadCupula"
		map.Fundicion = "CiudadFundicion"
		map.Bunker = "CiudadBunker"
		map.Aguja = "CiudadAguja"
		map.Tanque = "CiudadDeposito"
		map.Chatarra = "CiudadChatarra"
	end
	local ROUND_KIND = { Cupula = true, Choza = true, Tanque = true, Aguja = true }
	local FLOORS_KIND = { Casa = true, Cupula = true }
	local PROPS: { [string]: { string } } = {
		Tefra = { "CalleCajas", "CalleTuberias", "CalleGenerador", "CalleCajas", "CalleVehiculo" },
		Siroco = { "CalleCajas", "CallePuesto", "CalleVehiculo", "CalleJardinera", "CallePuesto" },
		Talasa = { "CalleVehiculo", "CalleJardinera", "CallePuesto", "CalleJardinera" },
		Nivalis = { "CalleCajas", "CalleJardinera", "CalleGenerador", "CallePuesto" },
		Umbria = { "CalleCajas", "CalleJardinera", "CalleCajas" },
		Miasma = { "CalleTuberias", "CalleGenerador", "CalleCajas", "CalleVehiculo", "CalleTuberias" },
		Vertice = { "CalleVehiculo", "CallePuesto", "CalleGenerador", "CalleJardinera", "CalleVehiculo" },
	}
	local CityMeshes = require(script.Parent.PlanetCityMeshes)
	local templates: { [string]: any } = {}
	if type(options.Meshes) == "table" then
		templates = options.Meshes
	elseif options.Meshes ~= false then
		local want: { [string]: boolean } = {}
		for _, name in MESH_OF[planet] or {} do
			want[name] = true
		end
		for _, name in PROPS[planet] or {} do
			want[name] = true
		end
		want.CallePuesto = true -- (los puestos de los mercados)
		for name in want do
			if CityMeshes.has(name) then
				templates[name] = CityMeshes.load(name)
				if yield then
					yield()
				end
			end
		end
	end
	local COLLIDER = { Cuerpo = true, Alto = true, Torre = true, Zocalo = true }
	local STRUCT = { Cimientos = true, Plataforma = true, Barandilla = true, Pilote = true, Puntal = true }
	local PROP_BODY: { [string]: { any } } = {}
	local function meshStyle(wall: Color3, strip: Color3, body: string?, bodyColor: Color3?, bodyMat: Enum.Material?)
		return function(group: string, p: BasePart, _sec: string)
			p.CastShadow = group == "Cuerpo" or group == "Techo" -- (sombras solo de lo grande: más ligero)
			if group == "Cuerpo" then
				p.Material = bodyMat or wallMat
				p.Color = bodyColor or wall
				if not bodyColor then
					skin(p, body)
				end
			elseif group == "Cristal" then
				p.Material = Enum.Material.Glass
				p.Color = L.Window
				p.Transparency = 0.2
			elseif group == "Luz" then
				p.Material = Enum.Material.Neon
				p.Color = strip
			elseif group == "Metal" then
				p.Material = Enum.Material.Metal
				p.Color = L.Metal
			elseif group == "Techo" then
				p.Material = Enum.Material.Slate
				p.Color = L.Roof
			elseif group == "Nieve" then
				p.Material = Enum.Material.Snow
				p.Color = L.Snow or rgb(244, 248, 254)
			elseif group == "Toldo" then
				p.Material = Enum.Material.Fabric
				p.Color = L.Awning or L.Accent
			elseif group == "Hoja" then
				p.Material = Enum.Material.Grass
				p.Color = L.Leaf
			elseif group == "Forro" then
				-- (las paredes de dentro: lisas y más claras que la fachada)
				p.Material = Enum.Material.SmoothPlastic
				p.Color = wall:Lerp(Color3.new(1, 1, 1), 0.3)
				p.CastShadow = false
			end
		end
	end
	-- Cambia el edificio de piezas de un solar por su malla: las piezas del cuerpo se quedan, invisibles, para
	-- los choques (andar, la nave); lo demás de piezas se quita
	local function meshify(m: Model, lot: any, cf: CFrame, w: number, d: number, r: () -> number): boolean
		local name = MESH_OF[planet] and MESH_OF[planet][lot.Kind]
		local tpl = name and templates[name]
		if not tpl then
			return false
		end
		if ROUND_KIND[lot.Kind] or name == "CiudadTorre" then
			w = math.min(w, d) -- (redondos: el diámetro es el lado corto del solar)
			d = w
		end
		local h = if FLOORS_KIND[lot.Kind] then lot.Floors * FH else lot.Height
		local E = tpl.Info.Enter
		for _, ch in m:GetChildren() do
			if ch:IsA("BasePart") then
				if COLLIDER[ch.Name] and not E then
					ch.Transparency = 1
					ch.CastShadow = false
					if ch.Name == "Alto" or ch.Name == "Torre" then
						ch.Size = V3(w, ch.Size.Y, d)
					end
				elseif not STRUCT[ch.Name] then
					ch:Destroy()
					stats.Parts -= 1
				end
			end
		end
		if not E then
			-- (sin planta baja en la que entrar, p. ej. el depósito: un cuerpo invisible para chocar)
			local hasBody = false
			for _, ch in m:GetChildren() do
				if ch:IsA("BasePart") and (ch.Name == "Cuerpo" or ch.Name == "Torre" or ch.Name == "Alto") then
					hasBody = true
				end
			end
			if not hasBody then
				Builder.part({ Name = "Cuerpo", Size = V3(w * 0.9, h, d * 0.9), CFrame = cf * CFrame.new(0, h / 2, 0), Transparency = 1, CastShadow = false, Parent = m })
				stats.Parts += 1
			end
		end
		if E then
			-- Se ENTRA en la planta baja: suelo, muros con el hueco de la puerta, techo (lo de arriba, macizo), los
			-- muebles que chocan y una luz. Todo invisible menos el suelo: lo que se ve es la malla.
			local info = tpl.Info
			local kx, kz = w / info.W, d / info.D
			local sb = CityMeshes.layout(info, h)
			local shrink = if E.Round then 0.9 else 1
			local hx, y0, y1 = E.HX * shrink, E.Y0 * shrink, E.Y1 * shrink
			local t = E.T * (if E.Round then 1.6 else 1)
			-- (coordenadas de Blender: x, y = fondo con el frente en -y, z = alto → las del solar: -x, z, y)
			local function col(name: string, x0: number, x1: number, ya: number, yb: number, z0: number, z1: number, visible: boolean?): BasePart
				local part = Builder.part({
					Name = name,
					Size = V3(math.max(0.2, math.abs(x1 - x0) * kx), math.max(0.2, math.abs(z1 - z0) * sb), math.max(0.2, math.abs(yb - ya) * kz)),
					CFrame = cf * CFrame.new(-(x0 + x1) / 2 * kx, (z0 + z1) / 2 * sb, (ya + yb) / 2 * kz),
					Color = L.Ground,
					Material = if haveSkin.CiudadSuelo then Enum.Material.Pavement else Enum.Material.Slate,
					Transparency = if visible then 0 else 1,
					CastShadow = false,
					Parent = m,
				})
				stats.Parts += 1
				return part
			end
			local floor = col("SueloInterior", -hx, hx, y0, y1, E.Floor - 0.6, E.Floor + 0.05, true)
			if haveSkin.CiudadSuelo then
				floor.MaterialVariant = "CiudadSuelo"
			end
			col("MuroIzq", -hx, -hx + t, y0, y1, E.Floor, E.Top)
			col("MuroDer", hx - t, hx, y0, y1, E.Floor, E.Top)
			col("MuroFondo", -hx, hx, y1 - t, y1, E.Floor, E.Top)
			col("MuroFrenteA", -hx, -E.DoorW / 2, y0, y0 + t, E.Floor, E.Top)
			col("MuroFrenteB", E.DoorW / 2, hx, y0, y0 + t, E.Floor, E.Top)
			col("Dintel", -E.DoorW / 2, E.DoorW / 2, y0, y0 + t, E.Floor + E.DoorH, E.Top)
			local topY = E.Top * sb
			if h - topY > 0.5 then
				Builder.part({ Name = "Cuerpo", Size = V3(w, h - topY, d), CFrame = cf * CFrame.new(0, (h + topY) / 2, 0), Transparency = 1, CastShadow = false, Parent = m })
				stats.Parts += 1
			end
			for i, sd in E.Solids do
				col("Mueble" .. i, sd[1] - sd[4] / 2, sd[1] + sd[4] / 2, sd[2] - sd[5] / 2, sd[2] + sd[5] / 2, sd[3] - sd[6] / 2, sd[3] + sd[6] / 2)
			end
			local lamp = col("LuzInterior", -0.5, 0.5, (y0 + y1) / 2 - 0.5, (y0 + y1) / 2 + 0.5, E.Top - 2.2, E.Top - 1.2)
			lamp.CanCollide = false
			lamp.CanQuery = false
			local pl = Instance.new("PointLight")
			pl.Color = L.WindowNight or L.Lamp
			pl.Range = 22
			pl.Brightness = 0.9
			pl.Shadows = false
			pl.Parent = lamp
			-- la rampa de la puerta, si el suelo de dentro queda más alto que el de fuera
			local floorY = lot.Base + E.Floor * sb
			local outP = (cf * CFrame.new(0, 0, y0 * kz - 4)).Position
			local gy = if deck then lot.Base else math.max(M.groundY(outP.X - O.X, outP.Z - O.Z), lot.Base - 12)
			local diff = floorY - gy
			if diff > 0.45 then
				local len = math.clamp(diff * 1.9, 3, 16)
				local ang = math.atan2(diff, len)
				local slab = Builder.part({
					Name = "RampaPuerta",
					Size = V3(E.DoorW * kx + 1, 0.5, math.sqrt(len * len + diff * diff) + 0.6),
					CFrame = cf * CFrame.new(0, E.Floor * sb - diff / 2 - 0.25, y0 * kz - len / 2) * CFrame.Angles(-ang, 0, 0),
					Color = L.Ground,
					Material = Enum.Material.Metal,
					Transparency = if E.Ramp then 1 else 0,
					CastShadow = false,
					Parent = m,
				})
				slab:SetAttribute("Diff", diff)
				stats.Parts += 1
			end
			stats.Enterable = (stats.Enterable or 0) + 1
		end
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		local strip = if L.Neon then L.Neon[1 + math.floor(r() * #L.Neon)] else (L.Strip or L.Glow)
		local lit = r() < 0.65
		local housing = HOUSING[lot.Kind] or ROUND_KIND[lot.Kind]
		local _, parts = CityMeshes.place(tpl, m, cf, w, d, h, meshStyle(wall, strip, if housing then BODY_SKIN[planet] else (TECH_SKIN[planet] or "CiudadPanel")))
		for _, p in parts do
			if lit and string.find(p.Name, "_Cristal$") then
				glow(p)
			end
		end
		stats.Meshes += #parts
		stats.MeshBuildings += 1
		return true
	end
	-- Los MERCADOS: puestos de hologramas de malla en lugar de los de piezas (2 a 4, según el solar)
	local function meshMarket(m: Model, lot: any, cf: CFrame, w: number, d: number, r: () -> number): boolean
		local tpl = templates.CallePuesto
		if lot.Kind ~= "Mercado" or not tpl then
			return false
		end
		for _, ch in m:GetChildren() do
			if ch:IsA("BasePart") and ch.Name ~= "Suelo" and not STRUCT[ch.Name] then
				ch:Destroy()
				stats.Parts -= 1
			end
		end
		local cols = if w > 34 then 2 else 1
		local rows = if d > 30 then 2 else 1
		local hull = if L.Neon then L.Neon[1 + math.floor(r() * #L.Neon)] else L.Accent
		for i = 1, cols do
			for j = 1, rows do
				local x = (i / (cols + 1) - 0.5) * w
				local z = (j / (rows + 1) - 0.5) * d
				local info = tpl.Info
				local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
				local pm, parts = CityMeshes.place(tpl, m, cf * CFrame.new(x, 0.4, z) * CFrame.Angles(0, (r() - 0.5) * 0.5, 0), info.W, info.D, info.Base, meshStyle(wall, hull, nil, wall, wallMat))
				pm.Name = "Puesto"
				for _, part in parts do
					if string.find(part.Name, "_Cuerpo$") then
						part.CanCollide = true
					end
				end
				stats.Meshes += #parts
			end
		end
		return true
	end

	-- Un objeto de calle junto al edificio (deslizador aparcado, cajas, tuberías, generador, puesto, jardinera):
	-- delante si cabe sin pisar la calle; si no, a un lado
	local function streetProp(m: Model, lot: any, cf: CFrame, w: number, d: number, r: () -> number)
		local list = PROPS[planet]
		if not list or r() > 0.62 then
			return
		end
		local name = list[1 + math.floor(r() * #list)]
		local tpl = templates[name]
		if not tpl then
			return
		end
		local side = if r() < 0.5 then -1 else 1
		local tries = { { side * w * 0.3, -d / 2 - 8.5, 0 }, { side * (w / 2 + 6), -d * 0.15, math.pi / 2 }, { -side * (w / 2 + 6), d * 0.15, math.pi / 2 } }
		if deck then
			-- (en plataformas: en una esquina de la suya, si el edificio deja sitio)
			local rc = lot.Rect
			tries = {}
			for _, c in { { rc.X0 + 4.5, rc.Z0 + 4.5 }, { rc.X1 - 4.5, rc.Z0 + 4.5 }, { rc.X0 + 4.5, rc.Z1 - 4.5 }, { rc.X1 - 4.5, rc.Z1 - 4.5 } } do
				local q = cf:PointToObjectSpace(W(c[1], c[2], lot.Base))
				table.insert(tries, { q.X, q.Z, if math.abs(q.X) > w / 2 + 2.5 then math.pi / 2 else 0 })
			end
			if side < 0 then
				tries[1], tries[4] = tries[4], tries[1]
			end
		end
		for _, o in tries do
			local p = (cf * CFrame.new(o[1], 0, o[2])).Position
			local lx, lz = p.X - O.X, p.Z - O.Z
			local ok, y = false, lot.Base
			if deck then
				ok = (math.abs(o[1]) > w / 2 + 4 or math.abs(o[2]) > d / 2 + 4) and name ~= "CalleVehiculo"
					or (math.abs(o[1]) > w / 2 + 6.5 or math.abs(o[2]) > d / 2 + 6.5)
			else
				y = M.groundY(lx, lz)
				ok = not M.streetAt(lx, lz) and M.lotAt(lx, lz, 3) == nil and math.abs(y - lot.Base) < 2.5
			end
			if ok then
				local body = PROP_BODY[name]
				local hull = if L.Neon then L.Neon[1 + math.floor(r() * #L.Neon)] else L.Accent
				local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
				local bodyColor: Color3 = if body then body[1] elseif name == "CalleVehiculo" then hull else wall
				local bodyMat: Enum.Material = if body then body[2] elseif name == "CalleVehiculo" then Enum.Material.Metal else wallMat
				local info = tpl.Info
				local pcf = CFrame.new(W(lx, lz, y)) * (cf - cf.Position) * CFrame.Angles(0, o[3], 0)
				local pm, parts = CityMeshes.place(tpl, m, pcf, info.W, info.D, info.Base, meshStyle(wall, L.Strip or L.Glow, nil, bodyColor, bodyMat))
				pm.Name = "Calle_" .. name
				for _, part in parts do
					if string.find(part.Name, "_Cuerpo$") or string.find(part.Name, "_Metal$") then
						part.CanCollide = true
					end
				end
				stats.Props += 1
				stats.Meshes += #parts
				return
			end
		end
	end

	---------------------------------------------------------------------
	-- Piezas comunes de los edificios (cf: centro de la base, LookVector hacia la calle)
	---------------------------------------------------------------------
	local function windows(m: Model, cf: CFrame, w: number, d: number, y0: number, floors: number, r: () -> number, maxBands: number?)
		local step = math.max(1, math.ceil(floors / (maxBands or 12)))
		for i = 0, floors - 1, step do
			local band = mk(m, "Ventanas", cf * CFrame.new(0, y0 + i * FH + FH * 0.55, 0), V3(w + 0.3, FH * 0.42 * math.min(step, 2), d + 0.3), L.Window, Enum.Material.Glass, { Decor = true })
			if r() < 0.55 then
				glow(band)
			end
		end
	end
	local function door(m: Model, cf: CFrame, d: number, width: number?, height: number?)
		mk(m, "Puerta", cf * CFrame.new(0, (height or 9) / 2, -d / 2 - 0.25), V3(width or 6, height or 9, 0.6), darker(L.Trim, 0.6), Enum.Material.Wood, { Decor = true })
		mk(m, "Marquesina", cf * CFrame.new(0, (height or 9) + 0.6, -d / 2 - 1.5), V3((width or 6) + 3, 0.5, 3), L.Accent, trimMat, { Decor = true })
	end
	local function roof(m: Model, cf: CFrame, w: number, d: number, top: number, kind: string, r: () -> number)
		if kind == "Pitched" then
			local hr = math.min(w, d) * 0.32 + 2
			mk(m, "TejadoA", cf * CFrame.new(0, top + hr / 2, -d / 4), V3(w + 1.2, hr, d / 2 + 0.6), L.Roof, Enum.Material.Slate, { Class = "WedgePart" })
			mk(m, "TejadoB", cf * CFrame.new(0, top + hr / 2, d / 4) * CFrame.Angles(0, math.pi, 0), V3(w + 1.2, hr, d / 2 + 0.6), L.Roof, Enum.Material.Slate, { Class = "WedgePart" })
			if L.Snow then
				mk(m, "NieveA", cf * CFrame.new(0, top + hr / 2 + 0.35, -d / 4 - 0.1), V3(w + 1.3, hr * 0.92, d / 2 + 0.4), L.Snow, Enum.Material.Snow, { Class = "WedgePart", Decor = true })
				mk(m, "NieveB", cf * CFrame.new(0, top + hr / 2 + 0.35, d / 4 + 0.1) * CFrame.Angles(0, math.pi, 0), V3(w + 1.3, hr * 0.92, d / 2 + 0.4), L.Snow, Enum.Material.Snow, { Class = "WedgePart", Decor = true })
			end
		elseif kind == "Spire" then
			mk(m, "Cornisa", cf * CFrame.new(0, top + 0.6, 0), V3(w + 1, 1.2, d + 1), L.Trim, trimMat)
			spire(m, cf, math.min(w, d) * 0.55, top + 1.2, math.min(w, d) * 0.9 + 6)
			if L.Snow then
				mk(m, "Nieve", cf * CFrame.new(0, top + 1.3, 0), V3(w + 0.6, 0.3, d + 0.6), L.Snow, Enum.Material.Snow, { Decor = true })
			end
		elseif kind == "Dome" and r() < 0.45 then
			-- (no todas con cúpula: azotea con pretil y, a veces, una cúpula pequeña en una esquina)
			mk(m, "Pretil", cf * CFrame.new(0, top + 1, 0), V3(w + 0.8, 2, d + 0.8), L.Trim, trimMat)
			if r() < 0.5 then
				ball(m, "Cupulin", cf * CFrame.new(w * 0.25, top + 1, d * 0.2), math.min(w, d) * 0.35, L.Roof, wallMat)
			end
		elseif kind == "Dome" then
			local s = math.min(w, d) * 0.62
			mk(m, "Cornisa", cf * CFrame.new(0, top + 0.5, 0), V3(w + 1, 1, d + 1), L.Trim, trimMat, { Decor = true })
			ball(m, "Cupula", cf * CFrame.new(0, top, 0), s, L.Roof, wallMat)
		elseif kind == "Cone" then
			local s = math.min(w, d)
			for i = 0, 2 do
				column(m, "Tejado" .. i, cf * CFrame.new(0, top + i * 3.2, 0), 3.4, s * (1.25 - i * 0.36), L.Roof, Enum.Material.Grass, { Decor = i > 0 })
			end
		else
			-- plano o con pretil: losa, pretil y alguna máquina en la azotea
			mk(m, "Pretil", cf * CFrame.new(0, top + 0.8, 0), V3(w + 1, 1.6, d + 1), L.Trim, trimMat)
			if r() < 0.6 then
				mk(m, "Maquina", cf * CFrame.new((r() - 0.5) * w * 0.4, top + 3, (r() - 0.5) * d * 0.4), V3(math.min(8, w * 0.3), 3, math.min(6, d * 0.3)), L.Metal, Enum.Material.Metal, { Decor = true })
			end
			if L.Snow then
				mk(m, "Nieve", cf * CFrame.new(0, top + 1.7, 0), V3(w + 0.6, 0.3, d + 0.6), L.Snow, Enum.Material.Snow, { Decor = true })
			end
		end
	end
	-- Luces de ciencia ficción (como la hoja del dueño): dos franjas de neón en las esquinas de la fachada y una
	-- banda arriba, del color del planeta (L.Strip)
	local function accents(m: Model, cf: CFrame, w: number, d: number, h: number, r: () -> number)
		local c = L.Strip or L.Glow
		for _, sx in { -1, 1 } do
			mk(m, "Franja", cf * CFrame.new(sx * (w / 2 + 0.15), h / 2, -d / 2 - 0.15), V3(0.45, h * 0.94, 0.45), c, Enum.Material.Neon, { Decor = true })
		end
		if r() < 0.7 then
			mk(m, "Banda", cf * CFrame.new(0, h - 1.4, 0), V3(w + 0.5, 0.6, d + 0.5), c, Enum.Material.Neon, { Decor = true })
		end
	end
	-- Pantalla holográfica en la fachada (como en la hoja de estética: paneles de luz con un anuncio)
	local SCREEN_TEXT = {
		Tefra = { "⚠ ZONA DE FORJA", "GUARDIA", "RACIONES" },
		Siroco = { "AGUA FRESCA", "LA RECTA", "MOTORES" },
		Talasa = { "NÁCAR", "PRESIÓN OK", "BUCEO" },
		Nivalis = { "AURORA", "LANA", "FAROLES" },
		Umbria = { "SAVIA", "SEMILLAS", "VIVERO" },
		Miasma = { "☢ FILTROS", "GAS", "RACIONES" },
		Vertice = { "CRÉDITO YA", "HOLOVIA", "LUZ+", "NEXO" },
	}
	local function screen(m: Model, cf: CFrame, w: number, d: number, h: number, r: () -> number)
		local list = SCREEN_TEXT[planet] or { "TIENDA" }
		local sw = math.clamp(w * 0.55, 6, 16)
		local sh = math.clamp(sw * 0.6, 4, 10)
		local y = math.clamp(h * (0.45 + r() * 0.3), 10, math.max(10, h - sh))
		local c = if L.Neon then L.Neon[1 + math.floor(r() * #L.Neon)] else (L.Strip or L.Glow)
		local frame = mk(m, "Marco", cf * CFrame.new((r() - 0.5) * w * 0.3, y, -d / 2 - 0.35), V3(sw + 0.8, sh + 0.8, 0.3), c, Enum.Material.Neon, { Decor = true })
		local panel = mk(m, "Pantalla", frame.CFrame * CFrame.new(0, 0, -0.2), V3(sw, sh, 0.2), rgb(12, 16, 26), Enum.Material.SmoothPlastic, { Decor = true })
		Builder.sign(panel, list[1 + math.floor(r() * #list)], Enum.NormalId.Front, c, rgb(12, 16, 26))
	end

	-- Remate en aguja: escalones que se estrechan y una punta de luz
	local function spire(m: Model, cf: CFrame, base: number, top: number, tall: number)
		local tiers = 4
		for i = 0, tiers - 1 do
			local k = 1 - i / tiers
			column(m, "Aguja" .. i, cf * CFrame.new(0, top + i * tall / tiers, 0), tall / tiers + 0.2, math.max(1.2, base * k), if i % 2 == 0 then L.Roof else L.Trim, if i % 2 == 0 then wallMat else trimMat, { Decor = i > 1 })
		end
		column(m, "Punta", cf * CFrame.new(0, top + tall, 0), tall * 0.45, math.max(0.6, base * 0.12), L.Strip or L.Glow, Enum.Material.Neon, { Decor = true })
	end

	local function sign(m: Model, cf: CFrame, d: number, y: number, text: string, color: Color3)
		local board = mk(m, "Cartel", cf * CFrame.new(0, y, -d / 2 - 0.5), V3(math.min(16, 4 + #text * 1.1), 3, 0.4), darker(L.Trim, 0.5), Enum.Material.SmoothPlastic, { Decor = true })
		Builder.sign(board, text, Enum.NormalId.Front, color, nil)
	end
	local function neonStrips(m: Model, cf: CFrame, w: number, d: number, h: number, r: () -> number)
		local list = L.Neon or { L.Accent }
		local c = list[1 + math.floor(r() * #list)]
		for _, sx in { -1, 1 } do
			mk(m, "Neon", cf * CFrame.new(sx * (w / 2 + 0.2), h / 2, -d / 2 - 0.2), V3(0.5, h * 0.9, 0.5), c, Enum.Material.Neon, { Decor = true })
		end
	end
	local function tree(m: Model, cf: CFrame, size: number, r: () -> number)
		if treeKind == "Pine" then
			column(m, "Tronco", cf, size * 0.5, 1.2, L.Trunk, Enum.Material.Wood, { Decor = true })
			for i = 0, 2 do
				column(m, "Pino" .. i, cf * CFrame.new(0, size * 0.3 + i * size * 0.22, 0), size * 0.24, size * (0.62 - i * 0.18), L.Leaf, Enum.Material.Grass, { Decor = true })
				if L.Snow then
					column(m, "Nieve" .. i, cf * CFrame.new(0, size * 0.3 + i * size * 0.22 + size * 0.24, 0), 0.4, size * (0.5 - i * 0.16), L.Snow, Enum.Material.Snow, { Decor = true })
				end
			end
		elseif treeKind == "Palm" then
			column(m, "Tronco", cf, size, 1.3, L.Trunk, Enum.Material.Wood, { Decor = true })
			for i = 1, 4 do
				mk(m, "Hoja", cf * CFrame.new(0, size, 0) * CFrame.Angles(0, i * math.pi / 2 + r(), 0) * CFrame.new(0, -0.6, -size * 0.22) * CFrame.Angles(math.rad(-20), 0, 0), V3(2.2, 0.3, size * 0.45), L.Leaf, Enum.Material.Grass, { Decor = true })
			end
		elseif treeKind == "Dead" then
			column(m, "Tronco", cf, size * 0.8, 1.4, L.Trunk, Enum.Material.Wood, { Decor = true })
			for i = 1, 2 do
				mk(m, "Rama", cf * CFrame.new(0, size * (0.45 + i * 0.12), 0) * CFrame.Angles(0, i * 2.2 + r(), 0) * CFrame.Angles(0, 0, math.rad(50)) * CFrame.new(0, size * 0.15, 0), V3(0.7, size * 0.3, 0.7), L.Trunk, Enum.Material.Wood, { Decor = true })
			end
		elseif treeKind == "Coral" then
			for i = 1, 3 do
				column(m, "Coral", cf * CFrame.new((r() - 0.5) * 3, 0, (r() - 0.5) * 3), size * (0.4 + r() * 0.5), 1 + r() * 1.5, L.Leaf, Enum.Material.Neon, { Decor = true })
			end
		elseif treeKind == "Fungus" then
			column(m, "Pie", cf, size * 0.6, 1.4, L.Trunk, Enum.Material.Slate, { Decor = true })
			column(m, "Sombrero", cf * CFrame.new(0, size * 0.6, 0), 1.6, size * 0.7, L.Leaf, Enum.Material.Neon, { Decor = true })
		else
			column(m, "Tronco", cf, size * 0.55, 1.4, L.Trunk, Enum.Material.Wood, { Decor = true })
			ball(m, "Copa", cf * CFrame.new(0, size * 0.65, 0), size * 0.6, L.Leaf, Enum.Material.Grass, { Decor = true })
		end
	end

	---------------------------------------------------------------------
	-- Los tipos de edificio
	---------------------------------------------------------------------
	local draw: { [string]: (Model, CFrame, any, number, number, () -> number) -> () } = {}

	draw.Bloque = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		mk(m, "Cuerpo", cf * CFrame.new(0, h / 2, 0), V3(w, h, d), wall, wallMat)
		windows(m, cf, w, d, FH * 0.15, lot.Floors, r)
		door(m, cf, d)
		roof(m, cf, w, d, h, if L.RoofKind == "Pitched" or L.RoofKind == "Cone" then "Flat" else L.RoofKind, r)
		if L.Neon then
			neonStrips(m, cf, w, d, h, r)
		else
			accents(m, cf, w, d, h, r)
		end
		if r() < 0.3 then
			sign(m, cf, d, 11.5, brands[1 + math.floor(r() * #brands)], L.Accent)
		end
		if h >= 24 and r() < 0.45 then
			screen(m, cf, w, d, h, r)
		end
	end

	draw.Torre = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		if planet == "Nivalis" or planet == "Talasa" or planet == "Umbria" then
			-- torre redonda (piedra con tejado de pico, o blanca con anillo de cristal)
			local s = math.min(w, d)
			column(m, "Cuerpo", cf, h, s, wall, wallMat)
			for i = 1, math.min(lot.Floors, 8) do
				local band = column(m, "Ventanas", cf * CFrame.new(0, i * (h / (math.min(lot.Floors, 8) + 1)), 0), 1.6, s + 0.4, L.Window, Enum.Material.Glass, { Decor = true })
				if r() < 0.5 then
					glow(band)
				end
			end
			if planet == "Talasa" then
				column(m, "Anillo", cf * CFrame.new(0, h * 0.7, 0), 2, s * 1.6, L.Trim, trimMat)
				ball(m, "Remate", cf * CFrame.new(0, h, 0), s * 0.9, L.Roof, Enum.Material.Glass, { Transparency = 0.25 })
			else
				for i = 0, 3 do
					column(m, "Pico" .. i, cf * CFrame.new(0, h + i * 3, 0), 3.2, s * (1.2 - i * 0.3), L.Roof, Enum.Material.Slate, { Decor = i > 0 })
				end
				if L.Snow then
					column(m, "Nieve", cf * CFrame.new(0, h + 12, 0), 1.4, s * 0.2, L.Snow, Enum.Material.Snow, { Decor = true })
				end
			end
			mk(m, "Puerta", cf * CFrame.new(0, 4.5, -s / 2 - 0.1), V3(5, 9, 1), darker(L.Trim, 0.6), Enum.Material.Wood, { Decor = true })
			return
		end
		-- torre de esquinas: cuerpo, un retranqueo arriba y la antena
		local h1 = math.floor(h * 0.72)
		mk(m, "Cuerpo", cf * CFrame.new(0, h1 / 2, 0), V3(w, h1, d), wall, wallMat)
		mk(m, "Alto", cf * CFrame.new(0, h1 + (h - h1) / 2, 0), V3(w * 0.72, h - h1, d * 0.72), darker(wall, 0.9), wallMat)
		windows(m, cf, w, d, FH * 0.15, math.floor(h1 / FH), r)
		windows(m, cf, w * 0.72, d * 0.72, h1, math.floor((h - h1) / FH), r, 4)
		door(m, cf, d, 8, 10)
		roof(m, cf, w * 0.72, d * 0.72, h, "Flat", r)
		if r() < 0.5 then
			screen(m, cf, w, d, h1, r)
		end
		if L.RoofKind == "Spire" then
			spire(m, cf, math.min(w, d) * 0.6, h + 1, math.min(w, d) + 10)
		else
			column(m, "Antena", cf * CFrame.new(0, h, 0), 12, 0.5, L.Metal, Enum.Material.Metal, { Decor = true })
		end
		if L.Neon then
			neonStrips(m, cf, w, d, h1, r)
		else
			accents(m, cf, w, d, h1, r)
		end
	end

	draw.Rascacielos = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		local podium = FH * 2
		mk(m, "Zocalo", cf * CFrame.new(0, podium / 2, 0), V3(w, podium, d), darker(wall, 0.8), Enum.Material.Concrete)
		local tw, td = w * 0.74, d * 0.74
		mk(m, "Torre", cf * CFrame.new(0, podium + (h - podium) / 2, 0), V3(tw, h - podium, td), wall, wallMat)
		windows(m, cf, tw, td, podium, math.floor((h - podium) / FH), r, 14)
		door(m, cf, d, 10, 12)
		-- la corona de neón, la antena y la luz roja para las lanzaderas
		local list = L.Neon or { L.Accent }
		local c = list[1 + math.floor(r() * #list)]
		mk(m, "Corona", cf * CFrame.new(0, h - 2, 0), V3(tw + 0.6, 2.4, td + 0.6), c, Enum.Material.Neon, { Decor = true })
		mk(m, "Azotea", cf * CFrame.new(0, h + 0.6, 0), V3(tw + 0.4, 1.2, td + 0.4), L.Trim, trimMat)
		column(m, "Antena", cf * CFrame.new(0, h + 1.2, 0), 22 + r() * 18, 0.7, L.Metal, Enum.Material.Metal, { Decor = true })
		ball(m, "Baliza", cf * CFrame.new(0, h + 36, 0), 1.6, rgb(255, 40, 40), Enum.Material.Neon, { Decor = true })
		-- un anuncio enorme en la fachada
		if r() < 0.5 then
			local board = mk(m, "Anuncio", cf * CFrame.new(0, podium + (h - podium) * 0.45, -td / 2 - 0.6), V3(tw * 0.8, math.min(26, h * 0.18), 0.5), rgb(10, 10, 16), Enum.Material.SmoothPlastic, { Decor = true })
			Builder.sign(board, brands[1 + math.floor(r() * #brands)], Enum.NormalId.Front, c, rgb(10, 10, 16))
		end
	end

	draw.Casa = function(m, cf, lot, w, d, r)
		local h = lot.Floors * FH
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		mk(m, "Cuerpo", cf * CFrame.new(0, h / 2, 0), V3(w, h, d), wall, wallMat)
		windows(m, cf, w, d, FH * 0.15, lot.Floors, r)
		door(m, cf, d, 5, 8)
		roof(m, cf, w, d, h, L.RoofKind, r)
		if r() < 0.5 then
			accents(m, cf, w, d, h, r)
		end
		if planet == "Nivalis" or planet == "Tefra" then
			mk(m, "Chimenea", cf * CFrame.new(w * 0.28, h + 5, d * 0.2), V3(2.2, 8, 2.2), darker(wall, 0.7), wallMat)
		end
		if planet == "Siroco" and r() < 0.5 then
			mk(m, "Toldo", cf * CFrame.new(0, 8.5, -d / 2 - 2) * CFrame.Angles(math.rad(14), 0, 0), V3(w * 0.7, 0.3, 4), L.Accent, Enum.Material.Fabric, { Decor = true })
		end
	end

	draw.Cupula = function(m, cf, lot, w, d, r)
		local s = math.min(w, d)
		local h = lot.Floors * FH
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		column(m, "Tambor", cf, h, s, wall, wallMat)
		local band = column(m, "Ventanas", cf * CFrame.new(0, h * 0.55, 0), 2, s + 0.4, L.Window, Enum.Material.Glass, { Decor = true })
		glow(band)
		local glass = planet == "Talasa" or planet == "Vertice"
		ball(m, "Cupula", cf * CFrame.new(0, h, 0), s * 0.96, L.Roof, if glass then Enum.Material.Glass else wallMat, { Transparency = if glass then 0.3 else nil })
		ball(m, "Remate", cf * CFrame.new(0, h + s * 0.48, 0), 2, L.Accent, Enum.Material.Neon, { Decor = true })
		mk(m, "Puerta", cf * CFrame.new(0, 5, -s / 2 - 0.2), V3(6, 10, 1.4), darker(L.Trim, 0.6), Enum.Material.Wood, { Decor = true })
	end

	draw.Nave = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		mk(m, "Muros", cf * CFrame.new(0, h / 2, 0), V3(w, h, d), wall, Enum.Material.Metal)
		-- techo en arco (medio cilindro tumbado a lo largo)
		mk(m, "Arco", cf * CFrame.new(0, h, 0) * CFrame.Angles(0, math.pi / 2, 0), V3(d, math.min(w, 34), w), L.Roof, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		mk(m, "Porton", cf * CFrame.new(0, h * 0.38, -d / 2 - 0.2), V3(w * 0.55, h * 0.72, 0.6), darker(L.Metal, 0.7), Enum.Material.DiamondPlate, { Decor = true })
		local lamp = mk(m, "Foco", cf * CFrame.new(0, h * 0.8, -d / 2 - 0.6), V3(4, 0.8, 0.8), L.WindowNight, Enum.Material.Neon, { Decor = true })
		glow(lamp)
		if r() < 0.4 then
			sign(m, cf, d, h * 0.86, brands[1 + math.floor(r() * #brands)], L.Accent)
		end
	end

	draw.Fundicion = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		mk(m, "Nave", cf * CFrame.new(-w * 0.12, h / 2, 0), V3(w * 0.76, h, d), wall, wallMat)
		roof(m, cf * CFrame.new(-w * 0.12, 0, 0), w * 0.76, d, h, "Flat", r)
		local n = 2 + math.floor(r() * 2)
		for i = 1, n do
			local z = (i / (n + 1) - 0.5) * d
			local ch = h + 18 + r() * 24
			column(m, "Chimenea", cf * CFrame.new(w * 0.36, 0, z), ch, 4, darker(wall, 0.75), Enum.Material.Brick)
			column(m, "Brasa", cf * CFrame.new(w * 0.36, ch - 1.2, z), 1.4, 4.3, L.Glow, Enum.Material.Neon, { Decor = true })
			if i == 1 then
				local top = mk(m, "Humo", cf * CFrame.new(w * 0.36, ch + 1, z), V3(1, 1, 1), L.Glow, Enum.Material.SmoothPlastic, { Decor = true, Transparency = 1 })
				local pe = Instance.new("ParticleEmitter")
				pe.Name = "Humo"
				pe.Rate = 3
				pe.Lifetime = NumberRange.new(5, 8)
				pe.Speed = NumberRange.new(3, 6)
				pe.SpreadAngle = Vector2.new(12, 12)
				pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 12) })
				pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
				pe.Color = ColorSequence.new(rgb(70, 66, 64))
				pe.Acceleration = V3(2, 1, 0)
				pe.Parent = top
			end
		end
		local mouth = mk(m, "Horno", cf * CFrame.new(-w * 0.12, 4, -d / 2 - 0.2), V3(w * 0.4, 6, 0.6), L.Glow, Enum.Material.Neon, { Decor = true })
		glow(mouth)
	end

	draw.Bunker = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		mk(m, "Cuerpo", cf * CFrame.new(0, h / 2, 0), V3(w, h, d), wall, Enum.Material.Concrete)
		mk(m, "Tronera", cf * CFrame.new(0, h * 0.62, 0), V3(w + 0.4, 1.2, d + 0.4), rgb(14, 14, 16), Enum.Material.SmoothPlastic, { Decor = true })
		mk(m, "Techo", cf * CFrame.new(0, h + 0.9, 0), V3(w + 2, 1.8, d + 2), darker(wall, 0.8), Enum.Material.Concrete)
		for _, sx in { -1, 1 } do
			mk(m, "Sacos", cf * CFrame.new(sx * w * 0.28, 1.4, -d / 2 - 3), V3(w * 0.3, 2.8, 2.4), rgb(120, 104, 80), Enum.Material.Fabric)
		end
		mk(m, "Puerta", cf * CFrame.new(0, 4, -d / 2 - 0.2), V3(5, 8, 0.6), L.Metal, Enum.Material.DiamondPlate, { Decor = true })
	end

	draw.Mercado = function(m, cf, lot, w, d, r)
		mk(m, "Suelo", cf * CFrame.new(0, 0.2, 0), V3(w, 0.4, d), L.Ground, Enum.Material.Pavement)
		local cols = if w > 34 then 3 else 2
		local rows = if d > 34 then 2 else 1
		for i = 1, cols do
			for j = 1, rows do
				local x = (i / (cols + 1) - 0.5) * w
				local z = (j / (rows + 1) - 0.5) * d
				local c = cf * CFrame.new(x, 0, z)
				mk(m, "Mostrador", c * CFrame.new(0, 1.8, 0), V3(8, 3.2, 3), L.Trim, Enum.Material.Wood)
				local awn = L.Neon and L.Neon[1 + math.floor(r() * #L.Neon)] or (if r() < 0.7 then (L.Awning or L.Accent) else L.Walls[1])
				mk(m, "Toldo", c * CFrame.new(0, 8.4, -0.6) * CFrame.Angles(math.rad(10), 0, 0), V3(9.4, 0.3, 6.6), awn, Enum.Material.Fabric, { Decor = true })
				for _, sx in { -1, 1 } do
					mk(m, "Poste", c * CFrame.new(sx * 4.4, 4, -3.4), V3(0.4, 8, 0.4), L.Metal, Enum.Material.Metal, { Decor = true })
				end
				mk(m, "Caja", c * CFrame.new((r() - 0.5) * 4, 3.9, 0), V3(2, 1, 1.6), L.Accent, Enum.Material.Wood, { Decor = true })
				local lamp = mk(m, "Bombilla", c * CFrame.new(0, 7.6, -1), V3(0.8, 0.8, 0.8), L.WindowNight, Enum.Material.Neon, { Decor = true })
				glow(lamp)
			end
		end
	end

	draw.Plaza = function(m, cf, lot, w, d, r)
		mk(m, "Losas", cf * CFrame.new(0, 0.2, 0), V3(w, 0.4, d), L.Ground, Enum.Material.Pavement)
		-- el centro: una fuente (o un brasero, un obelisco de hielo, un holograma… según el planeta)
		column(m, "Pilon", cf * CFrame.new(0, 0.4, 0), 2.2, 16, L.Trim, wallMat)
		column(m, "Agua", cf * CFrame.new(0, 0.4, 0), 2.4, 14, L.Glow, if planet == "Tefra" or planet == "Vertice" or planet == "Miasma" then Enum.Material.Neon else Enum.Material.Glass, { Decor = true, Transparency = if planet == "Tefra" or planet == "Vertice" or planet == "Miasma" then 0.1 else 0.35 })
		mk(m, "Monumento", cf * CFrame.new(0, 7, 0), V3(2.6, 13, 2.6), L.Walls[1], wallMat)
		ball(m, "Remate", cf * CFrame.new(0, 14.4, 0), 3, L.Accent, Enum.Material.Neon, { Decor = true })
		for i = 0, 3 do
			local a = i * math.pi / 2 + math.pi / 4
			local c = cf * CFrame.new(math.cos(a) * w * 0.33, 0, math.sin(a) * d * 0.33) * CFrame.Angles(0, -a + math.pi / 2, 0)
			mk(m, "Banco", c * CFrame.new(0, 1.3, 0), V3(6, 0.6, 2), L.Trim, Enum.Material.Wood)
			if i % 2 == 0 then
				tree(m, cf * CFrame.new(math.cos(a + 0.5) * w * 0.4, 0.4, math.sin(a + 0.5) * d * 0.4), 14 + r() * 6, r)
			end
		end
	end

	-- El parque de cada planeta: lo que más se ve en la hoja de estética (lava, charcas tóxicas, cascadas…)
	local function parqueRio(m: Model, cf: CFrame, w: number, d: number, r: () -> number, liquid: Color3, liquidMat: Enum.Material, transp: number, rock: Color3, rockMat: Enum.Material, fallMat: Enum.Material?)
		mk(m, "Orilla", cf * CFrame.new(0, 0.2, 0), V3(w, 0.4, d), rock, rockMat)
		local pool = mk(m, "Charca", cf * CFrame.new(0, 0.45, d * 0.08), V3(w * 0.78, 0.3, d * 0.62), liquid, liquidMat, { Decor = true, Transparency = transp })
		local pl = Instance.new("PointLight")
		pl.Color = liquid
		pl.Range = 28
		pl.Brightness = if liquidMat == Enum.Material.Neon then 1.6 else 0.6
		pl.Shadows = false
		pl.Parent = pool
		-- el risco del fondo y la cascada que cae a la charca
		local back = cf * CFrame.new(0, 0, -d * 0.36)
		local ch = 14 + r() * 12
		mk(m, "Risco", back * CFrame.new(0, ch / 2, 0), V3(w * 0.7, ch, d * 0.22), rock, rockMat)
		local fall = mk(m, "Cascada", back * CFrame.new(0, ch / 2, d * 0.115), V3(w * 0.24, ch, 0.8), liquid, fallMat or liquidMat, { Decor = true, Transparency = transp })
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(if liquidMat == Enum.Material.Neon then liquid else Color3.new(1, 1, 1))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(1, 2)
		pe.Rate = 5
		pe.Speed = NumberRange.new(1, 3)
		pe.EmissionDirection = Enum.NormalId.Bottom
		pe.LightEmission = if liquidMat == Enum.Material.Neon then 0.8 else 0
		pe.Parent = fall
		for i = 1, 3 do
			tree(m, cf * CFrame.new((i - 2) * w * 0.34, 0.4, d * 0.4), 12 + r() * 8, r)
		end
	end

	draw.Parque = function(m, cf, lot, w, d, r)
		if planet == "Tefra" then
			return parqueRio(m, cf, w, d, r, L.Glow, Enum.Material.Neon, 0.05, rgb(40, 34, 32), Enum.Material.Basalt)
		elseif planet == "Miasma" then
			return parqueRio(m, cf, w, d, r, rgb(130, 255, 60), Enum.Material.Neon, 0.15, rgb(60, 64, 60), Enum.Material.Metal)
		elseif planet == "Nivalis" then
			return parqueRio(m, cf, w, d, r, rgb(170, 225, 255), Enum.Material.Ice, 0.2, rgb(200, 224, 245), Enum.Material.Ice)
		elseif planet == "Umbria" then
			return parqueRio(m, cf, w, d, r, rgb(110, 200, 220), Enum.Material.Glass, 0.3, rgb(70, 74, 58), Enum.Material.Slate)
		elseif planet == "Siroco" then
			return parqueRio(m, cf, w, d, r, rgb(70, 190, 220), Enum.Material.Glass, 0.25, rgb(200, 150, 100), Enum.Material.Sandstone)
		elseif planet == "Talasa" then
			return parqueRio(m, cf, w, d, r, rgb(60, 220, 240), Enum.Material.Neon, 0.45, rgb(210, 218, 226), Enum.Material.SmoothPlastic, Enum.Material.Glass)
		end
		mk(m, "Cesped", cf * CFrame.new(0, 0.2, 0), V3(w, 0.4, d), darker(L.Leaf, 0.8), if treeKind == "Coral" or treeKind == "Fungus" or treeKind == "Dead" then Enum.Material.Ground else Enum.Material.Grass)
		mk(m, "Camino", cf * CFrame.new(0, 0.45, 0), V3(4, 0.2, d), L.Ground, Enum.Material.Pavement, { Decor = true })
		for i = 1, 5 do
			tree(m, cf * CFrame.new((r() - 0.5) * w * 0.8, 0.4, (r() - 0.5) * d * 0.8), 12 + r() * 10, r)
		end
		mk(m, "Banco", cf * CFrame.new(4, 1.3, 0), V3(2, 0.6, 6), L.Trim, Enum.Material.Wood)
	end

	draw.Jardin = function(m, cf, lot, w, d, r)
		mk(m, "Muro", cf * CFrame.new(0, 1.5, 0), V3(w, 3, d), L.Walls[1], wallMat)
		mk(m, "Invernadero", cf * CFrame.new(0, 3 + (lot.Height - 3) / 2, 0), V3(w - 1, lot.Height - 3, d - 1), L.Window, Enum.Material.Glass, { Transparency = 0.55 })
		for i = 1, 3 do
			mk(m, "Cultivo", cf * CFrame.new(0, 3.4, (i / 4 - 0.5) * d), V3(w * 0.8, 0.8, 2.2), L.Leaf, Enum.Material.Grass, { Decor = true })
		end
		local lamp = mk(m, "Luz", cf * CFrame.new(0, lot.Height - 0.6, 0), V3(w * 0.6, 0.4, 0.8), L.WindowNight, Enum.Material.Neon, { Decor = true })
		glow(lamp)
	end

	draw.Arbol = function(m, cf, lot, w, d, r)
		-- árbol gigante: tronco, raíces, copa y una casa colgada a media altura (se sube por la escalera)
		local h = lot.Height
		local s = math.min(w, d)
		local trunk = math.max(8, s * 0.32)
		column(m, "Tronco", cf * CFrame.new(0, -4, 0), h + 4, trunk, L.Trunk, Enum.Material.Wood)
		for i = 0, 2 do
			mk(m, "Raiz", cf * CFrame.Angles(0, i * 2.1, 0) * CFrame.new(0, 3, -trunk * 0.7), V3(3, 8, trunk * 0.9), L.Trunk, Enum.Material.Wood, { Class = "WedgePart" })
		end
		for i = 0, 2 do
			local a = i * 2.1 + r()
			ball(m, "Copa", cf * CFrame.new(math.cos(a) * s * 0.3, h + (r() - 0.3) * 8, math.sin(a) * s * 0.3), s * (0.8 + r() * 0.3), L.Leaf, Enum.Material.Grass, { Decor = true })
		end
		local py = math.floor(h * 0.42)
		column(m, "Plataforma", cf * CFrame.new(0, py, 0), 1.4, trunk + 16, L.Trim, Enum.Material.WoodPlanks)
		local hut = cf * CFrame.new(0, py + 1.4, -(trunk / 2 + 4))
		mk(m, "Cabana", hut * CFrame.new(0, 4, 0), V3(9, 8, 6), L.Walls[1 + math.floor(r() * #L.Walls)], wallMat)
		mk(m, "TejadoCabana", hut * CFrame.new(0, 8.8, 0), V3(10.5, 1.6, 7.5), L.Roof, Enum.Material.Grass)
		local win = mk(m, "Ventana", hut * CFrame.new(0, 4.4, -3.1), V3(3, 2, 0.3), L.WindowNight, Enum.Material.Neon, { Decor = true })
		glow(win)
		mk(m, "Escalera", cf * CFrame.new(0, py / 2, -(trunk / 2 + 8.6)), V3(2, py, 2), L.Trim, Enum.Material.Wood, { Class = "TrussPart" })
		-- farolillos de luciérnaga
		local bulb = ball(m, "Farolillo", cf * CFrame.new(trunk / 2 + 7, py - 2, 0), 1.2, L.Lamp, Enum.Material.Neon, { Decor = true, Tags = { "StreetLamp" } })
		local pl = Instance.new("PointLight")
		pl.Range = 22
		pl.Brightness = 1.2
		pl.Color = L.Lamp
		pl.Enabled = false
		pl.Shadows = false
		pl.Parent = bulb
	end

	draw.Choza = function(m, cf, lot, w, d, r)
		local s = math.min(w, d)
		local stilt = 6
		for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			mk(m, "Zanco", cf * CFrame.new(c[1] * s * 0.36, stilt / 2 - 1, c[2] * s * 0.36), V3(1, stilt + 2, 1), L.Trunk, Enum.Material.Wood, { Decor = true })
		end
		mk(m, "Tarima", cf * CFrame.new(0, stilt + 0.5, 0), V3(s, 1, s), L.Trim, Enum.Material.WoodPlanks)
		local h = lot.Height - stilt
		column(m, "Choza", cf * CFrame.new(0, stilt + 1, 0), h, s * 0.78, L.Walls[1 + math.floor(r() * #L.Walls)], wallMat)
		for i = 0, 2 do
			column(m, "Techo" .. i, cf * CFrame.new(0, stilt + 1 + h + i * 2.6, 0), 2.8, s * (1.05 - i * 0.32), L.Roof, Enum.Material.Grass, { Decor = i > 0 })
		end
		local win = mk(m, "Ventana", cf * CFrame.new(0, stilt + 5, -s * 0.39 - 0.1), V3(2.6, 2, 0.3), L.WindowNight, Enum.Material.Neon, { Decor = true })
		glow(win)
		mk(m, "Rampa", cf * CFrame.new(0, stilt / 2 + 0.5, -s / 2 - 4) * CFrame.Angles(math.rad(-38), 0, 0), V3(4, 0.6, 10.5), L.Trim, Enum.Material.WoodPlanks)
	end

	draw.Globo = function(m, cf, lot, w, d, r)
		mk(m, "Amarre", cf * CFrame.new(0, 1.5, 0), V3(w * 0.6, 3, d * 0.6), L.Metal, Enum.Material.DiamondPlate)
		column(m, "Mastil", cf * CFrame.new(0, 3, 0), 26, 1, L.Metal, Enum.Material.Metal, { Decor = true })
		local size = math.min(w, d) * 0.9
		local hue = L.Neon and L.Neon[1] or L.Walls[1 + math.floor(r() * #L.Walls)]
		ball(m, "Globo", cf * CFrame.new(0, 34 + size * 0.4, 0), size, if r() < 0.5 then hue else L.Accent, Enum.Material.Fabric, { Decor = true })
		mk(m, "Barquilla", cf * CFrame.new(0, 30, 0), V3(6, 3, 6), L.Trim, Enum.Material.WoodPlanks, { Decor = true })
		for _, c in { { -1, -1 }, { 1, 1 } } do
			mk(m, "Cabo", cf * CFrame.new(c[1] * 2.8, 32 + size * 0.15, c[2] * 2.8), V3(0.2, size * 0.5, 0.2), L.Trunk, Enum.Material.Fabric, { Decor = true })
		end
		local light = ball(m, "Luz", cf * CFrame.new(0, 29, 0), 1, L.WindowNight, Enum.Material.Neon, { Decor = true })
		glow(light)
	end

	draw.Mastil = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local s = math.min(w, d) * 0.5
		for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			mk(m, "Pata", cf * CFrame.new(c[1] * s / 2, h / 2, c[2] * s / 2), V3(1, h, 1), L.Metal, Enum.Material.Metal)
		end
		for y = 10, h - 4, 12 do
			mk(m, "Travesano", cf * CFrame.new(0, y, 0), V3(s + 1, 0.6, s + 1), L.Metal, Enum.Material.Metal, { Decor = true })
		end
		mk(m, "Plataforma", cf * CFrame.new(0, h, 0), V3(s + 4, 1, s + 4), L.Trim, Enum.Material.DiamondPlate)
		mk(m, "Escalera", cf * CFrame.new(0, h / 2, -s / 2 - 1.1), V3(2, h, 2), L.Metal, Enum.Material.Metal, { Class = "TrussPart" })
		if planet == "Miasma" then
			column(m, "Pararrayos", cf * CFrame.new(0, h + 1, 0), 16, 0.6, rgb(200, 200, 210), Enum.Material.Metal, { Decor = true })
			ball(m, "Bola", cf * CFrame.new(0, h + 17, 0), 2.4, L.Glow, Enum.Material.Neon, { Decor = true })
		else
			local light = ball(m, "Faro", cf * CFrame.new(0, h + 2.2, 0), 2, L.Glow, Enum.Material.Neon, { Decor = true })
			glow(light)
		end
	end

	draw.TorreViento = function(m, cf, lot, w, d, r)
		local h = lot.Height
		local s = math.min(w, d) * 0.62
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		mk(m, "Base", cf * CFrame.new(0, 5, 0), V3(math.min(w, d), 10, math.min(w, d)), wall, wallMat)
		mk(m, "Torre", cf * CFrame.new(0, h / 2, s * 0.3), V3(s, h, s), darker(wall, 0.92), wallMat)
		mk(m, "Rejillas", cf * CFrame.new(0, h - 5, s * 0.3), V3(s + 0.4, 4, s + 0.4), rgb(40, 30, 24), Enum.Material.WoodPlanks, { Decor = true })
		mk(m, "Remate", cf * CFrame.new(0, h + 0.6, s * 0.3), V3(s + 1.4, 1.2, s + 1.4), L.Trim, trimMat)
		door(m, cf, math.min(w, d), 5, 8)
	end

	draw.Chatarra = function(m, cf, lot, w, d, r)
		local h = lot.Height
		mk(m, "Cobertizo", cf * CFrame.new(-w * 0.2, h / 2, d * 0.15), V3(w * 0.55, h, d * 0.6), L.Walls[1 + math.floor(r() * #L.Walls)], Enum.Material.Metal)
		mk(m, "Techo", cf * CFrame.new(-w * 0.2, h + 0.3, d * 0.1) * CFrame.Angles(math.rad(-6), 0, 0), V3(w * 0.6, 0.4, d * 0.75), L.Metal, Enum.Material.Metal)
		for i = 1, 5 do
			local c = cf * CFrame.new(w * (0.15 + r() * 0.3), 1 + r() * 2, (r() - 0.5) * d * 0.7) * CFrame.Angles(r() * 0.6, r() * 3, r() * 0.6)
			mk(m, "Chatarra", c, V3(3 + r() * 6, 2 + r() * 3, 3 + r() * 5), if r() < 0.5 then L.Metal else darker(L.Accent, 0.6), Enum.Material.CorrodedMetal)
		end
		local tire = mk(m, "Rueda", cf * CFrame.new(w * 0.3, 1.6, -d * 0.35) * CFrame.Angles(0, 0, math.pi / 2), V3(1.6, 3.2, 3.2), rgb(26, 26, 28), Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder, Decor = true })
		tire.CastShadow = false
	end

	-- Aguja: torre fina de ciencia ficción con un núcleo de luz y una punta altísima (hielo, desierto, volcán)
	draw.Aguja = function(m, cf, lot, w, d, r)
		local s = math.min(w, d)
		local body = lot.Height - 34
		local wall = L.Walls[1 + math.floor(r() * #L.Walls)]
		mk(m, "Base", cf * CFrame.new(0, 4, 0), V3(s, 8, s), L.Trim, trimMat)
		column(m, "Cuerpo", cf * CFrame.new(0, 8, 0), body - 8, s * 0.82, wall, wallMat)
		-- el núcleo de luz que se ve entre las costillas
		column(m, "Nucleo", cf * CFrame.new(0, 10, 0), body - 12, s * 0.86, L.Strip or L.Glow, Enum.Material.Neon, { Decor = true, Transparency = 0.55 })
		for i = 0, 3 do
			local a = i * math.pi / 2 + math.pi / 4
			mk(m, "Costilla", cf * CFrame.new(math.cos(a) * s * 0.42, body / 2 + 4, math.sin(a) * s * 0.42), V3(1.6, body, 1.6), L.Trim, trimMat)
		end
		local band = column(m, "Ventanas", cf * CFrame.new(0, body * 0.55, 0), 2.2, s * 0.9, L.Window, Enum.Material.Glass, { Decor = true })
		glow(band)
		spire(m, cf, s * 0.7, body, 34)
		mk(m, "Puerta", cf * CFrame.new(0, 4.5, -s / 2 - 0.2), V3(5, 9, 0.6), darker(L.Trim, 0.6), Enum.Material.Metal, { Decor = true })
	end

	-- Tanque: depósito de cristal con el líquido que brilla (radiación de Miasma) y sus tuberías
	draw.Tanque = function(m, cf, lot, w, d, r)
		local s = math.min(w, d)
		local h = lot.Height
		mk(m, "Zocalo", cf * CFrame.new(0, 1.5, 0), V3(s, 3, s), L.Trim, trimMat)
		column(m, "Liquido", cf * CFrame.new(0, 3, 0), (h - 6) * (0.55 + r() * 0.35), s * 0.66, L.Glow, Enum.Material.Neon, { Decor = true })
		column(m, "Cristal", cf * CFrame.new(0, 3, 0), h - 6, s * 0.74, L.Window, Enum.Material.Glass, { Transparency = 0.55 })
		for _, y in { 3, h - 3 } do
			column(m, "Aro", cf * CFrame.new(0, y - 1, 0), 2, s * 0.8, L.Metal, Enum.Material.Metal)
		end
		ball(m, "Tapa", cf * CFrame.new(0, h - 3, 0), s * 0.72, L.Roof, wallMat)
		for i = 0, 3 do
			local a = i * math.pi / 2
			mk(m, "Pata", cf * CFrame.new(math.cos(a) * s * 0.4, (h - 4) / 2 + 2, math.sin(a) * s * 0.4), V3(1.2, h - 4, 1.2), L.Metal, Enum.Material.Metal, { Decor = true })
		end
		mk(m, "Tubo", cf * CFrame.new(s * 0.45, h * 0.35, 0), V3(s * 0.4, 1.6, 1.6), L.Metal, Enum.Material.Metal, { Decor = true })
		local light = ball(m, "Aviso", cf * CFrame.new(0, h + s * 0.36 - 2, 0), 1.6, L.Glow, Enum.Material.Neon, { Decor = true })
		glow(light)
	end

	---------------------------------------------------------------------
	-- Plataformas y pasarelas (Deck)
	---------------------------------------------------------------------
	local deckColor = L.Deck or L.Ground
	local deckMat = mat(L.DeckMaterial, Enum.Material.Concrete)
	local function rail(p: Instance, x0: number, x1: number, z0: number, z1: number, y: number)
		mk(p, "Barandilla", CFrame.new(W((x0 + x1) / 2, (z0 + z1) / 2, y + 1.6)), V3(math.max(0.6, x1 - x0), 3.2, math.max(0.6, z1 - z0)), L.Metal, Enum.Material.Metal)
	end
	local function deckUnder(p: Instance, lx: number, lz: number, y: number)
		if planet == "Talasa" then
			local floor = math.min(S.rawHeight(lx, lz), (S.WaterY or 20) - 4)
			mk(p, "Pilote", CFrame.new(W(lx, lz, (floor + y) / 2)) * CFrame.Angles(0, 0, math.pi / 2), V3(y - floor, 2.6, 2.6), L.Pylon or L.Metal, Enum.Material.Concrete, { Shape = Enum.PartType.Cylinder, Decor = true })
		else
			mk(p, "Puntal", CFrame.new(W(lx, lz, y - 22)), V3(2, 40, 2), L.Pylon or L.Metal, Enum.Material.Metal, { Decor = true })
		end
	end
	-- barandilla en los bordes de un rectángulo donde al lado no hay por donde andar (tramos de ~12 studs)
	local function railEdges(p: Instance, rx0: number, rx1: number, rz0: number, rz1: number, y: number)
		local sides = {
			{ ax = "Z", fixed = rz0 - 0.4, out = rz0 - 3, a = rx0, b = rx1 },
			{ ax = "Z", fixed = rz1 + 0.4, out = rz1 + 3, a = rx0, b = rx1 },
			{ ax = "X", fixed = rx0 - 0.4, out = rx0 - 3, a = rz0, b = rz1 },
			{ ax = "X", fixed = rx1 + 0.4, out = rx1 + 3, a = rz0, b = rz1 },
		}
		for _, sd in sides do
			local len = sd.b - sd.a
			local n = math.max(1, math.floor(len / 12))
			local seg = len / n
			local runStart: number? = nil
			local function close(u1: number)
				if runStart then
					if sd.ax == "Z" then
						rail(p, runStart, u1, sd.fixed - 0.3, sd.fixed + 0.3, y)
					else
						rail(p, sd.fixed - 0.3, sd.fixed + 0.3, runStart, u1, y)
					end
					runStart = nil
				end
			end
			for i = 1, n do
				local u0 = sd.a + (i - 1) * seg
				local u = u0 + seg / 2
				local px, pz = if sd.ax == "Z" then u else sd.out, if sd.ax == "Z" then sd.out else u
				local open = not M.walkable(px, pz) and not (S.City and S.City.inside(px, pz, 2))
				if open then
					runStart = runStart or u0
				else
					close(u0)
				end
			end
			close(sd.b)
		end
	end

	---------------------------------------------------------------------
	-- Construir
	---------------------------------------------------------------------
	local lots = M.lots()
	local nearestPlaza: { [string]: { lot: any, d: number } } = {}
	for i, lot in lots do
		local f = folderFor(lot.District)
		local m = Builder.model(lot.Kind .. "_" .. i, f)
		m:SetAttribute("MetroLot", lot.Id)
		local r = rng(lot.Seed)
		r()
		local look = V3(lot.FX, 0, lot.FZ)
		local cf = Builder.facing(W(lot.X, lot.Z, lot.Base), look)
		local w = if lot.FX ~= 0 then lot.D else lot.W
		local d = if lot.FX ~= 0 then lot.W else lot.D
		if deck then
			local rc = lot.Rect
			mk(m, "Plataforma", CFrame.new(W((rc.X0 + rc.X1) / 2, (rc.Z0 + rc.Z1) / 2, lot.Base - 1)), V3(rc.X1 - rc.X0, 2, rc.Z1 - rc.Z0), deckColor, deckMat)
			deckUnder(m, rc.X0 + 3, rc.Z0 + 3, lot.Base - 2)
			deckUnder(m, rc.X1 - 3, rc.Z1 - 3, lot.Base - 2)
			railEdges(m, rc.X0, rc.X1, rc.Z0, rc.Z1, lot.Base)
		elseif lot.Base - lot.Low > 0.6 and lot.Kind ~= "Arbol" then
			-- cimientos hasta el punto más bajo del solar
			local fh = lot.Base - lot.Low + 2
			mk(m, "Cimientos", CFrame.new(W(lot.X, lot.Z, lot.Base - fh / 2)), V3(lot.W + 1.5, fh, lot.D + 1.5), darker(L.Ground, 0.85), mat(L.WallMaterial, Enum.Material.Concrete))
		end
		local fn = draw[lot.Kind] or draw.Bloque
		local ok, err = pcall(fn, m, cf, lot, w, d, r)
		if not ok then
			warn("[PlanetMetroBuilder] " .. planet .. " " .. lot.Kind .. ": " .. tostring(err))
		end
		dress(m, lot.Kind)
		if next(templates) ~= nil then
			local okMesh, errMesh = pcall(function()
				if not meshMarket(m, lot, cf, w, d, r) then
					meshify(m, lot, cf, w, d, r)
				end
				if lot.Kind ~= "Plaza" and lot.Kind ~= "Parque" and lot.Kind ~= "Mercado" and lot.Kind ~= "Jardin" then
					streetProp(m, lot, cf, w, d, r)
				end
			end)
			if not okMesh then
				warn("[PlanetMetroBuilder] malla de " .. planet .. " " .. lot.Kind .. ": " .. tostring(errMesh))
			end
		end
		if lot.Kind ~= "Plaza" and lot.Kind ~= "Parque" then
			stats.Buildings += 1
			Builder.streamable(m)
		end
		if lot.Kind == "Plaza" then
			local dist = math.huge
			for _, dsc in M.Districts do
				if dsc.Id == lot.District then
					dist = (lot.X - dsc.X) ^ 2 + (lot.Z - dsc.Z) ^ 2
				end
			end
			local cur = nearestPlaza[lot.District]
			if not cur or dist < cur.d then
				nearestPlaza[lot.District] = { lot = lot, d = dist }
			end
		end
		if yield and i % 20 == 0 then
			yield()
		end
	end

	-- Puentes elevados entre torres vecinas (los de la hoja de estética): de cristal, con luz por debajo
	local TALLK = { Bloque = true, Torre = true, Aguja = true, Rascacielos = true, Fundicion = true, Tanque = true, Cupula = true }
	local bridgeFolder = Builder.model("PuentesAltos", root)
	local bridges = 0
	for i, a in lots do
		if bridges >= 140 then
			break
		end
		if TALLK[a.Kind] and a.Height >= 26 then
			for j = i + 1, math.min(#lots, i + 12) do
				local b = lots[j]
				if TALLK[b.Kind] and b.Height >= 26 then
					local dx, dz = b.X - a.X, b.Z - a.Z
					local alongX = math.abs(dz) < 2 and math.abs(dx) < 90 and math.abs(dx) > (a.W + b.W) / 2 + 4
					local alongZ = math.abs(dx) < 2 and math.abs(dz) < 90 and math.abs(dz) > (a.D + b.D) / 2 + 4
					if (alongX or alongZ) and (i * 7 + j) % 3 == 0 then
						local y = math.min(a.Base + a.Height, b.Base + b.Height) * 0.62 + math.max(a.Base, b.Base) * 0.38
						y = math.max(y, math.max(a.Base, b.Base) + 14)
						local x0 = if alongX then (if dx > 0 then a.X + a.W / 2 else a.X - a.W / 2) else a.X
						local x1 = if alongX then (if dx > 0 then b.X - b.W / 2 else b.X + b.W / 2) else b.X
						local z0 = if alongZ then (if dz > 0 then a.Z + a.D / 2 else a.Z - a.D / 2) else a.Z
						local z1 = if alongZ then (if dz > 0 then b.Z - b.D / 2 else b.Z + b.D / 2) else b.Z
						local len = math.abs(if alongX then x1 - x0 else z1 - z0) + 1
						local size = if alongX then V3(len, 3, 5) else V3(5, 3, len)
						local c = CFrame.new(W((x0 + x1) / 2, (z0 + z1) / 2, y))
						mk(bridgeFolder, "PuenteAlto", c, size, L.Trim, Enum.Material.Metal)
						mk(bridgeFolder, "Cristal", c * CFrame.new(0, 2.6, 0), if alongX then V3(len, 2.2, 4.6) else V3(4.6, 2.2, len), L.Window, Enum.Material.Glass, { Decor = true, Transparency = 0.45 })
						mk(bridgeFolder, "LuzBajo", c * CFrame.new(0, -1.7, 0), if alongX then V3(len, 0.4, 3) else V3(3, 0.4, len), L.Strip or L.Glow, Enum.Material.Neon, { Decor = true })
						bridges += 1
						break
					end
				end
			end
		end
	end
	stats.SkyBridges = bridges
	-- CABLES entre edificios vecinos (como en la hoja de estética): un Beam que cuelga un poco entre dos azoteas
	local CABLE_PLANETS = { Vertice = true, Miasma = true, Siroco = true, Tefra = true, Nivalis = true }
	local cables = 0
	if CABLE_PLANETS[planet] then
		local cableFolder = Builder.model("Cables", root)
		local anchor = Builder.part({ Name = "Anclajes", Size = V3(1, 1, 1), CFrame = CFrame.new(W(0, 0, -400)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = cableFolder })
		local cableColor = ColorSequence.new(if planet == "Vertice" then (L.Neon and L.Neon[2] or L.Strip or L.Glow) else rgb(28, 28, 32))
		for i, a in lots do
			if cables >= 220 then
				break
			end
			if TALLK[a.Kind] or a.Kind == "Casa" then
				-- (el vecino más cercano que quede a buena distancia: los solares no van en orden por el plano)
				local bestJ, bestD = nil, math.huge
				for j = i + 1, #lots do
					local b = lots[j]
					if (TALLK[b.Kind] or b.Kind == "Casa") and (i + j) % 2 == 0 then
						local dd = (a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2
						if dd < bestD and dd > ((a.W + b.W) / 2 + 2) ^ 2 then
							bestJ, bestD = j, dd
						end
					end
				end
				for _, j in { bestJ } do
					local b = lots[j]
					if b then
						local dist = math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2)
						if dist > (a.W + b.W) / 2 + 2 and dist < 70 then
							local ha = math.min(a.Height, 60) * 0.85
							local hb = math.min(b.Height, 60) * 0.85
							local a0 = Instance.new("Attachment")
							a0.WorldPosition = W(a.X, a.Z, a.Base + ha)
							a0.Parent = anchor
							local a1 = Instance.new("Attachment")
							a1.WorldPosition = W(b.X, b.Z, b.Base + hb)
							a1.Parent = anchor
							local beam = Instance.new("Beam")
							beam.Attachment0 = a0
							beam.Attachment1 = a1
							beam.Width0 = 0.25
							beam.Width1 = 0.25
							beam.Color = cableColor
							beam.LightEmission = if planet == "Vertice" then 1 else 0
							beam.Transparency = NumberSequence.new(0)
							beam.CurveSize0 = -dist * 0.12
							beam.CurveSize1 = dist * 0.12
							beam.Segments = 8
							beam.FaceCamera = true
							beam.Parent = anchor
							cables += 1
							break
						end
					end
				end
			end
		end
	end
	stats.Cables = cables

	-- Pasarelas (Deck), con barandilla donde dan al vacío, y escaleras desde el agua (Tálasa)
	if deck then
		local bf = Builder.model("Pasarelas", root)
		for i, b in M.bridges() do
			mk(bf, "Pasarela", CFrame.new(W((b.X0 + b.X1) / 2, (b.Z0 + b.Z1) / 2, b.Y - 0.8)), V3(b.X1 - b.X0, 1.6, b.Z1 - b.Z0), darker(deckColor, 0.92), deckMat)
			stats.Bridges += 1
			local long = math.max(b.X1 - b.X0, b.Z1 - b.Z0)
			for t = 0.25, 0.76, 0.5 do
				local lx = if b.X1 - b.X0 > b.Z1 - b.Z0 then b.X0 + (b.X1 - b.X0) * t else (b.X0 + b.X1) / 2
				local lz = if b.X1 - b.X0 > b.Z1 - b.Z0 then (b.Z0 + b.Z1) / 2 else b.Z0 + (b.Z1 - b.Z0) * t
				deckUnder(bf, lx, lz, b.Y - 1.6)
			end
			railEdges(bf, b.X0, b.X1, b.Z0, b.Z1, b.Y)
			if i == 1 then
				stats.Skins = haveSkin.CiudadSuelo
			end
			if planet == "Talasa" and long > 60 then
				local lx = if b.X1 - b.X0 > b.Z1 - b.Z0 then (b.X0 + b.X1) / 2 else b.X1 + 1.2
				local lz = if b.X1 - b.X0 > b.Z1 - b.Z0 then b.Z1 + 1.2 else (b.Z0 + b.Z1) / 2
				local bottom = (S.WaterY or 20) - 6
				mk(bf, "Escalerilla", CFrame.new(W(lx, lz, (bottom + b.Y) / 2)), V3(2, b.Y - bottom, 2), L.Metal, Enum.Material.Metal, { Class = "TrussPart" })
			end
			if yield and i % 30 == 0 then
				yield()
			end
		end
	end

	if deck then
		dress(root:FindFirstChild("Pasarelas") :: Instance, nil)
	end

	-- Farolas
	local lampFolder = Builder.model("Farolas", root)
	for i, lp in M.lamps() do
		local m = Builder.model("StreetLamp", lampFolder)
		local cf = Builder.facing(W(lp.X, lp.Z, lp.Y), V3(lp.FX, 0, lp.FZ))
		mk(m, "Pie", cf * CFrame.new(0, 0.4, 0), V3(1.2, 0.8, 1.2), L.Metal, Enum.Material.Metal)
		column(m, "Poste", cf, 11, 0.5, L.Metal, Enum.Material.Metal)
		mk(m, "Brazo", cf * CFrame.new(0, 11, -1.4), V3(0.4, 0.4, 3), L.Metal, Enum.Material.Metal, { Decor = true })
		local bulb = mk(m, "Bombilla", cf * CFrame.new(0, 10.6, -2.6), V3(1.3, 0.9, 1.3), L.Lamp, Enum.Material.SmoothPlastic, { Decor = true, Tags = { "StreetLamp" } })
		local light = Instance.new("PointLight")
		light.Range = 34
		light.Brightness = 1.5
		light.Color = L.Lamp
		light.Shadows = false
		light.Enabled = false
		light.Parent = bulb
		stats.Lamps += 1
		if yield and i % 60 == 0 then
			yield()
		end
	end

	-- Gente (CrowdService: un grupo por solar, así salen cerca de quien pasa)
	local crowdFolder = Builder.model("Gente", root)
	local groupOf: { [string]: number } = {}
	for i, c in M.crowd() do
		local lot = M.plotAt(c.X, c.Z)
		local key = if lot then lot.Id else ("%sMc%d"):format(prefix, i)
		groupOf[key] = (groupOf[key] or 0) + 1
		local at = W(c.X, c.Z, c.Y + 2.5)
		local dir = V3(c.FX - c.X, 0, c.FZ - c.Z)
		local cf = if dir.Magnitude > 0.1 then Builder.facing(at, dir) else CFrame.new(at)
		Builder.part({
			Name = "CrowdSpot",
			Size = V3(2, 5, 2),
			CFrame = cf,
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Tags = { "CrowdSpot" },
			Attributes = { Group = key, Work = c.Work },
			Parent = crowdFolder,
		})
	end

	-- Un hito con el nombre de cada distrito (en su plaza más céntrica; si no tiene, en su solar más cercano)
	for _, dsc in M.Districts do
		local at = nearestPlaza[dsc.Id] and nearestPlaza[dsc.Id].lot
		local ox, oz = 0, 0
		if not at then
			local best = math.huge
			for _, lot in lots do
				if lot.District == dsc.Id then
					local dd = (lot.X - dsc.X) ^ 2 + (lot.Z - dsc.Z) ^ 2
					if dd < best then
						best, at = dd, lot
					end
				end
			end
			if at then
				-- (en la acera, delante de la fachada)
				local inward = if at.FX ~= 0 then at.W else at.D
				ox, oz = at.FX * (inward / 2 + 1.5), at.FZ * (inward / 2 + 1.5)
				local along = if at.FX ~= 0 then at.D else at.W
				if at.FX ~= 0 then
					oz = along * 0.42
				else
					ox = along * 0.42
				end
			end
		else
			ox = at.W * 0.3
		end
		if at then
			local f = folderFor(dsc.Id)
			local y = if deck then at.Base else M.groundY(at.X + ox, at.Z + oz)
			local cf = Builder.facing(W(at.X + ox, at.Z + oz, y), V3(at.FX, 0, at.FZ))
			local m = Builder.model("Hito_" .. dsc.Id, f)
			mk(m, "Pedestal", cf * CFrame.new(0, 1, 0), V3(4, 2, 4), L.Trim, trimMat)
			local post = mk(m, "Hito", cf * CFrame.new(0, 7, 0), V3(1.6, 10, 9), L.Walls[1], wallMat)
			local txt = (dsc.Icon or "") .. " " .. dsc.Name
			Builder.sign(post, txt, Enum.NormalId.Left, rgb(255, 255, 255), darker(L.Trim, 0.5))
			Builder.sign(post, txt, Enum.NormalId.Right, rgb(255, 255, 255), darker(L.Trim, 0.5))
			local top = mk(m, "Luz", cf * CFrame.new(0, 12.4, 0), V3(1.8, 0.8, 9.4), L.Glow, Enum.Material.Neon, { Decor = true })
			glow(top)
			stats.Districts += 1
			-- un Taller al lado del hito (fabricar: Services/CraftingService)
			local okBench, BeastKit = pcall(require, script.Parent.Kit.BeastKit)
			if okBench then
				local side = cf * CFrame.new(10, 0, 2)
				local p = side.Position
				local by = if deck then at.Base else M.groundY(p.X - O.X, p.Z - O.Z)
				BeastKit.bench(m, CFrame.new(p.X, O.Y + by, p.Z) * (cf - cf.Position), { Trim = L.Trim, Metal = L.Metal, Glow = L.Glow })
				stats.Benches = (stats.Benches or 0) + 1
			end
		end
	end

	-- El gran monumento de la ciudad (como la hoja de estética del dueño)
	local LM = M.Landmark
	if LM then
		local okLm, err = pcall(function()
			PlanetMetroBuilder.landmark(root, S, M, LM, mk, column, ball, glow, L)
		end)
		if not okLm then
			warn("[PlanetMetroBuilder] monumento de " .. planet .. ": " .. tostring(err))
		end
		if yield then
			yield()
		end
	end
	-- Naves que vuelan por encima de la ciudad (las mueve el cliente: Controllers/AmbientShips)
	local ships = Builder.model("NavesCielo", root)
	local center = if LM then V3(O.X + LM.X, O.Y + (LM.Base or 0), O.Z + LM.Z) else V3(O.X, O.Y + S.padY(), O.Z)
	for i = 1, 7 do
		local sm = Builder.model("Nave_" .. i, ships)
		local c0 = CFrame.new(center + V3(0, 140 + i * 16, 0))
		local hull = if L.Neon then L.Neon[1 + i % #L.Neon] else (if i % 2 == 0 then L.Walls[1] else rgb(220, 224, 230))
		local body = mk(sm, "Casco", c0, V3(7, 3, 16), hull, Enum.Material.Metal, { Decor = true })
		mk(sm, "Cabina", c0 * CFrame.new(0, 1.6, -4), V3(4.5, 1.6, 5), L.Window, Enum.Material.Glass, { Decor = true })
		mk(sm, "Alas", c0 * CFrame.new(0, -0.3, 2), V3(20, 0.6, 5), darker(hull, 0.8), Enum.Material.Metal, { Decor = true })
		for _, sx in { -1, 1 } do
			local eng = mk(sm, "Motor", c0 * CFrame.new(sx * 3, 0, 8.2), V3(2.4, 2.4, 0.6), L.Strip or L.Glow, Enum.Material.Neon, { Decor = true })
			local pl = Instance.new("PointLight")
			pl.Color = eng.Color
			pl.Range = 16
			pl.Brightness = 1.4
			pl.Parent = eng
		end
		sm.PrimaryPart = body
		sm:AddTag("NaveAmbiente")
		sm:SetAttribute("Centro", center)
		sm:SetAttribute("Radio", 160 + i * 70)
		sm:SetAttribute("Altura", 120 + (i % 4) * 40)
		sm:SetAttribute("Velocidad", (if i % 2 == 0 then 1 else -1) * (0.05 + i * 0.012))
		sm:SetAttribute("Fase", i * 0.9)
	end

	root:SetAttribute("Parts", stats.Parts)
	root:SetAttribute("Buildings", stats.Buildings)
	return root, stats
end

---------------------------------------------------------------------
-- Los monumentos (Landmark.Kind): uno por planeta, a lo grande. cf: centro de la base mirando hacia el barrio.
---------------------------------------------------------------------
function PlanetMetroBuilder.landmark(root: Instance, S: any, M: any, LM: any, mk: any, column: any, ball: any, glow: any, L: any)
	local O = S.Origin
	local m = Builder.model("Monumento_" .. LM.Kind, root)
	Builder.streamable(m)
	local base = V3(O.X + LM.X, O.Y + LM.Base, O.Z + LM.Z)
	local toCity = V3(-LM.X, 0, -LM.Z)
	local cf = Builder.facing(base, if toCity.Magnitude > 1 then toCity else V3(0, 0, -1))
	local R = LM.R
	local glowC = L.Strip or L.Glow
	local wallMat = mat(L.WallMaterial, Enum.Material.Concrete)
	local white = L.Walls[1]
	local function light(part: BasePart, range: number, bright: number)
		local pl = Instance.new("PointLight")
		pl.Color = part.Color
		pl.Range = range
		pl.Brightness = bright
		pl.Shadows = false
		pl.Parent = part
	end
	local function tiered(at: CFrame, base0: number, height: number, tiers: number, color: Color3, material: Enum.Material)
		for i = 0, tiers - 1 do
			local k = 1 - i / tiers
			column(m, "Piso" .. i, at * CFrame.new(0, i * height / tiers, 0), height / tiers + 0.3, math.max(2, base0 * (0.35 + 0.65 * k)), if i % 2 == 0 then color else darker(color, 0.85), material)
			mk(m, "Anillo" .. i, at * CFrame.new(0, (i + 1) * height / tiers - 1, 0), V3(1, 1, 1), glowC, Enum.Material.Neon, { Decor = true }).Size = V3(math.max(2, base0 * (0.35 + 0.65 * k)) + 0.6, 0.8, math.max(2, base0 * (0.35 + 0.65 * k)) + 0.6)
		end
		column(m, "Punta", at * CFrame.new(0, height, 0), height * 0.25, math.max(1, base0 * 0.08), glowC, Enum.Material.Neon, { Decor = true })
	end
	-- un anillo hecho de tramos (hueco por dentro), tumbado
	local function ring(at: CFrame, radius: number, thick: number, color: Color3)
		local n = 24
		for i = 0, n - 1 do
			local a = (i + 0.5) / n * math.pi * 2
			local len = 2 * math.pi * radius / n + 0.4
			mk(m, "Aro", at * CFrame.Angles(0, -a, 0) * CFrame.new(radius, 0, 0), V3(thick, thick, len), color, Enum.Material.Neon, { Decor = true })
		end
	end
	local function waterfall(at: CFrame, width: number, height: number, color: Color3, material: Enum.Material, transp: number)
		local fall = mk(m, "Cascada", at * CFrame.new(0, height / 2, 0), V3(width, height, 1.4), color, material, { Decor = true, Transparency = transp })
		mk(m, "Poza", at * CFrame.new(0, 0.3, -width * 0.4), V3(width * 1.6, 0.6, width), color, material, { Decor = true, Transparency = transp * 0.6 })
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.new(1, 1, 1))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(1.5, 2.5)
		pe.Rate = 8
		pe.Speed = NumberRange.new(2, 5)
		pe.SpreadAngle = Vector2.new(60, 20)
		pe.EmissionDirection = Enum.NormalId.Bottom
		pe.Parent = fall
	end
	local function beam(at: CFrame, height: number, width: number)
		local b = column(m, "Haz", at, height, width, glowC, Enum.Material.Neon, { Decor = true, Transparency = 0.35 })
		b.CastShadow = false
		light(b, 60, 3)
	end
	-- la explanada (en tierra) o la plataforma (en el mar o la niebla)
	if M.Mode == "Deck" then
		mk(m, "Plataforma", CFrame.new(base + V3(0, -0.7, 0)), V3(R * 2.2, 2, R * 2.2), L.Deck or L.Ground, mat(L.DeckMaterial, Enum.Material.Concrete))
	else
		local low = math.huge
		for a = 0, 7 do
			local x, z = LM.X + math.cos(a * math.pi / 4) * R, LM.Z + math.sin(a * math.pi / 4) * R
			low = math.min(low, M.groundY(x, z))
		end
		local fh = LM.Base - low + 3
		column(m, "Explanada", cf * CFrame.new(0, -fh, 0), fh, R * 2, L.Ground, Enum.Material.Pavement)
	end
	column(m, "Circulo", cf * CFrame.new(0, 0.05, 0), 0.3, R * 1.3, glowC, Enum.Material.Neon, { Decor = true, Transparency = 0.2 })
	column(m, "Circulo2", cf * CFrame.new(0, 0.06, 0), 0.32, R * 1.24, L.Ground, Enum.Material.Pavement, { Decor = true })

	local kind = LM.Kind
	if kind == "Palacio" then
		-- Palacio de Hielo: una aguja central de cristal, cuatro torres, un anillo de puentes y una cascada helada
		tiered(cf, 34, 210, 7, white, Enum.Material.SmoothPlastic)
		for i = 0, 3 do
			mk(m, "Nucleo", cf * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 90, -17.2), V3(3, 170, 0.6), glowC, Enum.Material.Neon, { Decor = true })
		end
		for i = 0, 3 do
			local a = i * math.pi / 2 + math.pi / 4
			local at = cf * CFrame.new(math.cos(a) * R * 0.55, 0, math.sin(a) * R * 0.55)
			tiered(at, 16, 120 + i * 10, 5, white, Enum.Material.SmoothPlastic)
			ball(m, "Cupula", at * CFrame.new(0, 30, 0), 20, L.Roof, Enum.Material.Glass, { Transparency = 0.25 })
		end
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			local a2 = (i + 1) / 12 * math.pi * 2
			local p1 = V3(math.cos(a), 0, math.sin(a)) * R * 0.55
			local p2 = V3(math.cos(a2), 0, math.sin(a2)) * R * 0.55
			local mid = (p1 + p2) / 2
			local seg = (p2 - p1)
			local c = cf * CFrame.new(mid.X, 64, mid.Z) * CFrame.Angles(0, math.atan2(-seg.X, -seg.Z), 0)
			mk(m, "Puente", c, V3(5, 1.6, seg.Magnitude + 1), L.Trim, Enum.Material.Metal)
			mk(m, "LuzPuente", c * CFrame.new(0, -1, 0), V3(5.4, 0.4, seg.Magnitude + 1), glowC, Enum.Material.Neon, { Decor = true })
		end
		-- la cascada helada que baja de un risco de hielo
		local cliff = cf * CFrame.new(R * 0.2, 0, R * 0.9)
		mk(m, "Risco", cliff * CFrame.new(0, 24, 6), V3(46, 48, 14), rgb(190, 220, 245), Enum.Material.Ice)
		waterfall(cliff * CFrame.new(0, 0, -1.5), 16, 46, rgb(170, 225, 255), Enum.Material.Ice, 0.25)
	elseif kind == "Puerta" then
		-- Puerta del Sol: dos torres de arenisca con agujas, el arco y el anillo de luz azul en medio; detrás, la catedral
		for _, sx in { -1, 1 } do
			local at = cf * CFrame.new(sx * 26, 0, 0)
			mk(m, "Pilono", at * CFrame.new(0, 55, 0), V3(20, 110, 22), white, wallMat)
			mk(m, "Franja", at * CFrame.new(0, 55, -11.2), V3(2, 100, 0.5), glowC, Enum.Material.Neon, { Decor = true })
			tiered(at * CFrame.new(0, 110, 0), 18, 50, 4, white, wallMat)
		end
		mk(m, "Arco", cf * CFrame.new(0, 100, 0), V3(72, 14, 20), darker(white, 0.9), wallMat)
		for i = 0, 23 do
			local a = i / 24 * math.pi * 2
			mk(m, "Portal", cf * CFrame.new(math.cos(a) * 20, 52 + math.sin(a) * 20, -0.5) * CFrame.Angles(0, 0, a), V3(2.4, 5.6, 2), glowC, Enum.Material.Neon, { Decor = true })
		end
		local disc = column(m, "Velo", cf * CFrame.new(0, 52, 0) * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.new(0, -0.5, 0), 1, 38, glowC, Enum.Material.Glass, { Decor = true, Transparency = 0.6 })
		light(disc, 60, 2.5)
		local back = cf * CFrame.new(0, 0, 40)
		mk(m, "Nave", back * CFrame.new(0, 30, 0), V3(40, 60, 40), white, wallMat)
		tiered(back * CFrame.new(0, 60, 0), 26, 80, 5, white, wallMat)
		for _, sx in { -1, 1 } do
			ball(m, "Cupula", back * CFrame.new(sx * 30, 26, 0), 26, L.Roof, wallMat)
			column(m, "Tambor", back * CFrame.new(sx * 30, 0, 0), 26, 22, white, wallMat)
			mk(m, "Anillo", back * CFrame.new(sx * 30, 22, 0), V3(23, 1.2, 23), glowC, Enum.Material.Neon, { Decor = true })
		end
	elseif kind == "ArbolMadre" then
		-- Árbol Madre: un tronco enorme con casas-cúpula en dos plataformas y una cascada
		column(m, "Tronco", cf * CFrame.new(0, -6, 0), 206, 34, L.Trunk, Enum.Material.Wood)
		for i = 0, 5 do
			mk(m, "Raiz", cf * CFrame.Angles(0, i * math.pi / 3, 0) * CFrame.new(0, 8, -24), V3(8, 22, 22), L.Trunk, Enum.Material.Wood, { Class = "WedgePart" })
		end
		for i = 0, 6 do
			local a = i / 7 * math.pi * 2
			ball(m, "Copa", cf * CFrame.new(math.cos(a) * 34, 196 + (i % 3) * 10, math.sin(a) * 34), 70 + (i % 3) * 12, L.Leaf, Enum.Material.Grass, { Decor = true })
		end
		ball(m, "CopaCentro", cf * CFrame.new(0, 222, 0), 90, darker(L.Leaf, 1.1), Enum.Material.Grass, { Decor = true })
		for _, y in { 70, 130 } do
			column(m, "Plataforma", cf * CFrame.new(0, y, 0), 2, 78, L.Trim, Enum.Material.WoodPlanks)
			ring(cf * CFrame.new(0, y + 1.4, 0), 39, 1, glowC)
			for i = 0, 3 do
				local a = i * math.pi / 2 + (if y == 70 then 0 else math.pi / 4)
				local at = cf * CFrame.new(math.cos(a) * 28, y + 2, math.sin(a) * 28)
				column(m, "Casa", at, 8, 13, white, Enum.Material.SmoothPlastic)
				ball(m, "Cupula", at * CFrame.new(0, 8, 0), 13, L.Roof, Enum.Material.Glass, { Transparency = 0.2 })
				local win = mk(m, "Luz", at * CFrame.new(0, 4, -6.6), V3(4, 2, 0.4), glowC, Enum.Material.Neon, { Decor = true })
				light(win, 18, 1.2)
			end
		end
		mk(m, "Escalera", cf * CFrame.new(0, 66, -19), V3(3, 132, 3), L.Trim, Enum.Material.Wood, { Class = "TrussPart" })
		waterfall(cf * CFrame.new(-30, 0, -40), 14, 70, rgb(150, 220, 240), Enum.Material.Glass, 0.3)
	elseif kind == "TorreAnillos" then
		-- Torre del Crédito: un rascacielos de 330 studs con tres anillos de neón y anuncios gigantes
		local seg = { { 54, 0, 110 }, { 42, 110, 110 }, { 30, 220, 80 } }
		for _, sgm in seg do
			local w, y0, h = sgm[1], sgm[2], sgm[3]
			mk(m, "Cuerpo", cf * CFrame.new(0, y0 + h / 2, 0), V3(w, h, w), white, Enum.Material.Glass)
			for y = y0 + 6, y0 + h - 4, 12 do
				mk(m, "Ventanas", cf * CFrame.new(0, y, 0), V3(w + 0.4, 3, w + 0.4), L.Window, Enum.Material.Neon, { Decor = true, Transparency = 0.3 })
			end
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					mk(m, "Arista", cf * CFrame.new(sx * w / 2, y0 + h / 2, sz * w / 2), V3(1, h, 1), glowC, Enum.Material.Neon, { Decor = true })
				end
			end
		end
		column(m, "Aguja", cf * CFrame.new(0, 300, 0), 70, 3, L.Metal, Enum.Material.Metal)
		ball(m, "Baliza", cf * CFrame.new(0, 372, 0), 4, rgb(255, 40, 60), Enum.Material.Neon, { Decor = true })
		local colors = L.Neon or { glowC }
		for i, y in { 120, 200, 270 } do
			ring(cf * CFrame.new(0, y, 0), 48 - i * 6, 4, colors[(i - 1) % #colors + 1])
		end
		local brands = { "CRÉDITO YA", "VÉRTICE BANK", "HOLOVIA", "LUZ+" }
		for i = 0, 3 do
			local face = cf * CFrame.Angles(0, i * math.pi / 2, 0)
			local board = mk(m, "Anuncio", face * CFrame.new(0, 60, -27.6), V3(38, 30, 0.6), rgb(10, 8, 20), Enum.Material.SmoothPlastic, { Decor = true })
			Builder.sign(board, brands[i + 1], Enum.NormalId.Front, colors[i % #colors + 1], rgb(10, 8, 20))
		end
	elseif kind == "Reactor" then
		-- Reactor de Mareas: un disco blanco enorme con el núcleo de luz azul y un halo; cuatro torres alrededor
		column(m, "Disco", cf * CFrame.new(0, 14, 0), 8, R * 1.7, white, Enum.Material.SmoothPlastic)
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			column(m, "Pilar", cf * CFrame.new(math.cos(a) * R * 0.6, 0, math.sin(a) * R * 0.6), 14, 5, L.Metal, Enum.Material.Metal)
		end
		column(m, "BordeLuz", cf * CFrame.new(0, 21.6, 0), 0.6, R * 1.72, glowC, Enum.Material.Neon, { Decor = true })
		column(m, "Tapa", cf * CFrame.new(0, 22, 0), 0.4, R * 1.66, white, Enum.Material.SmoothPlastic, { Decor = true })
		for _, d in { 40, 70 } do
			column(m, "Circulo", cf * CFrame.new(0, 22.3, 0), 0.3, d, glowC, Enum.Material.Neon, { Decor = true })
			column(m, "Circulo", cf * CFrame.new(0, 22.4, 0), 0.32, d - 3, white, Enum.Material.SmoothPlastic, { Decor = true })
		end
		local core = ball(m, "Nucleo", cf * CFrame.new(0, 44, 0), 26, glowC, Enum.Material.Neon)
		light(core, 80, 3)
		column(m, "Jaula", cf * CFrame.new(0, 22, 0), 46, 32, L.Window, Enum.Material.Glass, { Transparency = 0.7 })
		ring(cf * CFrame.new(0, 50, 0), 44, 2, glowC)
		ring(cf * CFrame.new(0, 34, 0), 30, 1.4, glowC)
		for i = 0, 3 do
			local a = i * math.pi / 2 + math.pi / 4
			local at = cf * CFrame.new(math.cos(a) * R * 0.95, 0, math.sin(a) * R * 0.95)
			mk(m, "Torre", at * CFrame.new(0, 30, 0), V3(14, 60, 14), white, Enum.Material.SmoothPlastic)
			mk(m, "Banda", at * CFrame.new(0, 48, 0), V3(14.6, 2, 14.6), glowC, Enum.Material.Neon, { Decor = true })
			mk(m, "Pantalla", at * CFrame.new(0, 34, -7.3), V3(10, 8, 0.4), glowC, Enum.Material.Neon, { Decor = true, Transparency = 0.25 })
		end
	elseif kind == "Ciudadela" then
		-- La Forja Mayor: una ciudadela negra de púas con ríos de lava y un haz de luz naranja hacia el cielo
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			local at = cf * CFrame.new(math.cos(a) * R * 0.75, 0, math.sin(a) * R * 0.75) * CFrame.Angles(0, -a, 0)
			mk(m, "Muralla", at * CFrame.new(0, 16, 0), V3(10, 32, R * 0.62), white, wallMat)
			tiered(at * CFrame.new(0, 32, 0), 9, 40 + (i % 3) * 12, 3, darker(white, 0.9), wallMat)
			mk(m, "Lava", at * CFrame.new(-5.4, 14, 0), V3(0.6, 28, 4), glowC, Enum.Material.Neon, { Decor = true })
		end
		mk(m, "Torreon", cf * CFrame.new(0, 45, 0), V3(46, 90, 46), white, wallMat)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				tiered(cf * CFrame.new(sx * 20, 90, sz * 20), 12, 70, 4, darker(white, 0.85), wallMat)
			end
		end
		tiered(cf * CFrame.new(0, 90, 0), 26, 80, 5, white, wallMat)
		beam(cf * CFrame.new(0, 170, 0), 600, 7)
		column(m, "Foso", cf * CFrame.new(0, -0.6, 0), 1, R * 1.9, glowC, Enum.Material.Neon, { Decor = true, Transparency = 0.1 })
		column(m, "Isla", cf * CFrame.new(0, -0.4, 0), 1.2, R * 1.6, L.Ground, Enum.Material.Basalt)
		for i = 0, 2 do
			waterfall(cf * CFrame.Angles(0, i * 2.1, 0) * CFrame.new(0, 0, -23.8), 8, 80, glowC, Enum.Material.Neon, 0.05)
		end
	elseif kind == "ReactorVerde" then
		-- Reactor Verde: tanques de cristal con el líquido verde que brilla, tuberías y un haz verde
		local spots = { { 0, 0, 30, 120 }, { 32, 10, 18, 70 }, { -30, 14, 18, 64 }, { 12, -34, 16, 56 }, { -18, -30, 14, 48 } }
		for i, sp in spots do
			local at = cf * CFrame.new(sp[1], 0, sp[2])
			local d, h = sp[3], sp[4]
			column(m, "Zocalo", at, 4, d + 4, L.Trim, Enum.Material.Metal)
			column(m, "Liquido", at * CFrame.new(0, 4, 0), h * 0.85, d * 0.86, glowC, Enum.Material.Neon, { Decor = true })
			column(m, "Cristal", at * CFrame.new(0, 4, 0), h, d, L.Window, Enum.Material.Glass, { Transparency = 0.5 })
			for _, y in { 4, h * 0.5, h + 2 } do
				column(m, "Aro", at * CFrame.new(0, y, 0), 2, d + 1.4, L.Metal, Enum.Material.Metal)
			end
			ball(m, "Tapa", at * CFrame.new(0, h + 4, 0), d, L.Roof, Enum.Material.Metal)
			if i > 1 then
				local dir = V3(-sp[1], 0, -sp[2])
				mk(m, "Tubo", at * CFrame.new(0, h * 0.4, 0) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0) * CFrame.new(0, 0, -dir.Magnitude / 2), V3(3, 3, dir.Magnitude), L.Metal, Enum.Material.Metal, { Decor = true })
			end
		end
		beam(cf * CFrame.new(0, 128, 0), 520, 6)
		column(m, "Charca", cf * CFrame.new(0, 0.1, 0), 0.4, R * 1.8, glowC, Enum.Material.Neon, { Decor = true, Transparency = 0.25 })
	end
	-- el rótulo con su nombre
	local post = mk(m, "Rotulo", cf * CFrame.new(0, 6, -R * 0.9), V3(28, 6, 1.2), rgb(16, 18, 26), Enum.Material.Metal)
	Builder.sign(post, LM.Name, Enum.NormalId.Front, glowC, rgb(16, 18, 26))
	Builder.sign(post, LM.Name, Enum.NormalId.Back, glowC, rgb(16, 18, 26))
	mk(m, "PieRotulo", cf * CFrame.new(0, 1.5, -R * 0.9), V3(2, 3, 1), L.Metal, Enum.Material.Metal)
	for _, ch in m:GetChildren() do
		if ch:IsA("BasePart") and (ch.Name == "Explanada" or ch.Name == "Plataforma") then
			pcall(function()
				if game:GetService("MaterialService"):FindFirstChild("CiudadSuelo") then
					ch.Material = Enum.Material.Pavement
					ch.MaterialVariant = "CiudadSuelo"
				end
			end)

		end
	end
	-- la versión de malla hecha con Blender, si está subida (World/PlanetMetroMeshes; si no, se queda esta)
	pcall(function()
		local Meshes = require(script.Parent.PlanetMetroMeshes) :: any
		Meshes.apply(m, kind, L, cf)
	end)
	return m
end

return PlanetMetroBuilder
