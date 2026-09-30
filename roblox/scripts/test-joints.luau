-- Prueba de las articulaciones (shared/Joints) y de las posturas hechas con código FUERA de Roblox,
-- con Lune, en cuerpos R15 de verdad (instancias de Lune) montados de las dos maneras:
--   * Motor6D (la de siempre; los NPC pueden seguir llevándola)
--   * AnimationConstraint entre dos Attachment (las articulaciones nuevas de los avatares de Roblox, las
--     del juego publicado: sin C0/C1/Part0/Part1). Los módulos que solo buscaban Motor6D no
--     encontraban nada y la postura no hacía nada (agacharse, ir sentado, el gimnasio, los golpes…).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-joints.luau
--
-- Comprueba, con los dos tipos de articulación, que:
--   * Joints lee C0/C1 y las piezas, las encuentra aunque no estén en su pieza, mueve C0 y sabe
--     cuándo ya no son del personaje (piezas cambiadas al aplicar el aspecto)
--   * las dos se mueven igual con la misma Transform (misma postura en el mundo)
--   * PoseLayers escribe y devuelve a la animación las dos
--   * cada módulo encuentra el cuerpo y su postura se ve (algo se mueve de verdad en el mundo):
--     agacharse (Stances), inclinarse (Locomotion), ir sentado conduciendo (RidePose), el gimnasio
--     (GymMotion), el puñetazo (PunchAnim), las reacciones (ReactMotion), gatear (AgeMotion) y nadar
--     (SeaMotion por las articulaciones de AgeMotion)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Enum, Instance = roblox.CFrame, roblox.Vector3, roblox.Enum, roblox.Instance

-- Lo que Lune no trae y los módulos usan
pcall(roblox.implementMethod, "Model", "GetScale", function()
	return 1
end)
pcall(roblox.implementProperty, "Model", "AncestryChanged", function()
	return { Connect = function() end }
end)
pcall(roblox.implementMethod, "Humanoid", "GetPropertyChangedSignal", function()
	return { Connect = function() end }
end)

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
-- Carga de módulos con un Roblox de mentira
---------------------------------------------------------------------
local modules: { [string]: any } = {}
local signal = { Connect = function() end }
-- script.Parent.X / ReplicatedStorage.Shared.X: una ruta que require carga de src/
local function node(path: string): any
	return setmetatable({ __path = path }, { __index = function(_, k)
		if k == "Parent" then
			return node((path:match("^(.*)/[^/]+$")) or "")
		end
		return node(path .. "/" .. k)
	end })
end
local services = {
	Players = { LocalPlayer = { UserId = 1, GetAttribute = function() return nil end }, GetPlayerFromCharacter = function() return nil end, GetPlayers = function() return {} end },
	RunService = { RenderStepped = signal, Heartbeat = signal, Stepped = signal, PreSimulation = signal },
	CollectionService = { GetTagged = function() return {} end, GetInstanceAddedSignal = function() return signal end },
	ReplicatedStorage = { Shared = node("shared") },
}
local fakeGame = { GetService = function(_, name)
	return services[name] or { Name = name }
end }

local load
local function resolve(what: any): any
	local path = if type(what) == "table" then rawget(what, "__path") else what
	assert(type(path) == "string", "require de algo raro: " .. tostring(what))
	if modules[path] == nil then
		modules[path] = load("src/" .. path .. ".luau", node(path))
	end
	return modules[path]
