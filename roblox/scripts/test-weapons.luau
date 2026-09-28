-- Prueba de las armas (shared/Weapons y Controllers/WeaponPose) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-weapons.luau
--
-- Comprueba las cuentas puras: dispersión, retroceso y su muelle, caída del daño y zonas del
-- cuerpo, cadencia, munición y recargas (táctica, en vacío, cartucho a cartucho), normas de compra
-- y de la licencia, test de seguridad, efectos (material -> impacto, casquillos, sonido lejano,
-- topes de casquillos y agujeros), posturas (tumbado, agachado) y las posturas del arma
-- (números normales y cero sin arma).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local env = setmetatable({ Vector3 = Vector3, CFrame = CFrame, Color3 = roblox.Color3, Enum = roblox.Enum, script = {} }, { __index = getfenv(1) })
local Weapons = luau.load(fs.readFile("src/shared/Weapons.luau"), { debugName = "Weapons", environment = env })()
local WeaponPose = luau.load(fs.readFile("src/client/Controllers/WeaponPose.luau"), { debugName = "WeaponPose", environment = env })()

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

local W = Weapons.List

print("▶ Datos de las armas")
local ids = 0
for id, w in W do
	ids += 1
	local okData = w.Id == id and w.Damage >= 0 and w.RPM > 0 and w.Magazine > 0 and w.Range > 0 and #w.Modes > 0 and #w.Parts > 0 and w.Parts[1].Name == "Empunadura"
	check(okData, id .. ": datos completos (empuñadura primero)")
	if w.Ammo then
		check(Weapons.AmmoTypes[w.Ammo] ~= nil, id .. ": su munición existe")
	end
