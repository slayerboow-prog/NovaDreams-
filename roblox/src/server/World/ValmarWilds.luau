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

local ValmarWilds = {}

ValmarWilds.Id = "Valmar"
ValmarWilds.Half = 5400 -- (la isla cubre X ±5000, Z −4400..4300)
ValmarWilds.CoreHalf = 2400 -- (zona 1 hasta 0,74 × esto del centro; 2-4 en anillos hasta Half − 440)
ValmarWilds.MinWild = 25 -- amplitud mínima del relieve (studs) para que cuente como campo
ValmarWilds.ClearBuilt = 80 -- nada construido a menos de esto (studs)
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
	local function inField(x: number, z: number): boolean
		return x > field.MinX + 64 and z > field.MinZ + 64 and x < field.MinX + (field.NX - 2) * field.Cell and z < field.MinZ + (field.NZ - 2) * field.Cell
	end
	function S.heightAt(x: number, z: number): number
		local y = ground(x, z)
		return y or Relief.surfaceY(field, x, z)
	end
	-- ¿Sitio bueno para una guarida? (lx, lz desde el centro de la isla)
	function S.goodSpot(lx: number, lz: number, maxSlope: number, margin: number?): boolean
		if not inField(lx, lz) then
			return false
		end
		if Relief.amplitude(field, lx, lz) < ValmarWilds.MinWild then
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
		add("ZonaCaza_" .. lair.Id, "ZonaCaza", lair.X, lair.Z)
	end
	if places.Boss then
		add("GuaridaJefe_Valmar", "GuaridaJefe", places.Boss.X, places.Boss.Z)
	end
	return n
end

function ValmarWilds.build(BeastService: any): Instance?
	local S = ValmarWilds.get()
	if not S then
		warn("[ValmarWilds] sin relieve guardado: no hay zonas de caza en Valmar")
		return nil
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