end
function load(path: string, script: any): any
	local env = setmetatable({
		CFrame = CFrame, Vector3 = Vector3, Color3 = roblox.Color3, Enum = Enum, game = fakeGame, script = script,
		workspace = { CurrentCamera = {}, Raycast = function() return nil end },
		RaycastParams = { new = function() return {} end },
		task = { spawn = function() end, delay = function() end, defer = function(fn) fn() end, wait = function() end },
		require = resolve,
	}, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local Joints = resolve("shared/Joints")
local Layers = resolve("client/Controllers/PoseLayers")

---------------------------------------------------------------------
-- Un R15 de verdad montado con Motor6D o con AnimationConstraint
---------------------------------------------------------------------
local PARTS = {
	HumanoidRootPart = Vector3.new(2, 2, 1), LowerTorso = Vector3.new(2, 0.4, 1), UpperTorso = Vector3.new(2, 1.6, 1),
	Head = Vector3.new(1.2, 1.2, 1.2),
	RightUpperArm = Vector3.new(1, 1.2, 1), RightLowerArm = Vector3.new(1, 1, 1), RightHand = Vector3.new(1, 0.3, 1),
	LeftUpperArm = Vector3.new(1, 1.2, 1), LeftLowerArm = Vector3.new(1, 1, 1), LeftHand = Vector3.new(1, 0.3, 1),
	RightUpperLeg = Vector3.new(1, 1.2, 1), RightLowerLeg = Vector3.new(1, 1.1, 1), RightFoot = Vector3.new(1, 0.3, 1),
	LeftUpperLeg = Vector3.new(1, 1.2, 1), LeftLowerLeg = Vector3.new(1, 1.1, 1), LeftFoot = Vector3.new(1, 0.3, 1),
}
-- nombre = { pieza de dentro, pieza de fuera, C0, C1 }
local RIG = {
	Root = { "HumanoidRootPart", "LowerTorso", CFrame.new(0, -0.1, 0), CFrame.new(0, 0.1, 0) },
	Waist = { "LowerTorso", "UpperTorso", CFrame.new(0, 0.2, 0), CFrame.new(0, -0.8, 0) },
	Neck = { "UpperTorso", "Head", CFrame.new(0, 0.8, 0), CFrame.new(0, -0.5, 0) },
	RightShoulder = { "UpperTorso", "RightUpperArm", CFrame.new(1, 0.6, 0), CFrame.new(-0.5, 0.4, 0) },
	LeftShoulder = { "UpperTorso", "LeftUpperArm", CFrame.new(-1, 0.6, 0), CFrame.new(0.5, 0.4, 0) },
	RightElbow = { "RightUpperArm", "RightLowerArm", CFrame.new(0, -0.3, 0), CFrame.new(0, 0.3, 0) },
	LeftElbow = { "LeftUpperArm", "LeftLowerArm", CFrame.new(0, -0.3, 0), CFrame.new(0, 0.3, 0) },
	RightWrist = { "RightLowerArm", "RightHand", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.1, 0) },
	LeftWrist = { "LeftLowerArm", "LeftHand", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.1, 0) },
	RightHip = { "LowerTorso", "RightUpperLeg", CFrame.new(0.5, -0.2, 0), CFrame.new(0, 0.6, 0) },
	LeftHip = { "LowerTorso", "LeftUpperLeg", CFrame.new(-0.5, -0.2, 0), CFrame.new(0, 0.6, 0) },
	RightKnee = { "RightUpperLeg", "RightLowerLeg", CFrame.new(0, -0.6, 0), CFrame.new(0, 0.5, 0) },
	LeftKnee = { "LeftUpperLeg", "LeftLowerLeg", CFrame.new(0, -0.6, 0), CFrame.new(0, 0.5, 0) },
	RightAnkle = { "RightLowerLeg", "RightFoot", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.1, 0) },
	LeftAnkle = { "LeftLowerLeg", "LeftFoot", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.1, 0) },
}

-- nombre -> pieza donde está (para Joints.collect)
local WHERE = {}
for name, def in RIG do
	WHERE[name] = def[2]
end

local function joint(kind: string, name: string, part0: any, part1: any, c0: CFrame, c1: CFrame): any
	if kind == "Motor6D" then
		local m = Instance.new("Motor6D")
		m.Name, m.Part0, m.Part1, m.C0, m.C1 = name, part0, part1, c0, c1
		m.Transform = CFrame.identity -- (Lune no le da valor al empezar)
		m.Parent = part1
		return m
	end
	local a0 = Instance.new("Attachment")
	a0.Name, a0.CFrame, a0.Parent = name .. "RigAttachment", c0, part0
	local a1 = Instance.new("Attachment")
	a1.Name, a1.CFrame, a1.Parent = name .. "RigAttachment", c1, part1
	local m = Instance.new("AnimationConstraint")
	m.Name, m.Attachment0, m.Attachment1 = name, a0, a1
	m.Parent = part1
	return m
