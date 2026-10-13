-- SkyRift: la Grieta del cielo (Saga de la Grieta). Cuentas puras: se prueban fuera de Roblox
-- (scripts/test-skyrift.luau). La dibuja el cliente (Controllers/SkyRift).
--
--   * Cómo es: las imágenes que encargó el dueño (scripts/rift/referencia.png, la grieta abierta, y
--     scripts/rift/etapas.png, sus 7 ETAPAS). La grieta CRECE a lo largo de la saga:
--       1 Cielo normal (nada)
--       2 Primera anomalía: un punto violeta que brilla con destello y una raya violeta fina en diagonal
--       3 La grieta crece: fractura en diagonal con rayos azul-blanco; el cielo se oscurece alrededor
--       4 Gran fractura: grieta enorme en diagonal, interior oscuro-violeta, muchos rayos, rocas
--       5 Portal dimensional: el AGUJERO con forma de rasgadura (la referencia principal): dentro el
--         espacio (galaxia espiral, planeta, nebulosa, estrellas); rayos y rocas alrededor
--       6 Grieta colosal: el agujero ocupa casi todo el cielo
--       7 Evento final: el cielo está roto; casi todo es espacio violeta y TODA la ciudad se ve violeta
--   * Capas (en un plano lejano que siempre mira a la cámara): halo, la textura de la etapa, galaxia
--     que gira despacio, rayos del borde y rayos que parpadean (se regeneran cada 0,1-0,6 s). Delante:
--     rocas 3D que flotan y giran, chispas y polvo de energía y un resplandor aditivo para el Bloom.
--     El ambiente (luz, nubes, bruma) se tiñe de azul/morado (etapa 7: violeta) con DayLight.pushLayer.
--   * Texturas: textures/rift/ (scripts/rift/gen.py) subidas con scripts/upload-rift.sh a
--     shared/RiftTextureIds. Sin ids se dibuja por código con la misma silueta (shared/SkyRiftArt).
--   * Fases de la saga (phaseFor, las publica LifeStoryService): cada una dice su etapa, cuánto ha
--     crecido dentro de ella (Open 0..1) y cuánto brilla (Intensity). Cosida = una cicatriz.
--   * Nivel gráfico Bajo: sin rocas 3D y la mitad de rayos y partículas, pero con la textura principal.

local SkyRift = {}

-- Las 7 etapas. Width: ancho del marco en studs a la distancia de Placement (la cámara de 70° ve unos
-- 900 studs de ancho a 650: la 2 es un puntito, la 5 media pantalla, la 7 tapa todo el cielo).
-- Bolts/Rocks/Emitters: cuánto de lo del nivel gráfico (1 = todo). Ambient: peso máximo de la capa de
-- luz Mood. Draw: cómo se dibuja sin textura (la silueta de la rasgadura a esa altura y girada Roll).
export type Stage = {
	Name: string,
	Width: number,
	Bolts: number,
	Rocks: number,
	RockScale: number,
	Emitters: number,
	Ambient: number,
	Mood: string?,
	Star: boolean, -- el destello violeta (etapa 2)
	FrameAspect: number?, -- (si está) proporción del marco en vez de la de su textura (SkyRiftArt)
	Draw: { Height: number, Roll: number, Fill: boolean, Cosmos: boolean, Backdrop: boolean },
}
SkyRift.Stages = {
	{ Name = "Cielo normal", Width = 0, Bolts = 0, Rocks = 0, RockScale = 1, Emitters = 0, Ambient = 0, Star = false,
		Draw = { Height = 0, Roll = 0, Fill = false, Cosmos = false, Backdrop = false } },
	{ Name = "Primera anomalía", Width = 240, Bolts = 0, Rocks = 0, RockScale = 1, Emitters = 0.2, Ambient = 0.1, Mood = "GrietaAzul", Star = true,
		Draw = { Height = 0.02, Roll = math.rad(-40), Fill = false, Cosmos = false, Backdrop = false } },
	{ Name = "La grieta crece", Width = 600, Bolts = 0.5, Rocks = 0, RockScale = 1, Emitters = 0.5, Ambient = 0.35, Mood = "GrietaAzul", Star = true,
		Draw = { Height = 0.07, Roll = math.rad(-38), Fill = false, Cosmos = false, Backdrop = false } },
	{ Name = "Gran fractura", Width = 860, Bolts = 0.8, Rocks = 0.6, RockScale = 1, Emitters = 0.8, Ambient = 0.6, Mood = "GrietaAzul", Star = false,
		Draw = { Height = 0.4, Roll = math.rad(-30), Fill = true, Cosmos = false, Backdrop = false } },
	-- (5: su textura, rift_interior, solo llena el 69 % x 49 % de su marco 2:1, con halo y rayos
	-- alrededor: a 620 de ancho el agujero salía de 430 x 150 studs, más pequeño que la 4. Ahora el
	-- marco es más ancho y más alto (FrameAspect: el agujero se ve de ~970 x 550, todas las capas
	-- estiradas igual, la galaxia sigue redonda): cada etapa que se abre es más grande que la anterior)
	{ Name = "Portal dimensional", Width = 1400, FrameAspect = 1.25, Bolts = 1, Rocks = 1, RockScale = 1.2, Emitters = 1, Ambient = 0.75, Mood = "GrietaAzul", Star = false,
		Draw = { Height = 1, Roll = 0, Fill = true, Cosmos = true, Backdrop = false } },
	{ Name = "Grieta colosal", Width = 1650, Bolts = 1.2, Rocks = 1, RockScale = 1.4, Emitters = 1, Ambient = 0.85, Mood = "GrietaAzul", Star = false,
		Draw = { Height = 1.25, Roll = 0, Fill = true, Cosmos = true, Backdrop = false } },
	{ Name = "Evento final", Width = 2300, Bolts = 1.2, Rocks = 1.2, RockScale = 2, Emitters = 1, Ambient = 1, Mood = "GrietaFinal", Star = false,
		Draw = { Height = 1.5, Roll = 0, Fill = true, Cosmos = true, Backdrop = true } },
} :: { Stage }

