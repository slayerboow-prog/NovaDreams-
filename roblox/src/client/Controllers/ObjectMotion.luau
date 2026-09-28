-- ObjectMotion (cliente): las cosas del mapa se mueven.
--
--   * Árboles y palmeras: la copa se mece con el viento (más con lluvia o tormenta). Las hojas de las
--     palmeras, además, se agitan cada una a su ritmo.
--   * Columpios: se balancean un poco colgados de la barra.
--   * Banderas: ondean (cada bandera se dibuja en trozos que se mueven como una tela).
--   * Feria: la noria gira (las cabinas cuelgan derechas), el carrusel da vueltas con los caballitos
--     subiendo y bajando, y una vagoneta recorre la montaña rusa.
--   * Fuentes: echan un chorro de agua.
--
-- El mapa marca estas piezas con etiquetas (Sway, Swing, Flag, Noria, Carousel, CoasterTrack,
-- Fountain) y atributos (Pivot: punto de giro; Axis: eje). Todo se hace solo en tu pantalla y solo
-- cerca de ti; al alejarte, cada pieza vuelve a su sitio. Con la carga por zonas (streaming), las
-- piezas que llegan se añaden solas.
--
-- Las cuentas (cuánto gira cada cosa) son funciones puras: scripts/test-objects.luau

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local ObjectMotion = {}

local sin = math.sin
local angles = CFrame.Angles

local RADIUS = { Sway = 90, Swing = 80, Flag = 160, Noria = 400, Carousel = 250, Fountain = 120 }
local MAX_SWAY = 260 -- hojas a la vez (lo más caro: hay muchas)
local MAX_FLAGS = 10

---------------------------------------------------------------------
-- Cuentas (puras)
---------------------------------------------------------------------

-- Viento según el tiempo que hace (1 = brisa normal)
function ObjectMotion.windFor(weather: string?): number
	if weather == "Tormenta" then
		return 3
	elseif weather == "Lluvia" or weather == "Nieve" then
		return 1.8
	elseif weather == "Nublado" then
		return 1.3
	end
	return 1
end

-- Copa que se mece: giro pequeño alrededor de la punta del tronco
function ObjectMotion.sway(t: number, phase: number, wind: number, leaf: boolean): CFrame
	local a = 0.018 * wind
	local x = (sin(t * 0.9 + phase) + 0.35 * sin(t * 2.3 + phase * 1.7)) * a
	local z = (sin(t * 0.7 + phase * 1.3) + 0.3 * sin(t * 1.9 + phase)) * a
	if leaf then
		-- Las hojas de palmera, más sueltas
		x += sin(t * 3.1 + phase * 2.3) * 0.03 * wind
	end
	return angles(x, 0, z)
end

-- Columpio: vaivén suave colgado de la barra
function ObjectMotion.swing(t: number, phase: number, wind: number): number
	return sin(t * 1.7 + phase) * 0.07 * wind + sin(t * 0.43 + phase) * 0.03
end

-- Bandera: el trozo i (de n) gira respecto al anterior; juntos forman una ola
function ObjectMotion.flag(t: number, phase: number, wind: number, i: number, n: number): number
	local k = i / n
	return sin(t * (3 + wind) - i * 1.1 + phase) * (0.18 + 0.12 * k) * math.min(wind, 2)
end

-- Noria: ángulo de giro (una vuelta cada ~2 minutos)
function ObjectMotion.noria(t: number): number
	return (t * 0.05) % (math.pi * 2)
end

-- Carrusel: ángulo y altura de los caballitos
function ObjectMotion.carousel(t: number, phase: number): (number, number)
	return (t * 0.35) % (math.pi * 2), sin(t * 2.2 + phase) * 0.6
end

-- Vagoneta: dónde va (0..1 del recorrido), de ida y vuelta, a velocidad constante
function ObjectMotion.coaster(t: number, length: number): number
	if length <= 0 then
		return 0
	end
	local speed = 22 -- studs por segundo
	local f = ((t * speed) / length) % 2
	return if f <= 1 then f else 2 - f
