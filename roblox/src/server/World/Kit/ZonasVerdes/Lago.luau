-- Lago: zona 17, «Orilla del Lago del Parque Natural», y el Camping que por fin se usa.
--   * ORILLA (x -3095..-2945, z -140..-40, al sur del sendero del lago): zona de pícnic (mesas con
--     «Comer de la mochila»), puesto de limonada, bancos mirando al lago, farolillos y la HOGUERA de
--     noche («Tostar malvaviscos», troncos alrededor: +diversión y +energía; luz, llamas y grillos).
--     Un monitor (WorkerSpot «Monitor») se queda junto al fuego.
--   * CAMPING (Kit/Icons.Camping, en el Oeste): cada tienda lleva su cama «CampTent» («Dormir en la
--     tienda»: se alquila y se duerme como en cualquier cama, SleepService); la hoguera de siempre pasa
--     a ser «Campfire» con troncos para sentarse; y cuatro parcelas libres («CampPitch») para montar
--     tu propia tienda gratis. La tienda que estaba encima de la hoguera se quita.

local Juegos = require(script.Parent.Juegos)
local Comun = require(script.Parent.Comun)
local Builder = require(script.Parent.Parent.Parent.Builder)

local Lago = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

Lago.Rect = { X0 = -3095, X1 = -2945, Z0 = -140, Z1 = -40 }
Lago.Top = -0.8

