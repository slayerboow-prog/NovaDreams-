-- AirArena: las piezas del combate aéreo (la arena de pruebas, la nave del jugador y los enemigos).
--
--   AirArena.build()                 la arena (una sola vez; la llama AirCombatService al entrar el
--                                    primero, nunca al arrancar el servidor). Un CAÑÓN DEL DESIERTO:
--                                    suelo de arenisca con manchas, dunas bajas y un cauce seco; mesas y
--                                    agujas de roca por capas (roca rojiza, franjas claras y sombrero de
--                                    pizarra; su caja de choque es la de shared/AirCombat/Arena.rocks);
--                                    paredes del cañón alrededor (fuera de la zona de vuelo: tapan el
--                                    borde del mundo); un manto de nubes a media altura; los anillos que
--                                    marcan la subida al espacio; y arriba el campo de asteroides (rocas
--                                    con bultos, caras de pizarra y algún cristal que brilla; su esfera
--                                    de choque es la de Arena.asteroids) con un planeta anillado de fondo.
--                                    El cielo, la luz y la bruma de la arena los pone el cliente
--                                    (Controllers/AirCombatClient): no es el cielo de Valmar.
--   AirArena.ship(cf, color?)        la nave del jugador (shared/AirCombat/ShipModel "Caza"): Root
--                                    invisible y ANCLADO (lo mueve por CFrame el ordenador del piloto y
--                                    el servidor lo copia tras comprobarlo) y el asiento "ShipSeat"
--   AirArena.enemy(kind, cf)         un dron, un caza enemigo o una torreta (ShipModel: "Dron",
--                                    "CazaEnemigo", "Torreta"; Root anclado: lo mueve el servidor)
--
-- Sin marcas, logos ni nada real; sin assets de fuera (piezas, materiales de Roblox y la textura de humo
-- que trae Roblox).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arena = require(ReplicatedStorage.Shared.AirCombat.Arena)
local ShipModel = require(ReplicatedStorage.Shared.AirCombat.ShipModel)

local AirArena = {}

AirArena.Name = "AirArena"
AirArena.CloudTexture = "rbxasset://textures/particles/smoke_main.dds" -- (viene con Roblox)

local rgb = Color3.fromRGB
local M = Enum.Material

-- Paleta del cañón
AirArena.Palette = {
	Sand = rgb(204, 146, 98),
	SandDark = rgb(176, 116, 78),
	Bed = rgb(132, 92, 72),
	RockLow = rgb(148, 76, 52),
	RockHigh = rgb(184, 102, 64),
	Band = rgb(226, 176, 124),
	Cap = rgb(112, 70, 56),
	Wall = rgb(160, 88, 60),
	Asteroid = rgb(78, 72, 70),
	AsteroidLump = rgb(100, 92, 86),
	Facet = rgb(62, 60, 66),
	Crystal = { rgb(90, 230, 255), rgb(190, 110, 255), rgb(255, 150, 70) },
	Ring = rgb(90, 200, 255),
}

local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "ClassName" and k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function persistentPerPlayer(model: Model)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	end)
end

-- Números repetibles (la arena es siempre igual)
local function rng(seed: number): () -> number
	local s = seed % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function tone(c: Color3, k: number): Color3
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

local built: Model? = nil

function AirArena.get(): Model?
	return if built and built.Parent then built else nil
end

