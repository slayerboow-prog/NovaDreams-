-- NacaraV2Look (servidor): las texturas y los ornamentos de Nácara v2 (docs/mar/nacara-v2/diseno.md §3 bis).
--
--   NacaraV2Look.setup()        qué MaterialVariant «NV2_<Textura>» hay en MaterialService: { [Textura] = true }.
--                               Los crea scripts/build-place.luau DENTRO del archivo del juego, con sus mapas
--                               (un Script no puede escribir los mapas ni BaseMaterial de un MaterialVariant:
--                               PluginSecurity), con los ids de shared/Sea/NacaraV2AssetIds (subidas con
--                               scripts/upload-nacara-v2.sh como Decal; su imagen, shared/TextureImageIds).
--   NacaraV2Look.ornaments()    las MeshParts de los ornamentos (una por malla subida) con su SurfaceAppearance del
--                               atlas; { [Ornamento] = MeshPart } (plantillas sin padre) o {} si no hay ids.
--   NacaraV2Look.variantFor(set, available)  el nombre del variant si está, o nil (entonces, el color liso)
--
-- Sin ids (aún sin subir) no crea nada y Nácara v2 se ve con sus colores lisos y las piezas de respaldo. Solo lo
-- llama World/NacaraV2Builder (Config.Sea.NacaraV2, apagado).

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NacaraV2 = require(ReplicatedStorage.Shared.Sea.NacaraV2)

local NacaraV2Look = {}

local function ids(): { Mallas: { [string]: string }, Texturas: { [string]: string } }
	local ok, t = pcall(function()
		return require(ReplicatedStorage.Shared.Sea.NacaraV2AssetIds)
	end)
	if not ok or type(t) ~= "table" then
		return { Mallas = {}, Texturas = {} }
	end
	local tex = t.Texturas or {}
	if next(tex) ~= nil then
		-- (subidas como Decal: hay que pasarlas a id de imagen o no se ven)
		local Images = require(ReplicatedStorage.Shared.Images)
		pcall(Images.resolve, tex)
		tex = Images.map(tex)
	end
	return { Mallas = t.Mallas or {}, Texturas = tex }
end

local available: { [string]: boolean }? = nil

function NacaraV2Look.setup(): { [string]: boolean }
	if available then
		return available
	end
	local out = {}
	for name in NacaraV2.Textures do
		local v = MaterialService:FindFirstChild(NacaraV2.VariantPrefix .. name)
		if v and v:IsA("MaterialVariant") then
			out[name] = true
		end
	end
	available = out
	return out
end

function NacaraV2Look.variantFor(set: string?, have: { [string]: boolean }): string?
	if set and have[set] then
		return NacaraV2.VariantPrefix .. set
	end
	return nil
end

local templates: { [string]: MeshPart }? = nil

function NacaraV2Look.ornaments(): { [string]: MeshPart }
	if templates then
		return templates
	end
	local out = {}
	local all = ids()
	if next(all.Mallas) ~= nil then
		local AssetLoader = require(script.Parent.AssetLoader)
		for name in NacaraV2.Ornaments do
			local id = all.Mallas[name]
			if id then
				local model = AssetLoader.download(tonumber(string.match(id, "%d+")) or 0)
				local mesh = model and model:FindFirstChildWhichIsA("MeshPart", true)
				if mesh then
					local m = mesh:Clone()
					for _, d in m:GetDescendants() do
						if not d:IsA("SurfaceAppearance") then
							d:Destroy()
						end
					end
					-- (el atlas: SurfaceAppearance si se deja —en el servidor sus mapas son PluginSecurity— y si no, el
					-- color en TextureID, que sí se puede escribir: como World/MarMeshes)
					local color, normal = all.Texturas.ornamentos_color, all.Texturas.ornamentos_normal
					if color and not m:FindFirstChildOfClass("SurfaceAppearance") then
						local okSa = pcall(function()
							local sa = Instance.new("SurfaceAppearance")
							sa.ColorMap = color
							if normal then
								sa.NormalMap = normal
							end
							sa.Parent = m
						end)
						if not okSa then
							pcall(function()
								m.TextureID = color
							end)
						end
					end
					m.Anchored = true
					m.CanCollide = false
					m.CanQuery = false
					m.CanTouch = false
					m.CastShadow = false
					out[name] = m
				end
			end
		end
	end
	templates = out
	return out
end

return NacaraV2Look
