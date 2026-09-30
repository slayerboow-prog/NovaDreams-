-- arranque: ¿arranca el servidor del juego sin errores? (en un servidor de verdad de Roblox)
--
-- En estas pruebas Main.server.luau no se ejecuta solo, así que aquí se hace lo mismo que él, paso a
-- paso y cada uno en su pcall: el terreno, la ciudad, la decoración, la isla del sueño, los datos
-- del tráfico y luego cada servicio (DataService, …, ActionService) en el mismo orden.
-- Después se espera un poco (muchos servicios siguen preparándose en task.spawn) y se cuentan los
-- errores y avisos que han salido en la consola del servidor.
--
-- Uso: bash scripts/cloud-test.sh arranque

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local ESPERA = 25 -- segundos esperando a lo que los servicios dejan en marcha

Cloud.escuchar()

-- 1) Mundo
local pasos = Cloud.prepararMundo()
local malMundo = {}
local tMundo = 0
for _, p in pasos do
	tMundo += p.s
	if not p.ok then
		table.insert(malMundo, ("%s: %s"):format(p.name, p.err))
	end
end
Cloud.check("Mundo preparado (terreno, ciudad, decoración, isla, tráfico)", #malMundo == 0, if #malMundo == 0 then ("%d pasos en %.1f s"):format(#pasos, tMundo) else Cloud.lista(malMundo, 6))
Cloud.check("La ciudad viene dentro del juego publicado (workspace.Town)", workspace:FindFirstChild("Town") ~= nil, if workspace:FindFirstChild("Town") then ("%d piezas"):format(#workspace.Town:GetDescendants()) else "no está: el .rbxl se publicó sin construir (scripts/build-place.luau)")

-- 2) Servicios
local servicios = Cloud.arrancarServicios()
local mal, lentos, saltados, noPublicados = {}, {}, {}, {}
local tServicios = 0
for _, s in servicios do
	tServicios += s.s
	if s.noPublicado then
		table.insert(noPublicados, s.name)
	elseif s.saltado then
		table.insert(saltados, s.name)
	elseif not s.ok then
		table.insert(mal, ("%s: %s"):format(s.name, s.err))
	elseif s.s >= 3 then
		table.insert(lentos, ("%s %.1f s"):format(s.name, s.s))
	end
end
Cloud.check(("Servicios iniciados (%d)"):format(#servicios - #saltados - #noPublicados), #mal == 0, if #mal == 0 then ("todos bien en %.1f s"):format(tServicios) else ("%d fallan: %s"):format(#mal, Cloud.lista(mal, 10)))
if #lentos > 0 then
	Cloud.aviso("Servicios que tardan en iniciar (≥ 3 s)", false, Cloud.lista(lentos, 8))
end
if #noPublicados > 0 then
	Cloud.salta("Servicios nuevos aún no publicados", table.concat(noPublicados, ", ") .. " (están en Main.server.luau de esta rama, pero no en la última versión publicada: aún no publicado)")
end
if #saltados > 0 then
	Cloud.salta("Servicios no arrancados a propósito", table.concat(saltados, ", ") .. " (avisaría a los servidores del juego de verdad)")
end

-- 3) Lo que siguen haciendo los servicios en segundo plano
local heartbeats = 0
local conn = game:GetService("RunService").Heartbeat:Connect(function()
	heartbeats += 1
end)
task.wait(math.min(ESPERA, math.max(1, Cloud.quedan() - 20)))
conn:Disconnect()
Cloud.info("heartbeats_en_espera", heartbeats)

-- Cosas que el servidor deja hechas (si no están, algo se quedó a medias)
local function hay(name: string, where: Instance): boolean
	return where:FindFirstChild(name) ~= nil
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local esperado = {
	{ "Autobuses (workspace.Buses)", hay("Buses", workspace) },
	{ "Tráfico publicado (ReplicatedStorage.Ambient)", hay("Ambient", ReplicatedStorage) },
	{ "Metro (ReplicatedStorage.MetroState)", hay("MetroState", ReplicatedStorage) },
	{ "Cercanías (ReplicatedStorage.RailState)", hay("RailState", ReplicatedStorage) },
}
local faltan = {}
for _, e in esperado do
	if not e[2] then
		table.insert(faltan, e[1])
	end
end
Cloud.check("Lo que los servicios dejan preparado", #faltan == 0, if #faltan == 0 then "autobuses, tráfico, metro y cercanías" else "falta: " .. table.concat(faltan, ", "))

-- 4) Errores y avisos de la consola
local oido = Cloud.oido()
Cloud.check("Sin errores en la consola del servidor", #oido.errores == 0, if #oido.errores == 0 then "ninguno" else ("%d: %s"):format(#oido.errores, Cloud.lista(oido.errores, 10)))
Cloud.aviso("Sin avisos (warn) en la consola del servidor", #oido.avisos == 0, if #oido.avisos == 0 then "ninguno" else ("%d: %s"):format(#oido.avisos, Cloud.lista(oido.avisos, 10)))

Cloud.info("segundos_mundo", math.floor(tMundo * 10) / 10)
Cloud.info("segundos_servicios", math.floor(tServicios * 10) / 10)
Cloud.info("piezas_en_workspace", #workspace:GetDescendants())
return Cloud.resultado()
