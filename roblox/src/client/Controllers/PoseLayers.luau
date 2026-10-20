-- PoseLayers (cliente): el sitio único donde se retoca Motor6D.Transform después de las animaciones.
-- (Vale igual para Motor6D y para AnimationConstraint, las articulaciones nuevas de Roblox: las dos
-- tienen Transform y lo usan igual, entre C0 —o Attachment0— y C1 —o Attachment1—; ver shared/Joints.)
--
-- Varios sistemas mueven el cuerpo con código encima de las animaciones de Roblox:
--   10 AgeMotion   cada edad a su manera (gatear, encorvado, oficios…)
--   20 Locomotion  inclinarse al girar y al correr, mirar hacia la cámara, aterrizar, sentarse suave
--   30 ReactMotion golpes, choques, gestos de coger cosas, pescar…
-- Antes cada uno apuntaba por su cuenta lo que había escrito ("Written") y lo que puso la
-- animación ("Base"). Con dos a la vez en una articulación que la animación no toca, el primero
-- veía lo que había escrito el segundo, lo tomaba por la animación y lo volvía a sumar: el cuerpo
-- se iba torciendo frame a frame. Aquí la cuenta es una sola por articulación y por frame:
--
--   read(joint)       lo que hay ahora en esta capa: la animación de este frame (o, si la animación
--                     no la ha tocado, la que había debajo) más lo que hayan puesto las capas anteriores
--   write(joint, cf)  deja cf y lo apunta
--   al acabar el frame, la articulación que nadie ha escrito vuelve a su animación (no se queda torcida)
--
-- Se ejecuta una vez por frame en PreSimulation (después de que Roblox anime y antes de la física),
-- llamando a cada capa en su orden. step/finish se pueden llamar a mano: scripts/test-motion.luau lo
-- prueba con articulaciones de mentira.

local PoseLayers = {}

type JointState = {
	Base: CFrame, -- lo que puso la animación (lo de debajo de todas las capas)
	Written: CFrame?, -- lo último que escribió una capa
	Value: CFrame, -- lo que hay en este frame tras las capas que ya han pasado
	Frame: number,
	Touched: boolean, -- alguna capa lo ha escrito este frame
}

type Layer = { Name: string, Order: number, Step: (dt: number, now: number) -> () }

local layers: { Layer } = {}
local states: { [any]: JointState } = setmetatable({}, { __mode = "k" }) :: any
local frame = 0
local started = false

-- ¿Es la misma transformación? (casi exacta: lo que se escribe puede volver con un redondeo)
local function same(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 1e-4 and a.LookVector:Dot(b.LookVector) > 0.999999 and a.UpVector:Dot(b.UpVector) > 0.999999
end
PoseLayers.same = same

local function stateOf(joint: any): JointState
	local s = states[joint]
	if not s then
		s = { Base = joint.Transform, Written = nil, Value = joint.Transform, Frame = -1, Touched = false }
		states[joint] = s
	end
	if s.Frame ~= frame then
		-- Primera vez en este frame: ¿la ha movido la animación?
		local current = joint.Transform
		if s.Written and same(current, s.Written) then
			current = s.Base -- no: seguimos desde lo que había debajo
		end
		s.Base = current
		s.Value = current
		s.Frame = frame
		s.Touched = false
	end
	return s
end

-- Lo que hay ahora en la articulación para la capa que la pide
function PoseLayers.read(joint: any): CFrame
	return stateOf(joint).Value
end

-- Lo que puso la animación (sin ninguna capa)
function PoseLayers.base(joint: any): CFrame
	return stateOf(joint).Base
end

function PoseLayers.write(joint: any, value: CFrame)
	local s = stateOf(joint)
	s.Value = value
	s.Written = value
	s.Touched = true
	joint.Transform = value
end

-- Añade una capa (orden de menor a mayor). Devuelve una función para quitarla.
function PoseLayers.add(name: string, order: number, step: (dt: number, now: number) -> ()): () -> ()
	local layer = { Name = name, Order = order, Step = step }
	table.insert(layers, layer)
	table.sort(layers, function(a, b)
		return a.Order < b.Order
	end)
	PoseLayers.start()
	return function()
		local i = table.find(layers, layer)
		if i then
			table.remove(layers, i)
		end
	end
end

-- Un frame: empieza la cuenta y pasa cada capa
function PoseLayers.step(dt: number, now: number)
	frame += 1
	for _, layer in layers do
		local ok, err = pcall(layer.Step, dt, now)
		if not ok then
			warn(("[PoseLayers] %s: %s"):format(layer.Name, tostring(err)))
		end
	end
	PoseLayers.finish()
end

-- Lo que nadie ha escrito este frame vuelve a la animación
function PoseLayers.finish()
	for joint, s in states do
		if s.Frame == frame and s.Touched then
			continue
		end
		if s.Written then
			local ok, current = pcall(function()
				return joint.Transform
			end)
			if ok and same(current, s.Written) then
				joint.Transform = s.Base
			end
		end
		states[joint] = nil
	end
end

-- Para las pruebas: vuelve a empezar de cero
function PoseLayers.reset()
	table.clear(layers)
	table.clear(states)
	frame = 0
end

function PoseLayers.start()
	if started or type(game) ~= "userdata" then
		return -- (en las pruebas se llama a step a mano)
	end
	started = true
	local RunService = game:GetService("RunService")
	local signal = (RunService :: any).PreSimulation or RunService.Stepped
	signal:Connect(function(a, b)
		local dt = if typeof(b) == "number" then b else a -- Stepped da (tiempo, dt)
		PoseLayers.step(dt, os.clock())
	end)
end

return PoseLayers
