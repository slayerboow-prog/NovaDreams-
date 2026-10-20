-- MerBody (servidor): el cuerpo hondario de un JUGADOR (el Don de la Marea; en la fase 1, la «vida hondaria»
-- del modo pruebas: Services/HondarioService). docs/mar/civilizacion-marina.md §2.2 y §6.
--
--   * Se monta UNA vez por personaje, con piezas normales pegadas a las que ya tiene (nada de mallas subidas:
--     solo Part, WedgePart y la malla de esfera de Roblox, como la gente de Nácara de NacaraService):
--       cola de cuatro tramos con Motor6D desde la cadera (el cliente le da la onda: Controllers/MerForm),
--       aleta de dos lóbulos en abanico, escamas con la firma de luz, aletas en los antebrazos, cresta de
--       aleta en la cabeza, branquias finas en el cuello y un peto con hombreras de nácar (siempre vestido:
--       la ropa de cintura para arriba es la suya).
--   * MerBody.setForm(character, "Cola" | "Piernas"): con cola, las piernas (y lo que lleve pegado a ellas)
--     se esconden y sale todo lo hondario; con piernas, todo vuelve a como estaba (la transparencia de cada
--     pieza se guarda en el atributo MerT).
--   * Sin choques ni consultas (CanCollide/CanQuery/CanTouch false) y sin masa: no cambia cómo te mueves.

local MerBody = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

MerBody.Folder = "MerBody" -- carpeta dentro del personaje
MerBody.Legs = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }

export type Look = { Scales: Color3?, Crest: Color3?, Nacre: Color3? }
MerBody.DefaultLook = { Scales = rgb(40, 170, 190), Crest = rgb(120, 240, 255), Nacre = rgb(226, 222, 238) }

local function weldPart(folder: Instance, to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, class: string?): BasePart
	local p = Instance.new(class or "Part") :: BasePart
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.Transparency = 1 -- (se enseña con setForm)
	p.CFrame = to.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = p
	weld.Parent = p
	p.Parent = folder
	return p
end

local function sphereMesh(p: BasePart)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
end

-- Cuántas piezas lleva (para las pruebas y los topes)
function MerBody.count(character: Model): number
	local folder = character:FindFirstChild(MerBody.Folder)
	local n = 0
	for _, d in (if folder then folder:GetDescendants() else {}) do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

