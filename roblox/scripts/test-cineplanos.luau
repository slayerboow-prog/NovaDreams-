-- Prueba de los PLANOS de las cinemáticas y conversaciones contra el mapa real (Lune).
--
-- Uso (desde roblox/):
--   lune run scripts/test-cineplanos.luau [mapa.rbxl]
--     sin mapa: lo construye (rojo build + build-place, ~3 min); también vale CINEPLANOS_MAPA=ruta.
--   lune run scripts/test-cineplanos.luau --solo-cuentas   (solo la parte 1, sin mapa: segundos)
--
-- 1. Las cuentas de la cámara (CameraShots.fit, clearPath, anclas Over/Wide, ActorStaging.gatherSpot)
--    con un mundo de mentira: una pared detrás de la cámara, alguien delante de la cara, la regla de
--    los 180°, un dolly que cruzaría una farola, una escena lejos de ti.
-- 2. La auditoría visual entera (scripts/lib/CinePlanos, la de scripts/audit/cine-planos.luau) sobre
--    todas las misiones: falla si aparece un plano NUEVO con la cámara dentro de una pared o de alguien,
--    bajo tierra, con quien tiene que salir fuera de cuadro, un movimiento que atraviesa una pared, un
--    salto de eje o dos personas metidas la una en la otra. Las escenas del motor se ponen también
--    llegando desde otros lados y en un vehículo aparcado a tu lado (CinePlanos.Arrivals).
--    CINEPLANOS_TODO=1: la lista entera de planos nuevos con fallo (si no, los 40 primeros). Los casos que se conocen y no se han podido arreglar están en PENDIENTES (y en
--    docs/auditoria-cinematicas-visual.md); si uno se arregla, se avisa para quitarlo de la lista.

local process = require("@lune/process")
local roblox = require("@lune/roblox")

local L = require("./lib/ModuleLoader")
local Vector3 = roblox.Vector3
local V = Vector3.new
local check = L.check

local CameraShots = L.load("src/shared/CameraShots")
local ActorStaging = L.load("src/shared/LifeStory/ActorStaging")

---------------------------------------------------------------------
print("1. Cuentas de la cámara (sin mapa)")
---------------------------------------------------------------------
-- Mundo de mentira: cajas { lo, hi } que tapan
local function boxProbe(boxes, bodies)
	return {
		bodies = bodies or {},
		cast = function(origin, direction)
			local best = nil
			for _, b in boxes do
				local lo, hi = b[1], b[2]
				-- (si el rayo sale de dentro no cuenta, como en Roblox)
				local inside = origin.X > lo.X and origin.X < hi.X and origin.Y > lo.Y and origin.Y < hi.Y and origin.Z > lo.Z and origin.Z < hi.Z
				if not inside then
					local tmin, tmax = 0, 1
					local ok = true
					for _, axis in { "X", "Y", "Z" } do
						local o, d = (origin :: any)[axis], (direction :: any)[axis]
						local l, h = (lo :: any)[axis], (hi :: any)[axis]
						if math.abs(d) < 1e-9 then
							if o < l or o > h then
								ok = false
							end
						else
							local t1, t2 = (l - o) / d, (h - o) / d
							if t1 > t2 then
								t1, t2 = t2, t1
							end
							tmin, tmax = math.max(tmin, t1), math.min(tmax, t2)
							if tmin > tmax then
								ok = false
							end
						end
					end
					if ok then
						local dist = tmin * direction.Magnitude
						best = if best then math.min(best, dist) else dist
					end
				end
			end
			return best
		end,
	}
end

