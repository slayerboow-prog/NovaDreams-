-- CityAssets: los modelos de la Tienda que eligió Sebastián para la CALLE, la CIUDAD y los EDIFICIOS POR
-- FUERA, metidos de verdad en Valmar donde se pasea (qué trae cada asset: docs/assets-usuario*.md; qué
-- se usa y qué no, y por qué: docs/assets-implementados.md, sección «Calles, ciudad y edificios»).
--
-- Al arrancar el servidor (Main, en un hilo aparte) carga cada asset (AssetService:LoadAssetAsync; si
-- falla, InsertService:LoadAsset), lo limpia con World/CityAssetsKit (fuera TODOS los scripts, sonidos,
-- textos, logos y marcas; solo piezas e imágenes permitidas), saca plantillas con nombre en español y
-- las guarda en ServerStorage.ActivosCiudad (no se replica). Luego, por tandas:
--
--   1. Mallas encima de las piezas de bloques que ya había (la pieza queda invisible y sigue chocando;
--      son pequeñas y baratas: se ven en todos los niveles gráficos, también en Bajo):
--        * aires acondicionados de las fachadas de casas y pisos (ACUnit + ACGrille) -> aires de
--          13465440856 (Funiki, sin logo), 6795368713 (los de la casa, sin marcas) y AC_Unit del
--          99479110531330
--        * obras en la calzada (Detalles/Obras): conos y vallas del Construction Pack 5411055653
--        * palés (Pallet) -> palé PBR 10396819700
--        * porterías del campo de fútbol (Manzana_Deporte/Goal) -> portería 75541553
--        * pintadas de los armarios eléctricos (Graffiti) -> grafitis reales de 103449549978145 (solo los
--          24 permitidos: nada de Counter-Strike, Half-Life 2, Wu-Tang ni el cartel con teléfono)
--   2. Calles: bocas de riego, buzones, quioscos de prensa y jardineras PBR (99479110531330) en la
--      acera junto a las farolas, solo donde hay hueco (nunca en medio de nada).
--   3. Polígono industrial (Manzana_Industrial): en los patios, carretillas elevadoras, transpaletas,
--      palés con film (Factory Props 113264079562085), palés, contenedores de basura (9876129164 y el
--      Garbage_Bin del city pack), enchufe industrial en la nave (82042358715900) y grafitis en sus
--      paredes. En un patio, una OBRA: montacargas de obra 11188629897 con el cartel «FUERA DE SERVICIO»
--      (133967929770771, en español y sin el logo), andamios, contenedor, bidones, palés, conos,
--      barreras de hormigón y vallado de chapa (99043731526992). En otro, un APARTADERO de mercancías:
--      vía (8386763665 + tope de 2161748423) con un vagón cerrado y un furgón del train pack 8380605189
--      (sin logos, sin scripts: no se mueven). En otro, un DESGUACE con el camión abandonado
--      124865259344404 (sin la textura con la marca International).
--   4. Talleres (Manzana_Taller): plataforma de exposición 82136423205151 con su foco y contenedor.
--   5. Villas: la puerta corredera de 18777387875 (Barbados Gates, solo la puerta) abierta junto a la
--      entrada de cada villa (no cierra el paso).
--   6. Parques: una pista de tenis 898778590 (con sus bancos) y la locomotora de vapor 10887600145 como
--      monumento sobre un tramo de vía 2161748423.
--   7. Puerto y mar: pesqueros amarrados al muelle, barcas varadas en la playa, un barco hundido y
--      pesqueros fondeados (13728551087; sin el buque de guerra).
--   8. Al fondo, al otro lado del mar (sur): «la costa de enfrente», skyline con los rascacielos de
--      79665094662717 y los edificios del city pack (solo se ven; carga persistente, Bajo los esconde).
--   9. Oficinas (salas Interior_Oficina): un par de armarios de servidores 120631576642977.
--  10. Villaverde: la casa de campo de 111283915226740 (sin scripts ni nombres en polaco) en un hueco.
--  11. Reemplazos limpios (docs/assets-reemplazos.md): estadio de mallas 15569059562 encima de cada
--      Estadio, colegio de ladrillo 76558120171446 por fuera junto a un colegio, skyline 16524471626 y
--      edificios del City Building Pack 6418277837, y parches de asfalto PBR del City Road Pack
--      6432233485 encima de los parches de Kit/CityDetail (no se duplican marcas).
--
-- No se tocan coches, tráfico ni el tren de Cercanías ni el metro (los vagones y la locomotora van en
-- vías propias, aparte). Todo con topes de piezas, etiquetas para el nivel gráfico (shared/Graphics.
-- DetailTags: lo suelto y barato lleva PropDetail / PropMesh / PropShell y se ve también en Bajo; lo
-- pesado, el skyline CityDetail y el estadio y el instituto BuildingMesh / BuildingShell, que Bajo
-- esconde) y en pcall: si algo no carga, el juego sigue como estaba.

local CityAssets = {}

local Kit = require(script.Parent.CityAssetsKit)

type Template = Kit.Template
type Pools = { [string]: { any } }

CityAssets.FolderName = "ActivosCiudad"
CityAssets.MaxParts = 60000 -- piezas nuevas en total (tope)
CityAssets.SeaLevel = -2 -- (shared/Boats.SeaLevel, Swim.Surface)
CityAssets.Center = Vector3.new(0, 0, 0)

-- Grafitis que se pueden usar (docs/assets-usuario-3.md: firmas y letras sin marcas)
CityAssets.GraffitiOk = {
	"1078699847", "1297260114", "1335774378", "1388254418", "1410967229", "1511156214", "1511157511",
	"1556478289", "237334220", "328481563", "363250560", "363251020", "363251273", "393302577", "43315557",
	"6968196415", "8604374847", "8604378617", "8604383322", "8604385209", "8604388602", "8604394415",
	"896464818", "89772442",
}

-- Tamaño de cada cosa en Valmar (studs; un personaje mide ~5): H = alto, W = lo más largo en planta
CityAssets.Sizes = {
	Carretilla = { H = 7 }, Transpaleta = { H = 3.8 }, PaleFilm = { H = 4.2 }, Pale = { W = 3.8 },
	Contenedor = { W = 6.5 }, ContenedorGrande = { W = 7 }, Bidon = { H = 3 }, Andamio = { H = 14 },
	ContenedorObra = { W = 18 }, Montacargas = { H = 16 }, CartelAscensor = { W = 3 }, Hidrante = { H = 2.6 },
	Buzon = { H = 4 }, Quiosco = { H = 3.8 }, Jardinera = { S = 1 }, BarreraHormigon = { W = 6 },
	Enchufe = { W = 1.2 }, CamionAbandonado = { H = 10 }, Expositor = { W = 18 }, Rack = { H = 6.5 },
	Pesquero = { W = 60 }, Barca = { W = 16 }, Lancha = { W = 18 }, LanchaRapida = { W = 20 }, BarcoHundido = { W = 40 },
	Locomotora = { H = 13 }, Vagon = { H = 13 }, PistaTenis = { S = 1 }, CasaCampo = { S = 1 },
}

---------------------------------------------------------------------
-- Buscar cosas dentro de un asset
---------------------------------------------------------------------

-- Objetos (Model o pieza suelta) cuyo nombre encaja con algún patrón (minúsculas, patrones de Lua).
-- No devuelve lo que está dentro de algo ya encontrado.
function CityAssets.named(root: Instance, patterns: { string }, exclude: { string }?): { Instance }
	local found: { Instance } = {}
	local hit: { [Instance]: boolean } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("Model") or d:IsA("BasePart") then
			local inside = false
			local a = d.Parent
			while a and a ~= root do
				if hit[a] then
					inside = true
					break
				end
				a = a.Parent
			end
			if not inside then
				local n = string.lower(d.Name)
				local ok = false
				for _, p in patterns do
					if string.find(n, p) then
						ok = true
						break
					end
				end
				for _, p in exclude or {} do
					if string.find(n, p) then
						ok = false
					end
				end
				if ok then
					hit[d] = true
					table.insert(found, d)
				end
			end
		end
	end
	return found
end

local function add(pools: Pools, key: string, item: any?)
	if item then
		pools[key] = pools[key] or {}
		table.insert(pools[key], item)
	end
end

local function addNamed(pools: Pools, root: Instance, key: string, patterns: { string }, opts: any?, limit: number?, exclude: { string }?)
	local n = 0
	for _, inst in CityAssets.named(root, patterns, exclude) do
		if limit and n >= limit then
			break
		end
		local t = Kit.template(inst, key, opts)
		if t then
			add(pools, key, t)
			n += 1
		end
	end
	return n
end

-- Cambia el nombre (con marca) de todo lo que encaje antes de limpiar, para no perder el objeto
-- entero (los logos no: esos se tienen que ir)
local function rename(root: Instance, patterns: { string }, to: string)
	for _, d in root:GetDescendants() do
		if d:IsA("Model") or d:IsA("BasePart") then
			local n = string.lower(d.Name)
			if not string.find(n, "logo", 1, true) then
				for _, p in patterns do
					if string.find(n, p) then
						d.Name = to
						break
					end
				end
			end
		end
	end
