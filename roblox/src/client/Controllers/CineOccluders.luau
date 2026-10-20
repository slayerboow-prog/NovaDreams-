-- CineOccluders (cliente): que la cámara de las escenas VEA la decoración.
--
-- Por qué: casi todo lo decorativo del mapa (Builder.decor: copas de los árboles, tejas, hastiales,
-- toldos, balcones, contraventanas, marcos; los muebles de World/Furniture) se construye con
-- CanQuery = false para que el motor vaya más ligero. Pero la cámara de las conversaciones y de las
-- cinemáticas (CineCamera → CameraShots.fit / clearOff) busca paredes con workspace:Raycast, que NO
-- ve esas piezas: el ajuste creía libre el sitio y dejaba la cámara dentro de un toldo, de una copa, de
-- un balcón o detrás de un armario. Eso era lo de «en las cinemáticas aparecen paredes» (auditoría:
-- scripts/audit/cine-planos.luau --solo-consultables, docs/auditoria/cinematicas.md).
--
-- Cómo: un índice ligero (rejilla de 32 studs con REFERENCIAS a las piezas, nada más) de las piezas
-- sin CanQuery que tapan a la cámara (CameraShots.occluder, la misma regla que la auditoría), hecho
-- poco a poco al arrancar y al llegar piezas nuevas (StreamingEnabled). Mientras hay una escena, las
-- de alrededor del sitio donde se lanzan los rayos se ponen CanQuery = true SOLO en este cliente (no se
-- replica: el servidor y los demás no cambian) y, cuando la cámara de escena deja de preguntar unos
-- segundos, vuelven a su valor. Tope de piezas por escena para que no cueste.
--
--   CineOccluders.ensure(point)   (CineCamera, en cada rayo de la cámara de escena: barato si ya está)
--   CineOccluders.release()       (las devuelve ya; también se hace solo tras IDLE segundos)

local CameraShots = require(game:GetService("ReplicatedStorage").Shared.CameraShots)
local RunService = game:GetService("RunService")

local CineOccluders = {}
CineOccluders.CELL = 32
CineOccluders.RADIUS = 70 -- se activan las de este radio alrededor de donde mira la cámara
CineOccluders.MOVE = 8 -- rayos desde menos de esto del anterior: ya está (no se recorre nada)
CineOccluders.MAX = 9000 -- tope de piezas activas a la vez
CineOccluders.IDLE = 3 -- segundos sin rayos de escena: se devuelven
CineOccluders.BIG = 96 -- más grandes que esto (una fachada entera): lista aparte, siempre se miran

local CELL = CineOccluders.CELL
local grid: { [number]: { BasePart } } = {}
local big: { BasePart } = {}
local cellOf: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any
local active: { BasePart } = {}
local activeCells: { [number]: boolean } = {}
local bigOn = false
local lastPoint: Vector3? = nil
local lastUse = 0
local started = false

local function key(x: number, z: number): number
	return (x + 4096) * 8192 + (z + 4096)
end

local function skip(part: BasePart): boolean
	-- (los personajes y los actores de las escenas ya los tiene en cuenta CameraShots.fit como cuerpos)
	local scenes = workspace:FindFirstChild("StoryScenes")
	if scenes and part:IsDescendantOf(scenes) then
		return true
	end
	local camera = workspace.CurrentCamera
	if camera and part:IsDescendantOf(camera) then
		return true
	end
	local model = part:FindFirstAncestorOfClass("Model")
	return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function add(part: Instance)
	if not part:IsA("BasePart") or part:IsA("Terrain") or cellOf[part :: BasePart] then
		return
	end
	local p = part :: BasePart
	if not CameraShots.occluder(p.Transparency, p.Size, p.CanQuery, p:GetAttribute("Collider") == true) then
		return
	end
	if skip(p) then
		return
	end
	local s = p.Size
	if math.max(s.X, s.Y, s.Z) > CineOccluders.BIG then
		table.insert(big, p)
		cellOf[p] = -1
		return
	end
	local pos = p.Position
	local k = key(math.floor(pos.X / CELL), math.floor(pos.Z / CELL))
	local list = grid[k]
	if not list then
		list = {}
		grid[k] = list
	end
	table.insert(list, p)
	cellOf[p] = k
end

local function remove(part: Instance)
	local k = cellOf[part :: BasePart]
	if not k then
		return
	end
	cellOf[part :: BasePart] = nil
	local list = if k == -1 then big else grid[k]
	if list then
		local i = table.find(list, part :: BasePart)
		if i then
			list[i] = list[#list]
			list[#list] = nil
		end
	end
end

function CineOccluders.release()
	for _, p in active do
		if p.Parent then
			p.CanQuery = false
		end
	end
	table.clear(active)
	table.clear(activeCells)
	bigOn = false
	lastPoint = nil
end

local function activate(p: BasePart)
	if p.Parent and not p.CanQuery and #active < CineOccluders.MAX then
		p.CanQuery = true
		table.insert(active, p)
	end
end

-- Activa las celdas de alrededor de `point` que aún no lo estén (se acumulan durante la escena: el foco y
-- la cámara pueden estar a 40 studs; todo se devuelve junto cuando la escena acaba)
function CineOccluders.ensure(point: Vector3)
	lastUse = os.clock()
	if not started then
		CineOccluders.start()
	end
	if lastPoint and (point - lastPoint).Magnitude < CineOccluders.MOVE then
		return
	end
	lastPoint = point
	if not bigOn then
		bigOn = true
		for _, p in big do
			activate(p)
		end
	end
	local r = CineOccluders.RADIUS
	local cx, cz = math.floor(point.X / CELL), math.floor(point.Z / CELL)
	local reach = math.ceil(r / CELL)
	-- (de dentro afuera: con el tope, las de cerca primero)
	for ring = 0, reach do
		for x = cx - ring, cx + ring do
			for z = cz - ring, cz + ring do
				if math.max(math.abs(x - cx), math.abs(z - cz)) == ring then
					local k = key(x, z)
					if not activeCells[k] then
						activeCells[k] = true
						for _, p in grid[k] or {} do
							activate(p)
						end
					end
				end
			end
		end
	end
end

-- ¿Cuántas hay en el índice y activas? (pruebas y depuración)
function CineOccluders.stats(): (number, number)
	local n = #big
	for _, list in grid do
		n += #list
	end
	return n, #active
end

function CineOccluders.start()
	if started then
		return
	end
	started = true
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			-- (lo que llega con el streaming: con sus propiedades ya puestas al siguiente fotograma)
			task.defer(add, d)
		end
	end)
	workspace.DescendantRemoving:Connect(remove)
	task.spawn(function()
		local list = workspace:GetDescendants()
		for i, d in list do
			add(d)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)
	-- (sin rayos de escena unos segundos: todo vuelve a como estaba)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 then
			return
		end
		acc = 0
		if #active > 0 and os.clock() - lastUse > CineOccluders.IDLE then
			CineOccluders.release()
		end
	end)
end

return CineOccluders
