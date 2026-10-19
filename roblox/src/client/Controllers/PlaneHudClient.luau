-- PlaneHudClient (cliente): el HUD de los aviones del aeroclub es el de la nave del espacio
-- (UI/AirCombatHud con el vehículo "Plane" de UI/ShipHudLayout: sin salto ni escudo). Queja del dueño:
-- «los controles del avión, la interfaz y todo, debe ser igual que el de las naves espaciales». Lo
-- llama Controllers/Flying cada fotograma con el avión activo; aquí se decide qué se actualiza y cuándo
-- (como Controllers/ShipHudClient):
--   * brújula (B) 30 veces por segundo: gira con el rumbo del avión; el rombo marca la pista o la misión;
--   * velocidad y MOTOR (arco de la izquierda), ESTRUCTURA (daños), ALTITUD, V/S, RUMBO, flaps · tren ·
--     frenos (setPlane), ranuras (H: FLAPS, TREN, FRENOS, CÁMARA, PALANCA, RALENTÍ, A TOPE, BAJARSE),
--     radar (D: pistas, otros aviones y la misión), la PISTA que queda (tarjeta OBJETIVO) y la ayuda
--     para despegar (Prompt y la flecha de la palanca) 10 veces por segundo;
--   * perfil (A), sitio (B), misiones (E), reloj y teclas 2 veces por segundo.
-- Lo puro (ranuras, teclas, la ayuda para despegar, el radar) lo prueban scripts/test-hud.luau y
-- scripts/test-flight.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Airport = require(ReplicatedStorage.Shared.Airport)
local Flight = require(ReplicatedStorage.Shared.Flight)
local AirCombatHud = require(script.Parent.Parent.UI.AirCombatHud)
local ShipHudLayout = require(script.Parent.Parent.UI.ShipHudLayout)

local PlaneHudClient = {}

PlaneHudClient.RadarRange = 2500
PlaneHudClient.Vehicle = "Plane" -- (el de UI/ShipHudLayout.Vehicles)
-- (acrobacias del dueño: «con los aviones y naves podamos hacer 360 verticales y horizontales»: ACRO,
-- LOOPING y TONEL en las ranuras 5-7; el freno de aparcamiento, el ralentí y la palanca siguen en B, MOTOR −
-- y ⚙️ Ajustes)
PlaneHudClient.SlotIds = { "Flaps", "Gear", "Camera", "Full", "Acro", "Loop", "Roll", "Exit" }

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local clocks = { Compass = 0, Fast = 0, Slow = 0 }
local lastDevice: string? = nil
local lastStick: boolean? = nil

function PlaneHudClient.reset()
	clocks.Compass, clocks.Fast, clocks.Slow = 0, 0, 0
	lastDevice, lastStick = nil, nil
end

-- Lo que dice el «?» del móvil
PlaneHudClient.TouchHelp = {
	{ Key = "Palanca", Text = "Tirar ↓ sube el morro · lados: girar" },
	{ Key = "MOTOR +", Text = "Más gas (mantener)" },
	{ Key = "MOTOR −", Text = "Menos gas (mantener)" },
	{ Key = "FRENOS", Text = "Frenar en tierra (mantener)" },
	{ Key = "Ranura 1", Text = "Flaps (despegar y aterrizar)" },
	{ Key = "Ranura 2", Text = "Tren: subir / bajar" },
	{ Key = "Ranura 3", Text = "Cámara: persecución / cabina" },
	{ Key = "Ranura 4", Text = "Motor a tope" },
	{ Key = "Ranura 5", Text = "ACRO: sin límites (loopings a mano)" },
	{ Key = "Ranura 6", Text = "LOOPING: 360° vertical (con altura)" },
	{ Key = "Ranura 7", Text = "TONEL: 360° de alabeo (palanca al lado)" },
	{ Key = "Ranura 8", Text = "Bajarse (parado en tierra)" },
	{ Key = "Despegar", Text = "Motor a tope y, pasada Vr, tira ↓" },
}

