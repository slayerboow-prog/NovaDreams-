-- RainVeil (cliente): con lluvia, el cielo es una manta gris (v108).
--
-- El cielo de día es una FOTO (skybox azul con nubes blancas: shared/SkyChoice, o el de Roblox si no
-- carga). Las nubes volumétricas (Clouds) y la bruma (Atmosphere) se pintan encima, pero en el móvil
-- (nivel Bajo, calidad de Roblox baja) apenas tapan esa foto: el dueño veía «Lluvia» en el HUD con el
-- cielo azul. El skybox no se puede teñir, así que se pone delante un velo: una caja abierta por
-- abajo (5 placas finas, sin sombras, sin colisión, invisible a los rayos) alrededor de la cámara, a
-- ~900 studs (más allá de lo que se carga del mapa: StreamingTargetRadius 768). Como está lejos, la
-- bruma del aire la pinta de su color gris y el cielo queda gris y tapado; lo cercano no cambia.
--
-- Lo mueve DayLight (Veil y VeilColor de shared/DayGrade.weather) después de las capas de cielo de la
-- historia (SkyMoods: la Grieta…): si una capa de la historia está puesta, el velo se aparta para no
-- tapar su cielo. Coste: 5 piezas que solo se mueven si la cámara se ha movido más de 40 studs.

local RainVeil = {}

local RADIUS = 900 -- distancia a la cámara de cada pared del velo
local TOP = 520 -- altura del techo sobre la cámara
local BOTTOM = 380 -- hasta dónde baja (por debajo del horizonte)
local MOVE = 40 -- se recoloca cuando la cámara se ha movido esto

local folder: Folder? = nil
local plates: { BasePart } = {}
local anchor: Vector3? = nil
local shown = -1

local function plate(name: string, size: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.Transparency = 1
	p.Parent = folder
	return p
end

local function build()
	local f = Instance.new("Folder")
	f.Name = "RainVeil"
	f.Parent = workspace.CurrentCamera -- (solo en este dispositivo)
	folder = f
	local span = math.min(RADIUS * 2 + 40, 2048)
	local height = TOP + BOTTOM
	table.insert(plates, plate("Techo", Vector3.new(span, 2, span)))
	for i = 1, 4 do
		table.insert(plates, plate("Pared" .. i, Vector3.new(span, height, 2)))
	end
end

local function place(at: Vector3)
	anchor = at
	plates[1].CFrame = CFrame.new(at + Vector3.new(0, TOP, 0))
	local mid = (TOP - BOTTOM) / 2
	for i = 1, 4 do
		local angle = (i - 1) * math.pi / 2
		local dir = Vector3.new(math.sin(angle), 0, math.cos(angle))
		plates[i + 1].CFrame = CFrame.lookAt(at + dir * RADIUS + Vector3.new(0, mid, 0), at + Vector3.new(0, mid, 0))
	end
end

-- alpha: 0 = sin velo (cielo de siempre); 0,85 = cielo totalmente gris. color: el de la bruma.
function RainVeil.update(alpha: number, color: Color3?)
	alpha = math.clamp(alpha, 0, 0.9)
	if alpha < 0.01 then
		if shown ~= 0 and folder then
			for _, p in plates do
				p.Transparency = 1
			end
			-- (fuera del mundo mientras no llueve: nada que dibujar)
			(folder :: Folder).Parent = nil
		end
		shown = 0
		return
	end
	if not folder then
		build()
	end
	local f = folder :: Folder
	local camera = workspace.CurrentCamera
	if f.Parent ~= camera then
		f.Parent = camera
		anchor = nil
	end
	local at = camera.CFrame.Position
	if not anchor or (at - (anchor :: Vector3)).Magnitude > MOVE then
		place(at)
	end
	local transparency = 1 - alpha
	if math.abs(transparency - shown) > 0.01 or color then
		shown = transparency
		for _, p in plates do
			p.Transparency = transparency
			if color then
				p.Color = color
			end
		end
	end
end

return RainVeil