-- Monta el cuerpo hondario (escondido). Devuelve la carpeta, o nil si el personaje no tiene cadera.
function MerBody.build(character: Model, look: Look?): Folder?
	local existing = character:FindFirstChild(MerBody.Folder)
	if existing then
		return existing :: Folder
	end
	local hip = (character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not hip or not hip:IsA("BasePart") then
		return nil
	end
	local L = look or MerBody.DefaultLook
	local scales: Color3 = L.Scales or MerBody.DefaultLook.Scales
	local crest: Color3 = L.Crest or MerBody.DefaultLook.Crest
	local nacre: Color3 = L.Nacre or MerBody.DefaultLook.Nacre
	local light = scales:Lerp(Color3.new(1, 1, 1), 0.35)
	local folder = Instance.new("Folder")
	folder.Name = MerBody.Folder
	-- escala: la de la cadera de un adulto R15 mide 2 de ancho
	local k = math.clamp(hip.Size.X / 2, 0.3, 2)
	-- la cola: cuatro tramos con Motor6D (Transform lo mueve el cliente)
	local sizes = { V(1.85, 1.6, 1.05), V(1.5, 1.5, 0.9), V(1.1, 1.4, 0.72), V(0.66, 1.1, 0.5) }
	local prev: BasePart = hip
	for i, s in sizes do
		local size = s * k
		local seg = Instance.new("Part")
		seg.Name = "Cola" .. i
		seg.Size = size
		seg.Color = scales:Lerp(light, (i - 1) / 5)
		seg.Material = Enum.Material.SmoothPlastic
		seg.Reflectance = 0.08
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.Massless = true
		seg.CastShadow = false
		seg.Transparency = 1
		local motor = Instance.new("Motor6D")
		motor.Name = "ColaJunta" .. i
		motor.Part0 = prev
		motor.Part1 = seg
		motor.C0 = CF(0, -prev.Size.Y / 2 + (if i == 1 then 0.1 * k else 0.05 * k), 0)
		motor.C1 = CF(0, size.Y / 2, 0)
		seg.CFrame = prev.CFrame * motor.C0 * motor.C1:Inverse()
		motor.Parent = seg
		seg.Parent = folder
		prev = seg
	end
	-- la aleta: dos lóbulos en abanico (láminas finas: de frente se ve la aleta entera, no dos piernas)
	for s = -1, 1, 2 do
		weldPart(folder, prev, "Aleta", V(1.5, 0.75, 0.12) * k, CF(s * 0.62 * k, -0.55 * k, 0.05 * k) * CFrame.Angles(math.rad(-10), 0, math.rad(s * 28)), light)
	end
	-- la firma de luz en la cola y unas escamas de nácar
	local first = folder:FindFirstChild("Cola1") :: BasePart
	weldPart(folder, first, "FirmaCola", V(0.12, 1.3, 0.1) * k, CF(0, 0, -first.Size.Z / 2 - 0.03), crest, Enum.Material.Neon)
	local second = folder:FindFirstChild("Cola2") :: BasePart
	for s = -1, 1, 2 do
		weldPart(folder, second, "EscamaNacar", V(0.5, 0.5, 0.12) * k, CF(s * second.Size.X * 0.32, 0.2 * k, -second.Size.Z / 2 - 0.02), nacre, Enum.Material.SmoothPlastic).Reflectance = 0.25
	end
	-- el cinturón de red donde empieza la cola (tapa la unión con la cadera)
	weldPart(folder, hip, "Cinturon", V(hip.Size.X * 1.06, 0.34 * k, hip.Size.Z * 1.08), CF(0, -hip.Size.Y * 0.3, 0), crest:Lerp(Color3.new(0, 0, 0), 0.45), Enum.Material.Fabric)
	-- peto y hombreras de nácar (encima de su ropa: siempre vestido)
	local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if torso then
		local t = torso.Size
		weldPart(folder, torso, "PetoNacar", V(t.X * 0.7, t.Y * 0.36, 0.14), CF(0, t.Y * 0.18, -t.Z / 2 - 0.06), nacre).Reflectance = 0.2
	end
	for _, side in { "Left", "Right" } do
		local sx = if side == "Left" then -1 else 1
		local upper = character:FindFirstChild(side .. "UpperArm") :: BasePart?
		local lower = character:FindFirstChild(side .. "LowerArm") :: BasePart?
		if upper and upper:IsA("BasePart") then
			local pad = weldPart(folder, upper, "Hombrera", V(1.05, 0.4, 1.05) * k, CF(0, upper.Size.Y / 2 - 0.05, 0), nacre)
			sphereMesh(pad)
			weldPart(folder, upper, "FirmaBrazo", V(0.08, upper.Size.Y * 0.8, 0.08), CF(sx * (upper.Size.X / 2 + 0.02), 0, 0), crest, Enum.Material.Neon)
		end
		if lower and lower:IsA("BasePart") then
			weldPart(folder, lower, "AletaBrazo", V(0.12, lower.Size.Y * 0.9, 0.8 * k), CF(sx * (lower.Size.X / 2 + 0.05), 0, 0.25 * k) * CFrame.Angles(math.rad(-12), 0, 0), scales:Lerp(Color3.new(1, 1, 1), 0.25))
		end
	end
	local head = character:FindFirstChild("Head") :: BasePart?
	if head and head:IsA("BasePart") then
		local s = head.Size
		weldPart(folder, head, "Cresta", V(0.14, s.Y * 0.7, s.Z * 1.0), CF(0, s.Y * 0.55, 0.12) * CFrame.Angles(math.rad(-10), 0, 0), crest, Enum.Material.SmoothPlastic, "WedgePart")
		for side = -1, 1, 2 do
			weldPart(folder, head, "Branquias", V(0.06, 0.26, 0.38), CF(side * (s.X / 2 - 0.06), -s.Y * 0.4, 0.05), scales:Lerp(Color3.new(0, 0, 0), 0.3))
		end
	end
	folder.Parent = character
	character:SetAttribute("SeaForm", "Piernas")
	return folder
end

-- Lo que va pegado a una pierna (zapatos, accesorios de las piernas): también se esconde con la cola
local function legAccessories(character: Model, legs: { [string]: boolean }): { BasePart }
	local list = {}
	for _, acc in character:GetChildren() do
		if acc:IsA("Accessory") then
			local handle = acc:FindFirstChild("Handle")
			local weld = handle and handle:FindFirstChildWhichIsA("Weld")
			local to = weld and (weld.Part1 == handle and weld.Part0 or weld.Part1)
			if handle and handle:IsA("BasePart") and to and legs[to.Name] then
				table.insert(list, handle)
			end
		end
	end
	return list
end

local function hide(p: BasePart, on: boolean)
	if on then
		if p:GetAttribute("MerT") == nil then
			p:SetAttribute("MerT", p.Transparency)
		end
		p.Transparency = 1
	else
		local t = p:GetAttribute("MerT")
		if type(t) == "number" then
			p.Transparency = t
			p:SetAttribute("MerT", nil)
		end
	end
end

-- Cambia la forma: "Cola" (en el agua) o "Piernas" (en tierra). Devuelve si ha cambiado algo.
function MerBody.setForm(character: Model, form: string): boolean
	local folder = character:FindFirstChild(MerBody.Folder)
	if not folder then
		return false
	end
	local tail = form == "Cola"
	if character:GetAttribute("SeaForm") == form then
		return false
	end
	local legs = {}
	for _, name in MerBody.Legs do
		legs[name] = true
		local leg = character:FindFirstChild(name)
		if leg and leg:IsA("BasePart") then
			hide(leg, tail)
		end
	end
	for _, handle in legAccessories(character, legs) do
		hide(handle, tail)
	end
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = if tail then 0 else 1
		end
	end
	character:SetAttribute("SeaForm", form)
	return true
end

-- Con cola: si algo ha vuelto a enseñar las piernas (otra ropa, AvatarService), se esconden otra vez
function MerBody.enforce(character: Model)
	if character:GetAttribute("SeaForm") ~= "Cola" then
		return
	end
	for _, name in MerBody.Legs do
		local leg = character:FindFirstChild(name)
		if leg and leg:IsA("BasePart") and leg.Transparency < 1 then
			hide(leg, true)
		end
	end
end

-- Quita el cuerpo hondario (vuelta a la vida humana): piernas a la vista y fuera las piezas
function MerBody.remove(character: Model)
	MerBody.setForm(character, "Piernas")
	local folder = character:FindFirstChild(MerBody.Folder)
	if folder then
		folder:Destroy()
	end
	character:SetAttribute("SeaForm", nil)
end

return MerBody
