-- Prueba del manejo de las armas en el móvil (estilo shooter móvil) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-shooter.luau
--
-- Comprueba, en el código y con las cuentas, que:
--   * la ayuda al apuntar (shared/AimAssist) es SEGURA: solo a enemigos (nunca jugadores ni gente de la
--     calle), nunca mueve la cámara si no la mueves tú, fricción e imán con tope, imán de la bala pequeño,
--     se puede apagar (shared/ShooterPrefs) y con ratón va apagada en «Auto»; disparo automático en el
--     móvil solo con la mira encima de un enemigo que se ve
--   * la cámara con el arma es la de Roblox: ni zona de arrastre propia (CamaraTactil), ni el dedo de
--     Disparar gira la cámara; solo se gira un poquito DESPUÉS de la de Roblox (ayuda y golpe del
--     retroceso, que vuelve solo) y nunca se fija de golpe
--   * lo que se nota al acertar: aspa (cabeza, caído), chasquidos, números de daño (con su ajuste),
--     barra de recarga, aviso de pocas balas y cambiar de arma
--   * el hombro y el zoom van con Humanoid.CameraOffset y el zoom de Roblox; apuntando o disparando
--     gira el CUERPO hacia donde mira la cámara
--   * los botones del móvil y el servidor siguen igual

local fs = require("@lune/fs")
local process = require("@lune/process")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local L = require("./lib/ModuleLoader")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3

print("▶ Ayuda al apuntar (cuentas)")
local AimAssist = L.load("src/shared/AimAssist")
local ShooterPrefs = L.load("src/shared/ShooterPrefs")
local touch = AimAssist.Profiles.Touch
local mouse = AimAssist.Profiles.Mouse
check(AimAssist.isEnemy({ InvasionTarget = "G1" }) and AimAssist.isEnemy({ MissionEnemy = "q" }), "ayuda hacia alienígenas y enemigos de tu misión")
check(not AimAssist.isEnemy({}) and not AimAssist.isEnemy({ IsPlayer = true, InvasionTarget = "x" }), "nunca hacia jugadores ni gente de la calle")
local eye = Vector3.new(0, 5, 0)
local fwd = Vector3.new(0, 0, -1)
local near = { Id = "a", Pos = Vector3.new(1.5, 5, -40), Radius = 1 } -- (≈ 2° de lado)
local wide = { Id = "b", Pos = Vector3.new(30, 5, -40), Radius = 1 } -- (≈ 37°: fuera del cono)
local best, angle = AimAssist.pick(fwd, eye, { wide, near }, touch)
check(best == near and angle < touch.Cone, ("elige al que está dentro del cono (%.1f°)"):format(angle))
check(AimAssist.pick(fwd, eye, { wide }, touch) == nil, "fuera del cono, nada")
check(AimAssist.pick(fwd, eye, { { Id = "c", Pos = Vector3.new(0, 5, -400), Radius = 1 } }, touch) == nil, "ni más lejos que su alcance")
check(AimAssist.friction(0.5, touch) == touch.Friction and AimAssist.friction(touch.Cone + 1, touch) == 1 and AimAssist.friction(nil, touch) == 1, "fricción solo con la mira encima (y nada fuera del cono)")
local f1, f2 = AimAssist.friction(touch.Inner + 1, touch), AimAssist.friction(touch.Cone - 0.5, touch)
check(f1 < f2 and f2 < 1, "la fricción se suaviza hacia el borde del cono")
local y0, p0 = AimAssist.magnet(fwd, eye, near.Pos, touch, 1 / 60, false)
check(y0 == 0 and p0 == 0, "el imán NO mueve la cámara si no estás girando ni andando")
local y1, p1 = AimAssist.magnet(fwd, eye, Vector3.new(4, 5, -40), touch, 1 / 60, true)
check(math.abs(y1) > 0 and math.abs(y1) <= math.rad(touch.Magnet) / 60 + 1e-6 and y1 < 0, "girando: un empujoncito hacia el enemigo, con tope de grados por segundo")
local y2 = AimAssist.magnet(fwd, eye, Vector3.new(0.05, 5, -40), touch, 1 / 60, true)
check(y2 == 0, "ya encima: no tira más (no se pega)")
check(select(1, AimAssist.magnet(fwd, eye, near.Pos, mouse, 1 / 60, true)) == 0 and mouse.Friction == 1, "con ratón ni imán ni fricción")
local dirBent = AimAssist.bend(eye, fwd * 100, near.Pos, touch)
local dirKept = AimAssist.bend(eye, fwd * 100, wide.Pos, touch)
check((dirBent.Unit - (near.Pos - eye).Unit).Magnitude < 1e-4 and dirKept == fwd * 100, "imán de la bala: rozando le da; lejos de él, no")
check(AimAssist.autoFire(0.5, touch, true) and not AimAssist.autoFire(0.5, touch, false) and not AimAssist.autoFire(touch.Cone, touch, true), "disparo automático: solo encima de un enemigo que se ve")
check(ShooterPrefs.assistOn("Auto", "Touch") and ShooterPrefs.assistOn("Auto", "Gamepad") and not ShooterPrefs.assistOn("Auto", "Mouse"), "«Auto»: en el móvil y el mando sí; con ratón no")
check(not ShooterPrefs.assistOn("No", "Touch") and ShooterPrefs.assistOn("Si", "Mouse"), "se puede apagar (o encender con ratón)")
local clean = ShooterPrefs.sanitize({ Assist = "Hack", AutoFire = "sí", Numbers = false })
check(clean.Assist == "Auto" and clean.AutoFire == true and clean.Numbers == false, "lo guardado se limpia (lo que no vale, el de por defecto)")
check(ShooterPrefs.next("Assist", "Auto") == "Si" and ShooterPrefs.next("Assist", "No") == "Auto" and ShooterPrefs.next("Numbers", true) == false, "el botón del menú pasa al siguiente valor")

