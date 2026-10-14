-- PlaneHudClient (cliente): el HUD de los aviones del aeroclub es el de la nave del espacio
-- (UI/AirCombatHud con Variant = "Plane", zonas de UI/ShipHudLayout). Queja del dueño: «los controles
-- del avión, la interfaz y todo, debe ser igual que el de las naves espaciales». Lo llama
-- Controllers/Flying cada fotograma con el avión activo; aquí se decide qué se actualiza y cuándo (como
-- Controllers/ShipHudClient):
--   * brújula (B) 30 veces por segundo: gira con el rumbo del avión; el rombo marca la pista o la misión;
--   * panel (C: VEL, MOTOR, ALTITUD, V/S, ESTADO, RUMBO, flaps · tren · frenos), ranuras (H), radar (D:
--     pistas, otros aviones y la misión) y la ayuda para despegar (Prompt y la flecha de la palanca)
--     10 veces por segundo;
--   * perfil (A), sitio (B), misiones (E) y teclas (G) 2 veces por segundo.
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
PlaneHudClient.SlotIds = { "Flaps", "Gear", "Camera", "Stick", "Exit" }

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local clocks = { Compass = 0, Fast = 0, Slow = 0 }
local lastDevice: string? = nil
local lastStick: boolean? = nil

function PlaneHudClient.reset()
	clocks.Compass, clocks.Fast, clocks.Slow = 0, 0, 0
	lastDevice, lastStick = nil, nil
end

-- El HUD de los aviones (uno; Controllers/Flying lo crea al arrancar)
function PlaneHudClient.new(parent: Instance, touch: boolean): AirCombatHud.View
	return AirCombatHud.new(parent, touch, { Variant = "Plane", Slots = ShipHudLayout.PlaneSlots, Buttons = ShipHudLayout.PlaneButtonSlots })
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
}

-- Las 5 ranuras del avión (como ShipAbilities.slotViews para la nave)
function PlaneHudClient.slots(st: SlotState): { { [string]: any } }
	local gearNote = if st.FixedGear then "Tren fijo" elseif st.OnGround then "En tierra" else nil
	return {
		{ Id = "Flaps", Glyph = "Flaps", Name = "FLAPS", Key = "F", Count = tostring(st.Flaps), State = if st.Flaps > 0 then "Active" else "Ready" },
		{ Id = "Gear", Glyph = "Tren", Name = if st.Gear then "TREN ↓" else "TREN ↑", Key = "G", Count = "", State = if st.FixedGear then "Locked" elseif st.Gear then "Active" else "Ready", Note = gearNote },
		{ Id = "Camera", Glyph = "Camara", Name = if st.Camera == "Cabina" then "CABINA" else "CÁMARA", Key = "C", Count = "", State = if st.Camera == "Cabina" then "Active" else "Ready" },
		{ Id = "Stick", Glyph = "Palanca", Name = if st.PullUp then "↓ SUBE" else "↑ SUBE", Key = "", Count = "", State = "Ready" },
		{ Id = "Exit", Glyph = "Bajarse", Name = "BAJARSE", Key = "Esp", Count = "", State = if st.CanExit then "Ready" else "Cooling", Note = if st.CanExit then nil else "Para el avión" },
	}
end

-- La tarjeta de teclas (ordenador y mando)
function PlaneHudClient.hints(device: string, pullUp: boolean): { { Key: string, Text: string } }
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
		}
	end
	return {
		{ Key = "W / S", Text = "Morro (W sube)" },
		{ Key = "A / D", Text = "Alas (girar)" },
		{ Key = "Shift", Text = "Motor +" },
		{ Key = "Ctrl", Text = "Motor −" },
		{ Key = "B", Text = "Frenos" },
		{ Key = "Q / E", Text = "Timón" },
		{ Key = "F / G", Text = "Flaps / tren" },
		{ Key = "C · Esp", Text = "Cámara · bajarse" },
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

-- a = el avión de Controllers/Flying (Sim, Spec, Kind, Model, Camera, Brake, PullUp, CanExit, Id)
function PlaneHudClient.update(view: AirCombatHud.View, a: { [string]: any }, dt: number)
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
		}), device)
		local yawCF = CFrame.new(pos) * CFrame.Angles(0, sim.Yaw, 0)
		local obj = objective()
		local mission = if obj and typeof(obj.Target) == "Vector3" then obj.Target else nil
		local range = PlaneHudClient.RadarRange
		AirCombatHud.radar(view, ShipHudLayout.blips(yawCF, PlaneHudClient.contacts(pos, otherPlanes(a.Model), mission), range, AirCombatHud.MaxBlips), range, heading)
		local c = PlaneHudClient.cue(sim, spec, a.PullUp ~= false, device)
		if c then
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
			NoChispas = true,
			Ship = ("%s %s · %s"):format(kindName, tostring(a.Id or ""), if sim.OnGround then "EN TIERRA" else "EN VUELO"),
		})
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
				AirCombatHud.setHints(view, PlaneHudClient.hints(device, pullUp))
			end
		end
	end
end

return PlaneHudClient
