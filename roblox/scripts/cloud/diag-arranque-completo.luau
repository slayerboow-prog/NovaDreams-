-- diag-arranque-completo: arranca TODO como Main.server.luau (mundo, assets, servicios y casa de Cosme) y lista cada error y aviso
--
-- Diagnóstico de la v95 (docs/diagnostico-v95.md). A diferencia de "arranque" (solo mundo y servicios) y
-- "diag-modulos" (solo assets, y solo lo que lleva etiqueta), aquí va todo a la vez y en el mismo orden
-- que Main.server.luau, cada paso en su pcall, y se guarda TODO lo que sale en la consola (errores con
-- su traza de ScriptContext). Al final: recuentos de assets (coches, naturaleza, ciudad, interiores,
-- casa de Cosme) y la historia validada en el servidor (Validate.report, lo mismo que hace
-- LifeStoryService.init). No hay jugadores: no se puede empezar una historia de verdad.
--
-- Uso: bash scripts/cloud-test.sh --version 95 -v diag-arranque-completo

local Cloud = Cloud :: any
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")

local World = Cloud.Server:WaitForChild("World")
local Shared = Cloud.Shared

local function line(s: string)
	print("[diag] " .. s)
end

---------------------------------------------------------------------
-- 0) Todo lo que sale en la consola
---------------------------------------------------------------------
local errores: { string } = {}
local avisos: { string } = {}
local visto: { [string]: number } = {}
local function guardar(lista: { string }, texto: string)
	texto = string.sub(texto, 1, 600)
	if visto[texto] then
		visto[texto] += 1
		return
	end
	visto[texto] = 1
	if #lista < 300 then
		table.insert(lista, texto)
	end
end
LogService.MessageOut:Connect(function(message, kind)
	if string.sub(message, 1, 7) == "[diag] " then
		return
	end
	if kind == Enum.MessageType.MessageError then
		guardar(errores, message)
	elseif kind == Enum.MessageType.MessageWarning then
		guardar(avisos, message)
	end
end)
ScriptContext.Error:Connect(function(message, trace)
	local where = string.gsub(trace or "", "\n", " | ")
	guardar(errores, "[ScriptContext] " .. message .. (if where ~= "" then " @ " .. where else ""))
end)

---------------------------------------------------------------------
-- 1) Lo mismo que Main.server.luau
---------------------------------------------------------------------
local pasos: { { name: string, ok: boolean, err: string?, s: number } } = {}
local enMarcha: { [string]: boolean } = {}
local function paso(name: string, fn: () -> ())
	local t = os.clock()
	local ok, err = pcall(fn)
	table.insert(pasos, { name = name, ok = ok, err = if ok then nil else tostring(err), s = os.clock() - t })
	if not ok then
		line(("PASO %s: ERROR %s"):format(name, tostring(err)))
	end
end
local function hilo(name: string, fn: () -> ())
	enMarcha[name] = true
	task.spawn(function()
		paso(name, fn)
		enMarcha[name] = nil
	end)
end

local TerrainBuilder = require(World.TerrainBuilder) :: any
local TownBuilder = require(World.TownBuilder) :: any
paso("TerrainBuilder.build", function()
	TerrainBuilder.build()
end)
paso("Ciudad (workspace.Town)", function()
	if not workspace:FindFirstChild("Town") then
		TownBuilder.build()
	end
end)
paso("Decor.dressTown", function()
	local built = workspace:FindFirstChild("Town")
	if built then
		require(World.Kit.Decor).dressTown(built)
	end
end)
paso("Polish.surfaces", function()
	local built = workspace:FindFirstChild("Town")
	local Polish = require(World.Kit.Polish) :: any
	if built and (built:GetAttribute("SurfaceVersion") or 0) < Polish.SurfaceVersion then
		Polish.surfaces(built)
	end
end)
hilo("MaterialLook.start", function()
	require(World.Kit.MaterialLook).start(workspace:FindFirstChild("Town"))
end)
hilo("UserMaterials.start (+StreetDress)", function()
	require(World.UserMaterials).start(nil, function(service, library, load, unpack)
		require(World.StreetDress).start(service, library, load, unpack, nil, require(World.Region).Highways)
	end)
end)
hilo("SkyAssets.start", function()
	require(World.SkyAssets).start()
end)
hilo("SkyLoader.start", function()
	require(World.SkyLoader).start()
end)
hilo("Images.resolve (grieta y ropa)", function()
	local Images = require(Shared.Images) :: any
	Images.resolve(require(Shared.RiftTextureIds))
	Images.resolve(require(Shared.OutfitIds))
end)
paso("TerrainBuilder.removeGroundPart", function()
	TerrainBuilder.removeGroundPart()
end)
paso("DreamIsland.build", function()
	require(World.Kit.DreamIsland).build()
end)
local segments = {}
paso("Ambient.publish", function()
	local Roads = require(World.Kit.Roads) :: any
	for _, segment in Roads.segments() do
		table.insert(segments, { A = segment.A, B = segment.B, Kind = segment.Kind, Width = Roads.Kinds[segment.Kind].Road, Walk = Roads.Kinds[segment.Kind].Walk })
	end
	require(World.Ambient).publish(TownBuilder.roads(), segments)
end)
hilo("MeshLibrary.start", function()
	require(World.MeshLibrary).start(segments)
end)
hilo("NatureAssets.start", function()
	require(World.NatureAssets).start()
end)
hilo("WorkshopProps.start", function()
	require(World.WorkshopProps).start()
end)
hilo("UserArsenal.start", function()
	require(World.UserArsenal).start()
end)
hilo("InteriorProps.start", function()
	require(World.InteriorProps).start()
end)
hilo("Buildings3D.start", function()
	require(World.Buildings3D).start(segments)
end)
hilo("CityAssets.start", function()
	require(World.CityAssets).start()
end)
hilo("MissionZones.start", function()
	require(World.MissionZones).start()
end)

