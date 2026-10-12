-- Pitch (compartido): la geometría de un campo de fútbol, sin nada de Roblox salvo CFrame/Vector3
-- (se prueba en scripts/test-futbol.luau). Lo usan Sports/Ball, Sports/FootballSim, FootballService
-- (servidor) y FootballClient (cliente).
--
-- Todo el juego se calcula en coordenadas DEL CAMPO ("locales"):
--   X  a lo largo (de la portería -1 a la +1), Y hacia arriba desde el césped, Z a lo ancho.
--   El centro del campo es (0, 0, 0). La portería del lado s (-1 o +1) está en x = s * GoalLine.
-- Así la física y la IA son las mismas en el campo del colegio, en el estadio o en un parque, y el
-- campo puede estar girado como sea en el mapa.

local Pitch = {}

export type Pitch = {
	Id: string,
	CFrame: CFrame, -- centro del campo a ras de césped (Y = arriba del mundo; X = a lo largo)
	Length: number, -- largo total (studs)
	Width: number, -- ancho total
	GoalLine: number, -- distancia del centro a la línea de gol (la mitad del largo, o donde están los postes)
	GoalWidth: number, -- de poste a poste
	GoalHeight: number, -- altura del larguero
	GoalDepth: number, -- fondo de la red
	PostRadius: number,
	BoardX: number, -- vallas invisibles (el balón no se escapa del recinto ni atraviesa paredes)
	BoardZ: number,
}

Pitch.BALL_RADIUS = 0.65

-- Un campo a partir de su centro, largo y ancho. opts: GoalLine, GoalWidth, GoalHeight, GoalDepth, Id
function Pitch.new(cf: CFrame, length: number, width: number, opts: { [string]: any }?): Pitch
	local o = opts or {}
	local half = length / 2
	-- Porterías por defecto según el tamaño (las del mapa: 12×6 en el colegio, 14×7,5 en el estadio)
	local big = length >= 100
	-- (GoalWidth = 0: sin porterías, p. ej. los pases en la calle)
	local goalWidth = o.GoalWidth or (if big then 14 elseif length >= 60 then 12 else 9)
	local goalHeight = if goalWidth <= 0 then 0 else (o.GoalHeight or (if big then 7.5 elseif length >= 60 then 6 else 4.5))
	return {
		Id = o.Id or "Campo",
		CFrame = cf,
		Length = length,
		Width = width,
		GoalLine = o.GoalLine or (half - 1),
		GoalWidth = goalWidth,
		GoalHeight = goalHeight,
		GoalDepth = o.GoalDepth or 3,
		PostRadius = 0.25,
		BoardX = half + (o.BoardMargin or 6),
		BoardZ = width / 2 + (o.BoardMargin or 6),
	}
end

---------------------------------------------------------------------
-- Coordenadas
---------------------------------------------------------------------

function Pitch.toLocal(p: Pitch, world: Vector3): Vector3
	return p.CFrame:PointToObjectSpace(world)
end

function Pitch.toWorld(p: Pitch, loc: Vector3): Vector3
	return p.CFrame:PointToWorldSpace(loc)
end

function Pitch.dirToLocal(p: Pitch, world: Vector3): Vector3
	return p.CFrame:VectorToObjectSpace(world)
end

function Pitch.dirToWorld(p: Pitch, loc: Vector3): Vector3
	return p.CFrame:VectorToWorldSpace(loc)
end

-- Plano (sin altura)
function Pitch.flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Dirección plana unitaria (o la de respaldo si es casi cero)
function Pitch.unitFlat(v: Vector3, fallback: Vector3?): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	if f.Magnitude < 1e-4 then
		return fallback or Vector3.new(1, 0, 0)
	end
	return f.Unit
end

---------------------------------------------------------------------
-- Sitios del campo
---------------------------------------------------------------------

-- Centro de la boca de gol del lado s (a ras de suelo)
function Pitch.goalCenter(p: Pitch, side: number): Vector3
	return Vector3.new(side * p.GoalLine, 0, 0)
end

-- Punto de penalti delante de la portería del lado s
function Pitch.penaltyDistance(p: Pitch): number
	return math.clamp(p.GoalLine * 0.24, 8, 12)
end
function Pitch.penaltySpot(p: Pitch, side: number): Vector3
	return Vector3.new(side * (p.GoalLine - Pitch.penaltyDistance(p)), 0, 0)
end

-- El área grande delante de la portería del lado s (fondo y medio ancho)
function Pitch.areaSize(p: Pitch): (number, number)
	return math.clamp(p.GoalLine * 0.32, 10, 17), math.min(p.Width / 2 - 2, p.GoalWidth * 1.6)
end
function Pitch.inArea(p: Pitch, loc: Vector3, side: number): boolean
	local depth, halfWidth = Pitch.areaSize(p)
	return loc.X * side >= p.GoalLine - depth and loc.X * side <= p.GoalLine + 0.5 and math.abs(loc.Z) <= halfWidth
end

-- ¿Dentro del terreno de juego? (margin: holgura; positivo = cuenta un poco por fuera)
function Pitch.inBounds(p: Pitch, loc: Vector3, margin: number?): boolean
	local m = margin or 0
	return math.abs(loc.X) <= p.GoalLine + m and math.abs(loc.Z) <= p.Width / 2 + m
end

