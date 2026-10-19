-- Prueba: pilotar los aviones del aeroclub COMO EN EL JUEGO, con el cliente de verdad y el mapa construido.
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl
--   lune run scripts/test-avion-real.luau /tmp/x.rbxl        (sin argumento: RealLifeSimulator.rbxl)
--
-- Por qué existe (v116, móvil del dueño, docs/bugs/avion-video/captura-hud-avioneta.png): al darle a
-- «Pilotar» la avioneta del aeroclub, el HUD nuevo salía pero la pantalla era toda chapa oxidada (la
-- cámara de persecución, al «no meterse en el suelo», buscaba el suelo con un rayo que salía 30 studs
-- por encima y daba con el TEJADO del hangar: la cámara acababa encima del tejado), el piloto se veía
-- «medio enterrado» (el servidor soltaba el avión nada más sentarse y, sin piezas que chocasen, caía
-- hasta que el personaje tocaba el suelo) y «el avión no hacía nada» (no se veía). Las pruebas de
-- siempre (test-clientboot) usaban un suelo plano sin techo y nunca lo vieron.
--
-- Aquí, con el cliente entero arrancado (scripts/test-clientboot.luau como biblioteca: Main.client y
-- todos sus módulos, en ordenador y en móvil):
--   * el aeropuerto de verdad (las piezas del mapa construido: suelo y tejado del hangar, plataforma,
--     pistas…) con rayos y Blockcast que se comportan como los de Roblox (excluir, CanQuery,
--     RespectCanCollide, y un rayo que empieza dentro de una pieza no la ve);
--   * los aviones de verdad del mapa (la avioneta EC-VAL1 en el hangar y el avión de línea EC-VLA en la
--     plataforma), soldados a su Root como hace AviationService, y el servidor hecho a mano igual que
--     AviationService.pilot: te sienta en el PilotSeat, pone Piloting y manda "Pilot" (con Start);
--     responde a "Ready" (suelta el avión), a "Exit" (te baja: "Off") y simula reaparecer y un accidente.
-- Comprueba: sale el HUD del avión (vehículo Plane, 8 ranuras), "Ready" llega al servidor, la cámara ve
-- el avión (debajo del tejado y sin nada en medio), el avión no se hunde, los mandos (palanca y MOTOR + a
-- la vez, FRENOS, FLAPS, TREN, FRENO APARC., CÁMARA, PALANCA, RALENTÍ, A TOPE, BAJARSE; en el ordenador
-- Shift/G/F/C), rueda de verdad fuera del hangar sin chocar, bajarse limpia todo, volver a subir,
-- reaparecer en pleno vuelo, el accidente y de pasajero (sin HUD de piloto).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

process.env.CLIENTBOOT_LIB = "1"
local CB = require("./test-clientboot")

local V3, V2, CFrame, Enum = roblox.Vector3, roblox.Vector2, roblox.CFrame, roblox.Enum

local placePath = process.args[1] or "RealLifeSimulator.rbxl"
if not fs.isFile(placePath) then
	print("Uso: lune run scripts/test-avion-real.luau <mapa construido .rbxl>")
	process.exit(1)
end

