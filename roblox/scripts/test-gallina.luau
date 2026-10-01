-- Prueba de «La gallina de seis metros» (Loco_N3_Pollo) FUERA de Roblox, con Lune: que lo que cuenta
-- la misión se VE en el juego.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-gallina.luau                  # la gallina, sus huevos y la misión
--   rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl
--   lune run scripts/test-gallina.luau /tmp/x.rbxl      # y además, la granja de Julián en el mapa
--
-- Comprueba que:
--   * Petra (World/Kit/GallinaGigante) es una gallina de verdad: ~6 m (20 studs) con cuerpo, plumas en
--     capas, alas, cola, cresta y barbillas rojas, pico, ojos, patas con dedos; articulaciones para
--     moverse; nada choca; disfrazada sobre un personaje, los pies en el suelo
--   * se mueve como una gallina (Controllers/GiantHen): cabeza a golpes, picotazos, patas al andar
--   * la misión la usa: Petra comiendo en el granero, los huevos gigantes en el nido (el que hay que
--     mirar brilla), la huida al silo y el rayo encogedor que la va encogiendo hasta su tamaño
--   * en el mapa: una sola granja de Julián con un granero GRANDE en el que se entra (portón abierto
--     por el que cabe Petra, dentro nada que bloquee el paso hasta el nido y los comederos), silo,
--     y los sitios de la misión (patio, nido, comederos, silo) existen y están despejados

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Color3, Enum, Instance = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum, roblox.Instance
local V = Vector3.new

local function load(path: string, extra: { [string]: any }?)
	local env = setmetatable({
		CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum, Instance = Instance,
		Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, NumberRange = roblox.NumberRange, NumberSequence = roblox.NumberSequence,
		ColorSequence = roblox.ColorSequence,
	}, { __index = getfenv(1) })
	for k, v in extra or {} do
		env[k] = v
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Caja que envuelve las piezas (Lune no tiene GetBoundingBox), en los ejes de "frame"
local function bounds(parts: { any }, frame: any?): (any, any)
	local lo, hi = V(1e9, 1e9, 1e9), V(-1e9, -1e9, -1e9)
	local inv = if frame then frame:Inverse() else CFrame.new()
	for _, p in parts do
		local h = p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = inv * (p.CFrame * V(h.X * sx, h.Y * sy, h.Z * sz))
					lo = lo:Min(w)
					hi = hi:Max(w)
				end
			end
		end
	end
	return lo, hi
end