---------------------------------------------------------------------
-- Suelo del cañón
---------------------------------------------------------------------
local function ground(model: Model, r: () -> number)
	local P = AirArena.Palette
	local O = Arena.Origin
	local tiles = 7
	local side = Arena.SlabHalf * 2 / tiles
	for i = 0, tiles - 1 do
		for j = 0, tiles - 1 do
			local x = -Arena.SlabHalf + side * (i + 0.5)
			local z = -Arena.SlabHalf + side * (j + 0.5)
			part({
				Name = "Suelo",
				Size = Vector3.new(side, 40, side),
				CFrame = CFrame.new(O + Vector3.new(x, Arena.GroundY - 20, z)),
				Material = M.Sandstone,
				Color = P.Sand:Lerp(P.SandDark, r() * 0.45),
				CanCollide = true,
				Parent = model,
			})
		end
	end
	-- Manchas (arena más oscura, grava) y dunas bajas (nunca más de 10 studs: el choque es el suelo)
	for _ = 1, 18 do
		local x, z = (r() * 2 - 1) * 1900, (r() * 2 - 1) * 1900
		local w, d = 120 + r() * 260, 80 + r() * 200
		part({
			Name = "Mancha",
			Size = Vector3.new(w, 0.6, d),
			CFrame = CFrame.new(O + Vector3.new(x, Arena.GroundY + 0.2, z)) * CFrame.Angles(0, r() * math.pi, 0),
			Material = if r() < 0.5 then M.Ground else M.Sand,
			Color = P.SandDark:Lerp(P.Bed, r() * 0.6),
			Parent = model,
		})
	end
	for _ = 1, 12 do
		local x, z = (r() * 2 - 1) * 1800, (r() * 2 - 1) * 1800
		local len, h = 140 + r() * 200, 5 + r() * 5
		local cf = CFrame.new(O + Vector3.new(x, Arena.GroundY + h / 2, z)) * CFrame.Angles(0, r() * math.pi, 0)
		for _, s in { -1, 1 } do
			-- (dos cuñas espalda con espalda: la cresta en medio)
			part({
				ClassName = "WedgePart",
				Name = "Duna",
				Size = Vector3.new(len, h, 22),
				CFrame = cf * CFrame.new(0, 0, s * 11) * CFrame.Angles(0, if s > 0 then math.pi else 0, 0),
				Material = M.Sand,
				Color = P.Sand:Lerp(P.Band, 0.25),
				Parent = model,
			})
		end
	end
	-- Un cauce seco que cruza la meseta (tramos girados)
	local pos = O + Vector3.new(-2000, Arena.GroundY + 0.35, -600)
	local heading = 0.25
	for _ = 1, 12 do
		heading += (r() - 0.5) * 0.7
		local len = 300 + r() * 120
		local dir = Vector3.new(math.cos(heading), 0, math.sin(heading))
		part({
			Name = "Cauce",
			Size = Vector3.new(len + 40, 0.7, 46 + r() * 30),
			CFrame = CFrame.lookAt(pos + dir * len / 2, pos + dir * len) * CFrame.Angles(0, math.pi / 2, 0),
			Material = M.Slate,
			Color = P.Bed,
			Parent = model,
		})
		pos += dir * len
	end
end

