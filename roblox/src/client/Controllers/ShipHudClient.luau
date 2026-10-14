-- ShipHudClient (cliente): llena el HUD de la nave (UI/AirCombatHud, zonas A-J) con datos de verdad,
-- a ritmo limitado (Espacio AAA, docs/espacio-aaa/diseno.md). Lo llama Controllers/AirCombatClient cada
-- fotograma con la nave activa; aquí se decide qué se actualiza y cuándo:
--   * brújula (zona B) 30 veces por segundo: gira con el rumbo real del Root;
--   * panel (C), ranuras (H) y radar (D) 10 veces por segundo;
--   * perfil (A), navegación (B: zona y destino), misiones (E) y teclas (G) 2 veces por segundo.
-- Los números salen del servidor («State»: escudo, casco, misiles, energía, recargas…; «Nav»: Chispas,
-- misiones, eventos), de la simulación local (velocidad, impulso, rumbo) y de la historia
-- (UI/Hud.objective: la misión principal).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AC = ReplicatedStorage.Shared.AirCombat
local Cosmos = ReplicatedStorage.Shared.Cosmos
local ShipFlight = require(AC.ShipFlight)
local ShipWeapons = require(AC.ShipWeapons)
local ShipAbilities = require(AC.ShipAbilities)
local ShipKeys = require(AC.ShipKeys)
local Hyperspeed = require(AC.Hyperspeed)
local ShipCombat = require(AC.ShipCombat)
local NavInfo = require(Cosmos.NavInfo)
local Stations = require(Cosmos.Stations)
local Zone = require(Cosmos.Zone)
local PlanetBodies = require(Cosmos.PlanetBodies)
local Format = require(ReplicatedStorage.Shared.Format)
local AirCombatHud = require(script.Parent.Parent.UI.AirCombatHud)
local ShipHudLayout = require(script.Parent.Parent.UI.ShipHudLayout)

local ShipHudClient = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local clocks = { Compass = 0, Fast = 0, Slow = 0 }
local othersAt = -math.huge
local othersList: { BasePart } = {}
local lastDevice: string? = nil

function ShipHudClient.reset()
	clocks.Compass, clocks.Fast, clocks.Slow = 0, 0, 0
	lastDevice = nil
end

-- ¿Teclado, mando o táctil? (para las pistas y las teclas de las ranuras)
function ShipHudClient.device(): string
	if TOUCH then
		return "Touch"
	end
	local last = UserInputService:GetLastInputType()
	if string.find(last.Name, "Gamepad") then
		return "Gamepad"
	end
	return "Keyboard"
end

-- El destino que se enseña (zona B y el rombo de la brújula): el salto que carga, el último elegido,
-- la primera misión con sitio o la estación más cercana
function ShipHudClient.destination(a: any): (string?, Vector3?)
	if a.Quantum and a.Quantum.Pos then
		return a.Quantum.Name, a.Quantum.Pos
	end
	if a.QuantumSel and a.QuantumSel.Pos then
		return a.QuantumSel.Name, a.QuantumSel.Pos
	end
	local nav = a.Nav
	if nav and type(nav.Missions) == "table" then
		for _, m in nav.Missions do
			if typeof(m.Target) == "Vector3" then
				return m.TargetName or m.Title, m.Target
			end
		end
	end
	if a.World == "Cosmos" and a.Root then
		local st = Stations.nearest(a.Root.Position)
		return st.Name, st.Dock
	end
	return nil, nil
end

