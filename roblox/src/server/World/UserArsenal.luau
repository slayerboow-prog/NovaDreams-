-- UserArsenal: los assets de Sebastián de ARMAS Y HERRAMIENTAS, EJÉRCITO, y ZONAS Y CRIATURAS DE
-- TERROR (contenido de cada uno: docs/assets-usuario*.md; qué se usa y dónde: docs/assets-implementados.md).
--
-- No es un sistema de armas nuevo: las armas siguen siendo las de shared/Weapons (WeaponService,
-- Armerías, policía). Aquí solo se ponen MALLAS de verdad donde ya había armas o hacía falta verlas:
--   * Armerías (Kit/GunShop): fusiles, escopetas, subfusiles y rifles colgados en el armero de pared;
--     pistolas y miras de punto rojo en un panel de exposición; una mira encima del fusil de arriba.
--   * Comisarías (Kit/PoliceStation): armero policial con cristal (pistolas, subfusil, escudo si lo
--     hay) y un explosivo DESACTIVADO como prueba en el mostrador (atracos y la brigada de explosivos).
--   * Cuartel del Ejército (sala Interior_Cuartel): fusiles en el armero y cascos militares en las literas.
--   * Museo (sala Interior_Museo): un carro de combate antiguo SIN ninguna insignia ni imagen (se borran
--     todas: las del pack no se podían revisar), con su placa.
--   * Teatro (sala Interior_Teatro): un cámara grabando el escenario.
--   * Tiendas de deportes (sala Interior_Local con Shop = "Deportes"): bates de béisbol en un bidón.
--   * Parque de atracciones (Model «Feria»): caseta de premios con la pistola láser-gato de juguete
--     (no dispara: es un premio) y el «martillo de fuerza» con el mazo de goma.
--   * Las zonas de terror (backrooms, poolrooms, pasillo y escalera sin fin, noria abandonada,
--     cementerio, criaturas) son «los Pliegues» de la Grieta: World/Kit/Pliegues.
--
-- Seguridad (todo lo cargado pasa por sanitize):
--   * fuera TODOS los scripts (muchos packs traen virus o puertas traseras: «Ban Gun» echaba del juego),
--     sonidos (varios son de otros juegos o privados), animaciones, valores, avisos, remotos, partículas,
--     GUIs y textos; fuera decals con nombres de marcas, sangre o símbolos (y en algunos packs, todos).
--   * Nombres genéricos en español: nada de nombres de armas reales, marcas ni SCP.
--   * Las armas copiadas de otros juegos que vienen mezcladas en los packs (Apex, Half-Life 2, CoD) se
--     descartan por nombre; también cuchillos, granadas, lanzacohetes…
--   * Piezas ancladas, sin choque las pequeñas y con la etiqueta PropDetail (objeto suelto: se ve en
--     todos los niveles gráficos, shared/Graphics.DetailTags). Topes de piezas por plantilla.
--   * Si algo no carga, el juego sigue igual (todo con pcall).

local MeshLibrary = require(script.Parent.MeshLibrary)

local UserArsenal = {}

-- Packs de armas (solo mallas). El dead guy (7105428424) NO se carga: sangre (ver el doc).
UserArsenal.WeaponPacks = {
	{ Id = 101748452, Name = "PistolaDorada" }, -- pistola de bloques; su script echaba del juego
	{ Id = 117850698505269, Name = "PackArmas1" }, -- 4 Tool; efectos de sangre (se borran)
	{ Id = 100792423689137, Name = "PackArmas2" }, -- 4 Tool de bloques (2010)
	{ Id = 115493232746766, Name = "PackArmas3" }, -- ~80 modelos (algunos de otros juegos: fuera)
	{ Id = 78033796632460, Name = "PackArmas4" }, -- 1 malla de fusil
	{ Id = 546753609, Name = "KitP90" }, -- solo GUI y scripts: suele no dar ninguna malla
	{ Id = 9700798278, Name = "PackArmas7" }, -- 5 fusiles (sus 70 sonidos fuera)
}

UserArsenal.Props = {
	MiraPuntoRojo = 480927087,
	PistolaGato = 124581242124664,
	MazoGoma = 114120925733217,
	Bate = 9763579280,
	Explosivo = 11156149162,
	CascoMilitar = 5849304432,
	CarroCombate = 266515007,
	Camarografo = 891244647,
}

-- Longitud de cada clase de arma en studs (como las de shared/Weapons, un poco más grandes para que
-- se lean en el expositor)
UserArsenal.Length = { Pistola = 1.25, Subfusil = 2.3, Escopeta = 3.6, Fusil = 3.4, Francotirador = 4.4, Escudo = 4.2, Taser = 1 }
UserArsenal.MaxPerKind = 10
UserArsenal.MaxPerPackKind = 3
UserArsenal.MaxWeaponParts = 160

-- Palabras que no pueden quedar en ningún nombre ni texto visible (minúsculas)
UserArsenal.Banned = {
	-- marcas y armas reales
	"glock", "colt", "beretta", "remington", "benelli", "heckler", "kalashnikov", "taurus", "sako", "uzi",
	"barrett", "desert", "deagle", "nikon", "canon", "sony", "walther", "ruger", "mossberg", "winchester",
	"sig", "kriss", "famas", "steyr", "mauser", "luger", "thompson", "browning", "smith", "wesson",
	-- otros juegos y creadores
	"bad business", "valve", "tarkov", "apex", "acs", "roblox", "bloxburg", "doors",
	-- terror con nombre
	"scp", "096", "087", "backrooms", "howler", "bacteria",
	-- sangre y odio
	"blood", "gore", "sangre", "kill", "dead", "corpse", "wehrmacht", "reich", "nazi", "swastika",
	"hitler", "ss ", "panzer", "iron cross", "balkenkreuz",
}