---------------------------------------------------------------------
-- Mesas y agujas (dentro de su caja de choque, casi del todo)
---------------------------------------------------------------------
local function mesa(model: Model, box: Arena.Box, r: () -> number)
	local P = AirArena.Palette
	local c, s = box.Center, box.Size
	local bottom = c.Y - s.Y / 2
	local k = 0.9 + r() * 0.2
	local spin = (r() - 0.5) * 1.1
	local function slab(name: string, w: number, h: number, d: number, y: number, yaw: number, color: Color3, material: Enum.Material, solid: boolean?)
		local p = part({
			Name = name,
			Size = Vector3.new(w, h, d),
			CFrame = CFrame.new(Vector3.new(c.X, y + h / 2, c.Z)) * CFrame.Angles(0, yaw, 0),
			Material = material,
			Color = color,
			CanCollide = solid == true,
			CastShadow = true,
			Parent = model,
		})
		if solid then
			p:SetAttribute("AirSolid", true)
		end
		return p
	end
	local h = s.Y
	-- Cuerpo de abajo (la roca grande), franja clara, cuerpo de arriba girado y sombrero de pizarra
	slab("Roca", s.X, h * 0.48, s.Z, bottom, 0, tone(P.RockLow, k), M.Rock, true)
	slab("RocaFranja", s.X * 0.94, h * 0.05, s.Z * 0.94, bottom + h * 0.48, spin * 0.3, tone(P.Band, k), M.Sandstone)
	if h > 280 then
		-- (las altas: dos tramos que se van estrechando, como una aguja)
		slab("RocaMedio", s.X * 0.86, h * 0.22, s.Z * 0.86, bottom + h * 0.53, spin, tone(P.RockHigh, k), M.Rock, true)
		slab("RocaFranja", s.X * 0.8, h * 0.035, s.Z * 0.8, bottom + h * 0.75, -spin * 0.5, tone(P.Band, k * 1.04), M.Sandstone)
		slab("RocaAlta", s.X * 0.7, h * 0.16, s.Z * 0.7, bottom + h * 0.785, spin * 1.4, tone(P.RockHigh, k * 1.05), M.Rock, true)
	else
		slab("RocaMedio", s.X * 0.86, h * 0.4, s.Z * 0.86, bottom + h * 0.53, spin, tone(P.RockHigh, k), M.Rock, true)
	end
	local capW = if h > 280 then 0.78 else 0.92
	slab("RocaSombrero", s.X * capW, h * 0.055, s.Z * capW, c.Y + h / 2 - h * 0.055, -spin, tone(P.Cap, k), M.Slate, true)
	-- (el sombrero llega justo al techo de la caja: ahí se ponen las torretas, Arena.turretSpots)
	-- Lajas: trozos de roca girados apoyados en los lados (rompen la silueta de caja)
	for q = 1, 2 do
		local a = r() * math.pi * 2
		local lw = math.min(s.X, s.Z) * (0.35 + r() * 0.2)
		local lh = h * (0.3 + r() * 0.3)
		local reach = math.min(s.X, s.Z) * 0.32
		part({
			Name = "Laja",
			Size = Vector3.new(lw, lh, lw * (0.6 + r() * 0.3)),
			CFrame = CFrame.new(Vector3.new(c.X + math.cos(a) * reach, bottom + lh * 0.45, c.Z + math.sin(a) * reach))
				* CFrame.Angles((r() - 0.5) * 0.25, a + q, (r() - 0.5) * 0.25),
			Material = M.Rock,
			Color = tone(if q == 2 then P.RockHigh else P.RockLow, k * (0.92 + r() * 0.1)),
			CastShadow = true,
			Parent = model,
		})
	end
	-- Pedregal al pie (cuñas bajas que bajan hacia fuera)
	for q = 0, 3 do
		local yaw = q * math.pi / 2 + spin * 0.2
		local out = (if q % 2 == 0 then s.Z else s.X) / 2
		local along = if q % 2 == 0 then s.X else s.Z
		local hh = math.min(10, 4 + h * 0.02)
		part({
			ClassName = "WedgePart",
			Name = "Pedregal",
			Size = Vector3.new(along * (0.6 + r() * 0.3), hh, 18),
			CFrame = CFrame.new(Vector3.new(c.X, bottom + hh / 2, c.Z)) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, out + 8) * CFrame.Angles(0, math.pi, 0),
			Material = M.Slate,
			Color = tone(P.RockLow, k * 0.85),
			Parent = model,
		})
	end
end

