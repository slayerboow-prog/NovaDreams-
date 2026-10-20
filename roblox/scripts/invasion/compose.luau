-- Monta el Model COMPLETO de cada alienígena v2 (fase 3 de scripts/upload-invasion.sh): coge las MeshPart
-- del Model que Roblox hizo con su FBX (<dir>/<Id>.rbxm), las nombra como en el manifest
-- (assets/invasion/manifest.json: Body, Head, ArmL, HeadBrillo, LOD…), les da material y, a las
-- principales, su SurfaceAppearance (ColorMap, NormalMap, RoughnessMap, MetalnessMap del juego de
-- texturas de su raza: los scripts del juego no pueden crearla con mapas, por eso va ya dentro) y lo
-- guarda en <salida>/<Id>.rbxm para subirlo.
--
--   lune run scripts/invasion/compose.luau <dir> <manifest.json> <texturas.txt> <salida>
--   (texturas.txt: líneas «Vortidos_tropas_color=rbxassetid://…»)
-- Sin ninguna clave: solo lee y escribe archivos.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Instance, Vector3, CFrame, Color3, Enum = roblox.Instance, roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

local Compose = {}

local function meshParts(list: { any }): { [string]: any }
	local out = {}
	for _, inst in list do
		local all = { inst }
		for _, d in inst:GetDescendants() do
			table.insert(all, d)
		end
		for _, d in all do
			if d.ClassName == "MeshPart" and out[d.Name] == nil then
				out[d.Name] = d
			end
		end
	end
	return out
end

-- model: una entrada del manifest; bytes: el .rbxm del FBX; textures: "<juego>_<mapa>" -> id
function Compose.build(model: any, bytes: string, textures: { [string]: string }): (any, { string })
	local found = meshParts(roblox.deserializeModel(bytes))
	local out = Instance.new("Model")
	out.Name = model.Id
	local missing = {}
	for _, part in model.Parts do
		local mp = found[part.Name]
		if not mp then
			if not part.Glow and not part.Lod then
				table.insert(missing, part.Name)
			end
			continue
		end
		local p = mp:Clone()
		for _, d in p:GetChildren() do
			d.Parent = nil
		end
		p.Name = part.Name
		local c, s = part.Center, part.Size
		p.Size = Vector3.new(s[1], s[2], s[3])
		p.CFrame = CFrame.new(c[1], c[2], c[3])
		p.Anchored = true
		p.CanCollide = false
		if part.Glow then
			p.Material = Enum.Material.Neon
		elseif part.Crystal then
			-- el cristal de los Vórtidos: Glass cian pálido algo transparente, sin textura
			local cc = model.CrystalColor or { 142, 230, 255 }
			p.Material = Enum.Material.Glass
			p.Color = Color3.fromRGB(cc[1], cc[2], cc[3])
			p.Transparency = 0.18
			p.CastShadow = false
		else
			p.Material = (Enum.Material :: any)[model.Material] or Enum.Material.SmoothPlastic
			p.Color = Color3.new(1, 1, 1)
			local set = model.Set
			if textures[set .. "_color"] then
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
		end
		p.Parent = out
	end
	return out, missing
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
	local dir, manifestPath, texPath, outDir = args[1], args[2], args[3], args[4]
	local manifest = serde.decode("json", fs.readFile(manifestPath))
	local textures = Compose.readTextures(fs.readFile(texPath))
	fs.writeDir(outDir)
	local made = 0
	for _, model in manifest.Models do
		-- (el nombre con que se subió: Asset si lo tiene —los Vórtidos de cristal— y si no su Id)
		local name = model.Asset or model.Id
		local path = dir .. "/" .. name .. ".rbxm"
		if fs.isFile(path) then
			local built, missing = Compose.build(model, fs.readFile(path), textures)
			if #missing > 0 then
				print(("⚠️  %s: faltan %s (se queda con las piezas sueltas)"):format(name, table.concat(missing, ", ")))
			else
				fs.writeFile(outDir .. "/" .. name .. ".rbxm", roblox.serializeModel({ built }))
				made += 1
			end
		end
	end
	print(("🧩 %d modelos completos en %s"):format(made, outDir))
end

return Compose