local focus = V(0, 4.5, 0)
local cam = CameraShots.lookAt(V(0, 5, -10), focus)
-- Libre: el plano no cambia
local free = CameraShots.fit(cam, focus, boxProbe({}))
check((free.Position - cam.Position).Magnitude < 1e-4, "sin nada en medio, el plano se queda igual")
-- Pared entre la cara y la cámara a 6 studs: se acerca por la misma línea (y sigue mirando la cara)
local wall = { V(-20, 0, -6.5), V(20, 20, -6) }
local fitted = CameraShots.fit(cam, focus, boxProbe({ wall }))
check((fitted.Position - focus).Magnitude < 6.2 and (fitted.Position - focus).Magnitude >= CameraShots.FIT_MIN, "pared detrás: la cámara se acerca hasta antes de ella")
check(fitted.LookVector:Dot((focus - fitted.Position).Unit) > 0.99, "…y sigue mirando a la misma cara")
-- Pared pegada a la cara (a 1 stud): acercarse no vale, gira alrededor
local close = { V(-1.2, 0, -1.6), V(1.2, 20, -1.2) }
local turned = CameraShots.fit(cam, focus, boxProbe({ close }))
check((turned.Position - focus).Magnitude > CameraShots.FIT_MIN and boxProbe({ close }).cast(focus, turned.Position - focus) == nil, "pared pegada a la cara: el plano gira alrededor del foco hasta verla")
-- Alguien entre la cámara y la cara: no se queda detrás de su cabeza
local someone = { Head = V(0, 4.5, -4), Feet = V(0, 0, -4) }
local around = CameraShots.fit(cam, focus, boxProbe({}, { someone }))
local probeBodies = boxProbe({}, { someone })
check((around.Position - cam.Position).Magnitude > 0.5, "alguien delante de la cara: el plano cambia")
check(CameraShots.clearPath(around.Position, focus + (around.Position - focus).Unit * 1.3, { cast = probeBodies.cast, bodies = { someone } }), "…y ya no hay nadie entre la cámara y la cara")
-- Quien está en el foco no tapa (es el sujeto)
local subject = { Head = focus, Feet = V(0, 0, 0) }
local same = CameraShots.fit(cam, focus, boxProbe({}, { subject }))
check((same.Position - cam.Position).Magnitude < 1e-4, "el sujeto no se tapa a sí mismo")
-- Choice: los fotogramas siguientes no cambian de giro
local _, choice = CameraShots.fit(cam, focus, boxProbe({ close }))
local again, choice2 = CameraShots.fit(cam, focus, boxProbe({}), { Choice = choice })
check(choice2 == choice and (again.Position - turned.Position).Magnitude < 1e-3, "con Choice el giro elegido al empezar el plano se mantiene")
-- Un foco lejísimos (el cielo): no se toca
local sky = CameraShots.lookAt(V(0, 5, -10), V(0, 400, 0))
check(CameraShots.fit(sky, V(0, 400, 0), boxProbe({ wall })) == sky, "un plano al cielo no se ajusta")
-- clearPath: un dolly que cruza una farola no vale
local pole = { V(-0.3, 0, -8.3), V(0.3, 20, -7.7) }
check(not CameraShots.clearPath(V(-3, 5, -8), V(3, 5, -8), boxProbe({ pole })), "un dolly que atraviesa una farola: no")
check(CameraShots.clearPath(V(-3, 5, -12), V(3, 5, -12), boxProbe({ pole })), "…y uno que pasa por delante, sí")
check(not CameraShots.clearPath(V(0, 4.5, -12), V(0, 4.5, 2), { cast = function() return nil end, bodies = { someone } }), "un dolly que pasa por la cabeza de alguien: no")

-- Regla de los 180°: plano y contraplano (y el plano de dos) del mismo lado de la línea
local people = {
	Player = CameraShots.lookAt(V(0, 3, -6), V(0, 3, 0)),
	["Actor:Lucia"] = CameraShots.lookAt(V(0, 3, 0), V(0, 3, -6)),
	["Actor:Mateo"] = CameraShots.lookAt(V(6, 3, 0), V(0, 3, 0)),
	["Actor:Sara"] = CameraShots.lookAt(V(0, 3, 6), V(6, 3, 0)),
}
local resolve = CameraShots.composite(function(name)
	return people[name]
end)
local function sideOf(a, b, p)
	local ab, ap = b - a, p - a
	return if ab.X * ap.Z - ab.Z * ap.X > 0 then 1 else -1
end
local function camOf(spec)
	local shot = CameraShots.preset(spec)
	return CameraShots.base(shot, 0, resolve).Position
