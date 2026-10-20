-- Karting de San Roque (zona 13, Llanura de San Roque Sur; shared/OcioSitios «Karting»).
--
--   * Circuito de shared/KartTrack (≈ 930 studs por vuelta en 370 × 220): asfalto en tramos planos con
--     discos en las uniones, pianos rojos y blancos y muros de neumáticos por fuera de las curvas.
--   * Línea de meta a cuadros, pórtico con el semáforo de salida (tag OcioKartLight + Light = 1..3: lo
--     enciende KartService) y la parrilla.
--   * Boxes: caseta, taquilla (tag OcioKartDesk: «Correr · Karts» y «Contrarreloj»), estantes de ruedas
--     (Pickup_Boxes), karts de exposición (Dropoff_Boxes) y tablón del oficio «Mecánico/a de boxes».
--   * Panel de la clasificación (tag OcioKartBoard: KartService escribe las mejores vueltas), grada y focos.
-- Coordenadas del sitio: X hacia el este, Z hacia el sur (las calles de San Roque quedan al norte).

local Builder = require(script.Parent.Parent.Parent.Builder)
local Props = require(script.Parent.Parent.Props)
local Rides = require(script.Parent.Parent.Rides)
local Kit = require(script.Parent.OcioKit)
local Sitios = require(game:GetService("ReplicatedStorage").Shared.OcioSitios)
local KartTrack = require(game:GetService("ReplicatedStorage").Shared.KartTrack)

local Karting = {}

local rgb = Color3.fromRGB
local NORTH, SOUTH, WEST = Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0)

Karting.PER_SPAN = 4 -- puntos por tramo de la línea central al construir (los mismos que al cronometrar)
Karting.ASPHALT_TOP = 0.15
Karting.PIT = { X = 75, Z = -96 }
Karting.DESK = { X = 30, Z = -92 }

local function turnAt(pts: { { number } }, i: number): number
	-- giro (con signo) en el punto i: + a la derecha, - a la izquierda (vista desde arriba, Z al sur)
	local n = #pts
	local a, b, c = pts[(i - 2) % n + 1], pts[i], pts[i % n + 1]
	local ux, uz = b[1] - a[1], b[2] - a[2]
	local vx, vz = c[1] - b[1], c[2] - b[2]
	return math.atan2(ux * vz - uz * vx, ux * vx + uz * vz)
end

