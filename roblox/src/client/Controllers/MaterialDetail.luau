-- MaterialDetail: el detalle del mundo según el nivel gráfico (UI/Perf, shared/Graphics). Todo son
-- cambios locales: no afectan a los demás jugadores.
--
--   * Relieve de las texturas PBR (MaterialService, World/Kit/MaterialLook): en el nivel Bajo se quita
--     el mapa normal de cada material (menos memoria y GPU en el móvil; el color y el brillo se
--     quedan); en Medio y Alto se vuelve a poner. Sin texturas subidas no hace nada.
--   * Suelo mojado: con lluvia (workspace "Wet") el asfalto, las aceras y los bordillos cambian su
--     rugosidad por la «mojada» (shared/Textures.WetSets): casi lisos, y con la iluminación Future
--     reflejan el cielo, las fachadas y las farolas. Al secarse vuelven a la normal. En Bajo no.
--     (Solo en NUESTROS variants: los de los packs del dueño, World/UserMaterials, no dejan cambiar
--     sus mapas; ahí el mojado lo pone Controllers/WetWorld: más oscuro, reflejo y charcos.)
--   * Césped 3D: las briznas del terreno (Terrain.Decoration) solo en Medio y Alto.
--   * Árboles: los racimos de relleno de las copas y las raíces (etiqueta LeafDetail, Kit/Nature)
--     se esconden en el nivel Bajo (no se pintan: la mitad de piezas por árbol).
--   * Ciudad: las tejas con relieve, cornisas, zócalos, portales, el desgaste del asfalto y los
--     adornos de las farolas (etiqueta CityDetail, Kit/CityDetail) también se esconden en Bajo:
--     queda la ciudad lisa de antes.

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

-- Detalle que el nivel Bajo esconde (solo en esta pantalla): etiqueta -> campo del nivel
local DETAIL_TAGS = { LeafDetail = "LeafDetail", CityDetail = "CityDetail" }
local hidden: { [string]: boolean } = { LeafDetail = false, CityDetail = false }
local function applyDetail(part: Instance, hide: boolean)
	if part:IsA("BasePart") then
		part.LocalTransparencyModifier = if hide then 1 else 0
	end
end

function MaterialDetail.apply(tierName: Graphics.TierName)
	local tier = Graphics.tier(tierName)
	for _, variant in MaterialService:GetChildren() do
		applyTo(variant, tier)
	end
	applyGrass(tier)
	for tag, field in DETAIL_TAGS do
		local hide = not (tier :: any)[field]
		if hide ~= hidden[tag] then
			hidden[tag] = hide
			for _, part in CollectionService:GetTagged(tag) do
				applyDetail(part, hide)
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
	-- (los árboles y los edificios llegan con la carga por zonas)
	for tag in DETAIL_TAGS do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(part)
			if hidden[tag] then
				applyDetail(part, true)
			end
		end)
	end
end

return MaterialDetail
