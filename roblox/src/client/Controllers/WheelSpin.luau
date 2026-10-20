-- WheelSpin (cliente): las ruedas de los vehículos giran como en la vida real, en TODOS los ordenadores.
--
--   * Ruedan según lo que avanza el vehículo (sin deslizar: giro = distancia / radio; marcha atrás,
--     al revés). La distancia sale de cuánto se ha movido el vehículo entre fotogramas, así que vale
--     igual para tu vehículo, los de otros jugadores y los que mueve el servidor (autobuses, patrullas).
--   * Las de delante giran con el volante (coche, patrulla, autobús, camiones; en la moto, la rueda
--     con la horquilla y el guardabarros). El tuyo, con tu volante (Driving.current); los demás, con
--     cuánto giran para lo que avanzan (shared/WheelRig.steerFromYaw). Sin red de más.
--   * Freno de mano en marcha: las de atrás se bloquean (derrapa).
--   * Solo cerca y a la vista: como mucho WheelRig.MAX_VEHICLES a menos de WheelRig.RANGE studs, y
--     el tuyo siempre. Se elige 4 veces por segundo; lo demás se queda quieto y sin coste.
--   * Barato y sin tocar la física: los vehículos preparados (Rides.prepare: soldados a «Chassis»)
--     cambian en ESTE ordenador la soldadura de cada rueda por una Weld (WheelSpinJoint) que se gira
--     con C0 (una escritura por rueda y fotograma); llanta, buje, radios… van soldados a su rueda.
--     Los anclados (patrullas de ronda) se colocan con BulkMoveTo. Nunca cambia la colisión, el
--     tamaño, los nombres ni nada en el servidor; al salir de la vista, todo vuelve a su sitio.
--   * El tráfico de la ciudad (Controllers/Traffic) gira sus ruedas él mismo, con las mismas cuentas.
--   * Ruedas pinchadas (atributo Flat_<rueda> del servidor, shared/Tyres): la rueda baja y se ve la
--     goma chafada contra el suelo (una pieza solo de este ordenador, sin colisión). Si la tuya tiene
--     una pinchada, en los surtidores sale «Reparar rueda» (TyrePrompt, solo en tu pantalla).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WheelRig = require(ReplicatedStorage.Shared.WheelRig)
local Tyres = require(ReplicatedStorage.Shared.Tyres)
local Driving = require(script.Parent.Driving)

local WheelSpin = {}

local JOINT = "WheelSpinJoint"
local BULGE = "WheelSpinBulge"
local LOD_EVERY = 0.25
local FOLDERS = { "Rides", "Buses" } -- vehículos de los jugadores (y los de trabajo) y autobuses
local TAGS = { "VehicleLamps", "PoliceCar" } -- los que conduce alguien y las patrullas

type Entry = {
	Model: Model,
	Kind: string,
	Ref: BasePart?, -- la pieza de referencia (Chassis o la carrocería)
	Mode: string, -- "Weld" (soldado a Chassis) | "Anchored" | "None" (sin ruedas)
	Rig: WheelRig.Rig?,
	Parts: { BasePart },
	Rest: { CFrame }, -- sitio de cada pieza, quieta, respecto a Ref
	Joints: { [number]: Weld }, -- las Weld que se mueven (rueda -> Ref, horquilla -> Ref)
	Active: boolean,
	Dirty: boolean,
	Links: { RBXScriptConnection },
	LastCF: CFrame?,
	Speed: number,
	Steer: number,
	ShownSteer: number?,
	Ids: { string }, -- nombre de cada rueda (shared/Tyres.ids): "1L", "2R"…
	Flat: { [number]: boolean }, -- ruedas pinchadas (por índice de rueda)
	Bulges: { [number]: { Part: BasePart, Joint: Weld?, Rest: CFrame } },
}

local entries: { [Model]: Entry } = {}
local active: { Entry } = {}

local function kindOf(model: Model): string?
	local kind = model:GetAttribute("Kind")
	if type(kind) ~= "string" then
		kind = model.Name
	end
	return if WheelRig.Kinds[kind :: string] then kind :: string else nil
end

