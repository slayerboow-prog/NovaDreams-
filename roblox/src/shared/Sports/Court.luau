-- Court (compartido): la geometría de una pista de baloncesto, en coordenadas de la pista
-- (como Sports/Pitch): X a lo largo (de la canasta -1 a la +1), Y arriba desde el suelo, Z a lo ancho.
-- Una pista entera tiene dos canastas; media pista (la del parque, la del gimnasio del colegio), solo
-- la del lado +1. Se prueba en scripts/test-baloncesto.luau.

local Court = {}

export type Hoop = {
	Side: number,
	Rim: Vector3, -- centro del aro (local)
	Radius: number, -- radio del aro
	Board: Vector3, -- centro del tablero (local)
	BoardHalf: Vector2, -- medio ancho (a lo ancho de la pista) y media altura del tablero
	Normal: Vector3, -- del tablero hacia la pista (plano)
}

export type Court = {
	Id: string,
	CFrame: CFrame,
	Length: number,
	Width: number,
	Hoops: { [number]: Hoop },
	BoardX: number,
	BoardZ: number,
	Half: boolean,
}

Court.BALL_RADIUS = 0.6

function Court.new(cf: CFrame, length: number, width: number, hoops: { [number]: Hoop }, opts: { [string]: any }?): Court
	local o = opts or {}
	return {
		Id = o.Id or "Pista",
		CFrame = cf,
		Length = length,
		Width = width,
		Hoops = hoops,
		BoardX = length / 2 + (o.BoardMargin or 4),
		BoardZ = width / 2 + (o.BoardMargin or 4),
		Half = hoops[-1] == nil,
	}
end

-- Una canasta estándar en el lado `side` de una pista de largo `length`: aro a `height` del suelo
function Court.hoop(length: number, side: number, height: number?, radius: number?): Hoop
	local h = height or 9
	local r = radius or 1
	local boardX = side * (length / 2 - 0.4)
	local rimX = boardX - side * (r + 0.35)
	return {
		Side = side,
		Rim = Vector3.new(rimX, h, 0),
		Radius = r,
		Board = Vector3.new(boardX, h + 1, 0),
		BoardHalf = Vector2.new(3, 1.8),
		Normal = Vector3.new(-side, 0, 0),
	}
end

function Court.toLocal(c: Court, world: Vector3): Vector3
	return c.CFrame:PointToObjectSpace(world)
end
function Court.toWorld(c: Court, loc: Vector3): Vector3
	return c.CFrame:PointToWorldSpace(loc)
end
function Court.dirToLocal(c: Court, world: Vector3): Vector3
	return c.CFrame:VectorToObjectSpace(world)
end
function Court.dirToWorld(c: Court, loc: Vector3): Vector3
	return c.CFrame:VectorToWorldSpace(loc)
end

-- Distancia (en planta) desde la que una canasta vale 3
function Court.threeDistance(c: Court): number
	return math.clamp(c.Length * 0.27, 11, 19)
end

-- Cuánto vale una canasta tirada desde `from` hacia la canasta `hoop`
function Court.points(c: Court, hoop: Hoop, from: Vector3): number
	local d = Vector3.new(from.X - hoop.Rim.X, 0, from.Z - hoop.Rim.Z).Magnitude
	return if d >= Court.threeDistance(c) then 3 else 2
end

-- La línea de tiros libres de una canasta (en el suelo)
function Court.freeThrowSpot(c: Court, hoop: Hoop): Vector3
	local p = hoop.Rim + hoop.Normal * math.clamp(c.Length * 0.17, 7, 10)
	return Vector3.new(p.X, 0, p.Z)
end

-- ¿Fuera de la pista? (el balón entero fuera de las líneas)
function Court.out(c: Court, loc: Vector3, radius: number?): boolean
	local r = radius or Court.BALL_RADIUS
	return math.abs(loc.X) > c.Length / 2 + r or math.abs(loc.Z) > c.Width / 2 + r
end

function Court.clampInside(c: Court, loc: Vector3, margin: number?): Vector3
	local m = margin or 1
	return Vector3.new(math.clamp(loc.X, -c.Length / 2 + m, c.Length / 2 - m), loc.Y, math.clamp(loc.Z, -c.Width / 2 + m, c.Width / 2 - m))
end

---------------------------------------------------------------------
-- Pistas del mapa (con Roblox)
---------------------------------------------------------------------

