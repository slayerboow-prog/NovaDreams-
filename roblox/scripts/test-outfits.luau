-- Prueba de los 30 CONJUNTOS DE ROPA del pase (shared/Outfits + shared/OutfitBuilder) FUERA de Roblox,
-- con Lune, en cuerpos R15 y R6 de verdad (instancias de Lune).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-outfits.luau
--
-- Comprueba que:
--   * están los 30 de la hoja, con su número, nombre y rareza; sin «Nova» ni marcas reales
--     («VALMAR TEAM» y la camiseta «VALMAR 23»);
--   * los tres de oficios son «Estilo …», solo ropa: no dan Job, ni uniforme, ni textos oficiales;
--   * las plantillas (assets/outfits, scripts/outfits/gen.py) existen, miden 585×559 y respetan la
--     plantilla clásica de Roblox (nada fuera de las caras; camisa en el torso, pantalón en las piernas);
--   * cada pieza 3D va soldada (WeldConstraint) a una parte del cuerpo, sin colisión ni masa, en R15 y
--     en R6, de adulto y en talla de niño (sin ombligo al aire ni tacones); con plantillas pone Shirt/Pants;
--   * AvatarService: el conjunto equipado se viste; el bebé lleva pelele; de servicio con uniforme (o en
--     prisión) se guarda y vuelve al acabar; un trabajo sin uniforme no lo quita;
--   * BattlePassRewardService: conseguir, equipar, quitar y guardar/cargar (JSON) el conjunto;
--   * el pase (Season1) da los 30, una vez cada uno, con su rareza, y siguen los 13 vehículos.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local CFrame, Vector3, Color3, Enum, Instance = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Roblox de mentira (lo justo) y carga de módulos de src/
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in handlers do
				fn(...)
			end
		end,
	}
end

-- Random (Lune no lo trae)
local RandomShim = {}
function RandomShim.new(seed: number?)
	local state = math.floor(seed or 1) % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local r = {}
	local function nextRaw()
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
	function r:NextNumber(a, b)
		local v = nextRaw()
		return if a then a + (b - a) * v else v
	end
	function r:NextInteger(a, b)
		return a + math.floor(nextRaw() * (b - a + 1))
	end
	return r
end

local warnings = {}
local mocks: { [string]: any } = {}
local modules: { [string]: any } = {}
local services: { [string]: any } = {}
local fakeGame = { GetService = function(_, name)
	return services[name] or { Name = name }
end }

local function node(path: string): any
	return setmetatable({ __path = path }, { __index = function(_, k)
		if k == "Parent" then
			return node((path:match("^(.*)/[^/]+$")) or "")
		end
		return node(path .. "/" .. k)
	end })
end
services.ReplicatedStorage = { Shared = node("shared") }

local load
local function resolve(what: any): any
	local path = if type(what) == "table" then rawget(what, "__path") else what
	assert(type(path) == "string", "require de algo raro: " .. tostring(what))
	if mocks[path] ~= nil then
		return mocks[path]
	end
	if modules[path] == nil then
		modules[path] = load("src/" .. path .. ".luau", node(path))
	end
	return modules[path]
end
function load(path: string, script: any): any
	local env = setmetatable({
		CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum, Instance = Instance,
		Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, UDim = roblox.UDim, Random = RandomShim,
		game = fakeGame, script = script, require = resolve,
		task = { spawn = function(fn, ...) fn(...) end, delay = function() end, defer = function(fn, ...) fn(...) end, wait = function() end },
		warn = function(...)
			table.insert(warnings, table.concat({ ... }, " "))
		end,
	}, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local Outfits = resolve("shared/Outfits")
local Builder = resolve("shared/OutfitBuilder")
local BPConfig = resolve("shared/BattlePass/Config")
local Catalog = resolve("shared/BattlePass/Catalog")
local S1 = BPConfig.Seasons[1]

---------------------------------------------------------------------
-- Cuerpos R15 y R6 de verdad
---------------------------------------------------------------------
local R15 = {
	HumanoidRootPart = { Vector3.new(2, 2, 1), Vector3.new(0, 3, 0) },
	LowerTorso = { Vector3.new(2, 0.4, 1), Vector3.new(0, 2.8, 0) },
	UpperTorso = { Vector3.new(2, 1.6, 1), Vector3.new(0, 3.8, 0) },
	Head = { Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 5.2, 0) },
	LeftUpperArm = { Vector3.new(1, 1.2, 1), Vector3.new(-1.5, 4, 0) },
	LeftLowerArm = { Vector3.new(1, 1, 1), Vector3.new(-1.5, 2.9, 0) },
	LeftHand = { Vector3.new(1, 0.3, 1), Vector3.new(-1.5, 2.25, 0) },
	RightUpperArm = { Vector3.new(1, 1.2, 1), Vector3.new(1.5, 4, 0) },
	RightLowerArm = { Vector3.new(1, 1, 1), Vector3.new(1.5, 2.9, 0) },
	RightHand = { Vector3.new(1, 0.3, 1), Vector3.new(1.5, 2.25, 0) },
	LeftUpperLeg = { Vector3.new(1, 1.2, 1), Vector3.new(-0.5, 2, 0) },
	LeftLowerLeg = { Vector3.new(1, 1.1, 1), Vector3.new(-0.5, 0.9, 0) },
	LeftFoot = { Vector3.new(1, 0.3, 1), Vector3.new(-0.5, 0.2, 0) },
	RightUpperLeg = { Vector3.new(1, 1.2, 1), Vector3.new(0.5, 2, 0) },
	RightLowerLeg = { Vector3.new(1, 1.1, 1), Vector3.new(0.5, 0.9, 0) },
	RightFoot = { Vector3.new(1, 0.3, 1), Vector3.new(0.5, 0.2, 0) },
}
local R6 = {
	HumanoidRootPart = { Vector3.new(2, 2, 1), Vector3.new(0, 3, 0) },
	Torso = { Vector3.new(2, 2, 1), Vector3.new(0, 3, 0) },
	Head = { Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0) },
	["Left Arm"] = { Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0) },
	["Right Arm"] = { Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0) },
	["Left Leg"] = { Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0) },
	["Right Leg"] = { Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0) },
}