-- Fases de la saga: Stage (1..7), cuánto ha crecido dentro de su etapa (Open) y cuánto brilla.
-- Mode "Sky": en el cielo de Valmar (sigue a la cámara, muy lejos); "Dream": sobre la isla del sueño
-- del prólogo (fija en el mundo).
--   Acto I:   Rasguño 2 → Crece 3 → Grande 4 → Abierta 5 (el portal, «Coser el cielo»)
--   Acto II:  Cosida (cicatriz: la 2, apagada) → Hilachas 3
--   Acto III: Rota 5 (se rompe la costura)
--   Acto IV:  Inminente 6 → Fusión 7 (el evento final) → Última costura 4 (se va cerrando) → Cerrada 1
export type Phase = { Stage: number, Open: number, Intensity: number, Sparks: number, Mode: string }
SkyRift.Phases = {
	Ninguna = { Stage = 1, Open = 0, Intensity = 0, Sparks = 0, Mode = "Sky" },
	Sueno = { Stage = 5, Open = 0.8, Intensity = 0.9, Sparks = 0.6, Mode = "Dream" }, -- prólogo (el sueño)
	Rasguno = { Stage = 2, Open = 1, Intensity = 0.85, Sparks = 0.3, Mode = "Sky" }, -- «un rasguño en el aire» (tras conocer a Cosme)
	Crece = { Stage = 3, Open = 1, Intensity = 0.9, Sparks = 1, Mode = "Sky" }, -- La grieta en el cielo: ha crecido y caen cosas
	Grande = { Stage = 4, Open = 1, Intensity = 0.95, Sparks = 1.2, Mode = "Sky" }, -- la noche de las cosas perdidas
	Abierta = { Stage = 5, Open = 1, Intensity = 1, Sparks = 1.4, Mode = "Sky" }, -- Coser el cielo (antes de coserla)
	Cosida = { Stage = 2, Open = 0.6, Intensity = 0.3, Sparks = 0, Mode = "Sky" }, -- una cicatriz finísima
	Hilachas = { Stage = 3, Open = 0.8, Intensity = 0.7, Sparks = 0.6, Mode = "Sky" }, -- Acto II: las costuras se sueltan
	Rota = { Stage = 5, Open = 1, Intensity = 1, Sparks = 1.4, Mode = "Sky" }, -- Acto III: la costura se rompió
	Inminente = { Stage = 6, Open = 1, Intensity = 1, Sparks = 1.6, Mode = "Sky" }, -- Acto IV: llega la Gran Fusión
	Fusion = { Stage = 7, Open = 1, Intensity = 1, Sparks = 2, Mode = "Sky" }, -- la batalla final: el cielo se rompe
	Ultima = { Stage = 4, Open = 0.7, Intensity = 0.7, Sparks = 0.6, Mode = "Sky" }, -- la última costura: se va cerrando
	Cerrada = { Stage = 1, Open = 0, Intensity = 0, Sparks = 0, Mode = "Sky" }, -- cerrada para siempre
} :: { [string]: Phase }