print("▶ Ayuda al apuntar (en el juego)")
local wc = fs.readFile("src/client/Controllers/WeaponController.luau")
local function has(text: string): boolean
	return string.find(wc, text, 1, true) ~= nil
end
check(has("AimAssist.isEnemy({ InvasionTarget") and has('CollectionService:GetTagged("MissionEnemy")') and has("not Players:GetPlayerFromCharacter(m)"), "los candidatos: alienígenas y enemigos de tu misión (nunca jugadores)")
check(has('BindToRenderStep("WeaponAssist", Enum.RenderPriority.Camera.Value + 1'), "la ayuda y el golpe del retroceso van DESPUÉS de la cámara de Roblox")
do
	local body = string.match(wc, "local function afterCamera%(dt: number%)(.-)\nend\n") or ""
	check(body:find("turning or moving or trigger", 1, true) ~= nil and body:find("WeaponController.menuOpen()", 1, true) ~= nil, "el imán solo mientras giras, andas o disparas; con un menú abierto, nada")
	check(body:find("kickUp *= decay", 1, true) ~= nil, "el golpe del retroceso vuelve solo a su sitio")
end
check(has('holdTrigger("Auto", wantAuto)') and has('pref("AutoFire") ~= false') and has("TouchLayout.isTouch() and pref"), "disparo automático en el móvil (con su ajuste)")
check(has('WeaponController.damageNumber(hit.At') and has('pref("Numbers") ~= false') and has('SoundFx.play("Punto"') and has('SoundFx.play("KO"'), "números de daño (con su ajuste) y un chasquido para acertar, cabeza y caer")
check(has('Name = "Recarga"') and has('"RECARGANDO…"') and has('"R · RECARGAR"'), "recargando: barra y texto; con pocas balas, aviso")
check(has('Id = "CambiarArma"') and has("function WeaponController.nextWeapon()") and has("Enum.KeyCode.Q"), "cambiar de arma: botón en el móvil, Q y la cruceta")
local mainc = fs.readFile("src/client/Main.client.luau")
local settings = fs.readFile("src/server/Services/SettingsService.luau")
check(mainc:find("ShooterPrefs.label(key", 1, true) ~= nil and settings:find("SettingsService.setShooter", 1, true) ~= nil and settings:find('"ShooterPrefs"', 1, true) ~= nil, "los ajustes salen en el menú y se guardan con la partida")

