-- ValmarWilds: ZONAS DE CAZA en la isla de Valmar (petición del dueño: «sitios de farmeo estilo World of
-- Warcraft y Metin2, para subir niveles y farmear objetos y dinero»). Usa lo mismo que los planetas
-- (shared/Cosmos/Bestiary + Services/BeastService): guaridas con manadas, anillos de zonas de caza
-- (cuanto más lejos del centro, más nivel), esquirlas de la Grieta con oleadas, alijos, ruinas y el jefe
-- (El Ciervo Roto) en lo más salvaje.
--
-- Dónde: solo en el CAMPO de verdad, lejos de lo construido. El relieve horneado (shared/Relief) dice,
-- de cada punto, cuánto hay construido alrededor y lo «salvaje» que es (la amplitud de las colinas:
-- 0 junto a calles y casas, alta en las sierras). Una guarida va donde no hay nada construido cerca,
-- con colinas de verdad, poca pendiente y suelo de tierra (no agua). Así nunca sale una manada en
-- una calle, una casa o un sitio de una misión.
--
-- surface() es pura (la prueba scripts/test-bestias.luau le pasa un relieve de mentira); build() la
-- monta en el servidor (BeastService.init, al poco de arrancar).

local Relief = require(game:GetService("ReplicatedStorage").Shared.Relief)
local ValmarRegions = require(game:GetService("ReplicatedStorage").Shared.Cosmos.ValmarRegions)
local OuterLands = require(game:GetService("ReplicatedStorage").Shared.Cosmos.OuterLands)
local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)

local ValmarWilds = {}

ValmarWilds.Id = "Valmar"
ValmarWilds.Half = 5400 -- (la isla cubre X ±5000, Z −4400..4300)
ValmarWilds.CoreHalf = 2400 -- (zona 1 hasta 0,74 × esto del centro; 2-4 en anillos hasta Half − 440)
ValmarWilds.MinWild = 25 -- amplitud mínima del relieve (studs) para que cuente como campo
ValmarWilds.ClearBuilt = 80 -- nada construido a menos de esto (studs)
ValmarWilds.LooseWild = 5 -- (las regiones con muy poco campo: S.goodSpot «loose»)
-- Radios de las zonas de caza desde el centro de la isla (el campo de verdad empieza a ~1500 studs:
-- la ciudad ocupa el centro): zona 1 (nv. 5) de 1500 a 2600, zona 2 hasta 3200, zona 3 hasta 3800 y
-- los confines (nv. 35, con el jefe) hasta la costa
ValmarWilds.ZoneR = { 1500, 2600, 3200, 3800, 5200 }

-- ground(x, z) → (Y del suelo o nil si no hay, ¿agua?)
function ValmarWilds.surface(field: Relief.Field, ground: (number, number) -> (number?, boolean?)): { [string]: any }
	local S = {}
	S.Id = ValmarWilds.Id
	S.Origin = Vector3.new(0, 0, 0)
	S.Seed = 57
	S.Half = ValmarWilds.Half
	S.CoreHalf = ValmarWilds.CoreHalf
	S.ZoneR = ValmarWilds.ZoneR
	-- las ocho regiones (shared/Cosmos/ValmarRegions): Bestiary.regionPlaces reparte por ellas guaridas y jefes
	S.Regions = ValmarRegions
	-- (17-11-2026) los distritos de caza de la isla (shared/CityPlan: Farm) y el Distrito Central, que es seguro
	S.Farms = {}
	for _, d in CityPlan.Districts do
		if d.Farm then
			table.insert(S.Farms, d)
		end
	end
	function S.insideFarm(d: { [string]: any }, x: number, z: number): boolean
		return CityPlan.inside(d.Poly, x, z)
	end
	local function inField(x: number, z: number): boolean
		return x > field.MinX + 64 and z > field.MinZ + 64 and x < field.MinX + (field.NX - 2) * field.Cell and z < field.MinZ + (field.NZ - 2) * field.Cell
	end
	function S.heightAt(x: number, z: number): number
		local y = ground(x, z)
		if y then
			return y
		end
		-- (las Tierras Exteriores: la misma cuenta con la que World/OuterLandsBuilder escribe el terreno)
		if ValmarRegions.outside(x, z) > 0 then
			return OuterLands.height(x, z) or Relief.surfaceY(field, x, z)
		end
		return Relief.surfaceY(field, x, z)
	end
	-- ¿Sitio bueno para una guarida? (lx, lz desde el centro de la isla)
	-- (loose: para las regiones casi sin campo, como el Pantano junto a la playa: vale terreno menos salvaje,
	-- pero igual de lejos de lo construido)
	function S.goodSpot(lx: number, lz: number, maxSlope: number, margin: number?, loose: boolean?): boolean
		-- al otro lado del mar: tierra firme, lejos de los campamentos y del paso de los puentes, sin mucha cuesta
		if ValmarRegions.outside(lx, lz) > 0 then
			local h = OuterLands.height(lx, lz)
			return h ~= nil and h > 4 and OuterLands.campDistance(lx, lz) > OuterLands.SafeRadius and OuterLands.flat(lx, lz) < 0.02
				and OuterLands.slope(lx, lz, 8) <= maxSlope
		end
		if not inField(lx, lz) then
			return false
		end
		if CityPlan.isCentral(lx, lz) then
			return false -- (el Distrito Central es la zona segura: ninguna bestia)
		end
		if Relief.amplitude(field, lx, lz) < (if loose then ValmarWilds.LooseWild else ValmarWilds.MinWild) then
			return false
		end
		local clear = ValmarWilds.ClearBuilt + (margin or 0)
		for _, o in { { 0, 0 }, { clear, 0 }, { -clear, 0 }, { 0, clear }, { 0, -clear } } do
			if Relief.builtAt(field, lx + o[1], lz + o[2]) > 0.02 then
				return false
			end
		end
		if Relief.slope(field, lx, lz, 6) > maxSlope then
			return false
		end
		-- (sin terreno aún, al arrancar: vale lo que diga el relieve, que es lo que se escribe luego)
		local _, wet = ground(lx, lz)
		return not wet
	end
	return S
