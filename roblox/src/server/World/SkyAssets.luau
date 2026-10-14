-- SkyAssets (servidor): carga los assets de cielo, tiempo, efectos, luz y sonidos que pidió el dueño
-- (shared/SkyExtras) y los deja listos para los clientes:
--
--   * ReplicatedStorage.SkyLibrary: cielos especiales hechos por nosotros con las imágenes de los
--     assets (Verde, Isla, Arcoiris, Asteroides) y los 11 clásicos (Clasico_*). Los packs con puerta
--     trasera NO se meten en el juego: de los clásicos se copian solo las caras a un Sky nuevo y el
--     paquete descargado se destruye al momento (sus scripts nunca llegan a correr).
--   * ReplicatedStorage.FxLibrary: la luna 3D (Luna3D), el fuego (Fuego), la nube de tormenta
--     (NubeTormenta) y, como atributos, las imágenes del pack de partículas (Img_Chispa, Img_Cometa…),
--     la gota de lluvia (LluviaImagen), su sonido (LluviaSonido) y las texturas del agua (Agua1..n).
--   * La luna 2D del cielo: la textura y el tamaño de 12737479807.
-- Todo lo cargado: sin scripts, sin letreros ni marcas, piezas ancladas y sin chocar. Si algo no carga,
-- se usa el respaldo (los ids conocidos) o no se hace: el juego sigue igual.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkyExtras = require(ReplicatedStorage.Shared.SkyExtras)
local MeshLibrary = require(script.Parent.MeshLibrary)

local SkyAssets = {}

local MAX_PARTS = 12 -- (la luna, el fuego y la nube son 1-3 piezas: si trae más, es otra cosa)

local function folder(name: string): Instance
	local found = ReplicatedStorage:FindFirstChild(name)
	if not found then
		found = Instance.new("Folder")
		found.Name = name
		found.Parent = ReplicatedStorage
	end
	return found
end

-- Descarga con el cargador compartido (World/AssetLoader: LoadAssetAsync, InsertService, reintentos y
-- cola). nil si no carga.
local function download(id: number): Instance?
	local ok, asset = pcall(function()
		return require(script.Parent.AssetLoader).download(id)
	end)
	return if ok then asset else nil
end

-- Quita scripts, letreros y textos (marcas) de lo cargado. Devuelve cuántos scripts había.
function SkyAssets.clean(root: Instance, keepDecals: boolean?): number
	local scripts = MeshLibrary.stripScripts(root)
	for _, d in root:GetDescendants() do
		if d:IsA("SurfaceGui") or d:IsA("BillboardGui") or d:IsA("TextLabel") or d:IsA("ScreenGui") then
			d:Destroy()
		elseif not keepDecals and d:IsA("Decal") then
			d:Destroy()
		end
	end
	return scripts
end