-- Una fase de ejemplo para ver cada etapa (modo pruebas)
SkyRift.StagePreview = { "Cerrada", "Rasguno", "Crece", "Grande", "Abierta", "Inminente", "Fusion" }

-- Dónde se dibuja. Sky: a Distance studs de la cámara, en la dirección del cielo que MIRABA la cámara
-- (su giro, yaw) cuando empezó la fase o entró el jugador, y fija después (Controllers/SkyRift), a
-- Elevation grados sobre el horizonte: lo bastante alta para asomar por encima de los edificios y lo
-- bastante baja para caber en la pantalla del móvil (la cámara de 70° mira casi siempre al frente o un
-- poco hacia abajo). Direction: la de antes (hacia Los Pinos, al norte), solo si aún no hay cámara.
-- Dream: encima de la isla del sueño (World/Kit/DreamIsland: origen -3400, 700, -3400 y 164 de
-- largo), fija; DreamWidth es el ancho del marco allí.
-- DrawDistance: a cuántos studs de la cámara se dibuja DE VERDAD (más cerca, todo a escala
-- DrawDistance / Distance: se ve igual de grande, pero la bruma del aire —Atmosphere— la lava mucho
-- menos; a 650 studs, de día, la grieta y sus rocas salían casi del color del cielo)
SkyRift.Placement = {
	Sky = { Direction = { 0.25, 0.78, -1 }, Distance = 650, DrawDistance = 420, Elevation = 27 },
	Dream = { Center = { -3400 + 82, 700 + 80, -3400 - 6 }, DreamWidth = 300 },
}

-- Giro (yaw, radianes) de una dirección horizontal: 0 = hacia -Z (norte), como CFrame.Angles(0, yaw, 0)
function SkyRift.yawOf(lookX: number, lookZ: number): number
	if math.abs(lookX) < 1e-6 and math.abs(lookZ) < 1e-6 then
		local d = SkyRift.Placement.Sky.Direction
		lookX, lookZ = d[1], d[3]
	end
	return math.atan2(-lookX, -lookZ)
end

-- Dirección (unitaria) del centro de la grieta en el cielo: hacia «yaw», a Elevation grados (o a los
-- que se pidan). Sin yaw, la de siempre (hacia el norte).
function SkyRift.skyDirection(yaw: number?, elevationDeg: number?): (number, number, number)
	local d = SkyRift.Placement.Sky.Direction
	local y = yaw or SkyRift.yawOf(d[1], d[3])
	local e = math.rad(elevationDeg or SkyRift.Placement.Sky.Elevation)
	return -math.sin(y) * math.cos(e), math.sin(e), -math.cos(y) * math.cos(e)
end

-- ¿Es de noche? (la primera noche en «Crece» o más se avisa de mirar al cielo). Hora del juego; es
-- DayCycle.isNight (oscuridad >= 0,5: de 21:45 a 07:30), escrito aquí para no hacer require
function SkyRift.isNight(clockTime: number): boolean
	local h = clockTime % 24
	return h >= 21.75 or h <= 7.5
end

-- Aviso «¡Mira al cielo!» (con una flecha hacia la grieta): la primera vez que el jugador está en una
-- fase con grieta en el cielo de Valmar (Rasguño o más) y la primera noche en «Crece» o más. memo
-- guarda lo ya avisado (First / Night): cada aviso, UNA vez. Devuelve "First", "Night" o nil.
function SkyRift.hintFor(memo: { [string]: boolean }, phaseName: string, clockTime: number): string?
	local ph = SkyRift.Phases[phaseName]
	if not ph or ph.Mode ~= "Sky" or ph.Stage < 2 or ph.Intensity <= 0 then
		return nil
	end
	if not memo.First then
		memo.First = true
		if SkyRift.isNight(clockTime) and ph.Stage >= 3 then
			memo.Night = true -- (ya es de noche: un solo aviso)
		end
		return "First"
	end
	if not memo.Night and ph.Stage >= 3 and SkyRift.isNight(clockTime) then
		memo.Night = true
		return "Night"
	end
	return nil
