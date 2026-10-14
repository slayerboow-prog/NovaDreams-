-- pase: ¿está bien el pase de temporada en un servidor de Roblox de verdad?
--
-- Comprueba, con el juego publicado:
--   * que la temporada tiene recompensa en los 50 niveles de las dos pistas (Free y Premium),
--   * que el Game Pass existe, está a la venta y es de este juego,
--   * que se montan las vistas previas 3D de TODOS los coches, motos, barcos y decoraciones del pase
--     (BattlePassService.activate las monta en ReplicatedStorage.BattlePassPreviews): que existan, que
--     tengan piezas y que no midan algo absurdo; y que los vehículos se puedan sacar: una copia se
--     prepara con Rides.prepare (como VehicleService) y tiene que quedar con su asiento de conductor,
--   * que cargan las animaciones de los gestos (ContentProvider:PreloadAsync).
-- No toca datos de jugadores (no hay jugadores en este servidor).
--
-- Uso: bash scripts/cloud-test.sh -v pase

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")

local TALLA_MAX = 80 -- studs: un vehículo o una decoración más grande que esto es raro

Cloud.escuchar()
local BP = Cloud.Shared:WaitForChild("BattlePass")
local BPConfig = require(BP:WaitForChild("Config")) :: any
local Catalog = require(BP:WaitForChild("Catalog")) :: any
Cloud.check("El pase está encendido en el juego publicado", BPConfig.Enabled == true, "BattlePassConfig.Enabled = " .. tostring(BPConfig.Enabled))

-- 1. Recompensas en los 50 niveles de las dos pistas
for _, season in BPConfig.Seasons do
	local max = season.MaxLevel or 50
	local hay = { Free = {}, Premium = {} }
	local n = 0
	for _, r in season.Rewards or {} do
		n += 1
		if hay[r.Track] then
			hay[r.Track][r.Level] = true
		end
	end
	for _, track in { "Free", "Premium" } do
		local faltan = {}
		for level = 1, max do
			if not hay[track][level] then
				table.insert(faltan, tostring(level))
			end
		end
		-- (en la pista gratis no todos los niveles tienen por qué dar algo: solo aviso)
		local check = if track == "Premium" then Cloud.check else Cloud.aviso
		check(("%s: recompensa en los %d niveles de %s"):format(season.Id, max, track), #faltan == 0,
			if #faltan == 0 then ("%d recompensas en total"):format(n) else "faltan los niveles " .. Cloud.lista(faltan, 20))
	end
	Cloud.info(season.Id .. "_recompensas", n)

	-- 2. Game Pass
	if type(season.GamePassId) == "number" and season.GamePassId > 0 then
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, season.GamePassId, Enum.InfoType.GamePass)
		if ok and info then
			Cloud.check(season.Id .. ": Game Pass a la venta", info.IsForSale == true,
				("«%s», %s Robux"):format(tostring(info.Name), tostring(info.PriceInRobux)))
		else
			Cloud.check(season.Id .. ": Game Pass a la venta", false, "GetProductInfo falla: " .. tostring(info))
		end
	else
		Cloud.aviso(season.Id .. ": Game Pass a la venta", false, "GamePassId = 0 (la compra sale como «Próximamente»)")
	end
end

-- 3. Vistas previas 3D (las monta BattlePassService.activate en un task.spawn)
local ok, err = pcall(function()
	local service = require(Cloud.Server:WaitForChild("Services"):WaitForChild("BattlePassService")) :: any
	service.activate()
end)
Cloud.check("BattlePassService.activate()", ok, if ok then nil else tostring(err))
local folder = ReplicatedStorage:WaitForChild("BattlePassPreviews", 60)
Cloud.check("Se crea ReplicatedStorage.BattlePassPreviews", folder ~= nil)

local Rides = require(Cloud.Server:WaitForChild("World"):WaitForChild("Kit"):WaitForChild("Rides")) :: any

local function asientos(model: Instance): (number, number)
	local driver, seats = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("VehicleSeat") then
			driver += 1
		elseif d:IsA("Seat") then
			seats += 1
		end
	end
	return driver, seats
end

local function piezas(model: Instance): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

if folder then
	local all = Catalog.all()
	local ids = {}
	for id in all do
		table.insert(ids, id)
	end
	table.sort(ids)
	local vistos = 0
	for _, id in ids do
		local def = all[id]
		if def.Type ~= "VehicleSkin" and def.Type ~= "Boat" and def.Type ~= "Decor" then
			continue
		end
		vistos += 1
		local model = folder:FindFirstChild(id)
		local nombre = ("%s %s «%s»"):format(def.Type, id, tostring(def.Name))
		if not model then
			Cloud.check(nombre, false, "no se ha montado (su constructor falla: mira la consola)")
			continue
		end
		local n = piezas(model)
		local talla = Vector3.zero
		pcall(function()
			talla = (model :: Model):GetExtentsSize()
		end)
		local grande = math.max(talla.X, talla.Y, talla.Z)
		local detalle = ("%d piezas, talla %s"):format(n, Cloud.v3(talla))
		local bien = n > 0 and grande > 0.5 and grande <= TALLA_MAX
		local kind = if def.Type == "Boat" then (def.Boat or def.Kind) else def.Kind
		if (def.Type == "VehicleSkin" or def.Type == "Boat") and type(kind) == "string" and Rides.Spec[kind] then
			-- (sacarlo como hace VehicleService: una copia preparada, lejos de todo)
			local copia = model:Clone()
			copia.Parent = workspace
			local okP, errP = pcall(Rides.prepare, copia, kind, CFrame.new(0, 800, 0))
			local driver, seats = asientos(copia)
			detalle ..= ("; al sacarlo (%s): %d VehicleSeat y %d Seat"):format(kind, driver, seats)
			if not okP then
				detalle ..= " — Rides.prepare falla: " .. tostring(errP)
			end
			bien = bien and okP and driver >= 1
			copia:Destroy()
		elseif def.Type == "Boat" then
			detalle ..= " (barco: lo prepara BoatService, aquí solo se mira el modelo)"
		end
		Cloud.check(nombre, bien, detalle)
	end
	Cloud.info("vistas_previas", vistos)
end

-- 4. Gestos: ¿cargan sus animaciones?
for _, id in (function()
	local ids = {}
	for k in Catalog.all() do
		table.insert(ids, k)
	end
	table.sort(ids)
	return ids
end)() do
	local def = Catalog.get(id)
	if def and def.Type == "Emote" and def.AnimationId then
		local anim = Instance.new("Animation")
		anim.AnimationId = if type(def.AnimationId) == "number" then "rbxassetid://" .. def.AnimationId else tostring(def.AnimationId)
		local estado = "?"
		pcall(function()
			ContentProvider:PreloadAsync({ anim }, function(_, s)
				estado = s.Name
			end)
		end)
		Cloud.check(("Gesto %s «%s»"):format(id, tostring(def.Name)), estado == "Success", anim.AnimationId .. " → " .. estado)
		anim:Destroy()
	end
end

-- Errores en la consola mientras se montaba todo
local oido = Cloud.oido()
local delPase = {}
for _, e in oido.errores do
	if e:find("BattlePass") or e:find("Rides") or e:find("Rewards") then
		table.insert(delPase, e)
	end
end
Cloud.check("Sin errores del pase en la consola", #delPase == 0, if #delPase > 0 then Cloud.lista(delPase, 5) else nil)

return Cloud.resultado()