-- El HUD de los aviones (uno; Controllers/Flying lo crea al arrancar): el de la nave con el vehículo
-- "Plane", con su nombre (no se pisa con el de la nave) y sin mira
function PlaneHudClient.new(parent: Instance, touch: boolean): AirCombatHud.View
	local view = AirCombatHud.new(parent, touch, PlaneHudClient.Vehicle)
	view.Gui.Name = "PlaneHud"
	view.Overlay.Name = "PlaneOverlay"
	-- (la mirilla la pone update cada fotograma: setReticle; la fijación, solo con el cañón y un blanco)
	view.Cross.Visible = false
	view.LockBox.Visible = false
	AirCombatHud.setTouchHelp(view, "MANDOS DEL AVIÓN", PlaneHudClient.TouchHelp)
	return view
end

-- ¿Teclado, mando o táctil? (las teclas de las ranuras y la tarjeta de teclas)
function PlaneHudClient.device(): string
	if TOUCH then
		return "Touch"
	end
	local ok, last = pcall(function()
		return UserInputService:GetLastInputType()
	end)
	if ok and last and string.find(last.Name, "Gamepad") then
		return "Gamepad"
	end
	return "Keyboard"
end

function PlaneHudClient.distanceText(studs: number): string
	local m = math.max(0, studs) * Flight.METERS
	if m < 1000 then
		return ("%d m"):format(math.floor(m / 10 + 0.5) * 10)
	end
	return (string.gsub(("%.1f km"):format(m / 1000), "%.", ","))
end

---------------------------------------------------------------------
-- Lo puro
---------------------------------------------------------------------
export type SlotState = {
	Flaps: number,
	MaxFlaps: number,
	Gear: boolean,
	FixedGear: boolean,
	OnGround: boolean,
	Camera: string,
	PullUp: boolean, -- tirar hacia abajo sube el morro (lo normal)
	CanExit: boolean,
	Parking: boolean?, -- freno de aparcamiento puesto
	Throttle: number?,
	Acro: boolean?, -- modo acrobático
	Maneuver: string?, -- "Loop" | "Roll" en marcha
	ManeuverCool: number?, -- 0..1 de la recarga entre maniobras (1 = recién hecha)
}

-- Las 8 ranuras del avión (como ShipAbilities.slotViews para la nave; se tocan igual)
function PlaneHudClient.slots(st: SlotState): { { [string]: any } }
	local gearNote = if st.FixedGear then "Tren fijo" elseif st.OnGround then "En tierra" else nil
	local thr = st.Throttle or 0
	local cool = st.ManeuverCool or 0
	local function maneuverState(kind: string): string
		return if st.Maneuver == kind then "Active" elseif st.OnGround or cool > 0 then "Cooling" else "Ready"
	end
	return {
		{ Id = "Flaps", Glyph = "Flaps", Name = "FLAPS", Key = "F", Count = tostring(st.Flaps), State = if st.Flaps > 0 then "Active" else "Ready" },
		{ Id = "Gear", Glyph = "Tren", Name = if st.Gear then "TREN ↓" else "TREN ↑", Key = "G", Count = "", State = if st.FixedGear then "Locked" elseif st.Gear then "Active" else "Ready", Note = gearNote },
		{ Id = "Camera", Glyph = "Camara", Name = if st.Camera == "Cabina" then "CABINA" else "CÁMARA", Key = "C", Count = "", State = if st.Camera == "Cabina" then "Active" else "Ready" },
		{ Id = "Full", Glyph = "MotorMax", Name = "A TOPE", Key = "", Count = ("%d%%"):format(math.floor(thr * 100 + 0.5)), State = if thr >= 0.99 then "Active" else "Ready" },
		{ Id = "Acro", Glyph = "Acro", Name = if st.Acro then "ACRO ✓" else "ACRO", Key = "T", Count = "", State = if st.Acro then "Active" else "Ready" },
		{ Id = "Loop", Glyph = "Looping", Name = "LOOPING", Key = "L", Count = "", State = maneuverState("Loop"), Cool = if st.Maneuver then 0 else cool },
		{ Id = "Roll", Glyph = "Tonel", Name = "TONEL", Key = "R", Count = "", State = maneuverState("Roll"), Cool = if st.Maneuver then 0 else cool },
		{ Id = "Exit", Glyph = "Bajarse", Name = "BAJARSE", Key = "Esp", Count = "", State = if st.CanExit then "Ready" else "Cooling", Note = if st.CanExit then nil else "Para el avión" },
	}