function Lago.build(world: Instance): Model
	local R = Lago.Rect
	local Y = Lago.Top
	local cx, cz = (R.X0 + R.X1) / 2, (R.Z0 + R.Z1) / 2
	-- Árboles del bosque del lago que caían dentro
	local roots = {}
	for _, name in { "Naturaleza", "Campo" } do
		local f = world:FindFirstChild(name)
		if f then
			table.insert(roots, f)
		end
	end
	Comun.prune(roots, { R }, 4)
	local m = Comun.site(world, "OrillaDelLago", 17)
	Comun.ground(m, CF(cx, 0, cz), R.X1 - R.X0, R.Z1 - R.Z0, Y, rgb(104, 150, 76))
	local function at(x: number, z: number, yaw: number?): CFrame
		return CF(cx + x, Y, cz + z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	end
	-- Claro de tierra para la hoguera y caminos
	Builder.decor({ Name = "Claro", Shape = Enum.PartType.Cylinder, Size = V(0.12, 26, 26), CFrame = at(20, -8) * CF(0, 0.06, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(150, 124, 92), Material = Enum.Material.Ground, Parent = m })
	Comun.path(m, (at(-74, 10)).Position, (at(74, 10)).Position, 5, Y, rgb(170, 140, 100), Enum.Material.Ground)
	Comun.path(m, (at(20, 10)).Position, (at(20, -48)).Position, 5, Y, rgb(170, 140, 100), Enum.Material.Ground)

	-- La hoguera (de noche) con seis troncos
	Juegos.campfire(m, at(20, -8), 6, 8)
	local spot = Builder.decor({ Name = "WorkerSpot", Size = V(1, 1, 1), CFrame = at(31, -8, 90) * CF(0, 0.5, 0), Transparency = 1, Parent = m })
	spot:SetAttribute("Role", "Monitor")
	spot:AddTag("WorkerSpot")

	-- Pícnic al oeste
	for i, p in { { -60, -22 }, { -42, -30 }, { -60, -2 }, { -40, 28 } } do
		Juegos.picnicTable(m, at(p[1], p[2], if i % 2 == 0 then 90 else 0))
	end
	Juegos.kiosk(m, at(-24, 30, 0), "LIMONADA · BOCADILLOS", { "Limonada", "Bocadillo" }, rgb(240, 190, 60))
	-- Bancos mirando al lago (al norte, -Z) y farolillos
	for _, x in { 52, 64 } do
		Juegos.bench(m, at(x, -40, 0))
	end
	for _, p in { { -70, 14 }, { -10, 14 }, { 48, 14 }, { 44, -30 } } do
		Comun.lantern(m, at(p[1], p[2]))
	end
	Comun.sign(m, at(-60, 44, 0), "ORILLA DEL LAGO · PÍCNIC Y HOGUERA", rgb(60, 100, 60), 16)
	return m
end

-- El Camping de siempre (Kit/Icons.Camping): tiendas que se usan, hoguera y parcelas libres
function Lago.camping(world: Instance): Model?
	local camping: Instance? = nil
	for _, d in world:GetDescendants() do
		if d:IsA("Model") and d.Name == "Camping" then
			camping = d
			break
		end
	end
	if not camping then
		return nil
	end
	local camp = camping :: Instance
	local m = Comun.site(world, "CampingVivo", "Camping")
	-- La hoguera de siempre
	local fire: BasePart? = nil
	for _, d in camp:GetChildren() do
		if d:IsA("BasePart") and d.Name == "Fire" then
			fire = d
		end
	end
	-- Las tiendas: pares de lonas «Tent»; la que estaba encima de la hoguera se quita
	local wedges = {}
	for _, d in camp:GetChildren() do
		if d:IsA("BasePart") and d.Name == "Tent" then
			table.insert(wedges, d)
		end
	end
	local used = {}
	local tents = {}
	for i, a in wedges do
		if not used[a] then
			used[a] = true
			local best, bestD = nil, 6
			for j = i + 1, #wedges do
				local b = wedges[j]
				if not used[b] then
					local dd = (a.CFrame.Position - b.CFrame.Position).Magnitude
					if dd < bestD then
						best, bestD = b, dd
					end
				end
			end
			if best then
				used[best] = true
				table.insert(tents, { a, best })
			end
		end
	end
	local count = 0
	for _, pair in tents do
		local center = (pair[1].CFrame.Position + pair[2].CFrame.Position) / 2
		local ground = math.min(pair[1].CFrame.Position.Y - pair[1].Size.Y / 2, pair[2].CFrame.Position.Y - pair[2].Size.Y / 2)
		local base = Vector3.new(center.X, ground, center.Z)
		if fire and (Vector3.new(fire.CFrame.Position.X, ground, fire.CFrame.Position.Z) - base).Magnitude < 9 then
			pair[1]:Destroy()
			pair[2]:Destroy()
		else
			count += 1
			Builder.part({
				Name = "CamaTienda",
				Size = V(3, 2, 3),
				CFrame = CF(base + V(0, 1, 0)),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				CastShadow = false,
				Tags = { "CampTent" },
				Attributes = { TentId = "Camping_" .. count, LieAt = base + V(0, 1.2, 0) },
				Parent = m,
			})
		end
	end
	m:SetAttribute("Tents", count)
	local cx, cz = 0, 0
	if fire then
		fire:AddTag("Campfire")
		fire:SetAttribute("Reason", "Campfire")
		cx, cz = fire.CFrame.Position.X, fire.CFrame.Position.Z - 10
		local fy = fire.CFrame.Position.Y - 1.5
		-- Troncos para sentarse alrededor (como en la hoguera del lago)
		for i = 1, 5 do
			local a = (i - 0.5) / 5 * math.pi * 2
			local spot = CF(fire.CFrame.Position.X, fy, fire.CFrame.Position.Z) * CFrame.Angles(0, a, 0) * CF(0, 0, -7)
			Builder.part({
				ClassName = "Seat",
				Name = "Tronco",
				Size = V(4.5, 1.1, 1.3),
				CFrame = spot * CF(0, 0.55, 0) * CFrame.Angles(0, math.pi, 0),
				Color = rgb(120, 86, 58),
				Material = Enum.Material.Wood,
				CanTouch = false,
				Tags = { "FunSeat" },
				Attributes = { FunPerMinute = 10, Reason = "Campfire", NightOnly = true, EnergyPerMinute = 3 },
				Parent = m,
			})
		end
	else
		local p = Comun.positionOf(camp)
		if p then
			cx, cz = p.X, p.Z
		end
	end
	-- Parcelas libres para montar tu tienda (fila al sur de las tiendas de alquiler)
	local rects = {}
	for k = 0, 3 do
		local x, z = cx - 70 + k * 35, cz + 58
		table.insert(rects, { X0 = x - 6, X1 = x + 6, Z0 = z - 6, Z1 = z + 6 })
	end
	Comun.prune({ camp }, rects, 2)
	for k, r in rects do
		local x, z = (r.X0 + r.X1) / 2, (r.Z0 + r.Z1) / 2
		local y = if fire then fire.CFrame.Position.Y - 1.5 else 0
		Builder.decor({ Name = "Parcela", Size = V(10, 0.1, 10), CFrame = CF(x, y + 0.05, z), Color = rgb(170, 140, 100), Material = Enum.Material.Ground, Parent = m })
		Builder.part({
			Name = "ParcelaLibre",
			Size = V(2, 1, 2),
			CFrame = CF(x, y + 0.5, z),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Tags = { "CampPitch" },
			Attributes = { PitchId = "Parcela_" .. k },
			Parent = m,
		})
		Builder.decor({ Name = "EstacaParcela", Size = V(0.3, 1.6, 0.3), CFrame = CF(x - 5, y + 0.8, z - 5), Color = rgb(240, 240, 240), Material = Enum.Material.Wood, Parent = m })
	end
	return m
end

return Lago