end

---------------------------------------------------------------------
-- Piezas marcadas
---------------------------------------------------------------------

type Entry = {
	Part: BasePart,
	Tag: string,
	Base: CFrame,
	Pivot: Vector3?,
	Axis: Vector3?,
	Role: string?,
	Leaf: boolean,
	Phase: number,
	Moved: boolean,
	Extra: any, -- trozos de bandera, chorro de la fuente…
}

local entries: { [BasePart]: Entry } = {}
local active: { Entry } = {}
local coasterTracks: { [number]: BasePart } = {}
local coasterCart: { BasePart }? = nil
local folder: Folder

local TAGS = { "Sway", "Swing", "Flag", "Noria", "Carousel", "Fountain" }

local function add(part: Instance, tag: string)
	if not part:IsA("BasePart") or entries[part] then
		return
	end
	local pivot = part:GetAttribute("Pivot")
	local axis = part:GetAttribute("Axis")
	entries[part] = {
		Part = part,
		Tag = tag,
		Base = part.CFrame,
		Pivot = if typeof(pivot) == "Vector3" then pivot else nil,
		Axis = if typeof(axis) == "Vector3" and axis.Magnitude > 0 then axis.Unit else nil,
		Role = part:GetAttribute("Role"),
		Leaf = part:GetAttribute("Leaf") == true,
		-- Mismo árbol, mismo ritmo (desfase según dónde está el tronco)
		Phase = if typeof(pivot) == "Vector3" then (pivot.X * 0.37 + pivot.Z * 0.23) % 6.28 else math.random() * 6.28,
		Moved = false,
		Extra = nil,
	}
end

local function remove(part: Instance)
	local entry = entries[part :: BasePart]
	if entry then
		if entry.Extra and entry.Extra.Destroy then
			entry.Extra:Destroy()
		end
		entries[part :: BasePart] = nil
	end
end

-- Vuelve a dejar la pieza como estaba y quita lo añadido
local function rest(entry: Entry)
	if entry.Moved and entry.Part.Parent then
		entry.Part.CFrame = entry.Base
	end
	entry.Moved = false
	if entry.Tag == "Flag" then
		entry.Part.LocalTransparencyModifier = 0
	end
	if entry.Extra then
		entry.Extra:Destroy()
		entry.Extra = nil
	end
end

-- Bandera en trozos (la original se oculta solo en tu pantalla)
local FLAG_PIECES = 5
local function flagPieces(entry: Entry): Model
	local model = Instance.new("Model")
	model.Name = "Bandera"
	local p = entry.Part
	for i = 1, FLAG_PIECES do
		local piece = Instance.new("Part")
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanQuery = false
		piece.CanTouch = false
		piece.CastShadow = false
		piece.Size = Vector3.new(p.Size.X / FLAG_PIECES + 0.02, p.Size.Y, p.Size.Z)
		piece.Color = p.Color
		piece.Material = p.Material
		piece.Parent = model
	end
	model.Parent = folder
	p.LocalTransparencyModifier = 1
	return model
end

-- Chorro de la fuente (partículas, solo en tu pantalla)
local function fountainJet(entry: Entry): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = "Chorro"
	attachment.WorldCFrame = CFrame.new(entry.Part.Position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	attachment.Parent = workspace.Terrain
	local jet = Instance.new("ParticleEmitter")
	jet.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	jet.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	jet.LightEmission = 0.3
	jet.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	jet.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2) })
	jet.Lifetime = NumberRange.new(1, 1.4)
	jet.Rate = 40
	jet.Speed = NumberRange.new(13, 15)
	jet.SpreadAngle = Vector2.new(8, 8)
	jet.Acceleration = Vector3.new(0, -workspace.Gravity * 0.12, 0)
	jet.EmissionDirection = Enum.NormalId.Right -- el eje X del attachment apunta arriba
	jet.Parent = attachment
	return attachment