end
local p, l, m = people.Player.Position, people["Actor:Lucia"].Position, people["Actor:Mateo"].Position
check(sideOf(p, l, camOf("Hombro:Yo>Lucia")) == sideOf(p, l, camOf("Hombro:Lucia>Yo")), "Hombro:Yo>Lucia y Hombro:Lucia>Yo del mismo lado de la línea")
check(sideOf(l, m, camOf("Hombro:Lucia>Mateo")) == sideOf(l, m, camOf("Hombro:Mateo>Lucia")), "Hombro:Lucia>Mateo y su contraplano, del mismo lado")
check(sideOf(l, m, camOf("Hombro:Lucia>Mateo")) == sideOf(l, m, p), "…del lado desde donde lo ves tú")
-- Wide: dos que están lejos caben en el plano de dos
people["Actor:Mateo"] = CameraShots.lookAt(V(30, 3, 0), V(0, 3, 0))
local dos = CameraShots.preset("DosPlanos:Lucia,Mateo")
local dosCf = CameraShots.base(dos, 0, resolve)
local function onScreen(cf, point, fov)
	local rel = cf:PointToObjectSpace(point)
	local ty = math.tan(math.rad(fov) / 2)
	return -rel.Z > 0 and math.abs(rel.X / (-rel.Z * ty * 16 / 9)) <= 1
end
check(onScreen(dosCf, V(0, 4.5, 0), 55) and onScreen(dosCf, V(30, 4.5, 0), 55), "DosPlanos de dos a 30 studs: salen los dos")
-- Line en fit: los giros no cruzan la línea de la pareja
local lineCam = CameraShots.lookAt(V(2, 5, -8), V(0, 4.5, 0))
local lineFit = CameraShots.fit(lineCam, V(0, 4.5, 0), boxProbe({ { V(-1.2, 0, -2.6), V(3, 20, -2.2) } }), { Line = { V(0, 4.5, 0), V(0, 4.5, -8) } })
check(sideOf(V(0, 0, 0), V(0, 0, -8), lineFit.Position) == sideOf(V(0, 0, 0), V(0, 0, -8), lineCam.Position), "fit con Line: el giro no cruza la línea de la pareja")
-- Escena lejos de ti: te acerca a quien la lleva
local lead = ActorStaging.lead({ { Npc = "Alumno1", Place = "X", Mode = "Wander" }, { Npc = "Luca", Place = "Universidad" } }, { "Luca" })
check(lead and lead.Npc == "Luca", "quien lleva la escena: el primero que habla con sitio en el mapa")
check(ActorStaging.gatherSpot(V(0, 0, 0), V(20, 0, 0), "Scene") == nil, "conversación a 20 studs: no te mueve (se acerca él)")
local spot = ActorStaging.gatherSpot(V(0, 0, 0), V(90, 0, 0), "Scene")
check(spot ~= nil and math.abs((spot - V(90, 0, 0)).Magnitude - ActorStaging.GatherStop) < 1e-3 and spot.X < 90, "a 90 studs: te deja a unos pasos, de tu lado")
check(ActorStaging.gatherSpot(V(0, 0, 0), V(40, 0, 0), "Cinematic") ~= nil, "escena del motor a 40 studs: también")

-- Llegas en bici (vídeo de la Plaza Mayor, Adulto_Bienvenida): la escena te baja, la bici de alquiler
-- se retira y la tuya se queda aparcada a tu lado. Las marcas de Ernesto y Lola van contigo («Yo»):
-- con un coche aparcado a tu derecha, la escena se gira hasta que nadie cae dentro de él.
local CF = L.CFrame
local car = { V(0.8, 0, -6), V(6, 6, 2) } -- (caja del coche aparcado, en planta)
local function inCar(p)
	return p.X > car[1].X and p.X < car[2].X and p.Z > car[1].Z and p.Z < car[2].Z
end
local marks = { V(1.8, 0, -3.6), V(-1.8, 0, -3.6) }
local yoCf = CF.new(0, 3, 0)
check(inCar(yoCf:PointToWorldSpace(marks[1])), "(sin girar, Ernesto caería dentro del coche)")
local turnedCf, yaw, still = ActorStaging.clearFacing(yoCf, marks, inCar)
check(yaw ~= 0 and still == 0, ("llegas en bici con tu coche al lado: la escena se gira %d° y nadie cae en el coche"):format(yaw))
local feet = { V(0, 0, 0) }
for _, m in marks do
	local p = turnedCf:PointToWorldSpace(m) - V(0, 3, 0)
	table.insert(feet, ActorStaging.freeMark(p, feet))