function Karting.build(parent: Instance): Model
	local site = Sitios.get("Karting") :: any
	local root = Builder.model("Ocio_Karting", parent)
	root:SetAttribute("Zone", site.Zone)
	local base = Sitios.cframe("Karting")
	local function at(x: number, z: number, dir: Vector3?): CFrame
		local p = base * CFrame.new(x, 0, z)
		return if dir then Builder.facing(p.Position, dir) else p
	end
	local function world(x: number, z: number, y: number?): Vector3
		return (base * CFrame.new(x, y or 0, z)).Position
	end

	-- Asfalto: un tramo por lado de la línea central y un disco en cada unión
	local track = Builder.model("Pista", root)
	local pts = KartTrack.centerline(Karting.PER_SPAN)
	local W = KartTrack.WIDTH
	local asphalt = rgb(58, 58, 62)
	local H = 1.3
	local yMid = 1 + Karting.ASPHALT_TOP - H / 2 -- (sobre la base del sitio, que está en Y = -1)
	for i = 1, #pts do
		local a, b = pts[i], pts[i % #pts + 1]
		local pa, pb = world(a[1], a[2], yMid), world(b[1], b[2], yMid)
		local len = (pb - pa).Magnitude
		Kit.part(track, "Asphalt", Vector3.new(W, H, len + 0.4), Kit.along((pa + pb) / 2, pb - pa), asphalt, Enum.Material.Asphalt)
		Kit.disc(track, "AsphaltJoint", W, H - 0.02, CFrame.new(pa), asphalt, Enum.Material.Asphalt, true)
	end

	-- Pianos y muros de neumáticos por fuera de las curvas cerradas
	local curbs = Builder.model("Pianos", root)
	local barriers = Builder.model("Neumaticos", root)
	for i = 1, #pts do
		local turn = turnAt(pts, i) + turnAt(pts, i % #pts + 1)
		if math.abs(turn) > math.rad(14) then
			local a, b = pts[i], pts[i % #pts + 1]
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(dx * dx + dz * dz)
			-- a la derecha de la marcha: (-dz, dx)/len; fuera de la curva = contrario al giro
			local side = if turn > 0 then -1 else 1
			local nx, nz = -dz / len * side, dx / len * side
			local mx, mz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
			local dir = world(b[1], b[2]) - world(a[1], a[2])
			local curbPos = world(mx + nx * (W / 2 + 0.8), mz + nz * (W / 2 + 0.8), 1 + Karting.ASPHALT_TOP - 0.45)
			Kit.part(curbs, "Curb", Vector3.new(1.6, 0.9, len), Kit.along(curbPos, dir), if i % 2 == 0 then rgb(210, 40, 40) else Kit.WHITE, Enum.Material.SmoothPlastic)
			local wallA = world(a[1] + nx * (W / 2 + 7), a[2] + nz * (W / 2 + 7), 0)
			local wallB = world(b[1] + nx * (W / 2 + 7), b[2] + nz * (W / 2 + 7), 0)
			Kit.tyreWall(barriers, wallA, wallB, if i % 3 == 0 then rgb(220, 40, 40) else nil)
		end
	end

	-- Meta: línea a cuadros y pórtico con el semáforo
	local gates = KartTrack.gates(KartTrack.centerline(4))
	local g1 = gates[1]
	local meta = Kit.model("Meta", root)
	for k = 0, 5 do
		local z = -W / 2 + (k + 0.5) * W / 6
		Kit.decor(meta, "Checker", Vector3.new(1.5, 0.05, W / 6), at(g1[1] + (if k % 2 == 0 then -0.75 else 0.75), g1[2] + z) * CFrame.new(0, 1 + Karting.ASPHALT_TOP + 0.03, 0), if k % 2 == 0 then Kit.WHITE else rgb(20, 20, 22))
	end
	for _, s in { -1, 1 } do
		Kit.part(meta, "GantryPost", Vector3.new(1, 12, 1), at(g1[1], g1[2] + s * (W / 2 + 3)) * CFrame.new(0, 6, 0), rgb(220, 220, 225), Enum.Material.Metal)
	end
	local beam = Kit.part(meta, "GantryBeam", Vector3.new(1.4, 2, W + 7), at(g1[1], g1[2]) * CFrame.new(0, 12.5, 0), rgb(30, 30, 34), Enum.Material.Metal)
	Builder.sign(beam, "KARTING DE SAN ROQUE", Enum.NormalId.Left, Kit.WHITE)
	Builder.sign(beam, "KARTING DE SAN ROQUE", Enum.NormalId.Right, Kit.WHITE)
	for k = 1, 3 do
		Kit.decor(meta, "StartLight", Vector3.new(0.6, 1.2, 1.2), at(g1[1] - 0.8, g1[2] - 3 + (k - 1) * 3) * CFrame.new(0, 12.5, 0), rgb(60, 20, 20), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, Tags = { "OcioKartLight" }, Attributes = { Light = k } })
	end

	-- Boxes al norte: caseta, taquilla, estantes de ruedas, karts de exposición y tablón
	local pit = Kit.model("Boxes", root)
	local P = Karting.PIT
	Kit.part(pit, "PitFloor", Vector3.new(56, 0.6, 30), at(P.X, P.Z + 4) * CFrame.new(0, 0.4, 0), rgb(150, 150, 155), Enum.Material.Concrete)
	Kit.part(pit, "PitWall", Vector3.new(56, 10, 1), at(P.X, P.Z - 10) * CFrame.new(0, 5.5, 0), rgb(230, 230, 225), Enum.Material.Concrete)
	Kit.part(pit, "PitRoof", Vector3.new(58, 0.8, 16), at(P.X, P.Z - 2) * CFrame.new(0, 10.8, 0), rgb(200, 40, 40), Enum.Material.Metal)
	for _, x in { -27, -9, 9, 27 } do
		Kit.part(pit, "PitPillar", Vector3.new(0.8, 10, 0.8), at(P.X + x, P.Z + 5.5) * CFrame.new(0, 5.5, 0), Kit.METAL, Enum.Material.Metal)
	end
	local sign = Kit.decor(pit, "PitSign", Vector3.new(30, 2.2, 0.3), at(P.X, P.Z + 6) * CFrame.new(0, 12.4, 0), rgb(30, 30, 34))
	Builder.sign(sign, "BOXES · KARTING DE SAN ROQUE", Enum.NormalId.Back, Kit.WHITE)
	Builder.sign(sign, "BOXES · KARTING DE SAN ROQUE", Enum.NormalId.Front, Kit.WHITE)
	for _, x in { -24, 24 } do
		Kit.part(pit, "TyreRack", Vector3.new(4, 5, 2), at(P.X + x, P.Z - 7.5) * CFrame.new(0, 3, 0), rgb(28, 28, 30), Enum.Material.Rubber, { Tags = { "Pickup_Boxes" } })
	end
	for i, x in { -12, 0, 12 } do
		local cf = at(P.X + x, P.Z + 2, SOUTH) * CFrame.new(0, 0.7, 0)
		local kart = Rides.build("Kart", pit, cf, ({ rgb(230, 50, 40), rgb(30, 120, 220), rgb(250, 190, 30) })[i])
		kart.Name = "PitKart"
		local frame = kart:FindFirstChild("Frame")
		if frame then
			frame:AddTag("Dropoff_Boxes")
		end
	end
	-- Taquilla
	local D = Karting.DESK
	local desk = Kit.part(pit, "KartDesk", Vector3.new(8, 3.6, 2.4), at(D.X, D.Z) * CFrame.new(0, 1.8, 0), rgb(200, 40, 40), Enum.Material.SmoothPlastic, { Tags = { "OcioKartDesk" } })
	Kit.part(pit, "DeskRoof", Vector3.new(9, 0.4, 5), at(D.X, D.Z + 0.8) * CFrame.new(0, 7.6, 0), rgb(30, 30, 34), Enum.Material.Metal)
	for _, x in { -4, 4 } do
		Kit.decor(pit, "DeskPost", Vector3.new(0.3, 7.4, 0.3), at(D.X + x, D.Z + 3) * CFrame.new(0, 3.7, 0), Kit.METAL, Enum.Material.Metal)
	end
	local deskSign = Kit.decor(pit, "DeskSign", Vector3.new(8, 1.4, 0.2), at(D.X, D.Z - 1.3) * CFrame.new(0, 6.6, 0), rgb(250, 250, 245))
	Builder.sign(deskSign, ("KARTS · %d € la tanda"):format(KartTrack.Entry), Enum.NormalId.Back, rgb(170, 30, 30))
	desk:SetAttribute("Entry", KartTrack.Entry)
	Props.jobBoard(pit, at(P.X + 34, P.Z - 4, SOUTH), "Boxes", "MECÁNICO/A DE BOXES")

	-- Clasificación (KartService la rellena)
	local board = Kit.sign(pit, at(D.X - 16, D.Z - 2, NORTH), "🏁 MEJORES VUELTAS", 10, 7, rgb(20, 24, 32))
	board.Name = "KartBoard"
	board:AddTag("OcioKartBoard")

	-- Grada frente a la meta (al sur, mirando al norte) y focos dentro del óvalo
	Kit.part(root, "Grada", Vector3.new(90, 5, 8), at(0, 116, NORTH) * CFrame.new(0, 2.5, 0), rgb(170, 170, 176), Enum.Material.Concrete, { ClassName = "WedgePart" })
	for _, p in { { 0, 45 }, { -110, 20 }, { 110, 30 }, { -60, -40 }, { P.X - 40, P.Z } } do
		Kit.floodlight(root, at(p[1], p[2]), 18)
	end
	Kit.sign(root, at(-20, -118, NORTH), "🏎️ KARTING DE SAN ROQUE · taquilla en boxes", 12, 2.4, rgb(170, 30, 30))
	return root
end

return Karting
