-- MaterialDetail: el detalle del mundo según el nivel gráfico (UI/Perf, shared/Graphics). Todo son
-- cambios locales: no afectan a los demás jugadores.
--
--   * Relieve de las texturas PBR (MaterialService, World/Kit/MaterialLook): en el nivel Bajo se quita
--     el mapa normal de cada material (menos memoria y GPU en el móvil; el color y el brillo se
--     quedan); en Medio y Alto se vuelve a poner. Sin texturas subidas no hace nada.
--   * Suelo mojado: con lluvia (workspace "Wet") el asfalto, las aceras y los bordillos cambian su
--     rugosidad por la «mojada» (shared/Textures.WetSets): casi lisos, y con la iluminación Future
--     reflejan el cielo, las fachadas y las farolas. Al secarse vuelven a la normal. En Bajo no.
--   * Césped 3D: las briznas del terreno (Terrain.Decoration) solo en Medio y Alto.
--   * Árboles: los racimos de relleno de las copas y las raíces (etiqueta LeafDetail, Kit/Nature)
--     se esconden en el nivel Bajo (no se pintan: la mitad de piezas por árbol).

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

-- Racimos de relleno de los árboles: visibles o escondidos solo en esta pantalla
local leafHidden = false
local function applyLeaf(part: Instance)
	if part:IsA("BasePart") then
		part.LocalTransparencyModifier = if leafHidden then 1 else 0
	end
end

function MaterialDetail.apply(tierName: Graphics.TierName)
	local tier = Graphics.tier(tierName)
	for _, variant in MaterialService:GetChildren() do
		applyTo(variant, tier)
	end
	applyGrass(tier)
	local hide = not tier.LeafDetail
	if hide ~= leafHidden then
		leafHidden = hide
		for _, part in CollectionService:GetTagged("LeafDetail") do
			applyLeaf(part)
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
	-- (los árboles llegan con la carga por zonas)
	CollectionService:GetInstanceAddedSignal("LeafDetail"):Connect(function(part)
		if leafHidden then
			applyLeaf(part)
		end
	end)
end

return MaterialDetail