-- Por dónde ha salido el balón (nil = sigue dentro). La línea se pasa con el balón ENTERO fuera.
--   "Side" = banda (saque de banda), "End" = línea de fondo (saque de puerta o córner)
-- (los goles los detecta Ball.step: un balón que entra en la portería no "sale")
function Pitch.exit(p: Pitch, loc: Vector3, radius: number?): string?
	local r = radius or Pitch.BALL_RADIUS
	if math.abs(loc.Z) > p.Width / 2 + r then
		return "Side"
	end
	if math.abs(loc.X) > p.GoalLine + r then
		-- Dentro de la portería no es fuera (de eso se encarga el gol)
		if math.abs(loc.Z) < p.GoalWidth / 2 and loc.Y < p.GoalHeight then
			return nil
		end
		return "End"
	end
	return nil
end

-- Punto de reanudación tras una salida (sobre la línea, un poco dentro)
--   Side: donde salió, en la banda. Corner: la esquina más cercana. GoalKick: el borde del área pequeña.
function Pitch.restartSpot(p: Pitch, kind: string, at: Vector3, side: number?): Vector3
	local halfW = p.Width / 2
	if kind == "Side" then
		local x = math.clamp(at.X, -p.GoalLine + 2, p.GoalLine - 2)
		return Vector3.new(x, 0, (if at.Z >= 0 then 1 else -1) * (halfW - 0.8))
	elseif kind == "Corner" then
		local s = side or (if at.X >= 0 then 1 else -1)
		return Vector3.new(s * (p.GoalLine - 0.8), 0, (if at.Z >= 0 then 1 else -1) * (halfW - 0.8))
	elseif kind == "GoalKick" then
		local s = side or (if at.X >= 0 then 1 else -1)
		return Vector3.new(s * (p.GoalLine - 5), 0, (if at.Z >= 0 then 1 else -1) * math.min(p.GoalWidth * 0.5, halfW - 2))
	end
	return Vector3.zero
end

-- Lleva un punto a dentro del campo (con margen desde las líneas)
function Pitch.clampInside(p: Pitch, loc: Vector3, margin: number?): Vector3
	local m = margin or 1
	return Vector3.new(math.clamp(loc.X, -p.GoalLine + m, p.GoalLine - m), loc.Y, math.clamp(loc.Z, -p.Width / 2 + m, p.Width / 2 - m))
end

---------------------------------------------------------------------
-- Campos del mapa (con Roblox): a partir de la pieza «Pitch» y de los postes que tenga cerca
---------------------------------------------------------------------

-- Nombres de las piezas de portería que construyen Kit/Civic y Kit/Districts
Pitch.PostNames = { GoalPost = true, Post = true }
Pitch.BarNames = { GoalBar = true, Crossbar = true }
Pitch.BlockNames = { Goal = true } -- (los campos de los barrios: un bloque de 1 × 8 × 20)

-- Describe un campo a partir de su pieza de césped y las piezas de portería de su modelo.
-- part: BasePart «Pitch»; siblings: lista de BaseParts del mismo modelo (o nil)
function Pitch.fromPart(part: BasePart, siblings: { BasePart }?, id: string?): Pitch
	local size = part.Size
	local alongX = size.X >= size.Z
	local top = part.CFrame * CFrame.new(0, size.Y / 2, 0)
	-- Solo el giro en horizontal (el césped está plano)
	local look = if alongX then top.RightVector else top.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	flatLook = if flatLook.Magnitude > 1e-3 then flatLook.Unit else Vector3.new(1, 0, 0)
	-- X local = a lo largo: CFrame.fromMatrix(pos, X, Y)
	local cf = CFrame.fromMatrix(top.Position, flatLook, Vector3.new(0, 1, 0))
	local length = if alongX then size.X else size.Z
	local width = if alongX then size.Z else size.X
	local opts: { [string]: any } = { Id = id, BoardMargin = 4 }
	-- Postes de verdad: la línea de gol, el ancho y la altura salen de ellos
	local postsX, postsZ, height = {}, {}, nil
	for _, sib in siblings or {} do
		local loc = cf:PointToObjectSpace(sib.Position)
		if math.abs(loc.Z) > width / 2 + 2 or math.abs(loc.X) > length / 2 + 4 or math.abs(loc.X) < length / 2 - 8 then
			continue
		end
		if Pitch.PostNames[sib.Name] then
			table.insert(postsX, math.abs(loc.X))
			table.insert(postsZ, math.abs(loc.Z))
			local h = sib.Size.Y
			height = math.max(height or 0, h)
		elseif Pitch.BlockNames[sib.Name] then
			table.insert(postsX, math.abs(loc.X))
			local local3 = cf:VectorToObjectSpace(sib.CFrame:VectorToWorldSpace(sib.Size))
			table.insert(postsZ, math.abs(local3.Z) / 2)
			height = math.max(height or 0, sib.Size.Y)
		end
	end
	if #postsX > 0 then
		local sx, sz = 0, 0
		for i = 1, #postsX do
			sx += postsX[i]
			sz += postsZ[i]
		end
		opts.GoalLine = sx / #postsX
		opts.GoalWidth = math.clamp(2 * sz / #postsZ, 6, 24)
		opts.GoalHeight = math.clamp(height or 6, 3, 10)
	end
	return Pitch.new(cf, length, width, opts)
end

return Pitch
