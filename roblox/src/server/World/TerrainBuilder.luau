-- TerrainBuilder: sustituye el suelo de piezas por terreno real de Roblox
-- (hierba con textura y colinas en el horizonte). Se ejecuta al arrancar el servidor,
-- porque el terreno no se puede guardar desde el script que genera el archivo.

local TerrainBuilder = {}

function TerrainBuilder.build()
	local terrain = workspace.Terrain
	-- Sin briznas de hierba: atravesarían las calles y los suelos
	pcall(function()
		terrain.Decoration = false
	end)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(98, 146, 70))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(128, 122, 112))

	-- Llanura: la superficie queda justo en Y = 0
	terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(1200, 8, 1200), Enum.Material.Grass)

	-- Colinas en el horizonte (cierran el mapa sin muros invisibles)
	local count = 44
	for i = 1, count do
		local angle = i / count * math.pi * 2
		local distance = 560 + math.random(0, 90)
		local radius = 70 + math.random(0, 60)
		local center = Vector3.new(math.cos(angle) * distance, -radius * 0.45, math.sin(angle) * distance)
		terrain:FillBall(center, radius, if math.random() < 0.2 then Enum.Material.Rock else Enum.Material.Grass)
	end
end

-- El suelo de piezas de la ciudad solo sirve para verla en Studio: en el juego se quita
function TerrainBuilder.removeGroundPart()
	local town = workspace:FindFirstChild("Town")
	local ground = town and town:FindFirstChild("Ground")
	if ground then
		ground:Destroy()
	end
end

return TerrainBuilder