end
check(ActorStaging.overlapping(feet) == nil, "tú, Ernesto y Lola sin meteros el uno en el otro")
check((feet[2] - feet[3]).Magnitude >= 3 and (feet[2] - feet[1]).Magnitude >= 3, "…a una distancia para hablar (3-6 studs)")
-- Dos marcas encima de ti y la una de la otra: se apartan lo justo, sin caer en el coche
local crowd = { V(0, 0, 0) }
for _, p in { V(0, 0, -0.4), V(0.1, 0, -0.5), V(1, 0, -1) } do
	table.insert(crowd, ActorStaging.freeMark(p, crowd, nil, nil, function(q)
		return not inCar(q)
	end))
end
local a, b, d = ActorStaging.overlapping(crowd)
check(a == nil, ("tres marcas encima de ti: se separan (%s)"):format(if d then ("%.2f"):format(d) else "ok"))
local inside = false
for i = 2, #crowd do
	inside = inside or inCar(crowd[i])
end
check(not inside, "…y ninguna dentro del coche aparcado")
check(ActorStaging.freeMark(V(5, 0, 0), { V(0, 0, 0) }) == V(5, 0, 0), "una marca que ya está bien no se toca")

-- Quien habla tapado: alguien (de espaldas a la cámara) pegado a la cara de quien habla y la cámara
-- justo detrás de su espalda. Acercarse no basta: el plano tiene que cambiar hasta verle la cara.
local speaker = { Head = V(0, 4.5, 0), Feet = V(0, 0, 0) }
local blocker = { Head = V(0, 4.5, -1.6), Feet = V(0, 0, -1.6) }
local behind = CameraShots.lookAt(V(0, 4.6, -3.2), speaker.Head)
local probeTwo = boxProbe({}, { speaker, blocker })
local function clearView(cf, focus, bodies)
	for _, body in bodies do
		if (body.Head - focus).Magnitude > 1.2 then
			for _, sphere in CameraShots.bodySpheres(body) do
				local ab = focus - cf.Position
				local t = math.clamp((sphere[1] - cf.Position):Dot(ab) / ab:Dot(ab), 0, 1)
				if (cf.Position + ab * t - sphere[1]).Magnitude < sphere[2] then
					return false
				end
			end
		end
	end
	return true
end
check(not clearView(behind, speaker.Head, { blocker }), "(el plano de partida: la espalda de otro llena la pantalla)")
local fixed, fixedChoice = CameraShots.fit(behind, speaker.Head, probeTwo, { Keep = { speaker.Head } })
check(clearView(fixed, speaker.Head, { blocker }), "quien habla tapado por otro: la cámara se mueve hasta verle la cara")
check(fixed.LookVector:Dot((speaker.Head - fixed.Position).Unit) > 0.98, "…y sigue mirando a quien habla")
local insideBody = false
for _, sphere in CameraShots.bodySpheres(blocker) do
	insideBody = insideBody or (fixed.Position - sphere[1]).Magnitude < sphere[2]
end
check(not insideBody, "…sin meterse dentro de quien tapaba")
-- A mitad de plano alguien se mete delante (Choice ya elegido): se cambia de giro, no se queda tapado
local free0, choice0 = CameraShots.fit(behind, speaker.Head, boxProbe({}, { speaker }))
local later, choiceLater = CameraShots.fit(behind, speaker.Head, boxProbe({}, { speaker, { Head = V(0, 4.5, -1.4), Feet = V(0, 0, -1.4) } }), { Choice = choice0 })
check((free0.Position - behind.Position).Magnitude < 1e-3, "(nadie delante al empezar: el plano tal cual)")
check(choiceLater ~= choice0 and clearView(later, speaker.Head, { { Head = V(0, 4.5, -1.4), Feet = V(0, 0, -1.4) } }), "alguien se cruza a mitad de plano: la cámara cambia de giro y sigue viendo la cara")
local _ = fixedChoice

if table.find(process.args, "--solo-cuentas") then
	print(if L.failures == 0 then "\n✅ test-cineplanos (cuentas): todo correcto" else ("\n❌ %d fallos"):format(L.failures))
	process.exit(if L.failures == 0 then 0 else 1)
end

---------------------------------------------------------------------
print("2. Auditoría visual contra el mapa real")
---------------------------------------------------------------------
local E = require("./lib/CinePlanos")