end

-- Las dos listas de teclas (ordenador y mando): «MANDOS DEL AVIÓN» y «DESPEGAR Y ATERRIZAR»
PlaneHudClient.HintNames = { ZonaKeys = "MANDOS DEL AVIÓN", ZonaMoves = "DESPEGAR Y ATERRIZAR" }
function PlaneHudClient.hints(device: string, pullUp: boolean): ({ { Key: string, Text: string } }, { { Key: string, Text: string } })
	if device == "Gamepad" then
		return {
			{ Key = "Stick izq.", Text = if pullUp then "Atrás sube el morro" else "Adelante sube el morro" },
			{ Key = "RT / LT", Text = "Motor + / −" },
			{ Key = "RB / LB", Text = "Timón" },
			{ Key = "X", Text = "Frenos" },
			{ Key = "↓", Text = "Flaps" },
			{ Key = "Y", Text = "Tren" },
			{ Key = "R3", Text = "Cámara" },
			{ Key = "A", Text = "Bajarse (parado)" },
			{ Key = "L3", Text = "Modo acrobático" },
			{ Key = "↑ / ← →", Text = "Looping / tonel" },
		}, {
			{ Key = "RT", Text = "1. Motor a tope" },
			{ Key = "Stick ↓", Text = "2. Pasada Vr, tira hacia atrás" },
			{ Key = "Y", Text = "3. Tren arriba (o solo)" },
			{ Key = "↓", Text = "Aterrizar: flaps 2, despacio" },
			{ Key = "X", Text = "En la pista: frena" },
		}
	end
	return {
		{ Key = "W / S", Text = "Morro (W sube)" },
		{ Key = "A / D", Text = "Alas (girar)" },
		{ Key = "Q / E", Text = "Timón" },
		{ Key = "Shift", Text = "Motor +" },
		{ Key = "Ctrl", Text = "Motor −" },
		{ Key = "B", Text = "Frenos" },
		{ Key = "F", Text = "Flaps" },
		{ Key = "G", Text = "Tren" },
		{ Key = "C", Text = "Cámara" },
		{ Key = "Espacio", Text = "Bajarse (parado)" },
		{ Key = "T", Text = "Modo acrobático" },
		{ Key = "L / R", Text = "Looping / tonel" },
	}, {
		{ Key = "Shift", Text = "1. Motor a tope" },
		{ Key = "W", Text = "2. Pasada Vr, sube el morro" },
		{ Key = "G", Text = "3. Tren arriba (o solo)" },
		{ Key = "F", Text = "Aterrizar: flaps 2, despacio" },
		{ Key = "B", Text = "En la pista: frena" },
		{ Key = "H", Text = "Plegar estas listas" },
	}
end