-- Armas sacadas de videojuegos (vienen dentro de los packs) y cosas que no son un arma de expositor
UserArsenal.Skip = {
	"wingman", "kraber", "r-301", "r301", "hemlok", "flatline", "spitfire", "g7", "osipr", "pulse",
	"holger", "m13b", "stg", "oden", "mmc", "confederal", "knife", "karambit", "katana", "sword",
	"grenade", "granada", "molotov", "rpg", "minigun", "launcher", "claymore", "bayonet", "axe",
	"machete", "flash", "smoke", "c4", "nade", "bullet", "shell", "mag", "ammo", "arms", "hands",
}

-- Clase por palabras del nombre (en orden: la primera que encaja)
UserArsenal.Classes = {
	{ "Escudo", { "shield", "escudo" } },
	{ "Taser", { "taser" } },
	{ "Francotirador", { "sniper", "awp", "svd", "mosin", "m82", "m107", "kar98", "dsr", "sako", "scout", "barrett", "m24", "l96", "intervention", "bolt" } },
	{ "Escopeta", { "shotgun", "spas", "870", "benelli", "aa12", "aa-12", "saiga", "escopeta", "m1014", "nova" } },
	{ "Subfusil", { "mp5", "ump", "uzi", "vector", "p90", "sten", "scorpion", "fmg", "mp7", "mac1", "mac-1", "thompson", "smg", "mp40", "kriss", "subfusil", "pdw" } },
	{ "Pistola", { "pistol", "glock", "deagle", "desert", "eagle", "1911", "revolver", "judge", "luger", "beretta", "usp", "p226", "p250", "five", "magnum", "handgun", "pistola", "tec", "m9", "357" } },
	{ "Fusil", { "rifle", "m4", "m16", "ak", "416", "aug", "g36", "famas", "scar", "m249", "m240", "lmg", "mg42", "fal", "garand", "carbine", "m27", "iar", "fusil" } },
}

-- Lo que nunca pasa (además de los scripts)
local DROP = {
	Sound = true, SoundGroup = true, Animation = true, AnimationController = true, Animator = true,
	KeyframeSequence = true, ClickDetector = true, ProximityPrompt = true, RemoteEvent = true,
	RemoteFunction = true, BindableEvent = true, BindableFunction = true, ParticleEmitter = true,
	Fire = true, Smoke = true, Sparkles = true, Explosion = true, Beam = true, Trail = true,
	BillboardGui = true, SurfaceGui = true, ScreenGui = true, TextLabel = true, TextButton = true,
	TextBox = true, Atmosphere = true, Sky = true, BloomEffect = true, BlurEffect = true,
	ColorCorrectionEffect = true, DepthOfFieldEffect = true, SunRaysEffect = true, NumberPose = true,
	PlaneConstraint = true, Configuration = true, Dialog = true, Camera = true, Tool = false,
}

export type Template = {
	Name: string,
	Kind: string,
	Model: Model,
	Pivot: CFrame, -- en el espacio de las piezas de Model; X = lo largo, Y = alto, Z = grosor (armas)
	Size: Vector3, -- tamaño en los ejes del pivote
	Parts: number,
	Source: number?,
}

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function lower(s: string?): string
	return string.lower(s or "")
end

local function hasWord(text: string, words: { string }): boolean
	local t = lower(text)
	for _, w in words do
		if string.find(t, w, 1, true) then
			return true
		end
	end
	return false
end

function UserArsenal.isBanned(text: string?): boolean
	return hasWord(text or "", UserArsenal.Banned)
end

local function partsOf(root: Instance): { BasePart }
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root :: BasePart)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d :: BasePart)
		end
	end
	return list
end
UserArsenal.partsOf = partsOf

local function read(inst: Instance, prop: string): any
	local ok, value = pcall(function()
		return (inst :: any)[prop]
	end)
	return if ok then value else nil
end

-- Limpia lo cargado. opts.NoDecals: fuera TODAS las imágenes (Decal y Texture si NoTextures).
-- opts.KeepHumanoid: deja el Humanoid (para que se vea la ropa de un personaje).
-- Devuelve { Scripts, Removed, Renamed }.
function UserArsenal.sanitize(root: Instance, opts: { NoDecals: boolean?, NoTextures: boolean?, KeepHumanoid: boolean?, Generic: string? }?): { [string]: number }
	local o = opts or {}
	local stats = { Scripts = MeshLibrary.stripScripts(root), Removed = 0, Renamed = 0 }
	local doomed = {}
	for _, d in root:GetDescendants() do
		local class = d.ClassName
		local drop = DROP[class] == true
			or d:IsA("ValueBase")
			or d:IsA("BodyMover")
			or (class == "Humanoid" and not o.KeepHumanoid)
			or (class == "Decal" and (o.NoDecals or UserArsenal.isBanned(d.Name) or UserArsenal.isBanned(tostring(read(d, "Texture")))))
			or (class == "Texture" and (o.NoTextures or UserArsenal.isBanned(d.Name)))
			or ((class == "Seat" or class == "VehicleSeat")) -- nadie se sienta en un adorno anclado
			or (d:IsA("BasePart") and hasWord(d.Name, { "blood", "gore", "sangre", "puddle" }))
		if drop then
			table.insert(doomed, d)
		end
	end
	for _, d in doomed do
		if d.Parent then
			pcall(function()
				d:Destroy()
			end)
			stats.Removed += 1
		end
	end
	for _, d in root:GetDescendants() do
		if o.Generic and (d:IsA("BasePart") or d:IsA("Model") or d:IsA("Folder")) then
			if d.Name ~= o.Generic then
				d.Name = o.Generic
				stats.Renamed += 1
			end
		elseif UserArsenal.isBanned(d.Name) then
			d.Name = if d:IsA("BasePart") then "Pieza" else d.ClassName
			stats.Renamed += 1
		end
	end
	if o.Generic and root:IsA("BasePart") then
		root.Name = o.Generic
		stats.Renamed += 1
	elseif UserArsenal.isBanned(root.Name) then
		root.Name = "Modelo"
		stats.Renamed += 1
	end
	return stats
end

