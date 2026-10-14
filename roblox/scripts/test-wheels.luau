-- Prueba de las RUEDAS QUE GIRAN FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-wheels.luau
--
-- Comprueba (shared/WheelRig, Controllers/WheelSpin, con los modelos DE VERDAD de Kit/Rides y
-- Kit/CarModel y las llantas del taller de shared/VehicleBuild):
--   * rodar sin deslizar: el giro avanza distancia / radio; hacia delante la parte de arriba de la
--     rueda va hacia el morro; marcha atrás gira al revés
--   * el volante: con el mando (tope en cada tipo; bici, patinete y monopatín no giran) y deducido de
--     cuánto gira el vehículo (modelo de bicicleta), con tope y sin cambiar casi parado
--   * freno de mano en marcha: las de atrás bloqueadas, las de delante no
--   * LOD: lejos, fuera de la vista o pasado el máximo no se anima; el tuyo siempre
--   * se encuentran las ruedas de todos los vehículos (coche en sus tres carrocerías y ligero,
--     patrulla, autobús, camión, bomberos, moto, bici, patinete, monopatín), con todas sus piezas
--     (llanta, buje, radios, tuercas, disco) y las llantas y bandas del taller (Mod_…); los barcos no
--   * el controlador: suelda las ruedas con Weld (sin tocar colisión, tamaño, anclaje, masa ni el
--     chasis), las gira al moverse, las de delante con el volante, y al salir de la vista las deja
--     en su sitio; las patrullas ancladas se colocan pieza a pieza

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

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
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end
local function cfNear(a: any, b: any, eps: number?): boolean
	local ca, cb = { a:GetComponents() }, { b:GetComponents() }
	for i = 1, 12 do
		if math.abs(ca[i] - cb[i]) > (eps or 1e-4) then
			return false
		end
	end
	return true
end

---------------------------------------------------------------------
-- Cargar módulos (require por nombre)
---------------------------------------------------------------------
local mods = {}
local baseEnv = { Instance = Instance, CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum, UDim2 = roblox.UDim2, UDim = roblox.UDim, Font = roblox.Font }
local function load(path: string, name: string, extra: { [string]: any }?)
	local env = setmetatable(table.clone(baseEnv), { __index = getfenv(1) })
	env.script = { Parent = { Parent = { Builder = "Builder" }, Palette = "Palette", CarModel = "CarModel", VehicleParts = "VehicleParts", Driving = "Driving" } }
	env.require = function(key)
		return mods[key] or error("módulo sin cargar: " .. tostring(key))
	end
	for k, v in extra or {} do
		env[k] = v
	end
	mods[name] = luau.load(fs.readFile(path), { debugName = path, environment = env })()
	return mods[name]
end
load("src/server/World/Builder.luau", "Builder")
load("src/server/World/Kit/Palette.luau", "Palette")
local CarModel = load("src/server/World/Kit/CarModel.luau", "CarModel")
local Rides = load("src/server/World/Kit/Rides.luau", "Rides")
local VehicleParts = load("src/shared/VehicleParts.luau", "VehicleParts")
local VehicleBuild = load("src/shared/VehicleBuild.luau", "VehicleBuild")
local WheelRig = load("src/shared/WheelRig.luau", "WheelRig")
local Tyres = load("src/shared/Tyres.luau", "Tyres")

local CF = CFrame.new(120, 4, -35) * CFrame.Angles(0, 0.7, 0) -- sitio girado: las cuentas no dependen del origen

-- Las piezas de un modelo respecto al vehículo (como las ve WheelRig)
local function infosOf(model: any, origin: any): ({ any }, { any })
	local infos, parts = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(infos, { Name = d.Name, CFrame = origin:ToObjectSpace(d.CFrame), Size = d.Size })
		end
	end
	return infos, parts
end