-- Lo que hay alrededor para el radar
function ShipHudClient.contacts(a: any, list: { any }): { ShipHudLayout.Contact }
	local out = {}
	local lock = a.Lock
	for _, t in list do
		table.insert(out, { Kind = if lock and lock.Locked and lock.Target == t.Id then "Fijado" else "Enemigo", Pos = t.Pos, Id = t.Id })
	end
	-- Otras naves (otros pilotos; la lista se mira una vez por segundo)
	local now = os.clock()
	if now - othersAt > 1 then
		othersAt = now
		table.clear(othersList)
		for _, m in workspace:GetChildren() do
			if m:IsA("Model") and string.sub(m.Name, 1, 5) == "Nave_" and m ~= a.Ship and m.PrimaryPart then
				table.insert(othersList, m.PrimaryPart)
			end
		end
	end
	for _, root in othersList do
		if root.Parent then
			-- (camuflados: los radares de los demás solo los ven muy cerca)
			local model = root.Parent
			local cloaked = model and model:GetAttribute("Cloak") ~= nil
			if not cloaked or (root.Position - a.Root.Position).Magnitude <= ShipCombat.Cloak.Detect then
				table.insert(out, { Kind = "Aliado", Pos = root.Position })
			end
		end
	end
	local drone = a.Server and a.Server.Drone
	if type(drone) == "table" and typeof(drone.Pos) == "Vector3" then
		table.insert(out, { Kind = "Aliado", Pos = drone.Pos })
	end
	if a.World == "Cosmos" then
		for _, st in Stations.List do
			table.insert(out, { Kind = "Estacion", Pos = st.Center })
		end
		for _, f in Zone.Fields do
			table.insert(out, { Kind = "Campo", Pos = f.Center, Radius = f.Radius })
		end
		for _, b in PlanetBodies.List do
			table.insert(out, { Kind = "Planeta", Pos = b.Center, Radius = b.Radius })
		end
		table.insert(out, { Kind = "Baliza", Pos = NavInfo.Beacon })
		local nav = a.Nav
		if nav and type(nav.Missions) == "table" then
			for _, m in nav.Missions do
				if typeof(m.Target) == "Vector3" then
					table.insert(out, { Kind = "Mision", Pos = m.Target })
				end
			end
		end
		local _, dest = ShipHudClient.destination(a)
		if a.QuantumSel and dest then
			table.insert(out, { Kind = "Salto", Pos = dest })
		end
	end
	return out
end

local function quantumText(a: any, s: { [string]: any }): (string, Color3?)
	if a.Quantum then
		return "SALTO: CARGANDO", Color3.fromRGB(220, 160, 255)
	end
	local cool = (s.Cool and s.Cool.Quantum) or 0
	if cool > 0 then
		return ("SALTO %d s"):format(math.ceil(cool)), Color3.fromRGB(150, 160, 190)
	end
	if s.QuantumBlock then
		return "SALTO: " .. string.upper(ShipAbilities.Reasons[s.QuantumBlock] or s.QuantumBlock), Color3.fromRGB(255, 160, 70)
	end
	return "SALTO LISTO (X)", Color3.fromRGB(200, 130, 255)
end

function ShipHudClient.slotInfo(a: any): { [string]: any }
	local s = a.Server or {}
	return {
		Energy = s.Energy,
		Weapon = a.Weapon or s.Weapon,
		Missiles = s.Missiles or a.Gun.Missiles,
		MaxMissiles = ShipWeapons.Missile.Ammo,
		MissileReload = s.MissileReload,
		Heat = s.Heat or a.Gun.Heat,
		Overheated = s.Overheated == true or a.Gun.Overheated,
		Cool = s.Cool,
		Hyper = if a.Hyper then a.Hyper.Phase else nil,
		Quantum = if a.Quantum then "Charging" else nil,
		HyperBlock = s.HyperBlock,
		QuantumBlock = s.QuantumBlock,
		OverloadOn = s.OverloadOn,
		Overheat = s.Overheat,
		CloakOn = s.CloakOn,
		DroneKind = s.DroneKind,
		DroneOn = s.DroneOn,
		DroneNote = if type(s.Drone) == "table" then ("%d%%"):format(math.floor(100 * (s.Drone.Hp or 0) / math.max(s.Drone.MaxHp or 1, 1))) else nil,
		DroneLeft = if type(s.Drone) == "table" then ("%ds"):format(math.ceil(s.Drone.Left or 0)) else nil,
	}
