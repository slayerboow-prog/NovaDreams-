-- transporte: ¿se mueven los autobuses y el metro, y van por el suelo y por la vía?
--
-- Arranca el servidor como Main.server.luau (mundo y servicios) y luego sigue durante ~30 s a un
-- autobús de cada línea y a un tren de metro de cada línea:
--   * que se muevan (no se quedan parados todo el rato),
--   * que tengan suelo o vía debajo (no se caen ni flotan),
--   * que no se hundan ni salten de golpe.
-- Los autobuses y trenes del juego van anclados y los mueve el servidor en cada Heartbeat (PivotTo),
-- así que se pueden seguir aunque la física no corra. Si en este servidor no llega ningún Heartbeat,
-- la prueba se salta (con una nota).
--
-- Uso: bash scripts/cloud-test.sh transporte

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local MUESTRA = 30 -- segundos siguiendo a los vehículos
local CADA = 0.5 -- segundos entre medidas
local BAJO_BUS = 8 -- studs: el suelo tiene que estar como mucho a esto por debajo del chasis
local BAJO_TREN = 10
local SALTO = 60 -- studs en medio segundo: más que esto es un salto raro (teletransporte)

Cloud.escuchar()
for _, p in Cloud.prepararMundo() do
	if not p.ok then
		Cloud.check("Preparar el mundo: " .. p.name, false, p.err)
	end
end
local malServicios = {}
for _, s in Cloud.arrancarServicios() do
	if not s.ok then
		table.insert(malServicios, s.name)
	end
end
if #malServicios > 0 then
	Cloud.aviso("Servicios que no arrancan (mira la prueba 'arranque')", false, table.concat(malServicios, ", "))
end

-- ¿Llegan Heartbeats? (sin ellos nada se mueve en este servidor)
local beats = 0
local conn = RunService.Heartbeat:Connect(function()
	beats += 1
end)
task.wait(2)
conn:Disconnect()
Cloud.info("heartbeats_en_2s", beats)
if beats == 0 then
	Cloud.salta("Autobuses y metro en marcha", "en este servidor de pruebas no corre RunService.Heartbeat: los vehículos no se mueven aquí")
	return Cloud.resultado()
end

