-- MaterialDetail: el detalle del mundo según el nivel gráfico (UI/Perf, shared/Graphics). Todo son
-- cambios locales: no afectan a los demás jugadores.
--
--   * Relieve de las texturas PBR (MaterialService, World/Kit/MaterialLook): se pone o se quita el mapa
--     normal según el nivel (Graphics.Tier.NormalMaps; hoy en todos, es barato). Sin texturas subidas
--     no hace nada.
--   * Suelo mojado: con lluvia (workspace "Wet") el asfalto, las aceras y los bordillos cambian su
--     rugosidad por la «mojada» (shared/Textures.WetSets): casi lisos, y con la iluminación Future
--     reflejan el cielo, las fachadas y las farolas. Al secarse vuelven a la normal. En Bajo no.
--     (Solo en NUESTROS variants: los de los packs del dueño, World/UserMaterials, no dejan cambiar
--     sus mapas; ahí el mojado lo pone Controllers/WetWorld: más oscuro, reflejo y charcos.)
--   * Césped 3D: las briznas del terreno (Terrain.Decoration) según el nivel.
--   * Etiquetas (Graphics.DetailTags dice qué campo del nivel manda en cada una). En Bajo se esconde
--     SOLO lo pesado: el relleno de las copas (LeafDetail), las tejas y molduras de Kit/CityDetail y el
--     skyline (CityDetail) y los edificios 3D (BuildingMesh: se ve la caja de antes, BuildingShell).
--     Lo nuevo y barato (objetos de malla de la calle, naturaleza, muebles, señales, láminas:
--     PropDetail, PropMesh, PropShell, DecorProp, StreetSign, TextureDetail) se ve en TODOS los niveles.
--   * Distancia de detalle (Tier.DetailRadius): en Medio las piezas pequeñas de CityDetail solo cerca
--     de la cámara; en Alto hasta donde llegue la vista.

local CollectionService = game:GetService("CollectionService")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graphics = require(ReplicatedStorage.Shared.Graphics)
local Textures = require(ReplicatedStorage.Shared.Textures)
local Perf = require(script.Parent.Parent.UI.Perf)

local MaterialDetail = {}

local function wetAmount(): number
	local wet = workspace:GetAttribute("Wet")
	return if type(wet) == "number" then wet else 0
end

local function setMap(v: any, property: string, want: string)
	if v[property] ~= want then
		pcall(function()
			v[property] = want
		end)
	end
end

local function applyTo(variant: Instance, tier: Graphics.Tier)
	if not variant:IsA("MaterialVariant") then
		return
	end
	local v = variant :: any
	local id = variant:GetAttribute("NormalMapId")
	if type(id) == "string" and id ~= "" then
		setMap(v, "NormalMap", if tier.NormalMaps then id else "")
	end
	local dry = variant:GetAttribute("DryRoughnessId")
	local wetId = variant:GetAttribute("WetRoughnessId")
	if type(dry) == "string" and dry ~= "" and type(wetId) == "string" and wetId ~= "" then
		setMap(v, "RoughnessMap", Textures.roughnessFor(dry, wetId, wetAmount(), tier.WetGloss))
	end
end

-- Briznas de césped del terreno
local function applyGrass(tier: Graphics.Tier)
	pcall(function()
		local terrain = workspace.Terrain :: any
		if terrain.Decoration ~= tier.GrassBlades then
			terrain.Decoration = tier.GrassBlades
		end
	end)
end

-- Detalle que el nivel puede esconder (solo en esta pantalla): etiqueta -> campo del nivel
-- (shared/Graphics.DetailTags). Casos especiales al esconder:
-- (StreetSign: las señales de tráfico de World/StreetDress; su poste deja de chocar al esconderse)
-- (PropShell / BuildingShell: la pieza hecha por código que sustituye una malla; solo se ve cuando la
-- malla se esconde)
-- (TextureDetail: láminas de World/MaterialExtras: se esconde solo la lámina «U_Lamina», la pieza sigue)
local DETAIL_TAGS = Graphics.DetailTags
local hidden: { [string]: boolean } = {}
for tag in DETAIL_TAGS do
	hidden[tag] = false
