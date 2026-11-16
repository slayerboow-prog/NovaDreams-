-- ValmarRegions: las OCHO GRANDES REGIONES de caza que rodean la ciudad de Valmar (petición del dueño: un
-- mundo abierto al estilo MMORPG, con zonas por nivel, sus criaturas y su jefe). Datos y cuentas puras:
-- lo usan shared/Cosmos/Bestiary (dónde van guaridas, jefes, esquirlas y alijos), shared/Relief (el suelo
-- de cada región: arena, nieve, lodo, basalto…), World/ValmarWilds (las monta y las pone en el mapa),
-- Controllers/RegionBanner (el cartel al entrar) y las pruebas (scripts/test-bestias.luau).
--
--   * La ciudad (los seis distritos) se queda como está: es la zona segura. Las regiones son el CAMPO de
--     alrededor (lo salvaje que dice el relieve horneado), repartido en ocho sectores como en el mapa del
--     dueño: norte arriba (−Z), y en el sentido de las agujas del reloj.
--   * Cada región tiene su franja de niveles: cuanto más lejos de la ciudad dentro de ella, más nivel.
--   * Bearing: el centro del sector en grados desde el norte (0 = −Z, 90 = +X).

local ValmarRegions = {}

local rgb = Color3.fromRGB

ValmarRegions.InnerR = 1500 -- donde empieza el campo de verdad (la ciudad ocupa el centro)
ValmarRegions.OuterR = 5200 -- la costa
ValmarRegions.Width = 45 -- grados de cada sector

ValmarRegions.List = {
	{ Id = "BosqueEtereo", Name = "Bosque Etéreo", Icon = "🌲", Bearing = 0, MinLevel = 10, MaxLevel = 30,
		Color = rgb(80, 210, 100), Look = "Raices", Rare = "MaderaEterea",
		Species = { "LoboBosque", "AranaBosque", "GuardianMadera" }, Boss = "GuardianAncestral", Elite = "CiervoRoto",
		Ground = { Flat = "LeafyGrass", Mix = "Grass", Slope = "Ground", Steep = "Rock" },
		Lore = "Árboles que crecieron demasiado deprisa la noche que se abrió la Grieta. Algo los cuida." },
	{ Id = "TierrasOscuras", Name = "Tierras Oscuras", Icon = "💀", Bearing = 45, MinLevel = 80, MaxLevel = 100,
		Color = rgb(160, 90, 240), Look = "Roca", Rare = "FragmentoSombra",
		Species = { "BestiaSombria", "CaballeroCorrupto", "CriaturaVacio" }, Boss = "SenorSombras",
		Ground = { Flat = "Slate", Mix = "Ground", Slope = "Basalt", Steep = "Basalt" },
		Lore = "Aquí la luz de la Grieta no llega: se la comen. Cosme prohibió a sus ayudantes cruzar el puente negro." },
	{ Id = "PantanoMaldito", Name = "Pantano Maldito", Icon = "☠", Bearing = 90, MinLevel = 40, MaxLevel = 60,
		Color = rgb(70, 170, 120), Look = "Raices", Rare = "LodoMaldito",
		Species = { "CocodriloMutado", "AvispaGrieta", "EspirituCorrupto" }, Boss = "DevoradorPantano",
		Ground = { Flat = "Mud", Mix = "LeafyGrass", Slope = "Ground", Steep = "Slate" },
		Lore = "El agua que bajaba del laboratorio viejo acabó aquí. Las ranas ya no croan: cuentan." },
	{ Id = "RuinasAntiguas", Name = "Ruinas Antiguas", Icon = "🏛", Bearing = 135, MinLevel = 60, MaxLevel = 80,
		Color = rgb(230, 190, 80), Look = "Roca", Rare = "ReliquiaRunica",
		Species = { "CaballeroEspectral", "GuardianPiedra", "ConstructoRuinas" }, Boss = "ReyRuinas",
		Ground = { Flat = "Ground", Mix = "Limestone", Slope = "Limestone", Steep = "Rock" },
		Lore = "Una ciudad más vieja que Valmar. Sus muros tienen las mismas marcas que los cristales de la Grieta." },
	{ Id = "LlanurasSalvajes", Name = "Llanuras Salvajes", Icon = "🐾", Bearing = 180, MinLevel = 20, MaxLevel = 40,
		Color = rgb(150, 215, 70), Look = "Roca", Rare = "CrinSalvaje",
		Species = { "JabaliSierra", "AcechadorPradera", "SaqueadorNomada" }, Boss = "ReyLlanuras",
		Ground = { Flat = "Grass", Mix = "Grass", Slope = "Ground", Steep = "Rock" },
		Lore = "Praderas sin dueño. Los nómadas dicen que la hierba se mueve sola cuando el Rey pasa." },
	{ Id = "TierrasVolcanicas", Name = "Tierras Volcánicas", Icon = "🌋", Bearing = 225, MinLevel = 90, MaxLevel = 110,
		Color = rgb(245, 90, 45), Look = "Roca", Rare = "MagmaVivo",
		Species = { "SabuesoMagma", "GolemLava", "SalamandraVolcan" }, Boss = "TitanVolcan",
		Ground = { Flat = "Basalt", Mix = "CrackedLava", Slope = "Basalt", Steep = "Rock" },
		Lore = "El volcán dormía desde antes de los mapas. Despertó el mismo día que el cielo se rajó." },
	{ Id = "DesiertoDorado", Name = "Desierto Dorado", Icon = "🏜", Bearing = 270, MinLevel = 50, MaxLevel = 70,
		Color = rgb(240, 190, 80), Look = "Arenisca", Rare = "ArenaDorada",
		Species = { "EscorpionGigante", "VivoraPenasco", "GuardianDesierto" }, Boss = "ColosoArena",
		Ground = { Flat = "Sand", Mix = "Sand", Slope = "Sandstone", Steep = "Sandstone" },
		Lore = "La arena brilla de noche. Debajo hay templos que nadie de Valmar recuerda haber construido." },
	{ Id = "MontanasHeladas", Name = "Montañas Heladas", Icon = "❄", Bearing = 315, MinLevel = 70, MaxLevel = 90,
		Color = rgb(130, 200, 255), Look = "Hielo", Rare = "EscarchaPerpetua",
		Species = { "LoboArtico", "GolemHielo", "DracoHielo" }, Boss = "DragonInvierno",
		Ground = { Flat = "Snow", Mix = "Snow", Slope = "Glacier", Steep = "Rock" },
		Lore = "Nieva en pleno verano. Los montañeros que suben vuelven hablando de un ala del tamaño de un barco." },
}