end

local function whole(pools: Pools, root: Instance, key: string, opts: any?)
	add(pools, key, Kit.template(root, key, opts))
end

---------------------------------------------------------------------
-- Catálogo: qué se saca de cada asset
---------------------------------------------------------------------

export type Entry = {
	Id: number,
	Name: string,
	Policy: Kit.Policy?,
	Prepare: ((Instance) -> ())?, -- antes de limpiar (renombrar lo que lleva marca)
	Extract: (Instance, Pools) -> (),
}

local function graffitiFilter(d: Instance): boolean
	local tex = tostring((d :: any).Texture or "")
	for _, id in CityAssets.GraffitiOk do
		if string.find(tex, "%f[%d]" .. id .. "%f[%D]") then
			return true
		end
	end
	return false
end

CityAssets.Catalog = {
	{ Id = 5411055653, Name = "Construction Asset Pack", Extract = function(a, pools)
		addNamed(pools, a, "Cono", { "cone", "cono" }, nil, 3)
		addNamed(pools, a, "Valla", { "fence", "valla", "barricade" }, nil, 3)
		addNamed(pools, a, "Bidon", { "barrel", "drum", "gallon" }, nil, 3)
		addNamed(pools, a, "Andamio", { "scaffold", "andamio" }, nil, 2)
		addNamed(pools, a, "ContenedorObra", { "container", "dumpster", "skip" }, nil, 2)
		addNamed(pools, a, "Pale", { "pallet", "palet" }, nil, 2)
	end },
	{ Id = 113264079562085, Name = "Realistic Factory Props Pack", Extract = function(a, pools)
		addNamed(pools, a, "Carretilla", { "^forklift" }, nil, 1)
		addNamed(pools, a, "Transpaleta", { "^pallet_jack" }, nil, 1)
		addNamed(pools, a, "PaleFilm", { "^wrapped_boxes" }, nil, 2)
		addNamed(pools, a, "Pale", { "^pallet_0" }, nil, 2)
		addNamed(pools, a, "Cajas", { "^stack_box", "^shipping_crate" }, nil, 3)
	end },
	{ Id = 103449549978145, Name = "Realistic Graffiti Decoration Pack", Policy = { Images = true, ImageFilter = graffitiFilter }, Extract = function(a, pools)
		for _, d in a:GetDescendants() do
			if d:IsA("Decal") then
				add(pools, "Grafiti", d.Texture)
			end
		end
	end },
	{ Id = 99479110531330, Name = "Realistic city pack", Extract = function(a, pools)
		addNamed(pools, a, "Hidrante", { "^firehydrant" }, nil, 2)
		addNamed(pools, a, "Buzon", { "^mailbox" }, nil, 1)
		addNamed(pools, a, "Quiosco", { "^newspaper_stand" }, nil, 4)
		addNamed(pools, a, "Jardinera", { "^planter_" }, nil, 4)
		addNamed(pools, a, "BarreraHormigon", { "^cementbarrier", "^barrier$" }, nil, 2)
		addNamed(pools, a, "ContenedorGrande", { "^garbage_bin" }, nil, 1)
		addNamed(pools, a, "Bidon", { "^streebarrel", "^barrel$" }, nil, 2)
		addNamed(pools, a, "AC", { "^ac_unit", "^acunit" }, nil, 2)
		addNamed(pools, a, "Skyline", { "^city house", "^prefab highrise", "^prefab complex", "^lowres city housing", "^warehouse", "^factory" }, nil, 14)
	end },
	{ Id = 99043731526992, Name = "Roof Wall Floor Area51 (chapa)", Policy = { Images = true }, Extract = function(a, pools)
		-- (familia 3 de virus: ya no queda ni un script; solo la pieza con su textura de chapa)
		for _, p in Kit.parts(a) do
			add(pools, "Chapa", Kit.template(p, "Chapa"))
			break
		end
	end },
	{ Id = 9876129164, Name = "Contenedor de basura", Policy = { Images = true }, Extract = function(a, pools)
		whole(pools, a, "Contenedor")
	end },
	{ Id = 10396819700, Name = "Palé", Extract = function(a, pools)
		whole(pools, a, "Pale")
	end },
	{ Id = 2161748423, Name = "Realistic Mesh Track Pack", Policy = { Images = true }, Extract = function(a, pools)
		addNamed(pools, a, "Via", { "^tracklong", "^trackverylong" }, nil, 2)
		addNamed(pools, a, "Tope", { "bumper" }, nil, 1)
	end },
	{ Id = 8386763665, Name = "Realistic long train track", Policy = { Images = true }, Extract = function(a, pools)
		addNamed(pools, a, "ViaBalasto", { "long" }, nil, 1)
	end },
	{ Id = 18777387875, Name = "Barbados Gates", Prepare = function(a)
		rename(a, { "flower", "bush", "plant" }, "Descartar")
	end, Extract = function(a, pools)
		addNamed(pools, a, "Puerta", { "gate", "door", "puerta" }, { MaxParts = 160 }, 2, { "descartar", "post", "pillar", "frame" })
	end },
	{ Id = 6795368713, Name = "Air Conditioner, Ceiling Fan House", Prepare = function(a)
		rename(a, { "saijo", "luxiar", "eminent", "daikin", "panasonic", "mitsubishi", "air ?con", "^ac", "%f[%a]ac%f[%A]" }, "AireAcondicionado")
	end, Extract = function(a, pools)
		addNamed(pools, a, "AC", { "^aireacondicionado$" }, { MaxParts = 120 }, 2)
	end },
	{ Id = 13465440856, Name = "Funiki air conditioner (sin logo)", Prepare = function(a)
		rename(a, { "funiki", "air ?con" }, "AireAcondicionado")
		for _, d in a:GetDescendants() do
			if d:IsA("Model") and string.find(string.lower(d.Name), "remote") then
				d:Destroy() -- el mando
			end
		end
	end, Extract = function(a, pools)
		local found = CityAssets.named(a, { "^aireacondicionado$" })
		add(pools, "AC", Kit.template(found[1] or a, "AC", { MaxParts = 160 }))
	end },
	{ Id = 82042358715900, Name = "Wall socket decoration", Extract = function(a, pools)
		-- (familia de virus «Texture Streaming»: sin scripts ni PlaneConstraint ya no hace nada)
		whole(pools, a, "Enchufe")
	end },
	{ Id = 111283915226740, Name = "Polska Dom Mapa", Prepare = function(a)
		rename(a, { "water", "woda" }, "Descartar")
	end, Extract = function(a, pools)
		for _, d in CityAssets.named(a, { "descartar" }) do
			d:Destroy()
		end
		whole(pools, a, "CasaCampo", { MaxParts = 900 })
	end },
	{ Id = 79665094662717, Name = "Realistic Japan City Pack", Extract = function(a, pools)
		addNamed(pools, a, "Skyline", { "building" }, nil, 5, { "road", "lamp", "palm", "street" })
	end },
	{ Id = 124865259344404, Name = "Abandoned Truck", Policy = { StripTexture = true }, Prepare = function(a)
		rename(a, { "international", "truck", "aw " }, "CamionAbandonado")
	end, Extract = function(a, pools)
		whole(pools, a, "CamionAbandonado", { Color = Color3.fromRGB(120, 74, 48), Material = Enum.Material.CorrodedMetal })
	end },
	{ Id = 11188629897, Name = "Elevator (montacargas de obra)", Policy = { Lights = true }, Extract = function(a, pools)
		whole(pools, a, "Montacargas", { MaxParts = 1100 })
	end },
	{ Id = 133967929770771, Name = "Lift Out of Order Sign (en español)", Prepare = function(a)
		rename(a, { "consult", "logo" }, "Descartar")
	end, Extract = function(a, pools)
		for _, d in CityAssets.named(a, { "descartar" }) do
			d:Destroy()
		end
		whole(pools, a, "CartelAscensor")
	end },
	{ Id = 898778590, Name = "RS Tennis Court", Policy = { Images = true, Seats = true }, Prepare = function(a)
		rename(a, { "billionare", "billionaire" }, "Banco")
	end, Extract = function(a, pools)
		whole(pools, a, "PistaTenis", { MaxParts = 200 })
	end },
	{ Id = 75541553, Name = "Modern goal", Extract = function(a, pools)
		whole(pools, a, "Porteria", { MaxParts = 200 })
	end },
	{ Id = 82136423205151, Name = "Car Show Display", Policy = { Lights = true }, Extract = function(a, pools)
		whole(pools, a, "Expositor")
	end },
	{ Id = 120631576642977, Name = "Realistic Server Rack", Extract = function(a, pools)
		whole(pools, a, "Rack")
	end },
	{ Id = 13728551087, Name = "Realistic Boats Pack", Policy = { Images = true }, Prepare = function(a)
		rename(a, { "smash mouth" }, "LanchaRapida")
	end, Extract = function(a, pools)
		for _, inst in CityAssets.named(a, { "." }) do
			local list = Kit.parts(inst)
			if #list > 0 then
				local lo, hi = Kit.bounds(list)
				local size = hi - lo
				local long = math.max(size.X, size.Y, size.Z)
				local n = string.lower(inst.Name)
				local key: string? = nil
				if long > 250 or #list > 30 then
					key = nil -- buque de guerra: no
				elseif n == "lancharapida" then
					key = "LanchaRapida"
				elseif string.find(n, "small boat") or n == "boat 2" then
					key = "Barca"
				elseif inst:IsA("Model") and #list > 4 then
					key = "BarcoHundido"
				elseif long >= 80 then
					key = "Pesquero"
				elseif long >= 50 then
					key = "Pesquero"
				elseif long >= 30 then
					key = "Lancha"
				else
					key = "Barca"
				end
				if key then
					add(pools, key, Kit.template(inst, key, { Upright = true, MaxParts = 40 }))
				end
			end
		end
	end },
	{ Id = 10887600145, Name = "Mesh steam train", Policy = { Images = true }, Extract = function(a, pools)
		whole(pools, a, "Locomotora", { Upright = true })
	end },
	{ Id = 8380605189, Name = "realistic train pack (2 vagones)", Prepare = function(a)
		rename(a, { "boxcar" }, "VagonMercancias")
		rename(a, { "baggage" }, "Furgon")
	end, Extract = function(a, pools)
		addNamed(pools, a, "Vagon", { "^vagonmercancias$", "^furgon$" }, { MaxParts = 200, Upright = true }, 2)
	end },
	-- Reemplazos limpios (docs/assets-reemplazos.md, filas 11–14)
	{ Id = 16524471626, Name = "City Background Night (skyline)", Extract = function(a, pools)
		whole(pools, a, "SkylineGrande")
	end },
	{ Id = 6418277837, Name = "City Building Pack (Roblox)", Extract = function(a, pools)
		addNamed(pools, a, "Skyline", { "^building_%d+$" }, { MaxParts = 120 }, 6, { "section" })
	end },
	{ Id = 76558120171446, Name = "Modern Brick School Building", Extract = function(a, pools)
		whole(pools, a, "Instituto", { MaxParts = 3300 })
	end },
	{ Id = 15569059562, Name = "Mini Football stadium", Extract = function(a, pools)
		local t = Kit.template(a, "EstadioMalla", { MaxParts = 60 })
		if t then
			-- el césped: la pieza plana más grande (para encajarlo en nuestro campo)
			local best, area = nil, 0
			for _, p in Kit.parts(t.Model) do
				local flat = p.Size.Y < 0.1 * math.max(p.Size.X, p.Size.Z)
				if flat and p.Size.X * p.Size.Z > area then
					best, area = p, p.Size.X * p.Size.Z
				end
			end
			if best then
				best.Name = "Cesped"
				add(pools, "EstadioMalla", t)
			end
		end
	end },
	{ Id = 6432233485, Name = "City Road Pack (Roblox)", Extract = function(a, pools)
		addNamed(pools, a, "Parche", { "^road_patch" }, nil, 3)
	end },
}

