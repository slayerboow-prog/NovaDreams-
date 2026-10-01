-- SkyRift: la Grieta del cielo (Saga de la Grieta). Cuentas puras: se prueban fuera de Roblox
-- (scripts/test-skyrift.luau). La dibuja el cliente (Controllers/SkyRift).
--
--   * Cómo es (la imagen de referencia del dueño, scripts/rift/referencia.png): un AGUJERO enorme en
--     el cielo con forma de rasgadura horizontal de bordes rotos y dentados. Dentro se ve el espacio
--     (fondo azul-violeta oscuro, una galaxia espiral violeta-rosa en el centro, un planeta a la
--     izquierda, estrellas y nebulosa); del borde salen rayos azul eléctrico y morados hacia fuera y
--     hacia abajo; alrededor flotan y giran rocas con brillo azul en el borde, chispas de energía, y
--     las nubes y la luz se tiñen de azul y morado.
--   * Capas (de atrás adelante, en un mismo plano que siempre mira a la cámara): halo azul/morado,
--     interior (la textura de la rasgadura), galaxia que gira despacio, rayos del borde y rayos que
--     parpadean. Delante: rocas 3D, partículas y un resplandor aditivo (Beams) para el Bloom.
--   * Texturas (textures/rift/, hechas por scripts/rift/gen.py y subidas con scripts/upload-rift.sh
--     a shared/RiftTextureIds). Sin ids, la misma silueta (shared/SkyRiftOutline) se dibuja por código.
--   * Fases de la saga (phaseFor): cuánto está abierta (Open 0..1) y cuánto brilla (Intensity 0..1).
--     Rasguño = pequeña y fina; Abierta/Fusión = enorme, como la referencia; Cosida = una cicatriz.
--   * Nivel gráfico Bajo: sin rocas 3D y la mitad de rayos y partículas, pero con la textura principal.

local SkyRift = {}

-- Fases de la saga. Mode "Sky": en el cielo de Valmar (sigue a la cámara, muy lejos);
-- "Dream": sobre la isla del sueño del prólogo (fija en el mundo).
export type Phase = { Open: number, Intensity: number, Sparks: number, Mode: string }
SkyRift.Phases = {
	Ninguna = { Open = 0, Intensity = 0, Sparks = 0, Mode = "Sky" },
	Sueno = { Open = 0.6, Intensity = 0.9, Sparks = 0.6, Mode = "Dream" }, -- prólogo (el sueño)
	Rasguno = { Open = 0.28, Intensity = 0.55, Sparks = 0.3, Mode = "Sky" }, -- «un rasguño en el aire» (tras conocer a Cosme)
	Crece = { Open = 0.55, Intensity = 0.8, Sparks = 1, Mode = "Sky" }, -- La grieta en el cielo: ha crecido y caen cosas
	Grande = { Open = 0.8, Intensity = 0.9, Sparks = 1.2, Mode = "Sky" }, -- la noche de las cosas perdidas
	Abierta = { Open = 1, Intensity = 1, Sparks = 1.4, Mode = "Sky" }, -- Coser el cielo (antes de coserla)
	Cosida = { Open = 0.12, Intensity = 0.3, Sparks = 0, Mode = "Sky" }, -- una cicatriz finísima
	Hilachas = { Open = 0.3, Intensity = 0.5, Sparks = 0.4, Mode = "Sky" }, -- Acto II: las costuras se sueltan
	Rota = { Open = 0.75, Intensity = 0.9, Sparks = 1.2, Mode = "Sky" }, -- Acto III: la costura se rompió
	Inminente = { Open = 0.9, Intensity = 0.95, Sparks = 1.4, Mode = "Sky" }, -- Acto IV: llega la Gran Fusión
	Fusion = { Open = 1, Intensity = 1, Sparks = 2, Mode = "Sky" }, -- la batalla final
	Ultima = { Open = 0.5, Intensity = 0.6, Sparks = 0.6, Mode = "Sky" }, -- la última costura
	Cerrada = { Open = 0, Intensity = 0, Sparks = 0, Mode = "Sky" }, -- cerrada para siempre
} :: { [string]: Phase }

