-- muebles-asientos: en el servidor de verdad, lo del mapa que se cambió para la v103
--   1. Muebles sólidos: las salas amuebladas con los assets de verdad (InteriorProps.prepare con
--      AssetLoader) llevan su caja invisible «Choque» en lo grande de pie, y lo hecho con código que
--      antes se atravesaba (burro de ropa, mesas altas del pub…) choca. La cocina de Cosme choca.
--   2. Frutería: cada caja (ProduceCrate) tiene su producto (shared/Groceries), su forma, su cartel
--      de precio y, con ShopService.setupProduce, su cartel «Comprar».
--      Amueblar no pide a GetPartBoundsInBox cajas de talla negativa (avisos en la consola).
--   3. Asientos: con InteractService arrancado, ningún Seat del mapa te sienta al rozarlo (CanTouch
--      apagado) y los que nadie más usa llevan el cartel «Sentarse»; uno nuevo también.
--
-- Uso: bash scripts/cloud-test.sh --version 103 muebles-asientos

local Cloud = Cloud :: any

local World = Cloud.Server:WaitForChild("World")
local Services = Cloud.Server:WaitForChild("Services")

Cloud.escuchar()
for _, p in Cloud.prepararMundo() do
	if not p.ok then
		Cloud.check("Preparar el mundo: " .. p.name, false, p.err)
	end
end
local malos = {}
for _, s in Cloud.arrancarServicios() do
	if not s.ok then
		table.insert(malos, s.name .. ": " .. tostring(s.err))
	end
