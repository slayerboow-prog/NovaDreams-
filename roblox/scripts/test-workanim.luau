-- Prueba de las tareas de los personajes (Controllers/WorkAnim) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-workanim.luau
--
-- Comprueba que:
--   * cada tarea que pone el servidor (Npc.work(…, "X") o Work = "X") existe en WorkAnim
--   * las posturas dan ángulos razonables en cualquier momento (sin NaN ni vueltas raras) y sin tirones
--   * las manos de cada postura quedan delante del cuerpo, no dentro del torso
--   * los objetos de la mano están bien descritos y cerca de la mano

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Color3, Enum = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum

local env = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum }, { __index = getfenv(1) })
local WorkAnim = luau.load(fs.readFile("src/client/Controllers/WorkAnim.luau"), { debugName = "WorkAnim", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Brazo de un R15 (las mismas articulaciones que mueve ActorLife)
local SHOULDER = {
	Right = { C0 = CFrame.new(1, 0.563, 0), C1 = CFrame.new(-0.5, 0.392, 0) },
	Left = { C0 = CFrame.new(-1, 0.563, 0), C1 = CFrame.new(0.5, 0.392, 0) },
}
local ELBOW = { C0 = CFrame.new(0, -0.334, 0), C1 = CFrame.new(0, 0.259, 0) }
local WRIST = { C0 = CFrame.new(0, -0.501, 0), C1 = CFrame.new(0, 0.125, 0) }
local function hand(side: string, x: number, twist: number, z: number, e: number)
	local sign = if side == "Right" then 1 else -1
	local upper = SHOULDER[side].C0 * CFrame.Angles(x, twist * sign, z * sign) * SHOULDER[side].C1:Inverse()
	local lower = upper * ELBOW.C0 * CFrame.Angles(e, 0, 0) * ELBOW.C1:Inverse()
	return lower * WRIST.C0 * WRIST.C1:Inverse()
end

-- Tareas que usa el servidor
local used: { [string]: string } = {}
local function scan(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scan(path)
		elseif name:match("%.luau$") then
			local source = fs.readFile(path)
			for work in source:gmatch('Npc%.work%([^,]+,%s*"(%w+)"%)') do
				used[work] = path
			end
			for work in source:gmatch('Work = "(%w+)"') do
				used[work] = path
			end
		end
	end
end
scan("src/server")

print("Tareas que pone el servidor")
local count = 0
for work, path in used do
	count += 1
	check(WorkAnim.get(work) ~= nil, work .. " existe (" .. path .. ")")
end
check(count >= 15, "el servidor pone tareas a los trabajadores (" .. count .. ")")
check(WorkAnim.get(nil) == nil and WorkAnim.get("NoExiste") == nil and WorkAnim.get(3) == nil, "sin tarea o con un nombre raro no pasa nada")

print("Posturas")
local names = {}
for name in WorkAnim.Works do
	table.insert(names, name)
end
table.sort(names)
local FIELDS = { "np", "ny", "nr", "wp", "wy", "wr", "rx", "rz", "rt", "re", "lx", "lz", "lt", "le", "Look" }
for _, name in names do
	local work = WorkAnim.Works[name]
	local pose = {}
	local sane, inside, looks, smooth = true, false, false, true
	local before = {}
	for step = 0, 400 do
		local t = step * 0.137
		for _, seed in { 0, 0.37, 55.5 } do
			WorkAnim.clear(pose)
			work.Pose(t, seed, pose)
			for _, field in FIELDS do
				local v = pose[field]
				if type(v) ~= "number" or v ~= v or math.abs(v) > 2.6 then
					sane = false
				end
			end
			if pose.Look < 0 or pose.Look > 1 then
				sane = false
			end
			if pose.Look < 0.05 then
				looks = true
			end
			-- Las manos no pueden meterse dentro del torso (2 × 1.6 × 1)
			for _, side in { "Right", "Left" } do
				local p = if side == "Right"
					then hand(side, pose.rx, pose.rt, pose.rz, pose.re).Position
					else hand(side, pose.lx, pose.lt, pose.lz, pose.le).Position
				if math.abs(p.X) < 0.9 and math.abs(p.Y) < 0.75 and math.abs(p.Z) < 0.45 then
					inside = true
				end
			end
		end
	end
	-- Sin tirones: de un fotograma al siguiente cambia poco (también al dar la vuelta cada ciclo)
	for step = 0, 6000 do
		local t = step / 60
		WorkAnim.clear(pose)
		work.Pose(t, 0.37, pose)
		for _, field in FIELDS do
			if before[field] and math.abs(pose[field] - before[field]) > 0.12 then
				smooth = false
			end
			before[field] = pose[field]
		end
	end
	check(sane, name .. ": ángulos razonables en todo momento")
	check(smooth, name .. ": se mueve suave, sin tirones")
	check(not inside, name .. ": las manos quedan fuera del torso")
	-- (llevando algo, con la bandeja, la manguera o vigilando miran alrededor todo el rato)
	local alwaysLooking = { Tray = true, Guard = true, Carry = true, Hose = true }
	check(looks or alwaysLooking[name] == true, name .. ": hay ratos en que está metido en su tarea")
	for _, prop in work.Prop or {} do
		local ok = type(prop.Name) == "string"
			and (prop.Hand == "Right" or prop.Hand == "Left" or prop.Hand == "Torso")
			and typeof(prop.Size) == "Vector3"
			and typeof(prop.Offset) == "CFrame"
			and typeof(prop.Color) == "Color3"
			and prop.Offset.Position.Magnitude < 4.5
		check(ok, name .. ": objeto " .. tostring(prop.Name) .. " bien descrito")
	end
end

print("Leer sentado en un banco (PlaceLife: Banco/Leer)")
do
	-- El libro, en la mano izquierda: delante del pecho, por encima del regazo y con las hojas hacia la
	-- cara (se ve desde delante y desde arriba). (Torso de un R15 adulto: 2 × 1.6 × 1, el regazo de
	-- alguien sentado queda por debajo de y = -1.2.)
	local book = WorkAnim.get("Book")
	local spec = book and book.Prop and book.Prop[1]
	local pose = {}
	local front, aboveLap, outside, facesUp = true, true, true, true
	for step = 0, 200 do
		WorkAnim.clear(pose)
		book.Pose(step * 0.21, 0.37, pose)
		local h = hand("Left", pose.lx, pose.lt, pose.lz, pose.le)
		local cf = h * spec.Offset
		local p = cf.Position
		front = front and p.Z < -0.7
		aboveLap = aboveLap and p.Y > -1.0 and p.Y < 0.6
		outside = outside and not (math.abs(p.X) < 1 + spec.Size.X / 2 and math.abs(p.Y) < 0.8 and math.abs(p.Z) < 0.5 + spec.Size.Z / 2 - 0.05)
		facesUp = facesUp and cf.UpVector.Y > 0.5
	end
	check(spec ~= nil and spec.Name == "Libro" and spec.Size.X >= 1 and spec.Size.Z >= 0.8 and (spec.Transparency or 0) == 0, "el libro tiene un tamaño que se ve (y no es transparente)")
	check(front and outside, "el libro queda delante del pecho, no dentro del cuerpo")
	check(aboveLap, "y por encima del regazo (sentado no se mete entre las piernas)")
	check(facesUp, "con las hojas hacia arriba, hacia su cara")
	-- Antes la postura de sentarse (UseAnim Sit: manos en el regazo) se sumaba encima: el brazo se
	-- doblaba dos veces y el libro acababa contra el pecho. Así se ve que eso lo metía dentro:
	WorkAnim.clear(pose)
	book.Pose(0, 0.37, pose)
	local sign = -1
	local upper = SHOULDER.Left.C0 * CFrame.Angles(pose.lx, pose.lt * sign, pose.lz * sign) * CFrame.Angles(0.3, -0.35, 0.05) * SHOULDER.Left.C1:Inverse()
	local lower = upper * ELBOW.C0 * CFrame.Angles(pose.le, 0, 0) * CFrame.Angles(0.7, 0, 0) * ELBOW.C1:Inverse()
	local doubled = (lower * WRIST.C0 * WRIST.C1:Inverse() * spec.Offset).Position
	check(doubled.Z > -0.7, "(con los brazos de sentarse encima, el libro se metía en el pecho: por eso UseMotion ya no se los toca)")
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