-- La ayuda para despegar (letrero encima de las ranuras y la flecha de la palanca). Devuelve el letrero
-- (título, texto, progreso 0..1, color) y la flecha de la palanca (dirección y texto), o nil.
export type Cue = { Title: string, Sub: string, Progress: number, Color: Color3, Stick: string?, StickText: string? }
function PlaneHudClient.cue(sim: Flight.State, spec: Flight.Spec, pullUp: boolean, device: string): Cue?
	if sim.Crashed or not sim.OnGround then
		return nil
	end
	local pull = if pullUp then "Down" else "Up"
	local how = if device == "Touch" then (if pullUp then "TIRA HACIA ABAJO" else "EMPUJA HACIA ARRIBA")
		elseif device == "Gamepad" then (if pullUp then "STICK HACIA ATRÁS" else "STICK HACIA DELANTE")
		else "PULSA W"
	local orange = Color3.fromRGB(255, 160, 60)
	if sim.Cue == "Rotar" then
		return {
			Title = how .. " PARA DESPEGAR",
			Sub = ("Ya vas a %d km/h: sube el morro"):format(math.floor(sim.Speed + 0.5)),
			Progress = 1,
			Color = Color3.fromRGB(120, 240, 140),
			Stick = pull,
			StickText = if pullUp then "TIRA ↓ PARA SUBIR" else "EMPUJA ↑ PARA SUBIR",
		}
	end
	if sim.Warn == "FinPista" then
		return { Title = "⚠ FIN DE PISTA", Sub = if sim.Speed >= spec.Vr * 0.8 then how .. " o frena (B)" else "Frena (FRENOS) o gira", Progress = math.clamp((sim.RunwayLeft or 0) / 400, 0, 1), Color = Color3.fromRGB(255, 80, 70), Stick = if sim.Speed >= spec.Vr * 0.9 then pull else nil, StickText = nil }
	end
	local motor = if device == "Touch" then "MOTOR +" elseif device == "Gamepad" then "RT" else "Shift"
	if sim.Throttle < 0.3 and sim.Speed < 10 then
		return { Title = "PARA DESPEGAR: " .. motor .. " A TOPE", Sub = ("En la pista, a %d km/h, %s"):format(spec.Vr, string.lower(how)), Progress = sim.Throttle, Color = orange, Stick = nil, StickText = nil }
	end
	if sim.Throttle >= 0.5 and sim.Speed >= 10 and sim.Speed < spec.Vr * 0.95 and sim.RunwayLeft ~= nil then
		return { Title = ("ACELERANDO · %d / %d km/h"):format(math.floor(sim.Speed + 0.5), spec.Vr), Sub = "Al llegar, " .. string.lower(how) .. " para despegar", Progress = sim.Speed / spec.Vr, Color = orange, Stick = nil, StickText = nil }
	end
	return nil
end

-- La pista más cercana (centro) y su nombre
function PlaneHudClient.nearestRunway(pos: Vector3): (string, Vector3)
	local best, bestPos, bestD = "", Vector3.zero, math.huge
	for _, r in Airport.Runways do
		local R = r.Rect
		local c = Vector3.new((R.X0 + R.X1) / 2, Airport.GROUND, R.Z)
		local d = (c - pos).Magnitude
		if d < bestD then
			best, bestPos, bestD = r.Name, c, d
		end
	end
	return best, bestPos
end

-- Lo que sale en el radar: las cabeceras de las pistas, los otros aviones y la misión
function PlaneHudClient.contacts(pos: Vector3, planes: { Vector3 }, mission: Vector3?): { ShipHudLayout.Contact }
	local out = {}
	for _, r in Airport.Runways do
		local R = r.Rect
		table.insert(out, { Kind = "Pista", Pos = Vector3.new(R.X0, Airport.GROUND, R.Z), Id = r.Id .. "O" })
		table.insert(out, { Kind = "Pista", Pos = Vector3.new(R.X1, Airport.GROUND, R.Z), Id = r.Id .. "E" })
	end
	for _, p in planes do
		if (p - pos).Magnitude > 20 then
			table.insert(out, { Kind = "Avion", Pos = p })
		end
	end
	if mission then
		table.insert(out, { Kind = "Mision", Pos = mission })
	end
	return out
end

-- Dónde estás (zona B)
function PlaneHudClient.place(pos: Vector3): string
	local L = Airport.Land
	if pos.X >= L.X0 - 300 and pos.X <= L.X1 + 300 and pos.Z >= L.Z0 - 300 and pos.Z <= L.Z1 + 300 then
		return Airport.Name
	end
	local S = Airport.Strip
	if math.abs(pos.X - (S.X0 + S.X1) / 2) < 600 and math.abs(pos.Z - S.Z) < 600 then
		return Airport.Places.Gaviotas.Name
	end
	return "Cielo de Valmar"