-- Clase de un arma por su nombre (y si no, por su forma). nil = no se usa.
function UserArsenal.classify(name: string, size: Vector3): string?
	local n = lower(name)
	if hasWord(n, UserArsenal.Skip) then
		return nil
	end
	for _, entry in UserArsenal.Classes do
		if hasWord(n, entry[2]) then
			return entry[1]
		end
	end
	local dims = { size.X, size.Y, size.Z }
	table.sort(dims)
	if dims[3] <= 0 or dims[2] <= 0 then
		return nil
	end
	local ratio = dims[3] / dims[2]
	if ratio < 1.4 then
		return nil -- no tiene forma de arma (una caja, una mano…)
	end
	return if ratio < 2.4 then "Pistola" else "Fusil"
end

-- Las «cosas» de un pack: cada Tool, cada Model sin otros modelos con piezas dentro, y cada pieza suelta
function UserArsenal.items(root: Instance): { Instance }
	local out = {}
	local function hasParts(node: Instance): boolean
		for _, d in node:GetDescendants() do
			if d:IsA("BasePart") then
				return true
			end
		end
		return false
	end
	local function walk(node: Instance)
		for _, child in node:GetChildren() do
			if child:IsA("BasePart") then
				if node == root or node:IsA("Folder") then
					table.insert(out, child)
				end
			elseif child:IsA("Tool") or child:IsA("Model") then
				if hasParts(child) then
					-- Un Tool siempre es un arma; un modelo con piezas propias es un objeto (aunque lleve
					-- submodelos: cargador, mira…); uno que solo tiene modelos dentro es un pack
					local own = child:IsA("Tool")
					for _, sub in child:GetChildren() do
						if sub:IsA("BasePart") then
							own = true
							break
						end
					end
					if own then
						table.insert(out, child)
					else
						walk(child)
					end
				end
			elseif child:IsA("Folder") or child:IsA("Backpack") or child:IsA("StarterPack") or child.ClassName == "Workspace" then
				walk(child)
			end
		end
	end
	walk(root)
	return out
end