local function partsOf(model: any): { any }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function count(model: any, prefix: string): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name:sub(1, #prefix) == prefix then
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------------
print("\n▶ Petra, la gallina de seis metros (World/Kit/GallinaGigante)")
local Gallina = load("src/server/World/Kit/GallinaGigante.luau")
local giant = Gallina.build(20)
local lo, hi = bounds(partsOf(giant))
local height = hi.Y - lo.Y
check(height > 19 and height < 21.5, ("mide unos 20 studs, seis metros (%.1f)"):format(height))
check(math.abs(lo.Y) < 0.2, "con los pies en el suelo")
check(hi.Z - lo.Z > 14 and hi.X - lo.X > 9, ("es una gallina, no un palo: %.0f de largo y %.0f de ancho"):format(hi.Z - lo.Z, hi.X - lo.X))
local needs = { Cuerpo = 1, Pecho = 1, Cabeza = 1, Cresta = 3, CrestaBase = 1, Barbilla = 2, Pico = 2, Ojo = 2, Pupila = 2, Brillo = 2, AlaL = 1, AlaR = 1, Remera = 6, Cola = 5, PataL = 1, PataR = 1, Dedo = 6, Pluma = 12, Gorguera = 5 }
local missing = {}
for name, n in needs do
	if count(giant, name) < n then
		table.insert(missing, name)
	end
end
table.sort(missing)
check(#missing == 0, "cuerpo, pecho, plumas en capas, gorguera, alas con remeras, cola en abanico, cresta, barbillas, pico, ojos con brillo y patas con dedos" .. (if #missing > 0 then " (faltan: " .. table.concat(missing, ", ") .. ")" else ""))
local red = giant:FindFirstChild("Cresta")
local beak = giant:FindFirstChild("Pico")
check(red and red.Color.R > 0.7 and red.Color.G < 0.3 and beak and beak.Color.R > 0.8 and beak.Color.B < 0.4, "cresta roja y pico amarillo")
local beakZ = (beak.CFrame.Position).Z
check(beakZ < lo.Z + 2, "el pico va delante (hacia -Z)")
local anchored, collide, loose = 0, 0, 0
for _, p in partsOf(giant) do
	if p.Anchored then
		anchored += 1
	end
	if p.CanCollide or p.CanQuery then
		collide += 1
	end
end
for _, d in giant:GetDescendants() do
	if (d:IsA("Weld") or d:IsA("Motor6D")) and (d.Part0 == nil or d.Part1 == nil) then
		loose += 1
	end
end
check(anchored == 1 and giant.PrimaryPart and giant.PrimaryPart.Anchored, "solo la raíz está anclada (lo demás va soldado: se puede animar)")
check(collide == 0, "ninguna pieza choca ni estorba (es un disfraz/adorno)")
check(loose == 0, "todas las soldaduras unen dos piezas")
local motors = {}
for _, d in giant:GetDescendants() do
	if d:IsA("Motor6D") then
		motors[d.Name] = true
	end
end
check(motors.M_Cuerpo and motors.M_Cabeza and motors.M_AlaL and motors.M_AlaR and motors.M_Cola and motors.M_PataL and motors.M_PataR, "articulaciones de cuerpo, cabeza, alas, cola y patas")
check(giant:HasTag("GallinaGigante"), "etiqueta GallinaGigante (el cliente la anima)")
local shadows = 0
for _, p in partsOf(giant) do
	if p.CastShadow then
		shadows += 1
	end
end
check(#partsOf(giant) <= 110 and shadows <= 16, ("piezas justas para el móvil: %d piezas, %d con sombra"):format(#partsOf(giant), shadows))
local small = Gallina.build(1.7, nil, { Simple = true })
check(#partsOf(small) <= 50, ("la gallina normal del corral es sencilla (%d piezas)"):format(#partsOf(small)))

-- Disfraz sobre un personaje (como en la misión): los pies en el suelo, el cuerpo de persona escondido
local rig = Instance.new("Model")
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Size = V(2, 2, 1)
root.CFrame = CFrame.new(10, 3, 5)
root.Parent = rig
local head = Instance.new("Part")
head.Name = "Head"
head.Size = V(1, 1, 1)
head.CFrame = CFrame.new(10, 4.5, 5)
head.Parent = rig
local humanoid = Instance.new("Humanoid")
humanoid.HipHeight = 2
humanoid.Parent = rig
local costume = Gallina.costume(rig)
check(costume ~= nil and costume.Parent == rig, "el personaje lleva la gallina dentro de su modelo (Model:ScaleTo la agranda y la encoge con él)")
local clo, chi = bounds(partsOf(costume))
check(math.abs(clo.Y - 0) < 0.3, ("sus pies, en el suelo del personaje (%.2f)"):format(clo.Y))
check(math.abs((chi.Y - clo.Y) * 2.4 - 20) < 1.5, ("con Scale 2.4 (la misión) mide ~20 studs: %.1f"):format((chi.Y - clo.Y) * 2.4))
check(root.Transparency == 1 and head.Transparency == 1, "el cuerpo de persona no se ve")
local weld = costume.PrimaryPart:FindFirstChild("GallinaPies")
check(weld and weld.Part0 == root and not costume.PrimaryPart.Anchored, "soldada a la raíz del personaje (anda, persigue y busca camino como siempre)")

---------------------------------------------------------------------
print("\n▶ Se mueve como una gallina (Controllers/GiantHen)")
local GiantHen = load("src/client/Controllers/GiantHen.luau", {
	game = { GetService = function(_, name)
		return { Name = name }
	end },
})
local seed = 1
local function rnd(): number
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end
local st = GiantHen.newState(5)
local jerks, pecks, maxSettle, nan = 0, 0, 0, false
local last = nil
local legIdle = 0
for i = 1, 30 * 40 do
	local t = i / 30
	local poses = GiantHen.pose(st, t, 1 / 30, 0, rnd)
	local x, y, z = poses.Cabeza:ToEulerAnglesXYZ()
	if x ~= x or y ~= y then
		nan = true
	end
	if last and (math.abs(y - last) > 0.05) then
		jerks += 1
	end
	last = y
	if x > 0.6 then
		pecks += 1
	end
	maxSettle = math.max(maxSettle, st.Settle)
	local lx = poses.PataL:ToEulerAnglesXYZ()
	legIdle = math.max(legIdle, math.abs(lx))
end
check(not nan, "sin números raros")
check(jerks > 20, ("la cabeza va a golpes (%d cambios bruscos en 40 s)"):format(jerks))
check(pecks > 5, "picotea el suelo")
check(maxSettle > 0.5, "de vez en cuando se acomoda")
check(legIdle < 0.01, "quieta, las patas no se mueven")
local swing, steps = 0, 0
for i = 1, 90 do
	local poses, stepped = GiantHen.pose(st, 100 + i / 30, 1 / 30, 12, rnd)
	local lx = poses.PataL:ToEulerAnglesXYZ()
	swing = math.max(swing, math.abs(lx))
	if stepped then
		steps += 1
	end
end
check(swing > 0.3 and steps >= 4, ("corriendo mueve las patas y da pasos que se oyen (%d en 3 s)"):format(steps))

---------------------------------------------------------------------
print("\n▶ La misión «La gallina de seis metros» (Loco_N3_Pollo)")
local Locations = load("src/shared/LifeStory/Locations.luau")
local Cast = load("src/shared/LifeStory/Cast.luau")
local quests = load("src/shared/LifeStory/Misiones/Loco_Nino.luau")
local N3
for _, q in quests do
	if q.Id == "Loco_N3_Pollo" then
		N3 = q
	end
end
check(N3 ~= nil, "la misión existe")
check(Cast.People.PolloGigante.Body == "GallinaGigante", "Petra es una gallina (Cast: Body = GallinaGigante), no una persona vestida de blanco")
local steps = N3.Steps
local byType = {}
for i, s in steps do
	byType[s.Type] = byType[s.Type] or {}
	table.insert(byType[s.Type], i)
end
local transition = steps[byType.Transition[1]]
check(transition.Teleport == "GranjaPatio", "la furgoneta te deja en el patio, delante del portón del granero")
local function petraIn(step): any
	for _, a in step.Actors or {} do
		if a.Npc == "PolloGigante" then
			return a
		end
	end
	for _, a in step.Enemies or {} do
		if a.Npc == "PolloGigante" then
			return a
		end
	end
	return nil
end
local talkJulian = steps[byType.Transition[1] + 1]
local useEgg = steps[byType.Use[1]]
local escape = steps[byType.Escape[1]]
local fight = steps[byType.Fight[1]]
local p1, p2 = petraIn(talkJulian), petraIn(useEgg)
check(p1 and p1.Place == "GranjaComedero" and p1.Scale == 2.4 and p2 and p2.Place == "GranjaComedero", "Petra (6 m) se ve comiendo en el granero mientras hablas con Julián y entras a por el huevo")
check(table.find(talkJulian.Props or {}, "Huevos") ~= nil and table.find(escape.Props or {}, "Huevos") ~= nil, "los huevos gigantes están en el nido antes y durante la huida")
local egg = N3.Props[useEgg.Prop]
check(egg and egg.Kind == "HuevoGigante" and egg.Place == "GranjaNido" and egg.Brilla and type(egg.Prompt) == "string", "el huevo que hay que mirar está en el nido del granero, brilla y tiene su botón")
check(N3.Props.Huevos.Kind == "HuevoGigante" and N3.Props.Huevos.Prompt == false, "los demás huevos se ven pero no se tocan")
local hunter = petraIn(escape)
check(escape.Place == "GranjaSilo" and hunter and hunter.Mode == "Hunt" and hunter.Place == "GranjaComedero" and escape.Respawn == "GranjaPatio", "Petra sale del granero persiguiéndote hasta el silo (si te pilla, a la puerta del granero)")
local enemy = petraIn(fight)
check(enemy and enemy.Shrink and enemy.Scale * enemy.Shrink < 1.1 and enemy.Scale * enemy.Shrink > 0.5, "el rayo encogedor la va encogiendo disparo a disparo (de 2,4 a ~1)")
for i = 1, enemy.HP do
	local s = enemy.Scale * (1 - (1 - enemy.Shrink) * i / enemy.HP)
	if i == 1 then
		check(s < enemy.Scale and s > 1.8, ("primer disparo: «ha bajado un poco» (%.2f)"):format(s))
	end
end
-- Todos los sitios de la misión existen y llevan a la granja de Julián
local used = {}
for _, s in steps do
	for _, key in { "Place", "Teleport", "Respawn" } do
		if type(s[key]) == "string" then
			used[s[key]] = true
		end
	end
	for _, a in s.Actors or {} do
		if a.Place then
			used[a.Place] = true
		end
	end
end
for _, p in N3.Props do
	used[p.Place] = true
end
local farmPlaces = 0
for place in used do
	local def = Locations.Places[place]
	check(def ~= nil, place .. " existe")
	if def and def.Model == "Granja" then
		farmPlaces += 1
		check(def.Attribute and def.Attribute.Julian == true and def.Fallback ~= nil, place .. " es de la granja de Julián (y tiene plan B)")
	end
end
check(farmPlaces >= 4, "la misión pasa en la granja de Julián (patio, nido, comederos, silo)")
-- La visita a Petra de la saga: ya mide lo que una gallina
local saga = load("src/shared/LifeStory/Misiones/Saga_Acto4.luau")
for _, q in saga do
	if q.Id == "Saga_19_Recuerdos" then
		check(q.Props.Gallinero.Kind == "Gallina" and q.Props.Gallinero.Place == "GranjaNido", "años después (Saga 19), Petra es una gallina normal en su nido del granero")
	end
end

---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("\n▶ La granja de Julián en el mapa (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	assert(town, "el mapa no tiene la ciudad construida (Workspace.Town)")
	local farms, julian = 0, {}
	for _, d in town:GetDescendants() do
		if d:IsA("Model") and d.Name == "Granja" then
			farms += 1
			if d:GetAttribute("Julian") == true then
				table.insert(julian, d)
			end
		end
	end
	check(#julian == 1 and farms > 1, ("una sola granja de Julián entre las %d granjas"):format(farms))
	local farm = julian[1]
	local barn = farm and farm:FindFirstChild("Granero")
	check(barn and barn.PrimaryPart, "tiene su granero (con el suelo como pieza principal: delante = portón)")
	if barn and barn.PrimaryPart then
		local B = barn.PrimaryPart.CFrame * CFrame.new(0, -0.2, 0)
		local blo, bhi = bounds(partsOf(barn), B)
		check(bhi.Y - blo.Y >= 44 and bhi.X - blo.X >= 56 and bhi.Z - blo.Z >= 44, ("es GRANDE: %.0f × %.0f de planta y %.0f de alto"):format(bhi.X - blo.X, bhi.Z - blo.Z, bhi.Y - blo.Y))

		-- Todo lo que choca en la granja (para ver si algo tapa el paso)
		local solid = {}
		for _, p in partsOf(farm) do
			if p.CanCollide and p.Transparency < 1 and p.Name ~= "Suelo" and p.Name ~= "Patio" and p.Name ~= "Crop" then
				table.insert(solid, p)
			end
		end
		local function blockedAt(point): any
			for _, p in solid do
				local l = p.CFrame:PointToObjectSpace(point)
				local h = p.Size / 2
				if p:IsA("Part") and p.Shape == Enum.PartType.Ball then
					if l.Magnitude < h.X then
						return p
					end
				elseif math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z then
					return p
				end
			end
			return nil
		end
		-- ¿Está libre esta caja (en los ejes del granero)? Se mira cada 1,5 studs
		local function free(x0, x1, y0, y1, z0, z1, frame): (boolean, string?)
			frame = frame or B
			for x = x0, x1, 1.5 do
				for y = y0, y1, 1.5 do
					for z = z0, z1, 1.5 do
						local hit = blockedAt(frame * V(x, y, z))
						if hit then
							return false, hit.Name
						end
					end
				end
			end
			return true, nil
		end
		local ok, what = free(-11, 11, 1, 23, -32, -15)
		check(ok, "el portón está abierto y cabe Petra (22 de ancho y 23 de alto libres)" .. (if what then " — choca con " .. what else ""))
		ok, what = free(-11, 11, 1, 6, -48, -24)
		check(ok, "del patio al portón se llega andando" .. (if what then " — choca con " .. what else ""))
		ok, what = free(-20, 0, 1, 6, -14, 4)
		local ok2, what2 = free(-21, -7, 1, 21, -11, 1)
		ok, what = ok and ok2, what or what2
		check(ok, "dentro, nada tapa el paso hasta los comederos y Petra cabe de pie comiendo" .. (if what then " — choca con " .. what else ""))
		ok, what = free(4, 18, 1, 10, -14, 8)
		check(ok, "dentro, nada tapa el paso hasta el nido" .. (if what then " — choca con " .. what else ""))
		-- Lo que hay dentro
		local inside = {}
		for _, p in partsOf(barn) do
			inside[p.Name] = (inside[p.Name] or 0) + 1
		end
		check((inside.Paca or 0) >= 10 and (inside.Comedero or 0) >= 2 and (inside.Tirante or 0) >= 4 and inside.Pajar and inside.Escalera and (inside.Nido or 0) >= 8, "dentro: pacas, comederos, vigas, pajar con escalera y el nido de paja")
		check((inside.RayoDeLuz or 0) >= 3 and (inside.Farol or 0) >= 2, "luz que entra por las rendijas y faroles")
		local ladder = barn:FindFirstChild("Escalera", true)
		check(ladder and ladder:IsA("TrussPart"), "al pajar se sube trepando")
		local slits = 0
		for _, p in partsOf(barn) do
			if p.Name == "Pared" then
				slits += 1
			end
		end
		check(slits >= 20, "paredes de tablones con rendijas")
		-- Las marcas de la misión, en su sitio
		local function spot(name)
			return farm:FindFirstChild("StorySpot_" .. name, true)
		end
		local nido, comedero, patio = spot("Granja_Nido"), spot("Granja_Comedero"), spot("Granja_Patio")
		check(nido and comedero and patio, "marcas Granja_Nido, Granja_Comedero y Granja_Patio")
		if nido and comedero and patio then
			local ln = B:PointToObjectSpace(nido.CFrame.Position)
			local lc = B:PointToObjectSpace(comedero.CFrame.Position)
			local lp = B:PointToObjectSpace(patio.CFrame.Position)
			check(math.abs(ln.X) < 26 and math.abs(ln.Z) < 20 and math.abs(lc.X) < 26 and math.abs(lc.Z) < 20, "el nido y los comederos están DENTRO del granero")
			check(lp.Z < -30 and math.abs(lp.X) < 6, "el patio está delante del portón (desde ahí se ve a Petra dentro)")
			local look = B:VectorToObjectSpace(comedero.CFrame.LookVector)
			check(look.X < -0.9, "Petra come mirando a los comederos")
			-- Desde el nido, el huevo se alcanza (botón a 10 studs) desde un sitio libre
			check(blockedAt(nido.CFrame.Position) == nil and free(ln.X - 2, ln.X + 2, 1, 5, ln.Z - 10, ln.Z - 6), "delante del nido hay sitio para ponerse a mirar el huevo")
		end
		-- El silo y los sitios de la misión a su alrededor (Cosme, Petra, Julián), en el suelo libre
		local silo = farm:FindFirstChild("Silo")
		check(silo and silo:IsA("Model") and silo.PrimaryPart, "el silo (alto, con su escalerilla)")
		if silo and silo.PrimaryPart then
			local S = silo.PrimaryPart.CFrame
			for _, o in { { "Cosme", V(7, 0, -5) }, { "Petra", V(-12, 0, -8) }, { "Julián", V(-6, 0, -8) } } do
				local at = S * (o[2] + V(0, 2, 0))
				check(blockedAt(at) == nil and blockedAt(at + V(0, 2, 0)) == nil, o[1] .. " tiene sitio junto al silo")
			end
			-- Huida: del portón al silo, sin paredes en medio
			local from = B * V(0, 3, -26)
			local to = S * V(-6, 3, -8)
			local clear = true
			for i = 0, 40 do
				if blockedAt(from:Lerp(to, i / 40)) then
					clear = false
				end
			end
			check(clear and (to - from).Magnitude > 25, ("del granero al silo se corre en línea recta (%.0f studs)"):format((to - from).Magnitude))
		end
		local total = #partsOf(farm)
		check(total < 900, ("la granja entera tiene %d piezas (razonable en el móvil)"):format(total))
	end
end

print()
if failures > 0 then
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
