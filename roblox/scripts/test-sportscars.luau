-- Prueba de los 13 VEHÍCULOS PREMIUM del pase (shared/PremiumVehicles + World/Kit/SportsCars) FUERA
-- de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-sportscars.luau
--
-- Construye cada vehículo con los módulos DE VERDAD (Builder, Rides, SportsCars, VehicleParts,
-- VehicleBuild, WheelRig) en instancias de Lune y comprueba:
--   * se construyen (con Rides.build y su estilo), con el atributo Premium y su modelo, dentro del
--     presupuesto de piezas (220 coche, 140 moto) y solo con primitivas;
--   * nombres reservados (Body, Headlight, HeadlightRight, Taillight, ThirdBrake, Reverse,
--     intermitentes, matrículas, ruedas, pata de cabra…) y el faro con foco mirando hacia delante;
--   * simetría (cada pieza tiene su gemela al otro lado, salvo las marcadas Asym: volante, cadena…);
--   * ruedas apoyadas en el suelo (y nada más lo toca), asientos dentro y por debajo del techo;
--   * Rides.prepare (base, asiento del conductor y de pasajeros), WheelRig (ruedas que giran y
--     dirección), taller (anclas, ruedas, zonas, pintura, llantas, lunas, neón, matrícula, clear);
--   * sin pagar para ganar: Velocidad / Manejo = las del coche y la moto de siempre, sin campos de
--     rendimiento; la Estética, mayor;
--   * sin «Nova» ni marcas reales en datos, textos, modelos ni documentación;
--   * el pase: los 13 están en la temporada 1 (uno gratis), el 50 premium sigue siendo legendario, el
--     catálogo los conoce y las vistas previas 3D salen con su modelo.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Color3, Enum, Instance = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Cargador: script.Parent.X y require() como en Roblox (por rutas de verdad)
---------------------------------------------------------------------
local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end
local fakeGame = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then
			return { Shared = node("src/shared") }
		end
		error("servicio no disponible en la prueba: " .. tostring(name))
	end,
}
local cache = {}
local function load(path: string): any
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return load(rawget(target, "__path"))
		end,
		game = fakeGame,
		Instance = Instance,
		CFrame = CFrame,
		Vector3 = Vector3,
		Color3 = Color3,
		Enum = Enum,
		UDim2 = roblox.UDim2,
		UDim = roblox.UDim,
		Font = roblox.Font,
	}, { __index = getfenv(1) })
	local file = path .. ".luau"
	local result = luau.load(fs.readFile(file), { debugName = file, environment = env })()
	cache[path] = result
	return result
end

local PremiumVehicles = load("src/shared/PremiumVehicles")
local SportsCars = load("src/server/World/Kit/SportsCars")
local Rides = load("src/server/World/Kit/Rides")
local VehicleParts = load("src/shared/VehicleParts")
local VehicleBuild = load("src/shared/VehicleBuild")
local WheelRig = load("src/shared/WheelRig")
local Gameplay = load("src/shared/Gameplay")
local BPConfig = load("src/shared/BattlePass/Config")
local Catalog = load("src/shared/BattlePass/Catalog")
local Season1 = load("src/shared/BattlePass/Season1")

local CF = CFrame.new(80, 3, -40) * CFrame.Angles(0, 0.6, 0) -- sitio girado: las cuentas no dependen del origen
local function localPos(part: any): any
	return CF:PointToObjectSpace(part.CFrame.Position)
end
local function lowest(part: any): number
	local s = part.Size / 2
	local low = math.huge
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local corner = CF:PointToObjectSpace((part.CFrame * CFrame.new(s.X * x, s.Y * y, s.Z * z)).Position)
				low = math.min(low, corner.Y)
			end
		end
	end
	return low
end
local function partsOf(model: any): { any }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end
local function named(model: any, name: string): { any }
	local out = {}
	for _, p in partsOf(model) do
		if p.Name == name then
			table.insert(out, p)
		end
	end
	return out
end

-- Palabras prohibidas: el logo de la hoja no es nuestro y nada de marcas reales
local FORBIDDEN = {
	"nova", "novalife", "chevrolet", "chevy", "camaro", "corvette", "nissan", "skyline", "toyota", "supra", "ford", "mustang",
	"dodge", "viper", "lancia", "stratos", "ferrari", "lamborghini", "porsche", "mclaren", "bugatti", "pagani", "koenigsegg",
	"aston", "bmw", "mercedes", "audi", "ducati", "yamaha", "kawasaki", "honda", "suzuki", "ktm", "aprilia", "triumph",
}
local function forbiddenIn(text: string): string?
	local lower = string.lower(text)
	for _, word in FORBIDDEN do
		if string.find(lower, "%f[%w]" .. word .. "%f[%W]") then
			return word
		end
	end
	return nil