end
Cloud.check("Servicios arrancados", #malos == 0, if #malos == 0 then "todos bien" else Cloud.lista(malos, 5))

local Interiors = require(World.Interiors) :: any
local InteriorProps = require(World.InteriorProps) :: any
local rooms = Instance.new("Folder")
rooms.Name = "PruebaSalas"
rooms.Parent = workspace
local slot = 0
local function build(kind: string, shop: string?, seed: string): Instance
	slot += 1
	local r = Interiors[kind](rooms, CFrame.new(slot * 300, 6000, 0), { Seed = seed, Shop = shop })
	r.Model:SetAttribute("Key", seed)
	return r.Model
end

---------------------------------------------------------------------
-- 1. Muebles sólidos
---------------------------------------------------------------------
local okLib, library = pcall(function()
	return InteriorProps.prepare(require(World.AssetLoader).download, require(World.MeshLibrary).stripScripts)
end)
if not okLib or type(library) ~= "table" then
	Cloud.check("Muebles: assets de las salas", false, tostring(library))
else
	local kinds = 0
	for _ in library do
		kinds += 1
	end
	local muebles, conCaja, sinChoque = 0, 0, {}
	local negativas = 0
	for k = 1, 6 do
		local room = build(({ "Casa", "Villa", "Piso" })[(k - 1) % 3 + 1], nil, "nube" .. k)
		pcall(InteriorProps.dressRoom, room, library, function(cf, size, within)
			if size.X < 0 or size.Y < 0 or size.Z < 0 or size.X > 30000 or size.Y > 30000 or size.Z > 30000 then
				negativas += 1
			end
			local params = OverlapParams.new()
			if within then
				params.FilterType = Enum.RaycastFilterType.Include
				params.FilterDescendantsInstances = { within }
			end
			return workspace:GetPartBoundsInBox(cf, size, params)
		end)
		local folder = room:FindFirstChild(InteriorProps.Folder)
		for _, m in (if folder then folder:GetChildren() else {}) do
			if not m:IsA("Model") then
				continue
			end
			-- (las puertas se atraviesan a propósito)
			local _, size = m:GetBoundingBox()
			if m.Name == "PuertaMadera" or size.Y < 2 or math.max(size.X, size.Z) < 1.5 then
				continue -- (lo pequeño no choca a propósito)
			end
			muebles += 1
			local box = m:FindFirstChild(InteriorProps.HitboxName)
			local choca = box and box:IsA("BasePart") and box.CanCollide and box.Transparency == 1
			if choca then
				conCaja += 1
			else
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") and d.CanCollide then
						choca = true
						break
					end
				end
			end
			if not choca then
				table.insert(sinChoque, room.Name .. "/" .. m.Name)
			end
		end
	end
	Cloud.check("Amueblar: ninguna caja con talla fuera de rango", negativas == 0, ("%d (GetPartBoundsInBox avisa en la consola)"):format(negativas))
	Cloud.check("Muebles de pie en 6 casas: sólidos", muebles > 0 and #sinChoque == 0,
		("%d tipos de asset, %d muebles grandes, %d con caja «Choque»%s"):format(kinds, muebles, conCaja,
			if #sinChoque > 0 then "; se atraviesan: " .. Cloud.lista(sinChoque, 6) else ""))
end

-- Muebles hechos con código que antes se atravesaban
do
	local function solidos(room: Instance, names: { string }): (number, { string })
		local n, mal = 0, {}
		for _, name in names do
			local found = false
			for _, d in room:GetDescendants() do
				if d.Name == name and d:IsA("BasePart") then
					found = true
					if d.CanCollide then
						n += 1
					else
						table.insert(mal, name)
					end
				end
			end
			if not found then
				table.insert(mal, name .. " (no está)")
			end
		end
		return n, mal
	end
	local n1, mal1 = solidos(build("Local", "MODA URBANA", "nubeModa"), { "Choque" })
	local n2, mal2 = solidos(build("Ocio", nil, "nubeOcio"), { "HighTop", "HighLeg" })
	local mal = table.clone(mal1)
	table.move(mal2, 1, #mal2, #mal + 1, mal)
	Cloud.check("Burro de ropa y mesas altas del pub: chocan", #mal == 0,
		("%d piezas sólidas%s"):format(n1 + n2, if #mal > 0 then "; no: " .. Cloud.lista(mal, 6) else ""))
end

-- La cocina de Cosme (en el mapa publicado)
do
	local house = workspace:FindFirstChild("CasaCosme", true)
	if not house then
		Cloud.salta("Cocina de Cosme: choca", "no está CasaCosme en el mapa")
	else
		local mal = {}
		for _, name in { "ImpresoraComida", "NeveraPantalla", "CafeteraModificada", "MicroondasTemporal", "MesaCocina" } do
			local m = house:FindFirstChild(name, true)
			local any = false
			for _, d in (if m then m:GetDescendants() else {}) do
				if d:IsA("BasePart") and d.CanCollide then
					any = true
					break
				end
			end
			if not any then
				table.insert(mal, name)
			end
		end
		Cloud.check("Cocina de Cosme: choca", #mal == 0, if #mal == 0 then "impresora, nevera, cafetera, microondas y mesa" else "no chocan: " .. Cloud.lista(mal))
	end
end

---------------------------------------------------------------------
-- 2. Frutería
---------------------------------------------------------------------
do
	local fruteria = build("Local", "FRUTERIA LA HUERTA", "nubeFruteria")
	local okShop, err = pcall(function()
		require(Services.ShopService).setupProduce({ Room = { Model = fruteria } })
	end)
	local crates, productos, conForma, conPrecio, conPrompt = 0, {}, 0, 0, 0
	local nombres = {}
	for _, d in fruteria:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("ProduceCrate") then
			crates += 1
			local id = d:GetAttribute("Product")
			if id and not productos[id] then
				productos[id] = true
				table.insert(nombres, id)
			end
			local g = d.Parent
			local fruta = g and g:FindFirstChild("Fruta")
			if fruta and #fruta:GetDescendants() > 0 then
				conForma += 1
			end
			local card = g and g:FindFirstChild("Precio")
			if card and card:FindFirstChildOfClass("SurfaceGui") then
				conPrecio += 1
			end
			local prompt = d:FindFirstChild("ProducePrompt")
			if prompt and prompt:IsA("ProximityPrompt") and prompt.ActionText == "Comprar" then
				conPrompt += 1
			end
		end
	end
	Cloud.check("Frutería: cajas con producto", okShop and crates > 0 and #nombres == crates and conForma == crates and conPrecio == crates and conPrompt == crates,
		("%d cajas, %d productos (%s), %d con forma, %d con precio, %d con «Comprar»%s"):format(crates, #nombres,
			table.concat(nombres, ", "), conForma, conPrecio, conPrompt, if okShop then "" else "; setupProduce: " .. tostring(err)))
	-- Fruterías del mapa (por su cartel)
	local okAll, n = pcall(function()
		local c = 0
		for _, b in require(Services.InteriorService).all() do
			local profile = b.Kind == "Local" and b.Shop and Interiors.profileFor(b.Shop)
			if profile and profile.Id == "Fruteria" then
				c += 1
			end
		end
		return c
	end)
	Cloud.check("Fruterías en el mapa", okAll and (n :: number) > 0, if okAll then tostring(n) .. " locales" else tostring(n))
end

---------------------------------------------------------------------
-- 3. Asientos con guardia
---------------------------------------------------------------------
do
	local total, rozan, conCartel, ejemplos = 0, 0, 0, {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("Seat") or d:IsA("VehicleSeat") then
			if d:IsDescendantOf(rooms) then
				continue
			end
			total += 1
			if d.CanTouch then
				rozan += 1
				if #ejemplos < 6 then
					table.insert(ejemplos, Cloud.nombre(d))
				end
			end
			if d:HasTag("Interact") and d:GetAttribute("Use") == "Sit" then
				conCartel += 1
			end
		end
	end
	Cloud.check("Asientos del mapa: ninguno sienta al rozarlo", total > 0 and rozan == 0,
		("%d asientos, %d con CanTouch, %d con cartel «Sentarse»%s"):format(total, rozan, conCartel,
			if rozan > 0 then ": " .. Cloud.lista(ejemplos) else ""))
	-- Uno que se construye después
	local seat = Instance.new("Seat")
	seat.Anchored = true
	seat.Position = Vector3.new(0, 6500, 0)
	seat.Parent = rooms
	task.wait(0.2)
	Cloud.check("Asiento nuevo: con guardia", not seat.CanTouch and seat:HasTag("Interact") and seat:GetAttribute("Use") == "Sit",
		("CanTouch=%s, Interact=%s, Use=%s"):format(tostring(seat.CanTouch), tostring(seat:HasTag("Interact")), tostring(seat:GetAttribute("Use"))))
end

rooms:Destroy()

local oido = Cloud.oido()
Cloud.check("Errores en la consola", #oido.errores == 0, if #oido.errores == 0 then "0" else Cloud.lista(oido.errores, 8))
Cloud.aviso("Avisos en la consola", #oido.avisos == 0, if #oido.avisos == 0 then "0" else Cloud.lista(oido.avisos, 8))

return Cloud.resultado()
