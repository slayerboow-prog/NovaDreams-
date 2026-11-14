-- ValmarGlobe: Valmar vista desde el espacio como un PLANETA PEQUEÑO y redondo (cuentas puras; lo pinta
-- Controllers/ValmarGlobeClient). Solo se VE: el mundo donde se anda sigue plano, sin gravedad nueva,
-- sin mover nada de la ciudad.
--
-- Cómo (como en los juegos de planetas sin pantallas de carga):
--   * Una esfera de radio Radius con la cima (Top) encima del centro de la isla, por encima de todo el
--     mundo plano (ver abajo por qué).
--     La isla va encima con la proyección «acimutal equidistante»: cada punto de Valmar a distancia d
--     del centro queda en la esfera a un arco d de la cima, en su misma dirección. Así la isla tiene su
--     tamaño de verdad medido sobre el planeta.
--   * Al subir por la Transición (Layers.TransitionY → FullY) el planeta aparece poco a poco (blend) y la
--     isla plana dibujada y el paisaje lejano se van: el horizonte plano se «curva». En el Espacio ya es
--     solo el planeta (con su aire azul en el borde, nubes y luces de las ciudades en el lado de noche).
--     Al bajar, lo mismo al revés: crece, se aplana y estás en la ciudad de siempre (sin corte).
--   * La superficie: la imagen del mapa de verdad de Valmar (textura «valmar_planeta», hecha por
--     scripts/espacio/gen_valmar_planeta.py desde las teselas del mapa grande) si está subida; si no,
--     la isla en polígonos (costa, barrios con su color, carreteras) proyectados en la esfera.
--   * El día y la noche: la esfera es una pieza de verdad iluminada por el sol de Roblox (el de la hora
--     del juego), así que el terminador coincide con la hora. Las luces de las ciudades salen solo en
--     el lado de noche (night).

local Layers = require(script.Parent.Layers)
local CityPlan = require(script.Parent.Parent.CityPlan)

local ValmarGlobe = {}

-- (14-11-2026, «Valmar sigue plana» por tercera vez) LA CAUSA DE VERDAD: Roblox dibuja una versión
-- simplificada del TERRENO a cualquier distancia, aunque esa zona no esté cargada en el cliente
-- (comprobado en Studio: ReadVoxels da Air y el terreno se ve igual). Ese terreno plano, a Y ≈ 0, queda
-- POR ENCIMA de una esfera cuya cima toca el mar y la tapa entera salvo un puntito: desde la nave se veía
-- la isla cuadrada de siempre flotando en el espacio. No hay forma de esconder el terreno desde un script.
-- Por eso el planeta es GRANDE y su superficie queda por encima de todo lo que hay en Valmar (terreno,
-- edificios y lomas de la isla, ±5.600 y menos de ~400 studs de alto): la esfera envuelve el mundo plano y
-- lo tapa. Su cima (Top) queda bastante por debajo de donde empieza a verse (FromY), para que la imagen no
-- se vea borrosa de tan cerca. Desde la nave es como estar en órbita baja: horizonte curvo, la isla abajo
-- y el borde azul del aire. (La costa de enfrente, al sur y siempre cargada, la esconde ValmarGlobeClient
-- mientras se ve el planeta.)
ValmarGlobe.Radius = 39600
ValmarGlobe.Top = 1200 -- la cima de la esfera (por encima de todo el mundo plano; por debajo de FromY)
ValmarGlobe.Center = Vector3.new(Layers.Center.X, ValmarGlobe.Top - ValmarGlobe.Radius, Layers.Center.Z)
-- La imagen del planeta (valmar_tierra / valmar_planeta) se hizo para un planeta de radio 5.000: la isla
-- va a su tamaño de verdad (un arco d en la imagen = un arco d en la esfera) y solo la parte de la isla.
ValmarGlobe.TexRadius = 5000
ValmarGlobe.TexMaxDeg = 56 -- hasta aquí de la imagen (la isla y su costa); más allá, mar liso
ValmarGlobe.FromY = Layers.TransitionY + 550 -- desde aquí empieza a verse (por encima de Top)
-- y aquí ya entero. Un cruce corto: en medio se ven a la vez las losas planas (Controllers/Horizon,
-- SpaceClient) y la esfera a medias.
ValmarGlobe.FullY = ValmarGlobe.FromY + 300
ValmarGlobe.AirLift = 900 -- grosor del aire (el aro azul del borde)
ValmarGlobe.CloudLift = 70
ValmarGlobe.LandLift = 32 -- la isla dibujada va por encima de la esfera (sus triángulos planos no se meten dentro)
-- (la textura de la Tienda va «norte arriba»; si al subirla la isla sale girada o en espejo, se cambian
-- estos dos y nada más: el generador y el juego usan la misma convención)
ValmarGlobe.TexYaw = 0 -- grados alrededor del eje vertical
ValmarGlobe.TexMirror = false