end

-- Montarlo en el servidor: el relieve guardado en el mapa y el suelo de verdad (el terreno)
local surfaceS: { [string]: any }? = nil
function ValmarWilds.get(): { [string]: any }?
	if surfaceS then
		return surfaceS
	end
	local okB, ReliefBake = pcall(require, script.Parent.ReliefBake)
	local field = okB and (ReliefBake :: any).load() or nil
	if not field then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = false
	local function ground(x: number, z: number): (number?, boolean?)
		local hit = workspace:Raycast(Vector3.new(x, 900, z), Vector3.new(0, -1200, 0), params)
		if not hit then
			return nil, nil
		end
		return hit.Position.Y, hit.Material == Enum.Material.Water
	end
	surfaceS = ValmarWilds.surface(field, ground)
	return surfaceS
end

-- Las zonas de caza y el jefe en el mapa (ReplicatedStorage.MapLandmarks: shared/MapInfo, tipos
-- ZonaCaza y GuaridaJefe). Se llama al arrancar, antes de que los mapas de los jugadores lean los sitios.
function ValmarWilds.publish(Bestiary: any): number
	local S = ValmarWilds.get()
	if not S then
		return 0
	end
	local RS = game:GetService("ReplicatedStorage")
	local folder = RS:FindFirstChild("MapLandmarks")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "MapLandmarks"
		folder.Parent = RS
	end
	local places = Bestiary.places(S)
	local n = 0
	local function add(name: string, kind: string, x: number, z: number)
		if folder:FindFirstChild(name) then
			return
		end
		local config = Instance.new("Configuration")
		config.Name = name
		config:SetAttribute("Kind", kind)
		config:SetAttribute("Position", Vector3.new(x, 0, z))
		config:SetAttribute("District", "")
		config.Parent = folder
		n += 1
	end
	for _, lair in places.Lairs do
		if lair.Boss then
			add("Jefe_" .. lair.Id, if lair.Id:find("_Elite$") then "Jefe_Elite" else "Jefe_" .. (lair.Region or ""), lair.X, lair.Z)
		else
			add("ZonaCaza_" .. lair.Id, "ZonaCaza", lair.X, lair.Z)
		end
	end
	if places.Boss then
		add("GuaridaJefe_Valmar", "GuaridaJefe", places.Boss.X, places.Boss.Z)
	end
	-- los campamentos de las Tierras Exteriores (donde llegan los puentes)
	for _, b in OuterLands.Bridges do
		add("Campamento_" .. b.Id, "Campamento", b.CampX, b.CampZ)
	end
	-- el nombre de cada región, en medio de sus guaridas (o en el centro de su sector si no tiene)
	for _, reg in ValmarRegions.List do
		local sx, sz, k = 0, 0, 0
		for _, lair in places.Lairs do
			if lair.Region == reg.Id and not lair.Boss and ValmarRegions.outside(lair.X, lair.Z) > 0 then
				sx += lair.X
				sz += lair.Z
				k += 1
			end
		end
		local x, z
		if k > 0 then
			x, z = sx / k, sz / k
		else
			x, z = ValmarRegions.point(reg, (ValmarRegions.InnerR + ValmarRegions.OuterR) / 2)
		end
		add("Region_" .. reg.Id, "Region_" .. reg.Id, x, z)
	end
	return n
end

function ValmarWilds.build(BeastService: any): Instance?
	local S = ValmarWilds.get()
	if not S then
		warn("[ValmarWilds] sin relieve guardado: no hay zonas de caza en Valmar")
		return nil
	end
	-- (las guaridas del otro lado del mar necesitan su terreno: World/OuterLandsBuilder avisa con TierrasReady)
	local t0 = os.clock()
	while not workspace:GetAttribute("TierrasReady") and os.clock() - t0 < 420 do
		task.wait(2)
	end
	local folder = workspace:FindFirstChild("ValmarSalvaje")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ValmarSalvaje"
		folder.Parent = workspace
	end
	return BeastService.buildWilds(S, folder)
end

return ValmarWilds