end
SkyRift.Aspect = 2 -- ancho / alto del marco de la rasgadura (rift_interior es 1024x512)

function SkyRift.stage(n: number?): Stage
	return SkyRift.Stages[math.clamp(math.floor(n or 1), 1, #SkyRift.Stages)]
end

-- Velocidad a la que se abre o se cierra (Open por segundo)
SkyRift.OpenRate = 0.12
SkyRift.CloseRate = 0.2

local PROLOGUE = "Prologo_Sueno" -- (StoryContext.PrologueId)

---------------------------------------------------------------------
-- Texturas (shared/RiftTextureIds, las escribe scripts/upload-rift.sh)
---------------------------------------------------------------------
SkyRift.TextureNames = {
	"rift_interior", "rift_glow", "rift_rays", "rift_galaxy",
	"rift_s2", "rift_s3", "rift_s4", "rift_s6", "rift_s6_galaxy", "rift_s7", "rift_s7_galaxy",
	"bolt_1", "bolt_2", "bolt_3", "bolt_4",
}
SkyRift.BoltTextures = { "bolt_1", "bolt_2", "bolt_3", "bolt_4" }

export type StageArt = { Texture: string, Aspect: number, Galaxy: { number }?, GalaxyTexture: string?, Spawn: { { number } }?, Star: { number }? }
export type Textures = {
	Main: string, -- la textura de la etapa
	Aspect: number,
	Glow: string?, -- (etapa 5) halo
	Rays: string?, -- (etapa 5) rayos del borde
	Galaxy: string?, -- la galaxia que gira (si la etapa tiene)
	Bolts: { string },
}

local function idOf(ids: { [string]: any }, name: string?): string?
	local v = if name then ids[name] else nil
	if type(v) == "string" and v:match("^rbxassetid://%d+$") then
		return v
	end
	return nil
end

-- Qué texturas hay para la etapa n (art: shared/SkyRiftArt). nil si falta la principal de la etapa:
-- entonces se dibuja por código. map (opcional): del id del Decal al de su imagen (shared/Images.of)
function SkyRift.textures(ids: { [string]: any }?, stage: number, art: { Stages: { [number]: StageArt } }, map: ((string) -> string)?): Textures?
	local all: { [string]: any } = ids or {}
	local conv = map or function(x: string): string
		return x
	end
	local spec = art.Stages[stage]
	if not spec then
		return nil
	end
	local main = idOf(all, spec.Texture)
	if not main then
		return nil
	end
	local function get(name: string?): string?
		local id = idOf(all, name)
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
		Main = conv(main),
		Aspect = SkyRift.stage(stage).FrameAspect or spec.Aspect,
		Glow = if stage == 5 then get("rift_glow") else nil,
		Rays = if stage == 5 then get("rift_rays") else nil,
		Galaxy = get(spec.GalaxyTexture),
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
-- Cuánto del marco se ve con esta apertura (dentro de su etapa): (ancho, alto) en fracción. Al nacer
-- es pequeña y fina (casi una línea) y crece hasta el marco entero.
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
-- Contorno (shared/SkyRiftArt): centro y normales hacia fuera
---------------------------------------------------------------------
export type Outline = {
	Rim: { { number } },
	Columns: { { number } },
	Galaxy: { number },
	Planet: { number },
	Stages: { [number]: StageArt },
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

-- Un rayo nuevo. spawn: puntos de donde pueden salir (el borde de la rasgadura o la línea de la
-- fractura, en fracciones del marco); r: aleatorio (0..1). Sale hacia fuera, más bien hacia abajo y a
-- los lados (como en la referencia), y dura 0,1-0,6 s.
function SkyRift.newBolt(spawn: { { number } }, r: () -> number): Bolt
	local cu, cv = 0, 0
	for _, p in spawn do
		cu += p[1]
		cv += p[2]
	end
	cu, cv = cu / #spawn, cv / #spawn
	local p = spawn[math.clamp(math.floor(r() * #spawn) + 1, 1, #spawn)]
	-- Hacia fuera desde el centro (aplastado: la grieta es mucho más ancha que alta)
	local du, dv = (p[1] - cu), (p[2] - cv) * 2.6
	local out = if math.abs(du) + math.abs(dv) < 1e-4 then r() * 2 * math.pi else math.atan2(dv, du)
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

-- ¿Prólogo «atascado»? La historia tiene el prólogo del sueño activo pero ya hay misiones de después
-- (de la saga o conocer a Cosme) hechas o en curso: el prólogo no se cerró bien. Para la grieta se
-- hace como si no estuviera (el servidor lo apunta en el registro: LifeStoryService).
function SkyRift.stuckPrologue(story: StoryLike): boolean
	local A = story.Active or {}
	if not A[PROLOGUE] then
		return false
	end
	local C = story.Completed or {}
	if C.Loco_N1_Cosme or C[PROLOGUE] then
		return true
	end
	for id in C do
		if type(id) == "string" and string.sub(id, 1, 5) == "Saga_" then
			return true
		end
	end
	for id in A do
		if type(id) == "string" and string.sub(id, 1, 5) == "Saga_" then
			return true
		end
	end
	return false
end

-- Qué fase toca según la historia del jugador (lo publica el servidor en el atributo SkyRift)
function SkyRift.phaseFor(story: StoryLike): string
	local A = story.Active or {}
	local C = story.Completed or {}
	local F = story.Flags or {}
	if A[PROLOGUE] and not SkyRift.stuckPrologue(story) then
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
		return { Rocks = 28, Bolts = 16, BoltSegments = 6, Emitters = 8, Stars = 40, Halo = true, OuterRim = true }
	end
	return { Rocks = 20, Bolts = 14, BoltSegments = 6, Emitters = 6, Stars = 30, Halo = true, OuterRim = true }
end

SkyRift.RockParts = 2 -- piezas por roca (un bloque y una cuña)
SkyRift.GalaxyDots = 36 -- puntos de los brazos de la galaxia sin textura
SkyRift.NebulaBlobs = 8

-- Cuántos de cada cosa pone una etapa con este nivel gráfico
function SkyRift.counts(stage: number, tierName: string): { Rocks: number, Bolts: number, Emitters: number, Stars: number }
	local look = SkyRift.tierLook(tierName)
	local st = SkyRift.stage(stage)
	return {
		Rocks = math.floor(look.Rocks * st.Rocks + 0.5),
		Bolts = math.floor(look.Bolts * st.Bolts + 0.5),
		Emitters = math.max(if st.Emitters > 0 then 1 else 0, math.floor(look.Emitters * st.Emitters + 0.5)),
		Stars = if st.Draw.Cosmos then look.Stars else 0,
	}
end

-- Cuántas instancias gasta (para el presupuesto del móvil). outline: la silueta (shared/SkyRiftArt);
-- textured: con texturas subidas o dibujada por código.
function SkyRift.budget(outline: Outline, stage: number, tierName: string, textured: boolean): { Parts: number, Gui: number, Beams: number, Emitters: number }
	local look = SkyRift.tierLook(tierName)
	local st = SkyRift.stage(stage)
	local n = SkyRift.counts(stage, tierName)
	if stage <= 1 then
		return { Parts = 0, Gui = 0, Beams = 0, Emitters = 0 }
	end
	local gui = 0
	if textured then
		gui = 4 + n.Bolts -- halo, textura, galaxia, rayos + un ImageLabel por rayo
	else
		local d = st.Draw
		gui = #outline.Rim * (if look.OuterRim then 2 else 1)
		if d.Fill then
			gui += #outline.Columns + SkyRift.NebulaBlobs
		end
		if d.Cosmos then
			gui += 1 + SkyRift.GalaxyDots + 1 + n.Stars
		end
		if d.Backdrop then
			gui += 3
		end
		gui += n.Bolts * (look.BoltSegments + 3)
	end
	if st.Star then
		gui += 3
	end
	return {
		Parts = 1 + n.Rocks * SkyRift.RockParts,
		Gui = gui,
		Beams = if look.Halo then 2 else 0,
		Emitters = n.Emitters,
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

-- Cuánto más brilla de día (el lienzo no recibe luz del mundo: contra el cielo azul de mediodía
-- necesita más brillo para que la galaxia y el interior se lean igual de bien que de noche)
function SkyRift.dayBoost(clockTime: number): number
	return 1 + 0.75 * (1 - (SkyRift.skyFactor(clockTime) - 0.88) / 0.12)
end

-- Escala del dibujo en el cielo (DrawDistance / Distance)
function SkyRift.drawScale(): number
	local sky = SkyRift.Placement.Sky
	return sky.DrawDistance / sky.Distance
end

-- Sonido de la grieta según la etapa (1 en silencio; 7 un rugido fuerte y ominoso):
--   Hum: zumbido grave (viento muy lento), Roar: rugido de fondo (trueno en bucle, lento, etapas 5-7),
--   Buzz: zumbido eléctrico (etapas 3-7), Crackle: cada cuánto crepita un rayo (s) y a qué volumen
function SkyRift.soundFor(stage: number): { Hum: number, HumPitch: number, Roar: number, Buzz: number, CrackleEvery: number, Crackle: number }
	local n = math.clamp(math.floor(stage), 1, 7)
	if n <= 1 then
		return { Hum = 0, HumPitch = 0.5, Roar = 0, Buzz = 0, CrackleEvery = math.huge, Crackle = 0 }
	end
	local k = (n - 2) / 5 -- 0 (la 2) … 1 (la 7)
	return {
		Hum = 0.25 + 0.65 * k,
		HumPitch = 0.62 - 0.17 * k, -- (cuanto más grande, más grave)
		Roar = if n >= 5 then 0.25 + 0.35 * (n - 5) / 2 else 0,
		Buzz = if n >= 3 then 0.08 + 0.12 * k else 0,
		CrackleEvery = if n >= 3 then 5 - 3 * k else math.huge,
		Crackle = 0.25 + 0.3 * k,
	}
end

-- Transparencia de las capas con esta intensidad (0 = no se ve), pulso y hora
function SkyRift.visibility(intensity: number, sky: number): number
	return math.clamp(intensity * sky, 0, 1)
end

-- Brillo del lienzo (SurfaceGui.Brightness): por encima de 1 el Bloom lo hace resplandecer
function SkyRift.brightness(intensity: number, pulse: number, flare: number): number
	return (1.4 + 0.9 * math.clamp(intensity, 0, 1)) * pulse * (1 + flare)
end

-- Cuánto tiñe el ambiente (DayLight.pushLayer con el Mood de la etapa): lo que diga la etapa, según
-- lo crecida que esté y lo que brille
function SkyRift.ambientWeight(stage: number, open: number, intensity: number): number
	local st = SkyRift.stage(stage)
	return math.clamp(st.Ambient * math.clamp(open, 0, 1) * math.clamp(intensity, 0, 1), 0, 1)
end

---------------------------------------------------------------------
-- Ciclo de DEMOSTRACIÓN (temporal, para que el dueño vea la grieta sin jugar la saga)
---------------------------------------------------------------------
-- Con Config.SkyRift.DemoCycle = true, el cielo de Valmar recorre TODAS las etapas a lo largo de un
-- día de juego (20 minutos reales: Config.DayLengthMinutes), según la hora del juego del servidor
-- (GameClock.hour(), la misma para todos): 1→2→3→4→5→6→7 y luego se cierra 7→4→1. El ciclo
-- entero pasa DOS veces al día (una de día y otra de noche: cada etapa se ve con luz y a oscuras).
-- Con el horario de verano (shared/DayCycle: pleno día de 08:00 a 21:30, noche cerrada de 22:00 a
-- 07:00) la noche es más corta que el día: los huecos de noche duran 1,25 h (unos 62 s reales) y los
-- de día 1,75 h (unos 87 s; en horario de clase, con niños en el servidor, el reloj va a 0,4 y duran
-- más). Las etapas con grieta de día caen a pleno día y las de noche, en noche cerrada; la grieta
-- cerrada (1) llena el amanecer y la hora dorada con el atardecer. Con false, la de la historia
-- (phaseFor) sin cambios. El sueño del prólogo (Sueno) no se toca.
--   De noche: 22:00 2 · 23:15 3 · 00:30 4 · 01:45 5 · 03:00 6 · 04:15 7 · 05:30 4 (se cierra) · 06:45 1
--   De día:   08:00 2 · 09:45 3 · 11:30 4 · 13:15 5 · 15:00 6 · 16:45 7 · 18:30 4 (se cierra) · 20:15 1
-- El modo pruebas puede adelantar o atrasar etapas para todo el servidor (atributo de workspace
-- SkyRiftDemoOffset, TesterService «RiftStep»).
SkyRift.Demo = {
	Slots = { "Cerrada", "Rasguno", "Crece", "Grande", "Abierta", "Inminente", "Fusion", "Ultima" },
	-- { desde (hora del juego), hueco de Slots }, por orden desde StartHour; cada uno dura hasta el siguiente
	Schedule = {
		{ 6.75, 1 }, -- amanece (de 07:00 a 08:00): grieta cerrada
		{ 8, 2 },
		{ 9.75, 3 },
		{ 11.5, 4 },
		{ 13.25, 5 },
		{ 15, 6 },
		{ 16.75, 7 },
		{ 18.5, 8 },
		{ 20.25, 1 }, -- hora dorada y atardecer (21:30 a 22:00): grieta cerrada
		{ 22, 2 },
		{ 23.25, 3 },
		{ 0.5, 4 },
		{ 1.75, 5 },
		{ 3, 6 },
		{ 4.25, 7 },
		{ 5.5, 8 },
	},
	StartHour = 6.75,
	SlotHours = 1.25, -- el hueco más corto (los de noche)
}

-- El hueco del horario (1..#Schedule) en que cae esa hora
local function scheduleIndex(clockTime: number): number
	local list = SkyRift.Demo.Schedule
	local start = list[1][1]
	local rel = (clockTime - start) % 24
	local found = 1
	for i, entry in list do
		if ((entry[1] - start) % 24) <= rel + 1e-9 then
			found = i
		end
	end
	return found
end

-- Qué hueco del ciclo toca a esa hora (1..#Slots), con el desfase del modo pruebas
function SkyRift.demoSlot(clockTime: number, offset: number?): number
	local d = SkyRift.Demo
	local n = #d.Slots
	local k = d.Schedule[scheduleIndex(clockTime)][2] - 1
	return (k + math.floor(offset or 0)) % n + 1
end

function SkyRift.demoPhase(clockTime: number, offset: number?): string
	return SkyRift.Demo.Slots[SkyRift.demoSlot(clockTime, offset)]
end

-- El horario del día entero: { Phase, Stage, From, To } (horas de juego), por orden desde StartHour
function SkyRift.demoSchedule(): { { Phase: string, Stage: number, From: number, To: number } }
	local d = SkyRift.Demo
	local out = {}
	local n = #d.Schedule
	for i, entry in d.Schedule do
		local name = d.Slots[entry[2]]
		local nextFrom = d.Schedule[i % n + 1][1]
		table.insert(out, { Phase = name, Stage = SkyRift.Phases[name].Stage, From = entry[1] % 24, To = nextFrom % 24 })
	end
	return out
end

-- La fase que se ve: la de la historia o, con el ciclo de demostración, la de la hora (menos en el
-- sueño del prólogo, que es su propia escena)
function SkyRift.effectivePhase(storyPhase: string, clockTime: number, demo: boolean, offset: number?): string
	if demo and storyPhase ~= "Sueno" then
		return SkyRift.demoPhase(clockTime, offset)
	end
	return storyPhase
end

---------------------------------------------------------------------
-- Cambio de etapa EN DIRECTO (como un evento en vivo: nadie pierde el control ni la cámara)
---------------------------------------------------------------------
-- Cuando cambia la etapa, la grieta pasa de una a otra en el cielo, en tiempo real, en unos 16 s:
--   0-5 s     se carga: parpadeo, rayos y chispas cada vez más fuertes, un rumor grave
--   5-9,5 s   la de antes se rasga más y se apaga (o se cose y se encoge) mientras nace la nueva;
--             salen rocas que se desprenden y van a la deriva
--   9,5 s     destello y onda expansiva en el cielo, un trueno grave
--   9,5-16 s  se calma; la luz del ambiente ya es la de la etapa nueva (cambia poco a poco)
-- Nunca toca la cámara (solo un temblor muy leve y opcional a pie), la interfaz ni los controles.
SkyRift.Live = {
	Seconds = 16,
	BuildUp = 5,
	MorphAt = 5,
	MorphSeconds = 4.5,
	FlashAt = 9.5,
	FlashSeconds = 1.8,
}

export type Transition = { From: number, To: number, Kind: string, FromPhase: string, ToPhase: string }

-- ¿Hay transición de una fase a otra? Solo en el cielo de Valmar y si cambia la etapa. Kind: "Abre"
-- (crece) o "Cierra" (se cose y se encoge)
function SkyRift.transitionFor(fromName: string, toName: string): Transition?
	local a, b = SkyRift.Phases[fromName], SkyRift.Phases[toName]
	if not a or not b or a.Mode ~= "Sky" or b.Mode ~= "Sky" or a.Stage == b.Stage then
		return nil
	end
	return { From = a.Stage, To = b.Stage, Kind = if b.Stage > a.Stage then "Abre" else "Cierra", FromPhase = fromName, ToPhase = toName }
end

-- Quién lleva la cuenta de la fase vista: la primera (al entrar, o hasta que llega la de tu historia)
-- no lanza nada (quien entra tarde ve la etapa de ahora); luego, una transición por cambio
export type Tracker = { Phase: string?, Fired: number }
function SkyRift.newTracker(): Tracker
	return { Phase = nil, Fired = 0 }
end

function SkyRift.track(tracker: Tracker, name: string, ready: boolean): Transition?
	if not ready then
		return nil
	end
	local before = tracker.Phase
	if before == nil then
		tracker.Phase = name
		return nil
	end
	if before == name then
		return nil
	end
	tracker.Phase = name
	local t = SkyRift.transitionFor(before, name)
	if t then
		tracker.Fired += 1
	end
	return t
end

local function smooth01(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
SkyRift.smooth = smooth01

-- En qué punto va la transición a los t segundos: Build (carga: parpadeo, rayos, rumor), Morph (de la
-- vieja a la nueva, 0..1), Flash (destello y onda, 0..1), Ring (la onda, 0..1 mientras se ve),
-- Morphed (ya se ha cambiado de etapa) y Done
function SkyRift.liveAt(t: number, kind: string?): { Build: number, Morph: number, Flash: number, Ring: number, Morphed: boolean, Done: boolean }
	local L = SkyRift.Live
	local build
	if t < L.BuildUp then
		build = math.clamp(t / L.BuildUp, 0, 1) ^ 1.5
	elseif t < L.FlashAt then
		build = 1
	else
		build = 1 - smooth01((t - L.FlashAt) / (L.Seconds - L.FlashAt))
	end
	local morph = smooth01((t - L.MorphAt) / L.MorphSeconds)
	local u = (t - L.FlashAt) / L.FlashSeconds
	local flash = if u >= 0 and u <= 1 then (1 - u) ^ 2 else 0
	return {
		Build = build,
		Morph = morph,
		Flash = flash,
		Ring = if u >= 0 and u <= 1 then u else -1,
		Morphed = t >= L.MorphAt,
		Done = t >= L.Seconds,
	}
end

-- Cuánto de cada cosa pone la transición con este nivel gráfico (Bajo: sin rocas 3D, menos rayos)
function SkyRift.liveCounts(tierName: string, kind: string, toStage: number): { Debris: number, BurstBolts: number, Sparks: number }
	local debris, bolts, sparks
	if tierName == "Low" then
		debris, bolts, sparks = 0, 4, 12
	elseif tierName == "High" then
		debris, bolts, sparks = 14, 10, 50
	else
		debris, bolts, sparks = 9, 8, 30
	end
	if kind ~= "Abre" or toStage < 3 then
		debris = 0 -- (al coserse no se desprende nada nuevo; la 2 es solo un punto)
	end
	return { Debris = debris, BurstBolts = bolts, Sparks = sparks }
end

-- El aviso discreto de arriba (uno por transición)
function SkyRift.liveToast(t: Transition): string
	if t.Kind == "Cierra" then
		return if t.To <= 1 then "🌌 La grieta del cielo se está cerrando…" else "🌌 La grieta del cielo se está cosiendo…"
	end
	return if t.From <= 1 then "🌌 ¡Mira al cielo! Algo se abre…" else "🌌 ¡Mira al cielo! La grieta crece…"
end

return SkyRift