-- Cuánto planeta se ve a esta altura (0 = nada, 1 = entero), suave y siempre creciente con la altura
function ValmarGlobe.blend(y: number): number
	local t = math.clamp((y - ValmarGlobe.FromY) / (ValmarGlobe.FullY - ValmarGlobe.FromY), 0, 1)
	return t * t * (3 - 2 * t)
end

-- Un punto de Valmar (x, z del mundo plano) en la esfera, `lift` studs por encima de su superficie
function ValmarGlobe.toSphere(x: number, z: number, lift: number?): Vector3
	local C = ValmarGlobe.Center
	local dx, dz = x - C.X, z - C.Z
	local d = math.sqrt(dx * dx + dz * dz)
	local r = ValmarGlobe.Radius + (lift or 0)
	if d < 1e-6 then
		return C + Vector3.new(0, r, 0)
	end
	local theta = d / ValmarGlobe.Radius
	local s = math.sin(theta) / d
	return C + Vector3.new(dx * s * r, math.cos(theta) * r, dz * s * r)
end

-- La normal (hacia fuera) en un punto de la esfera
function ValmarGlobe.normal(p: Vector3): Vector3
	local v = p - ValmarGlobe.Center
	return if v.Magnitude > 1e-6 then v.Unit else Vector3.new(0, 1, 0)
end

-- ¿Es de noche en ese punto del planeta con el sol en sunDir? (para las luces de las ciudades)
function ValmarGlobe.night(p: Vector3, sunDir: Vector3): boolean
	return ValmarGlobe.normal(p):Dot(sunDir.Unit) < -0.04
end

-- Para el generador de la textura y las pruebas: el punto de Valmar (x, z) de un texel de la imagen
-- equirrectangular (u, v en 0..1; v = 0 es el polo de arriba, la cima donde está la isla)
function ValmarGlobe.texelToWorld(u: number, v: number): (number, number)
	local theta = v * math.pi
	local lon = math.rad(u * 360 + ValmarGlobe.TexYaw)
	if ValmarGlobe.TexMirror then
		lon = -lon
	end
	local d = theta * ValmarGlobe.TexRadius
	return ValmarGlobe.Center.X + d * math.sin(lon), ValmarGlobe.Center.Z - d * math.cos(lon)
end

-- Dónde hay luces de noche (los pueblos y barrios de la historia, los sitios y el centro)
function ValmarGlobe.lightSpots(): { { number } }
	local out = {}
	for _, p in CityPlan.Towns do
		table.insert(out, { p[1], p[2], 1 })
	end
	for _, p in CityPlan.Places do
		table.insert(out, { p[1], p[2], 0.6 })
	end
	-- (el centro, más denso: una rejilla de luces)
	for gx = -1, 1 do
		for gz = -1, 1 do
			if gx ~= 0 or gz ~= 0 then
				table.insert(out, { gx * 700, gz * 700, 0.8 })
			end
		end
	end
	return out
end

return ValmarGlobe