end

local function rig(kind: string): any
	local model = Instance.new("Model")
	model.Name = "Ana"
	for name, size in PARTS do
		local p = Instance.new("Part")
		p.Name, p.Size, p.Parent = name, size, model
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	root.CFrame = CFrame.new(0, 3, 0)
	root.Position = Vector3.new(0, 3, 0) -- (en Lune no sale del CFrame)
	model.PrimaryPart = root
	for name, def in RIG do
		joint(kind, name, model:FindFirstChild(def[1]), model:FindFirstChild(def[2]), def[3], def[4])
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 2
	humanoid.Parent = model
	model.Parent = Instance.new("Folder") -- (en el mundo: PunchAnim y ReactMotion no miran cuerpos sueltos)
	return model
end

-- Dónde queda cada pieza en el mundo (Part1 = Part0 * C0 * Transform * C1⁻¹), leyendo como lo hace el juego
local function world(model: any): { [string]: CFrame }
	local frames = { HumanoidRootPart = model:FindFirstChild("HumanoidRootPart").CFrame }
	for _ = 1, 10 do
		for _, d in model:GetDescendants() do
			if Joints.isJoint(d) then
				local p0, p1 = Joints.part0(d), Joints.part1(d)
				if p0 and p1 and frames[p0.Name] and not frames[p1.Name] then
					frames[p1.Name] = frames[p0.Name] * Joints.c0(d) * d.Transform * Joints.c1(d):Inverse()
				end
			end
		end
	end
	return frames
end

local function moved(before: { [string]: CFrame }, after: { [string]: CFrame }, part: string): number
	local a, b = before[part], after[part]
	if not a or not b then
		return 0
	end
	return (a.Position - b.Position).Magnitude + (1 - a.LookVector:Dot(b.LookVector)) + (1 - a.UpVector:Dot(b.UpVector))
end

local function resetTransforms(model: any)
	for _, d in model:GetDescendants() do
		if Joints.isJoint(d) then
			d.Transform = CFrame.identity
		end
	end
end

local KINDS = { "Motor6D", "AnimationConstraint" }

-- ¿Ha escrito la postura en Transform de articulaciones de esa clase? (cuántas)
local function wrote(model: any, kind: string): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d.ClassName == kind and not Layers.same(d.Transform, CFrame.identity) then
			n += 1
		end
	end
	return n
end

-- Cambia las piezas de un brazo y una pierna, como al aplicar el aspecto (AvatarService → ApplyDescription)
local function replaceParts(model: any, kind: string)
	for _, name in { "RightUpperArm", "RightLowerLeg" } do
		model:FindFirstChild(name):Destroy()
		local p = Instance.new("Part")
		p.Name, p.Size, p.Parent = name, PARTS[name], model
	end
	for name, def in RIG do
		local j = Joints.find(model, name)
		if not j or not j:IsDescendantOf(model) or not Joints.part0(j) or not Joints.part1(j)
			or not Joints.part0(j):IsDescendantOf(model) or not Joints.part1(j):IsDescendantOf(model) then
			if j then
				j:Destroy()
			end
			joint(kind, name, model:FindFirstChild(def[1]), model:FindFirstChild(def[2]), def[3], def[4])
		end
	end
end

local function fresh(joints: { [string]: any }, model: any): boolean
	for _, j in joints do
		if not j:IsDescendantOf(model) then
			return false
		end
	end
	return next(joints) ~= nil
end