print("▶ La mira, la barra de recarga y el aviso no pisan el HUD (932x430, 844x390, 640x360, 1920x1080)")
do
	local HudLayout = L.load("src/client/UI/HudLayout")
	for _, size in { { 932, 430, true }, { 844, 390, true }, { 640, 360, true }, { 1920, 1080, false } } do
		local view = roblox.Vector2.new(size[1], size[2])
		local layout = HudLayout.compute(view, { Touch = size[3] })
		-- (en píxeles: la mira con sus marcas, la barra de recarga y el aviso de debajo, y las esquinas de
		-- fijado van en el centro; se pasan al lienzo del HUD)
		local k = layout.Scale
		local zone = { X = (size[1] / 2 - 80) / k, Y = (size[2] / 2 - 30) / k, W = 160 / k, H = 102 / k }
		-- (lo que no sale a pie con un arma: avión, montura, ayudas de conducir; los avisos crecen solos)
		local notOnFoot = { Flight = true, FlightZone = true, Ride = true, HelpCard = true, GuideDrive = true, Toasts = true }
		local clash = {}
		for id, p in layout.Items do
			if type(p) == "table" and p.Size and not notOnFoot[id] and HudLayout.overlaps(zone, HudLayout.rect(p, layout.Canvas)) then
				table.insert(clash, id)
			end
		end
		for id, p in layout.Slots do
			if HudLayout.overlaps(zone, HudLayout.rect(p, layout.Canvas)) then
				table.insert(clash, id)
			end
		end
		check(#clash == 0, ("%dx%d: el centro (mira, recarga, aviso) libre%s"):format(size[1], size[2], if #clash > 0 then " — pisa: " .. table.concat(clash, ", ") else ""))
	end
end

print("▶ La cámara es la de Roblox")
check(not has("CamaraTactil") and not has("ZonaCamara") and not has("dragTurn") and not has("pendingYaw") and not has("applyTurn"),
	"sin zona de arrastre propia (CamaraTactil) ni giro de cámara a mano")
check(not has("Drag = WeaponController.drag") and not has("function WeaponController.drag"), "arrastrar el dedo de Disparar no gira la cámara")
local touchLayout = fs.readFile("src/client/UI/TouchLayout.luau")
check(touchLayout:find("spec.Drag", 1, true) == nil, "TouchLayout ya no gira nada al arrastrar el dedo de un botón")
do
	-- El CFrame de la cámara solo se toca en turnCamera (un giro pequeño alrededor de su foco, después de Roblox)
	local n = 0
	for _ in string.gmatch(wc, "camera%.CFrame%s*=[^=]") do
		n += 1
	end
	local turn = string.match(wc, "local function turnCamera%(.-\nend\n") or ""
	check(n == 1 and turn:find("camera.CFrame = CFrame.lookAt(focus + newRel", 1, true) ~= nil and string.find(wc, "CurrentCamera%.CFrame%s*=[^=]") == nil,
		"la cámara solo se gira en turnCamera (alrededor de su foco, sin saltos; ni balanceo ni hombro la fijan)")
end
check(not has("CameraType =") and not has("CameraSubject ="), "ni cambia el tipo ni el sujeto de la cámara (sigue en Custom)")
check(has("humanoid.CameraOffset = root.CFrame:VectorToObjectSpace(") and has("Weapons.shoulderOffset("), "el hombro va con Humanoid.CameraOffset (en el eje de la cámara)")
check(has("player.CameraMaxZoomDistance = math.max(distance, 1)") and has("FootCamera.setAim(eased, fov)"), "apuntando: el zoom de Roblox se acerca y el campo de visión se cierra")
check(has('BindToRenderStep("WeaponCamera", Enum.RenderPriority.Camera.Value - 1'), "el hombro y el giro del cuerpo van ANTES de la cámara de Roblox")
do
	local frameBody = string.match(wc, "local function frame%(dt: number%)(.-)\nend\n") or ""
	check(string.find(frameBody, "local firing = trigger", 1, true) ~= nil and string.find(frameBody, "humanoid.AutoRotate = false", 1, true) ~= nil
		and string.find(frameBody, "root.CFrame = current:Lerp(target", 1, true) ~= nil,
		"apuntando o disparando, gira el cuerpo hacia donde mira la cámara (no la cámara)")
end
local cc = fs.readFile("src/client/Controllers/CombatController.luau")
check(cc:find("CombatFx.inCinematic() or armed() then", 1, true) ~= nil and cc:find("if armed() and not lockTarget then", 1, true) ~= nil,
	"con un arma, el objetivo fijado de los puñetazos no gira la cámara")

print("▶ En el juego")
check(has('Slot = "DispararIzq"') and has('Slot = "Disparar"') and has('Slot = "Apuntar"') and has('Slot = "Recargar"'), "botones del móvil: Disparar, el segundo Disparar, Apuntar y Recargar")
check(has('Name = "WeaponReticle"') and has("DisplayOrder = -1") and has("WeaponController.menuOpen()"), "la mira va por debajo de los menús y con una ventana abierta ni se ve ni se dispara")
do
	local frameBody = string.match(wc, "local function frame%(dt: number%)(.-)\nend\n") or ""
	local menuAt = string.find(frameBody, "local menu = WeaponController.menuOpen()", 1, true)
	local aimingAt = string.find(frameBody, "local aiming = wantAim", 1, true)
	check(menuAt ~= nil and aimingAt ~= nil and menuAt < aimingAt and string.find(frameBody, "if menu and wantAim then\n\t\tWeaponController.setAim(false)", 1, true) ~= nil, "al abrir un menú se suelta la mira (sin zoom ni cámara al hombro detrás del menú)")
	check(string.find(frameBody, "if aimInputHeld() then\n\t\t\tWeaponController.setAim(true)", 1, true) ~= nil and has("IsMouseButtonPressed(Enum.UserInputType.MouseButton2)"), "…y al cerrarlo vuelve solo si sigues pulsando apuntar")
end
local items = fs.readFile("src/shared/Items.luau")
check(items:find("De juguete: hace muy poco daño", 1, true) ~= nil, "la pistola de agua dice «De juguete: hace muy poco daño»")
check(has('holdTrigger("Izq"') and has('holdTrigger("Der"'), "cada Disparar con su dedo (soltar uno no corta el otro)")
check(has("Airborne = humanoid.FloorMaterial == Enum.Material.Air"), "en el aire se puede disparar (con algo más de dispersión)")
local ws = fs.readFile("src/server/Services/WeaponService.luau")
check(ws:find('Remote:FireServer', 1, true) == nil and ws:find("Weapons.ready(w, s.LastShot, now", 1, true) ~= nil and ws:find("mags(player)", 1, true) ~= nil, "el servidor sigue mandando: cadencia y munición se comprueban allí")

print("▶ La bala va a la mira (auditoría de disparos: docs/auditoria/disparos.md)")
do
	local Weapons = L.load("src/shared/Weapons")
	local HitCheck = L.load("src/shared/Invasion/HitCheck")
	-- El jugador en el origen; la cámara al hombro (a la derecha y arriba) y 10 studs detrás, mirando un
	-- poco hacia un lado; un alienígena (alto 6, radio 1,3) puesto JUSTO en el centro de la pantalla a 40
	local head = Vector3.new(0, 4.5, 0)
	local camPos = head + Vector3.new(2.6, 0.35, 10)
	local look = (Vector3.new(-6, 1, -40) - camPos).Unit
	local center = camPos + look * 50 -- (el centro del alienígena, en la mira)
	local alien = { Id = "A", Feet = center - Vector3.new(0, 3, 0), Height = 6, Radius = 1.3 }
	-- Lo que hace aimPoint: el rayo del centro de la pantalla (empieza a la altura de tu cabeza)
	local start = Weapons.aimStart(camPos, look, head)
	check((start - camPos).Magnitude > 5 and (start - camPos).Magnitude < 12, "el rayo de la mira empieza a la altura de tu cabeza (no tapa lo que hay entre la cámara y tú)")
	local a = alien.Feet + Vector3.new(0, alien.Radius, 0)
	local b = alien.Feet + Vector3.new(0, alien.Height - alien.Radius, 0)
	local dist = HitCheck.rayCapsule(start, look, 300, a, b, alien.Radius)
	check(dist ~= nil, "el rayo de la cámara (centro de la pantalla) encuentra al alienígena de la mira")
	local aimPointWorld = start + look * ((dist or 0) + 0.3)
	-- El servidor: de tu CABEZA a ese punto (no hacia donde mira el cuerpo)
	local serverDir = (aimPointWorld - head).Unit
	local hit = HitCheck.pick(head, serverDir, 300, { alien }, nil, 1, 0)
	check(hit ~= nil, "el servidor, de tu cabeza al punto de la mira, le da (aunque la cámara vaya al hombro)")
	local bodyDir = Vector3.new(0, 0, -1) -- (hacia donde mira el cuerpo: lo que NO se usa)
	check(HitCheck.pick(head, bodyDir, 300, { alien }, nil, 1, 0) == nil, "…y disparando hacia donde mira el cuerpo habría fallado (por eso se usa la mira)")
	-- Con su dispersión: el primer disparo andando desde la cadera (dados del servidor) le da siempre
	local function rate(spread: number, n: number, uniform: boolean?): number
		local hits = 0
		for k = 1, n do
			local u, v = Weapons.shotRoll(4242, k, 1)
			local d = Weapons.scatter(serverDir, spread, u, v)
			if uniform then
				-- (el reparto de antes: radio con la raíz de u)
				local up = Vector3.new(0, 1, 0)
				local right = serverDir:Cross(up).Unit
				local up2 = right:Cross(serverDir).Unit
				local r = math.tan(math.rad(spread)) * math.sqrt(u)
				d = (serverDir + right * (math.cos(v * math.pi * 2) * r) + up2 * (math.sin(v * math.pi * 2) * r)).Unit
			end
			if HitCheck.pick(head, d, 300, { alien }, nil, 1, 0) then
				hits += 1
			end
		end
		return hits / n
	end
	local P = Weapons.get("Pistola") :: any
	local first = rate(Weapons.spread(P, { Speed = 16, First = true }), 300)
	local follow = rate(Weapons.spread(P, { Speed = 16, Bloom = P.Spread.Bloom }), 300)
	local before = rate(P.Spread.Hip * (1 + 1 * P.Spread.Move) + P.Spread.Bloom, 300, true)
	check(first >= 0.97, ("pistola, andando, desde la cadera, a 50 studs: el primer disparo le da (%.0f %%)"):format(first * 100))
	check(follow > before, ("los siguientes, mejor que antes (%.0f %% ahora, %.0f %% con el reparto de antes)"):format(follow * 100, before * 100))
end

print("▶ La ayuda al apuntar no se fija en caídos ni lejanos")
do
	local alive = { Id = "vivo", Pos = Vector3.new(0.5, 5, -30), Radius = 1 }
	local dead = { Id = "caido", Pos = Vector3.new(0.1, 5, -20), Radius = 1, Dead = true }
	local far = { Id = "lejos", Pos = Vector3.new(0, 5, -(touch.Range + 30)), Radius = 1 }
	check(AimAssist.pick(fwd, eye, { dead, far, alive }, touch) == alive, "entre un caído (más cerca y más centrado), uno lejísimos y uno vivo: el vivo")
	check(AimAssist.pick(fwd, eye, { dead }, touch) == nil and AimAssist.pick(fwd, eye, { far }, touch) == nil, "solo caídos o fuera de alcance: ninguno")
	check(has("local dead = (tonumber(c.Model:GetAttribute(\"Hp\")) or 1) <= 0 or c.Model:GetAttribute(\"EnemyDown\") ~= nil"), "en el juego se marca caído al alienígena sin vida y al enemigo de misión en el suelo")
end

print("▶ Se nota al acertar y las balas se leen en el móvil")
do
	local confirm = string.match(wc, 'elseif kind == "Confirm" then(.-)elseif kind == "Dry"') or ""
	check(confirm:find("hitMarker = os.clock()", 1, true) ~= nil and confirm:find("SoundFx.play", 1, true) ~= nil and confirm:find("WeaponController.damageNumber", 1, true) ~= nil,
		"al llegar el «acierto» del servidor: aspa, chasquido y número de daño")
	check(has('Remote:FireServer("Fire", target, shotN)') and has("Weapons.shotRoll(seed, shotN, pellet)"), "el trazo usa los mismos dados que el servidor (semilla WeaponSeed + número de disparo)")
	check(has("Weapons.holdRepeats(mode, #w.Modes, holds.Auto == true"), "mantener Disparar en el móvil repite con las semiautomáticas")
	check(has("autoReloadAt = now + 0.25") and has("WeaponController.reload()"), "recarga sola al gastar la última bala")
	local frameBody = string.match(wc, "local function frame%(dt: number%)(.-)\nend\n") or ""
	check(frameBody:find("refreshAmmo()", 1, true) ~= nil, "las balas en pantalla se ponen al momento (y sale «RECARGANDO…»), sin esperar al servidor")
	check(has("Weapons.reticleEase(reticleShown, goal"), "la mira se abre y se cierra suave")
	local wsrc = fs.readFile("src/server/Services/WeaponService.luau")
	check(wsrc:find("Weapons.shotRoll(s.Seed, s.ShotN, pellet)", 1, true) ~= nil and wsrc:find("Weapons.nextShotNumber(s.ShotN, shotNumber)", 1, true) ~= nil and wsrc:find("math.random(), math.random()", 1, true) == nil,
		"el servidor tira los mismos dados (su semilla) y decide él: el cliente solo manda el punto y el número")
	check(wsrc:find("First = s.Shot == 1", 1, true) ~= nil, "el servidor también hace preciso el primer disparo")
end

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