-- ¿Es esta pieza el aro de una canasta? (naranja, pequeño; los «Rim» de las ruedas no lo son)
function Court.isRim(part: any): boolean
	if part.Name ~= "Rim" then
		return false
	end
	local c = part.Color
	if not (c.R > 0.7 and c.G < 0.55 and c.B < 0.35) then
		return false
	end
	local s = part.Size
	local sizes = { s.X, s.Y, s.Z }
	table.sort(sizes)
	return sizes[3] >= 1.4 and sizes[3] <= 3.2 and sizes[1] <= 0.5
end

function Court.rimRadius(part: any): number
	local s = part.Size
	local sizes = { s.X, s.Y, s.Z }
	table.sort(sizes)
	return sizes[3] / 2
end

-- (Aquí y abajo, .CFrame.Position en vez de .Position: así funciona igual con las piezas de Lune,
-- que no tienen Position, y scripts/test-baloncesto.luau prueba el mapa construido con este código)

-- Una pista a partir de su suelo (`floor`: pieza «Court»/«HalfCourt», o nil para media pista
-- imaginaria delante del aro) y sus aros (cada uno con su tablero). rims: { { Part, Board } }
function Court.fromParts(floor: any?, rims: { { [string]: any } }, id: string?): Court?
	if #rims == 0 then
		return nil
	end
	local first = rims[1]
	local rimPos = first.Part.CFrame.Position
	local boardPos = first.Board.CFrame.Position
	local normal = Vector3.new(rimPos.X - boardPos.X, 0, rimPos.Z - boardPos.Z)
	normal = if normal.Magnitude > 1e-3 then normal.Unit else Vector3.new(1, 0, 0)
	local cf: CFrame
	local length: number
	local width: number
	local half = #rims < 2
	if floor then
		local top = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
		local alongX = floor.Size.X >= floor.Size.Z
		if half then
			-- Media pista: X hacia el aro
			local axis = -normal
			cf = CFrame.fromMatrix(top.Position, axis, Vector3.new(0, 1, 0))
			local localSize = floor.CFrame:VectorToObjectSpace(cf.XVector)
			length = if math.abs(localSize.X) > math.abs(localSize.Z) then floor.Size.X else floor.Size.Z
			width = if math.abs(localSize.X) > math.abs(localSize.Z) then floor.Size.Z else floor.Size.X
		else
			local a = rims[1].Part.CFrame.Position
			local b = rims[2].Part.CFrame.Position
			local axis = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			axis = if axis.Magnitude > 1e-3 then axis.Unit else (if alongX then top.RightVector else top.LookVector)
			cf = CFrame.fromMatrix(top.Position, axis, Vector3.new(0, 1, 0))
			length = if alongX then floor.Size.X else floor.Size.Z
			width = if alongX then floor.Size.Z else floor.Size.X
		end
	else
		-- Sin suelo marcado (el gimnasio): media pista de 20 × 18 delante del aro, a ras del suelo de abajo
		local floorY = first.FloorY or (rimPos.Y - 7.8)
		local axis = -normal
		local center = Vector3.new(boardPos.X, floorY, boardPos.Z) - axis * 10
		cf = CFrame.fromMatrix(center, axis, Vector3.new(0, 1, 0))
		length, width = 20, 18
	end
	local hoops: { [number]: Hoop } = {}
	for _, r in rims do
		local rim = cf:PointToObjectSpace(r.Part.CFrame.Position)
		local board = cf:PointToObjectSpace(r.Board.CFrame.Position)
		local side = if rim.X >= 0 then 1 else -1
		if half then
			side = 1
		end
		local n = Vector3.new(rim.X - board.X, 0, rim.Z - board.Z)
		n = if n.Magnitude > 1e-3 then n.Unit else Vector3.new(-side, 0, 0)
		local bs = r.Board.Size
		local sizes = { bs.X, bs.Y, bs.Z }
		table.sort(sizes)
		hoops[side] = {
			Side = side,
			Rim = rim,
			Radius = Court.rimRadius(r.Part),
			Board = board,
			BoardHalf = Vector2.new(sizes[3] / 2, sizes[2] / 2),
			Normal = n,
		}
	end
	return Court.new(cf, length, width, hoops, { Id = id, BoardMargin = if floor then 4 else 0.5 })
end

