-- test-tierras: LAS TIERRAS EXTERIORES (shared/Cosmos/OuterLands, World/OuterLandsBuilder): el continente nuevo
-- alrededor del mar de Valmar con las ocho regiones. lune run scripts/test-tierras.luau

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

local OL = L.load("src/shared/Cosmos/OuterLands")
local VR = L.load("src/shared/Cosmos/ValmarRegions")
local F = VR.Frame

print("🌍 Forma del continente")
check(OL.height(0, 0) == nil and OL.height(F.MaxX - 10, 0) == nil and OL.height(0, F.MinZ + 10) == nil, "dentro del mar de Valmar no se toca nada (ni la isla ni el mar)")
check(((F.Width + OL.Band) % 16) == 0 and ((F.MaxX - F.MinX) % 4) == 0 and ((F.MaxZ - F.MinZ) % 4) == 0, "el marco cuadra con los vóxeles y los nudos")
local land, water, per, maxH = 0, 0, {}, {}
for x = F.MinX - F.Width - 400, F.MaxX + F.Width + 400, 64 do
	for z = F.MinZ - F.Width - 400, F.MaxZ + F.Width + 400, 64 do
		local h = OL.height(x, z)
		if h then
			if OL.isLand(x, z) then
				land += 1
				local reg = OL.regions(x, z)
				per[reg.Id] = (per[reg.Id] or 0) + 1
				maxH[reg.Id] = math.max(maxH[reg.Id] or -1e9, h)
			else
				water += 1
			end
		end
	end
end
local km = land * 64 * 64
check(km > 60e6, ("mucha tierra nueva (%.0f millones de studs²)"):format(km / 1e6))
local allOk, txt = true, {}
for _, reg in VR.List do
	allOk = allOk and (per[reg.Id] or 0) * 4096 > 4e6
	table.insert(txt, ("%s %.0fM"):format(reg.Id, (per[reg.Id] or 0) * 4096 / 1e6))
end
check(allOk, "cada región tiene su territorio grande: " .. table.concat(txt, ", "))
check(water > 0, "con su mar alrededor")

print("⛰ Relieve de cada región")
check((maxH.MontanasHeladas or 0) > 250, ("picos altos en las Montañas Heladas (%d)"):format(math.floor(maxH.MontanasHeladas or 0)))
local V = OL.Volcano
local rim = OL.height(V.X + V.Crater * 1.3, V.Z) or 0
local pit = OL.height(V.X, V.Z) or 0
check(rim > 200 and pit < rim - 40, ("un volcán con su cráter (borde %d, fondo %d)"):format(math.floor(rim), math.floor(pit)))
local pools = 0
for x = 5900, 7400, 40 do
	for z = -1800, 1800, 40 do
		local h = OL.height(x, z)
		if h and h < OL.Surface and OL.edge(x, z) > 300 then
			pools += 1
		end
	end
end
check(pools > 5, ("charcas en el Pantano Maldito (%d)"):format(pools))
check(OL.material(-7000, 300, 30, 0.1) == "Sand" or OL.material(-7000, 300, 30, 0.1) == "Sandstone", "arena en el Desierto Dorado")
check(OL.material(V.X, V.Z, 300, 0.2) == "CrackedLava", "lava en el cráter")
check(OL.material(-6900, -6400, 260, 0.2) == "Snow", "nieve en lo alto de las Montañas Heladas")

print("🌉 Puentes y campamentos")
local okB = #OL.Bridges == 4
for _, b in OL.Bridges do
	okB = okB and OL.isLand(b.CampX, b.CampZ) and math.abs((OL.height(b.CampX, b.CampZ) or 0) - OL.CampY) < 1
	okB = okB and OL.isLand(b.EdgeX + b.Dir[1] * 240, b.EdgeZ + b.Dir[2] * 240) and OL.slope(b.CampX, b.CampZ) < 0.1
	okB = okB and VR.ById[b.Region] ~= nil and VR.at(b.CampX, b.CampZ).Id == b.Region
end
check(okB, "cuatro puentes que llegan a tierra firme y un campamento llano en la región que toca")
check(VR.ById[OL.Bridges[1].Region].MinLevel <= 20 and VR.ById[OL.Bridges[3].Region].MinLevel <= 20, "los puentes del norte y del sur llevan a las regiones de menos nivel")

print("🌲 Decoración")
local deco = OL.decor()
local dOk, kinds = #deco >= 700, {}
for _, d in deco do
	dOk = dOk and OL.isLand(d.X, d.Z) and OL.campDistance(d.X, d.Z) > OL.CampRadius
	kinds[d.Kind] = (kinds[d.Kind] or 0) + 1
end
check(dOk and (kinds.Arbol or 0) > 80 and (kinds.Cactus or 0) > 20 and (kinds.Lava or 0) > 5 and (kinds.Pino or 0) > 40, ("árboles, cactus, pinos, lava… en tierra firme (%d)"):format(#deco))
check(OL.decor() == deco, "siempre lo mismo (se calcula una vez)")

print("🔌 Conexiones")
local main = fs.readFile("src/server/Main.server.luau")
check(string.find(main, "OuterLandsBuilder", 1, true) ~= nil, "el servidor construye las Tierras Exteriores al arrancar")
local builder = fs.readFile("src/server/World/OuterLandsBuilder.luau")
check(string.find(builder, "TierrasReady", 1, true) ~= nil and string.find(builder, "WriteVoxels", 1, true) ~= nil, "el constructor escribe el terreno y avisa al acabar")
local wilds = fs.readFile("src/server/World/ValmarWilds.luau")
check(string.find(wilds, "TierrasReady", 1, true) ~= nil and string.find(wilds, "OuterLands.height", 1, true) ~= nil, "las guaridas esperan al terreno y se apoyan en él")

L.finish("test-tierras")
