-- SimpleActing (cliente): actuar con los cuerpos que NO son R15 (fase 4 del sistema de cine, H6).
--
-- ActorLife hace la actuación completa (mirar, respirar, gestos, posturas) con las articulaciones R15 y
-- las animaciones R15 de Roblox. Un personaje con otro cuerpo (R6, o una criatura con solo cuello) no
-- tenía nada: hablaba sin moverse. Aquí, lo poco que se puede hacer con lo que tenga:
--   * la cabeza (articulación «Neck», la del R6 en Torso o cualquier otra): cabeceo suave al hablar,
--     asentir (Nod), negar (No), ladear al preguntar (Ask), bajarla (Sad/Ashamed), apartar la mirada
--     (LookAway) y mirar a quien habla (lookAt);
--   * los brazos si tiene «Right Shoulder»/«Left Shoulder» (R6) o «RightShoulder»/«LeftShoulder»:
--     señalar (Point/PointLite), saludar (Wave/WaveLite), celebrar o aplaudir (Cheer/Clap), en jarras
--     (HandsOnHips) y cruzados (ArmsCrossed, aproximado).
-- No hay animaciones: solo se gira el C0 de esas articulaciones desde su postura de siempre, y al acabar
-- se deja como estaba. Si no tiene cuello, no hace nada (no rompe). No es sincronización labial.
--
--   SimpleActing.speak(model, emotion, seconds, gesture?)   habla `seconds` con esa emoción y gesto
--   SimpleActing.lookAt(model, point?)                       mira a ese punto (nil = al frente)
--   SimpleActing.supports(model)                             ¿tiene cuello que mover?
--   SimpleActing.step(t)                                     un fotograma (lo llama su propio bucle;
--                                                           las pruebas lo llaman a mano)

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Joints = require(ReplicatedStorage.Shared.Joints)

local SimpleActing = {}

type Entry = {
	Model: Model,
	Neck: any,
	NeckBase: CFrame,
	Right: any?,
	RightBase: CFrame?,
	Left: any?,
	LeftBase: CFrame?,
	Emotion: string,
	Gesture: string?,
	Start: number,
	Until: number,
	Look: Vector3?,
	Seed: number,
}

local entries: { [Model]: Entry } = {}
local connection: RBXScriptConnection? = nil

SimpleActing._clock = os.clock
local function now(): number
	return SimpleActing._clock()
end

local function findJoint(model: Model, names: { string }): any
	for _, name in names do
		local joint = Joints.find(model, name)
		if joint then
			return joint
		end
	end
	return nil
end

function SimpleActing.supports(model: Instance?): boolean
	if not model or not model:IsA("Model") then
		return false
	end
	return findJoint(model :: Model, { "Neck" }) ~= nil
end

