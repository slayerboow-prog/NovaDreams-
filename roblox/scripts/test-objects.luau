-- Prueba de los objetos que se mueven (Controllers/ObjectMotion) y de los juguetes con física
-- (shared/Toys + ToyService) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-objects.luau                           # solo las cuentas
--   lune run scripts/test-objects.luau RealLifeSimulator.rbxl    # y además, el mapa construido
--
-- Comprueba que:
--   * los árboles se mecen poco (más con tormenta), los columpios y las banderas no dan vueltas raras
--   * la noria y el carrusel giran sin saltos y la vagoneta va y vuelve por la vía
--   * la patada manda el balón hacia donde corres, más fuerte si vas rápido, y un poco hacia arriba
--   * un juguete perdido vuelve a su sitio, y uno con gente cerca no
--   * en el mapa, cada pieza marcada lleva su punto de giro y hay balones y conos repartidos

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Color3, Enum = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum

local fakeGame = { GetService = function(_, name)
	return { Name = name }
end }
local env = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum, game = fakeGame, workspace = {} }, { __index = getfenv(1) })
local ObjectMotion = luau.load(fs.readFile("src/client/Controllers/ObjectMotion.luau"), { debugName = "ObjectMotion", environment = env })()
local Toys = luau.load(fs.readFile("src/shared/Toys.luau"), { debugName = "Toys", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function angle(cf): number
	local _, a = cf:ToAxisAngle()
	return math.abs(a)
end

print("Viento, árboles, columpios y banderas")
check(ObjectMotion.windFor("Despejado") < ObjectMotion.windFor("Lluvia") and ObjectMotion.windFor("Lluvia") < ObjectMotion.windFor("Tormenta"), "más viento con lluvia y aún más con tormenta")
check(ObjectMotion.windFor(nil) == 1, "sin tiempo, brisa normal")
local maxCalm, maxStorm, maxLeaf, maxSwing, maxFlag = 0, 0, 0, 0, 0
local jumpy = false
local last = nil
for step = 0, 6000 do
	local t = step / 30
	maxCalm = math.max(maxCalm, angle(ObjectMotion.sway(t, 1.3, 1, false)))
	maxStorm = math.max(maxStorm, angle(ObjectMotion.sway(t, 1.3, 3, false)))
	maxLeaf = math.max(maxLeaf, angle(ObjectMotion.sway(t, 1.3, 1, true)))
	maxSwing = math.max(maxSwing, math.abs(ObjectMotion.swing(t, 0.4, 3)))
	local bend = 0
	for i = 1, 5 do
		bend += ObjectMotion.flag(t, 0.7, 3, i, 5)
	end
	maxFlag = math.max(maxFlag, math.abs(bend))
	local noria = ObjectMotion.noria(t)
	local car, bob = ObjectMotion.carousel(t, 0.2)
	if last then
		local dn = math.abs(noria - last[1])
		local dc = math.abs(car - last[2])
		if (dn > 0.01 and dn < 6) or (dc > 0.05 and dc < 6) or math.abs(bob - last[3]) > 0.1 then
			jumpy = true
		end
	end
	last = { noria, car, bob }
end
check(maxCalm < 0.06, ("con brisa, la copa se mece poco (%.3f rad)"):format(maxCalm))
check(maxStorm > maxCalm * 2 and maxStorm < 0.15, ("con tormenta, más, pero sin tumbarse (%.3f rad)"):format(maxStorm))
check(maxLeaf > maxCalm and maxLeaf < 0.15, "las hojas de palmera se agitan algo más")
check(maxSwing < 0.35, ("el columpio no da vueltas (%.2f rad como mucho)"):format(maxSwing))
check(maxFlag < math.rad(90), ("la bandera ondea sin doblarse del todo (%.0f°)"):format(math.deg(maxFlag)))
check(not jumpy, "la noria y el carrusel giran sin saltos")

print("Montaña rusa")
local ok, lastF = true, nil
local ends = { lo = false, hi = false }
for step = 0, 3000 do
	local f = ObjectMotion.coaster(step / 30, 300)
	if f < 0 or f > 1 then
		ok = false
	end
	if lastF and math.abs(f - lastF) > 0.01 then
		ok = false
	end
	if f < 0.01 then
		ends.lo = true
	end
	if f > 0.99 then
		ends.hi = true
	end
	lastF = f
end
check(ok, "la vagoneta avanza suave y sin salirse de la vía")
check(ends.lo and ends.hi, "va de un extremo al otro y vuelve")
check(ObjectMotion.coaster(5, 0) == 0, "sin vía no pasa nada")

print("Juguetes")
local ball = Toys.Kinds.Futbol
local run = Toys.kickVelocity(ball, Vector3.new(0, 1, -2), Vector3.new(0, 3, 0), Vector3.new(0, 0, -16))
check(run.Z < -10 and run.Y > 0, "corriendo hacia delante, el balón sale hacia delante y un poco arriba")
local walk = Toys.kickVelocity(ball, Vector3.new(0, 1, -2), Vector3.new(0, 3, 0), Vector3.new(0, 0, -6))
check(Vector3.new(run.X, 0, run.Z).Magnitude > Vector3.new(walk.X, 0, walk.Z).Magnitude, "cuanto más rápido vas, más fuerte")
local still = Toys.kickVelocity(ball, Vector3.new(2, 1, 0), Vector3.new(0, 3, 0), Vector3.zero)
check(still.X > 0, "quieto, lo empujas alejándolo de ti")
local beach = Toys.kickVelocity(Toys.Kinds.Playa, Vector3.new(0, 1, -2), Vector3.new(0, 3, 0), Vector3.new(0, 0, -16))
check(beach.Y > run.Y, "el balón de playa sube más")
local cone = Toys.kickVelocity(Toys.Kinds.Cono, Vector3.new(0, 1, -2), Vector3.new(0, 3, 0), Vector3.new(0, 0, -16))
check(cone.Magnitude < run.Magnitude, "un cono sale menos disparado que un balón")
local crazy = Toys.kickVelocity(ball, Vector3.new(0, 1, -2), Vector3.new(0, 3, 0), Vector3.new(0, 0, -900))
check(crazy.Magnitude < 60, "aunque vayas en coche, no sale a velocidades absurdas")
local home = Vector3.new(100, 5, 100)
check(Toys.shouldReset(Vector3.new(100, -80, 100), home, 5), "si se cae del mapa, vuelve a su sitio")
check(Toys.shouldReset(Vector3.new(130, 5, 100), home, 500), "lejos de su sitio y sin nadie cerca, vuelve")
check(not Toys.shouldReset(Vector3.new(130, 5, 100), home, 20), "si alguien está jugando con él, no")
check(not Toys.shouldReset(Vector3.new(101, 5, 100), home, 500), "en su sitio, se queda")
for name, kind in Toys.Kinds do
	check(kind.Density > 0 and kind.Elasticity >= 0 and kind.Elasticity <= 1 and kind.Friction >= 0 and kind.Friction <= 2, name .. ": física válida")
end

-- El mapa construido (opcional: tarda un poco)
local placePath = process.args[1]
if placePath and fs.isFile(placePath) then
	print("Mapa (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local counts, missing = {}, {}
	for _, d in game:GetService("Workspace"):GetDescendants() do
		for _, tag in d:GetTags() do
			counts[tag] = (counts[tag] or 0) + 1
			local needsPivot = tag == "Sway" or tag == "Swing" or tag == "Noria" or tag == "Carousel"
			if needsPivot and typeof(d:GetAttribute("Pivot")) ~= "Vector3" then
				missing[tag] = (missing[tag] or 0) + 1
			end
			if (tag == "Swing" or tag == "Noria") and typeof(d:GetAttribute("Axis")) ~= "Vector3" then
				missing[tag] = (missing[tag] or 0) + 1
			end
			if tag == "Toy" and not Toys.Kinds[d:GetAttribute("Toy") or ""] then
				missing[tag] = (missing[tag] or 0) + 1
			end
		end
	end
	for _, tag in { "Sway", "Swing", "Flag", "Noria", "Carousel", "CoasterTrack", "Fountain", "Toy" } do
		check((counts[tag] or 0) > 0 and (missing[tag] or 0) == 0, ("%s: %d piezas, todas con sus datos"):format(tag, counts[tag] or 0))
	end
	check((counts.CoasterTrack or 0) >= 10, "la montaña rusa tiene su vía entera")
	local workers = {}
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d.Name == "WorkerSpot" then
			local role = d:GetAttribute("Role")
			workers[role] = (workers[role] or 0) + 1
		end
	end
	local total = 0
	for _, n in workers do
		total += n
	end
	check(total <= 110, ("trabajadores en el mapa: %d (caben todos)"):format(total))
	for _, role in { "Jardinero", "Mecánico", "Granjero", "Músico" } do
		check((workers[role] or 0) > 0, role .. ": hay alguno en el mapa (" .. (workers[role] or 0) .. ")")
	end
	-- Mobiliario de la calle (vídeo de Valmar Centro: papeleras, cajas y tablas volando y cosas
	-- flotando en el aire). Lo que se puede tumbar (shared/Knock) sale con todo lo que lleva encima
	-- (compañeras + Knock.riders, como KnockService.register): nada se queda flotando. Y nada de la
	-- calle está suelto (sin anclar) al construir la ciudad: solo se suelta al darle (y vuelve).
	local Knock = luau.load(fs.readFile("src/shared/Knock.luau"), { debugName = "Knock", environment = env })()
	local ws = game:GetService("Workspace")
	local function ancestorsOf(instance)
		local list = {}
		local node = instance.Parent
		for _ = 1, 5 do
			if not node or node == ws then
				break
			end
			table.insert(list, node.Name)
			node = node.Parent
		end
		return list
	end
	local units, floating, loose = 0, {}, {}
	local town = ws:FindFirstChild("Town")
	for _, d in if town then town:GetDescendants() else {} do
		if d:IsA("BasePart") and not d.Anchored then
			local animal = d:FindFirstAncestor("Gallinero") ~= nil -- (las gallinas andan con física)
			if not animal then
				loose[d.Name] = (loose[d.Name] or 0) + 1
			end
		end
		if d:IsA("BasePart") and Knock.Catalog[d.Name] and d.Parent then
			local profile = Knock.profile(d.Name, "BasePart", ancestorsOf(d), d.Size)
			if profile then
				units += 1
				local with = { [d] = true }
				for _, other in d.Parent:GetChildren() do
					if other ~= d and other:IsA("BasePart") and profile.Companions and table.find(profile.Companions, other.Name) then
						local o, p = other.CFrame.Position, d.CFrame.Position
						if Vector3.new(o.X - p.X, 0, o.Z - p.Z).Magnitude <= (profile.Reach or 1.5) then
							with[other] = true
						end
					end
				end
				local siblings, infos = {}, {}
				for _, other in d.Parent:GetChildren() do
					if other:IsA("BasePart") and not with[other] then
						table.insert(siblings, other)
						table.insert(infos, { CFrame = other.CFrame, Size = other.Size, Name = other.Name, Anchored = other.Anchored })
					end
				end
				for _, i in Knock.riders({ CFrame = d.CFrame, Size = d.Size, Name = d.Name }, infos) do
					local name = siblings[i].Name
					floating[name] = (floating[name] or 0) + 1
				end
			end
		end
	end
	local looseList = {}
	for name, n in loose do
		table.insert(looseList, ("%s×%d"):format(name, n))
	end
	check(units > 500, ("objetos de la calle que se pueden tumbar: %d"):format(units))
	check(#looseList == 0, "nada de la ciudad está suelto (sin anclar) al construirla: " .. table.concat(looseList, ", "))
	-- Lo que iba encima sin ser compañera (se quedaba flotando): ahora lo recoge Knock.riders. Las
	-- conocidas (flores del cubo, franja de la valla) ya son compañeras: esta lista debería estar vacía
	local riding = {}
	for name, n in floating do
		table.insert(riding, ("%s×%d"):format(name, n))
	end
	check(#riding == 0, "lo que va encima de un objeto que se tumba es su compañera (Knock.Catalog): " .. table.concat(riding, ", "))
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