-- Pasa los hijos a un Model nuevo (los Tool, Accessory… no se anclan bien como adorno)
local function asModel(source: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	if source:IsA("BasePart") then
		source.Parent = model
	else
		for _, child in source:GetChildren() do
			child.Parent = model
		end
	end
	return model
end

-- Ejes de una caja: el más largo X, el medio Y, el corto Z. Y hacia arriba es donde hay más volumen
-- (en un arma, el cañón y el cajón; la empuñadura y el cargador cuelgan).
local function axesOf(list: { BasePart }, lo: Vector3, hi: Vector3): (Vector3, Vector3, Vector3)
	local size = hi - lo
	local axes = { { Vector3.new(1, 0, 0), size.X }, { Vector3.new(0, 1, 0), size.Y }, { Vector3.new(0, 0, 1), size.Z } }
	table.sort(axes, function(a, b)
		return a[2] > b[2]
	end)
	local x, y = axes[1][1], axes[2][1]
	local center = (lo + hi) / 2
	local sum, weight = 0, 0
	for _, p in list do
		local v = p.Size.X * p.Size.Y * p.Size.Z
		sum += (p.CFrame.Position - center):Dot(y) * v
		weight += v
	end
	if weight > 0 and sum < 0 then
		y = -y
	end
	return x, y, size
end

-- Plantilla de arma: copia limpia, sin nombres, con el pivote en el centro (X = cañón)
function UserArsenal.weaponTemplate(item: Instance, kind: string, index: number, source: number?): Template?
	local copy = item:Clone()
	UserArsenal.sanitize(copy, { Generic = "Pieza" })
	local model = asModel(copy, ("Arma_%s_%d"):format(kind, index))
	if not copy:IsA("BasePart") then -- (una pieza suelta ya está dentro del modelo)
		pcall(function()
			copy:Destroy()
		end)
	end
	local list = partsOf(model)
	if #list == 0 or #list > UserArsenal.MaxWeaponParts then
		return nil
	end
	local lo, hi = MeshLibrary.bounds(list)
	local xAxis, yAxis, size = axesOf(list, lo, hi)
	local dims = { size.X, size.Y, size.Z }
	table.sort(dims)
	local pivot = CFrame.fromMatrix((lo + hi) / 2, xAxis, yAxis)
	for _, p in list do
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Massless = true
	end
	return { Name = model.Name, Kind = kind, Model = model, Pivot = pivot, Size = Vector3.new(dims[3], dims[2], dims[1]), Parts = #list, Source = source }
end

-- Plantilla de un objeto entero (sin girar): pivote en el centro de la base. Si lleva torso o
-- HumanoidRootPart, el pivote mira hacia donde mira él. opts.MaxParts: se quedan las más grandes.
function UserArsenal.wholeTemplate(asset: Instance, name: string, opts: { [string]: any }?): Template?
	local o = opts or {}
	UserArsenal.sanitize(asset, o)
	local model = asModel(asset, name)
	local list = partsOf(model)
	if o.MaxParts and #list > o.MaxParts then
		table.sort(list, function(a, b)
			return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z
		end)
		for i = #list, o.MaxParts + 1, -1 do
			list[i]:Destroy()
			list[i] = nil
		end
	end
	if #list == 0 then
		return nil
	end
	for _, p in list do
		p.Anchored = true
	end
	local lo, hi = MeshLibrary.bounds(list)
	local look = Vector3.new(0, 0, -1)
	for _, key in { "HumanoidRootPart", "Torso", "UpperTorso" } do
		local body = model:FindFirstChild(key, true)
		if body and body:IsA("BasePart") then
			local l = (body :: BasePart).CFrame.LookVector
			local flat = Vector3.new(l.X, 0, l.Z)
			if flat.Magnitude > 0.1 then
				look = flat.Unit
			end
			break
		end
	end
	local right = look:Cross(Vector3.new(0, 1, 0))
	local base = Vector3.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	local pivot = CFrame.fromMatrix(base, right, Vector3.new(0, 1, 0))
	local size = hi - lo
	if math.abs(look.X) > math.abs(look.Z) then
		size = Vector3.new(size.Z, size.Y, size.X) -- (en los ejes del pivote)
	end
	return { Name = name, Kind = name, Model = model, Pivot = pivot, Size = size, Parts = #list }
end

-- Escala de una plantilla para una medida: { Length = n } (lo largo, eje X del pivote),
-- { Height = n }, { Longest = n } o { Scale = n }
function UserArsenal.scaleFor(t: Template, fit: { [string]: number }): number
	if fit.Scale then
		return fit.Scale
	elseif fit.Length then
		return fit.Length / math.max(t.Size.X, 0.05)
	elseif fit.Height then
		return fit.Height / math.max(t.Size.Y, 0.05)
	elseif fit.Longest then
		return fit.Longest / math.max(t.Size.X, t.Size.Y, t.Size.Z, 0.05)
	end
	return 1
end

-- Pone una copia: el pivote de la plantilla en «at», escalada. opts.Detail: etiqueta PropDetail.
-- opts.Collide: las piezas grandes chocan.
function UserArsenal.place(t: Template, parent: Instance, at: CFrame, fit: { [string]: number }?, opts: { [string]: any }?): Model
	local o = opts or {}
	local f = UserArsenal.scaleFor(t, fit or { Scale = 1 })
	local copy = t.Model:Clone()
	copy.Name = o.Name or t.Name
	local inverse = t.Pivot:Inverse()
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			local rel = inverse * d.CFrame
			d.Size = d.Size * f
			d.CFrame = at * CFrame.new(rel.Position * f) * (rel - rel.Position)
			d.Anchored = true
			local big = math.max(d.Size.X, d.Size.Y, d.Size.Z) >= 2
			d.CanCollide = o.Collide == true and big
			d.CanQuery = o.Collide == true and big
			d.CanTouch = false
			if o.Detail then
				d:AddTag("PropDetail") -- (objeto suelto: se ve en todos los niveles gráficos)
			end
		elseif d:IsA("SpecialMesh") then
			-- (las mallas de archivo tienen escala absoluta; las de bloque y cilindro, relativa)
			local mesh = d :: SpecialMesh
			if read(mesh, "MeshType") == Enum.MeshType.FileMesh then
				mesh.Scale = mesh.Scale * f
			end
			mesh.Offset = mesh.Offset * f
		end
	end
	pcall(function()
		copy.WorldPivot = at
	end)
	copy:SetAttribute("UserAsset", true)
	copy.Parent = parent
	return copy
end

---------------------------------------------------------------------
-- Biblioteca: todo lo cargado y limpio
---------------------------------------------------------------------
export type Library = { Weapons: { [string]: { Template } }, Props: { [string]: Template }, Report: { [number]: string } }

-- Prepara las armas de los packs ya descargados ({ [id] = Instance })
function UserArsenal.buildWeapons(loaded: { [number]: Instance }, report: { [number]: string }?): { [string]: { Template } }
	local out: { [string]: { Template } } = {}
	local count = 0
	for _, pack in UserArsenal.WeaponPacks do
		local asset = loaded[pack.Id]
		if asset then
			-- (los scripts fuera ANTES de mirar nada más)
			MeshLibrary.stripScripts(asset)
			local perKind: { [string]: number } = {}
			local used = 0
			for _, item in UserArsenal.items(asset) do
				local list = partsOf(item)
				if #list > 0 and #list <= UserArsenal.MaxWeaponParts then
					local lo, hi = MeshLibrary.bounds(list)
					local kind = UserArsenal.classify(item.Name, hi - lo)
					if kind and (perKind[kind] or 0) < UserArsenal.MaxPerPackKind and #(out[kind] or {}) < UserArsenal.MaxPerKind then
						count += 1
						local t = UserArsenal.weaponTemplate(item, kind, count, pack.Id)
						if t then
							out[kind] = out[kind] or {}
							table.insert(out[kind], t)
							perKind[kind] = (perKind[kind] or 0) + 1
							used += 1
						end
					end
				end
			end
			if report then
				report[pack.Id] = ("%d mallas"):format(used)
			end
			pcall(function()
				asset:Destroy()
			end)
		elseif report then
			report[pack.Id] = "no carga"
		end
	end
	return out
end

-- Opciones de limpieza de cada objeto suelto
UserArsenal.PropOptions = {
	MiraPuntoRojo = { Generic = "Pieza" },
	PistolaGato = { Generic = "Pieza" },
	MazoGoma = { Generic = "Pieza" },
	Bate = { Generic = "Pieza" },
	Explosivo = { Generic = "Pieza" }, -- (se llamaba «Cee Four»)
	CascoMilitar = { Generic = "Pieza", NoDecals = true },
	-- Todas las imágenes fuera: 6 decals de la torreta que no se pudieron revisar (posible símbolo)
	CarroCombate = { Generic = "Pieza", NoDecals = true, NoTextures = true },
	Camarografo = { KeepHumanoid = true },
}

function UserArsenal.buildProps(loaded: { [number]: Instance }, report: { [number]: string }?): { [string]: Template }
	local out = {}
	for name, id in UserArsenal.Props do
		local asset = loaded[id]
		if asset then
			local ok, t = pcall(UserArsenal.wholeTemplate, asset, name, UserArsenal.PropOptions[name])
			if ok and t then
				out[name] = t
				if report then
					report[id] = ("%d piezas"):format(t.Parts)
				end
			elseif report then
				report[id] = "sin piezas" .. (if ok then "" else ": " .. tostring(t))
			end
		elseif report then
			report[id] = "no carga"
		end
	end
	-- El personaje: sin nombre que se vea encima
	local cam = out.Camarografo
	if cam then
		for _, d in cam.Model:GetDescendants() do
			if d:IsA("Humanoid") then
				pcall(function()
					(d :: Humanoid).DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					;(d :: Humanoid).HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				end)
			end
		end
	end
	return out
end

---------------------------------------------------------------------
-- Dónde va cada cosa
---------------------------------------------------------------------

local function pick(list: { Template }?, i: number): Template?
	if not list or #list == 0 then
		return nil
	end
	return list[(i - 1) % #list + 1]
end

local function folder(parent: Instance, name: string): Model?
	if parent:FindFirstChild(name) then
		return nil -- (ya está puesto)
	end
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function box(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:AddTag("PropDetail")
	p.Parent = parent
	return p
end

local function label(part: BasePart, text: string, face: Enum.NormalId?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.Text = text
	t.Parent = gui
	gui.Parent = part
end
UserArsenal.label = label

-- Arma de lado contra una pared: cañón a lo largo de «along», el lado mirando a «out»
-- (el cañón va hacia un lado u otro: el que deja el arma derecha, con el «arriba» hacia arriba)
local function sideways(pos: Vector3, along: Vector3, out: Vector3): CFrame
	local z = out.Unit
	local x = along.Unit
	local y = z:Cross(x)
	if y.Y < 0 then
		x = -x
		y = -y
	end
	return CFrame.fromMatrix(pos, x, y)
end
UserArsenal.sideways = sideways

-- ARMERÍA (Kit/GunShop; W = 36, D = 34; GunShopCounter en at(4, 1.6, -4); armero en x = -17.1)
function UserArsenal.dressGunShop(shop: Instance, lib: Library): number
	local counter = shop:FindFirstChild("GunShopCounter", true)
	if not (counter and counter:IsA("BasePart")) then
		return 0
	end
	local m = folder(shop, "ExpositorMallas")
	if not m then
		return 0
	end
	local origin = (counter :: BasePart).CFrame * CFrame.new(-4, -1.6, 4)
	local function at(x: number, y: number, z: number): Vector3
		return (origin * CFrame.new(x, y, z)).Position
	end
	local into = origin:VectorToWorldSpace(Vector3.new(1, 0, 0)) -- del armero hacia la tienda
	local alongZ = origin:VectorToWorldSpace(Vector3.new(0, 0, 1))
	local n = 0
	-- Armero de pared: tres filas de armas largas, encima de las de pie
	local long = { "Fusil", "Escopeta", "Francotirador", "Subfusil", "Fusil", "Escopeta" }
	local topRifle: Model? = nil
	for row = 0, 2 do
		for col = 0, 1 do
			local kind = long[row * 2 + col + 1]
			local t = pick(lib.Weapons[kind], row + col + 1) or pick(lib.Weapons.Fusil, row * 2 + col + 1)
			if t then
				local length = UserArsenal.Length[t.Kind] or 3.4
				local thick = t.Size.Z * length / math.max(t.Size.X, 0.05)
				local g = UserArsenal.place(t, m, sideways(at(-16.85 + thick / 2, 6.2 + row * 1.25, -13 + col * 6), alongZ, into), { Length = length }, { Detail = true, Name = "ArmaExpuesta" })
				n += 1
				if row == 2 and col == 0 then
					topRifle = g
				end
			end
		end
	end
	-- Panel de exposición en la pared derecha, bajo los carteles: pistolas y miras
	local wallOut = origin:VectorToWorldSpace(Vector3.new(-1, 0, 0))
	local alongBack = origin:VectorToWorldSpace(Vector3.new(0, 0, -1))
	local panel = box(m, "PanelExpositor", Vector3.new(0.2, 3.4, 8), origin * CFrame.new(16.9, 4.6, -10), Color3.fromRGB(46, 48, 54), Enum.Material.Fabric)
	local panelSign = box(m, "CartelPanel", Vector3.new(0.1, 0.7, 4), origin * CFrame.new(16.75, 6.65, -10), Color3.fromRGB(120, 24, 24))
	label(panelSign, "ARMAS CORTAS · MIRAS", Enum.NormalId.Left)
	local _ = panel
	for i = 0, 2 do
		local t = pick(lib.Weapons.Pistola, i + 1)
		if t then
			local thick = t.Size.Z * 1.25 / math.max(t.Size.X, 0.05)
			UserArsenal.place(t, m, sideways(at(16.8 - thick / 2, 5.2, -12.5 + i * 2.5), alongBack, wallOut), { Length = 1.25 }, { Detail = true, Name = "PistolaExpuesta" })
			n += 1
		end
	end
	local sight = lib.Props.MiraPuntoRojo
	if sight then
		for i = 0, 1 do
			UserArsenal.place(sight, m, CFrame.new(at(16.2, 3.75, -11 + i * 2)) * (origin - origin.Position), { Longest = 0.9 }, { Detail = true, Name = "MiraPuntoRojo" })
			n += 1
		end
		-- y una montada en el fusil de arriba del armero
		if topRifle then
			local parts = partsOf(topRifle)
			if #parts > 0 then
				local lo, hi = MeshLibrary.bounds(parts)
				local top = Vector3.new((lo.X + hi.X) / 2, hi.Y, (lo.Z + hi.Z) / 2)
				UserArsenal.place(sight, m, CFrame.new(top) * (origin - origin.Position), { Longest = 0.6 }, { Detail = true, Name = "MiraPuntoRojo" })
				n += 1
			end
		end
	end
	-- (la repisa del panel)
	box(m, "RepisaPanel", Vector3.new(1.2, 0.15, 7.6), origin * CFrame.new(16.2, 3.55, -10), Color3.fromRGB(92, 62, 40), Enum.Material.Wood)
	return n
end

-- COMISARÍA (Kit/PoliceStation dentro de Civic.policeStation: W = 44, D = 30; FrontDesk en
-- at(11, 1.8, -8)). Armero policial en la pared del fondo, entre las banderas y las taquillas.
function UserArsenal.dressPoliceStation(station: Instance, lib: Library): number
	local desk = station:FindFirstChild("FrontDesk", true)
	if not (desk and desk:IsA("BasePart")) then
		return 0
	end
	local parent = desk.Parent :: Instance
	local m = folder(parent, "ArmeroPolicial")
	if not m then
		return 0
	end
	local origin = (desk :: BasePart).CFrame * CFrame.new(-11, -1.8, 8)
	local rot = origin - origin.Position
	local n = 0
	-- Armario: fondo, marco y cristal (mirando a la sala, -Z)
	local cx, cz = 10.5, 14.2
	box(m, "FondoArmero", Vector3.new(4.4, 6, 0.3), origin * CFrame.new(cx, 3.6, cz + 0.45), Color3.fromRGB(44, 52, 70), Enum.Material.Metal)
	box(m, "BaseArmero", Vector3.new(4.4, 0.6, 1.2), origin * CFrame.new(cx, 0.3, cz), Color3.fromRGB(30, 34, 44), Enum.Material.Metal)
	box(m, "TechoArmero", Vector3.new(4.4, 0.3, 1.2), origin * CFrame.new(cx, 6.75, cz), Color3.fromRGB(30, 34, 44), Enum.Material.Metal)
	box(m, "CristalArmero", Vector3.new(4.4, 6, 0.1), origin * CFrame.new(cx, 3.6, cz - 0.6), Color3.fromRGB(200, 225, 240), Enum.Material.Glass, 0.7)
	local sign = box(m, "CartelArmero", Vector3.new(4.2, 0.6, 0.1), origin * CFrame.new(cx, 7.25, cz - 0.4), Color3.fromRGB(24, 60, 150))
	label(sign, "ARMERO · SOLO PERSONAL", Enum.NormalId.Front)
	local into = origin:VectorToWorldSpace(Vector3.new(0, 0, -1))
	local right = origin:VectorToWorldSpace(Vector3.new(1, 0, 0))
	-- Dos pistolas abajo, un subfusil y un fusil arriba
	local rows = { { "Pistola", 1.8, -1 }, { "Pistola", 1.8, 1 }, { "Subfusil", 3.6, 0 }, { "Fusil", 5.4, 0 } }
	for i, r in rows do
		local t = pick(lib.Weapons[r[1] :: string], i)
		if t then
			local length = UserArsenal.Length[t.Kind]
			UserArsenal.place(t, m, sideways((origin * CFrame.new(cx + (r[3] :: number), r[2] :: number, cz + 0.1)).Position, right, into), { Length = length }, { Detail = true, Name = "ArmaReglamentaria" })
			n += 1
		end
	end
	local shield = pick(lib.Weapons.Escudo, 1)
	if shield then
		-- Escudo antidisturbios apoyado al lado del armario (de pie)
		local up = Vector3.new(0, 1, 0)
		UserArsenal.place(shield, m, CFrame.fromMatrix((origin * CFrame.new(cx + 3, 2.2, cz)).Position, up, -right), { Length = 4.2 }, { Detail = true, Name = "EscudoPolicial" })
		n += 1
	end
	-- Prueba: explosivo DESACTIVADO encima del mostrador, con su etiqueta
	local c4 = lib.Props.Explosivo
	if c4 then
		UserArsenal.place(c4, m, (origin * CFrame.new(15.3, 3.8, -8)) * CFrame.Angles(0, math.rad(20), 0), { Longest = 1.7 }, { Detail = true, Name = "PruebaExplosivo" })
		local tag = box(m, "EtiquetaPrueba", Vector3.new(1.4, 0.05, 0.6), origin * CFrame.new(15.3, 3.82, -7.1), Color3.fromRGB(240, 200, 40))
		label(tag, "PRUEBA 0451 · DESACTIVADO", Enum.NormalId.Top)
		n += 1
	end
	local _ = rot
	return n
end

local function roomOrigin(room: Instance): CFrame?
	local floor = room:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		return (floor :: BasePart).CFrame * CFrame.new(0, (floor :: BasePart).Size.Y / 2, 0)
	end
	return nil
end
UserArsenal.roomOrigin = roomOrigin

-- CUARTEL (Interiors.Cuartel: 90 × 70, front = -35, back = 35)
function UserArsenal.dressCuartel(room: Instance, lib: Library): number
	local origin = roomOrigin(room)
	local m = origin and folder(room, "MallasCuartel")
	if not (origin and m) then
		return 0
	end
	local n = 0
	-- Fusiles de pie en el armero (donde estaban las barras RifleRack, detrás del mostrador)
	local up = Vector3.new(0, 1, 0)
	local towardRoom = origin:VectorToWorldSpace(Vector3.new(0, 0, 1))
	local side = towardRoom:Cross(up)
	for k = 0, 5 do
		local t = pick(lib.Weapons.Fusil, k + 1) or pick(lib.Weapons.Subfusil, k + 1)
		if t then
			local pos = (origin * CFrame.new(-40.5 + k * 2.2, 3.7 + 1.7, -25.9)).Position
			UserArsenal.place(t, m, CFrame.fromMatrix(pos, up, side), { Length = UserArsenal.Length[t.Kind] }, { Detail = true, Name = "FusilArmero" })
			n += 1
		end
	end
	if n > 0 then
		for _, d in room:GetDescendants() do
			if d.Name == "RifleRack" and d:IsA("BasePart") then
				d.Transparency = 1 -- (las barras de antes: ahora están las armas de verdad)
			end
		end
	end
	-- Cascos en las literas de arriba
	local helmet = lib.Props.CascoMilitar
	if helmet then
		for k = 0, 5 do
			UserArsenal.place(helmet, m, origin * CFrame.new(-30 + k * 7, 5.7, 32) * CFrame.Angles(0, math.rad(180 + (k % 3 - 1) * 25), 0), { Longest = 1.3 }, { Detail = true, Name = "CascoMilitar" })
			n += 1
		end
		UserArsenal.place(helmet, m, origin * CFrame.new(3, 3.1, 17) * CFrame.Angles(0, math.rad(40), 0), { Longest = 1.3 }, { Detail = true, Name = "CascoMilitar" })
		n += 1
	end
	return n
end

-- MUSEO (Interiors.Museo: 90 × 60): carro de combate en la zona libre de delante, con placa
function UserArsenal.dressMuseo(room: Instance, lib: Library): number
	local origin = roomOrigin(room)
	local tank = lib.Props.CarroCombate
	local m = origin and tank and folder(room, "CarroCombateMuseo")
	if not (origin and tank and m) then
		return 0
	end
	-- Largo (X del pivote o Z) a 22 studs, mirando a lo largo de la sala
	local length = math.max(tank.Size.X, tank.Size.Z)
	local f = 22 / math.max(length, 1)
	local yaw = if tank.Size.Z >= tank.Size.X then math.rad(90) else 0
	UserArsenal.place(tank, m, origin * CFrame.new(-8, 0.6, -16) * CFrame.Angles(0, yaw, 0), { Scale = f }, { Collide = true, Name = "CarroDeCombate" })
	box(m, "TarimaCarro", Vector3.new(26, 0.6, 12), origin * CFrame.new(-8, 0.3, -16), Color3.fromRGB(90, 80, 70), Enum.Material.Slate).CanCollide = true
	local plate = box(m, "PlacaCarro", Vector3.new(5, 1.4, 0.2), origin * CFrame.new(-8, 1.8, -9.6) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(40, 40, 44))
	label(plate, "CARRO DE COMBATE ANTIGUO\nCedido por el Cuartel de Valmar", Enum.NormalId.Back)
	return 1
end

-- TEATRO (Interiors.Teatro: 80 × 70): el cámara en el pasillo, grabando el escenario (+Z)
function UserArsenal.dressTeatro(room: Instance, lib: Library): number
	local origin = roomOrigin(room)
	local cam = lib.Props.Camarografo
	local m = origin and cam and folder(room, "CamaraTeatro")
	if not (origin and cam and m) then
		return 0
	end
	-- (el pivote mira a su -Z: se gira para que mire al escenario)
	UserArsenal.place(cam, m, origin * CFrame.new(28, 0, 0) * CFrame.Angles(0, math.rad(180), 0), { Height = 5.2 }, { Name = "Camarografo" })
	return 1
end

-- TIENDA DE DEPORTES (Interiors.Local, Shop = "Deportes": 40 × 30): bidón con bates junto al escaparate
function UserArsenal.dressDeportes(room: Instance, lib: Library): number
	local origin = roomOrigin(room)
	local bat = lib.Props.Bate
	local m = origin and bat and folder(room, "BatesDeportes")
	if not (origin and bat and m) then
		return 0
	end
	local barrel = box(m, "BidonBates", Vector3.new(2.2, 2.4, 2.2), origin * CFrame.new(16.5, 1.2, -11), Color3.fromRGB(40, 150, 90), Enum.Material.Plastic)
	barrel.Shape = Enum.PartType.Cylinder
	barrel.CFrame = origin * CFrame.new(16.5, 1.2, -11) * CFrame.Angles(0, 0, math.rad(90))
	local up = Vector3.new(0, 1, 0)
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		local pos = (origin * CFrame.new(16.5 + math.cos(a) * 0.5, 2.6, -11 + math.sin(a) * 0.5)).Position
		local tilt = CFrame.Angles(math.cos(a) * 0.12, 0, math.sin(a) * 0.12)
		UserArsenal.place(bat, m, CFrame.new(pos) * tilt * CFrame.fromMatrix(Vector3.zero, up, Vector3.new(1, 0, 0)), { Longest = 2.8 }, { Detail = true, Name = "Bate" })
	end
	local sign = box(m, "CartelBates", Vector3.new(2.2, 0.6, 0.1), origin * CFrame.new(16.5, 4.6, -12.2), Color3.fromRGB(40, 150, 90))
	label(sign, "BATES · 25 $", Enum.NormalId.Back)
	return 4
end

-- FERIA (Icons.Feria): caseta de premios y martillo de fuerza junto a la taquilla (Booth)
function UserArsenal.dressFeria(feria: Instance, lib: Library): number
	local booth = feria:FindFirstChild("Booth", true)
	local m = booth and booth:IsA("BasePart") and folder(feria, "CasetaPremios")
	if not (booth and m) then
		return 0
	end
	local b = booth :: BasePart
	local ground = b.CFrame * CFrame.new(0, -b.Size.Y / 2, 0)
	local n = 0
	-- Caseta: mostrador, techo de rayas y cartel
	local stall = ground * CFrame.new(-14, 0, 0)
	local counter = box(m, "Mostrador", Vector3.new(8, 3.4, 2.4), stall * CFrame.new(0, 1.7, 0), Color3.fromRGB(240, 240, 236), Enum.Material.Wood)
	counter.CanCollide = true
	for i = 0, 3 do
		box(m, "Toldo", Vector3.new(2, 0.3, 4), stall * CFrame.new(-3 + i * 2, 7.2, 0.6), if i % 2 == 0 then Color3.fromRGB(220, 50, 60) else Color3.fromRGB(250, 250, 250), Enum.Material.Fabric)
	end
	for _, x in { -3.8, 3.8 } do
		box(m, "Poste", Vector3.new(0.3, 7, 0.3), stall * CFrame.new(x, 3.5, -1), Color3.fromRGB(250, 200, 60), Enum.Material.Metal)
	end
	local sign = box(m, "CartelCaseta", Vector3.new(7, 1.2, 0.2), stall * CFrame.new(0, 8, -1.3), Color3.fromRGB(220, 50, 60))
	label(sign, "CASETA DE PREMIOS", Enum.NormalId.Front)
	local toy = lib.Props.PistolaGato
	if toy then
		for i = 0, 2 do
			UserArsenal.place(toy, m, stall * CFrame.new(-2.4 + i * 2.4, 3.4, 0.2) * CFrame.Angles(0, math.rad(160 + i * 10), 0), { Longest = 1.6 }, { Detail = true, Name = "PremioPistolaGato" })
			n += 1
		end
		local tag = box(m, "EtiquetaPremio", Vector3.new(3, 0.5, 0.1), stall * CFrame.new(0, 2.4, -1.25), Color3.fromRGB(250, 220, 80))
		label(tag, "PISTOLA LÁSER GATUNA · PREMIO", Enum.NormalId.Front)
	end
	-- Martillo de fuerza: torre con campana y el mazo apoyado
	local hammer = ground * CFrame.new(-22, 0, 0)
	box(m, "BaseMartillo", Vector3.new(3, 0.8, 3), hammer * CFrame.new(0, 0.4, 0), Color3.fromRGB(200, 40, 50), Enum.Material.Metal).CanCollide = true
	box(m, "TorreMartillo", Vector3.new(1, 14, 0.6), hammer * CFrame.new(0, 7.8, 1), Color3.fromRGB(250, 250, 250), Enum.Material.Wood)
	local bell = box(m, "Campana", Vector3.new(1.4, 1.4, 1.4), hammer * CFrame.new(0, 15.3, 1), Color3.fromRGB(250, 200, 60), Enum.Material.Metal)
	bell.Shape = Enum.PartType.Ball
	local tower = box(m, "CartelMartillo", Vector3.new(0.9, 10, 0.1), hammer * CFrame.new(0, 7.8, 0.65), Color3.fromRGB(220, 50, 60))
	label(tower, "FUERZA", Enum.NormalId.Front)
	local mallet = lib.Props.MazoGoma
	if mallet then
		UserArsenal.place(mallet, m, hammer * CFrame.new(1.8, 0, -0.6) * CFrame.Angles(0, 0, math.rad(-12)), { Height = 3.9 }, { Detail = true, Name = "MazoDeGoma" })
		n += 1
	end
	return n
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------

local function download(id: number): Instance?
	local AssetLoader = require(script.Parent.AssetLoader) :: any
	if AssetLoader.download then
		return AssetLoader.download(id)
	end
	local ok, result = pcall(function()
		return (game:GetService("AssetService") :: any):LoadAssetAsync(id)
	end)
	return if ok then result else nil
end

-- Descarga (con pcall; nil si falla) y limpia los scripts nada más llegar
local function fetch(id: number, getter: ((number) -> Instance?)?): Instance?
	local ok, asset = pcall(getter or download, id)
	if ok and asset then
		MeshLibrary.stripScripts(asset)
		return asset
	end
	return nil
end
UserArsenal.fetch = fetch

-- Carga todo. getter: para las pruebas (por defecto, AssetLoader.download)
function UserArsenal.load(getter: ((number) -> Instance?)?): Library
	local report: { [number]: string } = {}
	local loaded: { [number]: Instance } = {}
	for _, pack in UserArsenal.WeaponPacks do
		loaded[pack.Id] = fetch(pack.Id, getter) :: any
	end
	for _, id in UserArsenal.Props do
		loaded[id] = fetch(id, getter) :: any
	end
	local lib: Library = { Weapons = UserArsenal.buildWeapons(loaded, report), Props = UserArsenal.buildProps(loaded, report), Report = report }
	return lib
end

local function safe(what: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn(("[UserArsenal] %s: %s"):format(what, tostring(err)))
	end
end

function UserArsenal.start()
	local lib = UserArsenal.load()
	local kinds = 0
	for _, list in lib.Weapons do
		kinds += #list
	end
	local store = Instance.new("Folder")
	store.Name = "UserArsenal"
	for kind, list in lib.Weapons do
		for _, t in list do
			t.Model.Parent = store
			local _ = kind
		end
	end
	for _, t in lib.Props do
		t.Model.Parent = store
	end
	store.Parent = game:GetService("ServerStorage")

	-- Los Pliegues (zonas de terror de la historia), con su propia carga
	task.spawn(function()
		safe("Pliegues", function()
			require(script.Parent.Kit.Pliegues).start(UserArsenal)
		end)
	end)

	-- La ciudad: armerías, comisarías, feria
	local town = workspace:WaitForChild("Town", 300)
	if town then
		for _, d in town:GetDescendants() do
			if d:IsA("Model") then
				if d.Name == "Armeria" then
					safe("armería", function()
						UserArsenal.dressGunShop(d, lib)
					end)
				elseif d.Name == "Feria" then
					safe("feria", function()
						UserArsenal.dressFeria(d, lib)
					end)
				elseif d:FindFirstChild("FrontDesk") and d:FindFirstChild("Emblem") then
					safe("comisaría", function()
						UserArsenal.dressPoliceStation(d, lib)
					end)
				end
			end
		end
	end

	-- Las salas (se construyen al entrar): cuartel, museo, teatro, tiendas de deportes
	local rooms = workspace:WaitForChild("Interiores", 300)
	if rooms then
		local dressers = {
			Interior_Cuartel = UserArsenal.dressCuartel,
			Interior_Museo = UserArsenal.dressMuseo,
			Interior_Teatro = UserArsenal.dressTeatro,
		}
		local function onRoom(child: Instance)
			local fn = dressers[child.Name]
			if child.Name == "Interior_Local" then
				fn = function(room, l)
					if room:GetAttribute("Shop") == "Deportes" then
						return UserArsenal.dressDeportes(room, l)
					end
					return 0
				end
			end
			if fn and child:IsA("Model") then
				-- (la sala se mete en la carpeta antes de amueblarla: se espera a que termine)
				task.delay(0.5, function()
					safe(child.Name, function()
						fn(child, lib)
					end)
				end)
			end
		end
		rooms.ChildAdded:Connect(onRoom)
		for _, child in rooms:GetChildren() do
			onRoom(child)
		end
	end
	local parts = {}
	for id, text in lib.Report do
		table.insert(parts, ("%d=%s"):format(id, text))
	end
	table.sort(parts)
	print(("[UserArsenal] %d armas de malla · %s"):format(kinds, table.concat(parts, " ")))
end

return UserArsenal