end

local function place(entry: Entry, t: number, wind: number)
	local p = entry.Part
	local tag = entry.Tag
	if tag == "Sway" and entry.Pivot then
		local pivot = entry.Pivot
		p.CFrame = CFrame.new(pivot) * ObjectMotion.sway(t, entry.Phase, wind, entry.Leaf) * CFrame.new(-pivot) * entry.Base
		entry.Moved = true
	elseif tag == "Swing" and entry.Pivot and entry.Axis then
		local pivot = entry.Pivot
		local rotation = CFrame.fromAxisAngle(entry.Axis, ObjectMotion.swing(t, entry.Phase, wind))
		p.CFrame = CFrame.new(pivot) * rotation * CFrame.new(-pivot) * entry.Base
		entry.Moved = true
	elseif tag == "Noria" and entry.Pivot and entry.Axis then
		local pivot = entry.Pivot
		local rotation = CFrame.fromAxisAngle(entry.Axis, ObjectMotion.noria(t))
		if entry.Role == "Cabin" then
			-- Cuelga del aro: se mueve con él pero sin girar
			local hang = entry.Base.Position + Vector3.new(0, 3, 0) - pivot
			local at = pivot + rotation:VectorToWorldSpace(hang) - Vector3.new(0, 3, 0)
			p.CFrame = CFrame.new(at) * entry.Base.Rotation
		else
			p.CFrame = CFrame.new(pivot) * rotation * CFrame.new(-pivot) * entry.Base
		end
		entry.Moved = true
	elseif tag == "Carousel" and entry.Pivot then
		local pivot = entry.Pivot
		local angle, bob = ObjectMotion.carousel(t, entry.Phase)
		local lift = if entry.Role == "Horse" then bob else 0
		p.CFrame = CFrame.new(0, lift, 0) * CFrame.new(pivot) * angles(0, angle, 0) * CFrame.new(-pivot) * entry.Base
		entry.Moved = true
	elseif tag == "Flag" then
		if not entry.Extra then
			entry.Extra = flagPieces(entry)
		end
		-- Desde el mástil (lado izquierdo de la bandera) hacia fuera, trozo a trozo
		local base = entry.Base
		local width = p.Size.X / FLAG_PIECES
		local cf = base * CFrame.new(-p.Size.X / 2, 0, 0)
		for i, piece in (entry.Extra :: Model):GetChildren() do
			cf = cf * angles(0, ObjectMotion.flag(t, entry.Phase, wind, i, FLAG_PIECES), 0)
			local part = piece :: BasePart
			part.CFrame = cf * CFrame.new(width / 2, 0, 0)
			cf = cf * CFrame.new(width, 0, 0)
		end
	elseif tag == "Fountain" then
		if not entry.Extra then
			entry.Extra = fountainJet(entry)
		end
	end
end

-- Vagoneta de la montaña rusa: recorre las vías de ida y vuelta
local function coaster(t: number)
	local points = {}
	local indices = {}
	for index, track in coasterTracks do
		if track.Parent then
			table.insert(indices, index)
		end
	end
	table.sort(indices)
	for _, index in indices do
		local track = coasterTracks[index]
		local half = track.CFrame.LookVector * (track.Size.Z / 2 - 0.2)
		if #points == 0 then
			table.insert(points, track.Position + half)
		end
		table.insert(points, track.Position - half)
	end
	if #points < 2 then
		if coasterCart then
			for _, part in coasterCart do
				part:Destroy()
			end
			coasterCart = nil
		end
		return
	end
	if not coasterCart then
		local cart = {}
		for i = 1, 2 do
			local part = Instance.new("Part")
			part.Name = "Vagoneta"
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Size = Vector3.new(3.4, 1.8, 3.6)
			part.Color = if i == 1 then Color3.fromRGB(250, 200, 40) else Color3.fromRGB(40, 120, 220)
			part.Material = Enum.Material.SmoothPlastic
			part.Parent = folder
			table.insert(cart, part)
		end
		coasterCart = cart
	end
	local lengths, total = {}, 0
	for i = 1, #points - 1 do
		lengths[i] = (points[i + 1] - points[i]).Magnitude
		total += lengths[i]
	end
	for k, part in coasterCart :: { BasePart } do
		local distance = math.clamp(ObjectMotion.coaster(t, total) * total - (k - 1) * 4, 0, total)
		for i = 1, #points - 1 do
			if distance <= lengths[i] or i == #points - 1 then
				local a, b = points[i], points[i + 1]
				local at = a:Lerp(b, math.clamp(distance / math.max(lengths[i], 0.01), 0, 1))
				part.CFrame = CFrame.lookAt(at, at + (b - a)) * CFrame.new(0, 1.3, 0)
				break
			end
			distance -= lengths[i]
		end
	end
