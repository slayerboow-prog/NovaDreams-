-- test-vigia: la Estación Vigía, su laboratorio (investigación con Datos) y «La anomalía que canta»
-- (expansión «La Deriva», fase 2). lune run scripts/test-vigia.luau

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local Vector3 = roblox.Vector3
local check = L.check

local Stations = L.load("src/shared/Cosmos/Stations")
local Zone = L.load("src/shared/Cosmos/Zone")
local Layers = L.load("src/shared/Cosmos/Layers")
local Research = L.load("src/shared/Cosmos/Research")
local Canto = L.load("src/shared/Cosmos/Canto")

print("🛰 La Estación Vigía")
local v = Stations.ById.Vigia
check(v ~= nil and v.Lab == true and Layers.inColumn(v.Center) and v.Center.Y > Layers.SpaceY, "existe, con laboratorio, en la columna del espacio")
local farSectors = true
for _, s in Zone.Sectors do
	if (s.Center - v.Center).Magnitude < s.Radius + 600 then
		farSectors = false
	end
end
check(farSectors, "fuera de los sectores con patrullas (es una estación de ciencia)")
local farOthers = true
for _, s in Stations.List do
	if s ~= v and (s.Center - v.Center).Magnitude < 2500 then
		farOthers = false
	end
end
check(farOthers and Stations.dockAt(v.Dock) == v, "lejos de Alba y Cénit, y se atraca en su muelle")

print("🔬 Investigación")
check(Research.canBuy({}, "EscanerLargo") and not Research.canBuy({}, "LecturaFina"), "cada rama empieza por su primer nodo")
check(Research.canBuy({ EscanerLargo = 1 }, "LecturaFina") and select(2, Research.canBuy({ EscanerLargo = 1 }, "EscanerLargo")) == "Hecho", "el segundo pide el primero; lo hecho no se repite")
local fx0, fx = Research.effects({}), Research.effects({ EscanerLargo = 1, LecturaFina = 1, Reciclaje = 1, Desguace = 1, Aleaciones = 1, Contactos = 1 })
check(fx0.ScanRadius == 1 and fx0.DatosMult == 1 and fx0.ModuleMoney == 1 and fx0.ContractPay == 1, "sin investigar, nada cambia")
check(fx.ScanRadius > 1 and fx.DatosMult > 1 and fx.CompChance > 0 and fx.CompBonus > 0 and fx.ModuleMoney < 1 and fx.ContractPay > 1, "cada investigación da lo suyo")
local allDatos = true
for _, n in Research.Nodes do
	if n.Datos <= 0 then
		allDatos = false
	end
end
check(allDatos and #Research.Nodes == 6, "6 investigaciones en 3 ramas, todas cuestan Datos (los Datos sirven para algo)")

print("♫ La anomalía que canta")
check(not Canto.offer({ Completed = {} }) and Canto.offer({ Completed = { Varkun_02_Escarcha = 1 }, Active = {} }) and not Canto.offer({ Completed = { Varkun_02_Escarcha = 1, [Canto.MissionId] = 1 } }), "se ofrece después del prólogo de Varkun, una vez")
local insideSector = false
for _, s in Zone.Sectors do
	if (s.Center - Canto.AnomalyPos).Magnitude < s.Radius then
		insideSector = true
	end
end
check(Layers.inColumn(Canto.AnomalyPos) and not insideSector and Zone.collide(Canto.AnomalyPos, 6) == nil, "la anomalía está en el espacio, sin patrullas y sin chocar con nada")
check(Canto.inScan(Canto.AnomalyPos + Vector3.new(0, 0, Canto.ScanRadius - 10)) and not Canto.inScan(Canto.AnomalyPos + Vector3.new(0, 0, Canto.ScanRadius + 10)), "zona de escaneo con su radio")
local ph = Canto.phaseOf({ Active = { [Canto.MissionId] = { Step = 2 } } })
check(ph and ph.Step == "Scanned" and Canto.row(ph, 15).Progress:find("50") ~= nil, "la fila del HUD enseña el escaneo en %")
local missions = L.load("src/shared/LifeStory/Misiones/Deriva_ActoI")
local m
for _, x in missions do
	if x.Id == Canto.MissionId then
		m = x
	end
end
check(m and #m.Steps == #Canto.Steps and m.Steps[4].Id == "Deriva_Vigia_Ivo" and table.find(m.Rewards.Flags, Research.UnlockFlag) ~= nil, "la misión acaba con la cinemática de Ivo y abre el laboratorio")
local scenes = L.load("src/shared/LifeStory/Happenings/Deriva")
check(scenes.Deriva_Vigia_Ivo ~= nil and scenes.Deriva_Vigia_Ivo.Anchors.Lab == "Place:Estacion_Vigia_Laboratorio", "la cinemática pasa en el laboratorio de la Vigía")
check(fs.isFile("src/shared/LifeStory/Guiones/Deriva_00_Canto.luau"), "guion de radio generado")
local client = fs.readFile("src/client/Controllers/DerelictClient.luau")
check(string.find(client, "Interferencia", 1, true) ~= nil and string.find(client, "LightningFlashes", 1, true) ~= nil, "interferencia en pantalla, sin destellos si el jugador los ha apagado")
local world = fs.readFile("src/server/World/SpaceWorld.luau")
check(string.find(world, "if st.Lab then", 1, true) ~= nil and string.find(world, "Estacion_%s_%s", 1, true) ~= nil, "la estación con laboratorio y sus sitios para las escenas")

L.finish("test-vigia")