-- Paredes del cañón alrededor (más allá del borde de la zona de vuelo: solo se ven)
local function walls(model: Model, r: () -> number)
	local P = AirArena.Palette
	local O = Arena.Origin
	local dist = Arena.SlabHalf + 60
	for side = 0, 3 do
		local yaw = side * math.pi / 2
		for seg = -3, 3 do
			local h = 300 + r() * 420
			local depth = 260 + r() * 120
			local width = 660
			local back = r() * 90 -- (no todas en línea)
			local base = CFrame.new(O + Vector3.new(0, Arena.GroundY, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.new(seg * 620, 0, -(dist + depth / 2 + back)) * CFrame.Angles(0, (r() - 0.5) * 0.25, 0)
			local k = 0.88 + r() * 0.2
			-- Terrazas: abajo ancha, la franja clara y dos bloques altos desplazados y girados
			part({ Name = "Pared", Size = Vector3.new(width, h * 0.5, depth), CFrame = base * CFrame.new(0, h * 0.25, 0), Material = M.Rock, Color = tone(P.Wall, k), CastShadow = true, Parent = model })
			part({ Name = "ParedFranja", Size = Vector3.new(width * 0.96, h * 0.05, depth * 0.94), CFrame = base * CFrame.new(0, h * 0.525, 12) * CFrame.Angles(0, (r() - 0.5) * 0.12, 0), Material = M.Sandstone, Color = tone(P.Band, k), Parent = model })
			for t = 1, 2 do
				local bw = width * (0.35 + r() * 0.3)
				local bh = h * (0.25 + r() * 0.25)
				part({
					Name = "ParedAlta",
					Size = Vector3.new(bw, bh, depth * (0.55 + r() * 0.3)),
					CFrame = base * CFrame.new((t - 1.5) * width * 0.45 + (r() - 0.5) * 80, h * 0.55 + bh / 2, 30 + r() * 40) * CFrame.Angles(0, (r() - 0.5) * 0.5, 0),
					Material = M.Rock,
					Color = tone(if t == 1 then P.RockHigh else P.Wall, k * (0.95 + r() * 0.1)),
					CastShadow = true,
					Parent = model,
				})
			end
			part({ ClassName = "WedgePart", Name = "ParedTalud", Size = Vector3.new(width, h * 0.18, 90), CFrame = base * CFrame.new(0, h * 0.09, depth / 2 + 45) * CFrame.Angles(0, math.pi, 0), Material = M.Slate, Color = tone(P.RockLow, k * 0.9), Parent = model })
		end
	end
end

-- Manto de nubes a media altura (partículas grandes y lentas; el cliente lo apaga en gráficos Bajo)
local function clouds(model: Model, r: () -> number)
	local O = Arena.Origin
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2 + r() * 0.4
		local d = 500 + r() * 1100
		local holder = part({
			Name = "Nubes",
			Size = Vector3.new(900, 60, 900),
			CFrame = CFrame.new(O + Vector3.new(math.cos(a) * d, 2500 + r() * 500, math.sin(a) * d)),
			Transparency = 1,
			Parent = model,
		})
		local e = Instance.new("ParticleEmitter")
		e.Name = "Nube"
		e.Texture = AirArena.CloudTexture
		e.Shape = Enum.ParticleEmitterShape.Box
		e.Rate = 0.3
		e.Lifetime = NumberRange.new(26, 36)
		e.Speed = NumberRange.new(1, 4)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 140), NumberSequenceKeypoint.new(1, 230) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.45), NumberSequenceKeypoint.new(0.8, 0.5), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(rgb(255, 246, 236))
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-2, 2)
		e.LightInfluence = 1
		e.LightEmission = 0
		e.Parent = holder
	end
end