local function setFlags(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
end

local function makeSky(name: string, faces: { [string]: string }, library: Instance): Instance?
	for _, face in SkyExtras.Faces do
		if not SkyExtras.validFace(faces[face]) then
			return nil
		end
	end
	local old = library:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local sky = Instance.new("Sky")
	sky.Name = name
	for _, face in SkyExtras.Faces do
		(sky :: any)[face] = faces[face]
	end
	sky.Parent = library
	return sky
end

-- Los cielos hechos a mano (ids conocidos, nada que descargar)
function SkyAssets.buildSkies(library: Instance): number
	local n = 0
	for name, def in SkyExtras.Skies do
		if makeSky(name, def.Faces, library) then
			n += 1
		end
	end
	return n
end

-- Los 11 clásicos: solo se COPIAN las caras de cada Sky; el paquete se destruye entero
function SkyAssets.copyClassic(asset: Instance, library: Instance): number
	local n = 0
	local list = if asset:IsA("Sky") then { asset } else {}
	for _, d in asset:GetDescendants() do
		if d:IsA("Sky") then
			table.insert(list, d)
		end
	end
	for _, sky in list do
		local slot = SkyExtras.classicSlot(sky.Name)
		if slot and not library:FindFirstChild(slot) then
			local faces = {}
			for _, face in SkyExtras.Faces do
				faces[face] = (sky :: any)[face]
			end
			if makeSky(slot, faces, library) then
				n += 1
			end
		end
	end
	asset:Destroy()
	return n
end

-- La primera pieza que cumpla `test`, sacada del asset y limpia (el resto se destruye)
local function takePart(asset: Instance, test: (BasePart) -> boolean): BasePart?
	local found: BasePart? = nil
	local count = 0
	for _, d in asset:GetDescendants() do
		if d:IsA("BasePart") then
			count += 1
			if not found and test(d) then
				found = d
			end
		end
	end
	if not found or count > MAX_PARTS then
		asset:Destroy()
		return nil
	end
	local part = found :: BasePart
	part.Parent = nil
	asset:Destroy()
	setFlags(part)
	return part
end

-- 8159177542: la luna (MeshPart con SurfaceAppearance). Fuera el fondo negro (Background).
function SkyAssets.takeMoon(asset: Instance, fx: Instance): BasePart?
	SkyAssets.clean(asset)
	local moon = takePart(asset, function(p)
		return p:IsA("MeshPart") and p.Name ~= "Background"
	end)
	if moon then
		moon.Name = "Luna3D"
		for _, d in moon:GetChildren() do
			if not d:IsA("SurfaceAppearance") then
				d:Destroy()
			end
		end
		moon.Parent = fx
	end
	return moon
end

-- 11365590395: el fuego. Se queda una pieza invisible con su ParticleEmitter y su Smoke.
function SkyAssets.takeFire(asset: Instance?, fx: Instance): BasePart
	local emitter: ParticleEmitter? = nil
	local smoke: Smoke? = nil
	if asset then
		SkyAssets.clean(asset)
		for _, d in asset:GetDescendants() do
			if d:IsA("ParticleEmitter") and not emitter then
				emitter = d
			elseif d:IsA("Smoke") and not smoke then
				smoke = d
			end
		end
	end
	local holder = Instance.new("Part")
	holder.Name = "Fuego"
	holder.Size = Vector3.new(2, 0.4, 2)
	holder.Transparency = 1
	setFlags(holder)
	if emitter then
		emitter.Parent = holder
	else
		-- respaldo: el mismo fuego hecho a mano con su imagen
		local e = Instance.new("ParticleEmitter")
		e.Texture = SkyExtras.FireImage
		e.Rate = 75
		e.Lifetime = NumberRange.new(1)
		e.Speed = NumberRange.new(2, 4)
		e.LightEmission = 1
		e.Parent = holder
		emitter = e
	end
	(emitter :: ParticleEmitter).Name = "Llamas"
	if smoke then
		smoke.Parent = holder
		smoke.Name = "Humo"
	end
	if asset then
		asset:Destroy()
	end
	local old = fx:FindFirstChild("Fuego")
	if old then
		old:Destroy()
	end
	holder.Parent = fx
	return holder
end

-- 979423743: la nube de malla (la pieza más grande; su luz apagada y el resto fuera)
function SkyAssets.takeCloud(asset: Instance, fx: Instance): BasePart?
	SkyAssets.clean(asset)
	local biggest: BasePart? = nil
	for _, d in asset:GetDescendants() do
		if d:IsA("BasePart") and (not biggest or d.Size.Magnitude > (biggest :: BasePart).Size.Magnitude) then
			biggest = d
		end
	end
	local cloud = if biggest then takePart(asset, function(p)
		return p == biggest
	end) else nil
	if not cloud then
		asset:Destroy()
		return nil
	end
	cloud.Name = "NubeTormenta"
	for _, d in cloud:GetDescendants() do
		if d:IsA("Light") then
			d:Destroy()
		end
	end
	cloud.Parent = fx
	return cloud
end

-- 13188926423: las imágenes de partículas por nombre -> atributos Img_<Clave> de FxLibrary
function SkyAssets.indexImages(asset: Instance, fx: Instance): number
	MeshLibrary.stripScripts(asset)
	local n = 0
	for _, d in asset:GetDescendants() do
		if d:IsA("Decal") then
			local holder = d.Parent
			local key = SkyExtras.imageKey(if holder then holder.Name .. " " .. d.Name else d.Name)
			if key and fx:GetAttribute("Img_" .. key) == nil and SkyExtras.validFace(d.Texture) then
				fx:SetAttribute("Img_" .. key, d.Texture)
				n += 1
			end
		end
	end
	asset:Destroy()
	return n
end

-- 11552439884: la gota y el sonido de la lluvia (con los conocidos de respaldo)
function SkyAssets.takeRain(asset: Instance?, fx: Instance)
	local image, sound = SkyExtras.RainImage, SkyExtras.RainSound
	if asset then
		MeshLibrary.stripScripts(asset)
		for _, d in asset:GetDescendants() do
			if d:IsA("ParticleEmitter") and SkyExtras.validFace(d.Texture) then
				image = d.Texture
			elseif d:IsA("Sound") and SkyExtras.validFace(d.SoundId) then
				sound = d.SoundId
			end
		end
		asset:Destroy()
	end
	fx:SetAttribute("LluviaImagen", image)
	fx:SetAttribute("LluviaSonido", sound)
end

-- 223224044: las texturas del agua (el script que la movía cambiando tamaños no se usa)
function SkyAssets.takeWater(asset: Instance, fx: Instance): number
	MeshLibrary.stripScripts(asset)
	local n = 0
	for _, d in asset:GetDescendants() do
		if d:IsA("Texture") and SkyExtras.validFace(d.Texture) and n < 6 then
			n += 1
			fx:SetAttribute("Agua" .. n, d.Texture)
		end
	end
	asset:Destroy()
	return n
end

-- La luna del cielo de Lighting (12737479807: solo la textura y el tamaño)
function SkyAssets.moon2D(lighting: Instance)
	local sky = lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky.MoonTextureId = SkyExtras.Moon.TextureId
		sky.MoonAngularSize = SkyExtras.Moon.AngularSize
	end
end

function SkyAssets.start(load: ((number) -> Instance?)?)
	local get = load or download
	local library = folder(SkyExtras.Library)
	local fx = folder(SkyExtras.FxLibrary)
	local function try(name: string, fn: () -> ())
		local ok, err = pcall(fn)
		if not ok then
			warn(("[SkyAssets] %s: %s"):format(name, tostring(err)))
		end
	end
	try("cielos", function()
		SkyAssets.buildSkies(library)
	end)
	try("luna 2D", function()
		SkyAssets.moon2D(game:GetService("Lighting"))
	end)
	try("fuego", function()
		SkyAssets.takeFire(get(SkyExtras.FireId), fx)
	end)
	try("lluvia", function()
		SkyAssets.takeRain(get(SkyExtras.RainId), fx)
	end)
	try("partículas", function()
		local asset = get(SkyExtras.ParticlesId)
		if asset then
			SkyAssets.indexImages(asset, fx)
		end
	end)
	try("luna 3D", function()
		local asset = get(SkyExtras.MoonMeshId)
		if asset then
			SkyAssets.takeMoon(asset, fx)
		end
	end)
	try("nube", function()
		local asset = get(SkyExtras.CloudId)
		if asset then
			SkyAssets.takeCloud(asset, fx)
		end
	end)
	try("agua", function()
		local asset = get(SkyExtras.WaterId)
		if asset then
			SkyAssets.takeWater(asset, fx)
		end
	end)
	try("cielos clásicos", function()
		local asset = get(SkyExtras.ClassicId)
		if asset then
			SkyAssets.copyClassic(asset, library)
		end
	end)
	fx:SetAttribute("Listo", true)
end

return SkyAssets