end

function ObjectMotion.init()
	folder = Instance.new("Folder")
	folder.Name = "ObjectMotion"
	folder.Parent = workspace.CurrentCamera -- solo para este jugador

	for _, tag in TAGS do
		for _, part in CollectionService:GetTagged(tag) do
			add(part, tag)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(part)
			add(part, tag)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	end
	local function addTrack(part: Instance)
		local index = part:GetAttribute("Index")
		if part:IsA("BasePart") and type(index) == "number" then
			coasterTracks[index] = part
		end
	end
	for _, part in CollectionService:GetTagged("CoasterTrack") do
		addTrack(part)
	end
	CollectionService:GetInstanceAddedSignal("CoasterTrack"):Connect(addTrack)
	CollectionService:GetInstanceRemovedSignal("CoasterTrack"):Connect(function(part)
		local index = part:GetAttribute("Index")
		if type(index) == "number" and coasterTracks[index] == part then
			coasterTracks[index] = nil
		end
	end)

	-- Qué está cerca (una vez por segundo)
	task.spawn(function()
		while true do
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position or Vector3.zero
			local near: { { Entry: Entry, Distance: number } } = {}
			for part, entry in entries do
				if not part.Parent then
					entries[part] = nil
					continue
				end
				local distance = (part.Position - from).Magnitude
				if distance < (RADIUS[entry.Tag] or 100) then
					table.insert(near, { Entry = entry, Distance = distance })
				end
			end
			table.sort(near, function(a, b)
				return a.Distance < b.Distance
			end)
			local nextActive, keep = {}, {}
			local sways, flags = 0, 0
			for _, item in near do
				local entry = item.Entry
				if entry.Tag == "Sway" then
					sways += 1
					if sways > MAX_SWAY then
						continue
					end
				elseif entry.Tag == "Flag" then
					flags += 1
					if flags > MAX_FLAGS then
						continue
					end
				end
				table.insert(nextActive, entry)
				keep[entry] = true
			end
			for _, entry in active do
				if not keep[entry] then
					pcall(rest, entry)
				end
			end
			active = nextActive
			task.wait(1)
		end
	end)

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		-- 30 veces por segundo es suficiente (y la mitad de trabajo en el móvil)
		accumulator += dt
		if accumulator < 1 / 30 then
			return
		end
		accumulator = 0
		local t = workspace:GetServerTimeNow() -- igual para todos: la noria está en el mismo sitio
		local wind = ObjectMotion.windFor(workspace:GetAttribute("Weather"))
		for _, entry in active do
			if entry.Part.Parent then
				local ok, err = pcall(place, entry, t, wind)
				if not ok then
					warn("[ObjectMotion] " .. tostring(err))
					entry.Tag = "Roto" -- no se vuelve a intentar con esta pieza
					entries[entry.Part] = nil
				end
			end
		end
		local ok, err = pcall(coaster, t)
		if not ok then
			warn("[ObjectMotion] " .. tostring(err))
		end
	end)
end

return ObjectMotion