-- Fallos que impiden ver bien un plano (los que vigila esta prueba)
-- (Solapados: dos personas metidas la una en la otra. Las escenas del motor se miran también llegando
-- desde otros lados y en un vehículo que se queda aparcado a tu lado: CinePlanos.Arrivals)
local WATCHED = { CamaraDentro = true, CamaraEnPersonaje = true, BajoTierra = true, FueraDeCuadro = true, Atraviesa = true, Salta180 = true, Tapado = true, TapadoPorPersona = true, Solapados = true }

-- Conocidos (escena · plano · tipo) que no tienen arreglo general: ver docs/auditoria-cinematicas-visual.md
local PENDIENTES: { [string]: string } = {
	-- «Misión#paso Escena|Plano|Tipo» = por qué sigue así
	["Adu02_Atardecer#13 Adu02_Orilla|Pan:Abu|FueraDeCuadro"] = "playa de terreno: Abu sentado en la arena, el barrido acaba de lado",
	["Adu_Ascenso#6 Respuesta|Hombro:Ernesto>Yo|BajoTierra"] = "Ernesto un escalón por debajo: la cámara baja con él (se ve bien)",
	["Eco_Despido#7 Reaccion|Hombro:Ernesto>Yo|BajoTierra"] = "el mismo sitio que Adu_Ascenso#6",
	["Adulto_MirarAtras#2 Vida_MirarAtras|Fixed|CamaraEnPersonaje"] = "montaje de recuerdos: planos a mano en casa",
	["Adulto_MirarAtras#2 Vida_MirarAtras|Travel|FueraDeCuadro"] = "montaje: el último plano mira al cielo",
	["Cole01_PrimerDia#43 Cena|Reaccion:Yo|Tapado"] = "cena: el jugador junto a la mesa de la cocina, el borde tapa algo",
	["Cole01_PrimerDia#43 Cena|PrimerPlano:Yo|Tapado"] = "cena (guion reescrito): el mismo sitio junto a la mesa de la cocina",
	["Cole09_Misterio#15 Dentro|Hombro:Yo>Ramon|CamaraDentro"] = "Ramón en el marco de la puerta del aula vieja (su cabeza toca la pared)",
	["Ins05_ElRumor#17 Ins05_DiaDespues|DosPlanos:Omar,Nico|Salta180"] = "DosPlanos de dos que miran al mismo lado (manda hacia donde miran)",
	["Saga_16_66B#3 Malvado|DosPlanos:TuMalvado,Ivan|FueraDeCuadro"] = "los dos lejos y entre paredes: la cámara no puede alejarse",
	["Saga_18_Precio#1 Anuncio|DosPlanos:Pip,Cosme|FueraDeCuadro"] = "garaje de Cosme: no cabe el plano de dos",
	["Saga_21_Consorcio#3 Quiebra|DosPlanos:Candela,Ivan|Tapado"] = "pared de la torre entre los dos",
	["Saga_24_Final#3 Grieta_Final|DosPlanos:Cosme,Cosimo|FueraDeCuadro"] = "cima del monte (terreno)",
	["Uni01_PrimerDia#5 Uni01_Campus|DosPlanos:Sara,Yo|FueraDeCuadro"] = "sitio del jugador aproximado en la explanada",
	["Uni06_Graduacion#19 Uni06_Final|DosPlanos:Abu,Yo|FueraDeCuadro"] = "cafetería con cristal: no cabe el plano de dos",
	["Uni06_Graduacion#19 Uni06_Final|Orbit|CamaraDentro"] = "órbita escrita a mano dentro de la casa",
	-- Llegando desde otro lado o en un vehículo aparcado a tu lado (CinePlanos.Arrivals): casos sueltos que
	-- no tienen arreglo general (la escena se pensó para llegar por un sitio concreto)
	["Cole04_Malotes#28 Rama_Grupo|DosPlanos:Nico,Bruno|FueraDeCuadro"] = "tabique del colegio entre los dos: la cámara ve a Nico pero tan cerca que no cabe entero",
	["Ins01_NuevoInstituto#7 Entrada|Hombro:Yo>Omar|CamaraDentro"] = "pared del instituto entre los dos (sitio del jugador aproximado): la cámara roza la pared",
	["Adulto_LlegadaValmar#2 Adulto_Bienvenida [desde atrás]|DosPlanos:Ernesto,Lola|Tapado"] = "llegando de espaldas a la plaza: el poste del cartel entre la cámara y Ernesto",
	["Adulto_LlegadaValmar#2 Adulto_Bienvenida [desde atrás]|DosPlanos:Ernesto,Yo|Tapado"] = "llegando de espaldas a la plaza: la fachada del edificio 10 detrás",
	["Eco_Despido#10 Adu_DespidoCasa [en coche]|Seguir:Familia|CamaraDentro"] = "el seguimiento cruza tu coche aparcado (en el juego el actor lo rodea)",
	["Pan3_Cruce#3 Pan3_Oferta [desde la izquierda]|DosPlanos:Rayo,Yo|Salta180"] = "salto de eje leve al llegar de lado",
	["Saga_12_Graduacion#2 Grieta_Rota [en coche]|Tilt:Cosimo|FueraDeCuadro"] = "Tilt de un gigante con tu coche al lado: la cabeza sale por arriba",
	["Saga_23_Fusion#1 Grieta_Fusion [en coche]|DosPlanos:Cosme,Yo|FueraDeCuadro"] = "cima del monte (terreno) con tu coche al lado",
	["Uni01_PrimerDia#5 Uni01_Campus [desde la izquierda]|DosPlanos:Luca,Yo|Salta180"] = "salto de eje leve al llegar de lado (explanada, sitio aproximado)",
	["Uni01_PrimerDia#5 Uni01_Campus [en coche]|DosPlanos:Sara,Yo|CamaraDentro"] = "explanada del campus: el plano de dos queda pegado a tu coche aparcado",
	["Uni01_PrimerDia#9 Uni01_Beltran [en coche]|Pan:Beltran|FueraDeCuadro"] = "barrido escrito a mano desde donde está tu coche",
	["Uni05_PrimerPiso#12 Uni05_Visita [en coche]|DosPlanos:Abu,Yo|FueraDeCuadro"] = "portal estrecho del piso con tu coche al lado: no cabe el plano de dos",
}