end

-- El objetivo elegido o fijado (para el HUD): categoría, nivel, salud y distancia
function ShipHudClient.targetRow(a: any): { [string]: any }?
	local id = a.SelTarget or (a.Lock and a.Lock.Target)
	if not id then
		return nil
	end
	local folder = workspace:FindFirstChild("AirEnemies_" .. player.UserId)
	if not folder then
		return nil
	end
	for _, m in folder:GetChildren() do
		if m:GetAttribute("AirEnemy") == id and m:IsA("Model") and m.PrimaryPart then
			local kind = m:GetAttribute("Kind")
			local hp, maxHp = tonumber(m:GetAttribute("Hp")) or 0, tonumber(m:GetAttribute("MaxHp")) or 1
			return {
				Kind = "OBJETIVO",
				Title = ("%s · Nv %d"):format(ShipCombat.Categories[kind or ""] or "Enemigo", tonumber(m:GetAttribute("Level")) or 1),
				Step = ("Salud %d%% · amenaza %s%s"):format(math.floor(100 * hp / math.max(maxHp, 1) + 0.5), ShipCombat.Threat[kind or ""] or "MEDIA", if a.Lock and a.Lock.Locked and a.Lock.Target == id then " · FIJADO" else ""),
				Right = NavInfo.distanceText((m.PrimaryPart.Position - a.Root.Position).Magnitude),
				Color = Color3.fromRGB(255, 80, 80),
			}
		end
	end
	return nil
end

