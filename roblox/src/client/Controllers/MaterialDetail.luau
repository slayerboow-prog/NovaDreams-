-- MaterialDetail: el relieve de las texturas PBR (MaterialService, World/Kit/MaterialLook) según el
-- nivel gráfico. En el nivel Bajo se quita el mapa normal de cada material (menos memoria y GPU en
-- el móvil; el color y el brillo se quedan); en Medio y Alto se vuelve a poner. Es un cambio local:
-- no afecta a los demás jugadores. Sin texturas subidas no hace nada.

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graphics = require(ReplicatedStorage.Shared.Graphics)
local Perf = require(script.Parent.Parent.UI.Perf)

local MaterialDetail = {}

local function applyTo(variant: Instance, normalMaps: boolean)
	if not variant:IsA("MaterialVariant") then
		return
	end
	local id = variant:GetAttribute("NormalMapId")
	if type(id) ~= "string" or id == "" then
		return
	end
	local want = if normalMaps then id else ""
	local v = variant :: any
	if v.NormalMap ~= want then
		pcall(function()
			v.NormalMap = want
		end)
	end
end

function MaterialDetail.apply(tierName: Graphics.TierName)
	local normalMaps = Graphics.tier(tierName).NormalMaps
	for _, variant in MaterialService:GetChildren() do
		applyTo(variant, normalMaps)
	end
end

function MaterialDetail.init()
	MaterialDetail.apply(Perf.tierName())
	Perf.onTier(MaterialDetail.apply)
	MaterialService.ChildAdded:Connect(function(variant)
		applyTo(variant, Graphics.tier(Perf.tierName()).NormalMaps)
	end)
end

return MaterialDetail
