-- Prueba del CATÁLOGO DE EFECTOS de la historia (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-vfx.luau
--
-- Comprueba:
--   1. Cada receta de shared/StoryFxCatalog está bien (tipo conocido, sonidos e impactos que existen) y
--      todas las texturas y sonidos son internos de Roblox (rbxasset://, nada de internet).
--   2. Cada efecto SE CONSTRUYE de verdad (con instancias de Roblox de Lune) en los tres niveles gráficos,
--      se anima hasta el final sin errores, se para cuando se le pide (portal, orbe, aura, tormenta,
--      grieta) y no deja nada al quitarlo.
--   3. Versión ligera: en gráficos Bajo salen menos partículas, menos escombros, menos luces y ninguna
--      luz con sombra; en Alto, la principal sí. Y el tope global de partículas recorta.
--   4. Lo que cada efecto pide al cliente: el meteorito lanza su impacto donde cae; el impacto hace
--      temblar, destella y suena; la tormenta oscurece el cielo y lo devuelve; el cambio de cielo igual.
--   5. El cráter que se queda (StoryFxBuild.crater): más rocas cuanto mejor el nivel, brillo y humo
--      según el estado.
--   6. Los cielos puntuales (shared/SkyMoods) solo tocan valores de la luz que existen (DayGrade) y se
--      mezclan poco a poco.

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Instance, Vector3 = roblox.Instance, roblox.Vector3
local CFrame = L.CFrame
local check = L.check

local Catalog = L.load("src/shared/StoryFxCatalog")
local Build = L.load("src/shared/StoryFxBuild")
local SkyMoods = L.load("src/shared/SkyMoods")
local DayGrade = L.load("src/shared/DayGrade")

---------------------------------------------------------------------
print("1. Recetas")
---------------------------------------------------------------------
local names = {}
for name, recipe in Catalog.Recipes do
	table.insert(names, name)
	local problems = Catalog.check(name, recipe)
	for _, p in problems do
		print("     " .. p)
	end
	check(#problems == 0, "receta " .. name)
end
table.sort(names)
for _, needed in { "Meteor", "MeteorImpact", "Crater", "Explosion", "Portal", "GroundCrack", "MysticOrb", "EnergyAura", "LocalStorm", "SkyShift" } do
	check(Catalog.Recipes[needed] ~= nil, "el catálogo tiene " .. needed)
end
local external = false
for _, tex in Catalog.Textures do
	if tex:sub(1, 11) ~= "rbxasset://" then
		external = true
	end
end
for _, sound in Catalog.Sounds do
	if sound.Id:sub(1, 11) ~= "rbxasset://" then
		external = true
	end
end
check(not external, "texturas y sonidos internos de Roblox (rbxasset://)")

---------------------------------------------------------------------
print("2-4. Construir y animar cada efecto en cada nivel")
---------------------------------------------------------------------
local function countOf(root: any, className: string): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d.ClassName == className then
			n += 1
		end
	end
	return n
end

local function shadowsOf(root: any): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d.ClassName == "PointLight" and d.Shadows then
			n += 1
		end
	end
	return n
end

local stats = {} -- [name][tier] = { Rate, Emitters, Lights, Shadows, Parts, Emits }
local function run(name: string, tier: string)
	local parent = Instance.new("Folder")
	local emits = {}
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Parent = model
	local ctx = {
		CFrame = CFrame.new(0, 0, 0),
		To = if name == "Meteor" then CFrame.new(40, 0, 20) else nil,
		Tier = tier,
		Parent = parent,
		Model = if name == "EnergyAura" then model else nil,
		Params = if name == "Portal" then { Teleport = { "Yo" } } elseif name == "MysticOrb" then { Rise = 3 } else nil,
		Emit = function(kind, ...)
			table.insert(emits, { Kind = kind, Args = { ... } })
		end,
	}
	local ok, handle = pcall(Build.build, name, ctx)
	if not ok or not handle then
		check(false, ("%s (%s) se construye: %s"):format(name, tier, tostring(handle)))
		return nil
	end
	local snapshot = {
		Rate = handle.Rate,
		Emitters = countOf(parent, "ParticleEmitter") + countOf(model, "ParticleEmitter"),
		Lights = countOf(parent, "PointLight") + countOf(model, "PointLight"),
		Shadows = shadowsOf(parent) + shadowsOf(model),
		Parts = countOf(parent, "Part"),
		Emits = emits,
	}
	-- Animar: hasta que acabe (o 8 s y pararlo, si dura hasta que se pare)
	local recipe = Catalog.get(name)
	local t, dt = 0, 1 / 30
	local alive = true
	local errorText = nil
	local peak = {}
	local stopAt = if (recipe.Seconds or 0) <= 0 then 8 else nil
	local stopped = false
	while alive and t < 30 do
		t += dt
		local okStep, result = pcall(handle.Update, dt, t)
		if not okStep then
			errorText = tostring(result)
			break
		end
		alive = result
		if name == "Portal" then
			for _, d in parent:GetDescendants() do
				if d.Name == "Interior" then
					peak.Portal = math.max(peak.Portal or 0, d.Size.Y)
				end
			end
		elseif name == "GroundCrack" then
			for _, d in parent:GetDescendants() do
				if d.Name == "Luz" then
					peak.Crack = math.max(peak.Crack or 0, d.Size.X)
				end
			end
		end
		if stopAt and not stopped and t >= stopAt then
			stopped = true
			handle.Stop()
		end
	end
	check(errorText == nil, ("%s (%s) se anima sin errores%s"):format(name, tier, if errorText then ": " .. errorText else ""))
	check(not alive, ("%s (%s) acaba (%s)"):format(name, tier, if stopAt then "al pararlo" else "solo"))
	handle.Destroy()
	check(#parent:GetChildren() == 0, ("%s (%s) no deja nada al quitarlo"):format(name, tier))
	if name == "EnergyAura" then
		check(root:FindFirstChild("AuraFx") == nil, "el aura se quita del personaje")
	end
	snapshot.Peak = peak
	snapshot.Time = t
	stats[name] = stats[name] or {}
	stats[name][tier] = snapshot
	return snapshot
end

for _, name in names do
	for _, tier in { "Low", "Medium", "High" } do
		run(name, tier)
	end
end

local function emitted(snapshot, kind: string): { any }?
	for _, e in snapshot.Emits do
		if e.Kind == kind then
			return e.Args
		end
	end
	return nil
end

-- Versión ligera
for _, name in names do
	local low, high = stats[name] and stats[name].Low, stats[name] and stats[name].High
	if low and high then
		check(low.Rate <= high.Rate, ("%s: en Bajo no más partículas que en Alto (%d ≤ %d)"):format(name, low.Rate, high.Rate))
		check(low.Shadows == 0, name .. ": en Bajo ninguna luz con sombra")
		check(low.Lights <= high.Lights, name .. ": en Bajo no más luces")
	end
end
check(stats.MeteorImpact.Low.Rate < stats.MeteorImpact.High.Rate * 0.5, "impacto en Bajo: menos de la mitad de partículas")
check(stats.MeteorImpact.Low.Parts < stats.MeteorImpact.High.Parts, "impacto en Bajo: menos escombros")
check(stats.MeteorImpact.High.Shadows >= 1, "impacto en Alto: el destello echa sombra")
check(Catalog.squeeze(0, 100, "Low") == 1, "tope global: si cabe, no recorta")
check(Catalog.squeeze(240, 100, "Low") < 0.2, "tope global: si no cabe, recorta lo nuevo")
check(Catalog.squeeze(2000, 100, "High") == 0, "tope global: lleno, lo nuevo no echa partículas")

-- Lo que piden al cliente
local meteor = stats.Meteor.Medium
local chain = emitted(meteor, "Chain")
check(chain and chain[1] == "MeteorImpact" and (chain[2].Position - Vector3.new(40, 0, 20)).Magnitude < 1e-3, "el meteorito lanza su impacto justo donde cae")
check(emitted(meteor, "Sound") ~= nil, "el meteorito silba")
check(math.abs(meteor.Time - Catalog.Recipes.Meteor.Seconds) < 0.1, "y tarda lo que dice la receta en caer")
local impact = stats.MeteorImpact.Medium
local shake = emitted(impact, "Shake")
check(shake and shake[1] > 0.5 and shake[4] ~= nil, "el impacto hace temblar (con radio)")
check(emitted(impact, "Flash") ~= nil and emitted(impact, "Sound") ~= nil, "el impacto destella y suena")
local storm = stats.LocalStorm.Medium
check(emitted(storm, "Sky") ~= nil and emitted(storm, "Sky")[1] == "Tormenta", "la tormenta oscurece el cielo (capa Tormenta)")
check(emitted(storm, "SkyPop") ~= nil, "y al acabar lo devuelve")
local strikes = 0
for _, e in storm.Emits do
	if e.Kind == "Sound" then
		strikes += 1
	end
end
check(strikes >= 2, ("caen rayos con trueno (%d en 8 s)"):format(strikes))
check(emitted(stats.SkyShift.Medium, "Sky") ~= nil and emitted(stats.SkyShift.Medium, "SkyPop") ~= nil, "el cambio de cielo pone su capa y la quita")
check((stats.Portal.High.Peak.Portal or 0) > 7, ("el portal se abre (llega a %.1f studs)"):format(stats.Portal.High.Peak.Portal or 0))
check((stats.GroundCrack.Medium.Peak.Crack or 0) > 1, "la grieta del suelo se abre")
check(emitted(stats.GroundCrack.Medium, "Shake") ~= nil, "y hace temblar")
check(Build.build("NoExiste", { CFrame = CFrame.new(), Parent = Instance.new("Folder"), Tier = "Low" }) == nil, "un efecto que no existe no rompe nada")

---------------------------------------------------------------------
print("5. El cráter que se queda")
---------------------------------------------------------------------
local function rocks(tier: string, glow: boolean, smoke: boolean)
	local parent = Instance.new("Folder")
	local model = Build.crater(parent, CFrame.new(0, 0, 0), { Radius = 4, Tier = tier, Glow = if glow then roblox.Color3.new(0, 1, 0) else nil, Smoke = smoke })
	local n = 0
	for _, d in model:GetChildren() do
		if d.Name == "Roca" then
			n += 1
		end
	end
	return n, countOf(model, "PointLight"), countOf(model, "ParticleEmitter"), model
end
local lowRocks = rocks("Low", false, false)
local highRocks, highLights, highEmitters = rocks("High", true, true)
check(lowRocks < highRocks, ("más rocas en el borde con mejores gráficos (%d < %d)"):format(lowRocks, highRocks))
check(highLights >= 1 and highEmitters >= 2, "humeante: brilla y echa humo y chispas")
local _, coldLights, coldEmitters, coldModel = rocks("Medium", false, false)
check(coldLights == 0 and coldEmitters == 0, "frío: sin brillo ni humo")
local solid = 0
for _, d in coldModel:GetChildren() do
	if d.Name == "Roca" and d.CanCollide then
		solid += 1
	end
end
check(solid > 0, "las rocas del borde se pueden pisar (chocan)")

---------------------------------------------------------------------
print("6. Cielos puntuales")
---------------------------------------------------------------------
local key = DayGrade.sample(14)
for name, mood in SkyMoods.List do
	local unknown = {}
	for field in mood do
		if key[field] == nil then
			table.insert(unknown, field)
		end
	end
	check(#unknown == 0, ("cielo %s solo toca valores que existen%s"):format(name, if #unknown > 0 then " (" .. table.concat(unknown, ", ") .. ")" else ""))
end
local half = SkyMoods.apply(key, SkyMoods.List.Tormenta, 0.5, DayGrade.mix)
check(half.Brightness < key.Brightness and half.Brightness > SkyMoods.List.Tormenta.Brightness, "a medio fundido, la luz está a medio camino")
check(SkyMoods.apply(key, SkyMoods.List.Tormenta, 0, DayGrade.mix) == key, "sin peso, la luz de la hora no cambia (el ciclo del día sigue)")

L.finish("test-vfx")
