-- Horizon (cliente): las montañas del fondo (las cuentas, en shared/Horizon).
--
--   * Silueta de cada montaña del terreno: se ve de lejos y se esconde al acercarte (entonces ya
--     ha llegado el terreno de verdad con la carga por zonas).
--   * Sierra lejana al otro lado del mar, al norte: solo en los niveles gráficos Medio y Alto.
-- Son piezas solo de esta pantalla (no van por la red), de una pieza cada montaña, sin colisión, sin
-- consultas y sin sombra: muy baratas. La bruma (Atmosphere) las pinta azuladas por la distancia.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graphics = require(ReplicatedStorage.Shared.Graphics)
local HorizonMath = require(ReplicatedStorage.Shared.Horizon)
local Perf = require(script.Parent.Parent.UI.Perf)

local Horizon = {}

type Built = { Piece: HorizonMath.Piece, Part: BasePart }

local built: { Built } = {}
local farOn = true

local function make(folder: Instance, piece: HorizonMath.Piece): BasePart
	local part = Instance.new("Part")
	part.Name = piece.Name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Locked = true
	local max = HorizonMath.MaxSize
	part.Size = Vector3.new(math.min(piece.Size.X, max), math.min(piece.Size.Y, max), math.min(piece.Size.Z, max))
	part.CFrame = CFrame.new(piece.Center)
	part.Color = piece.Color
	part.Material = piece.Material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere -- rellena la caja de la pieza: un elipsoide
	mesh.Parent = part
	part.Parent = folder
	return part
end

local function refresh()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	for _, b in built do
		local show = HorizonMath.visible(b.Piece, eye) and (farOn or not b.Piece.Far)
		local want = if show then 0 else 1
		if b.Part.LocalTransparencyModifier ~= want then
			b.Part.LocalTransparencyModifier = want
		end
	end
end

local function applyTier(name: Graphics.TierName)
	farOn = Graphics.tier(name).FarRange
	refresh()
end

function Horizon.init()
	local folder = Instance.new("Folder")
	folder.Name = "Horizonte"
	for _, piece in HorizonMath.mountainPieces() do
		table.insert(built, { Piece = piece, Part = make(folder, piece) })
	end
	for _, piece in HorizonMath.farPieces() do
		table.insert(built, { Piece = piece, Part = make(folder, piece) })
	end
	folder.Parent = workspace
	applyTier(Perf.tierName())
	Perf.onTier(applyTier)
	-- Dos veces por segundo basta: las montañas están lejos
	task.spawn(function()
		while folder.Parent do
			refresh()
			task.wait(0.5)
		end
	end)
end

return Horizon