-- Dónde se dibuja. Sky: dirección desde la cámara (hacia Los Pinos, al norte, a media altura),
-- distancia y ancho del marco en studs (el marco de las texturas es 2:1; la rasgadura ocupa ~85 %
-- del ancho: abierta del todo tapa ~45° del cielo, como en la referencia). Dream: encima de la isla
-- del sueño (World/Kit/DreamIsland: origen -3400, 700, -3400 y 164 de largo), fija.
SkyRift.Placement = {
	Sky = { Direction = { 0.25, 0.78, -1 }, Distance = 650, Width = 620 },
	Dream = { Center = { -3400 + 82, 700 + 80, -3400 - 6 }, Width = 300 },
}
SkyRift.Aspect = 2 -- ancho / alto del marco (las texturas son 2048x1024)

-- Velocidad a la que se abre o se cierra (Open por segundo)
SkyRift.OpenRate = 0.12
SkyRift.CloseRate = 0.2

local PROLOGUE = "Prologo_Sueno" -- (StoryContext.PrologueId)

---------------------------------------------------------------------
-- Texturas (shared/RiftTextureIds, las escribe scripts/upload-rift.sh)
---------------------------------------------------------------------
SkyRift.TextureNames = { "rift_interior", "rift_glow", "rift_rays", "rift_galaxy", "bolt_1", "bolt_2", "bolt_3", "bolt_4" }
SkyRift.BoltTextures = { "bolt_1", "bolt_2", "bolt_3", "bolt_4" }

export type Textures = {
	Interior: string,
	Glow: string?,
	Rays: string?,
	Galaxy: string?,
	Bolts: { string },
}

local function idOf(ids: { [string]: any }, name: string): string?
	local v = ids[name]
	if type(v) == "string" and v:match("^rbxassetid://%d+$") then
		return v
	end
	return nil
end

-- Qué texturas hay. nil si falta la principal (el interior): entonces se dibuja por código.
-- map (opcional): del id del Decal al de su imagen (shared/Images.of)
function SkyRift.textures(ids: { [string]: any }?, map: ((string) -> string)?): Textures?
	ids = ids or {}
	local conv = map or function(s: string): string
		return s
	end
	local interior = idOf(ids :: any, "rift_interior")
	if not interior then
		return nil
	end
	local function get(name: string): string?
		local id = idOf(ids :: any, name)
		return if id then conv(id) else nil
	end
	local bolts = {}
	for _, name in SkyRift.BoltTextures do
		local id = get(name)
		if id then
			table.insert(bolts, id)
		end
	end
	return {
		Interior = conv(interior),
		Glow = get("rift_glow"),
		Rays = get("rift_rays"),
		Galaxy = get("rift_galaxy"),
		Bolts = bolts,
	}
end

---------------------------------------------------------------------
-- Ruido determinista (no usa Random: igual en Roblox y en las pruebas)
---------------------------------------------------------------------
local function rng(seed: number): () -> number
	local s = math.floor(seed) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function(): number
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end
SkyRift.rng = rng

local function between(r: () -> number, a: number, b: number): number
	return a + (b - a) * r()
end

---------------------------------------------------------------------
-- Tamaño según la fase
---------------------------------------------------------------------
-- Cuánto del marco se ve con esta apertura: (ancho, alto) en fracción. Al principio es un rasguño
-- pequeño y fino (casi una línea); abierta del todo, el marco entero.
function SkyRift.size(open: number): (number, number)
	open = math.clamp(open, 0, 1)
	local w = 0.3 + 0.7 * open
	local h = math.max(0.035, open ^ 1.6)
	return w, h
end

-- Píxel del lienzo (SurfaceGui de cw x ch) de un punto (u, v) del marco, con la apertura (w, h)
function SkyRift.toCanvas(u: number, v: number, cw: number, ch: number, w: number, h: number): (number, number)
	return cw / 2 + (u - 0.5) * cw * w, ch / 2 + (v - 0.5) * ch * h
end

---------------------------------------------------------------------
-- Contorno (shared/SkyRiftOutline): centro y normales hacia fuera
---------------------------------------------------------------------
export type Outline = {
	Rim: { { number } },
	Columns: { { number } },
	Galaxy: { number },
	Planet: { number },
}

function SkyRift.centroid(outline: Outline): (number, number)
	local su, sv = 0, 0
	for _, p in outline.Rim do
		su += p[1]
		sv += p[2]
	end
	return su / #outline.Rim, sv / #outline.Rim