end

---------------------------------------------------------------------
-- Con Roblox
---------------------------------------------------------------------
local planesAt = -math.huge
local planeList: { BasePart } = {}
local function otherPlanes(own: Model): { Vector3 }
	local now = os.clock()
	if now - planesAt > 1 then
		planesAt = now
		table.clear(planeList)
		local CollectionService = game:GetService("CollectionService")
		for _, tag in { "Plane", "PilotPlane" } do
			for _, m in CollectionService:GetTagged(tag) do
				if m ~= own and m:IsA("Model") then
					local root = m.PrimaryPart or m:FindFirstChild("Root")
					if root and root:IsA("BasePart") then
						table.insert(planeList, root)
					end
				end
			end
		end
	end
	local out = {}
	for _, root in planeList do
		if root.Parent then
			table.insert(out, root.Position)
		end
	end
	return out
end

local function objective(): { [string]: any }?
	local ok, obj = pcall(function()
		return require(script.Parent.Parent.UI.Hud).objective()
	end)
	return if ok and type(obj) == "table" then obj else nil
end

-- El blanco más centrado delante del morro (puro): índice en `positions` o nil. Solo lo que está a
-- menos de maxDeg grados del morro y a menos de maxDist studs.
function PlaneHudClient.pickTarget(nose: CFrame, positions: { Vector3 }, maxDeg: number?, maxDist: number?): number?
	local best, bestAngle = nil, math.rad(maxDeg or 12)
	for i, p in positions do
		local d = p - nose.Position
		local dist = d.Magnitude
		if dist > 1 and dist <= (maxDist or 900) then
			local angle = math.acos(math.clamp(d.Unit:Dot(nose.LookVector), -1, 1))
			if angle <= bestAngle then
				best, bestAngle = i, angle
			end
		end
	end
	return best
end

PlaneHudClient.NoseDistance = 500 -- studs por delante del morro a los que apunta la mirilla

-- La mirilla del centro (cada fotograma): hacia donde apunta el morro; con el CAÑÓN de la invasión
-- armado, la mira con su aro y la fijación sobre el alienígena más centrado; si no, el marcador de
-- trayectoria
local function reticle(view: AirCombatHud.View, a: { [string]: any })
	local root = a.Root
	local cam = workspace.CurrentCamera
	if not (root and root.Parent and cam) then
		AirCombatHud.setReticle(view, AirCombatHud.reticleMode(true, false), nil)
		return
	end
	local ok, armed = pcall(function()
		return require(script.Parent.InvasionClient).gunReady()
	end)
	armed = ok and armed == true
	local nose = root.CFrame
	local p, onScreen = cam:WorldToViewportPoint(nose.Position + nose.LookVector * PlaneHudClient.NoseDistance)
	local point = if onScreen then Vector2.new(p.X, p.Y) else nil
	AirCombatHud.setReticle(view, AirCombatHud.reticleMode(true, armed), point)
	local target: Instance? = nil
	if armed then
		local okA, aliens = pcall(function()
			return require(script.Parent.InvasionClient).aliens()
		end)
		if okA and type(aliens) == "table" then
			local positions = {}
			for i, m in aliens do
				local okP, pos = pcall(function()
					return (m :: any):GetPivot().Position
				end)
				positions[i] = if okP then pos else Vector3.new(0, -1e6, 0)
			end
			local i = PlaneHudClient.pickTarget(nose, positions, 12, 900)
			if i then
				target = aliens[i]
				local sp, vis = cam:WorldToViewportPoint(positions[i])
				view.LockBox.Visible = vis
				view.LockBox.Position = UDim2.fromOffset(sp.X, sp.Y)
				if vis then
					AirCombatHud.setLock(view, true, { Name = (target :: Instance).Name, Dist = ("%d m"):format(math.floor((positions[i] - nose.Position).Magnitude * Flight.METERS + 0.5)) })
				end
			end
		end
	end
	if not target and view.LockBox.Visible then
		view.LockBox.Visible = false
	end