end
local function applyDetail(part: Instance, hide: boolean, tag: string?)
	if not part:IsA("BasePart") then
		return
	end
	if tag == "TextureDetail" then
		for _, child in part:GetChildren() do
			if child:IsA("Texture") and child.Name == "U_Lamina" then
				child.LocalTransparencyModifier = if hide then 1 else 0
			end
		end
	elseif tag == "BuildingShell" then
		-- (al revés: la caja de antes solo se ve cuando se esconde el detalle; cambio local)
		part.Transparency = if hide then 0 else 1
	elseif tag == "PropShell" then
		local before = part:GetAttribute("ShellTransparency")
		part.Transparency = if hide then (if type(before) == "number" then before else 0) else 1
	else
		part.LocalTransparencyModifier = if hide then 1 else 0
		-- (las imágenes pegadas a la pieza, como las señales y las tapas del road pack, van aparte)
		for _, child in part:GetChildren() do
			if child:IsA("Decal") then
				child.LocalTransparencyModifier = if hide then 1 else 0
			end
		end
		if (tag == "StreetSign" or tag == "DecorProp" or tag == "PropDetail") and part:GetAttribute("Solid") then
			part.CanCollide = not hide -- (sin poste invisible con el que chocar)
		end
	end
end

-- Distancia de detalle (Graphics.Tier.DetailRadius): en Medio las piezas PEQUEÑAS de CityDetail
-- (tejas, molduras, desgaste…) solo se ven cerca de la cámara; en Alto, todas. Se repasan poco a
-- poco (unas cientas cada vez) para no dar tirones. El skyline y lo grande no se tocan.
local SMALL = 16 -- (studs: lo más grande de una pieza «pequeña»)
local SWEEP_BATCH = 600
local farHidden: { [Instance]: boolean } = {}
local radius = math.huge
local function setFar(part: BasePart, far: boolean)
	if far then
		farHidden[part] = true
	else
		farHidden[part] = nil
	end
	part.LocalTransparencyModifier = if far then 1 else 0
end
local function clearFar()
	for part in farHidden do
		if (part :: any).Parent then
			setFar(part :: any, false)
		end
	end
	table.clear(farHidden)
end
MaterialDetail._farHidden = farHidden -- (pruebas)

function MaterialDetail.sweep(eye: Vector3, parts: { Instance }, from: number, count: number): number
	if hidden.CityDetail or radius == math.huge or radius <= 0 then
		return #parts + 1
	end
	local last = math.min(#parts, from + count - 1)
	for i = from, last do
		local part = parts[i]
		if part:IsA("BasePart") and part.Parent then
			local size = part.Size
			if math.max(size.X, size.Y, size.Z) < SMALL then
				local far = (part.Position - eye).Magnitude > radius
				if far ~= (farHidden[part] == true) then
					setFar(part, far)
				end
			end
		end
	end
	return last + 1
end

function MaterialDetail.apply(tierName: Graphics.TierName)
	local tier = Graphics.tier(tierName)
	local newRadius = if tier.DetailRadius and tier.DetailRadius > 0 then tier.DetailRadius else math.huge
	if newRadius ~= radius then
		radius = newRadius
		clearFar() -- (el repaso vuelve a esconder lo lejano con la distancia nueva)
	end
	for _, variant in MaterialService:GetChildren() do
		applyTo(variant, tier)
	end
	applyGrass(tier)
	for tag in DETAIL_TAGS do
		local hide = Graphics.hides(tierName, tag)
		if hide ~= hidden[tag] then
			hidden[tag] = hide
			for _, part in CollectionService:GetTagged(tag) do
				applyDetail(part, hide, tag)
			end
		end
	end
end

function MaterialDetail.init()
	MaterialDetail.apply(Perf.tierName())
	Perf.onTier(MaterialDetail.apply)
	MaterialService.ChildAdded:Connect(function(variant)
		applyTo(variant, Graphics.tier(Perf.tierName()))
	end)
	-- La rugosidad mojada sigue a la lluvia (el servidor sube y baja "Wet" poco a poco)
	workspace:GetAttributeChangedSignal("Wet"):Connect(function()
		local tier = Graphics.tier(Perf.tierName())
		for _, variant in MaterialService:GetChildren() do
			applyTo(variant, tier)
		end
	end)
	-- Distancia de detalle: un repaso continuo, a trozos
	task.spawn(function()
		local parts: { Instance } = {}
		local index = 1
		while true do
			task.wait(0.25)
			pcall(function()
				if index > #parts then
					parts = CollectionService:GetTagged("CityDetail")
					index = 1
				end
				local camera = workspace.CurrentCamera
				if camera then
					index = MaterialDetail.sweep(camera.CFrame.Position, parts, index, SWEEP_BATCH)
				end
			end)
		end
	end)
	-- (los árboles y los edificios llegan con la carga por zonas)
	for tag in DETAIL_TAGS do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(part)
			if hidden[tag] then
				applyDetail(part, true, tag)
			end
		end)
	end
end

return MaterialDetail