---------------------------------------------------------------------
print("Rodar sin deslizar")
---------------------------------------------------------------------
do
	local r = 1.3
	local a1 = WheelRig.advance(0, 2, r)
	check(near(math.abs(((a1 + math.pi) % (2 * math.pi)) - math.pi), 2 / r), "avanzar 2 studs con radio 1,3 gira 2/1,3 rad")
	local a2 = WheelRig.advance(0, -2, r)
	check(near(((a1 + a2) % (2 * math.pi)), 0) or near(((a1 + a2) % (2 * math.pi)), 2 * math.pi), "marcha atrás: gira lo mismo al revés")
	local a3 = WheelRig.advance(0, 2 * math.pi * r, r)
	check(near(a3, 0, 1e-9) or near(a3, 2 * math.pi, 1e-9), "una vuelta entera = 2πr (el ángulo se queda entre 0 y 2π)")
	check(WheelRig.advance(0.5, 3, 0) == 0.5, "radio 0: no gira (sin dividir por cero)")
	-- Hacia delante, lo de arriba de la rueda va hacia el morro (−Z) y lo de abajo hacia atrás
	local wheel = { Hub = CFrame.new(2.8, r, -4.3), Angle = WheelRig.advance(0, 0.2, r), Front = false, Steer = {}, Spin = {} }
	local top = WheelRig.pose(wheel :: any, 0, CFrame.new(2.8, 2 * r, -4.3)).Position
	local bottom = WheelRig.pose(wheel :: any, 0, CFrame.new(2.8, 0, -4.3)).Position
	check(top.Z < -4.3 and bottom.Z > -4.3, "hacia delante: arriba hacia el morro, abajo hacia atrás (rueda sin deslizar)")
	wheel.Angle = WheelRig.advance(0, -0.2, r)
	check(WheelRig.pose(wheel :: any, 0, CFrame.new(2.8, 2 * r, -4.3)).Position.Z > -4.3, "marcha atrás: arriba hacia atrás")
	-- La pieza no se separa de la rueda (gira alrededor de su centro)
	local dist = (WheelRig.pose(wheel :: any, 0, CFrame.new(2.8, 2 * r, -4.3)).Position - Vector3.new(2.8, r, -4.3)).Magnitude
	check(near(dist, r, 1e-5), "lo que gira con la rueda se queda a la misma distancia de su centro")
end

---------------------------------------------------------------------
print("Volante")
---------------------------------------------------------------------
local carInfos = infosOf(Rides.build("Coche", nil, CF), CF)
local carRig = WheelRig.find(carInfos, "Coche")
do
	local max = WheelRig.MaxSteer.Coche
	check(near(WheelRig.steerFromInput(carRig, 1), -max), "volante a la derecha: ruedas a la derecha (tope " .. math.floor(math.deg(max)) .. "°)")
	check(near(WheelRig.steerFromInput(carRig, -5), max), "volante de más: se queda en el tope")
	check(near(WheelRig.steerFromInput(carRig, 0.5), -max / 2), "medio volante: medio giro")
	local biciRig = WheelRig.find((infosOf(Rides.build("Bici", nil, CF), CF)), "Bici")
	check(not biciRig.Steers and WheelRig.steerFromInput(biciRig, 1) == 0, "la bici no gira la rueda (solo rueda)")
	-- Modelo de bicicleta: girando a 0,2 rad/s a 20 studs/s con batalla L: atan(L · 0,2 / 20)
	local L = carRig.Wheelbase
	check(near(L, 8.6, 0.01), "batalla del coche = 8,6 studs (de las ruedas encontradas)")
	local want = math.atan(L * 0.2 / 20)
	check(near(WheelRig.steerFromYaw(carRig, 0.2, 20) :: number, want), "deducido de la curva: atan(batalla × giro / velocidad)")
	check((WheelRig.steerFromYaw(carRig, 0.2, 20) :: number) > 0, "curva a la izquierda: ruedas a la izquierda")
	check((WheelRig.steerFromYaw(carRig, 0.2, -5) :: number) < 0, "marcha atrás girando a la izquierda: ruedas a la derecha")
	check(near(WheelRig.steerFromYaw(carRig, 50, 2) :: number, max), "un giro brusco (choque, derrape) se queda en el tope")
	check(WheelRig.steerFromYaw(carRig, 0.5, 0.3) == nil, "casi parado: el volante se queda como estaba")
	check(near(WheelRig.yawBetween(Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0)), math.pi / 2), "giro entre direcciones: izquierda = +90°")
	-- Con el volante girado, la rueda de delante mira hacia allí y la de atrás no
	local front, rear
	for _, w in carRig.Wheels do
		if w.Front and w.Hub.Position.X > 0 then
			front = w
		elseif w.Rear and w.Hub.Position.X > 0 then
			rear = w
		end
	end
	local steer = WheelRig.steerFromInput(carRig, 1)
	local look = WheelRig.hubPose(front, steer).RightVector -- (el eje de la rueda)
	check(near(math.abs(look.Z), math.sin(WheelRig.MaxSteer.Coche), 1e-4), "la rueda de delante gira sobre sí misma el ángulo del volante")
	check(cfNear(WheelRig.hubPose(rear, steer), rear.Hub), "la de atrás no gira con el volante")
	check((WheelRig.hubPose(front, steer).Position - front.Hub.Position).Magnitude < 1e-5, "y gira en su sitio (no se sale del paso de rueda)")