-- Los que no se usan, y por qué (también en docs/assets-implementados.md)
CityAssets.Skipped = {
	[12527638598] = "Reemplazado por 6432233485 (planos con líneas pintadas: duplicarían las marcas viales)",
	[15004077857] = "ya en el juego: World/StreetDress usa sus señales y alcantarillas",
	[16088161488] = "Reemplazado por 6432233485 (texturas antiguas sin PBR)",
	[11347783499] = "Reemplazado por 6432233485 / 6418277837 (ciudad de 2010 de bloques con Decals, sin mallas)",
	[6430696462] = "túnel de bloques de 97 studs: en Valmar ninguna carretera atraviesa un monte (quedaría una caja en medio de la calle)",
	[139484418601989] = "Reemplazado por 16524471626 + 6418277837 (solo era un cielo con una foto real de Tokio, y virus)",
	[131247677717086] = "→ Coches (ahora lo usa el agente de coches)",
	[70353066] = "Reemplazado por 15569059562 (estadio de 2012, 3 644 bloques, NPCs que dejan sangre)",
	[1119962617] = "Reemplazado por 76558120171446 (copia del mapa de otro juego: Roblox High School)",
	[26972564] = "12 bloques de 2010, nada aprovechable",
}

---------------------------------------------------------------------
-- Utilidades de colocación
---------------------------------------------------------------------

export type Ctx = {
	Town: Instance,
	Pools: Pools,
	Parent: Instance, -- carpeta de lo nuevo (workspace.Town.ActivosCiudad)
	Query: Kit.Query?,
	Ground: ((Vector3) -> (number?, Instance?))?, -- rayo hacia abajo desde ese punto: altura y pieza
	Parts: number,
	Counts: { [string]: number },
	Wait: (() -> ())?,
}

local function count(ctx: Ctx, key: string, model: Instance?)
	if model then
		ctx.Counts[key] = (ctx.Counts[key] or 0) + 1
		ctx.Parts += #Kit.parts(model)
	end
end

local function full(ctx: Ctx): boolean
	return ctx.Parts >= CityAssets.MaxParts
end

