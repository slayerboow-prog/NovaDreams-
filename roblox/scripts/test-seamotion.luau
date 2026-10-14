-- Prueba de las animaciones de nadar, bucear y pescar (Controllers/SeaMotion) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-seamotion.luau
--
-- Comprueba que cada postura sale bien (sin números raros) y que se parece a lo que tiene que ser:
-- el crol va boca abajo con los brazos alternos, al bajar se va de cabeza, al apuntar los brazos
-- van estirados al frente, al echar la caña se lleva atrás y luego adelante, al sacar el pez lo
-- enseña con la otra mano, etc.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame = roblox.CFrame
local env = setmetatable({ CFrame = CFrame, Vector3 = roblox.Vector3 }, { __index = getfenv(1) })
local SeaMotion = luau.load(fs.readFile("src/client/Controllers/SeaMotion.luau"), { debugName = "SeaMotion", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Ángulo X (el principal) de una articulación
local function pitch(cf): number
	local x = cf:ToEulerAnglesXYZ()
	return x
end

local function finite(pose): boolean
	for _, cf in pose do
		local x, y, z = cf:ToEulerAnglesXYZ()
		for _, v in { x, y, z, cf.Position.X, cf.Position.Y, cf.Position.Z } do
			if v ~= v or v == math.huge or v == -math.huge then
				return false
			end
		end
	end
	return true
end

local function input(over)
	local i = { InWater = false, Underwater = false, Speed = 0, Vertical = 0, Armed = false, ShotAgo = math.huge, Fish = nil, FishAgo = 0, Phase = 0, Seed = 1 }
	for k, v in over do
		i[k] = v
	end
	return i
end

print("▶ Nadar y bucear")
local ok = true
for t = 0, 6, 0.13 do
	for _, i in {
		input({ InWater = true }),
		input({ InWater = true, Speed = 12, Phase = t * 3 }),
		input({ InWater = true, Underwater = true, Speed = 10, Phase = t * 2 }),
		input({ InWater = true, Underwater = true, Vertical = -10, Phase = t * 2 }),
		input({ InWater = true, Underwater = true, Vertical = 10, Phase = t * 2 }),
		input({ InWater = true, Underwater = true, Armed = true, ShotAgo = t }),
	} do
		local pose = SeaMotion.pose(i, t)
		ok = ok and pose ~= nil and finite(pose)
	end
end
check(ok, "todas las posturas de agua salen bien en cualquier momento")
local _, s1 = SeaMotion.pose(input({ InWater = true }), 0)
local _, s2 = SeaMotion.pose(input({ InWater = true, Speed = 12 }), 0)
local _, s3 = SeaMotion.pose(input({ InWater = true, Underwater = true, Speed = 12 }), 0)
local _, s4 = SeaMotion.pose(input({ InWater = true, Underwater = true, Vertical = -10 }), 0)
local _, s5 = SeaMotion.pose(input({ InWater = true, Underwater = true, Vertical = 10 }), 0)
local _, s6 = SeaMotion.pose(input({ InWater = true, Underwater = true, Armed = true }), 0)
check(s1 == "Tread" and s2 == "Crawl" and s3 == "Dive" and s4 == "Down" and s5 == "Up" and s6 == "Aim", "elige flotar, crol, bucear, bajar, subir y apuntar según lo que hace")
local crawl = SeaMotion.crawl(0.7, 0, 1)
check(math.abs(pitch(crawl.Root) + math.pi / 2) < 0.3, "a crol va boca abajo")
local diff = 0
for ph = 0, 6, 0.3 do
	local c = SeaMotion.crawl(ph, 0, 1)
	diff = math.max(diff, math.abs(pitch(c.RightShoulder) - pitch(c.LeftShoulder)))
end
check(diff > 1.5, "a crol los brazos van alternos (uno delante y otro atrás)")
local down = SeaMotion.dive(0, 0, 1, -12, 0.7)
local level = SeaMotion.dive(0, 0, 1, 0, 0.7)
local up = SeaMotion.dive(0, 0, 1, 12, 0.7)
check(pitch(down.Root) < pitch(level.Root) and pitch(level.Root) < pitch(up.Root), "al bajar se va de cabeza y al subir mira arriba")
local tread = SeaMotion.tread(0, 1)
check(pitch(tread.Root) > -0.5, "flotando quieto va de pie")
local aim = SeaMotion.aim(0, 1, 0, math.huge)
check(pitch(aim.RightShoulder) > 2.5 or pitch(aim.RightShoulder) < -2.5, "al apuntar, el brazo del arma va estirado al frente")
local shot = SeaMotion.aim(0, 1, 0, 0.08)
local rest = SeaMotion.aim(0, 1, 0, 5)
check(math.abs(pitch(shot.RightElbow) - pitch(rest.RightElbow)) > 0.2, "al disparar, el arma da un golpe de retroceso")

print("▶ Pesca con caña")
ok = true
for ago = 0, 4, 0.1 do
	for _, fish in { "Cast", "Wait", "Bite", "Fight", "Catch", "Lost", "Reel", "Heave" } do
		local pose = SeaMotion.pose(input({ Fish = fish, FishAgo = ago }), ago)
		ok = ok and (pose == nil or finite(pose))
	end
end
check(ok, "todas las posturas de pesca salen bien")
local hold = SeaMotion.hold(0, 1)
local back = SeaMotion.cast(0.3, 0, 1)
local whip = SeaMotion.cast(0.6, 0, 1)
local settled = SeaMotion.cast(1.3, 0, 1)
check(pitch(back.RightShoulder) > pitch(hold.RightShoulder) + 1.2 or pitch(back.RightShoulder) < 0, "al echar la caña primero la lleva atrás por encima del hombro")
check(math.abs(pitch(whip.Waist)) > 0.05, "y luego da el latigazo hacia delante")
check((settled.RightShoulder.Position - hold.RightShoulder.Position).Magnitude < 1e-3 and math.abs(pitch(settled.RightShoulder) - pitch(hold.RightShoulder)) < 0.05, "y se queda esperando con la caña delante")
local bite = SeaMotion.bite(0.2, 0, 1)
check(pitch(bite.RightShoulder) > pitch(hold.RightShoulder) + 0.3, "cuando pica da un tirón hacia arriba")
local f1 = SeaMotion.fight(0.1, 0.2, 1)
check(pitch(f1.Waist) > 0.2, "peleando con un pez grande se echa hacia atrás")
local l1, l2 = SeaMotion.fight(5, 0, 1), SeaMotion.fight(5, 0.13, 1)
check(math.abs(pitch(l1.LeftElbow) - pitch(l2.LeftElbow)) > 0.05, "y la otra mano da vueltas al carrete")
local show = SeaMotion.catch(1.2, 0, 1)
check(pitch(show.LeftShoulder) > pitch(hold.LeftShoulder) + 0.6, "al sacarlo enseña el pez con la otra mano")
local lost = SeaMotion.lost(0.8, 0, 1)
check(pitch(lost.RightShoulder) < pitch(hold.RightShoulder) - 0.2, "si se escapa, baja los brazos")
check(SeaMotion.pose(input({ Fish = "Reel", FishAgo = 2 }), 0) == nil, "al recoger, luego suelta los brazos")
local h = SeaMotion.heave(0.1, 0, 1)
check(pitch(h.Root) > 0.2, "con un monstruo marino tira con todo el cuerpo hacia atrás")
check(SeaMotion.pose(input({}), 0) == nil, "en tierra y sin pescar no hace nada")

if failures > 0 then
	print(("\n❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
print("\n✅ Todo correcto")