local function refOf(model: Model): (BasePart?, string)
	local chassis = model:FindFirstChild("Chassis")
	if chassis and chassis:IsA("BasePart") then
		return chassis, "Weld"
	end
	for _, name in { "Body", "Deck", "Seat" } do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part, "Anchored"
		end
	end
	local primary = model.PrimaryPart
	if primary then
		return primary, "Anchored"
	end
	return nil, "None"
end

-- Suelda (en este ordenador) part a part0 con una Weld que se puede mover, y apaga sus WeldConstraint
local function jointFor(part: BasePart, part0: BasePart, c0: CFrame): Weld
	local joint = part:FindFirstChild(JOINT)
	if not (joint and joint:IsA("Weld")) then
		for _, child in part:GetChildren() do
			if child:IsA("WeldConstraint") and (child.Part1 == part or child.Part0 == part) then
				child.Enabled = false
			end
		end
		joint = Instance.new("Weld")
		joint.Name = JOINT
		joint.Part0 = part0
		joint.Part1 = part
		joint.C1 = CFrame.new()
		joint.C0 = c0
		joint:SetAttribute("Rest", c0)
		joint.Parent = part
	end
	return joint :: Weld
end

-- Sitio de una pieza quieta respecto a Ref (si ya la movemos, lo dice su Weld)
local function restOf(entry: Entry, part: BasePart, ref: BasePart): CFrame
	local joint = part:FindFirstChild(JOINT)
	if joint and joint:IsA("Weld") then
		local rest = joint:GetAttribute("Rest")
		if typeof(rest) == "CFrame" then
			if joint.Part0 == ref then
				return rest
			end
			local p0 = joint.Part0
			if p0 and p0:IsA("BasePart") then
				return restOf(entry, p0, ref) * rest
			end
		end
	end
	return ref.CFrame:ToObjectSpace(part.CFrame)
end

-- Todo a su sitio (al salir de la vista o antes de volver a buscar las piezas)
local function restore(entry: Entry)
	local rig = entry.Rig
	if not rig then
		return
	end
	if entry.Mode == "Weld" then
		for _, joint in entry.Joints do
			local rest = joint:GetAttribute("Rest")
			if typeof(rest) == "CFrame" and joint.Parent then
				joint.C0 = rest
			end
		end
	elseif entry.Mode == "Anchored" and entry.Ref then
		local cf = entry.Ref.CFrame
		local parts, cframes = {}, {}
		for _, w in rig.Wheels do
			for _, i in w.Spin do
				table.insert(parts, entry.Parts[i])
				table.insert(cframes, cf * entry.Rest[i])
			end
			for _, i in w.Steer do
				table.insert(parts, entry.Parts[i])
				table.insert(cframes, cf * entry.Rest[i])
			end
		end
		WheelSpin.move(parts, cframes)
	end
	for _, w in rig.Wheels do
		w.Angle = 0
	end
	for _, bulge in entry.Bulges do
		bulge.Part:Destroy()
	end
	entry.Bulges, entry.Flat = {}, {}
	entry.Steer = 0
	entry.ShownSteer = nil
end

-- Busca las ruedas (y lo que va con ellas) y lo deja listo para girar
function WheelSpin.rig(entry: Entry)
	restore(entry)
	entry.Dirty = false
	entry.LastCF = nil
	local ref, mode = refOf(entry.Model)
	entry.Ref, entry.Mode = ref, mode
	entry.Parts, entry.Rest, entry.Joints = {}, {}, {}
	entry.Rig = nil
	if not ref then
		entry.Mode = "None"
		return
	end
	local infos = {}
	for _, d in entry.Model:GetDescendants() do
		if d:IsA("BasePart") and d ~= ref and (WheelRig.SpinNames[d.Name] or WheelRig.SteerNames[d.Name]) then
			-- (soldadas: sueltas y unidas a Chassis; ancladas: todas ancladas)
			if (mode == "Weld" and not d.Anchored) or (mode == "Anchored" and d.Anchored) then
				local rest = restOf(entry, d, ref)
				table.insert(entry.Parts, d)
				table.insert(entry.Rest, rest)
				table.insert(infos, { Name = d.Name, CFrame = rest, Size = d.Size })
			end
		end
	end
	local rig = WheelRig.find(infos, entry.Kind)
	if #rig.Wheels == 0 then
		entry.Mode = "None"
		return
	end
	entry.Rig = rig
	local hubs = {}
	for k, w in rig.Wheels do
		hubs[k] = w.Hub.Position
	end
	entry.Ids = Tyres.ids(hubs)
	if mode == "Weld" then
		for _, w in rig.Wheels do
			local wheel = entry.Parts[w.Index]
			entry.Joints[w.Index] = jointFor(wheel, ref, entry.Rest[w.Index])
			for _, i in w.Spin do
				if i ~= w.Index then
					jointFor(entry.Parts[i], wheel, entry.Rest[w.Index]:ToObjectSpace(entry.Rest[i]))
				end
			end
			for _, i in w.Steer do
				entry.Joints[i] = jointFor(entry.Parts[i], ref, entry.Rest[i])
			end
		end
	end
