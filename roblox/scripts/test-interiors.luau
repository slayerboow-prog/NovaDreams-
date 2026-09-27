-- Prueba de los muebles de los interiores FUERA de Roblox, con Lune (funciones puras):
--   * neveras (shared/Fridge) y edificios de varias plantas (shared/Floors: escalera, puertas)
--   * reglas de uso (shared/Interact): qué se puede hacer en tu casa, en la de otro, en las de los
--     vecinos y en las tiendas; picar de la nevera con límite; textos de los carteles; canales
--   * números fijos por edificio (World/Furniture.rng): la misma casa siempre igual
--   * posturas al usar los muebles (Controllers/UseAnim): sin tirones, mezcla suave, y en un
--     personaje R15 las manos van donde deben (teclado, piano, grifo, cabeza en la ducha…) y
--     tumbado el cuerpo queda recto
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-interiors.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

local function load(path: string, extra: { [string]: any }?)
	local env = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Color3 = roblox.Color3, Enum = roblox.Enum }, { __index = getfenv(1) })
	for k, v in extra or {} do
		env[k] = v
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local Interact = load("src/shared/Interact.luau")
local UseAnim = load("src/client/Controllers/UseAnim.luau")
local Furniture = load("src/server/World/Furniture.luau", {
	script = { Parent = { Builder = "Builder" } },
	require = function()
		return {} -- (Builder: aquí solo se prueban los números)
	end,
})

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
print("Reglas de uso")
local USES = { "Sit", "Bed", "TV", "Light", "Fridge", "Tap", "Shower", "Door", "Wardrobe", "Computer", "Piano", "Window" }
local allOk = true
for _, use in USES do
	local info = Interact.Uses[use]
	if not info or info.Distance > 9 or info.Object == "" or info.Action == "" then
		allOk = false
	end
end
check(allOk, "cada mueble tiene su cartel, que solo sale de cerca (9 studs o menos)")
local ownerAll, publicAll = true, true
for _, use in USES do
	ownerAll = ownerAll and Interact.allowed(use, "Owner") == true and Interact.allowed(use, "Guest") == true
	publicAll = publicAll and Interact.allowed(use, "Public") == true
end
check(ownerAll, "en tu casa (y si estás invitado) se puede usar todo")
check(publicAll, "fuera de las viviendas se puede usar todo")
local harmless = true
for _, use in { "Sit", "Light", "Door", "Window", "TV" } do
	harmless = harmless and Interact.allowed(use, "Stranger") == true
end
check(harmless, "en casa ajena: sentarse, luces, puertas, tele y mirar por la ventana")
local blocked = true
for _, use in { "Bed", "Fridge", "Shower", "Tap", "Wardrobe", "Computer", "Piano" } do
	local ok, why = Interact.allowed(use, "Stranger")
	blocked = blocked and ok == false and type(why) == "string"
end
check(blocked, "en casa ajena no se duerme, ni se abre la nevera, ni la ducha… (y dice por qué)")
check(Interact.allowed("Bed", "Neighbor") == true and Interact.allowed("Shower", "Neighbor") == false and Interact.allowed("Fridge", "Neighbor") == false, "en casa de los vecinos te puedes tumbar, pero no ducharte ni abrir su nevera")
check(Interact.canSleep("Owner") and Interact.canSleep("Guest") and not Interact.canSleep("Neighbor") and not Interact.canSleep("ForSale") and not Interact.canSleep("Public"), "solo se duerme (energía) en tu casa o invitado")
check(Interact.fridgeMode("Owner", "Casa") == "Stock" and Interact.fridgeMode("Guest", "Piso") == "Stock", "la nevera de casa tiene lo que hayas guardado")
check(Interact.fridgeMode("Public", "Local") == "Pay" and Interact.fridgeMode("Public", "Ocio") == "Pay", "en las tiendas y bares se paga")
check(Interact.fridgeMode("Public", "Oficina") == nil and Interact.fridgeMode("ForSale", "Casa") == nil and Interact.fridgeMode("Stranger", "Casa") == nil, "en las demás, solo se mira")
-- Picar algo en casa: sin límite, solo un momento entre bocado y bocado
local okFirst = Interact.canSnack(nil, 1000)
local okSoon, waitSoon = Interact.canSnack(1000, 1001)
check(okFirst and not okSoon and waitSoon == Interact.Snack.Cooldown - 1 and Interact.Snack.Cooldown <= 5, "entre bocado y bocado, solo un momento (lo que se tarda en comer)")
local endless, t = true, 1000
for _ = 1, 200 do
	t += Interact.Snack.Cooldown
	endless = endless and Interact.canSnack(t - Interact.Snack.Cooldown, t) == true