local function pick(ctx: Ctx, key: string, pos: Vector3, salt: number?): Template?
	local list = ctx.Pools[key]
	if not list or #list == 0 then
		return nil
	end
	local i = 1 + math.floor(Kit.hash(pos, salt) * #list) % #list
	return list[i]
end

-- Escala para el tamaño de Valmar (CityAssets.Sizes)
function CityAssets.scaleOf(t: Template, key: string?): number
	local want = CityAssets.Sizes[key or t.Name]
	if not want then
		return 1
	end
	if want.H then
		return want.H / math.max(t.Size.Y, 0.01)
	elseif want.W then
		return want.W / math.max(t.Size.X, t.Size.Z, 0.01)
	end
	return want.S or 1
end

local function footOf(t: Template, s: number): Vector3
	return t.Size * s
end

local function folder(parent: Instance, name: string): Model
	local m = parent:FindFirstChild(name)
	if not m then
		m = Instance.new("Model")
		m.Name = name
		m.Parent = parent
	end
	return m :: Model
end

-- Áreas de suelo: Manzana_<kind> con su BlockGround (o la pieza «Yard» del patio), de cerca a lejos
local function blocks(ctx: Ctx, kind: string, center: Vector3?): { { Model: Instance, Area: Kit.Area, Ground: BasePart } }
	local out = {}
	for _, d in ctx.Town:GetDescendants() do
		if d.Name == "Manzana_" .. kind and d:IsA("Model") then
			local ground = d:FindFirstChild("BlockGround")
			if ground and ground:IsA("BasePart") then
				table.insert(out, { Model = d, Area = Kit.areaOf(ground), Ground = ground })
			end
		end
	end
	local c = center or CityAssets.Center
	table.sort(out, function(a, b)
		return (a.Ground.CFrame.Position - c).Magnitude < (b.Ground.CFrame.Position - c).Magnitude
	end)
	return out
end

local function place(ctx: Ctx, key: string, t: Template?, area: Kit.Area, prefer: Vector3?, parent: Instance, flags: Kit.Flags?, s: number?, spotOpts: Kit.SpotOpts?): (Model?, CFrame?)
	if not t or full(ctx) then
		return nil, nil
	end
	local scale = s or CityAssets.scaleOf(t, key)
	local o = table.clone(spotOpts or {})
	o.Prefer = prefer or o.Prefer
	o.Query = ctx.Query
	local spot = Kit.findSpot(area, footOf(t, scale), o)
	if not spot then
		return nil, nil
	end
	local f = table.clone(flags or { Collide = true, Detail = true })
	local m = Kit.spawn(t, spot, scale, parent, f)
	m.Name = key
	count(ctx, key, m)
	return m, spot
end

---------------------------------------------------------------------
-- 1. Mallas encima de las piezas de bloques
---------------------------------------------------------------------

CityAssets.Caps = { AC = 420, Cono = 200, Valla = 80, Pale = 80, Porteria = 12, Grafiti = 120, Parche = 400 }

local function nearestSibling(part: BasePart, name: string, reach: number): BasePart?
	local best, bestD = nil, reach
	for _, s in (part.Parent :: Instance):GetChildren() do
		if s ~= part and s.Name == name and s:IsA("BasePart") then
			local d = (s.CFrame.Position - part.CFrame.Position).Magnitude
			if d <= bestD then
				best, bestD = s, d
			end
		end
	end
	return best
end

local function hasAncestor(inst: Instance, names: { [string]: boolean }, stop: Instance): boolean
	local a = inst.Parent
	while a and a ~= stop do
		if names[a.Name] then
			return true
		end
		a = a.Parent
	end
	return false
end

local STREET = { Obras = true, Streets = true, MainRoads = true, Detalles = true }
local FACES = { Enum.NormalId.Front, Enum.NormalId.Back }

function CityAssets.paintGraffiti(part: BasePart, image: string, faces: { Enum.NormalId }?)
	for _, face in faces or FACES do
		local d = Instance.new("Decal")
		d.Name = "Grafiti"
		d.Texture = image
		d.Face = face
		d.Parent = part
	end
end

function CityAssets.overlays(ctx: Ctx): { [string]: number }
	local done: { [string]: number } = {}
	local function cap(key: string): boolean
		return (done[key] or 0) < (CityAssets.Caps[key] or math.huge) and not full(ctx)
	end
	local function bump(key: string, m: Instance?)
		if m then
			done[key] = (done[key] or 0) + 1
			count(ctx, key, m)
		end
	end
	local list = ctx.Town:GetDescendants()
	for i, d in list do
		if i % 3000 == 0 and ctx.Wait then
			ctx.Wait()
		end
		if not d:IsA("BasePart") or d.Transparency >= 1 or d:FindFirstChild("Malla") then
			continue
		end
		local name = d.Name
		local pos = d.CFrame.Position
		if name == "ACUnit" and cap("AC") then
			local t = pick(ctx, "AC", pos, 1)
			if t then
				local grille = nearestSibling(d, "ACGrille", 2.5)
				local facing = if grille then Vector3.new(pos.X - grille.CFrame.Position.X, 0, pos.Z - grille.CFrame.Position.Z) else nil
				if facing and facing.Magnitude < 0.01 then
					facing = nil
				end
				local m = Kit.overlay(d, t, { Grow = 1.15, Facing = facing })
				if m and grille then
					Kit.hide(grille, Kit.PropShellTag)
				end
				bump("AC", m)
			end
		elseif name == "Cone" and cap("Cono") and hasAncestor(d, STREET, ctx.Town) then
			local t = pick(ctx, "Cono", pos, 2)
			if t then
				bump("Cono", Kit.overlay(d, t, { Grow = 1.25 }))
			end
		elseif name == "WorksBarrier" and cap("Valla") and hasAncestor(d, STREET, ctx.Town) then
			local t = pick(ctx, "Valla", pos, 3)
			if t then
				local m = Kit.overlay(d, t, { Grow = 1.1 })
				if m then
					for _, n in { "WorksFence", "WorksStripe" } do
						local s = nearestSibling(d, n, 1.5)
						if s then
							Kit.hide(s, Kit.PropShellTag)
						end
					end
				end
				bump("Valla", m)
			end
		elseif name == "AsphaltPatch" and cap("Parche") then
			-- parches de asfalto de Kit/CityDetail -> parche PBR del City Road Pack (mismo sitio: no se duplica)
			local t = pick(ctx, "Parche", pos, 7)
			if t then
				bump("Parche", Kit.overlay(d, t, { Flat = true }))
			end
		elseif name == "Pallet" and cap("Pale") then
			local t = pick(ctx, "Pale", pos, 4)
			if t then
				bump("Pale", Kit.overlay(d, t, { Grow = 1.05 }))
			end
		elseif name == "Goal" and d.Parent and d.Parent.Name == "Manzana_Deporte" and cap("Porteria") then
			local t = pick(ctx, "Porteria", pos, 5)
			local pitch = d.Parent:FindFirstChild("Pitch")
			if t then
				local away = if pitch and pitch:IsA("BasePart") then Vector3.new(pos.X - pitch.CFrame.Position.X, 0, pos.Z - pitch.CFrame.Position.Z) else nil
				bump("Porteria", Kit.overlay(d, t, { Grow = 1.3, Facing = away }))
			end
		elseif name == "Graffiti" and cap("Grafiti") and ctx.Pools.Grafiti and #ctx.Pools.Grafiti > 0 then
			local images = ctx.Pools.Grafiti
			local image = images[1 + math.floor(Kit.hash(pos, 6) * #images) % #images]
			local cabinet = nearestSibling(d, "Cabinet", 3)
			if cabinet then
				d.Color = cabinet.Color
				d.Material = cabinet.Material
			end
			CityAssets.paintGraffiti(d, image)
			done.Grafiti = (done.Grafiti or 0) + 1
			ctx.Counts.Grafiti = (ctx.Counts.Grafiti or 0) + 1
		end
	end
	return done
end

---------------------------------------------------------------------
-- 2. Calles: bocas de riego, buzones, quioscos y jardineras junto a las farolas
---------------------------------------------------------------------

CityAssets.StreetCaps = { Hidrante = 180, Buzon = 70, Quiosco = 50, Jardinera = 90 }
CityAssets.StreetChance = { Hidrante = 0.22, Buzon = 0.08, Quiosco = 0.06, Jardinera = 0.1 }

function CityAssets.streetProps(ctx: Ctx): number
	local streets = ctx.Town:FindFirstChild("Streets")
	if not streets then
		return 0
	end
	local lamps = {}
	for _, m in streets:GetChildren() do
		if m.Name == "StreetLamp" then
			local base = m:FindFirstChild("Base") or m:FindFirstChildWhichIsA("BasePart")
			if base and base:IsA("BasePart") then
				table.insert(lamps, base)
			end
		end
	end
	table.sort(lamps, function(a, b)
		return (a.CFrame.Position - CityAssets.Center).Magnitude < (b.CFrame.Position - CityAssets.Center).Magnitude
	end)
	local out = folder(ctx.Parent, "Calles")
	local placed = 0
	local done: { [string]: number } = {}
	local kinds = { "Hidrante", "Buzon", "Quiosco", "Jardinera" }
	for i, base in lamps do
		if full(ctx) then
			break
		end
		if i % 60 == 0 and ctx.Wait then
			ctx.Wait()
		end
		local r = Kit.hash(base.CFrame.Position, 11)
		local acc, key = 0, nil
		for _, k in kinds do
			acc += CityAssets.StreetChance[k]
			if r < acc then
				key = k
				break
			end
		end
		if not key or (done[key] or 0) >= CityAssets.StreetCaps[key] then
			continue
		end
		local t = pick(ctx, key, base.CFrame.Position, 12)
		if not t then
			continue
		end
		local s = CityAssets.scaleOf(t, key)
		local foot = footOf(t, s)
		local y0 = base.CFrame.Position.Y - base.Size.Y / 2
		-- junto a la farola, a lo largo de la acera (4 lados; el primero que esté libre y sea acera)
		for k, dir in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
			local off = 1.2 + math.max(foot.X, foot.Z) / 2 + 0.6
			local p = Vector3.new(base.CFrame.Position.X, y0, base.CFrame.Position.Z) + dir * off
			local cf = CFrame.lookAt(p, p + Vector3.new(dir.Z, 0, -dir.X))
			local hits = (ctx.Query or Kit.defaultQuery)(cf * CFrame.new(0, 0.6 + foot.Y / 2, 0), foot + Vector3.new(1.6, 0, 1.6))
			if #hits == 0 then
				local ok = true
				if ctx.Ground then
					-- el centro y las cuatro esquinas, sobre la acera (nunca asomando a la calzada)
					local gy, gp = ctx.Ground(p + Vector3.new(0, foot.Y + 1, 0))
					ok = gy ~= nil and gp ~= nil and gp.Name == "Sidewalk" and math.abs(gy - y0) < 1
					for _, c in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
						if ok then
							local corner = (cf * CFrame.new(c[1] * (foot.X / 2 + 0.3), foot.Y + 1, c[2] * (foot.Z / 2 + 0.3))).Position
							local cy, cp = ctx.Ground(corner)
							ok = cy ~= nil and cp ~= nil and cp.Name == "Sidewalk" and math.abs(cy - (gy :: number)) < 0.3
						end
					end
					if ok then
						cf = cf + Vector3.new(0, (gy :: number) - y0, 0)
					end
				end
				if ok then
					local m = Kit.spawn(t, cf, s, out, { Collide = true, Detail = true })
					m.Name = key
					count(ctx, key, m)
					done[key] = (done[key] or 0) + 1
					placed += 1
					break
				end
			end
			if k == 4 then
				break
			end
		end
	end
	return placed
end

---------------------------------------------------------------------
-- 3. Polígono industrial: patios, obra, apartadero y desguace
---------------------------------------------------------------------

CityAssets.MaxYards = 12

local function dockPoint(nave: Instance?): Vector3?
	if not nave then
		return nil
	end
	local dock, hall = nave:FindFirstChild("Dock"), nave:FindFirstChild("Hall")
	if dock and hall and dock:IsA("BasePart") and hall:IsA("BasePart") then
		local out = Vector3.new(dock.CFrame.Position.X - hall.CFrame.Position.X, 0, dock.CFrame.Position.Z - hall.CFrame.Position.Z)
		if out.Magnitude > 0 then
			return dock.CFrame.Position + out.Unit * 14
		end
	end
	return nil
end

local function yardArea(b: any): Kit.Area
	local nave = b.Model:FindFirstChild("Nave")
	local yard = nave and nave:FindFirstChild("Yard")
	if yard and yard:IsA("BasePart") then
		return Kit.areaOf(yard)
	end
	return b.Area
end

-- La obra: vallado de chapa con una entrada, montacargas con el cartel, andamios, contenedor…
function CityAssets.buildSite(ctx: Ctx, area: Kit.Area, prefer: Vector3?): Model?
	local W, D = 64, 44
	local spot = Kit.findSpot(area, Vector3.new(W, 18, D), { Prefer = prefer, Query = ctx.Query, Margin = 2 })
	if not spot then
		return nil
	end
	local site = Instance.new("Model")
	site.Name = "Obra"
	local function at(x: number, z: number, yaw: number?): CFrame
		return spot * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	end
	local function put(key: string, cf: CFrame, s: number?): Model?
		local t = pick(ctx, key, cf.Position, 21)
		if not t then
			return nil
		end
		local m = Kit.spawn(t, cf, s or CityAssets.scaleOf(t, key), site, { Collide = true, Detail = key ~= "Montacargas" })
		m.Name = key
		count(ctx, key, m)
		return m
	end
	-- Vallado de chapa (Area51) o vallas de obra; entrada de 12 en el lado -Z
	local chapa = ctx.Pools.Chapa and ctx.Pools.Chapa[1]
	local function panel(cf: CFrame, len: number)
		if chapa then
			local p = (Kit.parts(chapa.Model)[1]):Clone()
			p.Name = "VallaChapa"
			p.Size = Vector3.new(len, 7, 0.4)
			p.CFrame = cf * CFrame.new(0, 3.5, 0)
			p.Anchored = true
			p.CanCollide = true
			p.Parent = site
			ctx.Parts += 1
		else
			put("Valla", cf)
		end
	end
	local step = 8
	for x = -W / 2 + step / 2, W / 2 - step / 2, step do
		panel(at(x, D / 2), step) -- fondo
		if math.abs(x) > 8 then
			panel(at(x, -D / 2), step) -- delante, con la entrada
		end
	end
	for z = -D / 2 + step / 2, D / 2 - step / 2, step do
		panel(at(-W / 2, z, 90), step)
		panel(at(W / 2, z, 90), step)
	end
	-- Montacargas y su cartel (delante, a la altura de la vista)
	local lift = put("Montacargas", at(16, 8))
	local sign = ctx.Pools.CartelAscensor and ctx.Pools.CartelAscensor[1]
	if lift and sign then
		local lo, hi = Kit.bounds(Kit.parts(lift))
		local s = CityAssets.scaleOf(sign, "CartelAscensor")
		local m = Kit.spawn(sign, CFrame.new((lo.X + hi.X) / 2, spot.Position.Y, lo.Z - 1.5) * (spot - spot.Position) * CFrame.Angles(0, math.pi, 0), s, site, { Collide = true, Detail = true })
		m.Name = "CartelAscensor"
		CityAssets.signText(m)
		count(ctx, "CartelAscensor", m)
	end
	put("Andamio", at(-16, 15))
	put("Andamio", at(-4, 15))
	put("ContenedorObra", at(-20, -8, 90))
	for k = 0, 2 do
		put("Bidon", at(2 + k * 3.2, -12))
	end
	put("Pale", at(4, 0))
	put("Pale", at(9, 0, 15))
	put("PaleFilm", at(4, 5))
	put("Contenedor", at(24, -14, 90))
	for k = -2, 2 do
		put("Cono", at(k * 3, -D / 2 - 3))
	end
	put("BarreraHormigon", at(-11, -D / 2 - 3))
	put("BarreraHormigon", at(11, -D / 2 - 3))
	site.Parent = folder(ctx.Parent, "Industria")
	count(ctx, "Obra", nil)
	ctx.Counts.Obra = (ctx.Counts.Obra or 0) + 1
	return site
end

-- Texto en español en el cartel del ascensor (el original estaba en inglés y con un logo)
function CityAssets.signText(model: Instance)
	local best: BasePart? = nil
	for _, p in Kit.parts(model) do
		if not best or p.Size.X * p.Size.Y > best.Size.X * best.Size.Y then
			best = p
		end
	end
	if not best then
		return
	end
	for _, face in FACES do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Aviso"
		gui.Face = face
		pcall(function()
			(gui :: any).SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			;(gui :: any).PixelsPerStud = 60
		end)
		local label = Instance.new("TextLabel")
		label.Name = "Texto"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(250, 205, 30)
		label.BackgroundTransparency = 0
		label.TextColor3 = Color3.fromRGB(20, 20, 20)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.Text = "⚠ ASCENSOR FUERA DE SERVICIO\nDisculpen las molestias"
		label.Parent = gui
		gui.Parent = best
	end
end

-- Apartadero: vía con tope y dos vagones parados encima
function CityAssets.buildSiding(ctx: Ctx, area: Kit.Area, prefer: Vector3?): Model?
	local via = (ctx.Pools.ViaBalasto and ctx.Pools.ViaBalasto[1]) or (ctx.Pools.Via and ctx.Pools.Via[1])
	local cars = ctx.Pools.Vagon
	if not via or not cars or #cars == 0 then
		return nil
	end
	local carScale = CityAssets.scaleOf(cars[1], "Vagon")
	local carWidth = math.min(cars[1].Size.X, cars[1].Size.Z) * carScale
	local trackScale = carWidth * 0.85 / math.max(math.min(via.Size.X, via.Size.Z), 0.01)
	local L = 0
	for _, c in cars do
		L += math.max(c.Size.X, c.Size.Z) * carScale + 3
	end
	L += 14
	local spot = Kit.findSpot(area, Vector3.new(carWidth + 4, 16, L), { Prefer = prefer, Query = ctx.Query, Margin = 2, Yaws = { 0, math.pi / 2 } })
	if not spot then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = "Apartadero"
	local start = spot * CFrame.new(0, 0, L / 2)
	Kit.layTrack(via, start, L, trackScale, m)
	local tope = ctx.Pools.Tope and ctx.Pools.Tope[1]
	if tope then
		Kit.spawn(tope, start * CFrame.new(0, via.Size.Y * trackScale, -L + 3), CityAssets.scaleOf(tope, "Tope") * trackScale, m, { Collide = true })
	end
	local z = 4
	local top = via.Size.Y * trackScale
	for _, c in cars do
		local len = math.max(c.Size.X, c.Size.Z) * carScale
		local yaw = if c.Size.X > c.Size.Z then CFrame.Angles(0, math.pi / 2, 0) else CFrame.new()
		local car = Kit.spawn(c, start * CFrame.new(0, top, -(z + len / 2)) * yaw, carScale, m, { Collide = true })
		car.Name = "VagonParado"
		z += len + 3
	end
	m.Parent = folder(ctx.Parent, "Industria")
	count(ctx, "Apartadero", m)
	return m
end

function CityAssets.industry(ctx: Ctx): number
	local yards = blocks(ctx, "Industrial", Vector3.new(0, 0, 1400))
	local out = folder(ctx.Parent, "Industria")
	local n = 0
	local specials = { "Obra", "Apartadero", "Desguace" }
	for i, b in yards do
		if i > CityAssets.MaxYards or full(ctx) then
			break
		end
		if ctx.Wait then
			ctx.Wait()
		end
		local area = yardArea(b)
		local nave = b.Model:FindFirstChild("Nave")
		local dock = dockPoint(nave)
		local special = specials[i]
		if special == "Obra" then
			CityAssets.buildSite(ctx, area, dock)
		elseif special == "Apartadero" then
			CityAssets.buildSiding(ctx, area, dock)
		elseif special == "Desguace" then
			for k = 1, 2 do
				place(ctx, "CamionAbandonado", pick(ctx, "CamionAbandonado", area.CFrame.Position, k), area, nil, out, { Collide = true, Detail = false })
			end
			place(ctx, "Contenedor", pick(ctx, "Contenedor", area.CFrame.Position, 31), area, nil, out)
		end
		-- Lo de todos los patios: carretilla, palés y contenedor, cerca del muelle de carga
		place(ctx, "Carretilla", pick(ctx, "Carretilla", area.CFrame.Position, 41), area, dock, out)
		place(ctx, "PaleFilm", pick(ctx, "PaleFilm", area.CFrame.Position, 42), area, dock, out)
		place(ctx, "Pale", pick(ctx, "Pale", area.CFrame.Position, 43), area, dock, out)
		place(ctx, "Transpaleta", pick(ctx, "Transpaleta", area.CFrame.Position, 44), area, dock, out)
		place(ctx, "Cajas", pick(ctx, "Cajas", area.CFrame.Position, 45), area, dock, out, nil, 1)
		place(ctx, if i % 2 == 0 then "ContenedorGrande" else "Contenedor", pick(ctx, if i % 2 == 0 then "ContenedorGrande" else "Contenedor", area.CFrame.Position, 46), area, nil, out)
		-- Enchufe industrial y grafiti en la pared de la nave
		local hall = nave and nave:FindFirstChild("Hall")
		if hall and hall:IsA("BasePart") then
			local face = hall.CFrame * CFrame.new(0, -hall.Size.Y / 2, hall.Size.Z / 2)
			local enchufe = pick(ctx, "Enchufe", hall.CFrame.Position, 47)
			if enchufe and i <= 8 then
				local s = CityAssets.scaleOf(enchufe, "Enchufe")
				local e = Kit.spawn(enchufe, face * CFrame.new(hall.Size.X / 4, 4, 0.05 + enchufe.Size.Z * s / 2), s, out, { Detail = true })
				e.Name = "Enchufe"
				count(ctx, "Enchufe", e)
			end
			local images = ctx.Pools.Grafiti
			if images and #images > 0 then
				local wall = Instance.new("Part")
				wall.Name = "GrafitiNave"
				wall.Size = Vector3.new(16, 7, 0.05)
				wall.CFrame = face * CFrame.new(-hall.Size.X / 5, 4.5, 0.06)
				wall.Transparency = 1
				wall.Anchored = true
				wall.CanCollide = false
				wall.CanQuery = false
				wall.CanTouch = false
				wall:AddTag(Kit.DetailTag)
				CityAssets.paintGraffiti(wall, images[1 + math.floor(Kit.hash(hall.CFrame.Position, 48) * #images) % #images], { Enum.NormalId.Back })
				wall.Parent = out
				ctx.Counts.Grafiti = (ctx.Counts.Grafiti or 0) + 1
			end
		end
		n += 1
	end
	return n
end

---------------------------------------------------------------------
-- 4. Talleres: plataforma de exposición y contenedor
---------------------------------------------------------------------

function CityAssets.workshops(ctx: Ctx): number
	local out = folder(ctx.Parent, "Talleres")
	local n = 0
	for i, b in blocks(ctx, "Taller") do
		if full(ctx) then
			break
		end
		local taller = b.Model:FindFirstChild("Taller")
		local near = taller and taller:FindFirstChildWhichIsA("BasePart")
		local prefer = near and near.CFrame.Position or nil
		if i <= 3 then
			if place(ctx, "Expositor", pick(ctx, "Expositor", b.Area.CFrame.Position, 51), b.Area, prefer, out, { Collide = true, Detail = true }) then
				n += 1
			end
		end
		place(ctx, "Contenedor", pick(ctx, "Contenedor", b.Area.CFrame.Position, 52), b.Area, nil, out)
	end
	return n
end

---------------------------------------------------------------------
-- 5. Villas: la puerta corredera abierta junto a la entrada
---------------------------------------------------------------------

CityAssets.MaxGates = 30

function CityAssets.villaGates(ctx: Ctx): number
	local list = ctx.Pools.Puerta
	if not list or #list == 0 then
		return 0
	end
	local out = folder(ctx.Parent, "Villas")
	local n = 0
	for _, villa in ctx.Town:GetDescendants() do
		if n >= CityAssets.MaxGates or full(ctx) then
			break
		end
		if villa.Name ~= "Villa" or not villa:IsA("Model") then
			continue
		end
		local pillars, body = {}, nil
		for _, c in villa:GetChildren() do
			if c.Name == "GatePillar" and c:IsA("BasePart") then
				table.insert(pillars, c)
			elseif c.Name == "Body" and c:IsA("BasePart") then
				body = c
			end
		end
		if #pillars ~= 2 or not body then
			continue
		end
		local a, b = pillars[1].CFrame.Position, pillars[2].CFrame.Position
		local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local gap = along.Magnitude - pillars[1].Size.X
		if gap < 3 then
			continue
		end
		local dir = along.Unit
		local mid = (a + b) / 2
		local inward = Vector3.new(body.CFrame.Position.X - mid.X, 0, body.CFrame.Position.Z - mid.Z)
		inward = (inward - dir * inward:Dot(dir))
		if inward.Magnitude < 0.01 then
			continue
		end
		inward = inward.Unit
		local t = pick(ctx, "Puerta", mid, 61) :: Template
		local wide = math.max(t.Size.X, t.Size.Z)
		local s = math.min(gap / wide, 4 / math.max(t.Size.Y, 0.01))
		local y0 = pillars[1].CFrame.Position.Y - pillars[1].Size.Y / 2
		-- (abierta: corrida detrás del muro de al lado, por dentro)
		local center = Vector3.new(mid.X, y0, mid.Z) + dir * (gap + 0.4) + inward * 1.1
		local cf = CFrame.lookAt(center, center + inward)
		if t.Size.Z > t.Size.X then
			cf = cf * CFrame.Angles(0, math.pi / 2, 0)
		end
		local m = Kit.spawn(t, cf, s, out, { Collide = false, Detail = true })
		m.Name = "PuertaCorredera"
		count(ctx, "Puerta", m)
		n += 1
	end
	return n
end

---------------------------------------------------------------------
-- 6. Parques: pista de tenis y locomotora monumento
---------------------------------------------------------------------

function CityAssets.parks(ctx: Ctx): number
	local parks = blocks(ctx, "Parque")
	local out = folder(ctx.Parent, "Parques")
	local n = 0
	local court = ctx.Pools.PistaTenis and ctx.Pools.PistaTenis[1]
	if court then
		for _, b in parks do
			if place(ctx, "PistaTenis", court, b.Area, nil, out, { Collide = true, Detail = false }, 1, { Margin = 3 }) then
				n += 1
				break
			end
		end
	end
	local loco = ctx.Pools.Locomotora and ctx.Pools.Locomotora[1]
	if loco then
		local s = CityAssets.scaleOf(loco, "Locomotora")
		local len = math.max(loco.Size.X, loco.Size.Z) * s + 8
		local width = math.min(loco.Size.X, loco.Size.Z) * s
		for k = #parks, 1, -1 do -- (los parques de las afueras primero: hay más sitio)
			local b = parks[k]
			local spot = Kit.findSpot(b.Area, Vector3.new(width + 6, 16, len), { Query = ctx.Query, Margin = 2 })
			if spot then
				local m = Instance.new("Model")
				m.Name = "LocomotoraMonumento"
				local plinth = Instance.new("Part")
				plinth.Name = "Peana"
				plinth.Size = Vector3.new(width + 4, 1, len)
				plinth.CFrame = spot * CFrame.new(0, 0.5, 0)
				plinth.Color = Color3.fromRGB(150, 146, 138)
				plinth.Material = Enum.Material.Cobblestone
				plinth.Anchored = true
				plinth.Parent = m
				local top = 1
				local via = ctx.Pools.Via and ctx.Pools.Via[1]
				if via then
					local ts = width * 0.85 / math.max(math.min(via.Size.X, via.Size.Z), 0.01)
					Kit.layTrack(via, spot * CFrame.new(0, 1, len / 2), len - 2, ts, m)
					top += via.Size.Y * ts
				end
				local yaw = if loco.Size.X > loco.Size.Z then CFrame.Angles(0, math.pi / 2, 0) else CFrame.new()
				Kit.spawn(loco, spot * CFrame.new(0, top, 0) * yaw, s, m, { Collide = true })
				m.Parent = out
				count(ctx, "Locomotora", m)
				n += 1
				break
			end
		end
	end
	return n
end

---------------------------------------------------------------------
-- 7. Puerto y mar
---------------------------------------------------------------------

local function boat(ctx: Ctx, key: string, cf: CFrame, out: Instance, tilt: number?): Model?
	local t = pick(ctx, key, cf.Position, 71)
	if not t then
		return nil
	end
	local s = CityAssets.scaleOf(t, key)
	local yaw = if t.Size.X > t.Size.Z then CFrame.Angles(0, math.pi / 2, 0) else CFrame.new()
	local m = Kit.spawn(t, cf * yaw * CFrame.Angles(0, 0, tilt or 0), s, out, { Collide = false, Detail = false, Shadow = 8 })
	m.Name = key
	count(ctx, key, m)
	return m
end

-- Si el punto es mar (fuera del contorno de la isla)
CityAssets.isSea = function(_x: number, _z: number): boolean
	return true
end

function CityAssets.harbour(ctx: Ctx): number
	local out = folder(ctx.Parent, "Mar")
	local n = 0
	local query = ctx.Query or Kit.defaultQuery
	-- Pesqueros amarrados al muelle del puerto
	local puerto = ctx.Town:FindFirstChild("Puerto")
	local pier = puerto and puerto:FindFirstChild("Pier")
	local fishing = ctx.Pools.Pesquero
	if pier and pier:IsA("BasePart") and fishing and #fishing > 0 then
		local along = if pier.Size.X >= pier.Size.Z then pier.CFrame.RightVector else pier.CFrame.LookVector
		local across = Vector3.new(-along.Z, 0, along.X)
		local half = math.max(pier.Size.X, pier.Size.Z) / 2
		local width = math.min(pier.Size.X, pier.Size.Z) / 2
		local moored = 0
		for d = -half + 30, half - 30, 45 do
			for _, side in { 1, -1 } do
				if moored >= 3 then
					break
				end
				local t = pick(ctx, "Pesquero", pier.CFrame.Position + along * d, 72) :: Template
				local s = CityAssets.scaleOf(t, "Pesquero")
				local beam = math.min(t.Size.X, t.Size.Z) * s
				local len = math.max(t.Size.X, t.Size.Z) * s
				local c = pier.CFrame.Position + along * d + across * side * (width + beam / 2 + 2)
				local draft = math.min(t.Size.Y * s * 0.18, 5)
				local cf = CFrame.lookAt(Vector3.new(c.X, CityAssets.SeaLevel - draft, c.Z), Vector3.new(c.X, CityAssets.SeaLevel - draft, c.Z) + along)
				local hits = query(CFrame.new(c.X, CityAssets.SeaLevel + 4, c.Z) * (cf - cf.Position), Vector3.new(beam + 2, 6, len + 4))
				if #hits == 0 then
					if boat(ctx, "Pesquero", cf, out) then
						moored += 1
						n += 1
					end
				end
			end
		end
	end
	-- Fondeados mar adentro (al sur del puerto) y un barco hundido varado en la playa
	for k, p in { { 300, 3900 }, { 1050, 3950 }, { -500, 3850 } } do
		if CityAssets.isSea(p[1], p[2]) then
			local key = if k == 3 then "Lancha" else "Pesquero"
			local t = pick(ctx, key, Vector3.new(p[1], 0, p[2]), 73)
			if t then
				local s = CityAssets.scaleOf(t, key)
				local draft = math.min(t.Size.Y * s * 0.18, 5)
				if boat(ctx, key, CFrame.new(p[1], CityAssets.SeaLevel - draft, p[2]) * CFrame.Angles(0, k * 1.3, 0), out) then
					n += 1
				end
			end
		end
	end
	-- Barcas varadas y el barco hundido en las playas
	local beached = 0
	for _, d in ctx.Town:GetDescendants() do
		if beached >= 4 then
			break
		end
		if d.Name == "Sand" and d:IsA("BasePart") and d.Size.X * d.Size.Z > 4000 then
			local area = Kit.areaOf(d)
			for _, key in { "Barca", if beached == 0 then "BarcoHundido" else "Barca" } do
				local t = pick(ctx, key, d.CFrame.Position, 74 + beached)
				if t then
					local s = CityAssets.scaleOf(t, key)
					local prefer = d.CFrame.Position + d.CFrame.RightVector * (d.Size.X / 2) -- hacia el agua
					local _, spot = place(ctx, key, t, area, prefer, out, { Collide = false, Detail = true }, s, { Margin = 2 })
					if spot then
						beached += 1
						n += 1
					end
				end
			end
		end
	end
	return n
end

---------------------------------------------------------------------
-- 8. Skyline lejano: la costa de enfrente, al sur, al otro lado del mar
---------------------------------------------------------------------

CityAssets.Skyline = { Z = 6500, From = -3200, To = 3200, Max = 40 }

function CityAssets.skyline(ctx: Ctx): number
	local list = ctx.Pools.Skyline or {}
	local big = ctx.Pools.SkylineGrande and ctx.Pools.SkylineGrande[1]
	if #list == 0 and not big then
		return 0
	end
	local m = Instance.new("Model")
	m.Name = "CostaDeEnfrente"
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
	local cfg = CityAssets.Skyline
	local land = Instance.new("Part")
	land.Name = "Costa"
	land.Size = Vector3.new(cfg.To - cfg.From + 1200, 4, 900)
	land.CFrame = CFrame.new((cfg.From + cfg.To) / 2, CityAssets.SeaLevel - 1, cfg.Z + 250)
	land.Color = Color3.fromRGB(120, 124, 116)
	land.Material = Enum.Material.Concrete
	land.Anchored = true
	land.CanCollide = false
	land.CanQuery = false
	land.CanTouch = false
	land.CastShadow = false
	land:AddTag(Kit.HeavyTag)
	land.Parent = m
	local x, i, n = cfg.From, 0, 0
	-- En medio, la ciudad grande de una malla (16524471626, con ventanas que brillan de noche)
	local gap0, gap1 = math.huge, -math.huge
	if big then
		local w = math.max(big.Size.X, big.Size.Z)
		local yaw = if big.Size.X >= big.Size.Z then CFrame.new() else CFrame.Angles(0, math.pi / 2, 0)
		local b = Kit.spawn(big, CFrame.new(0, CityAssets.SeaLevel + 1, cfg.Z + 120) * yaw, 1, m, { Collide = false, Heavy = true, Shadow = 1e9 })
		b.Name = "CiudadLejana"
		for _, p in Kit.parts(b) do
			p.CanQuery = false
		end
		count(ctx, "SkylineGrande", b)
		gap0, gap1 = -w / 2 - 30, w / 2 + 30
		n += 1
	end
	while #list > 0 and x < cfg.To and n < cfg.Max and not full(ctx) do
		if x + 150 > gap0 and x < gap1 then
			x = gap1
			continue
		end
		i += 1
		local t = list[1 + (i * 7) % #list]
		local s = 1 + Kit.hash(Vector3.new(x, 0, cfg.Z), 81) * 0.6
		local w = math.max(t.Size.X, t.Size.Z) * s
		local z = cfg.Z + (Kit.hash(Vector3.new(x, 0, 0), 82) - 0.5) * 300
		local b = Kit.spawn(t, CFrame.new(x + w / 2, CityAssets.SeaLevel + 1, z) * CFrame.Angles(0, math.pi * math.floor(Kit.hash(Vector3.new(x, 1, 0), 83) * 4) / 2, 0), s, m, { Collide = false, Heavy = true, Shadow = 1e9 })
		for _, p in Kit.parts(b) do
			p.CanQuery = false
		end
		count(ctx, "Skyline", b)
		x += w + 10 + Kit.hash(Vector3.new(x, 2, 0), 84) * 60
		n += 1
	end
	m.Parent = ctx.Parent
	return n
end

---------------------------------------------------------------------
-- 9. Oficinas: armarios de servidores (las salas se montan al entrar)
---------------------------------------------------------------------

CityAssets.RackSlots = { { X = 24.2, Z = -17 }, { X = 24.2, Z = -14.2 } }

function CityAssets.dressOffice(room: Instance, ctx: Ctx): number
	local rack = ctx.Pools.Rack and ctx.Pools.Rack[1]
	local floor = room:FindFirstChild("Floor")
	if not rack or not (floor and floor:IsA("BasePart")) or room:FindFirstChild("Servidores") then
		return 0
	end
	local origin = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
	local s = CityAssets.scaleOf(rack, "Rack")
	local foot = rack.Size * s
	local m = Instance.new("Model")
	m.Name = "Servidores"
	local n = 0
	for _, slot in CityAssets.RackSlots do
		local cf = origin * CFrame.new(slot.X, 0, slot.Z) * CFrame.Angles(0, -math.pi / 2, 0)
		local hits = (ctx.Query or Kit.defaultQuery)(cf * CFrame.new(0, 0.3 + foot.Y / 2, 0), foot)
		if #hits == 0 then
			Kit.spawn(rack, cf, s, m, { Collide = true })
			n += 1
		end
	end
	m.Parent = room
	return n
end

---------------------------------------------------------------------
-- 10. Villaverde: casa de campo
---------------------------------------------------------------------

function CityAssets.farmhouse(ctx: Ctx): boolean
	local house = ctx.Pools.CasaCampo and ctx.Pools.CasaCampo[1]
	local region = ctx.Town:FindFirstChild("Region")
	local village = region and region:FindFirstChild("Villaverde")
	if not house or not village then
		return false
	end
	local areas = {}
	for _, c in village:GetChildren() do
		if c.Name == "BlockGround" and c:IsA("BasePart") then
			table.insert(areas, Kit.areaOf(c))
		end
	end
	for _, a in areas do
		if place(ctx, "CasaCampo", house, a, nil, folder(ctx.Parent, "Campo"), { Collide = true, Detail = false }, 1, { Margin = 3 }) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- 11. Estadios: el «Mini Football stadium» (15569059562) encima de cada Estadio
---------------------------------------------------------------------

-- Lo nuestro que se esconde (sigue chocando lo que hace falta para el balón: postes, larguero, red)
CityAssets.StadiumHide = { Pitch = true, Stripe = true, Line = true, CenterCircle = true, CenterCircleIn = true, Post = true, Crossbar = true, Net = true }
CityAssets.StadiumReplace = { Stand = true, StandBack = true, Roof = true } -- (estos dejan de chocar: chocan las gradas de malla)

function CityAssets.stadiums(ctx: Ctx): number
	local t = ctx.Pools.EstadioMalla and ctx.Pools.EstadioMalla[1]
	if not t then
		return 0
	end
	local field: BasePart? = nil
	for _, p in Kit.parts(t.Model) do
		if p.Name == "Cesped" then
			field = p
		end
	end
	if not field then
		return 0
	end
	local fieldLong = math.max(field.Size.X, field.Size.Z)
	local fieldAlongX = field.Size.X >= field.Size.Z
	local rel = t.Base:PointToObjectSpace(field.CFrame.Position + Vector3.new(0, field.Size.Y / 2, 0))
	local out = folder(ctx.Parent, "Estadios")
	local n = 0
	for _, st in ctx.Town:GetDescendants() do
		if st.Name ~= "Estadio" or not st:IsA("Model") or st:FindFirstChild("EstadioMalla") then
			continue
		end
		local pitch = st:FindFirstChild("Pitch")
		local esplanade = st:FindFirstChild("Esplanade")
		if not (pitch and pitch:IsA("BasePart")) then
			continue
		end
		local pitchAlongX = pitch.Size.X >= pitch.Size.Z
		local s = math.max(pitch.Size.X, pitch.Size.Z) / fieldLong
		-- que el estadio entero quepa en la explanada (si no, un poco más pequeño)
		if esplanade and esplanade:IsA("BasePart") then
			local long = math.max(t.Size.X, t.Size.Z) * s
			local short = math.min(t.Size.X, t.Size.Z) * s
			local eLong, eShort = math.max(esplanade.Size.X, esplanade.Size.Z), math.min(esplanade.Size.X, esplanade.Size.Z)
			s *= math.min(1, eLong / long, eShort / short)
		end
		local yaw = if pitchAlongX == fieldAlongX then CFrame.new() else CFrame.Angles(0, math.pi / 2, 0)
		local top = pitch.CFrame * CFrame.new(0, pitch.Size.Y / 2 + 0.04, 0)
		local at = top * yaw * CFrame.new(-rel.X * s, -rel.Y * s, -rel.Z * s)
		local m = Kit.spawn(t, at, s, nil, { Collide = true, Mesh = true, Shadow = 8 })
		m.Name = "EstadioMalla"
		for _, p in Kit.parts(m) do
			if p.Name == "Cesped" then
				p.CanCollide = false -- (el suelo sigue siendo nuestro campo)
				p.CanQuery = false
			end
		end
		for _, c in st:GetChildren() do
			if c:IsA("BasePart") and (CityAssets.StadiumHide[c.Name] or CityAssets.StadiumReplace[c.Name]) then
				Kit.hide(c)
				if CityAssets.StadiumReplace[c.Name] then
					c.CanCollide = false
				end
			end
		end
		m.Parent = st
		count(ctx, "Estadio", m)
		n += 1
	end
	local _ = out
	return n
end

---------------------------------------------------------------------
-- 12. Instituto: el colegio de ladrillo (76558120171446), solo por fuera
---------------------------------------------------------------------
-- Los colegios del juego se recorren por dentro (aulas, historia): no se tocan. El de ladrillo va al
-- lado, en un hueco de una manzana de colegio (o del campus), como edificio que solo se ve por fuera,
-- con una caja de choque invisible (en gráficos Bajo se ve la caja y se esconde la malla).

CityAssets.SchoolScales = { 0.55, 0.45, 0.38 }

function CityAssets.school(ctx: Ctx): boolean
	local t = ctx.Pools.Instituto and ctx.Pools.Instituto[1]
	if not t then
		return false
	end
	local areas: { Kit.Area } = {}
	for _, d in ctx.Town:GetDescendants() do
		if d:IsA("Model") and string.sub(d.Name, 1, 15) == "Manzana_Colegio" then
			local g = d:FindFirstChild("BlockGround")
			if g and g:IsA("BasePart") then
				table.insert(areas, Kit.areaOf(g))
			end
		end
	end
	local region = ctx.Town:FindFirstChild("Region")
	for _, name in { "Campus Valmar" } do
		local town = region and region:FindFirstChild(name)
		for _, g in (town and town:GetChildren() or {}) do
			if g.Name == "BlockGround" and g:IsA("BasePart") then
				table.insert(areas, Kit.areaOf(g))
			end
		end
	end
	for _, s in CityAssets.SchoolScales do
		for _, a in areas do
			local foot = t.Size * s
			local spot = Kit.findSpot(a, foot, { Query = ctx.Query, Margin = 4, Step = 8 })
			if spot then
				local m = Kit.spawn(t, spot, s, nil, { Collide = false, Mesh = true, Shadow = 6 })
				m.Name = "Instituto"
				local box = Instance.new("Part")
				box.Name = "InstitutoChoque"
				box.Size = foot
				box.CFrame = spot * CFrame.new(0, foot.Y / 2, 0)
				box.Color = Color3.fromRGB(150, 80, 60)
				box.Material = Enum.Material.Brick
				box.Anchored = true
				box.Transparency = 1
				box:AddTag(Kit.ShellTag)
				box.Parent = m
				m.Parent = folder(ctx.Parent, "Colegios")
				count(ctx, "Instituto", m)
				return true
			end
		end
	end
	return false
end

---------------------------------------------------------------------
-- Todo junto
---------------------------------------------------------------------

function CityAssets.run(ctx: Ctx): { [string]: number }
	local steps = {
		{ "overlays", CityAssets.overlays },
		{ "streetProps", CityAssets.streetProps },
		{ "industry", CityAssets.industry },
		{ "workshops", CityAssets.workshops },
		{ "villaGates", CityAssets.villaGates },
		{ "parks", CityAssets.parks },
		{ "harbour", CityAssets.harbour },
		{ "skyline", CityAssets.skyline },
		{ "farmhouse", CityAssets.farmhouse },
		{ "stadiums", CityAssets.stadiums },
		{ "school", CityAssets.school },
	}
	for _, step in steps do
		local ok, err = pcall(step[2], ctx)
		if not ok then
			warn(("[CityAssets] %s: %s"):format(step[1], tostring(err)))
		end
		if ctx.Wait then
			ctx.Wait()
		end
	end
	return ctx.Counts
end

-- Carga y limpia un asset del catálogo; devuelve lo que se sacó (y lo quitado, para la consola)
function CityAssets.extract(entry: Entry, asset: Instance, pools: Pools): Kit.Stats?
	local ok, result = pcall(function()
		if entry.Prepare then
			entry.Prepare(asset)
		end
		local stats = Kit.sanitize(asset, entry.Policy)
		entry.Extract(asset, pools)
		return stats
	end)
	pcall(asset.Destroy, asset)
	if not ok then
		warn(("[CityAssets] %d (%s): %s"):format(entry.Id, entry.Name, tostring(result)))
		return nil
	end
	return result
end

function CityAssets.loadAll(load: (number) -> Instance?, wait: (() -> ())?): (Pools, { [number]: string })
	local pools: Pools = {}
	local report: { [number]: string } = {}
	for _, entry in CityAssets.Catalog do
		local okLoad, loaded = pcall(load, entry.Id)
		local asset = if okLoad and typeof(loaded) == "Instance" then loaded else nil
		if asset then
			local stats = CityAssets.extract(entry, asset, pools)
			report[entry.Id] = if stats then ("ok (scripts %d, quitado %d, marcas %d)"):format(stats.Scripts, stats.Removed, stats.Brands) else "error"
		else
			report[entry.Id] = "no carga"
		end
		if wait then
			wait()
		end
	end
	return pools, report
end

function CityAssets.start(load: ((number) -> Instance?)?)
	local loader = load or function(id: number): Instance?
		return require(script.Parent.Buildings3D).loadAsset(id)
	end
	local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)
	CityAssets.isSea = function(x: number, z: number): boolean
		return not CityPlan.inside(CityPlan.Coast, x, z)
	end
	local pools, report = CityAssets.loadAll(loader, task.wait)
	local store = Instance.new("Folder")
	store.Name = CityAssets.FolderName
	local kinds = {}
	for key, list in pools do
		table.insert(kinds, ("%s=%d"):format(key, #list))
		local sub = Instance.new("Folder")
		sub.Name = key
		for _, t in list do
			if type(t) == "table" and t.Model then
				t.Model.Parent = sub
			end
		end
		sub.Parent = store
	end
	store.Parent = game:GetService("ServerStorage")
	table.sort(kinds)
	print("[CityAssets] plantillas: " .. table.concat(kinds, " "))
	for id, what in report do
		if what ~= "ok (scripts 0, quitado 0, marcas 0)" then
			print(("[CityAssets] %d: %s"):format(id, what))
		end
	end

	local town = workspace:WaitForChild("Town", 120)
	if not town then
		return
	end
	-- (después de los edificios 3D, que miran las mismas manzanas)
	local t0 = os.clock()
	while not workspace:GetAttribute("InteriorsScanned") and os.clock() - t0 < 120 do
		task.wait(1)
	end
	local parent = Instance.new("Folder")
	parent.Name = CityAssets.FolderName
	parent.Parent = town
	local raycast = RaycastParams.new()
	raycast.FilterType = Enum.RaycastFilterType.Exclude
	raycast.FilterDescendantsInstances = { parent }
	local ctx: Ctx = {
		Town = town,
		Pools = pools,
		Parent = parent,
		Parts = 0,
		Counts = {},
		Wait = function()
			task.wait()
		end,
		Ground = function(from: Vector3): (number?, Instance?)
			local hit = workspace:Raycast(from, Vector3.new(0, -40, 0), raycast)
			if hit then
				return hit.Position.Y, hit.Instance
			end
			return nil, nil
		end,
	}
	local counts = CityAssets.run(ctx)
	local list = {}
	for k, v in counts do
		table.insert(list, ("%s=%d"):format(k, v))
	end
	table.sort(list)
	print(("[CityAssets] colocado (%d piezas): %s"):format(ctx.Parts, table.concat(list, " ")))

	-- Oficinas: armarios de servidores en cada sala que se monte
	local rooms = workspace:WaitForChild("Interiores", 300)
	if rooms then
		local function onRoom(child: Instance)
			if child.Name == "Interior_Oficina" and child:IsA("Model") then
				task.defer(function()
					local ok, err = pcall(CityAssets.dressOffice, child, ctx)
					if not ok then
						warn("[CityAssets] oficina: " .. tostring(err))
					end
				end)
			end
		end
		rooms.ChildAdded:Connect(onRoom)
		for _, child in rooms:GetChildren() do
			onRoom(child)
		end
	end
end

return CityAssets