local placePath = nil
for _, a in process.args do
	if a:match("%.rbxl$") then
		placePath = a
	end
end
placePath = placePath or process.env.CINEPLANOS_MAPA or E.buildMap()
local ctx = E.open(placePath)
local t0 = os.clock()
local scenes = E.collect(ctx)
local shots, newOnes, seenKnown = 0, {}, {}
for _, scene in scenes do
	E.audit(ctx, scene)
	for _, shot in scene.Shots do
		shots += 1
		for _, problem in shot.Problems do
			if WATCHED[problem.Kind] then
				local key = ("%s|%s|%s"):format(scene.Id, shot.Spec, problem.Kind)
				-- (un caso conocido lo es también llegando desde otro lado: «Escena [desde atrás]|…»)
				local plain = key:gsub(" %[[^%]]*%]", "")
				if PENDIENTES[key] or PENDIENTES[plain] then
					seenKnown[if PENDIENTES[key] then key else plain] = true
				else
					table.insert(newOnes, key .. " · " .. problem.Detail)
				end
			end
		end
	end
end
print(("  %d escenas, %d planos revisados en %.0f s"):format(#scenes, shots, os.clock() - t0))
check(#scenes > 500 and shots > 2500, "se ponen en escena todas las conversaciones y escenas del motor")
table.sort(newOnes)
for i, line in newOnes do
	if i <= 40 or process.env.CINEPLANOS_TODO then -- (CINEPLANOS_TODO=1: la lista entera)
		print("     " .. line)
	end
end
check(#newOnes == 0, ("ningún plano nuevo con la cámara dentro de algo, bajo tierra, sin su sujeto en cuadro, tapado, atravesando paredes, saltando el eje o con dos personas metidas la una en la otra (%d)"):format(#newOnes))
for key in PENDIENTES do
	if not seenKnown[key] then
		print("  ℹ ya no falla (quítalo de PENDIENTES): " .. key)
	end
end

print(if L.failures == 0 then "\n✅ test-cineplanos: todo correcto" else ("\n❌ test-cineplanos: %d fallos"):format(L.failures))
process.exit(if L.failures == 0 then 0 else 1)