end

-- a = el avión de Controllers/Flying (Sim, Spec, Kind, Model, Camera, Brake, PullUp, CanExit, Id)
function PlaneHudClient.update(view: AirCombatHud.View, a: { [string]: any }, dt: number)
	pcall(reticle, view, a)
	clocks.Compass += dt
	clocks.Fast += dt
	clocks.Slow += dt
	local sim: Flight.State = a.Sim
	local spec: Flight.Spec = a.Spec
	local pos = sim.Pos
	local heading = Flight.heading(sim)
	local function destination(): (string, Vector3)
		local obj = objective()
		if obj and typeof(obj.Target) == "Vector3" then
			return obj.Title or "Misión", obj.Target
		end
		return PlaneHudClient.nearestRunway(pos)
	end
	if clocks.Compass >= 1 / 30 then
		clocks.Compass = 0
		local _, dest = destination()
		local d = dest - pos
		local bearing = if Vector2.new(d.X, d.Z).Magnitude > 30 then (math.deg(math.atan2(d.X, -d.Z)) % 360 + 360) % 360 else nil
		AirCombatHud.setCompass(view, heading, bearing)
	end
	local device = PlaneHudClient.device()
	if clocks.Fast >= 0.1 then
		clocks.Fast = 0
		AirCombatHud.setPlane(view, {
			Speed = sim.Speed,
			SpeedMax = spec.Vmax,
			PullUp = a.PullUp ~= false,
			Altitude = math.max(0, pos.Y - Airport.GROUND) * Flight.METERS,
			Heading = heading,
			Climb = sim.Climb * Flight.METERS,
			Throttle = sim.Throttle,
			Gear = sim.Gear,
			FixedGear = spec.FixedGear,
			Flaps = sim.Flaps,
			Brake = a.Brake == true and sim.OnGround,
			Health = sim.Health,
			Warn = sim.Warn,
			OnGround = sim.OnGround,
			Stalled = sim.Stalled,
			Ceiling = Flight.Bounds.Ceiling * Flight.METERS,
		})
		AirCombatHud.setSlots(view, PlaneHudClient.slots({
			Flaps = sim.Flaps,
			MaxFlaps = spec.Flaps,
			Gear = sim.Gear,
			FixedGear = spec.FixedGear,
			OnGround = sim.OnGround,
			Camera = a.Camera,
			PullUp = a.PullUp ~= false,
			CanExit = a.CanExit == true,
			Parking = a.Parking == true,
			Throttle = sim.Throttle,
			Acro = sim.Acro == true,
			Maneuver = if sim.Maneuver then sim.Maneuver.Kind else nil,
			ManeuverCool = math.clamp(((sim.ManeuverReady or 0) - (sim.Time or 0)) / Flight.ManeuverCooldown, 0, 1),
		}), device)
		-- La tarjeta OBJETIVO es la PISTA: cuánta queda por delante (o la más cercana)
		local rwName, rwPos = PlaneHudClient.nearestRunway(pos)
		local left = sim.RunwayLeft
		AirCombatHud.setTarget(view, {
			Name = rwName,
			Dist = if left then ("Quedan %s"):format(PlaneHudClient.distanceText(left)) else PlaneHudClient.distanceText((rwPos - pos).Magnitude),
			Health = if left then math.clamp(left / 900, 0, 1) else 1,
		})
		local yawCF = CFrame.new(pos) * CFrame.Angles(0, sim.Yaw, 0)
		local obj = objective()
		local mission = if obj and typeof(obj.Target) == "Vector3" then obj.Target else nil
		local range = PlaneHudClient.RadarRange
		AirCombatHud.radar(view, ShipHudLayout.blips(yawCF, PlaneHudClient.contacts(pos, otherPlanes(a.Model), mission), range, AirCombatHud.MaxBlips), range, heading)
		local c = PlaneHudClient.cue(sim, spec, a.PullUp ~= false, device)
		local m = sim.Maneuver
		if m then
			-- (la maniobra en marcha, con su progreso)
			AirCombatHud.setPrompt(view, if m.Kind == "Loop" then "🔄 LOOPING" else "🌀 TONEL", "Maniobra asistida: suelta los mandos", m.T / m.Dur, Color3.fromRGB(110, 230, 255))
		elseif c then
			AirCombatHud.setPrompt(view, c.Title, c.Sub, c.Progress, c.Color)
		else
			AirCombatHud.setPrompt(view, nil)
		end
		a.CueStick, a.CueText = if c then c.Stick else nil, if c then c.StickText else nil
	end
	if clocks.Slow >= 0.5 then
		clocks.Slow = 0
		local Format = require(ReplicatedStorage.Shared.Format)
		local kindName = if a.Kind == "Avion" then "AVIÓN DE LÍNEA" else "AVIONETA"
		AirCombatHud.setProfile(view, {
			UserId = player.UserId,
			Name = player.DisplayName,
			Level = tonumber(player:GetAttribute("Level")) or 1,
			Money = Format.money(tonumber(player:GetAttribute("Money")) or 0),
			Res1 = "✈ " .. tostring(a.Id or ""),
			Res1Icon = "avion", -- (con los sprites del HUD: UI/HudArt)
			Resources = { { Text = ("⛽ %d%%"):format(math.floor(sim.Throttle * 100 + 0.5)), Icon = "combustible" }, { Text = ("🛬 %s"):format(if sim.Gear then "↓" else "↑"), Icon = "tren" } },
			Ship = ("%s %s · %s"):format(kindName, tostring(a.Id or ""), if sim.OnGround then "EN TIERRA" else "EN VUELO"),
		})
		AirCombatHud.setClock(view, os.date("%H:%M") :: string)
		local name, dest = destination()
		AirCombatHud.setNav(view, {
			System = "✈ Espacio aéreo de Valmar",
			Zone = PlaneHudClient.place(pos),
			Detail = ("ALT %d m"):format(math.floor(math.max(0, pos.Y - Airport.GROUND) * Flight.METERS + 0.5)),
			Dest = ("▶ %s · %s"):format(name, PlaneHudClient.distanceText((dest - pos).Magnitude)),
			Quantum = "",
		})
		local rows = {}
		local obj = objective()
		if obj then
			table.insert(rows, {
				Kind = if obj.Kind == "TRABAJO" or obj.Kind == "ENCARGO" then obj.Kind else "PRINCIPAL",
				Title = obj.Title,
				Step = obj.Later or obj.Step,
				Right = if typeof(obj.Target) == "Vector3" then PlaneHudClient.distanceText((obj.Target - pos).Magnitude) else "",
			})
		end
		local rwName, rwPos = PlaneHudClient.nearestRunway(pos)
		table.insert(rows, {
			Kind = "VUELO",
			Title = rwName,
			Step = if sim.OnGround then ("Despega a %d km/h · tren y flaps en las ranuras"):format(spec.Vr) else "Para aterrizar: tren abajo, flaps y despacio",
			Right = PlaneHudClient.distanceText((rwPos - pos).Magnitude),
			Color = Color3.fromRGB(110, 230, 255),
		})
		AirCombatHud.setMissions(view, rows)
		local pullUp = a.PullUp ~= false
		if device ~= lastDevice or pullUp ~= lastStick then
			lastDevice, lastStick = device, pullUp
			if device ~= "Touch" then
				local flight, special = PlaneHudClient.hints(device, pullUp)
				AirCombatHud.setHintLists(view, flight, special, PlaneHudClient.HintNames)
			end
		end
	end
end

return PlaneHudClient
