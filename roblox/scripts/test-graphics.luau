-- Prueba de la calidad gráfica y la iluminación FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-graphics.luau                 (cuentas, presupuestos y farolas de mentira)
--   lune run scripts/test-graphics.luau /tmp/x.rbxl      (además, las farolas y el cristal del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Comprueba que:
--   * el juego usa la iluminación Future y tiene todos los efectos de imagen (resplandor, color, rayos de
--     sol, desenfoque, atmósfera, cielo con estrellas y luna)
--   * la luz y el color de cada hora cambian sin saltos (también al pasar de las 23:59 a las 0:00), la
--     noche es de luna con contraste (no un azul marino plano), la hora dorada es cálida y la noche fría
--   * el tiempo: la lluvia apaga y enfría el color, el cielo tapado quita rayos y deslumbre, el suelo
--     mojado refleja más (y el asfalto mojado brilla), la niebla sube la bruma
--   * niveles Bajo / Medio / Alto: presupuestos de menos a más; el Bajo quita lo caro (sombras,
--     desenfoque, rayos, sombras de luces, carteles que brillan); el nivel de partida según el
--     dispositivo; el modo Auto baja con pocos fps y vuelve a subir con fps de sobra
--   * presupuesto de farolas: de noche, cerca de la cámara nunca hay más luces encendidas que las del
--     nivel (y de día ninguna); las sombras, solo las del nivel
--   * el cristal de las fachadas refleja un poco (Kit/Polish.surfaces)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Enum, Vector3, Color3 = roblox.Enum, roblox.Vector3, roblox.Color3

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local baseEnv = { Enum = Enum, Vector3 = Vector3, Color3 = Color3, CFrame = roblox.CFrame }
local function load(path: string, extra: { [string]: any }?): any
	local env = {}
	for k, v in baseEnv do
		env[k] = v
	end
	for k, v in extra or {} do
		env[k] = v
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local Graphics = load("src/shared/Graphics.luau")
local DayGrade = load("src/shared/DayGrade.luau")
local CONFIG_SCRIPT = { __module = "Config" }
local Seasons = load("src/shared/Seasons.luau", {
	script = { Parent = { Config = CONFIG_SCRIPT } },
	require = function()
		return load("src/shared/Config.luau")
	end,
})
local Wetness = load("src/shared/Wetness.luau")

---------------------------------------------------------------------
print("Archivo del juego (default.project.json)")
---------------------------------------------------------------------
local project = serde.decode("json", fs.readFile("default.project.json"))
local L = project.tree.Lighting
check(L["$properties"].Technology == "Future", "iluminación Future")
local classes = {}
for _, child in L do
	if type(child) == "table" and child["$className"] then
		classes[child["$className"]] = child["$properties"] or {}
	end
end
for _, className in { "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect", "DepthOfFieldEffect", "Sky" } do
	check(classes[className] ~= nil, "efecto de imagen: " .. className)
end
local sky = classes.Sky or {}
check((sky.StarCount or 0) >= 2000 and (sky.MoonAngularSize or 0) >= 9 and (sky.SunAngularSize or 21) < 21, "cielo: estrellas, luna grande y sol nítido")
check(classes.DepthOfFieldEffect and classes.DepthOfFieldEffect.Enabled == false and (classes.DepthOfFieldEffect.FarIntensity or 1) <= 0.1, "desenfoque apagado de serie y muy suave (lo enciende el nivel Alto)")
check((L["$properties"].EnvironmentSpecularScale or 0) > 0 and (L["$properties"].EnvironmentDiffuseScale or 0) > 0, "reflejos y luz del cielo (EnvironmentSpecular/Diffuse)")

---------------------------------------------------------------------
print("Luz de cada hora (shared/DayGrade)")
---------------------------------------------------------------------
-- Cuánto puede cambiar como mucho cada valor en 0,01 horas (36 s de juego, ~0,5 s reales)
local function delta(a: any, b: any): number
	if typeof(a) == "Color3" then
		return math.max(math.abs(a.R - b.R), math.abs(a.G - b.G), math.abs(a.B - b.B))
	end
	return math.abs(a - b)
end
local worst, worstAt, worstName = 0, 0, ""
local STEP = 0.01
local prev = DayGrade.sample(0)
for i = 1, math.floor(24 / STEP) do
	local h = i * STEP
	local k = DayGrade.sample(h)
	for name, value in k do
		local d = delta(prev[name], value)
		-- Relativo al tamaño del valor (Brightness va de 1 a 4; Saturation de -0.1 a 0.3)
		local scale = if typeof(value) == "Color3" then 1 else math.max(0.5, math.abs(value))
		if d / scale > worst then
			worst, worstAt, worstName = d / scale, h, name
		end
	end
	prev = k
end
check(worst < 0.06, ("sin saltos a lo largo del día (el mayor cambio en 36 s de juego: %.3f en %s a las %.2f)"):format(worst, worstName, worstAt))
local late, midnight = DayGrade.sample(23.999), DayGrade.sample(0)
local wrap = 0
for name, value in late do
	wrap = math.max(wrap, delta(value, midnight[name]))
end
check(wrap < 0.01, ("de las 23:59 a las 0:00 no cambia nada (%.4f)"):format(wrap))

local night = DayGrade.sample(23.6) -- la hora de la captura del dueño (23:36)
local noon = DayGrade.sample(13)
local golden = DayGrade.sample(17.3)
local outdoor: Color3 = night.Outdoor
check(night.Brightness >= 1.5, ("de noche la luna modela (Brightness %.2f: luz con dirección y sombras)"):format(night.Brightness))
check(outdoor.B / math.max(outdoor.R, 0.01) < 1.7 and outdoor.B < 0.5, ("la noche no es azul marino plano (ambiente de fuera %d,%d,%d)"):format(outdoor.R * 255, outdoor.G * 255, outdoor.B * 255))
check(night.Contrast >= 0.15 and night.Saturation >= 0, ("de noche hay contraste y las luces cálidas no se apagan (contraste %.2f, saturación %.2f)"):format(night.Contrast, night.Saturation))
check(night.Exposure > 0.15, "de noche la exposición compensa: se puede jugar")
check(night.Tint.B > night.Tint.R and golden.Tint.R > golden.Tint.B + 0.15, "noche fría (tinte azul) y hora dorada cálida")
check(golden.Saturation > noon.Saturation and golden.Rays > noon.Rays, "la hora dorada tiene más color y rayos de sol que el mediodía")
check(night.Rays == 0 and night.Glare == 0, "de noche, sin rayos de sol ni deslumbre")
check(night.Threshold < noon.Threshold and night.Bloom > noon.Bloom, "de noche el resplandor (farolas, ventanas) se nota más; de día es sutil")
check(noon.Bloom <= 0.35, ("resplandor sutil de día (%.2f)"):format(noon.Bloom))

---------------------------------------------------------------------
print("El tiempo encima de la luz")
---------------------------------------------------------------------
local W = Seasons.Weather
local clearNoon = DayGrade.weather(noon, W.Despejado, Seasons.Info.Verano, 0, 0)
local rainNoon = DayGrade.weather(noon, W.Lluvia, Seasons.Info.Verano, 0, 1)
check(rainNoon.Saturation < clearNoon.Saturation - 0.1, "lluvia: colores apagados")
check(rainNoon.Tint.B - rainNoon.Tint.R > clearNoon.Tint.B - clearNoon.Tint.R, "lluvia: imagen más fría")
check(rainNoon.Rays < clearNoon.Rays * 0.3 and rainNoon.Glare <= clearNoon.Glare, "cielo tapado: sin rayos de sol ni deslumbre")
check(rainNoon.Haze > clearNoon.Haze and rainNoon.Density > clearNoon.Density, "lluvia: más bruma")
check(rainNoon.EnvSpecular >= clearNoon.EnvSpecular and DayGrade.weather(night, W.Lluvia, nil, 0, 1).EnvSpecular > night.EnvSpecular, "suelo mojado: el entorno se refleja más")
local rainNight = DayGrade.weather(night, W.Lluvia, nil, 0, 1)
check(rainNight.Bloom > DayGrade.weather(night, W.Despejado, nil, 0, 0).Bloom, "de noche con el suelo mojado las luces resplandecen más")
local fog = DayGrade.weather(noon, W.Niebla, nil, 0, 0)
check(fog.Haze > clearNoon.Haze + 1 and fog.Density > clearNoon.Density + 0.2, "niebla: bruma espesa")
check(DayGrade.weather(noon, W.Tormenta, nil, 1, 1).Brightness > rainNoon.Brightness, "tormenta: el relámpago ilumina")
-- El asfalto mojado brilla y el seco no (lo que hace WetWorld con cada superficie)
local _, dryShine = Wetness.surface(Enum.Material.Asphalt, 0, 0, true)
local _, wetShine = Wetness.surface(Enum.Material.Asphalt, Wetness.level(W.Lluvia.Rain), 0, true)
check(dryShine == 0 and wetShine > 0.2 and W.Lluvia.Wet and W.Tormenta.Wet and not W.Despejado.Wet, ("calzada: seca sin brillo, con lluvia mojada y con reflejos (%.2f)"):format(wetShine))
-- El tiempo también cambia sin saltos a lo largo del día
local wWorst = 0
local wPrev = DayGrade.weather(DayGrade.sample(0), W.Lluvia, nil, 0, 1)
for i = 1, math.floor(24 / STEP) do
	local k = DayGrade.weather(DayGrade.sample(i * STEP), W.Lluvia, nil, 0, 1)
	for name, value in k do
		local scale = if typeof(value) == "Color3" then 1 else math.max(0.5, math.abs(value))
		wWorst = math.max(wWorst, delta(wPrev[name], value) / scale)
	end
	wPrev = k
end
check(wWorst < 0.06, ("con lluvia, también sin saltos (%.3f)"):format(wWorst))

---------------------------------------------------------------------
print("Niveles gráficos (shared/Graphics)")
---------------------------------------------------------------------
local T = Graphics.Tiers
check(T.Low.LampLights < T.Medium.LampLights and T.Medium.LampLights < T.High.LampLights, ("farolas con luz: %d / %d / %d"):format(T.Low.LampLights, T.Medium.LampLights, T.High.LampLights))
check(T.Low.ShadowLights == 0 and T.Medium.ShadowLights < T.High.ShadowLights, ("luces con sombra: %d / %d / %d"):format(T.Low.ShadowLights, T.Medium.ShadowLights, T.High.ShadowLights))
check(not T.Low.GlobalShadows and not T.Low.DepthOfField and not T.Low.SunRays and not T.Low.SignGlow, "Bajo: sin sombras del sol, desenfoque, rayos de sol ni carteles brillantes")
check(T.Low.Puddles < T.Medium.Puddles and T.Medium.Puddles <= T.High.Puddles and T.Low.WetRadius < T.High.WetRadius, "Bajo: menos charcos y menos suelo mojado alrededor")
check(not T.Medium.DepthOfField and T.High.DepthOfField and T.Medium.GlobalShadows, "Medio: sombras del sol sí, desenfoque solo en las cinemáticas; Alto: todo")
check(T.High.LampLights <= 48 and T.High.ShadowLights <= 8, "Alto: presupuestos con tope (no todas las farolas a la vez)")
check(Graphics.detect({ Mobile = true }) == "Medium" and Graphics.detect({ Mobile = false }) == "High", "al entrar: móvil Medio, ordenador Alto")
check(Graphics.detect({ Mobile = false, Quality = 2 }) == "Low" and Graphics.detect({ Mobile = true, Quality = 10 }) == "Medium", "con la calidad de Roblox baja, Bajo; un móvil no empieza en Alto")
check(Graphics.nextChoice("Auto") == "Low" and Graphics.nextChoice("High") == "Auto", "el botón del menú pasa Auto → Bajo → Medio → Alto → Auto")

-- Modo Auto con fps de mentira
local state = Graphics.newAuto("Medium")
local changes = {}
local function run(fps: number, seconds: number)
	for _ = 1, math.floor(seconds * fps) do
		local t = Graphics.autoStep(state, 1 / fps)
		if t then
			table.insert(changes, t)
		end
	end
end
run(60, 5)
check(#changes == 0, "con fps normales no cambia")
run(20, 10)
check(state.Tier == "Low", ("con 20 fps baja a Bajo (%s)"):format(table.concat(changes, ",")))
run(60, 40)
check(state.Tier == "Low", "y no vuelve enseguida al nivel que fue lento")
run(60, Graphics.Fps.RetrySeconds)
check(state.Tier ~= "Low", ("pasados unos minutos con fps de sobra, vuelve a probar (%s)"):format(state.Tier))
run(25, 2) -- un tirón corto (2 s) no baja
local before = state.Tier
run(60, 1)
check(state.Tier == before, "un tirón corto no cambia de nivel")

---------------------------------------------------------------------
print("Presupuesto de farolas (Controllers/NearShadows)")
---------------------------------------------------------------------
-- Luces y bombillas de mentira (lo justo de una instancia de Roblox)
local function signal()
	return { Connect = function() end }
end
local function fakeInstance(props: { [string]: any }, class: string, isa: { [string]: boolean }): any
	local self = props
	self.ClassName = class
	self.IsA = function(_, c)
		return c == class or isa[c] == true
	end
	self.HasTag = function(_, tag)
		return (props.__tags or {})[tag] == true
	end
	self.GetPropertyChangedSignal = function()
		return signal()
	end
	self.AncestryChanged = signal()
	return self
end
local tierName = "High"
local PerfMock = {
	tier = function()
		return Graphics.tier(tierName)
	end,
	onTier = function() end,
}
local clock = 23.6
local lightingMock = setmetatable({}, {
	__index = function(_, k)
		if k == "ClockTime" then
			return clock
		end
		return nil
	end,
})
local CONFIG = { __module = "Config" }
local GRAPHICS = { __module = "Graphics" }
local PERF = { __module = "Perf" }
local NearShadows: any
local function nearEnv(extra: { [string]: any }): { [string]: any }
	local env = {
	script = { Parent = { Parent = { UI = { Perf = PERF } } } },
	game = {
		GetService = function(_, name)
			if name == "Lighting" then
				return lightingMock
			end
			return { Shared = { Config = CONFIG, Graphics = GRAPHICS } }
		end,
	},
	require = function(m)
		if m == CONFIG then
			return load("src/shared/Config.luau")
		elseif m == GRAPHICS then
			return Graphics
		elseif m == PERF then
			return PerfMock
		end
		error("require inesperado")
	end,
	workspace = { GetDescendants = function() return {} end, DescendantAdded = signal() },
}
	for k, v in extra do
		env[k] = v
	end
	return env
end

-- Las farolas: del mapa construido (si se pasa) o una cuadrícula de calles cada 40 studs (la mitad
-- sin luz, como las construye Kit/Props: NearShadows les pone la suya)
local lampSpots: { { Position: Vector3, HasLight: boolean } } = {}
local placePath = process.args[1]
local place: any = nil
if placePath then
	place = roblox.deserializePlace(fs.readFile(placePath))
	for _, d in place:GetService("Workspace"):GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("StreetLamp") then
			table.insert(lampSpots, { Position = d.CFrame.Position, HasLight = d:FindFirstChildWhichIsA("Light") ~= nil }) -- (Lune no da .Position)
		end
	end
else
	local i = 0
	for x = -800, 800, 40 do
		for z = -800, 800, 80 do
			i += 1
			table.insert(lampSpots, { Position = Vector3.new(x, 14, z), HasLight = i % 2 == 0 })
		end
	end
end
local lights = {}
local function newLight(class: string, bulb: any): any
	local light = fakeInstance({ Parent = bulb, Enabled = true, Shadows = false, Range = 46, Brightness = 3, Angle = 120, Color = Color3.new(1, 1, 1) }, class, { Light = true })
	bulb.__light = light
	table.insert(lights, light)
	return light
end
NearShadows = load("src/client/Controllers/NearShadows.luau", nearEnv({
	Instance = {
		new = function(class)
			local light = fakeInstance({ Enabled = true, Shadows = false, Range = 8, Brightness = 1, Angle = 90, Color = Color3.new(1, 1, 1) }, class, { Light = true })
			-- (al ponerle Parent, se apunta en la bombilla)
			return setmetatable({}, {
				__index = light,
				__newindex = function(_, k, v)
					light[k] = v
					if k == "Parent" and v then
						v.__light = light
						table.insert(lights, light)
					end
				end,
			})
		end,
	},
}))
local withLight = 0
for _, spot in lampSpots do
	local bulb = fakeInstance({ Parent = {}, Position = spot.Position, Material = Enum.Material.Neon, Transparency = 0, Color = Color3.new(1, 1, 1), __tags = { StreetLamp = true } }, "Part", { BasePart = true })
	bulb.FindFirstChildWhichIsA = function(self)
		return self.__light
	end
	if spot.HasLight then
		withLight += 1
		NearShadows.add(newLight("SpotLight", bulb))
	end
	NearShadows.fillLamp(bulb)
end
check(#lights == #lampSpots and withLight < #lampSpots, ("cada farola tiene su luz (%d de %d la traían; el resto se la pone el cliente)"):format(withLight, #lampSpots))
-- Una luz de techo cerca (no es farola: solo puede llevar sombra)
local ceiling = fakeInstance({ Parent = fakeInstance({ Position = Vector3.new(5, 8, 5) }, "Part", { BasePart = true }), Enabled = true, Shadows = false }, "PointLight", { Light = true })
NearShadows.add(ceiling)

-- La cámara en medio de la ciudad (el centro del mapa o el de la cuadrícula)
local eye = Vector3.new(0, 20, 0)
if #lampSpots > 0 then
	local sum = Vector3.zero
	for _, p in lampSpots do
		sum += p.Position
	end
	eye = sum / #lampSpots + Vector3.new(0, 6, 0)
	-- (al lado de la farola más cercana al centro: rodeado de calles)
	local best, bestD = eye, math.huge
	for _, p in lampSpots do
		local d = (p.Position - eye).Magnitude
		if d < bestD then
			best, bestD = p.Position, d
		end
	end
	eye = best + Vector3.new(4, 4, 4)
end

local function count(): (number, number, number)
	local on, near, shadows = 0, 0, 0
	for _, light in lights do
		if light.Enabled then
			on += 1
			if (light.Parent.Position - eye).Magnitude < 300 then
				near += 1
			end
		end
		if light.Shadows then
			shadows += 1
		end
	end
	if ceiling.Shadows then
		shadows += 1
	end
	return on, near, shadows
end

for _, name in Graphics.Order do
	tierName = name
	local lit = NearShadows.step(eye)
	local on, near, shadows = count()
	local tier = Graphics.tier(name)
	check(on <= tier.LampLights and near == on and on == lit and on > 0, ("%s de noche: %d farolas con luz (tope %d) de %d, todas cerca de la cámara"):format(name, on, tier.LampLights, #lights))
	check(shadows <= tier.ShadowLights, ("%s: %d luces con sombra (tope %d)"):format(name, shadows, tier.ShadowLights))
end
-- Las farolas reciben su color (LED o sodio) y el foco hacia abajo
local styled, sodium = 0, 0
for _, light in lights do
	if light.Range == 50 and light.Angle == 125 then
		styled += 1
	end
	if light.Color.B < 0.5 then
		sodium += 1
	end
end
check(styled == #lights and sodium > 0 and sodium < #lights * 0.5, ("farolas con su luz: %d de sodio (naranja) y el resto LED cálido"):format(sodium))
-- De día (bombillas apagadas por el servidor) ninguna luz
for _, light in lights do
	light.Parent.Material = Enum.Material.SmoothPlastic
end
clock = 13
tierName = "High"
NearShadows.step(eye)
local onDay = count()
check(onDay == 0, ("de día ninguna farola da luz (%d)"):format(onDay))

---------------------------------------------------------------------
print("Acabados (Kit/Polish.surfaces)")
---------------------------------------------------------------------
local Polish = load("src/server/World/Kit/Polish.luau")
local folder = roblox.Instance.new("Folder")
local function glass(name: string, transparency: number, reflectance: number): any
	local p = roblox.Instance.new("Part")
	p.Name = name
	p.Material = Enum.Material.Glass
	p.Transparency = transparency
	p.Reflectance = reflectance
	p.Parent = folder
	return p
end
local windows = glass("Windows", 0, 0)
local shop = glass("ShopGlass", 0.25, 0)
local mirror = glass("Mirror", 0, 0.5)
local clear = glass("Windows", 0.9, 0)
local n = Polish.surfaces(folder)
check(n == 2 and windows.Reflectance > 0.05 and shop.Reflectance > 0.05, "el cristal de fachadas y escaparates refleja un poco")
check(mirror.Reflectance == 0.5 and clear.Reflectance == 0, "lo que ya tenía su reflejo o es casi transparente no cambia")
check(folder:GetAttribute("SurfaceVersion") == Polish.SurfaceVersion, "la ciudad apunta la versión de los acabados")
if place then
	local glassy, total = 0, 0
	for _, d in place:GetService("Workspace"):GetDescendants() do
		if d:IsA("BasePart") and d.Material == Enum.Material.Glass and Polish.FacadeGlass[d.Name] and d.Transparency < 0.6 then
			total += 1
			if d.Reflectance > 0.05 then
				glassy += 1
			end
		end
	end
	check(total > 0 and glassy / total > 0.95, ("mapa: %d de %d cristales de fachada con reflejo"):format(glassy, total))
	check(place:GetService("Lighting").Technology == Enum.Technology.Future, "mapa: iluminación Future")
end

---------------------------------------------------------------------
print("Gráficos fase 1: césped 3D, árboles, cielo, suelo mojado y horizonte")
---------------------------------------------------------------------
check(not T.Low.GrassBlades and not T.Medium.GrassBlades and not T.High.GrassBlades, "sin briznas de césped 3D en ningún nivel (asomaban por calles y aceras)")
check(not T.Low.LeafDetail and T.Medium.LeafDetail and T.High.LeafDetail, "racimos de relleno de los árboles en Medio y Alto; en Bajo se esconden")
check(not T.Low.WetGloss and T.Medium.WetGloss and T.High.WetGloss and not T.Low.FarRange and T.High.FarRange, "suelo mojado que refleja y sierra lejana en Medio y Alto")
local detail = fs.readFile("src/client/Controllers/MaterialDetail.luau")
check(detail:find("Decoration", 1, true) and detail:find("LeafDetail", 1, true) and detail:find("LocalTransparencyModifier", 1, true) and detail:find("WetRoughnessId", 1, true) and detail:find("Perf.onTier", 1, true), "el cliente (MaterialDetail) pone el césped 3D, esconde el relleno de los árboles y cambia la rugosidad con la lluvia según el nivel")
local terrainSrc = fs.readFile("src/server/World/TerrainBuilder.luau")
check(terrainSrc:find("SetMaterialColor(Enum.Material.Grass", 1, true) and terrainSrc:find("SetMaterialColor(Enum.Material.LeafyGrass", 1, true), "el césped del terreno tiene su verde (y la hierba alta otro)")
-- Sombras más suaves de día y hora dorada cinematográfica, sin pasarse
local shadowsOk, gradeOk = true, true
for h = 7.5, 17.6, 0.1 do
	local k = DayGrade.sample(h)
	if k.Shadow < 0.17 or k.Shadow > 0.26 then
		shadowsOk = false
	end
end
for h = 0, 23.9, 0.1 do
	local k = DayGrade.sample(h)
	if k.Saturation > 0.3 or k.Saturation < -0.1 or k.Contrast > 0.25 or k.Exposure > 0.4 then
		gradeOk = false
	end
end
local proj = L["$properties"].ShadowSoftness or 0
check(shadowsOk and proj >= 0.18 and proj <= 0.25, ("sombras del sol algo suaves de día (0,17-0,26; archivo %.2f)"):format(proj))
check(gradeOk, "sin filtros exagerados: saturación ≤ 0,3, contraste ≤ 0,25 y exposición contenida a todas horas")
check(golden.Outdoor.R > golden.Outdoor.B * 1.5 and golden.CloudColor.B < golden.CloudColor.R * 0.75 and golden.Glare > noon.Glare, "hora dorada: luz de fuera y nubes cálidas, con deslumbre del sol")
check(DayGrade.sample(13).CloudDensity >= 0.35 and DayGrade.sample(13).Cover >= 0.4, "nubes con cuerpo de día (densidad y cobertura)")
check(rainNoon.CloudDensity > clearNoon.CloudDensity + 0.15 and DayGrade.weather(noon, W.Tormenta, nil, 0, 1).CloudDensity > rainNoon.CloudDensity, "con lluvia las nubes se hacen gruesas; con tormenta, más")
local calm, storm = DayGrade.wind("Despejado", 12), DayGrade.wind("Tormenta", 12)
check(calm.Magnitude > 2 and storm.Magnitude > calm.Magnitude * 2.5 and calm.Y == 0, ("viento para las nubes: %.0f en calma, %.0f con tormenta"):format(calm.Magnitude, storm.Magnitude))
check(fs.readFile("src/client/Controllers/DayLight.luau"):find("GlobalWind", 1, true) ~= nil, "DayLight mueve las nubes con el viento (GlobalWind)")
-- Rugosidad mojada (shared/Textures)
local Textures = load("src/shared/Textures.luau")
local ids = { Asfalto_color = "rbxassetid://1", Asfalto_roughness = "rbxassetid://2", Asfalto_wet = "rbxassetid://3", Ladrillo_color = "rbxassetid://4", Ladrillo_wet = "rbxassetid://5" }
check(Textures.wetMap("Asfalto", ids) == "rbxassetid://3" and Textures.wetMap("Asfalto", { Asfalto_color = "rbxassetid://1" }) == nil and Textures.wetMap("Ladrillo", ids) == nil, "rugosidad mojada solo en la calle (asfalto, acera, bordillo) y solo si está subida")
check(Textures.roughnessFor("d", "w", 1, true) == "w" and Textures.roughnessFor("d", "w", 0.1, true) == "d" and Textures.roughnessFor("d", "w", 1, false) == "d" and Textures.roughnessFor("d", nil, 1, true) == "d", "con lluvia se pone la mojada; seco, en Bajo o sin id, la de siempre")
for set in Textures.WetSets do
	check(fs.isFile(("textures/%s/wet.png"):format(set)), ("textures/%s/wet.png existe (python3 scripts/textures/gen.py --wet)"):format(set))
end
check(fs.readFile("src/server/World/Kit/MaterialLook.luau"):find("WetRoughnessId", 1, true) ~= nil, "el servidor apunta en cada material su rugosidad seca y mojada")
local wetFloor = select(2, Wetness.surface(Enum.Material.Asphalt, 1, 0, true))
check(wetFloor >= 0.35 and wetFloor <= 0.45, ("asfalto empapado: reflejo de espejo oscuro (%.2f)"):format(wetFloor))

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Gráficos e iluminación correctos")