-- El tablero de un aro: la pieza «Backboard» más cercana (a menos de 5) en su modelo o el de encima
function Court.boardFor(rim: any): any?
	local best, bestD = nil, 5
	local scope = rim.Parent
	local rimPos = rim.CFrame.Position
	for _ = 1, 2 do
		if not scope then
			break
		end
		for _, c in scope:GetDescendants() do
			if c:IsA("BasePart") and c.Name == "Backboard" then
				local d = (c.CFrame.Position - rimPos).Magnitude
				if d < bestD then
					best, bestD = c, d
				end
			end
		end
		if best then
			return best
		end
		scope = scope.Parent
	end
	return best
end

-- El suelo marcado de un aro: una pieza «Court» o «HalfCourt» de su modelo (o el de encima) que
-- tenga debajo el punto de delante del aro
function Court.floorFor(rim: any, board: any): any?
	local rimPos, boardPos = rim.CFrame.Position, board.CFrame.Position
	local normal = Vector3.new(rimPos.X - boardPos.X, 0, rimPos.Z - boardPos.Z)
	normal = if normal.Magnitude > 1e-3 then normal.Unit else Vector3.zero
	local probe = rimPos + normal * 4
	local scope = rim.Parent
	for _ = 1, 2 do
		if not scope then
			break
		end
		for _, c in scope:GetChildren() do
			if c:IsA("BasePart") and (c.Name == "Court" or c.Name == "HalfCourt") then
				local loc = c.CFrame:PointToObjectSpace(probe)
				if math.abs(loc.X) <= c.Size.X / 2 + 3 and math.abs(loc.Z) <= c.Size.Z / 2 + 3 and loc.Y > 0 and loc.Y < 14 then
					return c
				end
			end
		end
		scope = scope.Parent
	end
	return nil
end

-- Todas las pistas del mapa (lo que hace BasketService al arrancar). descendants: las piezas del
-- mapa (workspace:GetDescendants()). floorY(entry): la altura del suelo delante de un aro sin suelo
-- marcado (en Roblox, un rayo hacia abajo); nil = 7.8 por debajo del aro.
-- Devuelve las pistas y, de cada una, los aros que la forman (Rims: { pieza del aro }).
function Court.scanMap(descendants: { any }, floorY: ((entry: { [string]: any }) -> number?)?): ({ Court }, { [string]: { any } })
	local byFloor: { [any]: { any } } = {}
	local floors: { any } = {}
	local loose = {}
	for _, d in descendants do
		if d:IsA("BasePart") and d.Name == "Rim" and Court.isRim(d) then
			local board = Court.boardFor(d)
			if board then
				local entry = { Part = d, Board = board }
				local floor = Court.floorFor(d, board)
				if floor then
					if not byFloor[floor] then
						byFloor[floor] = {}
						table.insert(floors, floor)
					end
					table.insert(byFloor[floor], entry)
				else
					table.insert(loose, entry)
				end
			end
		end
	end
	local courts: { Court } = {}
	local rimsOf: { [string]: { any } } = {}
	local seen: { [string]: boolean } = {}
	local function add(court: Court?, entries: { any })
		if court and not seen[court.Id] then
			seen[court.Id] = true
			table.insert(courts, court)
			local list = {}
			for _, e in entries do
				table.insert(list, e.Part)
			end
			rimsOf[court.Id] = list
		end
	end
	for _, floor in floors do
		local rims = byFloor[floor]
		local fp = floor.CFrame.Position
		local id = ("B%d_%d"):format(math.floor(fp.X), math.floor(fp.Z))
		local use = rims
		if #rims >= 2 then
			-- Los dos aros más separados
			local a, b, best = rims[1], rims[2], -1
			for i = 1, #rims do
				for j = i + 1, #rims do
					local dd = (rims[i].Part.CFrame.Position - rims[j].Part.CFrame.Position).Magnitude
					if dd > best then
						a, b, best = rims[i], rims[j], dd
					end
				end
			end
			use = { a, b }
		end
		local ok, court = pcall(Court.fromParts, floor, use, id)
		add(if ok then court else nil, rims)
	end
	for _, entry in loose do
		-- Sin suelo marcado: el suelo de verdad debajo de delante del aro
		local rp = entry.Part.CFrame.Position
		entry.FloorY = (if floorY then floorY(entry) else nil) or rp.Y - 7.8
		local id = ("H%d_%d"):format(math.floor(rp.X), math.floor(rp.Z))
		local ok, court = pcall(Court.fromParts, nil, { entry }, id)
		add(if ok then court else nil, { entry })
	end
	return courts, rimsOf
end

return Court
