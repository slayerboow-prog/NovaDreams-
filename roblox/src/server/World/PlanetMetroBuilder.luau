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

	local root = Builder.model("Metropoli", parent)
	local stats = { Parts = 0, Buildings = 0, Lamps = 0, Districts = 0, Bridges = 0 }
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
		end
		if r() < 0.3 then
			sign(m, cf, d, 11.5, brands[1 + math.floor(r() * #brands)], L.Accent)
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
		column(m, "Antena", cf * CFrame.new(0, h, 0), 12, 0.5, L.Metal, Enum.Material.Metal, { Decor = true })
		if L.Neon then
			neonStrips(m, cf, w, d, h1, r)
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
				local awn = L.Neon and L.Neon[1 + math.floor(r() * #L.Neon)] or (if r() < 0.5 then L.Accent else L.Walls[1])
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

	draw.Parque = function(m, cf, lot, w, d, r)
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

	root:SetAttribute("Parts", stats.Parts)
	root:SetAttribute("Buildings", stats.Buildings)
	return root, stats
end

return PlanetMetroBuilder