local function loadShared(path: string): any
	local env = setmetatable({ Vector3 = V3, Vector2 = V2, CFrame = CFrame, Color3 = roblox.Color3, Enum = Enum, script = { Parent = {} } }, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end
local Airport = loadShared("src/shared/Airport.luau")
local Flight = loadShared("src/shared/Flight.luau")

---------------------------------------------------------------------
-- El mapa: las piezas del aeropuerto y los aviones que se pilotan
---------------------------------------------------------------------
print("▶ Leyendo el mapa construido…")
local place = roblox.deserializePlace(fs.readFile(placePath))
local town = place:GetService("Workspace"):FindFirstChild("Town")
assert(town, "el mapa no tiene la ciudad construida (Workspace.Town)")

type PartData = { Class: string, Name: string, CFrame: any, Size: any, CanCollide: boolean, CanQuery: boolean, Transparency: number, Material: any }
type Node = { Class: string, Name: string, Attrs: { [string]: any }, Tags: { string }, Part: PartData?, Children: { Node } }

local function partData(d: any): PartData
	return { Class = d.ClassName, Name = d.Name, CFrame = d.CFrame, Size = d.Size, CanCollide = d.CanCollide, CanQuery = d.CanQuery, Transparency = d.Transparency, Material = d.Material }
end

-- Todo lo que no sea un avión, dentro del aeropuerto (con margen)
local L = Airport.Land
local function inside(cf: any): boolean
	local p = cf.Position
	return p.X > L.X0 - 120 and p.X < L.X1 + 120 and p.Z > L.Z0 - 120 and p.Z < L.Z1 + 120 and p.Y > -40 and p.Y < 120
end
local function planeModel(d: any): boolean
	local m = d:FindFirstAncestorWhichIsA("Model")
	while m do
		if m:GetAttribute("PilotPlane") ~= nil or m:HasTag("Plane") then
			return true
		end
		m = m.Parent and m.Parent:FindFirstAncestorWhichIsA("Model")
	end
	return false
end
local world: { PartData } = {}
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") and inside(d.CFrame) and not planeModel(d) then
		table.insert(world, partData(d))
	end
end

local function nodeOf(d: any): Node?
	if not (d:IsA("BasePart") or d:IsA("Model") or d:IsA("Folder")) then
		return nil
	end
	local n: Node = { Class = d.ClassName, Name = d.Name, Attrs = d:GetAttributes(), Tags = d:GetTags(), Part = if d:IsA("BasePart") then partData(d) else nil, Children = {} }
	for _, c in d:GetChildren() do
		local cn = nodeOf(c)
		if cn then
			table.insert(n.Children, cn)
		end
	end
	return n
end
local planeNodes: { [string]: Node } = {}
for _, spec in Airport.PilotPlanes do
	local m = town:FindFirstChild("Aviones") and town.Aviones:FindFirstChild(spec.Id)
	assert(m, "falta el avión " .. spec.Id .. " en el mapa")
	planeNodes[spec.Id] = nodeOf(m) :: Node
end
print(("  %d piezas del aeropuerto; aviones %s"):format(#world, table.concat({ "EC-VAL1", "EC-VLA" }, ", ")))

---------------------------------------------------------------------
-- Geometría: rayos y cajas como los de Roblox
---------------------------------------------------------------------
type Solid = { Inst: any, CF: any, Half: any, Lo: any, Hi: any }
local CELL = 32

local function aabb(cf: any, size: any): (any, any)
	local c = { cf:GetComponents() }
	local hx = (math.abs(c[4]) * size.X + math.abs(c[5]) * size.Y + math.abs(c[6]) * size.Z) / 2
	local hy = (math.abs(c[7]) * size.X + math.abs(c[8]) * size.Y + math.abs(c[9]) * size.Z) / 2
	local hz = (math.abs(c[10]) * size.X + math.abs(c[11]) * size.Y + math.abs(c[12]) * size.Z) / 2
	return V3.new(c[1] - hx, c[2] - hy, c[3] - hz), V3.new(c[1] + hx, c[2] + hy, c[3] + hz)
end

-- Rayo contra una caja orientada: distancia (0..1 del rayo) y normal; nil si no la toca o si el rayo
-- EMPIEZA dentro (como en Roblox)
local function rayBox(origin: any, dir: any, cf: any, half: any): (number?, any)
	local o = cf:PointToObjectSpace(origin)
	local d = cf:VectorToObjectSpace(dir)
	if math.abs(o.X) < half.X and math.abs(o.Y) < half.Y and math.abs(o.Z) < half.Z then
		return nil, nil
	end
	local tmin, tmax = 0, 1
	local normal = nil
	for _, axis in { "X", "Y", "Z" } do
		local oa, da, ha = (o :: any)[axis], (d :: any)[axis], (half :: any)[axis]
		if math.abs(da) < 1e-9 then
			if oa < -ha or oa > ha then
				return nil, nil
			end
		else
			local t1, t2 = (-ha - oa) / da, (ha - oa) / da
			local n = -1
			if t1 > t2 then
				t1, t2 = t2, t1
				n = 1
			end
			if t1 > tmin then
				tmin = t1
				normal = ({ X = V3.new(n, 0, 0), Y = V3.new(0, n, 0), Z = V3.new(0, 0, n) })[axis]
			end
			tmax = math.min(tmax, t2)
			if tmin > tmax then
				return nil, nil
			end
		end
	end
	if normal == nil then
		return nil, nil
	end
	return tmin, cf:VectorToWorldSpace(normal)
end

local function newScene()
	local grid: { [number]: { Solid } } = {}
	local all: { Solid } = {}
	local function key(gx: number, gz: number): number
		return (gx + 5000) * 10000 + (gz + 5000)
	end
	local scene = {}
	function scene.add(inst: any, cf: any, size: any): Solid
		local lo, hi = aabb(cf, size)
		local s: Solid = { Inst = inst, CF = cf, Half = size / 2, Lo = lo, Hi = hi }
		table.insert(all, s)
		for gx = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
			for gz = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
				local k = key(gx, gz)
				grid[k] = grid[k] or {}
				table.insert(grid[k], s)
			end
		end
		return s
	end
	-- (las piezas que se mueven: los aviones; se miran todas, son pocas)
	local moving: { Solid } = {}
	function scene.addMoving(inst: any)
		table.insert(moving, { Inst = inst, CF = nil :: any, Half = nil :: any, Lo = nil :: any, Hi = nil :: any })
	end
	local function excluded(inst: any, params: any): boolean
		local list = params and params.FilterDescendantsInstances or {}
		local include = params and params.FilterType == Enum.RaycastFilterType.Include
		local hit = false
		for _, f in list do
			if f == inst or inst:IsDescendantOf(f) then
				hit = true
				break
			end
		end
		return if include then not hit else hit
	end
	local function usable(inst: any, params: any): boolean
		if inst.Parent == nil or inst.CanQuery == false then
			return false
		end
		if params and params.RespectCanCollide and inst.CanCollide == false then
			return false
		end
		if params and params.IgnoreWater and inst.Material == Enum.Material.Water then
			return false
		end
		return not excluded(inst, params)
	end
	function scene.raycast(origin: any, dir: any, params: any): any
		local best, bestT, bestN = nil, math.huge, nil
		local function test(s: Solid, cf: any, half: any)
			if not usable(s.Inst, params) then
				return
			end
			local t, n = rayBox(origin, dir, cf, half)
			if t and t < bestT then
				best, bestT, bestN = s, t, n
			end
		end
		local finish = origin + dir
		local seen: { [Solid]: boolean } = {}
		for gx = math.floor(math.min(origin.X, finish.X) / CELL), math.floor(math.max(origin.X, finish.X) / CELL) do
			for gz = math.floor(math.min(origin.Z, finish.Z) / CELL), math.floor(math.max(origin.Z, finish.Z) / CELL) do
				for _, s in grid[key(gx, gz)] or {} do
					if not seen[s] then
						seen[s] = true
						test(s, s.CF, s.Half)
					end
				end
			end
		end
		for _, s in moving do
			local inst = s.Inst
			test(s, inst.CFrame, inst.Size / 2)
		end
		if not best then
			return nil
		end
		local inst = best.Inst
		return { Instance = inst, Position = origin + dir * bestT, Normal = bestN, Material = inst.Material, Distance = dir.Magnitude * bestT }
	end
	-- Blockcast: muchos rayos desde la caja (esquinas, aristas, caras y centro) en la dirección del
	-- movimiento; lo primero que toque cualquiera
	function scene.blockcast(cf: any, size: any, dir: any, params: any): any
		local best = nil
		local h = size / 2
		for _, x in { -1, 0, 1 } do
			for _, y in { -1, 0, 1 } do
				for _, z in { -1, 0, 1 } do
					local start = cf:PointToWorldSpace(V3.new(h.X * x, h.Y * y, h.Z * z))
					local hit = scene.raycast(start, dir, params)
					if hit and (best == nil or hit.Distance < best.Distance) then
						best = hit
					end
				end
			end
		end
		return best
	end
	-- ¿Está este punto dentro de algo sólido (que choca)?
	function scene.solidAt(p: any, params: any): any
		for gx = math.floor(p.X / CELL), math.floor(p.X / CELL) do
			for gz = math.floor(p.Z / CELL), math.floor(p.Z / CELL) do
				for _, s in grid[key(gx, gz)] or {} do
					local inst = s.Inst
					if inst.CanCollide and inst.Transparency < 0.95 and not excluded(inst, params) then
						local o = s.CF:PointToObjectSpace(p)
						if math.abs(o.X) < s.Half.X and math.abs(o.Y) < s.Half.Y and math.abs(o.Z) < s.Half.Z then
							return inst
						end
					end
				end
			end
		end
		return nil
	end
	return scene
end

---------------------------------------------------------------------
-- Una partida en un modo (ordenador o móvil)
---------------------------------------------------------------------
local failures = 0
local function report(results: { { any } })
	for _, c in results do
		print((if c[1] then "  ✅ " else "  ❌ ") .. c[2])
		if not c[1] then
			failures += 1
		end
	end
end

local START = 6 -- (s) cuando el cliente ya ha arrancado y tu personaje está

local function scenario(ctx: { [string]: any })
	local FPS = ctx.FPS
	local New, Fn, Task, Checks, Workspace = ctx.New, ctx.Fn, ctx.Task, ctx.Checks, ctx.Workspace
	local player, playerGui, mode = ctx.LocalPlayer, ctx.PlayerGui, ctx.Mode
	local function check(ok: any, what: string)
		table.insert(Checks, { ok and true or false, what })
	end
	local function wait(s: number)
		Task.wait(s)
	end
	local events: { [number]: () -> () } = {}
	events[math.floor(START * FPS)] = function()
		local scene = newScene()
		-- El aeropuerto
		local folder = New("Folder", "Town")
		folder.Parent = Workspace
		for _, d in world do
			local p = New(d.Class, d.Name)
			for k, v in { CFrame = d.CFrame, Size = d.Size, CanCollide = d.CanCollide, CanQuery = d.CanQuery, Transparency = d.Transparency, Material = d.Material, Anchored = true } do
				rawget(p, "__props")[k] = v
			end
			p.Parent = folder
			scene.add(p, d.CFrame, d.Size)
		end
		local floorOf: { [string]: number } = {}
		for _, d in world do
			if d.Name == "HangarRoof" then
				floorOf.Roof = math.min(floorOf.Roof or math.huge, d.CFrame.Position.Y - d.Size.Y / 2)
			end
		end
		Fn(Workspace, "Raycast", function(_, origin, dir, params)
			return scene.raycast(origin, dir, params)
		end)
		Fn(Workspace, "Blockcast", function(_, cf, size, dir, params)
			return scene.blockcast(cf, size, dir, params)
		end)
		-- Los aviones del mapa (como los suelda AviationService: todo a su Root)
		local aviones = New("Folder", "Aviones")
		aviones.Parent = folder
		local planes: { [string]: { Model: any, Root: any, Seat: any, Seats: { any }, Board: any, Welded: { { Part: any, Off: any } }, Kind: string } } = {}
		local function build(node: Node, parent: any): any
			local inst = New(node.Class, node.Name)
			if node.Part then
				for k, v in { CFrame = node.Part.CFrame, Size = node.Part.Size, CanCollide = node.Part.CanCollide, CanQuery = node.Part.CanQuery, Transparency = node.Part.Transparency, Material = node.Part.Material } do
					rawget(inst, "__props")[k] = v
				end
				scene.addMoving(inst)
			end
			for k, v in node.Attrs do
				inst:SetAttribute(k, v)
			end
			for _, child in node.Children do
				build(child, inst)
			end
			inst.Parent = parent
			for _, tag in node.Tags do
				inst:AddTag(tag)
			end
			return inst
		end
		for id, node in planeNodes do
			local m = build(node, aviones)
			local root = m:FindFirstChild("Root")
			local entry = { Model = m, Root = root, Seat = m:FindFirstChild("PilotSeat"), Seats = {}, Board = m:FindFirstChild("BoardPoint"), Welded = {}, Kind = m:GetAttribute("Kind") }
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d ~= root then
					table.insert(entry.Welded, { Part = d, Off = root.CFrame:ToObjectSpace(d.CFrame) })
				end
				if d:IsA("Seat") and d.Name == "Seat" then
					table.insert(entry.Seats, d)
				end
			end
			m:SetAttribute("NeedsWeld", nil)
			-- Los carteles del servidor (AviationService.setupPlane)
			for _, name in { "PilotPrompt", "RidePrompt" } do
				local prompt = New("ProximityPrompt", name)
				prompt.Enabled = true
				prompt.Parent = entry.Board
			end
			-- Soldaduras: al mover el Root se mueve todo (y quien vaya sentado)
			root:GetPropertyChangedSignal("CFrame"):Connect(function()
				local cf = root.CFrame
				for _, w in entry.Welded do
					rawget(w.Part, "__props").CFrame = cf * w.Off
				end
			end)
			planes[id] = entry
		end
		local remote = ctx.Remotes:FindFirstChild("Aviation")
		local okF, Flying = pcall(ctx.Require, ctx.Client.Controllers.Flying)
		local okS, Stick = pcall(ctx.Require, ctx.Client.UI.FlightStick)
		local okT, TouchLayout = pcall(ctx.Require, ctx.Client.UI.TouchLayout)
		if not (remote and okF and okS and okT) then
			check(false, "avión: remoto Aviation, Controllers/Flying, UI/FlightStick y UI/TouchLayout")
			return
		end

		-- El servidor (lo que hace AviationService)
		local logAt = #ctx.ServerLog
		local seatedChar: { Parts: { any }, Plane: any }? = nil
		local function character(): (any, any, any)
			local c = player.Character
			return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
		end
		local function sitIn(plane: any, seat: any)
			local c, hum, hrp = character()
			hrp.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
			-- Seat:Sit: soldado al asiento (la cadera en el cojín)
			local seatTop = seat.CFrame * CFrame.new(0, seat.Size.Y / 2 + hrp.Size.Y / 2, 0)
			local delta = seatTop * hrp.CFrame:Inverse()
			for _, d in c:GetDescendants() do
				if d:IsA("BasePart") then
					rawget(d, "__props").CFrame = delta * d.CFrame
					table.insert(plane.Welded, { Part = d, Off = plane.Root.CFrame:ToObjectSpace(d.CFrame), Character = true } :: any)
				end
			end
			local weld = New("Weld", "SeatWeld")
			weld.Part0, weld.Part1 = seat, hrp
			weld.Parent = seat
			rawget(seat, "__props").Occupant = hum
			rawget(hum, "__props").SeatPart = seat
			rawget(hum, "__props").Sit = true
			ctx.SignalOf(hum, "Seated"):Fire(true, seat)
		end
		local function standUp(plane: any)
			local _, hum = character()
			for i = #plane.Welded, 1, -1 do
				if (plane.Welded[i] :: any).Character then
					table.remove(plane.Welded, i)
				end
			end
			for _, s in { plane.Seat, table.unpack(plane.Seats) } do
				local w = s:FindFirstChild("SeatWeld")
				if w then
					w:Destroy()
				end
				rawget(s, "__props").Occupant = nil
			end
			if hum then
				rawget(hum, "__props").SeatPart = nil
				rawget(hum, "__props").Sit = false
				ctx.SignalOf(hum, "Seated"):Fire(false, nil)
			end
		end
		local released = false
		local function pilot(plane: any)
			released = false
			sitIn(plane, plane.Seat)
			player:SetAttribute("Piloting", plane.Model.Name)
			plane.Model:SetAttribute("Pilot", player.UserId)
			plane.Model:SetAttribute("EngineOn", true)
			remote.OnClientEvent:Fire("Pilot", { Plane = plane.Model, Id = plane.Model.Name, Kind = plane.Kind, Lesson = false, Health = 100, Start = plane.Root.CFrame })
		end
		local function endPilot(plane: any)
			standUp(plane)
			player:SetAttribute("Piloting", nil)
			plane.Model:SetAttribute("Pilot", nil)
			plane.Model:SetAttribute("EngineOn", false)
			remote.OnClientEvent:Fire("Off", {})
		end
		local current: any = nil
		-- Lo que manda el cliente
		local sent: { [string]: number } = {}
		local function pump()
			local log = ctx.ServerLog
			while logAt < #log do
				logAt += 1
				local e = log[logAt]
				if e.Remote == "Aviation" then
					local action = e.Args[1]
					sent[action] = (sent[action] or 0) + 1
					if action == "Ready" then
						released = true
					elseif action == "Exit" and current then
						endPilot(current)
						current = nil
					end
				end
			end
		end
		local function step(seconds: number)
			local t = 0
			while t < seconds do
				t += 1 / FPS
				wait(1 / FPS)
				pump()
			end
		end

		local Enum_ = Enum
		local function touch(x: number, y: number): any
			return { UserInputType = Enum_.UserInputType.Touch, UserInputState = Enum_.UserInputState.Begin, KeyCode = Enum_.KeyCode.Unknown, Position = V3.new(x, y, 0), Delta = V3.zero }
		end
		local uisBegan, uisChanged, uisEnded = ctx.SignalOf(ctx.Uis, "InputBegan"), ctx.SignalOf(ctx.Uis, "InputChanged"), ctx.SignalOf(ctx.Uis, "InputEnded")
		local function slot(label: string): any
			local hud = playerGui:FindFirstChild("PlaneHud")
			local bar = hud and hud:FindFirstChild("ZonaH")
			for _, b in if bar then bar:GetChildren() else {} do
				local name = b:FindFirstChild("Nombre")
				if name and string.find(tostring(name.Text), label, 1, true) then
					return b
				end
			end
			return nil
		end
		local function press(label: string): boolean
			local b = slot(label)
			if b then
				b.Activated:Fire()
				return true
			end
			return false
		end
		local function guiOn(name: string): boolean
			local g = playerGui:FindFirstChild(name)
			return g ~= nil and g.Enabled ~= false
		end
		local function charParams(plane: any): any
			return { FilterDescendantsInstances = { player.Character, plane.Model }, FilterType = Enum_.RaycastFilterType.Exclude, RespectCanCollide = false }
		end
		-- ¿Ve la cámara el avión? (debajo de cualquier techo y sin nada en medio)
		local function cameraSees(plane: any): (boolean, string)
			local cam = ctx.Camera
			local at = cam.CFrame.Position
			local target = plane.Root.Position + V3.new(0, 3, 0)
			local blocker = scene.raycast(at, target - at, charParams(plane))
			local inSolid = scene.solidAt(at, charParams(plane))
			local facing = cam.CFrame.LookVector:Dot((target - at).Unit)
			local ok = blocker == nil and inSolid == nil and facing > 0.5 and cam.CameraType == Enum_.CameraType.Scriptable
			return ok, ("cámara en (%.0f, %.1f, %.0f)%s%s"):format(at.X, at.Y, at.Z, if blocker then ", tapada por " .. blocker.Instance.Name else "", if inSolid then ", dentro de " .. inSolid.Name else "")
		end

		local function fly(plane: any, label: string, full: boolean)
			current = plane
			local rest = plane.Root.Position
			pilot(plane)
			step(1)
			local a = Flying._active()
			local hud = playerGui:FindFirstChild("PlaneHud")
			local slots = 0
			for _, b in if hud and hud:FindFirstChild("ZonaH") then hud.ZonaH:GetChildren() else {} do
				if b.ClassName == "TextButton" and string.sub(b.Name, 1, 6) == "Ranura" and b.Visible ~= false then
					slots += 1
				end
			end
			local names = {}
			for _, n in { "FLAPS", "TREN", "CÁMARA", "A TOPE", "ACRO", "LOOPING", "TONEL", "BAJARSE" } do
				if slot(n) then
					table.insert(names, n)
				end
			end
			check(a ~= nil and a.Model == plane.Model, ("%s: al sentarse a los mandos se pilota (Controllers/Flying)"):format(label))
			if not a then
				endPilot(plane)
				current = nil
				step(0.5)
				return
			end
			check(guiOn("PlaneHud") and slots == 8 and #names == 8 and hud.ZonaSpeed and hud.ZonaSpeed.Visible ~= false,
				("%s: sale el HUD nuevo del avión (vehículo Plane, %d ranuras: %s)"):format(label, slots, table.concat(names, ", ")))
			check(released and (sent.Ready or 0) >= 1, ("%s: su ordenador avisa al servidor («Ready») para que suelte el avión (anclado hasta entonces: no se hunde)"):format(label))
			check(math.abs(plane.Root.Position.Y - rest.Y) < 0.3, ("%s: el avión sigue sobre sus ruedas (Root a %.2f; aparcado %.2f)"):format(label, plane.Root.Position.Y, rest.Y))
			local sees, where = cameraSees(plane)
			check(sees, ("%s: la cámara de persecución ve el avión (%s%s)"):format(label, where, if floorOf.Roof and plane.Kind == "Avioneta" then (", tejado del hangar a %.1f"):format(floorOf.Roof) else ""))
			if full then
				-- Mandos
				if mode.Touch then
					local zoneGui = playerGui:FindFirstChild("FlightStickGui")
					local zone = zoneGui and zoneGui:FindFirstChild("Zona")
					check(zoneGui ~= nil and zoneGui.Enabled and Stick.available(), label .. " (móvil): la palanca analógica aparece")
					if zone then
						rawget(zone, "__props").AbsolutePosition = V2.zero
						rawget(zone, "__props").AbsoluteSize = V2.new(mode.Viewport.X / 2, mode.Viewport.Y)
					end
					-- Pulgar en la palanca y, a la vez, MOTOR + con el otro
					local thumb = touch(mode.Viewport.X * 0.18, mode.Viewport.Y * 0.6)
					uisBegan:Fire(thumb, false)
					local moved = touch(mode.Viewport.X * 0.18, mode.Viewport.Y * 0.6 + 200)
					thumb.Position = moved.Position
					thumb.UserInputState = Enum_.UserInputState.Change
					uisChanged:Fire(thumb, false)
					local pull = Flying._readInput()
					local motor = TouchLayout.buttons().MotorMas
					local finger = touch(mode.Viewport.X * 0.9, mode.Viewport.Y * 0.85)
					local thr0 = a.Sim.Throttle
					if motor then
						motor.InputBegan:Fire(finger)
						uisBegan:Fire(finger, true)
					end
					step(1.2)
					local thr1 = a.Sim.Throttle
					local stillStick = Stick.touching() and Stick.read().Y > 0.5
					finger.UserInputState = Enum_.UserInputState.End
					if motor then
						motor.InputEnded:Fire(finger)
					end
					uisEnded:Fire(finger, true)
					step(0.5)
					local thr2 = a.Sim.Throttle
					check(motor ~= nil and motor.Visible ~= false and pull.Pitch > 0.5 and thr1 > thr0 + 0.4 and stillStick and math.abs(thr2 - thr1) < 0.02,
						("%s (móvil): palanca hacia abajo = morro arriba (%.2f) y MOTOR + a la vez sube el gas (%.0f%% → %.0f%%) sin soltar la palanca; al soltar MOTOR + se queda"):format(label, pull.Pitch, thr0 * 100, thr1 * 100))
					thumb.UserInputState = Enum_.UserInputState.End
					uisEnded:Fire(thumb, false)
					step(0.1)
					check(not Stick.touching() and Stick.read().Magnitude < 0.01, label .. " (móvil): al soltar la palanca vuelve al centro")
					-- MOTOR − y FRENOS
					local minus = TouchLayout.buttons().MotorMenos
					local brakeB = TouchLayout.buttons().Frenos
					local f2 = touch(mode.Viewport.X * 0.8, mode.Viewport.Y * 0.85)
					if minus then
						minus.InputBegan:Fire(f2)
					end
					step(0.6)
					local thr3 = a.Sim.Throttle
					if minus then
						minus.InputEnded:Fire(f2)
					end
					local f3 = touch(mode.Viewport.X * 0.9, mode.Viewport.Y * 0.6)
					if brakeB then
						brakeB.InputBegan:Fire(f3)
					end
					local braking = Flying._readInput().Brake
					if brakeB then
						brakeB.InputEnded:Fire(f3)
					end
					local free = Flying._readInput().Brake
					check(thr3 < thr2 - 0.2 and braking and not free, ("%s (móvil): MOTOR − baja el gas (%.0f%%) y FRENOS frena mientras se mantiene"):format(label, thr3 * 100))
				else
					ctx.Fn(ctx.Uis, "IsKeyDown", function(_, k)
						return k == Enum_.KeyCode.LeftShift or k == Enum_.KeyCode.W
					end)
					local thr0 = a.Sim.Throttle
					local w = Flying._readInput()
					step(1)
					ctx.Fn(ctx.Uis, "IsKeyDown", function()
						return false
					end)
					check(a.Sim.Throttle > thr0 + 0.4 and w.Pitch > 0.9, ("%s (ordenador): Shift sube el gas (%.0f%%) y W sube el morro"):format(label, a.Sim.Throttle * 100))
					local toggles = ctx.Cas.FlyingToggles
					local flaps0 = a.Sim.Flaps
					if toggles then
						toggles("FlyingToggles", Enum_.UserInputState.Begin, { KeyCode = Enum_.KeyCode.F })
						toggles("FlyingToggles", Enum_.UserInputState.Begin, { KeyCode = Enum_.KeyCode.C })
					end
					local cab = a.Camera
					if toggles then
						toggles("FlyingToggles", Enum_.UserInputState.Begin, { KeyCode = Enum_.KeyCode.C })
					end
					check(toggles ~= nil and a.Sim.Flaps == flaps0 + 1 and cab == "Cabina" and a.Camera == "Persecucion", ("%s (ordenador): F flaps y C cámara (cabina y vuelta) (%s, flaps %d → %d, %s → %s)"):format(label, tostring(toggles ~= nil), flaps0, a.Sim.Flaps, tostring(cab), tostring(a.Camera)))
					a.Sim.Flaps = flaps0
				end
				-- Las ranuras del HUD (se tocan igual en el ordenador)
				local flaps0 = a.Sim.Flaps
				press("FLAPS")
				local flaps1 = a.Sim.Flaps
				press("FLAPS")
				press("FLAPS")
				check(flaps1 == flaps0 + 1 and a.Sim.Flaps == flaps0, ("%s: ranura FLAPS (%d → %d → … → %d)"):format(label, flaps0, flaps1, a.Sim.Flaps))
				local gear0 = a.Sim.Gear
				press("TREN")
				local gearGround = a.Sim.Gear
				a.Sim.OnGround = false
				press("TREN")
				local gearAir = a.Sim.Gear
				press("TREN")
				a.Sim.OnGround = true
				check(gear0 and gearGround and not gearAir and a.Sim.Gear, label .. ": ranura TREN (en tierra no se sube; en el aire sube y baja)")
				press("CÁMARA")
				step(0.1)
				local cabin = a.Camera == "Cabina" and (ctx.Camera.CFrame.Position - a.Seat.Position).Magnitude < 6
				press("CABINA")
				step(0.1)
				check(cabin and a.Camera == "Persecucion", label .. ": ranura CÁMARA (cabina, en tu asiento, y vuelta a la persecución)")
				press("A TOPE")
				local full1 = a.Sim.Throttle
				Flying._toggle("Idle")
				check(full1 == 1 and a.Sim.Throttle == 0, label .. ": ranura A TOPE")
				-- En tierra las acrobacias no se pueden (y lo dice)
				local refused = not press("LOOPING") or a.Sim.Maneuver == nil
				check(refused and a.Sim.Maneuver == nil, label .. ": en tierra LOOPING no hace nada (dice «despega primero»)")
				local exitEarly = sent.Exit or 0
				a.Sim.OnGround = false
				press("BAJARSE")
				a.Sim.OnGround = true
				check((sent.Exit or 0) == exitEarly and Flying._active() == a, label .. ": en el aire BAJARSE no te baja")
			end
			-- Rodar: motor a tope unos segundos (por la plataforma o fuera del hangar)
			press("A TOPE")
			local from = plane.Root.Position
			step(3.5)
			local moved = (plane.Root.Position - from).Magnitude
			local sees2, where2 = cameraSees(plane)
			check(moved > 8 and a.Sim.Speed > 10 and not a.Crashed and Flying._active() == a, ("%s: con el motor a tope rueda de verdad (%.0f studs, %.0f km/h, sin chocar%s)"):format(label, moved, a.Sim.Speed, if a.Sim.Bumped then "; tocó " .. tostring(a.Sim.Bumped) else ""))
			check(sees2, ("%s: rodando, la cámara sigue viendo el avión (%s)"):format(label, where2))
			-- Parar y bajarse con BAJARSE
			Flying._toggle("Idle")
			local brakeHold = TouchLayout.buttons().Frenos
			a.Parking = true
			local t = 0
			while a.Sim.Speed > 0.5 and t < 15 do
				step(0.25)
				t += 0.25
			end
			step(0.3)
			press("BAJARSE")
			step(0.6)
			local _ = brakeHold
			local cam = ctx.Camera
			check(Flying._active() == nil and not guiOn("PlaneHud") and player:GetAttribute("Piloting") == nil and cam.CameraType == Enum_.CameraType.Custom and not (playerGui:FindFirstChild("FlightStickGui") and playerGui.FlightStickGui.Enabled) and (sent.Exit or 0) >= 1,
				label .. ": parado, BAJARSE te baja (el servidor contesta «Off»): fuera el HUD del avión y la palanca, cámara normal")
			local prompt = plane.Board:FindFirstChild("PilotPrompt")
			check(prompt and prompt.Enabled, label .. ": vuelven los carteles de tu avión")
		end

		-- 1) La avioneta EC-VAL1 en el hangar del aeroclub (mandos completos)
		fly(planes["EC-VAL1"], "avioneta EC-VAL1 (hangar)", true)
		-- 2) Volver a subir a la misma
		current = planes["EC-VAL1"]
		pilot(current)
		step(1)
		check(Flying._active() ~= nil and guiOn("PlaneHud") and (cameraSees(current)), "avioneta: subir otra vez funciona (HUD y cámara)")
		-- 2b) En el aire: acrobacias (petición del dueño: «360 verticales y horizontales»)
		do
			local a = Flying._active()
			if a then
				a.Sim.OnGround = false
				a.Sim.Pos = a.Sim.Pos + V3.new(0, 30, 120)
				a.Sim.Speed = 120
				a.Sim.Throttle = 0.7
				a.Sim.Gear = false
				-- Bajo para un looping: se niega con motivo
				press("LOOPING")
				local refusedLow = a.Sim.Maneuver == nil
				a.Sim.Pos = a.Sim.Pos + V3.new(0, 500, 0)
				press("LOOPING")
				local started = a.Sim.Maneuver ~= nil and a.Sim.Maneuver.Kind == "Loop"
				step(0.6)
				local camA = ctx.Camera.CFrame.Position
				local trails = 0
				for _, d in a.Root:GetChildren() do
					if d.ClassName == "Trail" and d.Enabled then
						trails += 1
					end
				end
				step(1)
				local camStill = (ctx.Camera.CFrame.Position - camA).Magnitude < 1 and ctx.Camera.CFrame.LookVector:Dot((a.Root.Position - ctx.Camera.CFrame.Position).Unit) > 0.9
				local t = 0
				while a.Sim.Maneuver and t < 10 do
					step(0.25)
					t += 0.25
				end
				check(refusedLow and started and trails == 2 and camStill and a.Sim.Maneuver == nil and not a.Crashed and math.abs(a.Sim.Throttle - 0.7) < 0.01,
					("avioneta en el aire: LOOPING (bajo se niega; con altura lo hace, con estelas y la cámara quieta mirando el avión) y el motor sigue donde estaba (%s %s %d %s %s %s %.2f)"):format(tostring(refusedLow), tostring(started), trails, tostring(camStill), tostring(a.Sim.Maneuver == nil), tostring(a.Crashed), a.Sim.Throttle))
				step(Flight.ManeuverCooldown + 0.2)
				a.Sim.Roll, a.Sim.Pitch = 0, 0
				press("TONEL")
				local rolling = a.Sim.Maneuver ~= nil and a.Sim.Maneuver.Kind == "Roll"
				t = 0
				while a.Sim.Maneuver and t < 10 do
					step(0.25)
					t += 0.25
				end
				press("ACRO")
				local acro = a.Sim.Acro == true
				press("ACRO")
				check(rolling and a.Sim.Maneuver == nil and acro and not a.Sim.Acro, "avioneta: TONEL de un toque y el MODO ACROBÁTICO se enciende y se apaga")
				-- El asiento se suelta un momento en el aire: el vuelo sigue (antes empezaba de cero con el motor al 0 %)
				local _, hum = character()
				a.Sim.Throttle = 0.65
				rawget(hum, "__props").SeatPart = nil
				step(0.6)
				local graced = Flying._active() == a
				step(2.2)
				local stopped = Flying._active() == nil
				rawget(hum, "__props").SeatPart = current.Seat
				step(0.6)
				local b = Flying._active()
				check(graced and stopped and b ~= nil and b.Sim == a.Sim and math.abs(b.Sim.Throttle - 0.65) < 0.01 and not b.Sim.OnGround and guiOn("PlaneHud"),
					"avioneta: si el asiento se suelta en el aire, el vuelo sigue igual al volver a sentarse (motor al 65 %, en el aire)")
				-- (de vuelta a su sitio en tierra, como lo dejaría el servidor)
				if b then
					b.Sim = Flight.new("Avioneta", (Airport.rootCFrame("Avioneta", Airport.pilotPlane("EC-VAL1").Pose)) * CFrame.new(0, -(Airport.Kinds.Avioneta.FloorY - 0.3), -Airport.Kinds.Avioneta.RootZ))
				end
			end
		end
		-- 3) Reaparecer en pleno vuelo: el cliente lo deja y el servidor también
		local a = Flying._active()
		if a then
			a.Sim.OnGround = false
		end
		local oldChar = player.Character
		ctx.SpawnCharacter()
		endPilot(current)
		current = nil
		step(0.5)
		check(player.Character ~= oldChar and Flying._active() == nil and not guiOn("PlaneHud") and not (playerGui:FindFirstChild("FlightStickGui") and playerGui.FlightStickGui.Enabled), "reaparecer volando: se deja de pilotar y se limpia el HUD")
		-- 4) Y con el personaje nuevo, a pilotar otra vez; luego un accidente
		local avioneta = planes["EC-VAL1"]
		-- (vuelve a su sitio, como returnHome)
		avioneta.Root.CFrame = Airport.rootCFrame("Avioneta", Airport.pilotPlane("EC-VAL1").Pose)
		current = avioneta
		pilot(avioneta)
		step(1)
		check(Flying._active() ~= nil and guiOn("PlaneHud"), "con el personaje nuevo se vuelve a pilotar")
		standUp(avioneta)
		player:SetAttribute("Piloting", nil)
		remote.OnClientEvent:Fire("Crash", { At = avioneta.Root.Position, Reason = "Prueba" })
		current = nil
		step(0.5)
		check(Flying._active() == nil and not guiOn("PlaneHud") and ctx.Camera.CameraType == Enum_.CameraType.Custom, "accidente: fuera el HUD del avión y cámara normal")
		avioneta.Root.CFrame = Airport.rootCFrame("Avioneta", Airport.pilotPlane("EC-VAL1").Pose)
		-- 5) De pasajero en la avioneta: sin HUD de piloto
		local seat = avioneta.Seats[1]
		if seat then
			sitIn(avioneta, seat)
			step(1)
			check(Flying._active() == nil and not guiOn("PlaneHud"), "de pasajero no sale el HUD del piloto")
			standUp(avioneta)
			step(0.3)
		end
		-- 6) El avión de línea EC-VLA en la plataforma
		fly(planes["EC-VLA"], "avión de línea EC-VLA (plataforma)", false)
		local errs = 0
		for _, e in ctx.Errors do
			if string.find(e.Where .. e.Message, "Flying", 1, true) or string.find(e.Where .. e.Message, "PlaneHud", 1, true) or string.find(e.Where .. e.Message, "AirCombatHud", 1, true) or string.find(e.Where .. e.Message, "FlightStick", 1, true) then
				errs += 1
			end
		end
		check(errs == 0, ("ningún error del avión, su HUD o la palanca (%d)"):format(errs))
	end
	return events
end

for _, mode in {
	{ Name = "móvil (844x390, táctil)", Viewport = V2.new(844, 390), Touch = true },
	{ Name = "ordenador (1920x1080, teclado)", Viewport = V2.new(1920, 1080), Touch = false },
} do
	print(("\n▶ %s"):format(mode.Name))
	local result = CB.boot(mode, { Only = true, Seconds = START + 80, Budget = 400, Events = scenario })
	for _, e in result.Errors do
		print(("  ⚠️  [%s] %s"):format(e.Where, e.Message))
	end
	report(result.Checks)
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Los aviones se pilotan bien en el aeropuerto de verdad (móvil y ordenador)")
process.exit(0)