end

---------------------------------------------------------------------
print("Ficha de los 13 vehículos")
---------------------------------------------------------------------
check(#PremiumVehicles.List == 13, "13 vehículos en la lista (" .. #PremiumVehicles.List .. ")")
local cars, motos, supers, sports = 0, 0, 0, 0
local seenNumbers = {}
for i, id in PremiumVehicles.List do
	local v = PremiumVehicles.get(id)
	check(v and v.Id == id and v.Number == i and not seenNumbers[i], id .. ": ficha con su número de la hoja (" .. i .. ")")
	seenNumbers[i] = true
	if v then
		if v.Kind == "Moto" then
			motos += 1
		else
			cars += 1
			if v.Class == "Superdeportivo" then
				supers += 1
			else
				sports += 1
			end
		end
		check(v.Premium == true, id .. ": Premium = true (sin pinchazos, menos consumo)")
		check(BPConfig.Rarities[v.Rarity] ~= nil and (v.Kind == "Coche" or v.Kind == "Moto"), id .. ": rareza y tipo válidos")
	end
end
check(cars == 10 and motos == 3 and supers == 5 and sports == 5, "5 deportivos, 5 superdeportivos y 3 motos")
local nameOf = {}
for _, id in PremiumVehicles.List do
	nameOf[id] = PremiumVehicles.get(id).Name
end
check(nameOf.StratoRS == "Strato RS" and nameOf.ViboraGT == "Víbora GT", "renombrados: «Strato RS» y «Víbora GT» (sin nombres de modelos reales)")
check(nameOf.VoltexGTR == "Voltex GT-R" and nameOf.KairoS == "Kairo S" and nameOf.RavenT7 == "Raven T7" and nameOf.Zenith == "Zenith"
	and nameOf.ShadowF1 == "Shadow F1" and nameOf.Inferno == "Inferno" and nameOf.AuroraX == "Aurora X" and nameOf.Obsidian == "Obsidian"
	and nameOf.NexusR == "Nexus R" and nameOf.Blaze1000 == "Blaze 1000" and nameOf.Storm == "Storm", "los demás nombres, como en la hoja")
local rarityOk = PremiumVehicles.get("VoltexGTR").Rarity == "Rara" and PremiumVehicles.get("StratoRS").Rarity == "Epica" and PremiumVehicles.get("KairoS").Rarity == "Rara"
	and PremiumVehicles.get("RavenT7").Rarity == "Epica" and PremiumVehicles.get("Zenith").Rarity == "Rara" and PremiumVehicles.get("ShadowF1").Rarity == "Legendaria"
	and PremiumVehicles.get("Inferno").Rarity == "Epica" and PremiumVehicles.get("AuroraX").Rarity == "Legendaria" and PremiumVehicles.get("Obsidian").Rarity == "Epica"
	and PremiumVehicles.get("ViboraGT").Rarity == "Legendaria" and PremiumVehicles.get("NexusR").Rarity == "Rara" and PremiumVehicles.get("Blaze1000").Rarity == "Epica"
	and PremiumVehicles.get("Storm").Rarity == "Legendaria"
check(rarityOk, "rarezas como en la hoja (raro / épico / legendario)")

---------------------------------------------------------------------
print("Sin pagar para ganar")
---------------------------------------------------------------------
local PERF = { "Speed", "Accel", "Brake", "Reverse", "Turn", "Lean", "Mass", "Weight", "Grip", "Power", "Tune", "TopSpeed", "Fuel" }
for kind, base in PremiumVehicles.BaseStats do
	local vehicle, driving = Gameplay.Vehicles[kind], Gameplay.Driving[kind]
	local speed = math.floor(vehicle.Speed / 80 * 5 + 0.5)
	local handling = math.floor(driving.Turn / 2.5 * 5 + 0.5)
	check(base.Velocidad == speed and base.Manejo == handling, kind .. ": barras de serie = las de Gameplay (Velocidad " .. speed .. ", Manejo " .. handling .. ")")
	-- el mejor vehículo de ese tipo que se gana jugando (no oculto) es el propio tipo
	local best = 0
	for _, v in Gameplay.Vehicles do
		if not v.Hidden and not v.Boat then
			best = math.max(best, v.Speed)
		end
	end
	check(kind ~= "Coche" or vehicle.Speed == best, kind .. ": es el más rápido de los que se compran con dinero del juego (" .. vehicle.Speed .. ")")
end
for _, id in PremiumVehicles.List do
	local v = PremiumVehicles.get(id)
	local base = PremiumVehicles.BaseStats[v.Kind]
	local clean = true
	for _, key in PERF do
		if v[key] ~= nil or (v.Stats and key ~= "Velocidad" and v.Stats[key] ~= nil) then
			clean = false
		end
	end
	check(clean and v.Stats.Velocidad == base.Velocidad and v.Stats.Manejo == base.Manejo and v.Stats.Estetica > base.Estetica and v.Stats.Estetica <= 5,
		("%s: corre y gira como un %s del juego (V %d · M %d); Estética %d"):format(id, string.lower(v.Kind), v.Stats.Velocidad, v.Stats.Manejo, v.Stats.Estetica))
	check(Gameplay.Driving[v.Kind] ~= nil and Gameplay.Vehicles[v.Kind] ~= nil and not Gameplay.Vehicles[id], id .. ": no es un tipo nuevo con sus propias prestaciones (usa las de «" .. v.Kind .. "»)")
end

---------------------------------------------------------------------
print("Construcción, piezas y detalles")
---------------------------------------------------------------------
local PRIMITIVE = { Part = true, WedgePart = true, CornerWedgePart = true }
local ASYM_OK = { Steering = true, SteeringHub = true, Gauges = true, Chain = true, Cog = true, BrakeDisc = true, Caliper = true, Kickstand = true }
local built = {}
-- (los dos faros se llaman distinto: Headlight a la izquierda y HeadlightRight a la derecha)
local function twinName(name: string): string
	return if name == "HeadlightRight" then "Headlight" else name
end
for _, id in PremiumVehicles.List do
	local v = PremiumVehicles.get(id)
	local kind = v.Kind
	local ok, model = pcall(Rides.build, kind, nil, CF, nil, { Model = id })
	check(ok and model and model:GetAttribute("PremiumModel") == id, id .. ": Rides.build con su modelo premium" .. (if ok then "" else " — " .. tostring(model)))
	if not ok then
		continue
	end
	built[id] = model
	check(model:GetAttribute("Premium") == true and model:GetAttribute("Variant") == id and model:GetAttribute("DisplayName") == v.Name, id .. ": atributos Premium, Variant y DisplayName")
	local parts = partsOf(model)
	local max = SportsCars.MaxParts[kind]
	local primitive = true
	for _, p in parts do
		if not PRIMITIVE[p.ClassName] then
			primitive = false
		end
	end
	check(#parts <= max and #parts >= (if kind == "Coche" then 150 else 90), ("%s: %d piezas (máx. %d) — con detalle y dentro del presupuesto"):format(id, #parts, max))
	check(primitive, id .. ": solo primitivas (bloques, cuñas y cilindros; sin MeshPart ni uniones)")
	-- Nombres reservados
	local function has(name: string, n: number?): boolean
		return #named(model, name) >= (n or 1)
	end
	local heads = named(model, "Headlight")
	check(#heads == 1 and has("HeadlightRight") and has("Taillight") and has("Body") and #named(model, "Body") == 1, id .. ": Body, Headlight (uno), HeadlightRight y Taillight")
	if #heads == 1 then
		local look = CF:VectorToObjectSpace(heads[1].CFrame.LookVector)
		check(look.Z < -0.99, id .. ": el faro principal (el del foco) mira hacia delante")
	end
	if kind == "Coche" then
		check(#named(model, "Wheel") == 4 and has("ThirdBrake") and has("Reverse", 2) and #named(model, "IndicatorFront") == 2 and #named(model, "IndicatorRear") == 2
			and #named(model, "PlateFront") == 1 and #named(model, "PlateRear") == 1, id .. ": 4 ruedas, freno central, marcha atrás, 4 intermitentes y 2 matrículas")
		check(has("DRL", 2) and has("Splitter") and has("Diffuser") and has("DiffuserFin", 4) and has("Exhaust") and has("SideSkirt", 2) and has("Mirror", 2) and has("MirrorGlass", 2),
			id .. ": luz diurna, splitter, difusor con aletas, escapes, taloneras y retrovisores")
		check(has("Windshield") and has("SideWindow", 2) and has("SideWindowFront", 2) and (has("RearWindow") or has("EngineCover")) and has("PillarA", 2),
			id .. ": parabrisas, ventanillas, luneta o tapa del motor y montantes")
		check(has("SeatCushion", 2) and has("SeatBack", 2) and has("Steering") and has("Dash") and has("DashGlow") and has("Screen") and has("Gauges"),
			id .. ": interior (asientos baquet, volante, salpicadero con brillo y pantallas)")
		check(has("Caliper", 4) and has("BrakeDisc", 4) and has("Spoke", 12) and has("Rim", 4) and has("Hub", 4), id .. ": llantas de radios con disco y pinza de color")
		if v.Underglow then
			check(has("Underglow"), id .. ": neón bajo el coche")
		end
		if v.GlowLines then
			check(has("GlowLine", 4), id .. ": líneas de luz")
		end
		if v.Stripes then
			check(has("Livery", 4), id .. ": franjas")
		end
		if v.Wing == "GT" or v.Wing == "Swan" then
			check(has("Wing") and has("WingEndplate", 2) and has("WingStrut", 2), id .. ": alerón con soportes y derivas")
		end
	else
		check(#named(model, "Wheel") == 2 and #named(model, "Indicator") == 4 and has("Plate") and has("Kickstand") and has("Fork", 4) and has("Swingarm", 2)
			and has("Engine") and has("Exhaust") and has("Seat") and has("Dash"), id .. ": 2 ruedas, 4 intermitentes, matrícula, pata, horquilla, basculante, motor, escape, asiento y cuadro")
		local stand = named(model, "Kickstand")[1]
		check(stand and typeof(stand:GetAttribute("StandA")) == "Vector3" and typeof(stand:GetAttribute("StandFolded")) == "Vector3", id .. ": la pata de cabra se puede recoger (StandA / StandB / StandFolded)")
		if v.Style == "Sport" then
			check(has("Windscreen") and has("Shield", 5), id .. ": deportiva carenada con cúpula")
		else
			check(has("HeadlightHousing") and has("Frame", 6) and not has("FairingVent"), id .. ": naked con chasis a la vista y faro desnudo")
		end
	end
	-- Simetría
	local unmatched, badAsym = {}, {}
	for _, p in parts do
		local pos = localPos(p)
		if p:GetAttribute("Asym") then
			if not ASYM_OK[p.Name] then
				table.insert(badAsym, p.Name)
			end
			continue
		end
		if math.abs(pos.X) < 0.05 then
			continue
		end
		local found = false
		for _, q in parts do
			if q ~= p and twinName(q.Name) == twinName(p.Name) and q.ClassName == p.ClassName and (q.Size - p.Size).Magnitude < 0.01 then
				local qp = localPos(q)
				if math.abs(qp.X + pos.X) < 0.02 and math.abs(qp.Y - pos.Y) < 0.02 and math.abs(qp.Z - pos.Z) < 0.02 then
					found = true
					break
				end
			end
		end
		if not found then
			table.insert(unmatched, p.Name)
		end
	end
	check(#unmatched == 0, id .. ": simétrico" .. (if #unmatched > 0 then " — sin gemela: " .. table.concat(unmatched, ", ") else ""))
	check(#badAsym == 0, id .. ": solo son asimétricos el volante y la transmisión" .. (if #badAsym > 0 then " — " .. table.concat(badAsym, ", ") else ""))
	-- Ruedas en el suelo y nada más lo toca
	local geometry = v.Geometry
	local wheelsOk, groundOk, lowParts = true, true, {}
	for _, p in parts do
		local low = lowest(p)
		if p.Name == "Wheel" then
			local pos = localPos(p)
			wheelsOk = wheelsOk and math.abs(pos.Y - geometry.Wheels.Radius) < 0.02 and math.abs(low) < 0.02
		elseif p.Name ~= "Kickstand" and not WheelRig.SpinNames[p.Name] and p.Name ~= "Caliper" then
			if low < 0.25 then
				groundOk = false
				table.insert(lowParts, p.Name)
			end
		end
		if low < -0.02 then
			groundOk = false
			table.insert(lowParts, p.Name .. "(bajo el suelo)")
		end
	end
	check(wheelsOk, id .. ": las ruedas tocan el suelo (radio " .. geometry.Wheels.Radius .. ")")
	check(groundOk, id .. ": nada más toca el suelo (ni lo atraviesa)" .. (if #lowParts > 0 then " — " .. table.concat(lowParts, ", ") else ""))
	-- Cabe en la caja de su tipo (salvo retrovisores, alerón y escapes, que sobresalen poco)
	local size = Rides.Spec[kind].Size
	local inside = true
	for _, p in parts do
		local pos = localPos(p)
		if math.abs(pos.X) > size.X / 2 + 0.5 or math.abs(pos.Z) > size.Z / 2 + 0.4 then
			inside = false
		end
	end
	check(inside, id .. ": cabe en la caja de un «" .. kind .. "» (" .. size.X .. " × " .. size.Z .. ")")
	-- Texto sin marcas ni «Nova»
	local texts = {}
	for _, d in model:GetDescendants() do
		table.insert(texts, d.Name)
		if d:IsA("TextLabel") then
			table.insert(texts, d.Text)
		end
	end
	local bad = forbiddenIn(table.concat(texts, " "))
	check(bad == nil, id .. ": sin «Nova» ni marcas reales en el modelo" .. (if bad then " — " .. bad else ""))
end

---------------------------------------------------------------------
print("Asientos, conducción y ruedas que giran")
---------------------------------------------------------------------
for _, id in PremiumVehicles.List do
	local v = PremiumVehicles.get(id)
	local kind = v.Kind
	local model = Rides.build(kind, nil, CF, nil, { Model = id })
	local chassis, seat = Rides.prepare(model, kind, CF)
	local d = v.SeatLayout.Driver
	local seatPos = CF:PointToObjectSpace(seat.CFrame.Position)
	check(chassis.Name == "Chassis" and model.PrimaryPart == chassis and (seatPos - Vector3.new(d[1], d[2] - 0.1, d[3])).Magnitude < 0.01, id .. ": base y asiento del conductor en su sitio")
	local riders = 0
	local size = Rides.Spec[kind].Size
	local seatsInside = math.abs(seatPos.X) < size.X / 2 and math.abs(seatPos.Z) < size.Z / 2
	for _, child in model:GetChildren() do
		if child.Name == "RideSeat" then
			riders += 1
			local p = CF:PointToObjectSpace(child.CFrame.Position)
			seatsInside = seatsInside and math.abs(p.X) < size.X / 2 and math.abs(p.Z) < size.Z / 2 and (child:GetAttribute("Side") == 1 or child:GetAttribute("Side") == -1)
		end
	end
	local expected = if kind == "Moto" then 1 else (v.Seats or 2) - 1
	check(riders == expected and #Rides.passengerSeats(kind, id) == expected, ("%s: %d asiento(s) de pasajero (%d plazas en total)"):format(id, riders, riders + 1))
	check(seatsInside, id .. ": los asientos caben dentro y se bajan por un lado")
	if kind == "Coche" then
		local cab = v.Geometry.Cabin
		local roomy = true
		for _, p in { d, table.unpack(v.SeatLayout.Passengers) } do
			-- cabeza (sentado ~3,2 studs por encima del cojín) por debajo del techo o de la luneta
			local z = p[3]
			local ceiling = if z <= cab.RoofBack then cab.Roof - 0.14 else cab.Roof - 0.14 - (z - cab.RoofBack) * (cab.Roof - cab.BackY) / (cab.Back - cab.RoofBack)
			roomy = roomy and p[2] + 3.2 <= ceiling + 0.05 and z > cab.Base + 1.2 and z < v.Geometry.CabBack
		end
		check(roomy, id .. ": cabezas por debajo del techo y asientos dentro del habitáculo")
	end
	for _, p in partsOf(model) do
		if p ~= chassis and p.Anchored then
			check(false, id .. ": " .. p.Name .. " sigue anclada tras Rides.prepare")
			break
		end
	end
	-- WheelRig: ruedas que giran, dirección y pinzas que giran con el volante (no ruedan)
	local infos, list = {}, {}
	for _, p in partsOf(model) do
		table.insert(list, p)
		table.insert(infos, { Name = p.Name, CFrame = CF:ToObjectSpace(p.CFrame), Size = p.Size })
	end
	local rig = WheelRig.find(infos, kind)
	local wheelsN = if kind == "Moto" then 2 else 4
	local spun, steeredCalipers, spunCalipers = 0, 0, 0
	for _, w in rig.Wheels do
		spun += #w.Spin
		for _, i in w.Steer do
			if list[i].Name == "Caliper" then
				steeredCalipers += 1
			end
		end
		for _, i in w.Spin do
			if list[i].Name == "Caliper" then
				spunCalipers += 1
			end
		end
	end
	check(#rig.Wheels == wheelsN and rig.Steers and spun >= wheelsN * 6, ("%s: WheelRig ve %d ruedas que giran (%d piezas) y la dirección"):format(id, #rig.Wheels, spun))
	check(spunCalipers == 0 and steeredCalipers >= (if kind == "Moto" then 2 else 2), id .. ": las pinzas no ruedan; las de delante giran con el volante")
end

---------------------------------------------------------------------
print("Taller: anclas, ruedas, zonas, pintura, llantas, lunas, neón y matrícula")
---------------------------------------------------------------------
local function snapshot(model: any): { string }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, d.Name .. "|" .. tostring(d.Color) .. "|" .. d.Material.Name .. "|" .. string.format("%.3f|%.3f", d.Transparency, d.Reflectance) .. "|" .. tostring(d.CFrame))
		elseif d:IsA("TextLabel") then
			table.insert(out, "Text|" .. d.Text)
		end
	end
	table.sort(out)
	return out
end
for _, id in PremiumVehicles.List do
	local v = PremiumVehicles.get(id)
	local kind = v.Kind
	local model = built[id]
	if not model then
		continue
	end
	-- Anclas de las ruedas y de la matrícula = el modelo
	local anchors = VehicleParts.anchorsFor(kind, id)
	local info = VehicleParts.wheelsFor(kind, id)
	local wheels = named(model, "Wheel")
	local matched = anchors ~= nil
	local count = 0
	for key, a in anchors or {} do
		if string.sub(key, 1, 5) == "Wheel" then
			count += 1
			local found = false
			for _, w in wheels do
				if (localPos(w) - Vector3.new(a[1], a[2], a[3])).Magnitude < 0.05 and math.abs(w.Size.Y - info.Radius * 2) < 0.02 and math.abs(w.Size.X - info.Width) < 0.02 then
					found = true
				end
			end
			matched = matched and found
		end
	end
	check(matched and count == #wheels, id .. ": anclas de las ruedas = el modelo (radio y ancho incluidos)")
	local rim = named(model, "Rim")[1]
	check(rim and math.abs(rim.Size.Y - info.RimDiameter) < 0.02, id .. ": diámetro de la llanta de serie (perfil bajo)")
	local plateName = if kind == "Coche" then "PlateRear" else "Plate"
	local plate = named(model, plateName)[1]
	check(plate and (localPos(plate) - Vector3.new(anchors.PlateRear[1], anchors.PlateRear[2], anchors.PlateRear[3])).Magnitude < 0.05, id .. ": ancla de la matrícula = " .. plateName)
	local ref = VehicleParts.referenceFor(kind, id)
	local refPart = model:FindFirstChild(ref.Name)
	local origin = refPart and refPart.CFrame * CFrame.new(-ref.Offset[1], -ref.Offset[2], -ref.Offset[3])
	check(origin and (origin.Position - CF.Position).Magnitude < 0.01, id .. ": la pieza de referencia da el sitio de construcción")
	-- Una build completa: pintura, acabado, secundaria, llantas, color, neumáticos, lunas, neón, matrícula
	local before = snapshot(model)
	local build = VehicleBuild.default()
	build.Paint = "P_VerdeMenta"
	build.Finish = "F_Perlado"
	build.Paint2 = "P_OroViejo"
	build.Rims = "Rims_Clasica5"
	build.RimColor = "RC_Bronce"
	build.Tires = if kind == "Coche" then "T_LetrasBlancas" else ""
	build.Tint = if kind == "Coche" then 2 else 0
	build.Neon = "N_Cian"
	build.Plate = "VALMAR 1"
	local n, warnings = VehicleBuild.apply(model, build, { Kind = kind })
	check(#warnings == 0 and n > 0 and n <= VehicleParts.Budget[kind], ("%s: el taller se aplica sin avisos (%d piezas nuevas)%s"):format(id, n, if #warnings > 0 then " — " .. table.concat(warnings, "; ") else ""))
	local body = model:FindFirstChild("Body")
	local mint = Color3.fromRGB(150, 220, 180)
	local painted = body and (body.Color.G > 0.8 and body.Color.R > 0.6)
	local panelsPainted = true
	for _, p in named(model, if kind == "Coche" then "Panel" else "Shield") do
		panelsPainted = panelsPainted and math.abs(p.Color.G - body.Color.G) < 0.01
	end
	check(painted and panelsPainted, id .. ": la pintura cubre toda la carrocería (Body y paneles)")
	local hiddenRims = true
	for _, name in { "Rim", "Spoke", "BrakeDisc", "Caliper", "RimInner" } do
		for _, p in named(model, name) do
			hiddenRims = hiddenRims and p.Transparency >= 1
		end
	end
	local modRims = 0
	for _, p in partsOf(model) do
		if string.sub(p.Name, 1, 7) == "Mod_Rim" then
			modRims += 1
		end
	end
	check(hiddenRims and modRims >= #wheels * 3, id .. ": llantas del taller en su sitio (las de serie, el disco y la pinza se esconden)")
	if kind == "Coche" then
		local tinted = true
		for _, p in named(model, "SideWindow") do
			tinted = tinted and p.Transparency < 0.3
		end
		local wind = model:FindFirstChild("Windshield")
		check(tinted and wind and wind.Transparency > 0.3, id .. ": lunas tintadas (el parabrisas no)")
	end
	check(model:GetAttribute("NeonColor") ~= nil, id .. ": neón bajo el vehículo")
	local plateText = false
	for _, d in model:GetDescendants() do
		if d:IsA("TextLabel") and d.Text == "VALMAR 1" then
			plateText = true
		end
	end
	check(plateText, id .. ": matrícula personalizada")
	local mod = 0
	local outside = false
	for _, p in partsOf(model) do
		if string.sub(p.Name, 1, 4) == "Mod_" then
			mod += 1
			outside = outside or p.CanCollide
		end
	end
	check(not outside, id .. ": las piezas del taller no chocan")
	VehicleBuild.clear(model)
	local after = snapshot(model)
	local same = #before == #after
	for i = 1, math.min(#before, #after) do
		same = same and before[i] == after[i]
	end
	check(same, id .. ": clear() lo deja exactamente como de serie")
	-- Las piezas del taller que no van con un premium (alerones, parachoques, otra carrocería)
	if kind == "Coche" then
		local spoiler = VehicleParts.get("Sp_GT")
		local bumper = VehicleParts.get("BF_Deportivo")
		check(not VehicleParts.fits(spoiler, kind, id) and not VehicleParts.fits(bumper, kind, id) and VehicleParts.fits(VehicleParts.get("Rims_Faro"), kind, id),
			id .. ": alerón y parachoques del taller no (ya trae los suyos); llantas sí")
	end
	local _ = mint
end

---------------------------------------------------------------------
print("Pase de temporada")
---------------------------------------------------------------------
local inPass, onFree, levels = {}, 0, {}
local function visit(def: any, level: number?, track: string?)
	if type(def) ~= "table" then
		return
	end
	if def.Type == "VehicleSkin" and type(def.Model) == "string" then
		local v = PremiumVehicles.get(def.Model)
		check(v ~= nil and def.Kind == v.Kind and typeof(def.Color) == "Color3" and def.GrantsBase == true and def.Premium == true and def.Rarity == v.Rarity,
			("%s: recompensa del pase bien hecha (%s, %s, %s)"):format(def.Id, def.Model, def.Kind, def.Rarity))
		check(type(def.Stats) == "table" and def.Stats.Velocidad == v.Stats.Velocidad and def.Stats.Estetica == v.Stats.Estetica, def.Id .. ": barras Velocidad / Manejo / Estética para la interfaz")
		check(Catalog.get(def.Id) ~= nil and Catalog.get(def.Id).Model == def.Model, def.Id .. ": el catálogo lo conoce")
		inPass[def.Model] = (inPass[def.Model] or 0) + 1
		if track == "Free" then
			onFree += 1
		end
		if level then
			levels[def.Model] = level
		end
	end
	for _, item in def.Items or {} do
		visit(item, level, track)
	end
end
for _, reward in Season1.Rewards do
	visit(reward, reward.Level, reward.Track)
end
local all = true
for _, id in PremiumVehicles.List do
	all = all and inPass[id] == 1
end
check(all, "los 13 vehículos están en la temporada 1 (una vez cada uno)")
check(onFree == 1, "uno en la pista gratis (" .. onFree .. ")")
local fifty = nil
for _, r in Season1.Rewards do
	if r.Level == 50 and r.Track == "Premium" then
		fifty = r
	end
end
check(fifty and fifty.Rarity == "Legendaria" and fifty.Name == "Faro de Valmar" and levels.AuroraX == 50, "el 50 premium sigue siendo el conjunto legendario «Faro de Valmar» (con el Aurora X)")
local car50 = Catalog.get("S1_P50_Car")
check(car50 and car50.Model == "AuroraX" and car50.Parent == "S1_P50" and typeof(car50.Trim) == "Color3", "S1_P50_Car = Aurora X «Faro de Valmar» con detalles en oro (mismo Id de siempre)")
local order = { Rara = 1, Epica = 2, Legendaria = 3 }
local sorted = true
local lastByRarity = {}
for id, level in levels do
	local rarity = PremiumVehicles.get(id).Rarity
	lastByRarity[rarity] = math.max(lastByRarity[rarity] or 0, level)
end
for id, level in levels do
	local rarity = PremiumVehicles.get(id).Rarity
	for other, last in lastByRarity do
		if order[other] < order[rarity] and level < (last - 20) then
			sorted = false
		end
	end
end
check(sorted and levels.VoltexGTR < levels.ShadowF1 and levels.NexusR < levels.Storm, "rarezas repartidas: los raros pronto, los legendarios al final")
local enabledLine = string.match(fs.readFile("src/shared/BattlePass/Config.luau"), "Config%.Enabled%s*=%s*(%a+)") or string.match(fs.readFile("src/shared/BattlePass/Config.luau"), "Enabled%s*=%s*(%a+)")
check(enabledLine ~= nil and tostring(BPConfig.Enabled) == enabledLine, "BattlePassConfig.Enabled sin tocar (" .. tostring(enabledLine) .. ")")
-- Vistas previas 3D: el servidor las monta con Rides.build y el modelo del pase
local serviceSource = fs.readFile("src/server/Services/BattlePassService.luau")
check(string.find(serviceSource, "Model = def.Model", 1, true) ~= nil, "BattlePassService monta las vistas previas con el modelo premium")
local previews = 0
for _, def in Catalog.all() do
	if def.Type == "VehicleSkin" and type(def.Model) == "string" then
		local model = Rides.build(def.Kind, nil, CFrame.new(), def.Color, { Model = def.Model, Accent = if typeof(def.Trim) == "Color3" then def.Trim else nil })
		if model:GetAttribute("PremiumModel") == def.Model and #partsOf(model) > 50 then
			previews += 1
		end
	end
end
check(previews == 13, "las 13 vistas previas 3D salen con su modelo (" .. previews .. ")")
local faro = Rides.build("Coche", nil, CF, car50.Color, { Model = "AuroraX", Accent = car50.Trim })
local gold = 0
for _, p in named(faro, "Caliper") do
	if p.Color.R > 0.9 and p.Color.G > 0.65 and p.Color.B < 0.4 then
		gold += 1
	end
end
check(gold == 4 and faro:FindFirstChild("Body").Color == car50.Color, "Aurora X «Faro de Valmar»: blanco perla con pinzas doradas")
-- Modo pruebas («🏎️ Vehículos del pase»): los 14 que se sacan desde el panel (Catalog.vehicles) salen
-- igual que VehicleService.mount los monta (Rides.build con su pintura y su modelo, y Rides.prepare)
local passList = Catalog.vehicles()
local passOk = 0
for _, entry in passList do
	local ok, model = pcall(Rides.build, entry.Kind, nil, CF, entry.Color, { Model = entry.Model, Accent = entry.Trim })
	local prepared = ok and pcall(Rides.prepare, model, entry.Kind, CF)
	local wheels = if ok then #named(model, "Wheel") else 0
	if ok and prepared and model:GetAttribute("Premium") == true and model:GetAttribute("PremiumModel") == entry.Model
		and #named(model, "Headlight") == 1 and #named(model, "Taillight") >= 1 and wheels >= (if entry.Kind == "Coche" then 4 else 2)
		and model:FindFirstChild("Body").Color == entry.Color then
		passOk += 1
	else
		print("    (" .. tostring(entry.Id) .. " no sale bien)")
	end
end
check(#passList == 14 and passOk == 14, ("modo pruebas: los 14 vehículos del pase salen con su modelo, Premium, faros, pilotos, ruedas y su pintura (%d de %d)"):format(passOk, #passList))

---------------------------------------------------------------------
print("Sin «Nova» ni marcas reales")
---------------------------------------------------------------------
for _, path in {
	"src/shared/PremiumVehicles.luau",
	"src/server/World/Kit/SportsCars.luau",
	"src/shared/BattlePass/Season1.luau",
	"docs/pase-de-temporada.md",
} do
	local bad = forbiddenIn(fs.readFile(path))
	check(bad == nil, path .. ": limpio" .. (if bad then " — aparece «" .. bad .. "»" else ""))
end
local texts = {}
for _, reward in Season1.Rewards do
	table.insert(texts, (reward.Name or "") .. " " .. (reward.Description or ""))
	for _, item in reward.Items or {} do
		table.insert(texts, (item.Name or "") .. " " .. (item.Description or ""))
	end
end
local bad = forbiddenIn(table.concat(texts, " "))
check(bad == nil, "textos del pase limpios" .. (if bad then " — " .. bad else ""))

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