-- Esperar a que BusService cree los autobuses (lo hace en un task.spawn)
local buses = workspace:FindFirstChild("Buses")
local hasta = os.clock() + 20
while os.clock() < hasta and (not buses or #buses:GetChildren() == 0) do
	task.wait(0.5)
	buses = workspace:FindFirstChild("Buses")
end

---------------------------------------------------------------------
-- Qué se sigue
---------------------------------------------------------------------
type Sample = { t: number, p: Vector3, suelo: number? }
type Seguido = { tipo: string, label: string, root: BasePart, model: Instance, bajo: number, samples: { Sample } }
local seguidos: { Seguido } = {}

local porLinea: { [string]: boolean } = {}
if buses then
	for _, model in buses:GetChildren() do
		if model:IsA("Model") and model.PrimaryPart then
			local line = tostring(model:GetAttribute("BusLine") or model.Name)
			if not porLinea["bus " .. line] then
				porLinea["bus " .. line] = true
				table.insert(seguidos, { tipo = "bus", label = "autobús " .. line, root = model.PrimaryPart, model = model, bajo = BAJO_BUS, samples = {} })
			end
		end
	end
end
for _, model in CollectionService:GetTagged("MetroTrain") do
	local car = model:FindFirstChild("Car1")
	local root = car and car:FindFirstChild("Root")
	if root and root:IsA("BasePart") then
		local line = tostring(model:GetAttribute("Line") or model.Name)
		if not porLinea["metro " .. line] then
			porLinea["metro " .. line] = true
			table.insert(seguidos, { tipo = "metro", label = "metro " .. line, root = root, model = model, bajo = BAJO_TREN, samples = {} })
		end
	end
end

local nBus, nMetro = 0, 0
for _, s in seguidos do
	if s.tipo == "bus" then
		nBus += 1
	else
		nMetro += 1
	end
end
Cloud.check("Hay autobuses del juego circulando (workspace.Buses)", nBus > 0, if nBus > 0 then ("%d líneas"):format(nBus) else "no hay ninguno")
Cloud.check("Hay trenes de metro (etiqueta MetroTrain)", nMetro > 0, if nMetro > 0 then ("%d líneas"):format(nMetro) else "no hay ninguno")
if #seguidos == 0 then
	return Cloud.resultado()
end

---------------------------------------------------------------------
-- Seguirlos
---------------------------------------------------------------------
local function sueloBajo(s: Seguido): number?
	local p = s.root.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { s.model, workspace:FindFirstChild("Buses") or s.model }
	params.RespectCanCollide = true
	local hit = workspace:Raycast(p + Vector3.new(0, 2, 0), Vector3.new(0, -(s.bajo + 40), 0), params)
	return if hit then p.Y - hit.Position.Y else nil
end

local duracion = math.min(MUESTRA, math.max(5, Cloud.quedan() - 15))
local t0 = os.clock()
while os.clock() - t0 < duracion do
	for _, s in seguidos do
		if s.root.Parent then
			table.insert(s.samples, { t = os.clock() - t0, p = s.root.Position, suelo = sueloBajo(s) })
		end
	end
	task.wait(CADA)
end

---------------------------------------------------------------------
-- Resultado de cada uno
---------------------------------------------------------------------
for _, s in seguidos do
	local n = #s.samples
	if n < 2 then
		Cloud.check(s.label, false, "ha desaparecido mientras se le seguía")
		continue
	end
	local recorrido, maxSalto, parado = 0, 0, 0
	local sinSuelo, alto = 0, 0
	local minY, maxY = math.huge, -math.huge
	for i, sample in s.samples do
		minY = math.min(minY, sample.p.Y)
		maxY = math.max(maxY, sample.p.Y)
		if sample.suelo == nil then
			sinSuelo += 1
		elseif sample.suelo > s.bajo then
			alto += 1
		end
		if i > 1 then
			local d = (sample.p - s.samples[i - 1].p).Magnitude
			recorrido += d
			maxSalto = math.max(maxSalto, d)
			if d < 0.05 then
				parado += 1
			end
		end
	end
	local problemas = {}
	if recorrido < 5 then
		table.insert(problemas, ("no se mueve (%.1f studs en %d s)"):format(recorrido, math.floor(duracion)))
	end
	if sinSuelo > 0 then
		table.insert(problemas, ("sin nada debajo en %d de %d medidas"):format(sinSuelo, n))
	end
	if alto > 0 then
		table.insert(problemas, ("flotando (más de %d studs sobre el suelo) en %d medidas"):format(s.bajo, alto))
	end
	if maxSalto > SALTO then
		table.insert(problemas, ("salto de %.0f studs de golpe"):format(maxSalto))
	end
	if s.tipo == "bus" and maxY - minY > 40 then
		table.insert(problemas, ("sube y baja %.0f studs (¿se cae?)"):format(maxY - minY))
	end
	local last = s.samples[n].p
	local detail = if #problemas == 0
		then ("%.0f studs en %d s, parado %d%% del tiempo, ahora en %s"):format(recorrido, math.floor(duracion), math.floor(parado / (n - 1) * 100), Cloud.v3(last))
		else table.concat(problemas, "; ") .. " — en " .. Cloud.v3(last)
	Cloud.check(s.label .. " se mueve y va por el suelo/la vía", #problemas == 0, detail)
end

local oido = Cloud.oido()
local errTransporte = {}
for _, e in oido.errores do
	if string.find(e, "Bus") or string.find(e, "Metro") or string.find(e, "Rail") then
		table.insert(errTransporte, e)
	end
end
Cloud.check("Sin errores de BusService/MetroService/RailService", #errTransporte == 0, if #errTransporte == 0 then "ninguno" else Cloud.lista(errTransporte, 6))
Cloud.info("errores_totales_en_consola", #oido.errores)
return Cloud.resultado()