local function rows(a: any): { { [string]: any } }
	local out = {}
	local target = ShipHudClient.targetRow(a)
	if target then
		table.insert(out, target)
	end
	local pos = a.Root.Position
	local ok, obj = pcall(function()
		return require(script.Parent.Parent.UI.Hud).objective()
	end)
	if ok and type(obj) == "table" then
		table.insert(out, {
			Kind = if obj.Kind == "TRABAJO" or obj.Kind == "ENCARGO" then obj.Kind else "PRINCIPAL",
			Title = obj.Title,
			Step = obj.Later or obj.Step,
			Right = if typeof(obj.Target) == "Vector3" then NavInfo.distanceText((obj.Target - pos).Magnitude) else "",
		})
	end
	local nav = a.Nav
	if nav and type(nav.Missions) == "table" then
		for _, m in nav.Missions do
			table.insert(out, {
				Kind = "SECUNDARIA",
				Title = m.Title,
				Step = ("%s%s"):format(m.Progress or "", if m.TargetName then " · " .. m.TargetName else ""),
				Right = if typeof(m.Target) == "Vector3" then NavInfo.distanceText((m.Target - pos).Magnitude) else "",
			})
		end
	end
	if nav and type(nav.Event) == "string" then
		table.insert(out, { Kind = "EVENTO", Title = nav.Event, Step = "", Right = "" })
	elseif #out == 0 then
		table.insert(out, { Kind = "SECUNDARIA", Title = "Sin misiones del tablón", Step = "Atraca en una estación para coger misiones", Right = "" })
	end
	-- (el evento, si lo hay, siempre a la vista: si no caben todas, fuera las secundarias de más)
	local max = if TOUCH then 3 else 4
	while #out > max do
		table.remove(out, #out - (if out[#out].Kind == "EVENTO" then 1 else 0))
	end
	return out
end

local function heading(a: any): number
	return NavInfo.heading(a.Root.CFrame.LookVector)
end

function ShipHudClient.update(view: AirCombatHud.View, a: any, list: { any }, dt: number)
	clocks.Compass += dt
	clocks.Fast += dt
	clocks.Slow += dt
	local root = a.Root
	if clocks.Compass >= 1 / 30 then
		clocks.Compass = 0
		local _, dest = ShipHudClient.destination(a)
		local bearing = if dest then NavInfo.heading(dest - root.Position) else nil
		AirCombatHud.setCompass(view, heading(a), bearing)
	end
	if clocks.Fast >= 0.1 then
		clocks.Fast = 0
		local sim = a.Sim
		local s = a.Server or {}
		local alert: string? = nil
		local inc = s.Incoming
		if type(inc) == "table" and typeof(inc.Dir) == "Vector3" then
			-- (aviso de misil con su dirección: delante/detrás, izquierda/derecha)
			local rel = root.CFrame:VectorToObjectSpace(inc.Dir)
			local side = if math.abs(rel.X) > math.abs(rel.Z) then (if rel.X > 0 then "DERECHA" else "IZQUIERDA") elseif rel.Z > 0 then "DETRÁS" else "DELANTE"
			alert = ("⚠ MISIL ENTRANTE · %s · %s · K bengalas"):format(side, NavInfo.distanceText(inc.Dist or 0))
		elseif a.Hyper and a.Hyper.Warn then
			alert = a.Hyper.Warn
		elseif s.Shield == 0 and (s.MaxShield or 0) > 0 and s.InCombat then
			alert = "⚠ ESCUDO CAÍDO"
		elseif s.CloakOn then
			alert = "👻 CAMUFLADO"
		elseif s.InCombat then
			alert = "⚔ EN COMBATE"
		elseif sim.Time < sim.RecoverUntil and sim.Bumped then
			alert = "⚠ RECUPERANDO EL CONTROL"
		end
		local hull = s.Hull or 100
		if hull < (s.MaxHull or 100) * 0.3 then
			alert = "⚠ CASCO CRÍTICO"
		end
		AirCombatHud.set(view, {
			Speed = ShipFlight.kmh(sim),
			Boost = sim.Boost,
			BoostReady = sim.Time >= sim.CoolUntil,
			Boosting = sim.Boosting,
			Shield = s.Shield or 60,
			MaxShield = s.MaxShield or 60,
			Hull = hull,
			MaxHull = s.MaxHull or 100,
			Missiles = s.Missiles or a.Gun.Missiles,
			MaxMissiles = s.MaxMissiles or ShipWeapons.Missile.Ammo,
			Overheated = s.Overheated == true or a.Gun.Overheated,
			Heat = s.Heat or a.Gun.Heat,
			Wave = s.Wave or 0,
			Score = s.Score or 0,
			Objective = if a.Down then "💥 Derribado · reapareces en el punto de control…" else s.Objective or "Prepárate",
			Warn = sim.Warn,
			Mode = a.Mode,
			Energy = s.Energy,
			MaxEnergy = s.MaxEnergy,
			Weapon = a.Weapon or s.Weapon,
			FlightMode = sim.FlightMode,
			Assist = sim.Assist,
			Alert = alert,
			Flares = s.Flares,
			MaxFlares = s.MaxFlares,
		})
		AirCombatHud.setSlots(view, ShipAbilities.slotViews(ShipHudClient.slotInfo(a)), ShipHudClient.device())
		local range = ShipHudLayout.RadarRange.Combat
		if a.World == "Cosmos" then
			range = ShipHudLayout.RadarRange[sim.FlightMode] or range
			if type(s.Drone) == "table" and s.Drone.Kind == "Exploracion" then
				range = math.max(range, ShipHudLayout.RadarRange.Explore)
			end
		end
		AirCombatHud.radar(view, ShipHudLayout.blips(root.CFrame, ShipHudClient.contacts(a, list), range, AirCombatHud.MaxBlips), range, heading(a))
		-- Letrero de la habilidad en marcha
		local now = os.clock()
		if a.Quantum then
			local k = math.clamp((now - a.Quantum.Since) / math.max(a.Quantum.Seconds, 0.1), 0, 1)
			AirCombatHud.setPrompt(view, "SALTO CUÁNTICO · CARGANDO", ("%s · %s · ⚡ %d  (X cancela)"):format(a.Quantum.Name or "", NavInfo.distanceText(a.Quantum.Dist or 0), a.Quantum.Cost or 0), k, Color3.fromRGB(200, 130, 255))
		elseif a.Hyper then
			local phase = a.Hyper.Phase
			local T = Hyperspeed.Times
			local k = if phase == "Prepare" then (now - a.Hyper.Since) / T.Prepare elseif phase == "Activate" then (now - a.Hyper.Since) / T.Activate elseif phase == "Decel" then 1 - (now - a.Hyper.Since) / T.Decel else math.clamp((s.Energy or 0) / 100, 0, 1)
			local sub = if phase == "Travel" then ("Energía %d%% · Ctrl o 7 para salir"):format(math.floor(s.Energy or 0)) elseif phase == "Prepare" then "Comprobando energía y obstáculos…" else ""
			AirCombatHud.setPrompt(view, Hyperspeed.Titles[phase] or "HIPERVELOCIDAD", sub, k, Color3.fromRGB(255, 160, 60))
		elseif a.ShiftHint then
			AirCombatHud.setPrompt(view, "HIPERVELOCIDAD", "Mantén Shift para activar", a.ShiftHint, Color3.fromRGB(255, 160, 60))
		else
			AirCombatHud.setPrompt(view, nil)
		end
	end
	if clocks.Slow >= 0.5 then
		clocks.Slow = 0
		local s = a.Server or {}
		local nav = a.Nav or {}
		AirCombatHud.setProfile(view, {
			UserId = player.UserId,
			Name = player.DisplayName,
			Level = tonumber(player:GetAttribute("Level")) or 1,
			Money = Format.money(tonumber(player:GetAttribute("Money")) or 0),
			Chispas = tonumber(nav.Chispas) or 0,
			Ship = ("CAZA · %s%s"):format((ShipFlight.Modes[a.Sim.FlightMode] or ShipFlight.Modes.Combat).Name, if nav.Cargo then " · " .. nav.Cargo else ""),
		})
		local place = NavInfo.place(a.World, root.Position, a.Planet)
		local name, dest = ShipHudClient.destination(a)
		local qText, qColor = quantumText(a, s)
		AirCombatHud.setNav(view, {
			Zone = place.Zone,
			Detail = place.Detail,
			Dest = if name and dest then ("▶ %s · %s"):format(name, NavInfo.distanceText((dest - root.Position).Magnitude)) else "",
			Quantum = if a.World == "Cosmos" then qText else "",
			QuantumColor = qColor,
		})
		AirCombatHud.setMissions(view, rows(a))
		local device = ShipHudClient.device()
		if device ~= lastDevice then
			lastDevice = device
			if device ~= "Touch" then
				AirCombatHud.setHints(view, ShipKeys.hints(device))
			end
		end
	end
end

-- (para el selector del salto: textos de cada destino)
function ShipHudClient.quantumEntries(list: { any }): { { [string]: any } }
	local out = {}
	for _, d in list do
		table.insert(out, {
			Id = d.Id,
			Name = d.Name,
			Kind = (if d.Kind == "Planeta" then "Órbita" elseif d.Kind == "Estacion" then "Estación" elseif d.Kind == "Mision" then "Misión" elseif d.Kind == "Baliza" then "Baliza" elseif d.Kind == "Campo" then "Campo de asteroides" else "Sector (peligro)") .. (if d.Note then " · " .. d.Note else ""),
			Dist = NavInfo.distanceText(d.Dist or 0),
			Cost = d.Cost,
			Ok = d.Ok,
			Reason = if d.Ok then nil else (ShipAbilities.Reasons[d.Reason or ""] or d.Reason),
			Pos = d.Pos,
		})
	end
	-- (las que se pueden, primero)
	table.sort(out, function(x, y)
		if x.Ok ~= y.Ok then
			return x.Ok == true
		end
		return false
	end)
	return out
end

return ShipHudClient
