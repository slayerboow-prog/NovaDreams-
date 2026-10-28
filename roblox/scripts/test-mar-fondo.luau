-- Prueba: el mar hondo se ABRE de verdad en el terreno (v131), fuera de Roblox, con Lune.
--
-- En un servidor de verdad (sonda mar-v3-sonda, v131) el fondo del mar quedaba plano a −14 de arenisca en todas
-- partes: el agua de World/OceanBuilder caía sobre la capa de arena de World/TerrainBuilder (−24 a −14) y en
-- Roblox el AGUA NO SUSTITUYE el terreno macizo (solo llena lo vacío: por eso el río y los lagos se abren antes
-- con aire). Aquí, un terreno de mentira con ESA regla, por columnas de 1 stud en unos sitios:
--   * empieza como lo deja TerrainBuilder: arenisca de −24 a −14 y agua de −14 a −2
--   * se le pasa OceanBuilder.terrain entero (los mismos rellenos que en el juego)
--   * en los sitios hondos el primer macizo desde arriba tiene que estar en el fondo del plan (Ocean.floorY), no
--     a −14; y en la orilla poco honda, la capa sigue (no se abre un agujero)
--
-- Uso (desde roblox/):  lune run scripts/test-mar-fondo.luau

local L = require("./lib/ModuleLoader")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local check = L.check

local Ocean = L.load("src/shared/Sea/Ocean")
local OceanBuilder = L.load("src/server/World/OceanBuilder")
local TerrainCarve = L.load("src/server/World/TerrainCarve")

local Y0, Y1 = -620, 0
local spots = {
	{ Name = "Jardín Escarlata", X = Ocean.PoiById.JardinEscarlata.X + 30, Z = Ocean.PoiById.JardinEscarlata.Z + 30 },
	{ Name = "Laberinto de Kelp", X = Ocean.Kelp[1].X + 40, Z = Ocean.Kelp[1].Z - 40 },
	{ Name = "Abismo", X = Ocean.Basin.X, Z = Ocean.Basin.Z },
	{ Name = "Llanura", X = 0, Z = -4900 },
}
-- (un punto poco hondo junto a una playa: su fondo es la capa de TerrainBuilder)
for _, r in Ocean.ShoreReefs do
	local nx, nz = 0, 0
	local s = Ocean.sample(r.X, r.Z)
	if s.Floor and s.Floor > -14.5 then
		table.insert(spots, { Name = "orilla " .. r.Name, X = r.X, Z = r.Z, Shallow = true })
		break
	end
	local _ = nx + nz
end

-- columnas: mat[y] (y entero, de Y0 a Y1): "Air" | "Water" | otro (macizo)
local cols = {}
for _, sp in spots do
	local c = {}
	for y = Y0, Y1 do
		c[y] = if y >= -24 and y < -14 then "Sandstone" elseif y >= -14 and y < -2 then "Water" else "Air"
	end
	cols[sp] = c
end

local function apply(inside: (Vector3) -> boolean, material: any)
	local name = tostring(material):match("Material%.(%w+)") or tostring(material)
	for sp, c in cols do
		for y = Y0, Y1 do
			if inside(Vector3.new(sp.X, y + 0.5, sp.Z)) then
				if name == "Water" then
					if c[y] == "Air" then
						c[y] = "Water" -- (como Roblox: el agua solo llena lo vacío)
					end
				else
					c[y] = name
				end
			end
		end
	end
end

local fake = {}
function fake:FillBlock(cf, size, material)
	apply(function(p)
		local l = cf:PointToObjectSpace(p)
		return math.abs(l.X) <= size.X / 2 and math.abs(l.Y) <= size.Y / 2 and math.abs(l.Z) <= size.Z / 2
	end, material)
end
function fake:FillBall(center, r, material)
	apply(function(p)
		return (p - center).Magnitude <= r
	end, material)
end
function fake:FillCylinder(cf, h, r, material)
	apply(function(p)
		local l = cf:PointToObjectSpace(p)
		return math.abs(l.Y) <= h / 2 and l.X * l.X + l.Z * l.Z <= r * r
	end, material)
end
function fake:SetMaterialColor() end

-- La regla de mentira es la de Roblox: el agua sola no abre
do
	local c = { [0] = "Sandstone" }
	cols = { [{ X = 0, Z = 0 }] = c }
	for y = Y0, Y1 do
		c[y] = "Sandstone"
	end
	fake:FillBlock(roblox.CFrame.new(0, -5, 0), Vector3.new(4, 4, 4), roblox.Enum.Material.Water)
	local before = c[-5]
	TerrainCarve.wrap(fake):FillBlock(roblox.CFrame.new(0, -5, 0), Vector3.new(4, 4, 4), roblox.Enum.Material.Water)
	check(before == "Sandstone" and c[-5] == "Water", "El agua sola no abre la arena (como en Roblox); con TerrainCarve, sí")
end
-- (otra vez las columnas de verdad)
cols = {}
for _, sp in spots do
	local c = {}
	for y = Y0, Y1 do
		c[y] = if y >= -24 and y < -14 then "Sandstone" elseif y >= -14 and y < -2 then "Water" else "Air"
	end
	cols[sp] = c
end

print("▶ OceanBuilder.terrain sobre la capa de TerrainBuilder (puede tardar)")
if require("@lune/process").env.SIN_ABRIR == "1" then
	OceanBuilder.slabWater = function()
		return {}
	end -- (para ver que la prueba falla con lo de antes)
end
OceanBuilder.terrain(TerrainCarve.wrap(fake))

for _, sp in spots do
	local c = cols[sp]
	local top = nil
	for y = Y1, Y0, -1 do
		if c[y] ~= "Air" and c[y] ~= "Water" then
			top = y + 1
			break
		end
	end
	local plan = Ocean.floorY(sp.X, sp.Z)
	if sp.Shallow then
		check(top ~= nil and top >= -16 and top <= -12, ("%s: el fondo poco hondo sigue a −14 (terreno %s)"):format(sp.Name, tostring(top)))
	else
		local water = c[-20] == "Water" and c[-16] == "Water"
		-- (en lo muy hondo los bloques juntan más: ±20 studs)
		local tol = if plan and plan < -150 then 20 else 8
		check(top ~= nil and plan ~= nil and math.abs(top - plan) <= tol and water, ("%s: el fondo está donde dice el plan (%.0f), con agua de −24 a −14 (terreno %s)"):format(sp.Name, plan or 0, tostring(top)))
	end
end

L.finish("Fondo del mar abierto")
