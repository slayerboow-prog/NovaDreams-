-- Monta el Model COMPLETO de la nave realista (fase 3 de scripts/upload-nave.sh): coge la MeshPart de
-- cada pieza descargada (<dir>/<Pieza>.rbxm, los Model que Roblox hizo con cada FBX), la pone en su sitio
-- (assets/nave/manifest.json: centro y tamaño en studs), le da material, color y su SurfaceAppearance
-- (ColorMap, NormalMap, RoughnessMap, MetalnessMap: los scripts del juego no pueden crearla con mapas,
-- por eso va ya dentro del Model) y lo guarda en un .rbxm para subirlo.
--
--   lune run scripts/nave/compose.luau <dir> <manifest.json> <texturas.txt> <salida.rbxm>
--   (texturas.txt: líneas «casco_color=rbxassetid://…»)
-- Sin ninguna clave: solo lee y escribe archivos.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Instance, Vector3, CFrame, Color3, Enum = roblox.Instance, roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

local Compose = {}

local function findMeshPart(list: { any }): any?
	for _, inst in list do
		if inst.ClassName == "MeshPart" then
			return inst
		end
		for _, d in inst:GetDescendants() do
			if d.ClassName == "MeshPart" then
				return d
			end
		end
	end
	return nil
end

-- pieces: los del manifest; files: nombre -> contenido .rbxm; textures: "casco_color" -> id
function Compose.build(pieces: { any }, files: { [string]: string }, textures: { [string]: string }): (any, { string })
	local model = Instance.new("Model")
	model.Name = "NaveHX7"
	local missing = {}
	for _, piece in pieces do
		local bytes = files[piece.Name]
		local mp = if bytes then findMeshPart(roblox.deserializeModel(bytes)) else nil
		if not mp then
			table.insert(missing, piece.Name)
			continue
		end
		local p = mp:Clone()
		for _, d in p:GetChildren() do
			d.Parent = nil
		end
		p.Name = piece.Name
		local c, s = piece.Center, piece.Size
		p.Size = Vector3.new(s[1], s[2], s[3])
		p.CFrame = CFrame.new(c[1], c[2], c[3])
		p.Anchored = true
		p.CanCollide = false
		p.Material = (Enum.Material :: any)[piece.Material] or Enum.Material.Metal
		if piece.Color then
			p.Color = Color3.fromRGB(piece.Color[1], piece.Color[2], piece.Color[3])
		end
		if piece.Material == "Glass" then
			p.Transparency = 0.35
		end
		local set = piece.Set
		if set and textures[set .. "_color"] then
			local sa = Instance.new("SurfaceAppearance")
			sa.ColorMap = textures[set .. "_color"]
			if textures[set .. "_normal"] then
				sa.NormalMap = textures[set .. "_normal"]
			end
			if textures[set .. "_rugosidad"] then
				sa.RoughnessMap = textures[set .. "_rugosidad"]
			end
			if textures[set .. "_metal"] then
				sa.MetalnessMap = textures[set .. "_metal"]
			end
			sa.Parent = p
		end
		p.Parent = model
	end
	return model, missing
end

function Compose.readTextures(text: string): { [string]: string }
	local out = {}
	for line in string.gmatch(text, "[^\n]+") do
		local k, v = string.match(line, "^%s*([%w_]+)%s*=%s*(%S+)")
		if k then
			out[k] = v
		end
	end
	return out
end

local args = process.args
if #args >= 4 then
	local dir, manifestPath, texPath, outPath = args[1], args[2], args[3], args[4]
	local manifest = serde.decode("json", fs.readFile(manifestPath))
	local files = {}
	for _, piece in manifest.Pieces do
		local path = dir .. "/" .. piece.Name .. ".rbxm"
		if fs.isFile(path) then
			files[piece.Name] = fs.readFile(path)
		end
	end
	local model, missing = Compose.build(manifest.Pieces, files, Compose.readTextures(fs.readFile(texPath)))
	if #missing > 0 then
		print("⚠️  faltan piezas en las descargas: " .. table.concat(missing, ", "))
	end
	fs.writeFile(outPath, roblox.serializeModel({ model }))
	print(("🧩 %s con %d piezas"):format(outPath, #model:GetChildren()))
end

return Compose