end
check(ids >= 9, "hay pistola, revólver, escopeta, subfusil, fusil, francotirador, táser y dos de juguete")
check(W.Pistola.Kind == "Real" and W.PistolaAgua.Kind == "Toy" and W.Paintball.Kind == "Toy" and W.Taser.Stun ~= nil, "clases de arma")
check(W.PistolaPolicia.Duty and W.Taser.Duty and W.PistolaPolicia.Price == nil, "las de la policía no se venden")
check(W.Francotirador.Scope and W.Francotirador.AimFov < 30, "el francotirador tiene mira telescópica")
check(table.find(W.Fusil.Modes, "Auto") and table.find(W.Fusil.Modes, "Semi") and #W.Pistola.Modes == 1, "selector semi/auto donde toca")
check(Weapons.fromItem("Arma_Fusil") == W.Fusil and Weapons.fromItem("Pan") == nil, "objeto de la mochila <-> arma")

print("▶ Cadencia")
check(near(Weapons.interval(W.Fusil), 60 / 700), "el fusil dispara 700 por minuto")
check(not Weapons.ready(W.Pistola, 10, 10.1), "no se puede disparar antes de tiempo")
check(Weapons.ready(W.Pistola, 10, 10.16), "pasada la pausa, sí")
check(Weapons.ready(W.Pistola, 10, 10.13, 0.2), "con margen de red, un poco antes")
check(not Weapons.ready(W.Francotirador, 10, 10.8), "el cerrojo del francotirador es lento")

print("▶ Dispersión")
local still = Weapons.spread(W.Fusil, { Aiming = true })
local hip = Weapons.spread(W.Fusil, {})
local moving = Weapons.spread(W.Fusil, { Aiming = true, Speed = 16 })
local jumping = Weapons.spread(W.Fusil, { Aiming = true, Airborne = true })
local crouch = Weapons.spread(W.Fusil, { Aiming = true, Stance = "Crouch" })
local prone = Weapons.spread(W.Fusil, { Aiming = true, Stance = "Prone" })
check(still < hip, "apuntando se dispersa menos que desde la cadera")
check(moving > still and jumping > moving, "moverse y saltar abren la dispersión")
check(crouch < still and prone < crouch, "agachado mejor, tumbado todavía mejor")
check(Weapons.spread(W.Fusil, { Aiming = true, Stance = "Stand" }) == still, "de pie o sin atributo, igual")
check(Weapons.spread(W.Escopeta, { Aiming = true }) > 3, "la escopeta abre el cono de perdigones")
local bloom = 0
for _ = 1, 20 do
	bloom = Weapons.bloomAfter(W.Subfusil, bloom, 0.075)
end
check(bloom <= W.Subfusil.Spread.MaxBloom and bloom > 0, "disparar seguido abre la mira hasta un tope")
check(Weapons.bloomAfter(W.Subfusil, bloom, 5) == W.Subfusil.Spread.Bloom, "parando un rato vuelve a cerrarse")
local dir = Vector3.new(0, 0, -1)
local maxAngle = 0
for i = 1, 200 do
	local d = Weapons.scatter(dir, 3, (i % 17) / 17, (i % 23) / 23)
	maxAngle = math.max(maxAngle, math.deg(math.acos(math.clamp(d:Dot(dir), -1, 1))))
	if math.abs(d.Magnitude - 1) > 1e-4 then
		maxAngle = 999
	end
end
check(maxAngle <= 3.01 and maxAngle > 1, "los disparos caen dentro del cono (unitarios)")
check(Weapons.scatter(dir, 0, 0.5, 0.5) == dir, "sin dispersión, recto")
local px = Weapons.reticleRadius(2, 70, 800)
check(px > 0 and Weapons.reticleRadius(2, 30, 800) > px, "la mira se dibuja más grande con zoom")

print("▶ Daño")
check(Weapons.damageAt(W.Fusil, 10, "Torso") == 32, "el fusil quita 32 de cerca")
check(Weapons.damageAt(W.Fusil, 10, "Head") == 64 and Weapons.damageAt(W.Fusil, 10, "Limb") == 24, "cabeza x2, brazos y piernas menos")
check(Weapons.damageAt(W.Fusil, 500, "Torso") == math.floor(32 * 0.7 + 0.5), "de lejos cae hasta el mínimo")
check(Weapons.damageAt(W.Fusil, 325, "Torso") < 32 and Weapons.damageAt(W.Fusil, 325, "Torso") > 22, "entre medias, en línea recta")
check(Weapons.damageAt(W.Fusil, 700, "Torso") == 0, "fuera de alcance no hace nada")
check(Weapons.damageAt(W.Escopeta, 5, "Torso") * W.Escopeta.Pellets > Weapons.damageAt(W.Escopeta, 40, "Torso") * W.Escopeta.Pellets * 3, "la escopeta pierde mucho con la distancia")
check(Weapons.damageAt(W.PistolaAgua, 5, "Head") == 0 and Weapons.damageAt(W.Paintball, 5, "Torso") == 0, "los juguetes no hacen daño")
check(Weapons.zoneOf("Head") == "Head" and Weapons.zoneOf("LeftUpperArm") == "Limb" and Weapons.zoneOf("UpperTorso") == "Torso" and Weapons.zoneOf("RightFoot") == "Limb", "zonas del cuerpo por la pieza")

print("▶ Retroceso")
local up1, side1 = Weapons.recoilKick(W.Fusil, 1)
local up10 = Weapons.recoilKick(W.Fusil, 10)
check(up1 > 0 and up10 > up1, "en ráfaga el retroceso se acumula")
local upA, sideA = Weapons.recoilKick(W.Fusil, 4)
local upB, sideB = Weapons.recoilKick(W.Fusil, 4)
check(upA == upB and sideA == sideB, "el dibujo del retroceso se repite (se puede aprender)")
check(Weapons.recoilKick(W.Escopeta, 1) > Weapons.recoilKick(W.Pistola, 1) and W.Escopeta.Recoil.Body > W.Pistola.Recoil.Body, "la escopeta patea más que la pistola")
local _, recoilProne = Weapons.stanceFactor("Prone")
local _, recoilCrouch = Weapons.stanceFactor("Crouch")
check(recoilProne < recoilCrouch and recoilCrouch < 1 and select(2, Weapons.stanceFactor(nil)) == 1, "agachado y tumbado se nota menos el retroceso")
local x, v = 0, 5
for _ = 1, 120 do
	x, v = Weapons.spring(x, v, W.Fusil.Recoil.Return * 12, 1 / 60)
end
check(math.abs(x) < 1e-3 and math.abs(v) < 1e-2, "el muelle vuelve a 0 en menos de 2 s")
local peak, lowest = 0, 0
x, v = 0, 5
for _ = 1, 60 do
	x, v = Weapons.spring(x, v, 150, 1 / 60)
	peak = math.max(peak, x)
	lowest = math.min(lowest, x)
end
check(peak > 0.05, "el golpe se nota antes de volver")
check(lowest > -1e-3, "vuelve sin pasarse de largo (amortiguado)")

print("▶ Munición y recarga")
check(Weapons.capacity(W.Pistola, 3) == 16 and Weapons.capacity(W.Pistola, 0) == 15, "recámara: +1 si no está vacía")
check(Weapons.capacity(W.Revolver, 3) == 6, "el revólver no tiene recámara extra")
local plan = Weapons.reloadPlan(W.Pistola, 5, 100)
check(plan and plan.Mag == 16 and plan.Used == 11 and plan.Kind == "Tactical" and plan.Time == W.Pistola.Reload.Tactical, "recarga táctica: 15+1")
plan = Weapons.reloadPlan(W.Pistola, 0, 100)
check(plan and plan.Mag == 15 and plan.Kind == "Empty" and plan.Time > W.Pistola.Reload.Tactical, "en vacío: más lenta y sin la de la recámara")
plan = Weapons.reloadPlan(W.Pistola, 0, 4)
check(plan and plan.Mag == 4 and plan.Used == 4, "si quedan pocas balas, mete las que hay")
check(Weapons.reloadPlan(W.Pistola, 16, 100) == nil, "lleno no recarga")
check(Weapons.reloadPlan(W.Pistola, 3, 0) == nil, "sin munición no recarga")
plan = Weapons.reloadPlan(W.Escopeta, 4, 100)
check(plan and plan.Kind == "Shells" and plan.Used == 3 and near(plan.Time, W.Escopeta.Reload.Start + 3 * W.Escopeta.Reload.PerRound), "escopeta: cartucho a cartucho")
plan = Weapons.reloadPlan(W.PistolaAgua, 0, math.huge)
check(plan and plan.Mag == 40, "munición infinita (agua y armas de servicio)")
check(Weapons.nextMode(W.Fusil, "Auto") == "Semi" and Weapons.nextMode(W.Fusil, "Semi") == "Auto" and Weapons.nextMode(W.Pistola, "Semi") == "Semi", "selector de modo")

print("▶ Normas: quién compra, lleva y saca la licencia")
local adult = { Stage = "AdultoJoven", Licence = true, Stars = 0, Records = 0, Money = 10000 }
check(Weapons.buyCheck(W.Pistola, adult), "un adulto con licencia compra una pistola")
check(not Weapons.buyCheck(W.Pistola, { Stage = "AdultoJoven", Licence = false, Money = 10000 }), "sin licencia no")
check(not Weapons.buyCheck(W.Pistola, { Stage = "Adolescente", Licence = true, Money = 10000 }), "un adolescente no")
check(not Weapons.buyCheck(W.Pistola, { Stage = "Adulto", Licence = true, Stars = 2, Money = 10000 }), "con estrellas de búsqueda no")
check(not Weapons.buyCheck(W.Pistola, { Stage = "Adulto", Licence = true, Money = 10 }), "sin dinero no")
check(Weapons.buyCheck(W.PistolaAgua, { Stage = "Nino", Money = 100 }), "un niño compra la pistola de agua")
check(not Weapons.buyCheck(W.PistolaPolicia, adult), "la reglamentaria no se vende")
check(not Weapons.canHold(W.Pistola, "Nino") and not Weapons.canHold(W.Pistola, "Bebe") and Weapons.canHold(W.Paintball, "Nino"), "los niños no empuñan armas de verdad (sí de juguete)")
check(Weapons.licenceCheck({ Stage = "Adulto", Money = 1000 }), "un adulto sin antecedentes puede sacarse la licencia")
check(not Weapons.licenceCheck({ Stage = "Adulto", Money = 1000, Records = 1 }), "con antecedentes no")
check(not Weapons.licenceCheck({ Stage = "Adulto", Money = 1000, Stars = 1 }), "buscado no")
check(not Weapons.licenceCheck({ Stage = "Adolescente", Money = 1000 }), "menor no")
check(not Weapons.licenceCheck({ Stage = "Adulto", Money = 10 }), "sin la tasa no")
check(#Weapons.Quiz >= Weapons.Licence.Questions, "hay preguntas de sobra para el test")
local right, passed = Weapons.gradeQuiz({ 1, 2, 3, 1, 2 }, { 1, 2, 3, 1, 3 })
check(right == 4 and passed, "4 de 5: aprobado")
right, passed = Weapons.gradeQuiz({ 1, 2, 3, 1, 2 }, { 1, 1, 1, 1, 1 })
check(right == 2 and not passed, "2 de 5: suspenso")

print("▶ Tumbado: sin apuntar hacia atrás ni al suelo")
local look = Vector3.new(0, 0, -1)
local back = Weapons.clampProne(look, Vector3.new(0, 0, 1))
check(back:Dot(look) > math.cos(Weapons.ProneLimits.Yaw) - 1e-3, "hacia atrás se queda en el límite de giro")
local down = Weapons.clampProne(look, Vector3.new(0, -1, -0.1))
check(math.deg(math.asin(down.Y)) >= math.deg(Weapons.ProneLimits.PitchMin) - 0.01, "hacia el suelo se queda en el límite")
local ahead = Weapons.clampProne(look, Vector3.new(0.1, 0.05, -1).Unit)
check(ahead:Dot(Vector3.new(0.1, 0.05, -1).Unit) > 0.999, "delante no cambia")

print("▶ Efectos")
check(Weapons.impactKind("Metal") == "Sparks" and Weapons.impactKind("Concrete") == "Dust" and Weapons.impactKind("Brick") == "Dust", "metal chispas, hormigón y ladrillo polvo")
check(Weapons.impactKind("Wood") == "Splinters" and Weapons.impactKind("Water") == "Water" and Weapons.impactKind("Grass") == "Dirt" and Weapons.impactKind("Glass") == "Glass", "madera astillas, agua, césped tierra, cristal")
check(Weapons.impactKind(nil) == "Dust" and Weapons.impactKind("Loquesea") == "Dust", "material desconocido: polvo")
check(Weapons.leavesHole("Dust") and not Weapons.leavesHole("Water") and not Weapons.leavesHole("Character"), "agujero en paredes, no en el agua ni en personas")
local kind, n = Weapons.casingFor(W.Pistola, "Shot")
check(kind == "Brass" and n == 1, "la pistola expulsa un casquillo por disparo")
kind = Weapons.casingFor(W.Escopeta, "Shot")
check(kind == "Shell", "la escopeta expulsa cartuchos (rojos)")
kind, n = Weapons.casingFor(W.Revolver, "Shot")
check(kind == nil and n == 0, "el revólver no expulsa al disparar…")
kind, n = Weapons.casingFor(W.Revolver, "Reload", 6)
check(kind == "Brass" and n == 6, "…los suelta todos al recargar")
check(Weapons.casingFor(W.PistolaAgua, "Shot") == nil and Weapons.casingFor(W.Paintball, "Shot") == nil, "los juguetes no sueltan nada")
local ev = Weapons.casingVelocity(Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1), 0.5, 0.5)
check(ev.X > 5 and ev.Y > 4 and ev.Z > 0, "el casquillo sale a la derecha, arriba y un poco atrás")
local nearVol, nearMuffle = Weapons.hearing(10, false, 1)
local farVol, farMuffle, farEcho = Weapons.hearing(350, false, 1)
local _, _, inEcho = Weapons.hearing(350, true, 1)
check(nearVol > farVol and farMuffle > nearMuffle, "de lejos se oye más flojo y apagado")
check(farEcho > inEcho, "fuera hay más eco que dentro")
check(Weapons.hearing(Weapons.Fx.HearDistance + 10, false, 1) == 0, "muy lejos no se oye")
check(Weapons.recycleIndex(3, 30, 1) == 4 and Weapons.recycleIndex(30, 30, 7) == 7, "con el tope lleno se recicla el más viejo")
check(Weapons.Fx.MaxCasings == 30 and Weapons.Fx.MaxHoles == 60 and Weapons.Fx.HoleSeconds == 20, "topes: 30 casquillos y 60 agujeros (20 s)")
check(Weapons.muzzleBlocked(W.Fusil, 1) and not Weapons.muzzleBlocked(W.Fusil, 10) and not Weapons.muzzleBlocked(W.Fusil, nil), "pegado a una pared el cañón choca")
local su, ss = Weapons.sway(W.Francotirador, 1.3, true, false)
local hu, hs = Weapons.sway(W.Francotirador, 1.3, true, true)
check(math.abs(hu) < math.abs(su) and math.abs(hs) <= math.abs(ss), "conteniendo la respiración la mira tiembla menos")
check(Weapons.aimFov(W.Fusil, 70, 0) == 70 and Weapons.aimFov(W.Fusil, 70, 1) == 55 and Weapons.aimFov(W.Francotirador, 70, 1) < 30, "campo de visión apuntando")

print("▶ Posturas con el arma")
local function states()
	local list = {}
	for _, two in { false, true } do
		for _, aim in { 0, 0.5, 1 } do
			for _, extra in { {}, { Sprint = 1 }, { Reload = 0.4 }, { Recoil = 1.2 }, { Wall = 1 }, { Busy = 1 }, { Crouch = 1 }, { Prone = 1 }, { Pitch = 1.1 }, { Pitch = -2 } } do
				local s = { Hold = 1, Aim = aim, Pitch = 0.3, TwoHands = two, Stock = two, Sprint = 0, Recoil = 0, Body = 1, Wall = 0, SwayX = 0.01, SwayY = -0.01, Phase = 1 }
				for k, val in extra do
					s[k] = val
				end
				table.insert(list, s)
			end
		end
	end
	return list
end
local allSane = true
for _, s in states() do
	if not WeaponPose.sane(WeaponPose.pose(s)) then
		allSane = false
	end
end
check(allSane, "todas las posturas dan números normales y ángulos razonables")
local rest = WeaponPose.pose({ Hold = 0, Aim = 1, Pitch = 0.8, TwoHands = true, Stock = true, Sprint = 0, Recoil = 1, Body = 1, Wall = 0 })
local zero = rest.Weight == 0
for _, v3 in rest.Add do
	if v3.Magnitude > 1e-9 then
		zero = false
	end
end
check(zero, "sin arma (Hold = 0) no se toca nada")
local low = WeaponPose.pose({ Hold = 1, Aim = 0, Pitch = 0, TwoHands = true, Stock = true, Sprint = 0, Recoil = 0, Body = 1, Wall = 0 })
local aimed = WeaponPose.pose({ Hold = 1, Aim = 1, Pitch = 0, TwoHands = false, Stock = false, Sprint = 0, Recoil = 0, Body = 1, Wall = 0 })
check(aimed.Arms.RightShoulder.X > 1.2 and aimed.Arms.LeftShoulder.X > 1.2, "pistola apuntando: los dos brazos arriba")
check(low.Arms.LeftShoulder.X > 0.5 and low.Arms.RightShoulder.X < 1, "arma larga preparada: a dos manos, cañón abajo")
local up = WeaponPose.pose({ Hold = 1, Aim = 1, Pitch = 0.6, TwoHands = true, Stock = true, Sprint = 0, Recoil = 0, Body = 1, Wall = 0 })
local flat = WeaponPose.pose({ Hold = 1, Aim = 1, Pitch = 0, TwoHands = true, Stock = true, Sprint = 0, Recoil = 0, Body = 1, Wall = 0 })
check(up.Add.Waist.X > flat.Add.Waist.X and up.Arms.RightShoulder.X > flat.Arms.RightShoulder.X, "apuntando arriba suben el tronco y los brazos")
local kick = WeaponPose.pose({ Hold = 1, Aim = 1, Pitch = 0, TwoHands = true, Stock = true, Sprint = 0, Recoil = 1, Body = 1, Wall = 0 })
check(kick.Arms.RightShoulder.X > flat.Arms.RightShoulder.X and kick.Add.Waist.X > flat.Add.Waist.X and kick.Add.Neck.X > flat.Add.Neck.X, "el retroceso sube brazos, pecho y cabeza")
local run = WeaponPose.pose({ Hold = 1, Aim = 0, Pitch = 0, TwoHands = true, Stock = true, Sprint = 1, Recoil = 0, Body = 1, Wall = 0 })
check(run.Arms.RightElbow.X > low.Arms.RightElbow.X, "corriendo: el arma cruzada en el pecho")
local busyAim = WeaponPose.pose({ Hold = 1, Aim = 1, Pitch = 0, TwoHands = true, Stock = true, Sprint = 0, Recoil = 0, Body = 1, Wall = 0, Busy = 1 })
check(busyAim.Arms.RightElbow.X > flat.Arms.RightElbow.X, "saltando una valla: el arma bajada aunque apuntes")
local d0, u0 = WeaponPose.reloadCurve(0)
local d1, u1 = WeaponPose.reloadCurve(1)
local dm, um = WeaponPose.reloadCurve(0.25)
local _, um2 = WeaponPose.reloadCurve(0.6)
check(d0 == 0 and u0 == 0 and d1 == 0 and u1 == 0 and dm > 0.5 and um2 > 0.5 and um == 0, "recarga: mano al cinturón, al arma y vuelta")

print("▶ Armerías en la ciudad")
local districts = fs.readFile("src/server/World/Kit/Districts.luau")
local shops = 0
for name in districts:gmatch('{ "(Armeria%w+)", "%w+", %-?%d+, %-?%d+ }') do
	if districts:find("builders." .. name .. " = armeria(", 1, true) then
		shops += 1
	end
end
check(shops >= 3, ("hay %d Armerías en el plano (al menos 3, en distritos distintos)"):format(shops))
local mapInfo = fs.readFile("src/shared/MapInfo.luau")
check(mapInfo:find('Model = "Armeria"', 1, true) ~= nil, "salen en el mapa y el minimapa con su icono")
local kit = fs.readFile("src/server/World/Kit/GunShop.luau")
for _, tag in { '"GunShop"', '"GunLicence"', '"ShootingRange"', '"RangeTarget"', '"JobBoard"' } do
	check(kit:find(tag, 1, true) ~= nil, "la Armería tiene " .. tag)
end

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