end

-- La goma chafada de una rueda pinchada (solo en este ordenador: sin colisión, sin masa)
local function addBulge(entry: Entry, k: number)
	local rig, ref = entry.Rig, entry.Ref
	if not rig or not ref or entry.Bulges[k] then
		return
	end
	local w = rig.Wheels[k]
	local tyre = entry.Parts[w.Index]
	local r = w.Radius
	local hub = w.Hub.Position
	local rest = CFrame.new(hub.X, hub.Y - r + r * 0.17, hub.Z)
	local part = Instance.new("Part")
	part.Name = BULGE
	part.Size = Vector3.new(tyre.Size.X * 1.12, r * 0.34, r * 1.05)
	part.Color = tyre.Color
	part.Material = Enum.Material.Rubber
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	local joint: Weld? = nil
	if entry.Mode == "Weld" then
		part.Anchored = false
		part.CFrame = ref.CFrame * rest
		local j = Instance.new("Weld")
		j.Name = JOINT
		j.Part0 = ref
		j.Part1 = part
		j.C0 = rest
		j.Parent = part
		joint = j
	else
		part.Anchored = true
		part.CFrame = ref.CFrame * rest
	end
	part.Parent = tyre
	entry.Bulges[k] = { Part = part, Joint = joint, Rest = rest }
end

-- ¿Qué ruedas están pinchadas? (atributos del servidor). Devuelve si ha cambiado algo.
function WheelSpin.refreshFlats(entry: Entry): boolean
	local rig = entry.Rig
	if not rig or not entry.Ids then
		return false
	end
	local changed = false
	for k in rig.Wheels do
		local flat = entry.Model:GetAttribute(Tyres.PREFIX .. (entry.Ids[k] or "")) == true
		if (entry.Flat[k] == true) ~= flat then
			changed = true
			entry.Flat[k] = flat
			if flat then
				addBulge(entry, k)
			elseif entry.Bulges[k] then
				entry.Bulges[k].Part:Destroy()
				entry.Bulges[k] = nil
			end
		end
	end
	if changed then
		entry.ShownSteer = nil -- (que se vuelva a colocar todo)
	end
	return changed
end

