-- AmbientShips (cliente): las naves que vuelan en círculos sobre las ciudades de los planetas (las pone
-- World/PlanetMetroBuilder con la etiqueta «NaveAmbiente» y los atributos Centro, Radio, Altura, Velocidad
-- y Fase). Solo decorado: se mueven en TU pantalla (sin red) y solo las que están cerca de la cámara.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local AmbientShips = {}

AmbientShips.Range = 2600 -- studs de la cámara al centro de su vuelo

local ships: { Model } = {}

local function add(m: Instance)
	if m:IsA("Model") and not table.find(ships, m) then
		table.insert(ships, m)
	end
end

local function remove(m: Instance)
	local i = table.find(ships, m :: any)
	if i then
		table.remove(ships, i)
	end
end

function AmbientShips.init()
	for _, m in CollectionService:GetTagged("NaveAmbiente") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("NaveAmbiente"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("NaveAmbiente"):Connect(remove)
	RunService.RenderStepped:Connect(function()
		if #ships == 0 then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local t = workspace:GetServerTimeNow()
		local camPos = cam.CFrame.Position
		for _, m in ships do
			local center = m:GetAttribute("Centro")
			if typeof(center) == "Vector3" and (center - camPos).Magnitude < AmbientShips.Range and m.PrimaryPart then
				local r = tonumber(m:GetAttribute("Radio")) or 200
				local h = tonumber(m:GetAttribute("Altura")) or 150
				local w = tonumber(m:GetAttribute("Velocidad")) or 0.08
				local a = (tonumber(m:GetAttribute("Fase")) or 0) + t * w
				local pos = center + Vector3.new(math.cos(a) * r, h + math.sin(t * 0.6 + a) * 6, math.sin(a) * r)
				-- mirando hacia donde va (la tangente del círculo), un poco inclinada hacia dentro
				local dir = Vector3.new(-math.sin(a), 0, math.cos(a)) * (if w >= 0 then 1 else -1)
				local cf = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, 0, if w >= 0 then 0.18 else -0.18)
				m:PivotTo(cf)
			end
		end
	end)
end

return AmbientShips