---------------------------------------------------------------------
print("▶ shared/Joints: leer, buscar, mover C0, piezas cambiadas")
for _, kind in KINDS do
	local model = rig(kind)
	local knee = Joints.find(model, "RightKnee", "RightLowerLeg")
	check(knee ~= nil and knee.ClassName == kind, ("%s: se encuentra la rodilla en su pieza"):format(kind))
	check((Joints.c0(knee).Position - Vector3.new(0, -0.6, 0)).Magnitude < 1e-5 and (Joints.c1(knee).Position - Vector3.new(0, 0.5, 0)).Magnitude < 1e-5,
		("%s: C0/C1 se leen bien"):format(kind))
	check(Joints.part0(knee) == model:FindFirstChild("RightUpperLeg") and Joints.part1(knee) == model:FindFirstChild("RightLowerLeg"),
		("%s: Part0/Part1 se leen bien"):format(kind))
	-- Si la articulación no está en su pieza, se busca en todo el personaje (y no vale otra cosa con su nombre)
	local neck = Joints.find(model, "Neck", "Head")
	neck.Parent = model:FindFirstChild("UpperTorso")
	local decoy = Instance.new("Folder")
	decoy.Name, decoy.Parent = "Neck", model
	check(Joints.find(model, "Neck", "Head") == neck, ("%s: se encuentra aunque esté en otra pieza (y no se confunde con otra cosa llamada igual)"):format(kind))
	decoy:Destroy()
	local all = Joints.collect(model, WHERE)
	local count = 0
	for _ in all do
		count += 1
	end
	check(count == 15, ("%s: collect encuentra las 15 articulaciones (%d)"):format(kind, count))
	check(Joints.collect(model, { "Waist", "Nada" }).Waist ~= nil, ("%s: collect también con una lista de nombres"):format(kind))
	-- Mover C0 mueve la pieza de verdad
	local before = world(model)
	local shoulder = all.RightShoulder
	local c0 = Joints.c0(shoulder)
	Joints.setC0(shoulder, c0 * CFrame.Angles(math.rad(80), 0, 0))
	local after = world(model)
	check(moved(before, after, "RightHand") > 0.5 and moved(before, after, "LeftHand") < 1e-6, ("%s: setC0 levanta el brazo derecho (y solo ese)"):format(kind))
	Joints.setC0(shoulder, c0)
	check(moved(before, world(model), "RightHand") < 1e-5, ("%s: y vuelve exacto"):format(kind))
	-- Piezas cambiadas (al aplicar el aspecto)
	check(not Joints.stale(all, model), ("%s: recién buscadas, siguen siendo del personaje"):format(kind))
	model:FindFirstChild("RightLowerLeg"):Destroy()
	check(Joints.stale(all, model), ("%s: al cambiar una pieza, se nota que hay que volver a buscarlas"):format(kind))
end

print("\n▶ Las dos articulaciones se mueven igual con la misma postura")
do
	local a, b = rig("Motor6D"), rig("AnimationConstraint")
	local worst = 0
	for _, model in { a, b } do
		for name, cf in { RightShoulder = CFrame.Angles(1, 0.2, 0.3), RightKnee = CFrame.Angles(-1.2, 0, 0), Waist = CFrame.Angles(0.2, 0.4, 0) } do
			Joints.find(model, name).Transform = cf
		end
	end
	local wa, wb = world(a), world(b)
	for name in PARTS do
		worst = math.max(worst, moved(wa, wb, name))
	end
	check(worst < 1e-3, ("Misma Transform, misma postura en el mundo (diferencia %.6f)"):format(worst))
	local sa, sb = Joints.shape(Joints.collect(a, WHERE)), Joints.shape(Joints.collect(b, WHERE))
	local same = true
	for name, j in sa.Joints do
		local o = sb.Joints[name]
		same = same and o ~= nil and o.Part0 == j.Part0 and o.Part1 == j.Part1 and (o.C0.Position - j.C0.Position).Magnitude < 1e-6
	end
	check(same and sb.Sizes.RightFoot ~= nil, "Joints.shape da la misma forma del cuerpo con las dos")
end

