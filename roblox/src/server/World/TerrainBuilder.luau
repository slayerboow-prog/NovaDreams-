-- TerrainBuilder: sustituye el suelo de piezas por terreno real de Roblox
-- (hierba con textura y colinas en el horizonte). Se ejecuta al arrancar el servidor,
-- porque el terreno no se puede guardar desde el script que genera el archivo.

local TerrainBuilder = {}

function TerrainBuilder.build()
	local terrain = workspace.Terrain
	-- Sin briznas de hierba: atravesarían las calles y los suelos.
	-- (Desde un script no siempre se puede cambiar: por eso también va en default.project.json.)
	pcall(function()
		terrain.Decoration = false
	end)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(98, 146, 70))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(128, 122, 112))

	-- Llanura de la región: la superficie queda en Y = -1, un poco por DEBAJO de las calles
	-- (que empiezan en Y = 0). Si quedara justo en 0, el césped asoma y tapa calles y suelos.
	terrain:FillBlock(CFrame.new(-380, -5, 0), Vector3.new(4040, 8, 4800), Enum.Material.Grass)

	-- Debajo de las ciudades y de las carreteras, tierra en vez de hierba: la tierra no tiene briznas,
	-- así que nada puede asomar entre las piezas (ahí el suelo de verdad son las losas de césped y el asfalto)
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(86, 120, 62))
	local Region = require(script.Parent.Region)
	local under = { { 0, 20, 760, 520 } } -- Valmar Centro: centro X, centro Z, ancho, fondo
	for _, town in Region.Towns do
		table.insert(under, { town.Center.X, town.Center.Z, 730, 730 })
	end
	for _, road in Region.Highways do
		local length, mid = road.To - road.From + 40, (road.From + road.To) / 2
		if road.Axis == "X" then
			table.insert(under, { mid, road.At, length, 44 })
		else
			table.insert(under, { road.At, mid, 44, length })
		end
	end
	for _, r in under do
		terrain:FillBlock(CFrame.new(r[1], -5, r[2]), Vector3.new(r[3], 8, r[4]), Enum.Material.Ground)
	end

	-- Mar al este de Playa Dorada (fondo de arena y agua)
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(226, 206, 160))
	terrain:FillBlock(CFrame.new(1700, -4, 0), Vector3.new(120, 6, 4800), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(2100, -14, 0), Vector3.new(800, 8, 4800), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(2100, -5.5, 0), Vector3.new(800, 9, 4800), Enum.Material.Water)

	-- Colinas en el horizonte (menos en el lado del mar)
	local count = 60
	for i = 1, count do
		local angle = i / count * math.pi * 2
		if math.cos(angle) < 0.55 then
			local distance = 2300 + math.random(0, 200)
			local radius = 90 + math.random(0, 70)
			local center = Vector3.new(math.cos(angle) * distance - 300, -radius * 0.45, math.sin(angle) * distance)
			terrain:FillBall(center, radius, if math.random() < 0.2 then Enum.Material.Rock else Enum.Material.Grass)
		end
	end
end

-- Quita el suelo y el mar de piezas (solo servían para verlo en Studio)
function TerrainBuilder.removeGroundPart()
	local CollectionService = game:GetService("CollectionService")
	for _, part in CollectionService:GetTagged("EditOnly") do
		part:Destroy()
	end
end

return TerrainBuilder