local function rig(kind: string, scale: number?): any
	local k = scale or 1
	local model = Instance.new("Model")
	model.Name = "Ana"
	for name, def in (if kind == "R6" then R6 else R15) do
		local p = Instance.new("Part")
		p.Name = name
		p.Size = def[1] * k
		p.CFrame = CFrame.new(def[2] * k)
		p.Parent = model
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = if kind == "R6" then Enum.HumanoidRigType.R6 else Enum.HumanoidRigType.R15
	humanoid.Parent = model
	return model
end

local function piecesOf(model: any): { any }
	local folder = model:FindFirstChild("ValmarLook")
	local out = {}
	if folder then
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(out, d)
			end
		end
	end
	return out
end

local function named(model: any, name: string): number
	local n = 0
	for _, p in piecesOf(model) do
		if p.Name == name then
			n += 1
		end
	end
	return n
end

-- Todas soldadas a una parte del cuerpo de ESTE personaje, sin colisión ni masa y cerca de ella
local function weldProblems(model: any): { string }
	local bad = {}
	for _, p in piecesOf(model) do
		local weld = p:FindFirstChildOfClass("WeldConstraint")
		local body = weld and weld.Part0
		if not weld or weld.Part1 ~= p or not body or body.Parent ~= model or body:IsDescendantOf(model:FindFirstChild("ValmarLook")) then
			table.insert(bad, p.Name .. " sin soldar al cuerpo")
		elseif p.CanCollide or not p.Massless or p.CanTouch or p.CanQuery or p.Anchored then
			table.insert(bad, p.Name .. " con colisión o masa")
		elseif (p.CFrame.Position - body.CFrame.Position).Magnitude > 6 * (body.Size.Magnitude / 2 + 1) then
			table.insert(bad, p.Name .. " lejos de su parte")
		end
		if #bad > 5 then
			break
		end
	end
	return bad
end