ValmarRegions.ById = {}
for i, r in ValmarRegions.List do
	r.Index = i
	ValmarRegions.ById[r.Id] = r
end

-- Rumbo (grados desde el norte, 0..360) de un punto respecto al centro de la isla
function ValmarRegions.bearing(x: number, z: number): number
	local b = math.deg(math.atan2(x, -z))
	return (b + 360) % 360
end

-- Diferencia de ángulos (−180..180)
local function delta(a: number, b: number): number
	return ((a - b + 540) % 360) - 180
end

-- La región de un punto (o nil en la ciudad). wobble: los bordes ondulan un poco (no son rectas)
function ValmarRegions.at(x: number, z: number, wobble: boolean?): { [string]: any }?
	local r = math.sqrt(x * x + z * z)
	if r < ValmarRegions.InnerR then
		return nil
	end
	local b = ValmarRegions.bearing(x, z)
	if wobble then
		b += math.noise(x / 900, z / 900, 3.7) * 14
	end
	local best, bestD = nil, math.huge
	for _, reg in ValmarRegions.List do
		local d = math.abs(delta(b, reg.Bearing))
		if d < bestD then
			best, bestD = reg, d
		end
	end
	return best
end

-- ¿Este punto está en el sector de la región? (margin: grados que se quitan por cada lado)
function ValmarRegions.inside(reg: { [string]: any }, x: number, z: number, margin: number?): boolean
	local half = ValmarRegions.Width / 2 - (margin or 0)
	return math.abs(delta(ValmarRegions.bearing(x, z), reg.Bearing)) <= half
end

-- El nivel de un sitio dentro de su región: de MinLevel (junto a la ciudad) a MaxLevel (cerca de la costa)
function ValmarRegions.levelAt(reg: { [string]: any }, x: number, z: number): number
	local r = math.sqrt(x * x + z * z)
	local t = math.clamp((r - ValmarRegions.InnerR) / (ValmarRegions.OuterR - 600 - ValmarRegions.InnerR), 0, 1)
	return math.floor(reg.MinLevel + (reg.MaxLevel - reg.MinLevel) * t + 0.5)
end

-- Un punto en el centro del sector, a esa distancia del centro de la isla (para su cartel en el mapa)
function ValmarRegions.point(reg: { [string]: any }, radius: number): (number, number)
	local a = math.rad(reg.Bearing)
	return math.sin(a) * radius, -math.cos(a) * radius
end

-- «Bosque Etéreo · Nv. 10-30»
function ValmarRegions.label(reg: { [string]: any }): string
	return ("%s · Nv. %d-%d"):format(reg.Name, reg.MinLevel, reg.MaxLevel)
end

-- ¿Qué tal le va a un jugador de ese nivel? "Facil" | "Justa" | "Dificil" | "Peligro"
function ValmarRegions.danger(reg: { [string]: any }, level: number): string
	if level >= reg.MaxLevel + 10 then
		return "Facil"
	elseif level >= reg.MinLevel - 3 then
		return "Justa"
	elseif level >= reg.MinLevel - 12 then
		return "Dificil"
	end
	return "Peligro"
end

-- Cuánto da una bestia a un jugador que la supera de largo (que nadie farmee lo fácil sin fin)
function ValmarRegions.rewardFactor(playerLevel: number?, beastLevel: number?): number
	local p, b = tonumber(playerLevel), tonumber(beastLevel)
	if not p or not b then
		return 1
	end
	local over = p - b
	if over <= 10 then
		return 1
	elseif over <= 20 then
		return 0.35
	end
	return 0.1
end

return ValmarRegions
