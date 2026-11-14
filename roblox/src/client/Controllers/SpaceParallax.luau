-- SpaceParallax (cliente): PROFUNDIDAD en el espacio («que parezca 3D», dueño, 14-11-2026).
--
-- El cielo del espacio es una caja de 6 imágenes infinitamente lejos: al volar no se mueve nada y parece
-- un fondo pintado. Aquí, unas estrellas y motas de polvo de verdad (puntos de luz en el mundo) a
-- distintas distancias de la cámara: al moverte, las cercanas pasan rápido y las lejanas despacio contra
-- el fondo quieto. Eso es lo que da sensación de espacio con distancia.
--
--   * Tres capas: polvo cercano (60-400 studs, motas pequeñas y tenues), estrellas medias (400-1400) y
--     lejanas (1400-3000, más brillantes y más grandes para que se vean). Cada punto vive en una caja
--     alrededor de la cámara; el que sale por un lado vuelve a entrar por el contrario (no se crean piezas
--     nuevas mientras vuelas).
--   * Solo se ven: dentro de la cámara, sin choque ni consultas ni sombra. Solo en la zona «Espacio»
--     (Controllers/EnvDirector.inSpace) y no en la arena. Cuántos, según los gráficos (Perf: GraphicsTier): Low 70, Medium 160,
--     High 260.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SpaceParallax = {}

local player = Players.LocalPlayer

SpaceParallax.Layers = {
	{ Name = "Polvo", Near = 60, Far = 400, Share = 0.4, Size = { 0.25, 0.6 }, Alpha = { 0.55, 0.8 } },
	{ Name = "Medias", Near = 400, Far = 1400, Share = 0.35, Size = { 1.2, 2.4 }, Alpha = { 0.15, 0.45 } },
	{ Name = "Lejanas", Near = 1400, Far = 3000, Share = 0.25, Size = { 3.2, 6 }, Alpha = { 0.05, 0.35 } },
}
SpaceParallax.Count = { Low = 70, Medium = 160, High = 260 }
SpaceParallax.Tints = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 220, 255), Color3.fromRGB(255, 236, 210), Color3.fromRGB(220, 200, 255) }

type Dot = { Part: BasePart, Offset: Vector3, Box: number }
local dots: { Dot } = {}
local folder: Folder? = nil
local anchor: Vector3? = nil -- (el centro de la caja: se mueve con la cámara a saltos)

local function inSpace(): boolean
	local ok, yes = pcall(function()
		return require(script.Parent.EnvDirector).inSpace()
	end)
	return ok and yes == true
end

-- (puro) Envuelve un desplazamiento dentro de una caja de lado 2·half (el punto que sale, entra por el otro lado)
function SpaceParallax.wrap(v: Vector3, half: number): Vector3
	local function w(x: number): number
		return ((x + half) % (2 * half)) - half
	end
	return Vector3.new(w(v.X), w(v.Y), w(v.Z))
end

local function build(count: number)
	local f = Instance.new("Folder")
	f.Name = "EstrellasCercanas"
	local rng = Random.new(4242)
	for _, layer in SpaceParallax.Layers do
		local n = math.max(1, math.floor(count * layer.Share))
		for _ = 1, n do
			local p = Instance.new("Part")
			p.Name = layer.Name
			p.Shape = Enum.PartType.Ball
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			local s = rng:NextNumber(layer.Size[1], layer.Size[2])
			p.Size = Vector3.one * s
			p.Color = SpaceParallax.Tints[rng:NextInteger(1, #SpaceParallax.Tints)]
			p.Transparency = rng:NextNumber(layer.Alpha[1], layer.Alpha[2])
			-- (una dirección al azar y una distancia de su capa)
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
			if dir.Magnitude < 1e-3 then
				dir = Vector3.new(0, 0, 1)
			end
			local off = dir.Unit * rng:NextNumber(layer.Near, layer.Far)
			p.Parent = f
			table.insert(dots, { Part = p, Offset = off, Box = layer.Far })
		end
	end
	folder = f
end

local function clear()
	if folder then
		folder:Destroy()
	end
	folder = nil
	table.clear(dots)
	anchor = nil
end

local function tierCount(): number
	local tier = player:GetAttribute("GraphicsTier")
	return SpaceParallax.Count[tier] or SpaceParallax.Count.Medium
end

local function step()
	local cam = workspace.CurrentCamera
	local want = cam ~= nil and inSpace() and player:GetAttribute("AirCombatWorld") ~= "Arena"
	if not want then
		if folder then
			clear()
		end
		return
	end
	if not folder then
		build(tierCount())
	end
	local f = folder :: Folder
	if f.Parent ~= cam then
		f.Parent = cam
	end
	local camPos = (cam :: Camera).CFrame.Position
	if not anchor then
		anchor = camPos
	end
	-- Cada punto está fijo en el mundo (anchor + Offset); cuando se aleja demasiado de la cámara, entra
	-- por el lado contrario de su caja. Así hay paralaje de verdad al volar.
	for _, dt in dots do
		local world = (anchor :: Vector3) + dt.Offset
		local rel = SpaceParallax.wrap(world - camPos, dt.Box)
		local pos = camPos + rel
		if (dt.Part.Position - pos).Magnitude > 0.05 then
			dt.Part.CFrame = CFrame.new(pos)
		end
		dt.Offset = pos - (anchor :: Vector3)
	end
end

function SpaceParallax.init()
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 1 / 30 then
			return
		end
		acc = 0
		local ok, err = pcall(step)
		if not ok then
			warn("[SpaceParallax] " .. tostring(err))
		end
	end)
	player:GetAttributeChangedSignal("GraphicsTier"):Connect(function()
		if folder then
			clear() -- (se rehace con el número nuevo en el siguiente paso)
		end
	end)
end

return SpaceParallax