local function entryOf(model: Model): Entry?
	local entry = entries[model]
	if entry and entry.Neck.Parent then
		return entry
	end
	local neck = findJoint(model, { "Neck" })
	if not neck then
		return nil
	end
	local right = findJoint(model, { "Right Shoulder", "RightShoulder" })
	local left = findJoint(model, { "Left Shoulder", "LeftShoulder" })
	entry = {
		Model = model,
		Neck = neck,
		NeckBase = Joints.c0(neck),
		Right = right,
		RightBase = if right then Joints.c0(right) else nil,
		Left = left,
		LeftBase = if left then Joints.c0(left) else nil,
		Emotion = "Calm",
		Gesture = nil,
		Start = now(),
		Until = 0,
		Look = nil,
		Seed = (#model.Name * 7.31) % 6.28,
	}
	entries[model] = entry
	return entry
end

-- Cuánto se gira cada cosa en el instante t (puro: lo prueban las pruebas)
-- Devuelve (cabeza: pitch, yaw, roll), (brazo derecho: x, z), (brazo izquierdo: x, z)
function SimpleActing.pose(emotion: string, gesture: string?, since: number, talking: boolean, seed: number): (number, number, number, number, number, number, number)
	local pitch, yaw, roll = 0, 0, 0
	local rx, rz, lx, lz = 0, 0, 0, 0
	if talking then
		-- cabeceo suave al hablar (no es la boca: solo da vida)
		pitch += math.sin(since * 7.5 + seed) * 0.035
		yaw += math.sin(since * 3.1 + seed) * 0.04
	end
	local short = math.min(since, 1.6)
	local what = gesture or emotion
	if what == "Nod" or emotion == "Nod" then
		pitch += math.sin(short * math.pi * 3.2) * 0.22
	end
	if what == "No" or emotion == "No" then
		yaw += math.sin(short * math.pi * 3.6) * 0.3
	end
	if emotion == "Ask" or what == "Ask" then
		roll += 0.16
	end
	if emotion == "Sad" or emotion == "Ashamed" then
		pitch -= 0.28
	end
	if emotion == "Surprised" then
		pitch += 0.14
	end
	if what == "LookAway" then
		yaw += 0.55
		pitch -= 0.06
	end
	if what == "Point" or what == "PointLite" then
		rx = 1.5
	elseif what == "Wave" or what == "WaveLite" then
		rx, rz = 2.6, math.sin(since * 9) * 0.25
	elseif what == "Cheer" or what == "Clap" then
		local up = math.abs(math.sin(since * 6))
		rx, lx = 1.2 + up * 0.6, 1.2 + up * 0.6
	elseif what == "HandsOnHips" then
		rz, lz = 0.55, -0.55
	elseif what == "ArmsCrossed" then
		rx, lx = 0.9, 0.9
		rz, lz = -0.5, 0.5
	end
	return pitch, yaw, roll, rx, rz, lx, lz
end

local function apply(entry: Entry, t: number)
	local since = t - entry.Start
	local talking = t < entry.Until
	local pitch, yaw, roll, rx, rz, lx, lz = SimpleActing.pose(entry.Emotion, if talking or since < 1.6 then entry.Gesture else nil, since, talking, entry.Seed)
	if entry.Look then
		-- Mirar a un punto: el giro de la cabeza respecto al cuerpo (como mucho 70°)
		local okLook = pcall(function()
			local part0 = Joints.part0(entry.Neck)
			if part0 then
				local localDir = part0.CFrame:VectorToObjectSpace((entry.Look :: Vector3) - part0.Position)
				local flat = math.sqrt(localDir.X * localDir.X + localDir.Z * localDir.Z)
				if flat > 0.01 then
					yaw += math.clamp(math.atan2(-localDir.X, -localDir.Z), -1.2, 1.2)
					pitch += math.clamp(math.atan2(localDir.Y, flat), -0.5, 0.5) * 0.6
				end
			end
		end)
		if not okLook then
			entry.Look = nil
		end
	end
	Joints.setC0(entry.Neck, entry.NeckBase * CFrame.Angles(pitch, yaw, roll))
	if entry.Right and entry.RightBase then
		Joints.setC0(entry.Right, entry.RightBase * CFrame.Angles(0, 0, rx) * CFrame.Angles(rz, 0, 0))
	end
	if entry.Left and entry.LeftBase then
		Joints.setC0(entry.Left, entry.LeftBase * CFrame.Angles(0, 0, -lx) * CFrame.Angles(lz, 0, 0))
	end
end

local function rest(entry: Entry)
	pcall(Joints.setC0, entry.Neck, entry.NeckBase)
	if entry.Right and entry.RightBase then
		pcall(Joints.setC0, entry.Right, entry.RightBase)
	end
	if entry.Left and entry.LeftBase then
		pcall(Joints.setC0, entry.Left, entry.LeftBase)
	end
end

-- Un fotograma: actúan los que hablan o miran; los que han acabado vuelven a su postura y se olvidan
function SimpleActing.step(t: number?)
	local time = t or now()
	for model, entry in entries do
		if not model.Parent or not entry.Neck.Parent then
			entries[model] = nil
			continue
		end
		if time < entry.Until + 1.6 or entry.Look then
			local ok = pcall(apply, entry, time)
			if not ok then
				rest(entry)
				entries[model] = nil
			end
		else
			rest(entry)
			entries[model] = nil
		end
	end
	if next(entries) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function ensureLoop()
	if connection or SimpleActing._manual then
		return
	end
	connection = RunService.RenderStepped:Connect(function()
		SimpleActing.step()
	end)
end

function SimpleActing.speak(model: Instance?, emotion: string?, seconds: number?, gesture: string?)
	if not model or not model:IsA("Model") then
		return
	end
	local entry = entryOf(model :: Model)
	if not entry then
		return
	end
	local t = now()
	entry.Emotion = emotion or "Calm"
	entry.Gesture = gesture
	entry.Start = t
	entry.Until = t + math.max(0.8, seconds or 2)
	ensureLoop()
end

function SimpleActing.lookAt(model: Instance?, point: Vector3?)
	if not model or not model:IsA("Model") then
		return
	end
	local entry = entryOf(model :: Model)
	if not entry then
		return
	end
	entry.Look = point
	ensureLoop()
end

-- (pruebas) cuántos están actuando
function SimpleActing._count(): number
	local n = 0
	for _ in entries do
		n += 1
	end
	return n
end

return SimpleActing