end
check(endless, "en casa se come sin límite (200 bocados seguidos)")
check(Interact.familyFridge("Casa_3", "Casa_3") and not Interact.familyFridge("Casa_3", "Casa_4") and not Interact.familyFridge("Casa_3", nil) and not Interact.familyFridge(nil, nil), "la nevera de la casa familiar es de su familia")
-- Textos y canales
check(Interact.actionText("Light", true) == "Apagar la luz" and Interact.actionText("Light", false) == "Encender la luz", "el interruptor dice lo que va a hacer")
check(Interact.actionText("TV", true) == "Apagar la tele" and Interact.actionText("TV", false) == "Encender la tele", "la tele también")
check(Interact.actionText("Door", true) == "Cerrar la puerta" and Interact.actionText("Door", false) == "Abrir la puerta", "y la puerta")
check(Interact.nextChannel(nil) == 1 and Interact.nextChannel(#Interact.Channels) == 1 and Interact.nextChannel(2) == 3, "los canales van dando la vuelta")
local channelsOk = true
for _, channel in Interact.Channels do
	channelsOk = channelsOk and type(channel.Name) == "string" and #channel.Colors >= 2 and channel.Speed > 0
end
check(channelsOk and #Interact.Melody >= 8, "cada canal tiene nombre y colores; el piano, su melodía")

---------------------------------------------------------------------
print("Neveras: gratis de pequeño, desde la universidad lo que compres")
local Fridge = load("src/shared/Fridge.luau")
check(Fridge.freeAtFamily("Bebe") and Fridge.freeAtFamily("Nino") and Fridge.freeAtFamily("Adolescente"), "en la etapa del colegio, gratis en casa de tus padres")
check(not Fridge.freeAtFamily("AdultoJoven") and not Fridge.freeAtFamily("Adulto") and not Fridge.freeAtFamily("Mayor") and not Fridge.freeAtFamily(nil), "desde la universidad, no")
local stock = {}
check(Fridge.store(stock, "Pan", 3) == 3 and stock.Pan == 3 and Fridge.total(stock) == 3, "guardar comida en la nevera")
check(Fridge.take(stock, "Pan") and stock.Pan == 2, "comer gasta uno")
check(not Fridge.take(stock, "Leche"), "no se puede coger lo que no hay")
check(Fridge.store(stock, "Leche", 100) == Fridge.MaxStock - 2 and Fridge.total(stock) == Fridge.MaxStock, "no cabe más de lo que cabe")
check(Fridge.store(stock, "Pan", 1) == 0, "llena, ya no entra nada")
Fridge.take(stock, "Pan")
Fridge.take(stock, "Pan")
check(stock.Pan == nil and #Fridge.list(stock) == 1, "al acabarse algo, desaparece de la lista")
check(Fridge.isFood({ Kind = "Food", Hunger = 10 }) and not Fridge.isFood({ Kind = "Thing" }) and not Fridge.isFood(nil), "solo se guarda comida")

---------------------------------------------------------------------
print("Edificios de varias plantas (shared/Floors)")
local Floors = load("src/shared/Floors.luau")
check(Floors.isTower("Piso", 5) and not Floors.isTower(nil, 5) and not Floors.isTower("Piso", 1), "se sube por dentro si tiene plantas de arriba")
local rise, total = true, 0
local last = 0
for i, s in Floors.steps() do
	if s.Y - last > 1 or s.Y <= last then
		rise = false
	end
	last = s.Y
	total = i
end
check(rise and math.abs(last - Floors.Height) < 1e-6 and total == Floors.StepsPerFlight * 2, "escalera: escalones de ≤ 1 stud hasta la planta de arriba (dos tramos)")
local okUnits, unique = true, true
for k = 1, 200 do
	local key = "Portal_" .. k .. "_7"
	local seen = {}
	for f = 1, 8 do
		local units = Floors.units(key, "Portal", "Piso", f)
		if #units < 3 or #units > 6 then
			okUnits = false
		end
		for _, u in units do
			if seen[u.Id] or seen[u.Label] then
				unique = false
			end
			seen[u.Id], seen[u.Label] = true, true
			local floor, letter = Floors.parseUnit(u.Id)
			if floor ~= f or letter ~= u.Letter or u.Label ~= ("%dº%s"):format(f, u.Letter) then
				unique = false
			end
		end
	end
end
check(okUnits, "de 3 a 6 viviendas por planta")
check(unique, "cada puerta con su nombre (3ºA, 3ºB…) y su clave, que se lee al revés")
check(Floors.unitId(3, "A") == "3" and Floors.unitId(3, "B") == "3B" and Floors.unitId(0, nil) == "0", "la A de cada planta es la vivienda de antes (una por planta)")
check(#Floors.units("X", "Portal", "Piso", 0) == 0 and #Floors.units("X", "Local", "Piso", 0) == 1 and Floors.units("X", "Local", "Piso", 0)[1].Ground, "en la planta baja: el portal (o la tienda de la calle)")
check(string.match(Floors.units("X", "OficinaLobby", "Oficina", 3)[1].Label, "^Oficina 301$") ~= nil and Floors.units("R", "Portal", "Dorm", 2)[1].Kind == "Dorm", "oficinas numeradas y habitaciones de residencia")
check(Floors.floorAt(-1, 10) == 0 and Floors.floorAt(3, 10) == 0 and Floors.floorAt(Floors.Height * 4 + 3, 10) == 4 and Floors.floorAt(1e4, 10) == 10, "planta según la altura")
local build, keep = Floors.wanted({ 6 }, 11)
local nb = 0
for _ in build do
	nb += 1
end
check(nb == 5 and build[4] and build[8] and not build[3] and keep[3] and keep[9] and not keep[2], "se montan las plantas a ±2 y se quitan las que quedan a más de ±3")
check(Floors.isOpen(10) and not Floors.isOpen(22) and not Floors.isOpen(6), "las oficinas abren de 8:00 a 20:00")

---------------------------------------------------------------------
print("Números fijos por edificio")
local a, b, c = Furniture.rng("Casa_10_20:0"), Furniture.rng("Casa_10_20:0"), Furniture.rng("Casa_11_20:0")
local same, differs, inRange = true, false, true
local seenLow, seenHigh = false, false
for _ = 1, 500 do
	local x, y, z = a.next(), b.next(), c.next()
	same = same and x == y
	differs = differs or x ~= z
	inRange = inRange and x >= 0 and x < 1
	local n = a.int(1, 4)
	b.int(1, 4)
	inRange = inRange and n >= 1 and n <= 4 and n == math.floor(n)
	seenLow = seenLow or n == 1
	seenHigh = seenHigh or n == 4
	local r = a.range(2, 3)
	b.range(2, 3)
	inRange = inRange and r >= 2 and r <= 3
end
check(same, "la misma semilla da siempre los mismos números")
check(differs, "otra semilla, otros números")
check(inRange and seenLow and seenHigh, "los números salen en su rango (incluidos los extremos)")
check(a.pick({ "x" }) == "x" and Furniture.hash("abc") == Furniture.hash("abc") and Furniture.hash("abc") ~= Furniture.hash("abd"), "elegir de una lista y el número de un texto")

---------------------------------------------------------------------
print("Posturas: suaves y sin tirones")
check(UseAnim.ease(0) == 0 and UseAnim.ease(1) == 1 and math.abs(UseAnim.ease(0.5) - 0.5) < 1e-9, "la curva de mezcla va de 0 a 1")
check(UseAnim.ease(0.01) < 1e-4 and 1 - UseAnim.ease(0.99) < 1e-4, "empieza y acaba despacio (sin golpe)")
local mono = true
for i = 1, 100 do
	mono = mono and UseAnim.ease(i / 100) >= UseAnim.ease((i - 1) / 100)
end
check(mono, "y siempre sube")
local JOINTS = { "Root", "Waist", "Neck", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist", "RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle" }
local function transforms(name: string, u: number, w: number?, sleeping: boolean?)
	local pose = UseAnim.pose(name, u, 1.3, sleeping)
	local out = {}
	for _, joint in JOINTS do
		out[joint] = UseAnim.apply(CFrame.identity, pose, joint, w or 1)
	end
	return out
end
local function angleBetween(p: CFrame, q: CFrame): number
	local _, angle = (p:Inverse() * q):ToAxisAngle()
	return math.abs(angle)
end
check(#UseAnim.Names == 9, "nueve posturas: " .. table.concat(UseAnim.Names, ", "))
for _, name in UseAnim.Names do
	local finite, smooth = true, true
	local last = nil
	for step = 0, 12 * 60 do
		local t = transforms(name, step / 60, 1, name == "Lie" and step > 360)
		for _, joint in JOINTS do
			local cf = t[joint]
			local x, y, z = cf:ToEulerAnglesXYZ()
			if x ~= x or y ~= y or z ~= z then
				finite = false
			end
			if last and step ~= 361 and angleBetween(last[joint], cf) > 0.12 then
				smooth = false
			end
		end
		last = t
	end
	check(finite and smooth, name .. ": sin tirones de un frame a otro")
end
-- Mezcla: con peso 0 no cambia nada; con peso 1, la postura
local pose = UseAnim.pose("Type", 0.5, 0)
local base = CFrame.Angles(0.3, 0.1, -0.2)
check(UseAnim.apply(base, pose, "RightShoulder", 0) == base, "con peso 0 queda la animación")
check(angleBetween(UseAnim.apply(base, pose, "RightShoulder", 1), (pose.Set :: any).RightShoulder) < 1e-6, "con peso 1, la postura")
-- Entrar y salir: el peso sube y baja poco a poco
local w, frames = 0, 0
while w < 1 and frames < 1000 do
	w = UseAnim.fade(w, true, 1 / 60)
	frames += 1
end
check(math.abs(frames / 60 - UseAnim.BlendIn) < 0.05, ("entra en %.2f s"):format(frames / 60))
local out = 0
while w > 0 and out < 1000 do
	w = UseAnim.fade(w, false, 1 / 60)
	out += 1
end
check(math.abs(out / 60 - UseAnim.BlendOut) < 0.05, ("sale en %.2f s"):format(out / 60))
local jumps = false
local prev = nil
local weight = 0
for step = 1, 120 do
	weight = UseAnim.fade(weight, step < 60, 1 / 60)
	local cf = UseAnim.apply(base, pose, "RightShoulder", UseAnim.ease(weight))
	if prev and angleBetween(prev, cf) > 0.08 then
		jumps = true
	end
	prev = cf
end
check(not jumps, "al sentarse al ordenador y al levantarse, el brazo va y vuelve sin saltos")

---------------------------------------------------------------------
print("Posturas en un personaje R15")
local function rig()
	local function v(x, y, z)
		return Vector3.new(x, y, z)
	end
	local function c(x, y, z)
		return CFrame.new(x, y, z)
	end
	return {
		Sizes = {
			LowerTorso = v(2, 0.4, 1), UpperTorso = v(2, 1.6, 1), Head = v(1.2, 1.2, 1.2),
			RightUpperArm = v(1, 1.169, 1), RightLowerArm = v(1, 1.052, 1), RightHand = v(1, 0.3, 1),
			LeftUpperArm = v(1, 1.169, 1), LeftLowerArm = v(1, 1.052, 1), LeftHand = v(1, 0.3, 1),
			RightUpperLeg = v(1, 1.217, 1), RightLowerLeg = v(1, 1.193, 1), RightFoot = v(1, 0.3, 1),
			LeftUpperLeg = v(1, 1.217, 1), LeftLowerLeg = v(1, 1.193, 1), LeftFoot = v(1, 0.3, 1),
		},
		Joints = {
			Root = { Part0 = "HumanoidRootPart", Part1 = "LowerTorso", C0 = c(0, 0, 0), C1 = c(0, -0.2, 0) },
			Waist = { Part0 = "LowerTorso", Part1 = "UpperTorso", C0 = c(0, 0.2, 0), C1 = c(0, -0.8, 0) },
			Neck = { Part0 = "UpperTorso", Part1 = "Head", C0 = c(0, 0.8, 0), C1 = c(0, -0.6, 0) },
			RightShoulder = { Part0 = "UpperTorso", Part1 = "RightUpperArm", C0 = c(1, 0.563, 0), C1 = c(-0.5, 0.392, 0) },
			LeftShoulder = { Part0 = "UpperTorso", Part1 = "LeftUpperArm", C0 = c(-1, 0.563, 0), C1 = c(0.5, 0.392, 0) },
			RightElbow = { Part0 = "RightUpperArm", Part1 = "RightLowerArm", C0 = c(0, -0.334, 0), C1 = c(0, 0.259, 0) },
			LeftElbow = { Part0 = "LeftUpperArm", Part1 = "LeftLowerArm", C0 = c(0, -0.334, 0), C1 = c(0, 0.259, 0) },
			RightWrist = { Part0 = "RightLowerArm", Part1 = "RightHand", C0 = c(0, -0.501, 0), C1 = c(0, 0.125, 0) },
			LeftWrist = { Part0 = "LeftLowerArm", Part1 = "LeftHand", C0 = c(0, -0.501, 0), C1 = c(0, 0.125, 0) },
			RightHip = { Part0 = "LowerTorso", Part1 = "RightUpperLeg", C0 = c(0.5, -0.2, 0), C1 = c(0, 0.42, 0) },
			LeftHip = { Part0 = "LowerTorso", Part1 = "LeftUpperLeg", C0 = c(-0.5, -0.2, 0), C1 = c(0, 0.42, 0) },
			RightKnee = { Part0 = "RightUpperLeg", Part1 = "RightLowerLeg", C0 = c(0, -0.4, 0), C1 = c(0, 0.35, 0) },
			LeftKnee = { Part0 = "LeftUpperLeg", Part1 = "LeftLowerLeg", C0 = c(0, -0.4, 0), C1 = c(0, 0.35, 0) },
			RightAnkle = { Part0 = "RightLowerLeg", Part1 = "RightFoot", C0 = c(0, -0.55, 0), C1 = c(0, 0.1, 0) },
			LeftAnkle = { Part0 = "LeftLowerLeg", Part1 = "LeftFoot", C0 = c(0, -0.55, 0), C1 = c(0, 0.1, 0) },
		},
	}
end
local shape = rig()
-- Dónde queda cada pieza (respecto a HumanoidRootPart) con esas transformaciones
local function place(t)
	local frames = { HumanoidRootPart = CFrame.new() }
	for _ = 1, 10 do
		for name, j in shape.Joints do
			if frames[j.Part0] and not frames[j.Part1] then
				frames[j.Part1] = frames[j.Part0] * j.C0 * (t[name] or CFrame.new()) * j.C1:Inverse()
			end
		end
	end
	return frames
end
local function hand(frames, side)
	return (frames[side .. "Hand"] * CFrame.new(0, -0.1, 0)).Position
end
local standing = place({})
local shoulderY = (standing.UpperTorso * CFrame.new(0, 0.56, 0)).Position.Y
local headPos = standing.Head.Position

-- Tumbado: el cuerpo recto (brazos a los lados, piernas estiradas) y la cabeza apoyada
for _, asleep in { false, true } do
	local f = place(transforms("Lie", 3, 1, asleep))
	local straight = true
	for _, part in { "LowerTorso", "UpperTorso", "RightUpperLeg", "LeftUpperLeg", "RightLowerLeg" } do
		straight = straight and f[part].UpVector:Dot(Vector3.new(0, 1, 0)) > 0.93
	end
	local flat = true
	for part, frame in f do
		if part ~= "HumanoidRootPart" then
			flat = flat and math.abs(frame.Position.Z) < 0.75 -- (todo sobre el colchón: nada se levanta)
		end
	end
	check(straight and flat, "tumbado" .. (if asleep then " (durmiendo)" else "") .. ": cuerpo recto y apoyado")
	check(f.RightFoot.Position.Y < f.LowerTorso.Position.Y - 2 and f.Head.Position.Y > f.UpperTorso.Position.Y, "tumbado: los pies abajo y la cabeza arriba (en la almohada)")
end
-- Tecleando: manos delante, a la altura del teclado
local typing = place(transforms("Type", 2))
for _, side in { "Right", "Left" } do
	local p = hand(typing, side)
	check(p.Z < -0.9 and p.Y < shoulderY - 0.6 and p.Y > -0.4, ("tecleando: la mano %s sobre el teclado (delante y abajo)"):format(if side == "Right" then "derecha" else "izquierda"))
end
-- Piano: las manos delante, sobre las teclas, y se mueven por el teclado
local xs = {}
for step = 0, 40 do
	local p = hand(place(transforms("Piano", step * 0.1)), "Right")
	table.insert(xs, p.X)
	if step == 0 then
		check(p.Z < -1.2 and p.Y < shoulderY - 0.4, "al piano: las manos sobre las teclas")
	end
end
table.sort(xs)
check(xs[#xs] - xs[1] > 0.25, ("al piano: las manos recorren el teclado (%.2f studs)"):format(xs[#xs] - xs[1]))
-- Grifo: manos delante y bajas
local tapFrames = place(transforms("Tap", 1))
check(hand(tapFrames, "Right").Z < -0.8 and hand(tapFrames, "Left").Z < -0.8 and hand(tapFrames, "Right").Y < shoulderY - 0.6, "en el grifo: las manos bajo el agua, delante")
-- Ducha: manos en la cabeza
local shower = place(transforms("Shower", 1))
local showerHead = shower.Head.Position
check(hand(shower, "Right").Y > shoulderY + 0.3 and (hand(shower, "Right") - showerHead).Magnitude < 1.7 and (hand(shower, "Left") - showerHead).Magnitude < 1.7, "en la ducha: las manos lavando el pelo")
-- Nevera: alarga la mano, se asoma, coge algo y se lo lleva a la boca
local reach = place(transforms("Fridge", 0.55))
local grab = place(transforms("Fridge", 1.7))
local eat = place(transforms("Fridge", 2.5))
check(hand(reach, "Right").Z < -1, "nevera: primero alarga la mano a la puerta")
check(hand(grab, "Left").Z < -1.2, "luego mete la otra mano")
check((hand(eat, "Left") - eat.Head.Position).Magnitude < 1.4, "y se lo lleva a la boca")
-- Ventana: manos en el alféizar y la cabeza mira a un lado y a otro
local window = place(transforms("Window", 1))
check(hand(window, "Right").Z < -0.8 and hand(window, "Right").Y < shoulderY, "en la ventana: manos apoyadas delante")
local yaws = {}
for step = 0, 30 do
	local f = place(transforms("Window", step * 0.3))
	local look = f.Head.LookVector
	table.insert(yaws, math.atan2(-look.X, -look.Z))
end
table.sort(yaws)
check(yaws[#yaws] - yaws[1] > 0.6, "y mira a un lado y a otro")
-- Sentado: las manos no atraviesan el cuerpo
local sit = place(transforms("Sit", 1))
check(math.abs(hand(sit, "Right").X) > 0.3 and hand(sit, "Right").Z < 0, "sentado: las manos en el regazo")
local _ = headPos

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