---------------------------------------------------------------------
-- Asteroides (dentro de su esfera de choque) y el planeta del fondo
---------------------------------------------------------------------
local function asteroid(model: Model, ball: Arena.Ball, i: number, r: () -> number)
	local P = AirArena.Palette
	local R = ball.Radius
	local c = ball.Center
	local k = 0.8 + r() * 0.4
	local function rot(): CFrame
		return CFrame.Angles(r() * math.pi * 2, r() * math.pi * 2, r() * math.pi * 2)
	end
	local main = part({
		Name = "Asteroide",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * R * 1.7,
		CFrame = CFrame.new(c) * rot(),
		Material = M.Basalt,
		Color = tone(P.Asteroid, k),
		CanCollide = true,
		CastShadow = true,
		Parent = model,
	})
	main:SetAttribute("AirSolid", true)
	-- Bultos (bolas que asoman) y caras planas de pizarra: deja de parecer una bola
	for _ = 1, 2 do
		local dir = Vector3.new(r() * 2 - 1, r() * 2 - 1, r() * 2 - 1)
		dir = if dir.Magnitude > 0.05 then dir.Unit else Vector3.new(0, 1, 0)
		local rr = R * (0.5 + r() * 0.2)
		part({
			Name = "AsteroideBulto",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * rr * 2,
			CFrame = CFrame.new(c + dir * (R - rr) * 1.12) * rot(),
			Material = M.Rock,
			Color = tone(P.AsteroidLump, k),
			CastShadow = true,
			Parent = model,
		})
	end
	for _ = 1, 2 do
		local off = Vector3.new(r() * 2 - 1, r() * 2 - 1, r() * 2 - 1) * R * 0.18
		part({
			Name = "AsteroideCara",
			Size = Vector3.new(R * (1.25 + r() * 0.2), R * (0.75 + r() * 0.2), R * (1.0 + r() * 0.2)),
			CFrame = CFrame.new(c + off) * rot(),
			Material = M.Slate,
			Color = tone(P.Facet, k),
			CastShadow = true,
			Parent = model,
		})
	end
	if i % 4 == 0 then
		-- Cristales que brillan (pistas de color en el espacio negro)
		local color = P.Crystal[(i // 4) % #P.Crystal + 1]
		for _ = 1, 3 do
			local dir = Vector3.new(r() * 2 - 1, r() * 2 - 1, r() * 2 - 1)
			dir = if dir.Magnitude > 0.05 then dir.Unit else Vector3.new(1, 0, 0)
			local len = R * (0.35 + r() * 0.2)
			part({
				ClassName = "WedgePart",
				Name = "Cristal",
				Size = Vector3.new(R * 0.14, len, R * 0.2),
				CFrame = CFrame.lookAt(c + dir * (R * 0.85), c + dir * (R * 2)) * CFrame.Angles(-math.pi / 2, 0, 0),
				Material = M.Neon,
				Color = color,
				Transparency = 0.1,
				Parent = model,
			})
		end
	end
end

local function planet(model: Model)
	local O = Arena.Origin
	local center = O + Vector3.new(-2600, 5600, -5600)
	local tilt = CFrame.new(center) * CFrame.Angles(0.38, 0, 0.22)
	part({ Name = "Planeta", Shape = Enum.PartType.Ball, Size = Vector3.one * 1100, CFrame = CFrame.new(center), Material = M.Sand, Color = rgb(196, 120, 86), Parent = model })
	part({ Name = "PlanetaBandas", Shape = Enum.PartType.Ball, Size = Vector3.one * 1110, CFrame = tilt, Material = M.Glass, Color = rgb(255, 205, 160), Transparency = 0.8, Parent = model })
	part({
		Name = "PlanetaAnillo",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 2048, 2048),
		CFrame = tilt * CFrame.Angles(0, 0, math.pi / 2),
		Material = M.Glass,
		Color = rgb(232, 204, 172),
		Transparency = 0.7,
		Parent = model,
	})
end

function AirArena.build(): Model
	local existing = AirArena.get()
	if existing then
		return existing
	end
	local model = Instance.new("Model")
	model.Name = AirArena.Name
	persistentPerPlayer(model)
	local r = rng(Arena.Seed * 313)
	ground(model, r)
	for _, box in Arena.rocks() do
		mesa(model, box, r)
	end
	walls(model, r)
	clouds(model, r)
	-- Anillos de la subida al espacio (encima del centro): se ven desde lejos
	local O = Arena.Origin
	for k, y in { Arena.SpaceY - 900, Arena.SpaceY - 450, Arena.SpaceY - 60 } do
		local center = O + Vector3.new(0, y, -200 + k * 60)
		local radius = 120
		for s = 1, 16 do
			local a = (s - 1) / 16 * math.pi * 2
			local p = center + Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
			part({
				Name = "AnilloEspacio",
				Size = Vector3.new(10, 48, 10),
				CFrame = CFrame.new(p) * CFrame.Angles(0, 0, a),
				Material = M.Neon,
				Color = AirArena.Palette.Ring,
				Transparency = 0.15,
				Parent = model,
			})
		end
	end
	for i, ball in Arena.asteroids() do
		asteroid(model, ball, i, r)
	end
	planet(model)
	-- Balizas de los puntos de control (donde reapareces)
	for _, section in { "Atmos", "Space" } do
		local cp = Arena.checkpoint(section)
		for s = 1, 12 do
			local a = (s - 1) / 12 * math.pi * 2
			part({
				Name = "Control" .. section,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(6, 6, 6),
				CFrame = cp * CFrame.new(math.cos(a) * 40, math.sin(a) * 40, 30),
				Material = M.Neon,
				Color = if section == "Space" then rgb(190, 120, 255) else rgb(80, 255, 160),
				Transparency = 0.2,
				Parent = model,
			})
		end
	end
	model.Parent = workspace
	built = model
	return model
end

-- La nave del jugador: el morro hacia -Z, el centro del Root en el centro de la nave
function AirArena.ship(cf: CFrame, color: Color3?): Model
	local model = ShipModel.build("Caza", cf, if color then { Body = color } else nil)
	model.Name = "Nave"
	persistentPerPlayer(model)
	return model
end

-- Enemigos (Root anclado: el servidor lo mueve; el resto soldado)
local ENEMY_MODEL = { Dron = "Dron", Caza = "CazaEnemigo", Torreta = "Torreta", Interceptor = "Interceptor", Aguja = "Aguja", Pesada = "Pesada" }
function AirArena.enemy(kind: string, cf: CFrame): Model
	local model = ShipModel.build(ENEMY_MODEL[kind] or "Dron", cf)
	model.Name = kind
	return model
end

return AirArena