print("\n▶ PoseLayers con las dos")
for _, kind in KINDS do
	Layers.reset()
	local model = rig(kind)
	local neck = Joints.find(model, "Neck")
	local cf = CFrame.Angles(0, 0.5, 0)
	local stop = Layers.add("prueba", 1, function()
		Layers.write(neck, cf * Layers.read(neck))
	end)
	Layers.step(1 / 60, 0)
	check(Layers.same(neck.Transform, cf), ("%s: la capa escribe Transform"):format(kind))
	stop()
	Layers.step(1 / 60, 1 / 60)
	check(Layers.same(neck.Transform, CFrame.identity), ("%s: y cuando deja de escribir vuelve a la animación"):format(kind))
end
Layers.reset()

---------------------------------------------------------------------
print("\n▶ Cada módulo encuentra el cuerpo y su postura se ve")

-- Stances (agacharse)
local Stances = resolve("client/Controllers/Stances")
for _, kind in KINDS do
	local model = rig(kind)
	local body = Stances._bodyOf(model, { Name = "Ana" })
	check(body ~= nil and #body.Legs == 2 and body.Joints.Root ~= nil, ("Stances, %s: encuentra el cuerpo y las dos piernas"):format(kind))
	if body then
		local before = world(model)
		for name, cf in Stances.crouchPose(1, 0.9, -1.6, 0.7, 0, 0) do
			local j = body.Joints[name]
			if j then
				Layers.write(j, cf * Layers.read(j))
			end
		end
		local after = world(model)
		check(moved(before, after, "RightFoot") > 0.3 and moved(before, after, "LeftLowerLeg") > 0.3, ("Stances, %s: agachado, las piernas se doblan de verdad"):format(kind))
		check(wrote(model, kind) >= 4, ("Stances, %s: escribe Transform en las %s"):format(kind, kind))
		resetTransforms(model)
		Layers.reset()
	end
end

-- Locomotion (inclinarse, mirar a la cámara)
local Locomotion = resolve("client/Controllers/Locomotion")
for _, kind in KINDS do
	local model = rig(kind)
	local body = Locomotion._bodyOf(model)
	check(body ~= nil and body.Joints.Root ~= nil and body.Joints.Waist ~= nil and body.Joints.Neck ~= nil,
		("Locomotion, %s: encuentra la raíz, la cintura y el cuello"):format(kind))
	if body then
		local before = world(model)
		for name, cf in Locomotion.leanPose(2, 1.5, 30, 1) do
			Layers.write(body.Joints[name], cf * Layers.read(body.Joints[name]))
		end
		check(moved(before, world(model), "Head") > 0.05, ("Locomotion, %s: al girar corriendo el cuerpo se inclina"):format(kind))
		check(wrote(model, kind) >= 2, ("Locomotion, %s: escribe Transform en las %s"):format(kind, kind))
		resetTransforms(model)
		Layers.reset()
		-- Piezas nuevas (ApplyDescription): se vuelven a buscar
		model:FindFirstChild("Head"):Destroy()
		local head = Instance.new("Part")
		head.Name, head.Size, head.Parent = "Head", PARTS.Head, model
		joint(kind, "Neck", model:FindFirstChild("UpperTorso"), head, RIG.Neck[3], RIG.Neck[4])
		local again = Locomotion._bodyOf(model)
		check(again == body and fresh(again.Joints, model) and again.Joints.Neck.Parent == head,
			("Locomotion, %s: si cambian las piezas, usa las articulaciones nuevas"):format(kind))
	end
end

-- RidePose (ir sentado conduciendo: manos al volante, piernas a los pedales)
local RidePose = resolve("client/Controllers/RidePose")
RidePose._useLayers(Layers)
for _, kind in KINDS do
	local model = rig(kind)
	local car = Instance.new("Model")
	car:SetAttribute("Drivable", true)
	car:SetAttribute("Kind", "Coche")
	local seat = Instance.new("VehicleSeat")
	seat.Name, seat.Parent = "DriverSeat", car
	local humanoid = { RigType = Enum.HumanoidRigType.R15, SeatPart = seat, Parent = model }
	RidePose._track(model, humanoid)
	local body = RidePose._bodies[model]
	local count = 0
	for _ in (body and body.Joints) or {} do
		count += 1
	end
	check(body ~= nil and count == 10, ("RidePose, %s: encuentra el cuerpo (%d articulaciones)"):format(kind, count))
	if body then
		local before = world(model)
		for i = 1, 90 do
			Layers.step(0, i / 60) -- (nueva cuenta de frame)
			resetTransforms(model)
			RidePose._update(body, i / 60, 1 / 60)
		end
		local after = world(model)
		check(body.Name == "Drive", ("RidePose, %s: al volante de un coche, postura de conducir"):format(kind))
		check(moved(before, after, "RightHand") > 0.3 and moved(before, after, "LeftHand") > 0.3, ("RidePose, %s: las manos van al volante"):format(kind))
		check(moved(before, after, "RightLowerLeg") > 0.1, ("RidePose, %s: las piernas se colocan"):format(kind))
		check(wrote(model, kind) >= 6, ("RidePose, %s: escribe Transform en las %s"):format(kind, kind))
		replaceParts(model, kind)
		RidePose._track(model, humanoid)
		check(RidePose._bodies[model] == body and fresh(body.Joints, model), ("RidePose, %s: si cambian las piezas, usa las articulaciones nuevas"):format(kind))
		RidePose._bodies[model] = nil
		Layers.reset()
	end
end

-- GymMotion (una máquina del gimnasio)
local GymMotion = resolve("client/Controllers/GymMotion")
GymMotion._useLayers(Layers)
for _, kind in KINDS do
	local model = rig(kind)
	local body = {
		Model = model, Humanoid = model:FindFirstChildOfClass("Humanoid"), Root = model:FindFirstChild("HumanoidRootPart"), Joints = {},
		Kind = "Cinta", Want = true, Weight = 1, T = 0.25, RepStart = nil, Queue = 0, SeenRep = 0, Belt = 0, Machine = nil,
		Moving = {}, Props = {}, Rope = {}, Near = true,
	}
	GymMotion._findJoints(body)
	local count = 0
	for _ in body.Joints do
		count += 1
	end
	check(count == 15, ("GymMotion, %s: encuentra las 15 articulaciones (%d)"):format(kind, count))
	local before = world(model)
	GymMotion._step(body, 1 / 60, 0)
	local after = world(model)
	check(moved(before, after, "RightFoot") > 0.1 or moved(before, after, "RightHand") > 0.1, ("GymMotion, %s: corriendo en la cinta, el cuerpo se mueve"):format(kind))
	check(wrote(model, kind) >= 6, ("GymMotion, %s: escribe Transform en las %s"):format(kind, kind))
	Layers.reset()
end

-- PunchAnim (el puñetazo que se ve siempre: mueve C0)
local PunchAnim = resolve("client/Controllers/PunchAnim")
for _, kind in KINDS do
	local model = rig(kind)
	local before = world(model)
	check(PunchAnim.play(model, "Jab"), ("PunchAnim, %s: el directo se puede dar"):format(kind))
	local body = PunchAnim._bodyOf(model)
	body.Start = os.clock() - body.Duration * 0.35 -- (en pleno golpe)
	PunchAnim._step(1 / 60)
	check(moved(before, world(model), "RightHand") > 0.3, ("PunchAnim, %s: el brazo derecho golpea de verdad"):format(kind))
	body.Start = os.clock() - body.Duration * 3 -- (ya ha acabado)
	PunchAnim._step(1 / 60)
	check(moved(before, world(model), "RightHand") < 1e-3, ("PunchAnim, %s: al acabar el brazo vuelve a su sitio"):format(kind))
	-- La guardia mantenida mientras cambian las piezas: sigue con las articulaciones nuevas
	check(PunchAnim.hold(model, "Guard", true), ("PunchAnim, %s: la guardia se puede poner"):format(kind))
	replaceParts(model, kind)
	local rested = world(model)
	for _ = 1, 30 do
		PunchAnim._step(1 / 60)
	end
	local guard = PunchAnim._bodyOf(model)
	check(guard ~= nil and fresh(guard.Joints, model) and moved(rested, world(model), "RightHand") > 0.3,
		("PunchAnim, %s: si cambian las piezas con la guardia puesta, la guardia sigue en las nuevas"):format(kind))
	PunchAnim.hold(model, "Guard", false)
	for _ = 1, 120 do
		PunchAnim._step(1 / 60)
	end
end

-- ReactMotion (golpes, gestos)
local ReactMotion = resolve("client/Controllers/ReactMotion")
for _, kind in KINDS do
	local model = rig(kind)
	check(ReactMotion.play(model, "Jab") == true, ("ReactMotion, %s: encuentra los brazos y puede reaccionar"):format(kind))
end

-- AgeMotion (gatear: mide el cuerpo con C0/C1 y las piezas) y nadar (SeaMotion por sus articulaciones)
local AgeMotion = resolve("client/Controllers/AgeMotion")
local SeaMotion = resolve("client/Controllers/SeaMotion")
local drops = {}
for _, kind in KINDS do
	local model = rig(kind)
	local body = { Model = model, Humanoid = model:FindFirstChildOfClass("Humanoid"), Root = model:FindFirstChild("HumanoidRootPart"), Joints = {} }
	AgeMotion._findJoints(body)
	local count = 0
	for _ in body.Joints do
		count += 1
	end
	check(count >= 13 and body.Joints.RightShoulder and body.Joints.RightKnee, ("AgeMotion, %s: encuentra las articulaciones (%d)"):format(kind, count))
	local ok, drop = pcall(AgeMotion._crawlDrop, body)
	drops[kind] = if ok then drop else nil
	check(ok and type(drop) == "number" and drop == drop and math.abs(drop) > 0.01, ("AgeMotion, %s: al gatear se mide cuánto bajar (%s)"):format(kind, tostring(drop)))
	-- Nadar a crol
	local before = world(model)
	for name, cf in SeaMotion.crawl(1.3, 0.5, 0) do
		local j = body.Joints[name]
		if j then
			Layers.write(j, cf * Layers.read(j))
		end
	end
	local after = world(model)
	check(moved(before, after, "RightHand") > 0.3 or moved(before, after, "LeftHand") > 0.3, ("Nadar, %s: los brazos dan la brazada"):format(kind))
	check(wrote(model, kind) >= 4, ("Nadar, %s: escribe Transform en las %s"):format(kind, kind))
	resetTransforms(model)
	Layers.reset()
end
check(drops.Motor6D and drops.AnimationConstraint and math.abs(drops.Motor6D - drops.AnimationConstraint) < 1e-5,
	"AgeMotion: gateando baja lo mismo con las dos articulaciones")

-- ActorLife (NPC y tu personaje al hablar: mueve C0, que en las nuevas es Attachment0)
local ActorLife = resolve("client/Controllers/ActorLife")
for _, kind in KINDS do
	local model = rig(kind)
	local joints, rootJoint = ActorLife._rigJoints(model)
	local count = 0
	for _ in joints do
		count += 1
	end
	check(count == 7 and rootJoint ~= nil and joints.Neck.ClassName == kind, ("ActorLife, %s: encuentra cuello, cintura, brazos y la raíz (%d)"):format(kind, count))
	local before = world(model)
	Joints.setC0(joints.Neck, Joints.c0(joints.Neck) * CFrame.Angles(0, 0.8, 0))
	Joints.setC0(rootJoint, Joints.c0(rootJoint) * CFrame.Angles(0, 0.5, 0))
	local after = world(model)
	check(moved(before, after, "Head") > 0.3 and moved(before, after, "LowerTorso") > 0.1, ("ActorLife, %s: mirar y girar el cuerpo se ve"):format(kind))
end

print("")
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