---------------------------------------------------------------------
print("▶ Los 30 conjuntos de la hoja")
---------------------------------------------------------------------
local SHEET = {
	{ "Urban Classic", "Legendaria" }, { "Coast Vibes", "Epica" }, { "Shadow Ops", "Legendaria" }, { "Sporty Girl", "Epica" },
	{ "Valmar Team", "Rara" }, { "Business Lady", "Epica" }, { "Estilo Bombero", "Legendaria" }, { "Estilo Sanitaria", "Epica" },
	{ "Estilo Policía", "Legendaria" }, { "Summer Dream", "Epica" }, { "Caballero", "Rara" }, { "Elegance", "Legendaria" },
	{ "Basket Life", "Epica" }, { "Gym Girl", "Rara" }, { "Tech Wear", "Epica" }, { "Ranchera", "Legendaria" },
	{ "Purple Vibes", "Epica" }, { "Goth Style", "Rara" }, { "Tropical", "Epica" }, { "Street Skater", "Legendaria" },
	{ "Montaña", "Epica" }, { "Cyber Pink", "Legendaria" }, { "Racing", "Epica" }, { "Bohemia", "Rara" },
	{ "Winter", "Legendaria" }, { "Neon", "Epica" }, { "Urbano Cultural", "Rara" }, { "Tennis", "Epica" },
	{ "Future", "Legendaria" }, { "Ángel", "Legendaria" },
}
check(#Outfits.List == 30, ("30 conjuntos (%d)"):format(#Outfits.List))
do
	local bad = {}
	for i, o in Outfits.List do
		local want = SHEET[i]
		if o.Key ~= ("O%02d"):format(i) or o.Number ~= i or o.Name ~= want[1] or o.Rarity ~= want[2] or not BPConfig.Rarities[o.Rarity] then
			table.insert(bad, ("%s %s"):format(tostring(o.Key), tostring(o.Name)))
		end
		if not (o.Top and o.Top.Color and o.Bottom and o.Bottom.Color and o.Shoes and o.Shoes.Color and o.Description and o.Icon and o.Colors) then
			table.insert(bad, tostring(o.Key) .. " incompleto")
		end
		for _, a in o.Accessories or {} do
			if not Builder.Accessories[a.Kind] then
				table.insert(bad, tostring(o.Key) .. " accesorio desconocido " .. tostring(a.Kind))
			end
		end
		if not Builder.Shoes[o.Shoes.Kind] then
			table.insert(bad, tostring(o.Key) .. " zapato desconocido " .. tostring(o.Shoes.Kind))
		end
	end
	check(#bad == 0, "clave, número, nombre y rareza de la hoja; todo con piezas que existen" .. (if #bad > 0 then " (" .. table.concat(bad, ", ") .. ")" else ""))
	local counts = { Legendaria = 0, Epica = 0, Rara = 0 }
	for _, o in Outfits.List do
		counts[o.Rarity] += 1
	end
	check(counts.Legendaria == 11 and counts.Epica == 13 and counts.Rara == 6, ("rarezas de la hoja: %d legendarios, %d épicos, %d raros"):format(counts.Legendaria, counts.Epica, counts.Rara))
end

-- Palabras prohibidas (el logo de la hoja no es nuestro y nada de marcas reales)
local FORBIDDEN = table.clone(Outfits.Forbidden)
for _, w in { "ford", "ferrari", "porsche", "bmw", "mercedes", "honda", "yamaha", "police" } do
	table.insert(FORBIDDEN, w)
end
local function forbiddenIn(text: string): string?
	local lower = string.lower(text)
	for _, word in FORBIDDEN do
		if string.find(lower, "%f[%w]" .. word .. "%f[%W]") then
			return word
		end
	end
	return nil
end
do
	local texts = {}
	local function collect(value: any)
		if type(value) == "string" then
			table.insert(texts, value)
		elseif type(value) == "table" then
			for _, v in value do
				collect(v)
			end
		end
	end
	for _, o in Outfits.List do
		local copy = table.clone(o)
		copy.Forbidden = nil
		collect(copy)
	end
	local bad = forbiddenIn(table.concat(texts, " "))
	check(bad == nil, "sin «Nova» ni marcas en nombres, descripciones y estampados" .. (if bad then " — «" .. bad .. "»" else ""))
	for _, path in { "src/shared/OutfitBuilder.luau", "scripts/outfits/gen.py", "scripts/upload-outfits.sh", "src/shared/BattlePass/Season1.luau" } do
		local found = forbiddenIn(fs.readFile(path))
		check(found == nil, path .. ": limpio" .. (if found then " — «" .. found .. "»" else ""))
	end
	local team, jersey = Outfits.get("O05"), Outfits.get("O13")
	check(team.Name == "Valmar Team" and team.Top.Back.Text == "VALMAR TEAM", "el 05 es «VALMAR TEAM»")
	check(jersey.Top.Print.Text == "VALMAR" and jersey.Top.Number == "23", "la camiseta de baloncesto dice «VALMAR 23»")
end

print("▶ Ropa de oficios: solo estilo")
do
	local costumes = {}
	for _, o in Outfits.List do
		if o.Costume then
			table.insert(costumes, o.Key)
			local texts = {}
			for _, field in { o.Top.Print, o.Top.Back, o.Top.InnerPrint } do
				table.insert(texts, field and string.upper(field.Text) or "")
			end
			for _, a in o.Accessories do
				table.insert(texts, if type(a.Back) == "string" then string.upper(a.Back) else "")
			end
			local all = table.concat(texts, " ")
			check(string.sub(o.Name, 1, 7) == "Estilo " and not all:find("POLIC") and not all:find("BOMBERO") and not all:find("SANIT"), o.Key .. " «" .. o.Name .. "»: nombre «Estilo …» y sin rótulos oficiales (" .. all .. ")")
		end
	end
	check(table.concat(costumes, ",") == "O07,O08,O09", "los de oficios son 07, 08 y 09")
	local police = Outfits.get("O09")
	local cap
	for _, a in police.Accessories do
		if a.Kind == "Cap" then
			cap = a
		end
	end
	check(cap and cap.Style == "Patrol" and cap.Color ~= Color3.fromRGB(24, 40, 90), "la gorra de estilo policía es negra con banda, sin placa (la oficial es azul con placa dorada)")
	check(Outfits.get("O07").Accessories[1].Color ~= Color3.fromRGB(250, 210, 40), "el casco de estilo bombero no es el amarillo oficial")
	check(Outfits.SuspendJobs.Policia and Outfits.SuspendJobs.Bombero and Outfits.SuspendJobs.Militar and not Outfits.SuspendJobs.Barista, "de servicio con uniforme (policía, bomberos, ejército…) el conjunto se guarda; de barista, no")
end

---------------------------------------------------------------------
print("▶ Plantillas de ropa (assets/outfits)")
---------------------------------------------------------------------
local function pngSize(path: string): (number?, number?)
	if not fs.isFile(path) then
		return nil, nil
	end
	local data = fs.readFile(path)
	if string.sub(data, 2, 4) ~= "PNG" then
		return nil, nil
	end
	local w = string.unpack(">I4", data, 17)
	local h = string.unpack(">I4", data, 21)
	return w, h
end
do
	local missing = {}
	for _, o in Outfits.List do
		for _, kind in { "shirt", "pants" } do
			local path = ("assets/outfits/%s_%s.png"):format(string.lower(o.Key), kind)
			local w, h = pngSize(path)
			if w ~= 585 or h ~= 559 then
				table.insert(missing, path .. " (" .. tostring(w) .. "×" .. tostring(h) .. ")")
			end
		end
	end
	check(#missing == 0, "60 plantillas de 585×559 (camisa y pantalón por conjunto)" .. (if #missing > 0 then ": " .. table.concat(missing, ", ") else ""))
	-- La forma de la plantilla clásica (con Pillow, si está)
	local script = [[
import sys, glob
from PIL import Image
T = {"U": (231, 8, 128, 64), "F": (231, 74, 128, 128), "R": (165, 74, 64, 128), "L": (361, 74, 64, 128), "B": (427, 74, 128, 128), "D": (231, 204, 128, 64)}
RA = {"L": (19, 355, 64, 128), "B": (85, 355, 64, 128), "R": (151, 355, 64, 128), "F": (217, 355, 64, 128), "U": (217, 289, 64, 64), "D": (217, 485, 64, 64)}
LA = {"F": (308, 355, 64, 128), "L": (374, 355, 64, 128), "B": (440, 355, 64, 128), "R": (506, 355, 64, 128), "U": (308, 289, 64, 64), "D": (308, 485, 64, 64)}
rects = list(T.values()) + list(RA.values()) + list(LA.values())
def inside(x, y):
    return any(rx <= x < rx + w and ry <= y < ry + h for rx, ry, w, h in rects)
def opaque(img, r):
    rx, ry, w, h = r
    a = img.getchannel("A").crop((rx, ry, rx + w, ry + h))
    return sum(1 for v in a.getdata() if v > 0) / (w * h)
bad = []
for path in sorted(glob.glob("assets/outfits/o*_*.png")):
    img = Image.open(path).convert("RGBA")
    a = img.getchannel("A").load()
    out = sum(1 for y in range(0, 559, 2) for x in range(0, 585, 2) if a[x, y] > 0 and not inside(x, y))
    if out:
        bad.append(path + " pinta fuera de las caras (%d)" % out)
    if path.endswith("_shirt.png") and opaque(img, T["F"]) < 0.2:
        bad.append(path + " sin torso")
    if path.endswith("_pants.png") and (opaque(img, RA["F"]) < 0.12 or opaque(img, LA["F"]) < 0.12):
        bad.append(path + " sin piernas")
print("OK" if not bad else "\n".join(bad))
]]
	local ok, result = pcall(process.exec, "python3", { "-c", script })
	if ok and result.ok and string.find(result.stdout, "^OK") then
		check(true, "todas respetan la plantilla clásica (nada fuera de las caras, torso y piernas pintados)")
	elseif ok and result.ok then
		check(false, "plantilla clásica: " .. result.stdout)
	else
		print("  ⚠️ sin python3 + Pillow: no se mira el dibujo de las plantillas")
	end
end

---------------------------------------------------------------------
print("▶ Vestir en R15 y R6 (adulto y niño)")
---------------------------------------------------------------------
local SKIN = Color3.fromRGB(234, 190, 150)
do
	local bad = {}
	local total = 0
	for _, kind in { "R15", "R6" } do
		for _, stage in { "Adulto", "Nino" } do
			for _, o in Outfits.List do
				local model = rig(kind, if stage == "Nino" then 0.65 else 1)
				local before = #warnings
				local ok, err = pcall(Builder.dress, model, o, { Stage = stage, Skin = SKIN, Seed = 7 })
				if not ok then
					table.insert(bad, ("%s %s %s: %s"):format(kind, stage, o.Key, tostring(err)))
				elseif #warnings > before then
					table.insert(bad, ("%s %s %s: %s"):format(kind, stage, o.Key, warnings[#warnings]))
				else
					local problems = weldProblems(model)
					total += #piecesOf(model)
					if #problems > 0 then
						table.insert(bad, ("%s %s %s: %s"):format(kind, stage, o.Key, table.concat(problems, "; ")))
					end
					local folder = model:FindFirstChild("ValmarLook")
					if not folder or folder:GetAttribute("Outfit") ~= o.Key or #piecesOf(model) < 15 then
						table.insert(bad, ("%s %s %s: pocas piezas"):format(kind, stage, o.Key))
					end
				end
				if #bad > 6 then
					break
				end
			end
		end
	end
	check(#bad == 0, ("los 30 se visten en R15 y R6, de adulto y de niño: %d piezas, todas soldadas al cuerpo, sin colisión ni masa"):format(total) .. (if #bad > 0 then "\n     " .. table.concat(bad, "\n     ") else ""))
end

do
	local angel = rig("R15")
	Builder.dress(angel, Outfits.get("O30"), { Stage = "Adulto", Skin = SKIN })
	local light = false
	for _, d in angel:GetDescendants() do
		light = light or d:IsA("PointLight")
	end
	check(named(angel, "Feather") >= 30 and named(angel, "WingGlow") >= 12 and named(angel, "Halo") >= 12 and light, "Ángel: alas de plumas con brillo suave (neón translúcido + luz) y aureola")
	local glow = nil
	for _, p in piecesOf(angel) do
		if p.Name == "WingGlow" then
			glow = p
		end
	end
	check(glow and glow.Material == Enum.Material.Neon and glow.Transparency >= 0.7, "el brillo de las alas es suave (neón muy translúcido)")

	local checks = {
		{ "O16", "HatBrim", "sombrero vaquero" }, { "O20", "Deck", "monopatín a la espalda" }, { "O20", "EarCup", "auriculares" },
		{ "O28", "RacketFrame", "raqueta" }, { "O23", "Helmet", "casco en la mano" }, { "O06", "Handbag", "bolso" },
		{ "O06", "CoatTail", "abrigo largo" }, { "O12", "Gown", "vestido largo" }, { "O18", "Skirt", "falda plisada" },
		{ "O21", "Backpack", "mochila" }, { "O01", "Chain", "cadena" }, { "O03", "Glove", "guantes" }, { "O03", "FaceMask", "braga de cuello" },
		{ "O26", "GoggleLens", "gafas de ventisca" }, { "O25", "Scarf", "bufanda" }, { "O07", "HelmetDome", "casco" },
		{ "O16", "CowboyBoot", "botas camperas" }, { "O13", "Basketball", "balón" }, { "O02", "HairLong", "melena" },
		{ "O22", "Twintail", "coletas" }, { "O11", "BowTie", "pajarita" }, { "O09", "Vest", "chaleco" },
	}
	local bad = {}
	for _, c in checks do
		local model = rig("R15")
		Builder.dress(model, Outfits.get(c[1]), { Stage = "Adulto", Skin = SKIN })
		if named(model, c[2]) == 0 then
			table.insert(bad, c[1] .. " " .. c[3])
		end
	end
	check(#bad == 0, "accesorios en su sitio: gorras, sombreros, gafas, cascos, alas, mochilas, cadenas, guantes, botas, raqueta…" .. (if #bad > 0 then " (faltan: " .. table.concat(bad, ", ") .. ")" else ""))

	-- La espalda del chaleco de estilo policía dice ESTILO, no POLICÍA
	local police = rig("R15")
	Builder.dress(police, Outfits.get("O09"), { Stage = "Adulto", Skin = SKIN })
	local texts = {}
	for _, d in police:GetDescendants() do
		if d:IsA("TextLabel") then
			table.insert(texts, d.Text)
		end
	end
	check(table.find(texts, "ESTILO") ~= nil and not table.concat(texts, " "):upper():find("POLIC"), "estilo policía: «ESTILO» a la espalda, ningún «POLICÍA»")
end

print("▶ Talla de niño")
do
	local adult, kid = rig("R15"), rig("R15", 0.65)
	local coast = Outfits.get("O02")
	Builder.dress(adult, coast, { Stage = "Adulto", Skin = SKIN, Ids = {} }) -- (modo de piezas, sin plantillas)
	Builder.dress(kid, coast, { Stage = "Nino", Skin = SKIN, Ids = {} })
	check(named(adult, "Crop") == 1 and adult.UpperTorso.Color == SKIN, "adulto: top corto con el ombligo al aire")
	check(named(kid, "Crop") == 0 and kid.UpperTorso.Color == coast.Top.Color, "niño: el top le tapa la tripa")
	local elegance = Outfits.get("O12")
	local a2, k2 = rig("R15"), rig("R15", 0.65)
	Builder.dress(a2, elegance, { Stage = "Adulto", Skin = SKIN })
	Builder.dress(k2, elegance, { Stage = "Nino", Skin = SKIN })
	check(named(a2, "HeelPost") == 2 and named(k2, "HeelPost") == 0 and named(k2, "Flat") == 2, "niño: zapato plano en vez de tacón")
	check(named(a2, "Gown") < 16 and named(k2, "Gown") == 16, "adulto: vestido con abertura; niño: sin abertura")
	local goth = Outfits.get("O18")
	local k3 = rig("R15", 0.65)
	Builder.dress(k3, goth, { Stage = "Nino", Skin = SKIN })
	check(k3.LeftUpperLeg.Color == goth.Bottom.Color, "niño: medias opacas en vez de rejilla")
	-- Las piezas siguen la talla: el sombrero de un niño es más pequeño
	local ka, kk = rig("R15"), rig("R15", 0.65)
	Builder.dress(ka, Outfits.get("O16"), { Stage = "Adulto", Skin = SKIN })
	Builder.dress(kk, Outfits.get("O16"), { Stage = "Nino", Skin = SKIN })
	local function brim(m)
		for _, p in piecesOf(m) do
			if p.Name == "HatBrim" then
				return p.Size.X
			end
		end
		return 0
	end
	check(math.abs(brim(kk) / brim(ka) - 0.65) < 0.01, "todo a escala del cuerpo (el sombrero de niño es un 65 %)")
end

print("▶ Con plantillas subidas: ropa clásica + 3D")
do
	local model = rig("R15")
	local o = Outfits.get("O13")
	Builder.dress(model, o, { Stage = "Adulto", Skin = SKIN, Ids = { Shirt = "rbxassetid://111", Pants = "rbxassetid://222" } })
	local shirt, pants = model:FindFirstChild("ValmarShirt"), model:FindFirstChild("ValmarPants")
	check(shirt and shirt:IsA("Shirt") and shirt.ShirtTemplate == "rbxassetid://111" and pants and pants:IsA("Pants") and pants.PantsTemplate == "rbxassetid://222", "Shirt y Pants con sus plantillas")
	check(named(model, "Number") == 0 and named(model, "Basketball") == 1 and model.ValmarLook:GetAttribute("Textured") == true, "los estampados los pone la plantilla (no piezas); los accesorios 3D siguen")
	check(model.UpperTorso.Color == SKIN, "debajo de la plantilla, piel")
	Builder.dress(model, o, { Stage = "Adulto", Skin = SKIN, Ids = {} })
	check(model:FindFirstChild("ValmarShirt") == nil and named(model, "Number") == 1, "sin plantillas: fuera la ropa clásica y vuelve el modo de colores y piezas")
	local a, b = Builder.idsFor("O01")
	check((a == nil) == (b == nil) and (a == nil or (a:match("^rbxassetid://%d+$") ~= nil and b:match("^rbxassetid://%d+$") ~= nil)), "OutfitIds: o las dos plantillas (rbxassetid) o ninguna (sin subir): ningún conjunto se rompe")
end

---------------------------------------------------------------------
print("▶ AvatarService: vestir, bebé, uniformes y prisión")
---------------------------------------------------------------------
local profiles = {}
local loadedFns = {}
mocks["server/Services/DataService"] = {
	get = function(p)
		return profiles[p]
	end,
	waitFor = function() end,
	onLoaded = function(fn)
		table.insert(loadedFns, fn)
	end,
}
mocks["server/Services/LifeService"] = { refresh = function() end }
local playerAdded = signal()
local playerList = {}
services.Players = {
	PlayerAdded = playerAdded,
	PlayerRemoving = signal(),
	GetPlayers = function()
		return playerList
	end,
	GetPlayerByUserId = function(_, id)
		for _, p in playerList do
			if p.UserId == id then
				return p
			end
		end
		return nil
	end,
}
local avatarRemote = { OnServerEvent = signal() }
services.ReplicatedStorage.WaitForChild = function(self, name)
	if name == "Remotes" then
		return { WaitForChild = function()
			return avatarRemote
		end }
	end
	return self[name]
end

local function newPlayer(name: string, id: number, stage: string)
	local attrs, sigs = { LifeStage = stage }, {}
	local p = { Name = name, UserId = id, CharacterAdded = signal(), Character = nil }
	function p:GetAttribute(k)
		return attrs[k]
	end
	function p:GetAttributeChangedSignal(k)
		sigs[k] = sigs[k] or signal()
		return sigs[k]
	end
	function p:SetAttribute(k, v)
		local changed = attrs[k] ~= v
		attrs[k] = v
		if changed and sigs[k] then
			sigs[k]:Fire()
		end
	end
	function p:HasAppearanceLoaded()
		return true
	end
	profiles[p] = { OwnAvatar = false }
	table.insert(playerList, p)
	return p
end

local Avatar = resolve("server/Services/AvatarService")
local equipped: { [any]: any } = {}
Avatar.OutfitFor = function(p)
	return equipped[p]
end
local eva = newPlayer("Eva", 501, "Adulto")
Avatar.init()
eva.Character = rig("R15")
local function outfitOn(p): string?
	local folder = p.Character and p.Character:FindFirstChild("ValmarLook")
	return folder and folder:GetAttribute("Outfit")
end
Avatar._dress(eva, eva.Character)
check(outfitOn(eva) == nil and named(eva.Character, "Backpack") == 1, "sin conjunto: el aspecto de Valmar de siempre (con su mochila)")
equipped[eva] = Catalog.get("S1_O09")
Avatar._dress(eva, eva.Character)
check(outfitOn(eva) == "O09", "con el estilo policía equipado, se viste con él")
check(eva:GetAttribute("Job") == nil and eva.Character:FindFirstChild("PoliceUniform") == nil, "la ropa no da trabajo ni uniforme oficial (Job sigue vacío)")
eva:SetAttribute("Job", "Policia")
check(outfitOn(eva) == nil and named(eva.Character, "Hood") == 1, "de servicio en la policía: el conjunto se guarda (debajo del uniforme oficial, el aspecto de siempre)")
eva:SetAttribute("Job", nil)
check(outfitOn(eva) == "O09", "al acabar el turno vuelve el conjunto")
eva:SetAttribute("Job", "Bombero")
check(outfitOn(eva) == nil, "de bombero, igual")
eva:SetAttribute("Job", "Barista")
check(outfitOn(eva) == "O09", "un trabajo sin uniforme (barista) no quita el conjunto")
eva:SetAttribute("Job", nil)
eva:SetAttribute("JailUntil", 12345)
check(outfitOn(eva) == nil, "en prisión, sin conjunto (el mono naranja va encima del aspecto de siempre)")
eva:SetAttribute("JailUntil", nil)
check(outfitOn(eva) == "O09", "y al salir, vuelve")
eva:SetAttribute("LifeStage", "Bebe")
check(outfitOn(eva) == nil and named(eva.Character, "Bib") == 1, "el bebé lleva su pelele")
eva:SetAttribute("LifeStage", "Nino")
check(outfitOn(eva) == "O09", "de niño, el conjunto en talla de niño")
equipped[eva] = { Colors = { Hoodie = Color3.fromRGB(200, 0, 0) } } -- (forma vieja: solo colores)
Avatar._dress(eva, eva.Character)
check(outfitOn(eva) == nil and eva.Character.UpperTorso.Color == Color3.fromRGB(200, 0, 0), "un conjunto viejo de solo colores sigue funcionando (aspecto de Valmar con sus colores)")
profiles[eva].OwnAvatar = true
equipped[eva] = Catalog.get("S1_O30")
Avatar._dress(eva, eva.Character)
check(eva.Character:FindFirstChild("ValmarLook") == nil, "con el avatar propio de Roblox no se pone nada encima")

---------------------------------------------------------------------
print("▶ Pase: conseguir, equipar, quitar y guardar")
---------------------------------------------------------------------
local applied = 0
mocks["server/Services/AvatarService"] = { apply = function()
	applied += 1
end }
mocks["server/Services/BattlePassSeasonService"] = {
	activeFor = function()
		return true
	end,
	ensure = function(data)
		data.Cosmetics = data.Cosmetics or {}
		local c = data.Cosmetics
		c.Owned = c.Owned or {}
		c.Equipped = c.Equipped or {}
		c.Equipped.VehicleSkin = c.Equipped.VehicleSkin or {}
		c.Equipped.Decor = c.Equipped.Decor or {}
		c.Perks = c.Perks or {}
		c.Tokens = c.Tokens or 0
		return {}
	end,
}
mocks["server/Services/VehicleService"] = { grant = function()
	return true
end }
BPConfig.Enabled = true
local Rewards = resolve("server/Services/BattlePassRewardService")
local leo = newPlayer("Leo", 502, "Adulto")
leo.Character = rig("R15")
profiles[leo] = { OwnAvatar = true }
check(Rewards.outfitFor(leo) == nil, "sin conjuntos: nada")
check(Rewards.grant(leo, Catalog.get("S1_O09"), "S1") and profiles[leo].Cosmetics.Owned.S1_O09 ~= nil, "conseguir el estilo policía")
local worn = Rewards.outfitFor(leo)
check(worn and worn.Outfit == "O09" and profiles[leo].Cosmetics.Equipped.Outfit == "S1_O09" and applied >= 1, "el primero se pone solo y se viste al momento")
check(leo:GetAttribute("BP_Outfit") == "S1_O09" and leo:GetAttribute("Job") == nil, "atributo BP_Outfit (y ningún Job)")
local okNo, why = Rewards.equip(leo, "Outfit", "S1_O30")
check(not okNo and why == "NotOwned", "no se equipa uno que no tienes")
Rewards.grant(leo, Catalog.get("S1_P50"), "S1")
check(profiles[leo].Cosmetics.Owned.S1_O30 ~= nil and profiles[leo].Cosmetics.Equipped.Outfit == "S1_O09", "el Ángel llega con el conjunto del 50 (sin quitarte el que llevas)")
check(Rewards.equip(leo, "Outfit", "S1_O30") and Rewards.outfitFor(leo).Outfit == "O30", "EQUIPAR el Ángel")
check(profiles[leo].OwnAvatar == false and leo:GetAttribute("OwnAvatar") == false, "al equipar un conjunto se deja el avatar propio (para verlo)")
local okBad = Rewards.equip(leo, "Title", "S1_O30")
check(not okBad, "un conjunto no va en el hueco de un título")
-- Guardar y cargar (como el DataStore: JSON)
local saved = serde.decode("json", serde.encode("json", profiles[leo]))
local leo2 = newPlayer("Leo", 502, "Adulto")
profiles[leo2] = saved
check(Rewards.outfitFor(leo2) and Rewards.outfitFor(leo2).Outfit == "O30", "tras guardar y volver a entrar sigue puesto")
check(Rewards.equip(leo2, "Outfit", nil) and Rewards.outfitFor(leo2) == nil and leo2:GetAttribute("BP_Outfit") == nil, "QUITAR: vuelve el aspecto de siempre")
check(profiles[leo2].Cosmetics.Owned.S1_O30 ~= nil, "y lo sigues teniendo")

---------------------------------------------------------------------
print("▶ El pase da los 30")
---------------------------------------------------------------------
do
	local seen, free, bad, vehicles = {}, {}, {}, 0
	local function visit(def, level, track, parent)
		if def.Type == "Outfit" then
			local o = Outfits.get(def.Outfit)
			if not o then
				table.insert(bad, tostring(def.Id) .. " sin conjunto")
			else
				seen[o.Key] = (seen[o.Key] or 0) + 1
				if def.Id ~= "S1_" .. o.Key or def.Rarity ~= o.Rarity or def.Name ~= o.Name or type(def.Colors) ~= "table" then
					table.insert(bad, def.Id)
				end
				local preview = def.Preview or (parent and parent.Preview)
				if not (Catalog.get(def.Id) and (def.Preview == nil or def.Preview.Outfit == o.Key)) then
					table.insert(bad, def.Id .. " sin catálogo o vista previa")
				end
				if track == "Free" then
					table.insert(free, o.Key)
				end
				local _ = preview
			end
		elseif def.Type == "VehicleSkin" and type(def.Model) == "string" then
			vehicles += 1
		end
		for _, item in def.Items or {} do
			visit(item, level, track, def)
		end
	end
	for _, r in S1.Rewards do
		visit(r, r.Level, r.Track, nil)
	end
	local all, twice = 0, {}
	for key, n in seen do
		all += 1
		if n > 1 then
			table.insert(twice, key)
		end
	end
	check(all == 30 and #twice == 0, ("el pase da los 30, una vez cada uno (%d)"):format(all) .. (if #twice > 0 then " repetidos: " .. table.concat(twice, ",") else ""))
	check(#bad == 0, "Id «S1_Oxx», nombre, rareza y vista previa de cada uno" .. (if #bad > 0 then " (" .. table.concat(bad, ", ") .. ")" else ""))
	table.sort(free)
	check(table.concat(free, ",") == "O05,O14,O24,O27", "4 en la pista gratis (" .. table.concat(free, ",") .. ")")
	check(vehicles == 13, ("siguen los 13 vehículos premium (%d)"):format(vehicles))
	local fifty = nil
	for _, r in S1.Rewards do
		if r.Level == 50 and r.Track == "Premium" then
			fifty = r
		end
	end
	check(fifty and fifty.Type == "Bundle" and fifty.Rarity == "Legendaria" and Catalog.get("S1_P50_Car") and Catalog.get("S1_O30").Parent == "S1_P50", "el 50 sigue siendo «Faro de Valmar» (coche + título + placa + faro) y trae el Ángel")
	local first = nil
	for _, r in S1.Rewards do
		if r.Level == 1 and r.Track == "Premium" then
			first = r
		end
	end
	check(first and first.Outfit == "O01", "el nivel 1 premium ya es un legendario (Urban Classic)")
end

print()
if failures == 0 then
	print("✅ Conjuntos de ropa: todo correcto")
else
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