end

---------------------------------------------------------------------
print("Freno de mano")
---------------------------------------------------------------------
check(WheelRig.locked(true, true, 20), "en marcha con freno de mano: las de atrás bloqueadas (derrapa)")
check(not WheelRig.locked(false, true, 20), "las de delante siguen rodando")
check(not WheelRig.locked(true, true, 1), "casi parado no se nota (no bloquea)")
check(not WheelRig.locked(true, false, 20), "sin freno de mano ruedan")

---------------------------------------------------------------------
print("LOD (solo cerca, a la vista y como mucho unos cuantos)")
---------------------------------------------------------------------
do
	local cam = CFrame.new(0, 10, 0) -- mirando a −Z
	check(WheelRig.visible(cam, math.rad(70), 16 / 9, Vector3.new(0, 0, -60), 10), "delante de la cámara: se ve")
	check(not WheelRig.visible(cam, math.rad(70), 16 / 9, Vector3.new(0, 0, 80), 10), "detrás de la cámara: no")
	check(not WheelRig.visible(cam, math.rad(70), 16 / 9, Vector3.new(400, 0, -60), 10), "muy a un lado: no")
	local list = {}
	for i = 1, 20 do
		table.insert(list, { Key = "near" .. i, Position = Vector3.new(0, 0, -10 * i), Visible = true })
	end
	table.insert(list, { Key = "far", Position = Vector3.new(0, 0, -400), Visible = true })
	table.insert(list, { Key = "hidden", Position = Vector3.new(0, 0, -5), Visible = false })
	table.insert(list, { Key = "mine", Position = Vector3.new(0, 0, 900), Visible = false, Forced = true })
	local picked = WheelRig.pick(list, Vector3.zero)
	check(#picked == WheelRig.MAX_VEHICLES, "como mucho " .. WheelRig.MAX_VEHICLES .. " vehículos a la vez")
	check(picked[1] == "mine", "el tuyo siempre (aunque la cámara no lo vea)")
	check(table.find(picked, "far") == nil, "lejos (más de " .. WheelRig.RANGE .. " studs): no se anima")
	check(table.find(picked, "hidden") == nil, "fuera de la vista: no se anima")
	check(picked[2] == "near1" and table.find(picked, "near20") == nil, "los más cercanos primero")
end

---------------------------------------------------------------------
print("Ruedas de todos los vehículos")
---------------------------------------------------------------------
local EXPECT = {
	Coche = { Wheels = 4, Front = 2, Steers = true },
	Patrulla = { Wheels = 4, Front = 2, Steers = true },
	Autobus = { Wheels = 4, Front = 2, Steers = true },
	Camion = { Wheels = 6, Front = 2, Steers = true },
	Bomberos = { Wheels = 6, Front = 2, Steers = true },
	Moto = { Wheels = 2, Front = 1, Steers = true },
	Bici = { Wheels = 2, Front = 1, Steers = false },
	Patinete = { Wheels = 2, Front = 1, Steers = false },
	Monopatin = { Wheels = 4, Front = 2, Steers = false },
}
local function checkRig(label: string, infos: { any }, kind: string, expect: { [string]: any })
	local rig = WheelRig.find(infos, kind)
	local front, rear, assigned, steerParts = 0, 0, 0, 0
	for _, w in rig.Wheels do
		front += if w.Front then 1 else 0
		rear += if w.Rear then 1 else 0
		assigned += #w.Spin
		steerParts += #w.Steer
	end
	local spinNamed = 0
	for _, info in infos do
		if WheelRig.SpinNames[info.Name] then
			spinNamed += 1
		end
	end
	check(#rig.Wheels == expect.Wheels and front == expect.Front and rear == expect.Wheels - expect.Front and rig.Steers == expect.Steers,
		label .. ": " .. #rig.Wheels .. " ruedas (" .. front .. " delante" .. (if rig.Steers then ", giran con el volante" else "") .. ")")
	check(assigned == spinNamed, label .. ": todas las piezas de las ruedas giran con la suya (" .. assigned .. "/" .. spinNamed .. ")")
	if kind == "Moto" then
		check(steerParts >= 3, label .. ": la horquilla, el guardabarros y la pinza giran con la rueda de delante (" .. steerParts .. ")")
	end
	-- Cada rueda con algo que se vea girar (radios, tuercas o llanta del taller), salvo el monopatín
	if kind ~= "Monopatin" then
		local marked = true
		for _, w in rig.Wheels do
			local has = false
			for _, i in w.Spin do
				local n = infos[i].Name
				if n == "Spoke" or n == "Nut" or n == "Mod_RimSpoke" then
					has = true
				end
			end
			marked = marked and has
		end
		check(marked, label .. ": cada rueda tiene radios o tuercas (se ve que gira)")
	end
	return rig
end
for kind, expect in EXPECT do
	checkRig(kind, (infosOf(Rides.build(kind, nil, CF), CF)), kind, expect)
end
for _, variant in CarModel.Variants do
	checkRig("Coche del tráfico " .. variant, (infosOf(CarModel.build(nil, CF, Color3.new(1, 0, 0), { Variant = variant }), CF)), "Coche", EXPECT.Coche)
end
do
	local lite = CarModel.build(nil, CF, Color3.new(1, 0, 0), { Variant = "Compacto", Lite = true })
	local rig = WheelRig.find((infosOf(lite, CF)), "Coche")
	check(#rig.Wheels == 4, "coche aparcado ligero: también tiene sus 4 ruedas (si se conduce)")
end
check(WheelRig.Kinds.Lancha == nil and WheelRig.Kinds.Gaviota == nil, "los barcos no (su «Wheel» es el timón)")
check(WheelRig.TrafficKind.Car == "Coche" and WheelRig.TrafficKind.Moto == "Moto", "el tráfico usa los mismos tipos")

-- Llantas y bandas del taller (VehicleBuild): también giran
for _, case in { { "Coche", "Berlina", "Rims_Clasica5", "T_LetrasBlancas" }, { "Coche", "Todoterreno", "Rims_Malla", "T_BandaBlanca" }, { "Moto", nil, "Rims_Estrella6", nil } } do
	local kind, body = case[1], case[2]
	local model = if kind == "Coche" and body ~= "Berlina" then CarModel.build(nil, CF, Color3.new(1, 0, 0), { Name = "Coche", Variant = body, Interior = true }) else Rides.build(kind, nil, CF)
	local build = VehicleBuild.default()
	build.Rims = case[3]
	if case[4] then
		build.Tires = case[4]
	end
	local n = VehicleBuild.apply(model, build, { Kind = kind, Origin = CF })
	local infos = infosOf(model, CF)
	local mods = 0
	for _, info in infos do
		if WheelRig.SpinNames[info.Name] and string.sub(info.Name, 1, 4) == "Mod_" then
			mods += 1
		end
	end
	check(n > 0 and mods > 0, kind .. " " .. (body or "") .. " con " .. case[3] .. ": " .. mods .. " piezas del taller en las ruedas")
	checkRig(kind .. " " .. (body or "") .. " (taller)", infos, kind, EXPECT[kind])
end

---------------------------------------------------------------------
print("Controlador (Controllers/WheelSpin)")
---------------------------------------------------------------------
local own = { Model = nil :: any, Steer = 0, Handbrake = false }
mods.Driving = {
	current = function()
		return own.Model, own.Steer, 0, own.Handbrake
	end,
}
local fakeGame = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then
			return { Shared = { WheelRig = "WheelRig", Tyres = "Tyres" } }
		elseif name == "CollectionService" then
			return { GetTagged = function()
				return {}
			end }
		end
		return {}
	end,
}
local WheelSpin = load("src/client/Controllers/WheelSpin.luau", "WheelSpin", { game = fakeGame })

-- Física de un modelo: lo que nunca debe cambiar
local function physics(model: any): { string }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, table.concat({ d.Name, tostring(d.CanCollide), tostring(d.CanQuery), tostring(d.CanTouch), tostring(d.Anchored), tostring(d.Massless), tostring(d.Size), tostring(d:GetAttribute("Collide")) }, "|"))
		end
	end
	table.sort(out)
	return out
end
local function same(a: { string }, b: { string }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end
local world = Instance.new("Folder") -- (hace de workspace: un vehículo sin Parent se olvida)
local function cameraAt(target: any, distance: number)
	-- (mirando hacia −Z, un poco hacia abajo; sin CFrame.lookAt: en Lune falla hacia −Z)
	local eye = target + Vector3.new(0, 8, distance)
	return { CFrame = CFrame.new(eye) * CFrame.Angles(-math.atan2(8, distance), 0, 0), FieldOfView = 70, Aspect = 16 / 9 }
end

do
	local model = Rides.build("Coche", world, CF)
	local chassis = Rides.prepare(model, "Coche", CF)
	local before = physics(model)
	WheelSpin.lod(cameraAt(chassis.CFrame.Position, 40), nil, { model })
	local entry = WheelSpin._entry(model)
	check(entry ~= nil and entry.Active, "un coche cerca y a la vista se anima")
	WheelSpin.frame(1 / 60) -- (busca las ruedas)
	check(entry.Mode == "Weld" and entry.Rig ~= nil and #entry.Rig.Wheels == 4, "coche preparado: 4 ruedas soldadas a Chassis")
	local joints, disabled = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("Weld") and d.Name == "WheelSpinJoint" then
			joints += 1
		elseif d:IsA("WeldConstraint") then
			local ok, enabled = pcall(function()
				return d.Enabled
			end)
			if ok and enabled == false then
				disabled += 1
			end
		end
	end
	local spinCount = 0
	for _, w in entry.Rig.Wheels do
		spinCount += #w.Spin
	end
	check(joints == spinCount and disabled == spinCount, "cada pieza de rueda pasa a una Weld (" .. joints .. "); el resto sigue con su WeldConstraint")
	-- Avanza 1 stud hacia el morro
	local wheel = entry.Rig.Wheels[1]
	local joint = entry.Joints[wheel.Index]
	local rest = joint:GetAttribute("Rest")
	chassis.CFrame = chassis.CFrame * CFrame.new(0, 0, -1)
	WheelSpin.frame(1 / 60)
	local expected = WheelRig.advance(0, 1, wheel.Radius)
	check(near(wheel.Angle, expected, 1e-4), "al avanzar 1 stud la rueda gira 1/radio")
	check(cfNear(joint.C0, rest * CFrame.Angles(expected, 0, 0)), "la Weld de la rueda gira sobre su eje (C0)")
	-- Marcha atrás
	chassis.CFrame = chassis.CFrame * CFrame.new(0, 0, 1)
	WheelSpin.frame(1 / 60)
	check(near(wheel.Angle % (2 * math.pi), 0, 1e-6) or near(wheel.Angle, 2 * math.pi, 1e-6), "marcha atrás lo mismo: vuelve a como estaba")
	-- Freno de mano a 60 studs/s: las de atrás no giran
	model:SetAttribute("Handbrake", true)
	for _ = 1, 10 do
		chassis.CFrame = chassis.CFrame * CFrame.new(0, 0, -1)
		WheelSpin.frame(1 / 60)
	end
	local frontMoved, rearStill = true, true
	for _, w in entry.Rig.Wheels do
		if w.Rear then
			rearStill = rearStill and (near(w.Angle, 0, 1e-6) or near(w.Angle, 2 * math.pi, 1e-6))
		elseif not near(w.Angle, 0, 1e-6) then
			frontMoved = frontMoved and true
		else
			frontMoved = false
		end
	end
	check(rearStill and frontMoved, "freno de mano en marcha: las de atrás bloqueadas, las de delante ruedan")
	model:SetAttribute("Handbrake", false)
	-- Curva a la izquierda (otro jugador o el servidor): las de delante giran a la izquierda
	for _ = 1, 30 do
		chassis.CFrame = chassis.CFrame * CFrame.Angles(0, 0.004, 0) * CFrame.new(0, 0, -0.5)
		WheelSpin.frame(1 / 60)
	end
	check(entry.Steer > 0.05 and entry.Steer <= WheelRig.MaxSteer.Coche, "en una curva a la izquierda las ruedas de delante giran a la izquierda (" .. string.format("%.1f", math.deg(entry.Steer)) .. "°)")
	-- Tu coche: con tu volante (aunque estés parado)
	own.Model, own.Steer = model, 1
	for _ = 1, 60 do
		WheelSpin.frame(1 / 60)
	end
	check(near(entry.Steer, -WheelRig.MaxSteer.Coche, 0.01), "tu coche: las ruedas siguen tu volante, también parado")
	own.Model, own.Steer = nil, 0
	-- Teletransporte: no cuenta como rodar
	local angle = entry.Rig.Wheels[1].Angle
	chassis.CFrame = chassis.CFrame * CFrame.new(0, 0, -500)
	WheelSpin.frame(1 / 60)
	check(entry.Rig.Wheels[1].Angle == angle, "un salto (teletransporte) no hace girar las ruedas")
	-- Lejos: deja de animarse y todo vuelve a su sitio
	WheelSpin.lod(cameraAt(chassis.CFrame.Position + Vector3.new(0, 0, 900), 40), nil, { model })
	local restored = true
	for _, j in entry.Joints do
		restored = restored and cfNear(j.C0, j:GetAttribute("Rest"))
	end
	check(not entry.Active and restored, "lejos (más de " .. WheelRig.RANGE .. " studs): no se anima y las ruedas quedan en su sitio")
	check(same(before, physics(model)), "colisión, consultas, toque, anclaje, masa y tamaño de todas las piezas: iguales")
	-- Las piezas del taller se añaden con el coche ya animado: se vuelven a buscar
	WheelSpin.lod(cameraAt(chassis.CFrame.Position, 40), nil, { model })
	WheelSpin.frame(1 / 60)
	local build = VehicleBuild.default()
	build.Rims = "Rims_Clasica5"
	VehicleBuild.apply(model, build)
	entry.Dirty = true -- (en Roblox lo marca DescendantAdded)
	WheelSpin.frame(1 / 60)
	local modSpin = 0
	for _, w in entry.Rig.Wheels do
		for _, i in w.Spin do
			if string.sub(entry.Parts[i].Name, 1, 4) == "Mod_" then
				modSpin += 1
			end
		end
	end
	check(modSpin > 0, "llantas del taller puestas después: también giran (" .. modSpin .. " piezas)")
	-- Rueda pinchada (el servidor pone Flat_1L): baja y se ve la goma chafada; al repararla, vuelve
	local k1L
	for k, id in entry.Ids do
		if id == "1L" then
			k1L = k
		end
	end
	check(k1L ~= nil and entry.Rig.Wheels[k1L].Front and entry.Rig.Wheels[k1L].Hub.Position.X < 0, "las ruedas se llaman como en el servidor (1L = delante a la izquierda)")
	local before2 = physics(model)
	model:SetAttribute("Flat_1L", true)
	WheelSpin.lod(cameraAt(chassis.CFrame.Position, 40), nil, { model })
	chassis.CFrame = chassis.CFrame * CFrame.new(0, 0, -0.5)
	WheelSpin.frame(1 / 60)
	local w1 = entry.Rig.Wheels[k1L]
	local c0 = entry.Joints[w1.Index].C0
	local bulge = entry.Bulges[k1L]
	check(entry.Flat[k1L] and c0.Position.Y < w1.Hub.Position.Y - w1.Radius * 0.2 and bulge ~= nil and bulge.Part.CanCollide == false and bulge.Part.CanQuery == false,
		"pinchada: la rueda baja y aparece la goma chafada (sin colisión)")
	check(same(before2, physics(model)) or #physics(model) == #before2 + 1, "la física de las piezas del coche no cambia (solo se añade la goma, sin colisión)")
	model:SetAttribute("Flat_1L", nil)
	WheelSpin.lod(cameraAt(chassis.CFrame.Position, 40), nil, { model })
	WheelSpin.frame(1 / 60)
	check(not entry.Flat[k1L] and entry.Bulges[k1L] == nil and bulge.Part.Parent == nil, "reparada: la goma chafada se va y la rueda vuelve a su altura")
end

do
	-- Moto preparada: la horquilla gira con el volante; la pata de cabra no se toca
	local model = Rides.build("Moto", world, CF)
	local chassis = Rides.prepare(model, "Moto", CF)
	local before = physics(model)
	WheelSpin.lod(cameraAt(chassis.CFrame.Position, 20), nil, { model })
	own.Model, own.Steer = model, -1
	for _ = 1, 60 do
		WheelSpin.frame(1 / 60)
	end
	own.Model, own.Steer = nil, 0
	local entry = WheelSpin._entry(model)
	local fork
	for _, w in entry.Rig.Wheels do
		for _, i in w.Steer do
			if entry.Parts[i].Name == "Fork" then
				fork = entry.Joints[i]
			end
		end
	end
	check(fork ~= nil and not cfNear(fork.C0, fork:GetAttribute("Rest")), "moto: la horquilla gira con el manillar")
	local stand = model:FindFirstChild("Kickstand", true)
	check(stand and stand:FindFirstChild("WheelSpinJoint") == nil and stand:FindFirstChild("StandWeld") ~= nil, "la pata de cabra sigue con su soldadura (Rides.setStand)")
	check(same(before, physics(model)), "moto: la física de todas las piezas, igual")
end

do
	-- Patrulla de ronda (anclada, la mueve el servidor con PivotTo): se coloca pieza a pieza
	local model = Rides.build("Patrulla", world, CF)
	local body = model:FindFirstChild("Body")
	local before = physics(model)
	WheelSpin.lod(cameraAt(body.CFrame.Position, 40), nil, { model })
	WheelSpin.frame(1 / 60)
	local entry = WheelSpin._entry(model)
	check(entry.Mode == "Anchored" and #entry.Rig.Wheels == 4, "patrulla anclada: 4 ruedas (sin soldaduras)")
	-- El servidor la mueve 2 studs hacia delante (todas las piezas)
	local move = CF * CFrame.new(0, 0, -2) * CF:Inverse()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = move * d.CFrame
		end
	end
	WheelSpin.frame(1 / 60)
	local w = entry.Rig.Wheels[1]
	local wheelPart = entry.Parts[w.Index]
	check(near(w.Angle, WheelRig.advance(0, 2, w.Radius), 1e-4), "avanza 2 studs: la rueda gira 2/radio")
	check(cfNear(wheelPart.CFrame, body.CFrame * WheelRig.hubPose(w, entry.Steer)), "la rueda se coloca girada en su sitio")
	local welds = 0
	for _, d in model:GetDescendants() do
		if d:IsA("Weld") then
			welds += 1
		end
	end
	check(welds == 0 and same(before, physics(model)), "sin soldaduras nuevas y con la misma física")
	-- Fuera de la vista: vuelve a su sitio
	WheelSpin.lod(cameraAt(body.CFrame.Position + Vector3.new(0, 0, 900), 40), nil, { model })
	check(cfNear(wheelPart.CFrame, body.CFrame * w.Hub), "fuera de la vista: la rueda vuelve a su sitio")
end

do
	-- Un barco no se anima (aunque esté cerca)
	local boat = Rides.build("Lancha", world, CF)
	WheelSpin.lod(cameraAt(CF.Position, 30), nil, { boat })
	check(WheelSpin._entry(boat) == nil, "los barcos no se animan")
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