function WheelSpin.move(parts: { BasePart }, cframes: { CFrame })
	if #parts == 0 then
		return
	end
	local ok = pcall(function()
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	if not ok then
		for i, p in parts do
			p.CFrame = cframes[i]
		end
	end
end

-- Un fotograma de un vehículo: own = { Steer, Handbrake } si es el tuyo
function WheelSpin.step(entry: Entry, dt: number, own: { Steer: number, Handbrake: boolean }?)
	local rig, ref = entry.Rig, entry.Ref
	if not rig or not ref or dt <= 0 then
		return
	end
	local cf = ref.CFrame
	local last = entry.LastCF
	entry.LastCF = cf
	local dist, yaw = 0, 0
	if last then
		local delta = cf.Position - last.Position
		if delta.Magnitude < WheelRig.TELEPORT then
			dist = delta:Dot(cf.LookVector)
			yaw = WheelRig.yawBetween(last.LookVector, cf.LookVector)
		end
	end
	local speed = dist / dt
	entry.Speed += (speed - entry.Speed) * math.min(1, dt * 8)
	local target
	if own then
		target = WheelRig.steerFromInput(rig, own.Steer)
	else
		target = WheelRig.steerFromYaw(rig, yaw / dt, speed)
	end
	if target then
		entry.Steer += (target - entry.Steer) * math.min(1, dt * 10)
	end
	local handbrake = if own then own.Handbrake else entry.Model:GetAttribute("Handbrake") == true
	local rolled = false
	if dist ~= 0 then
		for k, w in rig.Wheels do
			if not WheelRig.locked(w.Rear, handbrake, entry.Speed) then
				-- (pinchada, rueda con menos radio: gira un poco más)
				w.Angle = WheelRig.advance(w.Angle, dist, w.Radius * (if entry.Flat[k] then 1 - Tyres.Drop else 1))
				rolled = true
			end
		end
	end
	local steer = entry.Steer
	local steered = entry.ShownSteer == nil or math.abs(steer - (entry.ShownSteer :: number)) > 0.002
	if not rolled and not steered then
		return -- (quieto: nada que escribir; el servidor tampoco lo ha movido)
	end
	entry.ShownSteer = steer
	if entry.Mode == "Weld" then
		for k, w in rig.Wheels do
			local joint = entry.Joints[w.Index]
			if joint then
				joint.C0 = WheelRig.hubPose(w, steer, if entry.Flat[k] then w.Radius * Tyres.Drop else nil)
			end
			if steered then
				for _, i in w.Steer do
					local j = entry.Joints[i]
					if j then
						j.C0 = WheelRig.steerPose(w, steer, entry.Rest[i])
					end
				end
				local bulge = entry.Bulges[k]
				if bulge and bulge.Joint then
					bulge.Joint.C0 = WheelRig.steerPose(w, steer, bulge.Rest)
				end
			end
		end
	else
		-- Anclado: lo coloca el servidor cada vez que se mueve; aquí, la rueda girada encima
		local parts, cframes = {}, {}
		for k, w in rig.Wheels do
			local hub = cf * WheelRig.hubPose(w, steer, if entry.Flat[k] then w.Radius * Tyres.Drop else nil)
			local bulge = entry.Bulges[k]
			if bulge then
				table.insert(parts, bulge.Part)
				table.insert(cframes, cf * WheelRig.steerPose(w, steer, bulge.Rest))
			end
			for _, i in w.Spin do
				table.insert(parts, entry.Parts[i])
				table.insert(cframes, hub * w.Hub:ToObjectSpace(entry.Rest[i]))
			end
			for _, i in w.Steer do
				table.insert(parts, entry.Parts[i])
				table.insert(cframes, cf * WheelRig.steerPose(w, steer, entry.Rest[i]))
			end
		end
		WheelSpin.move(parts, cframes)
	end
end

local function drop(entry: Entry)
	for _, link in entry.Links do
		link:Disconnect()
	end
	entry.Links = {}
	entries[entry.Model] = nil
end

function WheelSpin.track(model: Instance): Entry?
	if not model:IsA("Model") then
		return nil
	end
	local existing = entries[model :: Model]
	if existing then
		return existing
	end
	local kind = kindOf(model :: Model)
	if not kind then
		return nil
	end
	local entry: Entry = {
		Model = model :: Model,
		Kind = kind,
		Ref = nil,
		Mode = "None",
		Rig = nil,
		Parts = {},
		Rest = {},
		Joints = {},
		Active = false,
		Dirty = true,
		Links = {},
		Speed = 0,
		Steer = 0,
		Ids = {},
		Flat = {},
		Bulges = {},
	}
	entries[model :: Model] = entry
	return entry
end

local function setActive(entry: Entry, on: boolean)
	if entry.Active == on then
		return
	end
	entry.Active = on
	if on then
		-- Si cambian sus piezas (el taller, la versión completa del coche…), se vuelven a buscar
		local function dirty(d: Instance)
			if d.Name ~= JOINT and d.Name ~= BULGE then
				entry.Dirty = true
			end
		end
		pcall(function()
			table.insert(entry.Links, entry.Model.DescendantAdded:Connect(dirty))
			table.insert(entry.Links, entry.Model.DescendantRemoving:Connect(dirty))
		end)
		entry.Dirty = true
		entry.LastCF = nil
	else
		pcall(restore, entry)
		for _, link in entry.Links do
			link:Disconnect()
		end
		entry.Links = {}
	end
end

-- Qué vehículos se animan (cerca, a la vista y el tuyo). camera = { CFrame, FieldOfView, Aspect }
function WheelSpin.lod(camera: { CFrame: CFrame, FieldOfView: number, Aspect: number }, ownModel: Model?, candidates: { Model })
	for _, model in candidates do
		WheelSpin.track(model)
	end
	local list = {}
	for model, entry in entries do
		if not model.Parent then
			setActive(entry, false)
			drop(entry)
			continue
		end
		local ref = entry.Ref or refOf(model)
		if not ref then
			continue
		end
		local pos = ref.CFrame.Position
		table.insert(list, {
			Key = entry,
			Position = pos,
			Visible = WheelRig.visible(camera.CFrame, math.rad(camera.FieldOfView), camera.Aspect, pos, 25),
			Forced = model == ownModel,
		})
	end
	local chosen = {}
	for _, entry in WheelRig.pick(list, camera.CFrame.Position) do
		chosen[entry] = true
	end
	table.clear(active)
	local me = Players.LocalPlayer
	local mineFlat = false
	for model, entry in entries do
		setActive(entry, chosen[entry] == true)
		if entry.Active then
			table.insert(active, entry)
			if entry.Rig and not entry.Dirty then
				WheelSpin.refreshFlats(entry)
			end
		end
		-- ¿Tu vehículo (el que llevas o el tuyo) tiene una rueda pinchada?
		if model == ownModel or (me ~= nil and model:GetAttribute("OwnerId") == me.UserId) then
			for key, value in model:GetAttributes() do
				if value == true and string.sub(key, 1, #Tyres.PREFIX) == Tyres.PREFIX then
					mineFlat = true
				end
			end
		end
	end
	WheelSpin.tyrePrompts(mineFlat)
end

-- «Reparar rueda» en los surtidores: solo en tu pantalla y solo si tu vehículo tiene una pinchada
local promptsOn = false
function WheelSpin.tyrePrompts(on: boolean)
	if on == promptsOn then
		return
	end
	promptsOn = on
	for _, pump in CollectionService:GetTagged("FuelPump") do
		local prompt = pump:FindFirstChild("TyrePrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = on
		end
	end
end

-- Un fotograma de todos los que se animan
function WheelSpin.frame(dt: number)
	local ownModel, ownSteer, _, ownHandbrake = Driving.current()
	for _, entry in active do
		if not entry.Model.Parent then
			continue
		end
		if entry.Dirty then
			local ok, err = pcall(WheelSpin.rig, entry)
			if not ok then
				warn("[WheelSpin] " .. tostring(err))
				entry.Mode, entry.Rig, entry.Dirty = "None", nil, false
			else
				pcall(WheelSpin.refreshFlats, entry)
			end
		end
		if entry.Rig and entry.Ref and entry.Ref.Parent then
			WheelSpin.step(entry, dt, if entry.Model == ownModel then { Steer = ownSteer, Handbrake = ownHandbrake == true } else nil)
		end
	end
end

local function candidates(): { Model }
	local out = {}
	for _, name in FOLDERS do
		local folder = workspace:FindFirstChild(name)
		if folder then
			for _, child in folder:GetChildren() do
				if child:IsA("Model") then
					table.insert(out, child)
				end
			end
		end
	end
	for _, tag in TAGS do
		for _, model in CollectionService:GetTagged(tag) do
			if model:IsA("Model") and model:IsDescendantOf(workspace) then
				table.insert(out, model)
			end
		end
	end
	return out
end

-- (pruebas)
function WheelSpin._entry(model: Model): Entry?
	return entries[model]
end
WheelSpin._active = active

function WheelSpin.init()
	local every = math.huge
	RunService.RenderStepped:Connect(function(dt)
		every += dt
		if every >= LOD_EVERY then
			every = 0
			local camera = workspace.CurrentCamera
			if camera then
				local size = camera.ViewportSize
				local ok, err = pcall(WheelSpin.lod, {
					CFrame = camera.CFrame,
					FieldOfView = camera.FieldOfView,
					Aspect = if size.Y > 0 then size.X / size.Y else 16 / 9,
				}, (Driving.current()), candidates())
				if not ok then
					warn("[WheelSpin] " .. tostring(err))
				end
			end
		end
		local ok, err = pcall(WheelSpin.frame, math.min(dt, 0.1))
		if not ok then
			warn("[WheelSpin] " .. tostring(err))
		end
	end)
end

return WheelSpin
