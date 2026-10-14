-- Joints (compartido): las articulaciones del cuerpo, sean del tipo que sean.
--
-- Los avatares de Roblox pueden llevar dos clases de articulación:
--   * Motor6D (la de siempre): Part0/Part1 y C0/C1 son propiedades suyas
--   * AnimationConstraint (las articulaciones nuevas, las que tiene el juego publicado): no tiene
--     Part0/Part1 ni C0/C1; van en sus dos Attachment (Attachment0 en la pieza de dentro,
--     Attachment1 en la de fuera). Su CFrame hace de C0/C1 y su padre, de Part0/Part1.
-- Las dos tienen Transform y lo usan igual (el Animator lo escribe cada frame):
--   Motor6D:              Part1 = Part0 * C0 * Transform * C1:Inverse()
--   AnimationConstraint:  Part1 = Part0 * Attachment0.CFrame * Transform * Attachment1.CFrame:Inverse()
-- Así que las capas de postura (PoseLayers: read/write de .Transform) valen para las dos sin cambios;
-- lo único distinto es buscarlas y leer o mover su unión fija (C0), que es lo que hay aquí.
-- Antes cada módulo buscaba solo Motor6D: con las articulaciones nuevas no encontraba ninguna y la
-- postura hecha con código (agacharse, ir sentado, el gimnasio, los golpes…) no hacía nada.
--
-- Los NPC pueden seguir llevando Motor6D: todo funciona con las dos. En las pruebas las
-- articulaciones pueden ser tablas con C0/C1/Part0/Part1 (se tratan como Motor6D).

local Joints = {}

-- ¿Es una articulación que se mueve con Transform? (Motor6D o AnimationConstraint)
function Joints.isJoint(object: any): boolean
	if object == nil or typeof(object) ~= "Instance" then
		return false
	end
	return object:IsA("Motor6D") or object:IsA("AnimationConstraint")
end

-- ¿Se lee como un Motor6D (C0/C1/Part0/Part1 propios)? Se apunta: se pregunta muchas veces por frame.
local motorKind: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function isMotor(joint: any): boolean
	local known = motorKind[joint]
	if known == nil then
		known = typeof(joint) ~= "Instance" or joint:IsA("Motor6D") -- (las pruebas usan tablas con C0/C1)
		motorKind[joint] = known
	end
	return known
end
Joints.isMotor = isMotor

-- La unión fija con la pieza de dentro (Motor6D.C0 / Attachment0.CFrame)
function Joints.c0(joint: any): CFrame
	if isMotor(joint) then
		return joint.C0
	end
	local a = joint.Attachment0
	return if a then a.CFrame else CFrame.identity
end

-- La unión fija con la pieza de fuera (Motor6D.C1 / Attachment1.CFrame)
function Joints.c1(joint: any): CFrame
	if isMotor(joint) then
		return joint.C1
	end
	local a = joint.Attachment1
	return if a then a.CFrame else CFrame.identity
end

-- La pieza de dentro (Motor6D.Part0 / el padre de Attachment0)
function Joints.part0(joint: any): BasePart?
	if isMotor(joint) then
		return joint.Part0
	end
	local a = joint.Attachment0
	return a and a.Parent :: any
end

-- La pieza de fuera (Motor6D.Part1 / el padre de Attachment1)
function Joints.part1(joint: any): BasePart?
	if isMotor(joint) then
		return joint.Part1
	end
	local a = joint.Attachment1
	return a and a.Parent :: any
end

-- Mueve la unión fija con la pieza de dentro (Motor6D.C0 / Attachment0.CFrame). Para quien tuerce
-- el cuerpo sin pasar por Transform (PunchAnim, ActorLife, los NPC sentados del servidor).
function Joints.setC0(joint: any, value: CFrame)
	if isMotor(joint) then
		joint.C0 = value
		return
	end
	local a = joint.Attachment0
	if a then
		a.CFrame = value
	end
end

-- La articulación `name` del personaje: primero en su pieza (si se sabe), luego en cualquier sitio.
-- (No basta FindFirstChild(name, true): si lo primero que encuentra con ese nombre no es una
-- articulación, se sigue buscando.)
function Joints.find(model: Instance, name: string, partName: string?): any
	if partName then
		local part = model:FindFirstChild(partName)
		local joint = part and part:FindFirstChild(name)
		if Joints.isJoint(joint) then
			return joint
		end
	end
	local joint = model:FindFirstChild(name, true)
	if Joints.isJoint(joint) then
		return joint
	end
	if joint == nil then
		return nil
	end
	for _, d in model:GetDescendants() do
		if d.Name == name and Joints.isJoint(d) then
			return d
		end
	end
	return nil
end

-- Varias a la vez: `names` es una lista de nombres o un mapa nombre -> pieza donde suele estar
function Joints.collect(model: Instance, names: { [any]: string }): { [string]: any }
	local out = {}
	for key, value in names do
		if type(key) == "number" then
			out[value] = Joints.find(model, value)
		else
			out[key] = Joints.find(model, key, value)
		end
	end
	return out
end

-- ¿Ya no son de este personaje? (al aplicar el aspecto —AvatarService, al aparecer, al cambiar de
-- edad— Roblox cambia las piezas del cuerpo y con ellas las articulaciones: las viejas ya no mueven
-- nada y hay que volver a buscarlas)
function Joints.stale(joints: { [any]: any }, model: Instance): boolean
	for _, joint in joints do
		if typeof(joint) == "Instance" then
			local ok, inside = pcall(joint.IsDescendantOf, joint, model)
			if not ok or not inside then
				return true
			end
		end
	end
	return false
end

-- La forma del cuerpo (qué pieza mueve cada una y sus C0/C1) para AgeMotion.lowestPoint
function Joints.shape(joints: { [string]: any }): { Joints: { [string]: any }, Sizes: { [string]: Vector3 } }
	local shape = { Joints = {}, Sizes = {} }
	for name, joint in joints do
		local p0, p1 = Joints.part0(joint), Joints.part1(joint)
		if p0 and p1 then
			shape.Joints[name] = { Part0 = p0.Name, Part1 = p1.Name, C0 = Joints.c0(joint), C1 = Joints.c1(joint) }
			shape.Sizes[p1.Name] = p1.Size
		end
	end
	return shape
end

return Joints