local servicios = Cloud.arrancarServicios()
hilo("CosmeHouse.Start.start", function()
	require(World.CosmeHouse.Start).start()
end)
line("Servidor listo (como «[Real Life Simulator] Servidor listo ✅»)")

---------------------------------------------------------------------
-- 2) Esperar a lo que sigue en segundo plano
---------------------------------------------------------------------
local t0 = os.clock()
while next(enMarcha) and Cloud.quedan() > 45 do
	task.wait(2)
end
-- (CityAssets se queda escuchando las salas: su start no vuelve; se da margen igualmente)
while Cloud.quedan() > 45 and os.clock() - t0 < 150 do
	task.wait(2)
end
local siguen = {}
for name in enMarcha do
	table.insert(siguen, name)
end
table.sort(siguen)
line(("Espera: %.0f s; siguen en marcha: %s"):format(os.clock() - t0, if #siguen > 0 then table.concat(siguen, ", ") else "nada"))

---------------------------------------------------------------------
-- 3) Recuentos
---------------------------------------------------------------------
local function contar(root: Instance?, pred: (Instance) -> boolean): number
	local n = 0
	if root then
		for _, d in root:GetDescendants() do
			if pred(d) then
				n += 1
			end
		end
	end
	return n
end
local function esPieza(d: Instance): boolean
	return d:IsA("BasePart")
end
local recuento: { [string]: string } = {}
local town = workspace:FindFirstChild("Town")

pcall(function()
	local CarBodies = require(World.Kit.CarBodies) :: any
	local store = ServerStorage:FindFirstChild("CarBodies")
	recuento.CarBodies = ("estado %s, %d carrocerías"):format(tostring(CarBodies.State), if store then #store:GetChildren() else 0)
end)
pcall(function()
	local NatureAssets = require(World.NatureAssets) :: any
	local lib = NatureAssets.load()
	local total = 0
	for _, l in lib or {} do
		total += #l
	end
	recuento.NatureAssets = ("%d plantillas, %d de %d packs"):format(total, #NatureAssets.Log, #NatureAssets.Packs)
end)
pcall(function()
	local placed = town and town:FindFirstChild("ActivosCiudad")
	recuento.CityAssets = ("Town.ActivosCiudad: %d hijos, %d piezas"):format(if placed then #placed:GetChildren() else 0, contar(placed, esPieza))
end)
pcall(function()
	local n = 0
	if town then
		for _, d in town:GetDescendants() do
			if d.Name == "MueblesValmar" then
				n += #d:GetChildren()
			end
		end
	end
	recuento.InteriorProps = ("%d objetos en carpetas MueblesValmar"):format(n)
end)
pcall(function()
	local interiores = workspace:FindFirstChild("Interiores")
	recuento.Interiores = ("workspace.Interiores: %s, %d hijos, %d piezas"):format(tostring(interiores ~= nil), if interiores then #interiores:GetChildren() else 0, contar(interiores, esPieza))
end)
pcall(function()
	local houses = CollectionService:GetTagged("CosmeHouse")
	local house = houses[1]
	local detalle = {}
	if house then
		table.insert(detalle, ("%s, %d descendientes, %d piezas"):format(house:GetFullName(), #house:GetDescendants(), contar(house, esPieza)))
		local kids = {}
		for _, c in house:GetChildren() do
			table.insert(kids, ("%s(%d)"):format(c.Name, #c:GetDescendants()))
		end
		table.sort(kids)
		table.insert(detalle, "hijos: " .. table.concat(kids, ", "))
		table.insert(detalle, ("prompts %d, luces %d, StorySpot %d"):format(
			contar(house, function(d) return d:IsA("ProximityPrompt") end),
			contar(house, function(d) return d:IsA("Light") end),
			contar(house, function(d) return string.sub(d.Name, 1, 10) == "StorySpot_" end)))
	end
	local npc = {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and string.find(string.lower(d.Name), "cosme", 1, true) then
			table.insert(npc, d:GetFullName())
		end
	end
	table.insert(detalle, ("NPC Cosme: %d (%s)"):format(#npc, table.concat(npc, ", ")))
	recuento.CasaCosme = ("%d con etiqueta CosmeHouse; %s"):format(#houses, table.concat(detalle, "; "))
end)
pcall(function()
	local MaterialService = game:GetService("MaterialService")
	recuento.MaterialService = ("%d MaterialVariant"):format(contar(MaterialService, function(d) return d:IsA("MaterialVariant") end))
	-- (los mapas de MaterialLook vienen puestos en el archivo: aquí se ve el del asfalto)
	local asfalto = MaterialService:FindFirstChild("Asfalto") :: any
	local function leer(prop: string): string
		local ok, v = pcall(function()
			return asfalto[prop]
		end)
		return if ok then tostring(v) else "(no se puede leer)"
	end
	recuento.Asfalto = if asfalto
		then ("BaseMaterial=%s; ColorMap=%s; ColorMapContent=%s; NormalMap=%s; override Asphalt=%s"):format(
			leer("BaseMaterial"), leer("ColorMap"), leer("ColorMapContent"), leer("NormalMap"),
			tostring(MaterialService:GetBaseMaterialOverride(Enum.Material.Asphalt)))
		else "no hay variant «Asfalto»"
end)
recuento.Workspace = ("%d descendientes"):format(#workspace:GetDescendants())

---------------------------------------------------------------------
-- 4) Historia (sin jugador): lo que valida LifeStoryService.init
---------------------------------------------------------------------
local historia = {}
local okV, errV = pcall(function()
	local Validate = require(Shared.LifeStory.Validate) :: any
	local report = Validate.report()
	local bad = {}
	for id in report.BadQuests do
		table.insert(bad, id)
	end
	table.sort(bad)
	historia.errores = report.Errors
	historia.avisos = report.Warnings
	historia.bad = bad
	local Chapters = require(Shared.LifeStory.Chapters) :: any
	local Quests = require(Shared.LifeStory.Quests) :: any
	local nc, nq = 0, 0
	for _ in Chapters.All or Chapters do
		nc += 1
	end
	for _ in Quests.All or Quests do
		nq += 1
	end
	historia.tam = ("capítulos %d, misiones %d"):format(nc, nq)
end)
if not okV then
	historia.fallo = tostring(errV)
end

---------------------------------------------------------------------
-- 5) Informe
---------------------------------------------------------------------
local mal = {}
for _, p in pasos do
	line(("PASO %s: %s (%.1f s)%s"):format(p.name, if p.ok then "ok" else "ERROR", p.s, if p.err then " " .. p.err else ""))
	if not p.ok then
		table.insert(mal, p.name .. ": " .. tostring(p.err))
	end
end
Cloud.check(("Pasos de Main (mundo y assets): %d"):format(#pasos), #mal == 0, if #mal == 0 then "todos bien" else Cloud.lista(mal, 10))
local malS, lentos = {}, {}
for _, s in servicios do
	if not s.ok then
		table.insert(malS, s.name .. ": " .. tostring(s.err))
	elseif s.s >= 2 then
		table.insert(lentos, ("%s %.1f s"):format(s.name, s.s))
	end
end
Cloud.check(("Servicios (%d)"):format(#servicios), #malS == 0, if #malS == 0 then "todos bien" else Cloud.lista(malS, 10))
if #lentos > 0 then
	Cloud.aviso("Servicios lentos (≥ 2 s)", false, table.concat(lentos, ", "))
end
if #siguen > 0 then
	Cloud.aviso("Siguen en marcha al final", false, table.concat(siguen, ", "))
end

local keys = {}
for k in recuento do
	table.insert(keys, k)
end
table.sort(keys)
for _, k in keys do
	line(("RECUENTO %s: %s"):format(k, recuento[k]))
	Cloud.check("Recuento " .. k, true, string.sub(recuento[k], 1, 1500))
end

if historia.fallo then
	Cloud.check("Historia: Validate.report()", false, historia.fallo)
else
	for _, e in historia.errores do
		line("VALIDATE ERROR " .. e)
	end
	for _, w in historia.avisos do
		line("VALIDATE AVISO " .. w)
	end
	Cloud.check("Historia: Validate.report() sin errores (" .. historia.tam .. ")", #historia.errores == 0 and #historia.bad == 0,
		("%d errores, %d avisos, misiones que no se activan: %s"):format(#historia.errores, #historia.avisos, if #historia.bad > 0 then table.concat(historia.bad, ", ") else "ninguna"))
end
Cloud.salta("Empezar una historia con un jugador", "en un servidor de Open Cloud no hay jugadores (Players:CreateLocalPlayer no existe en servidor)")

for _, e in errores do
	line(("CONSOLA ERROR (x%d) %s"):format(visto[e] or 1, e))
end
for _, w in avisos do
	line(("CONSOLA AVISO (x%d) %s"):format(visto[w] or 1, w))
end
Cloud.check("Errores en la consola", #errores == 0, ("%d distintos"):format(#errores))
Cloud.aviso("Avisos en la consola", #avisos == 0, ("%d distintos"):format(#avisos))
return Cloud.resultado()
