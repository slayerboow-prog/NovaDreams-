-- Prueba del manejo de las armas en el móvil (estilo shooter móvil) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-shooter.luau
--
-- Comprueba, en el código, que:
--   * NO hay ayuda de apuntado (ni tirón al apuntar, ni imán al disparar, ni fricción): shared/AimAssist
--     ya no existe y WeaponController no la usa
--   * la cámara con el arma es la de Roblox: ni zona de arrastre propia (CamaraTactil), ni giro a mano,
--     ni el dedo de Disparar gira la cámara, ni se le fija el CFrame cada fotograma
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

print("▶ Sin ayuda de apuntado")
local wc = fs.readFile("src/client/Controllers/WeaponController.luau")
local function has(text: string): boolean
	return string.find(wc, text, 1, true) ~= nil
end
check(not fs.isFile("src/shared/AimAssist.luau"), "shared/AimAssist ya no existe")
check(not has("AimAssist") and not has("assistOn") and not has("snapPending") and not has("onTargetNow") and not has("refreshCandidates"),
	"WeaponController no tiene ayuda de apuntado (ni tirón, ni imán, ni fricción)")
for _, file in fs.readDir("src/client/Controllers") do
	if string.sub(file, -5) == ".luau" then
		local src = fs.readFile("src/client/Controllers/" .. file)
		if string.find(src, "AimAssist", 1, true) then
			check(false, ("%s ya no usa AimAssist"):format(file))
		end
	end
end

print("▶ La cámara es la de Roblox")
check(not has("CamaraTactil") and not has("ZonaCamara") and not has("dragTurn") and not has("pendingYaw") and not has("applyTurn"),
	"sin zona de arrastre propia (CamaraTactil) ni giro de cámara a mano")
check(not has("Drag = WeaponController.drag") and not has("function WeaponController.drag"), "arrastrar el dedo de Disparar no gira la cámara")
local touchLayout = fs.readFile("src/client/UI/TouchLayout.luau")
check(touchLayout:find("spec.Drag", 1, true) == nil, "TouchLayout ya no gira nada al arrastrar el dedo de un botón")
check(string.find(wc, "camera%.CFrame%s*=[^=]") == nil and string.find(wc, "CurrentCamera%.CFrame%s*=[^=]") == nil,
	"WeaponController nunca fija el CFrame de la cámara (ni retroceso, ni balanceo, ni hombro)")
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

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