end

-- ¿(u, v) dentro de la silueta? (por columnas)
function SkyRift.inside(outline: Outline, u: number, v: number): boolean
	for _, c in outline.Columns do
		if math.abs(u - c[1]) <= c[2] / 2 + 1e-6 then
			return v >= c[3] and v <= c[4]
		end
	end
	return false
end

---------------------------------------------------------------------
-- Rayos que salen del borde (se regeneran con parpadeo)
---------------------------------------------------------------------
export type Bolt = {
	U: number, -- de dónde sale (punto del borde)
	V: number,
	Angle: number, -- hacia dónde va (radianes, en el lienzo: 0 = derecha, +π/2 = abajo)
	Length: number, -- largo en fracción del ancho del marco
	Texture: number, -- cuál de las texturas de rayo (1..4)
	Life: number, -- segundos encendido
	Wait: number, -- segundos apagado después
	Purple: boolean,
}

-- Un rayo nuevo. k: número de rayo; r: aleatorio (0..1). Sale de un punto del borde hacia fuera,
-- más bien hacia abajo y a los lados (como en la referencia), y dura 0,1-0,6 s.
function SkyRift.newBolt(outline: Outline, r: () -> number): Bolt
	local rim = outline.Rim
	local cu, cv = SkyRift.centroid(outline)
	local p = rim[math.clamp(math.floor(r() * #rim) + 1, 1, #rim)]
	-- Hacia fuera desde el centro (aplastado: la grieta es mucho más ancha que alta)
	local du, dv = (p[1] - cu), (p[2] - cv) * 2.6
	local out = math.atan2(dv, du)
	-- Un poco hacia abajo (caen hacia la ciudad) y con algo de azar
	local down = math.pi / 2
	local diff = (down - out + math.pi) % (2 * math.pi) - math.pi
	local angle = out + diff * between(r, 0.1, 0.4) + between(r, -0.45, 0.45)
	return {
		U = p[1],
		V = p[2],
		Angle = angle,
		Length = between(r, 0.08, 0.22),
		Texture = math.clamp(math.floor(r() * 4) + 1, 1, 4),
		Life = between(r, 0.1, 0.6),
		Wait = between(r, 0.08, 0.5),
		Purple = r() < 0.35,
	}
end

-- Quebrada de un rayo (para dibujarlo sin textura): puntos de (0,0) a (1,0) con zigzag
-- (desplazamiento del punto medio) y una rama. Coordenadas en "largo del rayo".
function SkyRift.boltPath(seed: number, segments: number?): ({ { number } }, { { number } })
	local r = rng(seed)
	local n = segments or 7
	local pts: { { number } } = { { 0, 0 } }
	for i = 1, n - 1 do
		local t = i / n
		table.insert(pts, { t + between(r, -0.3, 0.3) / n, between(r, -0.13, 0.13) })
	end
	table.insert(pts, { 1, between(r, -0.12, 0.12) })
	-- Rama: desde un punto del medio, se abre hacia un lado
	local from = pts[math.clamp(math.floor(between(r, 2, n - 1)), 2, n)]
	local side = if r() < 0.5 then 1 else -1
	local branch: { { number } } = { from }
	local bx, by = from[1], from[2]
	for _ = 1, 3 do
		bx += between(r, 0.08, 0.14)
		by += side * between(r, 0.04, 0.12)
		table.insert(branch, { bx, by })
	end
	return pts, branch
end

---------------------------------------------------------------------
-- Rocas que flotan y giran alrededor
---------------------------------------------------------------------
export type Rock = {
	Orbit: number, -- radio de la órbita (fracción del ancho del marco)
	Phase: number, -- ángulo de salida
	Speed: number, -- radianes por segundo (muy despacio)
	Squash: number, -- la órbita, aplastada (la grieta es ancha)
	Depth: number, -- cuánto más cerca de la cámara que la grieta (fracción de la distancia)
	Size: number, -- tamaño (fracción del ancho)
	Spin: { number }, -- giro sobre sí misma (radianes por segundo en X, Y, Z)
	Bob: number, -- sube y baja un poco
	Seed: number,
}

function SkyRift.rocks(count: number, seed: number?): { Rock }
	local r = rng(seed or 9157)
	local out: { Rock } = {}
	for i = 1, count do
		-- Unas pocas grandes y muchas pequeñas
		local big = i <= math.max(2, math.floor(count / 6))
		table.insert(out, {
			Orbit = between(r, 0.18, 0.62),
			Phase = between(r, 0, 2 * math.pi),
			Speed = between(r, 0.012, 0.04) * (if r() < 0.5 then 1 else -1),
			Squash = between(r, 0.35, 0.6),
			Depth = between(r, 0.04, 0.3),
			Size = if big then between(r, 0.035, 0.06) else between(r, 0.008, 0.026),
			Spin = { between(r, -0.35, 0.35), between(r, -0.35, 0.35), between(r, -0.35, 0.35) },
			Bob = between(r, 0, 2 * math.pi),
			Seed = math.floor(between(r, 1, 1e6)),
		})
	end
	return out
end

-- Dónde está una roca en el tiempo t: (x, y) en fracción del ancho desde el centro de la grieta
-- (x a la derecha, y hacia arriba) y su profundidad (fracción de la distancia hacia la cámara)
function SkyRift.rockAt(rock: Rock, t: number, open: number): (number, number, number)
	local a = rock.Phase + rock.Speed * t
	local spread = 0.45 + 0.55 * math.clamp(open, 0, 1) -- con la grieta pequeña, más juntas
	local x = math.cos(a) * rock.Orbit * spread
	local y = math.sin(a) * rock.Orbit * rock.Squash * spread + 0.006 * math.sin(t * 0.5 + rock.Bob)
	return x, y, rock.Depth
end

---------------------------------------------------------------------
-- Fases de la saga
---------------------------------------------------------------------
local function any(map: { [string]: any }, ids: { string }): boolean
	for _, id in ids do
		if map[id] then
			return true
		end
	end
	return false
end

export type StoryLike = { Active: { [string]: any }?, Completed: { [string]: any }?, Flags: { [string]: any }? }

-- Qué fase toca según la historia del jugador (lo publica el servidor en el atributo SkyRift)
function SkyRift.phaseFor(story: StoryLike): string
	local A = story.Active or {}
	local C = story.Completed or {}
	local F = story.Flags or {}
	if A[PROLOGUE] then
		return "Sueno"
	end
	if C.Saga_24_Final or F.SagaCompleta then
		return "Cerrada"
	end
	if A.Saga_24_Final or C.Saga_23_Fusion then
		return "Ultima"
	end
	if A.Saga_23_Fusion then
		return "Fusion"
	end
	if C.Saga_18_Precio or any(A, { "Saga_19_Recuerdos", "Saga_20_Aliados", "Saga_21_Consorcio", "Saga_22_Ancla" }) then
		return "Inminente"
	end
	if C.Saga_12_Graduacion then
		return "Rota"
	end
	if C.Saga_06_Coser then
		if C.Saga_07_Costuras or any(A, { "Saga_07_Costuras", "Saga_08_MegaVerso", "Saga_09_Archivo", "Saga_10_Fiesta", "Saga_11_Cronos", "Saga_12_Graduacion" }) then
			return "Hilachas"
		end
		return "Cosida"
	end
	if A.Saga_06_Coser then
		return "Abierta"
	end
	if A.Saga_05_Perdidas or C.Saga_05_Perdidas then
		return "Grande"
	end
	if C.Saga_02_Grieta or any(A, { "Saga_02_Grieta", "Saga_03_Pez", "Saga_04_Ventanilla" }) then
		return "Crece"
	end
	if C.Loco_N1_Cosme or F.GrietaVista then
		return "Rasguno"
	end
	return "Ninguna"
end

function SkyRift.phase(name: string?): Phase
	return SkyRift.Phases[name or "Ninguna"] or SkyRift.Phases.Ninguna
end

-- Acercar el valor actual al objetivo (se abre despacio y se cierra algo más deprisa)
function SkyRift.approach(current: number, target: number, dt: number): number
	if target > current then
		return math.min(target, current + SkyRift.OpenRate * dt)
	end
	return math.max(target, current - SkyRift.CloseRate * dt)
end

---------------------------------------------------------------------
-- Aspecto: niveles gráficos, pulso, brillo y ambiente
---------------------------------------------------------------------
export type TierLook = {
	Rocks: number, -- rocas 3D
	Bolts: number, -- rayos que parpadean a la vez
	BoltSegments: number, -- tramos de cada rayo dibujado sin textura
	Emitters: number, -- emisores de chispas/polvo en el borde
	Stars: number, -- estrellas (solo sin textura)
	Halo: boolean, -- resplandor aditivo (Beams)
	OuterRim: boolean, -- el borde ancho morado (solo sin textura)
}

-- Bajo: sin rocas 3D y la mitad de rayos y partículas (la textura principal, igual)
function SkyRift.tierLook(tierName: string): TierLook
	if tierName == "Low" then
		return { Rocks = 0, Bolts = 7, BoltSegments = 5, Emitters = 3, Stars = 16, Halo = false, OuterRim = false }
	elseif tierName == "High" then
		return { Rocks = 28, Bolts = 16, BoltSegments = 7, Emitters = 8, Stars = 40, Halo = true, OuterRim = true }
	end
	return { Rocks = 20, Bolts = 14, BoltSegments = 6, Emitters = 6, Stars = 30, Halo = true, OuterRim = true }
end

SkyRift.RockParts = 2 -- piezas por roca (un bloque y una cuña)
SkyRift.GalaxyDots = 36 -- puntos de los brazos de la galaxia sin textura
SkyRift.NebulaBlobs = 8

-- Cuántas instancias gasta (para el presupuesto del móvil). outline: la silueta; textured: con
-- texturas subidas o dibujada por código.
function SkyRift.budget(outline: Outline, tierName: string, textured: boolean): { Parts: number, Gui: number, Beams: number, Emitters: number }
	local look = SkyRift.tierLook(tierName)
	local gui
	if textured then
		gui = 4 + look.Bolts -- halo, interior, galaxia, rayos + un ImageLabel por rayo
	else
		local rim = #outline.Rim * (if look.OuterRim then 2 else 1)
		gui = #outline.Columns + rim + 1 + SkyRift.GalaxyDots + 1 + look.Stars + SkyRift.NebulaBlobs
		gui += look.Bolts * (look.BoltSegments + 3)
	end
	return {
		Parts = 1 + look.Rocks * SkyRift.RockParts,
		Gui = gui,
		Beams = if look.Halo then 2 else 0,
		Emitters = look.Emitters,
	}
end

-- Pulso: un latido lento y un parpadeo rápido muy leve; cada capa (k) un poco desfasada
function SkyRift.pulse(time: number, k: number): number
	local slow = math.sin(time * 1.7 + k * 0.55)
	local flicker = math.sin(time * 11.3 + k * 2.9) * math.sin(time * 6.1 + k * 1.3)
	return 0.86 + 0.1 * slow + 0.06 * flicker
end

-- Cuánto se ve según la hora: de noche, del todo; a pleno día, casi igual (es un agujero en el cielo:
-- en la referencia es de día y se ve enorme)
function SkyRift.skyFactor(clockTime: number): number
	local h = clockTime % 24
	local dayness
	if h >= 8 and h <= 17 then
		dayness = 1
	elseif h > 5 and h < 8 then
		dayness = (h - 5) / 3
	elseif h > 17 and h < 20 then
		dayness = (20 - h) / 3
	else
		dayness = 0
	end
	return 1 - 0.12 * dayness
end

-- Transparencia de las capas con esta intensidad (0 = no se ve), pulso y hora
function SkyRift.visibility(intensity: number, sky: number): number
	return math.clamp(intensity * sky, 0, 1)
end

-- Brillo del lienzo (SurfaceGui.Brightness): por encima de 1 el Bloom lo hace resplandecer
function SkyRift.brightness(intensity: number, pulse: number, flare: number): number
	return (1.15 + 0.9 * math.clamp(intensity, 0, 1)) * pulse * (1 + flare)
end

-- Cuánto tiñe el ambiente (DayLight.pushLayer con SkyMoods.GrietaAzul): nada con la grieta pequeña,
-- casi del todo con la grieta abierta
function SkyRift.ambientWeight(open: number, intensity: number): number
	local o = math.clamp((open - 0.2) / 0.6, 0, 1)
	return math.clamp(o * intensity, 0, 1) * 0.85
end

return SkyRift
