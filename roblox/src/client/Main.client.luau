-- Punto de entrada del cliente: crea la interfaz y escucha los avisos del servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent.UI.Hud)
local Store = require(script.Parent.UI.Store)
local SpeechBubbles = require(script.Parent.UI.SpeechBubbles)
local TaskMarker = require(script.Parent.Controllers.TaskMarker)
local Ambient = require(script.Parent.Controllers.Ambient)
local Weather = require(script.Parent.Controllers.Weather)
local Wildlife = require(script.Parent.Controllers.Wildlife)
local Nudge = require(script.Parent.Controllers.Nudge)
local StoryAudio = require(script.Parent.Controllers.StoryAudio)
local DayLight = require(script.Parent.Controllers.DayLight)
local LifeStory = require(script.Parent.Controllers.LifeStory)
local Prologue = require(script.Parent.Controllers.Prologue)
local Baby = require(script.Parent.Controllers.Baby)
local ClassUI = require(script.Parent.Controllers.ClassUI)
local MapUI = require(script.Parent.Controllers.MapUI)
local InventoryUI = require(script.Parent.Controllers.InventoryUI)
local DialogueUI = require(script.Parent.Controllers.DialogueUI)
local DebugHud = require(script.Parent.Controllers.DebugHud)
local MiniGameUI = require(script.Parent.Controllers.MiniGameUI)
local SceneClient = require(script.Parent.Controllers.SceneClient)
local Vehicles = require(script.Parent.Controllers.Vehicles)
local Arcade = require(script.Parent.Controllers.Arcade)
local DrivingSchool = require(script.Parent.Controllers.DrivingSchool)
local Restaurant = require(script.Parent.Controllers.Restaurant)
local Character = require(script.Parent.Controllers.Character)
local Prompts = require(script.Parent.Controllers.Prompts)
local Cinematics = require(script.Parent.Controllers.Cinematics)
local NearShadows = require(script.Parent.Controllers.NearShadows)
local Actions = require(script.Parent.Controllers.Actions)
local Driving = require(script.Parent.Controllers.Driving)
local VehicleLights = require(script.Parent.Controllers.VehicleLights)
local WheelSpin = require(script.Parent.Controllers.WheelSpin)
local SoundFx = require(script.Parent.Controllers.SoundFx)
local SupermarketUI = require(script.Parent.Controllers.SupermarketUI)
local CafeUI = require(script.Parent.Controllers.CafeUI)
local PostUI = require(script.Parent.Controllers.PostUI)
local GarbageUI = require(script.Parent.Controllers.GarbageUI)
local MedicalUI = require(script.Parent.Controllers.MedicalUI)
local PoliceUI = require(script.Parent.Controllers.PoliceUI)
local FireUI = require(script.Parent.Controllers.FireUI)
local CinemaUI = require(script.Parent.Controllers.CinemaUI)
local HotelUI = require(script.Parent.Controllers.HotelUI)
local TradeUI = require(script.Parent.Controllers.TradeUI)
local PlayerMenuUI = require(script.Parent.Controllers.PlayerMenuUI)
local FishingUI = require(script.Parent.Controllers.FishingUI)
local MetroUI = require(script.Parent.Controllers.MetroUI)
local MetroMapUI = require(script.Parent.Controllers.MetroMapUI)
local MetroTrains = require(script.Parent.Controllers.MetroTrains)
local Flights = require(script.Parent.Controllers.Flights)
local RailUI = require(script.Parent.Controllers.RailUI)
local GymUI = require(script.Parent.Controllers.GymUI)
local GymMotion = require(script.Parent.Controllers.GymMotion)
local DivingUI = require(script.Parent.Controllers.DivingUI)
local SeaBiome = require(script.Parent.Controllers.SeaBiome)
local SeaEventsUI = require(script.Parent.Controllers.SeaEventsUI)
local JobPrompts = require(script.Parent.Controllers.JobPrompts)
local BusUI = require(script.Parent.Controllers.BusUI)
local BusBoards = require(script.Parent.Controllers.BusBoards)
local ActorLife = require(script.Parent.Controllers.ActorLife)
local AgeMotion = require(script.Parent.Controllers.AgeMotion)
local ReactMotion = require(script.Parent.Controllers.ReactMotion)
local Locomotion = require(script.Parent.Controllers.Locomotion)
local Stances = require(script.Parent.Controllers.Stances)
local Parkour = require(script.Parent.Controllers.Parkour)
local FootCamera = require(script.Parent.Controllers.FootCamera)
local RideCamera = require(script.Parent.Controllers.RideCamera)
local RidePose = require(script.Parent.Controllers.RidePose)
local ObjectMotion = require(script.Parent.Controllers.ObjectMotion)
local WetWorld = require(script.Parent.Controllers.WetWorld)
local StoneThrow = require(script.Parent.Controllers.StoneThrow)
local CombatController = require(script.Parent.Controllers.CombatController)
local WeaponController = require(script.Parent.Controllers.WeaponController)
local WantedUI = require(script.Parent.Controllers.WantedUI)
local DeathUI = require(script.Parent.Controllers.DeathUI)
local InstitutionsUI = require(script.Parent.Controllers.InstitutionsUI)
local InteriorUI = require(script.Parent.Controllers.InteriorUI)
local EconomyUI = require(script.Parent.Controllers.EconomyUI)
local UseMotion = require(script.Parent.Controllers.UseMotion)
local InteractClient = require(script.Parent.Controllers.InteractClient)
local FridgeUI = require(script.Parent.Controllers.FridgeUI)
local HousingUI = require(script.Parent.Controllers.HousingUI)
local LiftRide = require(script.Parent.Controllers.LiftRide)
local Joystick = require(script.Parent.Controllers.Joystick)
local Gps = require(script.Parent.Controllers.Gps)
local HelpUI = require(script.Parent.Controllers.HelpUI)
local Guide = require(script.Parent.Controllers.Guide)
local CommandMenu = require(script.Parent.Commands.CommandMenu)
local DefaultCommands = require(script.Parent.Commands.DefaultCommands)
local CanonMarkers = require(script.Parent.Controllers.CanonMarkers)
local CityErrands = require(script.Parent.Controllers.CityErrands)
local NameTags = require(script.Parent.Controllers.NameTags)

local gui = Hud.init(function()
	Store.open()
end)
-- (cada arranque protegido: si uno falla, los demás controladores siguen arrancando)
local function safeInit(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn(("[Main] %s no ha arrancado: %s"):format(name, tostring(err)))
	end
end
safeInit("Store", function()
	Store.init(gui)
end)
safeInit("TaskMarker", TaskMarker.init)
-- Modo pruebas (solo el dueño y los testers; se abre con /pruebas o TesterPanel.toggle())
safeInit("TesterPanel", function()
	require(script.Parent.UI.TesterPanel).init()
end)
safeInit("Perf", function()
	require(script.Parent.UI.Perf).stripDetails() -- móvil: sin los detalles pequeños de la calle
end)
safeInit("DayLight", DayLight.init) -- luz realista según la hora (amanecer, mediodía, atardecer, noche)
safeInit("Horizon", function()
	require(script.Parent.Controllers.Horizon).init() -- montañas del fondo (siluetas lejanas y sierra al otro lado del mar)
end)
safeInit("SkyRift", function()
	require(script.Parent.Controllers.SkyRift).init() -- la Grieta del cielo (Saga de la Grieta; fase en el atributo SkyRift)
end)
safeInit("StoryAudio", StoryAudio.init) -- música, efectos y voces de la historia
task.spawn(SpeechBubbles.init) -- bocadillos encima de cada personaje que habla (lo que dice la gente del servidor)
task.spawn(LifeStory.init) -- historia de vida (tarjeta "Tu vida", momentos, decisiones)
task.spawn(Prologue.init) -- prólogo jugable («El sueño»): tarjeta de ayuda de cada control y "Saltar"
task.spawn(Baby.init) -- tutorial de bebé (botón de levantarse, familia, vista de la ciudad)
task.spawn(ClassUI.init) -- clases y exámenes que se juegan
task.spawn(Gps.init) -- GPS: ruta por las calles hasta tu destino (mapas, flechas en el suelo e indicación)
task.spawn(HelpUI.init) -- botón ❓ "¿Qué hago ahora?" (tecla H): tu objetivo en claro y «Llévame»
-- Primeros pasos del jugador nuevo, pistas si te atascas y consejos de la primera vez
task.spawn(Guide.init, { mapOpen = MapUI.isOpen, bagOpen = InventoryUI.isOpen, dialogOpen = LifeStory.hasDialog })
-- Abrir el ❓ y usar «Llévame» también son pasos del tutorial
HelpUI.onOpen(function()
	Guide.mark("Ayuda")
end)
HelpUI.onGo(function()
	Guide.mark("Mision")
end)
task.spawn(MapUI.init) -- minimapa y mapa grande (tecla M)
task.spawn(InventoryUI.init) -- mochila estilo Minecraft (barra rápida 1-9, tecla E)
task.spawn(DialogueUI.init) -- conversaciones de las misiones (con respuestas y cámara)
task.spawn(DebugHud.init) -- panel de depuración del dueño (F8); a los demás jugadores no les llega nada
task.spawn(MiniGameUI.init) -- pase, canastas, partido de fútbol
task.spawn(SceneClient.init) -- cada uno ve solo los personajes de su historia
task.spawn(CanonMarkers.init) -- la saga: ❗ dorados en el mapa y pilares de luz hasta que haces cada misión canónica
task.spawn(CityErrands.init) -- encargos de la ciudad: cada uno ve solo los objetos y la gente de su encargo
task.spawn(NameTags.init) -- el nombre encima de los personajes de la historia (legible y sin pisar los bocadillos)
task.spawn(ActorLife.init) -- los personajes respiran, miran, gesticulan al hablar y andan con animación
task.spawn(AgeMotion.init) -- cada edad se mueve a su manera: el bebé gatea, los mayores van encorvados…
task.spawn(ReactMotion.init) -- golpes con cuerpo y choques: balón, piedras, arena, arbustos y charcos
task.spawn(Locomotion.init) -- andar fluido: arrancar y frenar suave, inclinarse, mirar, aterrizar, sentarse y alcanzar cosas
task.spawn(Stances.init) -- agacharse (Ctrl, cruceta abajo) y tumbarse (mantener): más bajo, más lento y más discreto
task.spawn(Parkour.init) -- saltar vallas, muros y capós corriendo, y agarrarse a bordes para subir
task.spawn(FootCamera.init) -- cámara a pie: zoom corto dentro de edificios y campo de visión al correr
task.spawn(RideCamera.init) -- cámara en un vehículo, el autobús o el metro: detrás, suave y sin meterse dentro
task.spawn(RidePose.init) -- postura en un vehículo: manos al volante o al manillar, pasajeros sentados
task.spawn(ObjectMotion.init) -- árboles que se mecen, columpios, banderas, noria, carrusel, fuentes
task.spawn(require(script.Parent.Controllers.GiantHen).init) -- las gallinas de código (Petra, la gigante) respiran, picotean y andan
task.spawn(WetWorld.init) -- con lluvia: suelo que brilla, charcos, gente y cosas mojadas; con nieve, todo blanco
task.spawn(StoneThrow.init) -- coger piedras del suelo y lanzarlas (tecla B o botón 🥌)
task.spawn(Ambient.init) -- tráfico y peatones
task.spawn(Weather.init) -- estaciones y tiempo: lluvia, tormenta, nieve, hojas de otoño
task.spawn(Wildlife.init) -- pájaros, palomas, mariposas, patos, perros, gatos y animales de granja
task.spawn(Nudge.init) -- los NPC se apartan (con traspiés) si chocas con ellos o pasa tu coche
task.spawn(Vehicles.init) -- bicis, monopatines, motos y coches
task.spawn(Arcade.init) -- recreativos
task.spawn(DrivingSchool.init) -- autoescuela
task.spawn(Restaurant.init) -- trabajo de camarero y barman
task.spawn(Character.init) -- ficha del personaje (botón Personaje) y correr con Shift
task.spawn(Joystick.init) -- móvil: joystick fijo abajo a la izquierda (con el estilo del HUD)
task.spawn(NearShadows.init) -- sombras de las luces solo cerca de ti (mismo aspecto, mucho más fluido)
task.spawn(Prompts.init) -- carteles de "pulsa E" con el estilo de la interfaz
task.spawn(SoundFx.init) -- efectos de sonido: saltos, golpes, agua, botones, motor, claxon y gente hablando
task.spawn(BusUI.init) -- pasajeros del autobús: línea, próxima parada y "Bajar en la próxima"
task.spawn(BusBoards.init) -- paneles ámbar de las paradas: cuánto falta para cada autobús
task.spawn(SupermarketUI.init) -- supermercados: carrito, ticket, cajero y charcutería
task.spawn(CafeUI.init) -- cafeterías: la carta y el panel del barista
task.spawn(PostUI.init) -- Correos: el panel de la ruta del repartidor
task.spawn(GarbageUI.init) -- Limpieza: el panel del basurero
task.spawn(MedicalUI.init) -- hospital: el panel del médico/a (pruebas, diagnóstico, botiquín)
task.spawn(PoliceUI.init) -- policía: panel del aviso y sirenas de los coches patrulla
task.spawn(FireUI.init) -- bomberos: panel del aviso
task.spawn(CinemaUI.init) -- cines: película en pantalla, taquilla y panel del taquillero
task.spawn(HotelUI.init) -- hoteles: reservar, descansar y panel del recepcionista
task.spawn(TradeUI.init) -- intercambio entre jugadores y mercadillo
task.spawn(PlayerMenuUI.init) -- al tocar a un jugador: invitar al grupo, chat y comerciar
task.spawn(FishingUI.init) -- pesca: sedal y corcho, ¡tirar!, tienda de pesca
task.spawn(MetroUI.init) -- metro: panel del tren, billetes, tiendas, encargos y escenario
task.spawn(MetroMapUI.init) -- metro: plano de la red, trenes en vivo, estación más cercana y planificador (app 🚇 Metro)
task.spawn(MetroTrains.init) -- metro: trenes fluidos en cada pantalla, ir de pie en el tren, megafonía y sonidos
task.spawn(Flights.init) -- aeropuerto: aviones fluidos en cada pantalla, panel del vuelo, cámara y megafonía
task.spawn(require(script.Parent.Controllers.Flying).init) -- pilotar avionetas y el avión de línea (aeroclub)
task.spawn(RailUI.init) -- Cercanías: panel del viaje, billetes y pasos a nivel (barreras, luces y coches que esperan)
task.spawn(GymUI.init) -- gimnasio: recepción (entrada y abono) y la barra del ritmo al entrenar
task.spawn(GymMotion.init) -- gimnasio: el cuerpo hace el ejercicio y la máquina se mueve (cinta, pesas, bici…)
task.spawn(DivingUI.init) -- nadar, bucear (aire) y pesca submarina con fusil o arpón
task.spawn(SeaBiome.init) -- el fondo del mar y la luz bajo el agua (solo cuando estás en el agua)
task.spawn(SeaEventsUI.init) -- catástrofes marinas: alerta, ola del tsunami, rayos, remolino, tiburón y medusas
task.spawn(JobPrompts.init) -- los carteles de cada oficio solo los ve quien trabaja en él
task.spawn(Driving.init) -- conducir coches, motos, bicis, monopatines y patinetes (W/A/S/D)
task.spawn(VehicleLights.init) -- faros, pilotos de freno y marcha atrás e intermitentes de los vehículos de los jugadores (todos los ven)
task.spawn(WheelSpin.init) -- las ruedas de los vehículos cercanos ruedan y las de delante giran con el volante (todos los ven)
task.spawn(Actions.init) -- gestos y bailes, linterna (L) y modo foto (P)
task.spawn(CombatController.init) -- pelear: X/RB golpear (combo de 3), Z/LB defenderse, 👊 y 🛡 en el móvil
task.spawn(WeaponController.init) -- armas: clic dcho/LT apuntar, clic/RT disparar, R recargar; Armerías y licencia
task.spawn(WantedUI.init) -- estrellas de búsqueda bajo el reloj, avisos de delito, DETENIDO y hélices
task.spawn(DeathUI.init) -- pantalla de HAS MUERTO y despertar en el hospital
-- Versión nueva del juego: aviso antes de pasar a un servidor nuevo (UpdateService)
task.spawn(function()
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Update", 60) :: RemoteEvent?
	if remote then
		remote.OnClientEvent:Connect(function(kind: string, data: any)
			if kind == "Soon" then
				Hud.toast("Info", ("🔄 ¡Versión nueva! Te llevamos a un servidor actualizado en %d s"):format(tonumber(data and data.Seconds) or 15))
			end
		end)
	end
end)
task.spawn(InstitutionsUI.init) -- instituciones: panel del juez, juicio, condena, ascensos y Hacienda
task.spawn(InteriorUI.init) -- ascensor de los edificios (todos se pueden visitar por dentro)
task.spawn(EconomyUI.init) -- granja (cooperativa, obrador) y negocios (gestión y mostrador)
task.spawn(UseMotion.init) -- posturas al usar los muebles: sentado, tumbado, grifo, nevera, ducha, ordenador, piano, ventana
task.spawn(InteractClient.init) -- tele con imagen, ordenador, piano, agua y clics de los muebles
task.spawn(FridgeUI.init) -- nevera de casa: lo que hay dentro (comer, coger) y guardar la compra
task.spawn(HousingUI.init) -- el timbre de tu casa (Abrir / No abrir) y el panel de llaves y visitas
task.spawn(LiftRide.init) -- el ascensor sube y baja fluido contigo dentro

-- Comandos: las acciones de ahora van en la tira junto a los botones (la elegida es también lo que
-- hace la tecla E, y su cartel es el único que se dibuja) y todo lo demás son apps del ValPhone, el
-- teléfono que asoma abajo a la izquierda (Tab / Select / tocarlo)
DefaultCommands.register()
CommandMenu.onFocus(Prompts.setFocus)
task.spawn(CommandMenu.init)

-- 🏆 Pase de temporada: app del ValPhone, tecla N y ventana. Con BattlePassConfig.Enabled = false no
-- hace nada (ni fila, ni tecla, ni remoto)
local BattlePassUI: any = nil
safeInit("BattlePassUI", function()
	BattlePassUI = require(script.Parent.UI.BattlePassUI)
	BattlePassUI.init()
end)

-- Acciones de los comandos (Objetos y Mapa)
Hud.setAction("Mochila", InventoryUI.toggle)
Hud.setAction("Mapa", MapUI.toggleBig)

-- 📖 «Mi historia» en Ajustes (capítulos, personajes y recuerdos; también su app, la tarjeta "Tu vida" y J)
Hud.addMenuToggle("📖 Mi historia", 0, function()
	LifeStory.openJournal()
	return "📖 Mi historia"
end)

-- Música on/off en el menú (sustituye al botón suelto 🔊). El estado lo guarda StoryAudio (uno solo)
local function musicLabel(): string
	return if StoryAudio.isMusicOn() then "🔊 Música: sí" else "🔇 Música: no"
end
Hud.addMenuToggle(musicLabel(), 1, function()
	StoryAudio.setMusicOn(not StoryAudio.isMusicOn())
	return musicLabel()
end)
-- Sonidos on/off: el estado lo guarda SoundFx
local function effectsLabel(): string
	return if SoundFx.isMuted() then "🔕 Sonidos: no" else "🔔 Sonidos: sí"
end
Hud.addMenuToggle(effectsLabel(), 2, function()
	SoundFx.setMuted(not SoundFx.isMuted())
	return effectsLabel()
end)

-- Primeros pasos: volver a ver el tutorial (se cierran el menú y el ValPhone para que se vea la tarjeta)
local REPLAY = "🎓 Ver tutorial otra vez"
Hud.addMenuToggle(REPLAY, 0.5, function()
	Guide.restart()
	Hud.closeMenu()
	CommandMenu.closePhone()
	Hud.toast("Info", "🎓 Empezamos los primeros pasos otra vez")
	return REPLAY
end)

-- Ropa: el aspecto de Valmar (por defecto) o tu avatar de Roblox
local function lookText(): string
	return if game:GetService("Players").LocalPlayer:GetAttribute("OwnAvatar") then "👕 Ropa: mi avatar de Roblox" else "👕 Ropa: estilo Valmar"
end
Hud.addMenuToggle(lookText(), 3, function()
	ReplicatedStorage.Remotes.Avatar:FireServer("Toggle")
	return if game:GetService("Players").LocalPlayer:GetAttribute("OwnAvatar") then "👕 Ropa: estilo Valmar" else "👕 Ropa: mi avatar de Roblox"
end)

-- GPS (ruta por las calles, flechas en el suelo e indicaciones): sí por defecto
Hud.addMenuToggle("🧭 GPS: sí", 3.2, function()
	Gps.setEnabled(not Gps.isEnabled())
	return if Gps.isEnabled() then "🧭 GPS: sí" else "🧭 GPS: no"
end)

-- ✨ Gráficos: Auto (según los fps) → Bajo → Medio → Alto (UI/Perf, presupuestos en shared/Graphics)
do
	local Perf = require(script.Parent.UI.Perf)
	local Graphics = require(ReplicatedStorage.Shared.Graphics)
	safeInit("PerfAuto", Perf.startAuto)
	Hud.addMenuToggle(Perf.choiceLabel(), 3.3, function()
		Perf.setChoice(Graphics.nextChoice(Perf.choice()))
		Hud.toast("Info", Perf.choiceLabel())
		return Perf.choiceLabel()
	end, Perf.choiceLabel)
end

-- Móvil: correr al empujar el joystick hasta el borde (sí por defecto)
local function autoRunText(): string
	return if game:GetService("Players").LocalPlayer:GetAttribute("AutoRun") == false then "🏃 Correr al empujar el joystick: no" else "🏃 Correr al empujar el joystick: sí"
end
Hud.addMenuToggle(autoRunText(), 3.5, function()
	Character.setAutoRun(game:GetService("Players").LocalPlayer:GetAttribute("AutoRun") == false)
	return autoRunText()
end)

-- Empezar una vida nueva (desde bebé): hay que pulsar dos veces para confirmar
local NEW_LIFE = "👶 Empezar una vida nueva"
local confirmUntil = 0
Hud.addMenuToggle(NEW_LIFE, 4, function()
	if os.clock() < confirmUntil then
		ReplicatedStorage.Remotes.NewLife:FireServer()
		return "⏳ Preparando tu vida nueva…"
	end
	confirmUntil = os.clock() + 5
	task.delay(5, function()
		confirmUntil = 0
	end)
	return "⚠️ Se borra la partida. Pulsa otra vez"
end)

-- La tarjeta "Tu vida" de la historia y el botón suelto de la música ya están en el HUD nuevo
-- (objetivos a la izquierda y menú): se ocultan para que no salgan repetidos.
task.spawn(function()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	-- (se esconde el botón y no la pantalla entera: las cinemáticas vuelven a encender las pantallas)
	local audioGui = playerGui:WaitForChild("StoryAudio", 30)
	if audioGui then
		for _, child in audioGui:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = false
			end
		end
	end
	-- (en el móvil la tarjeta vive en su propia pantalla, "LifeStoryDock"; en el ordenador, dentro de
	-- "LifeStory". Se busca en los dos sitios: el HUD ya enseña la misión)
	local story = playerGui:WaitForChild("LifeStory", 30)
	local dock = (story and story:FindFirstChild("LifeStoryDock"))
	if not dock then
		local own = playerGui:WaitForChild("LifeStoryDock", 5)
		dock = if own and own:IsA("ScreenGui") then own:FindFirstChildWhichIsA("GuiObject") else own
	end
	if not dock and story then
		dock = story:WaitForChild("LifeStoryDock", 25)
	end
	if dock and dock:IsA("GuiObject") then
		dock.Visible = false
		dock:GetPropertyChangedSignal("Visible"):Connect(function()
			dock.Visible = false
		end)
	end
end)

local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
Notify.OnClientEvent:Connect(function(kind: string, text: string)
	if kind == "Sleep" then
		Hud.sleep()
	elseif kind == "Travel" then
		Hud.fade(text, 2)
	else
		Hud.toast(kind, text)
	end
end)

-- Durante las cinemáticas y las conversaciones no se puede interactuar con nada:
-- se apagan los carteles de "pulsa E" (y el mapa grande se cierra)
local PromptGuard = require(script.Parent.Controllers.PromptGuard)
local localPlayer = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local function coreGuis()
	-- Lo que el juego ya dibuja a su manera (las cinemáticas encienden todo lo de Roblox al acabar)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- mochila propia
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) -- la vida es el aro del HUD
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) -- tapaba los botones de arriba a la derecha
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true) -- gestos y bailes: los de Roblox
	end)
end
coreGuis()
-- El chat de Roblox, a la derecha a media altura (arriba a la izquierda tapaba la ficha y los objetivos)
pcall(function()
	local TextChatService = game:GetService("TextChatService")
	local window = TextChatService:WaitForChild("ChatWindowConfiguration", 10) :: any
	if window then
		window.HorizontalAlignment = Enum.HorizontalAlignment.Right
		window.VerticalAlignment = Enum.VerticalAlignment.Center
	end
end)

-- Carteles: apagados en conversaciones y cinemáticas (y un segundo después), y el de hablar con alguien
-- no vuelve mientras su globo está en pantalla (PromptGuard: en el móvil, un toque de más ya no repite)
PromptGuard.init(function()
	return Cinematics.isPlaying() or localPlayer:GetAttribute("InDialogue") == true
end, Baby.isSaying)

-- Red de seguridad: si la marca "hablando" se quedó puesta sin ninguna conversación abierta
-- (algo falló a medias), se quita a los pocos segundos y vuelve toda la interfaz
task.spawn(function()
	local stale = 0
	while true do
		task.wait(1)
		if localPlayer:GetAttribute("InDialogue") == true and not DialogueUI.isOpen() then
			stale += 1
			if stale >= 3 then
				localPlayer:SetAttribute("InDialogue", nil)
				stale = 0
			end
		else
			stale = 0
		end
	end
end)

local wasBusy = false
game:GetService("RunService").Heartbeat:Connect(function()
	local cinematic = Cinematics.isPlaying()
	local busy = cinematic or localPlayer:GetAttribute("InDialogue") == true
	if busy ~= wasBusy then
		wasBusy = busy
		TaskMarker.setHidden(busy)
		Hud.setBusy(busy)
		CommandMenu.setBusy(busy)
		Joystick.setBusy(busy)
		Gps.setBusy(busy)
		Guide.setBusy(busy)
		HelpUI.setBusy(busy)
		if busy and MapUI.isOpen() then
			MapUI.toggleBig()
		end
		if not busy then
			task.defer(coreGuis)
		end
	end
end)

-- De bebé sobra el minimapa (los botones y el resto del HUD ya se apartan solos)
local function babyMode()
	local baby = localPlayer:GetAttribute("LifeStage") == "Bebe"
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end
	for _, path in { { "MapUI", "Minimap" } } do
		local target = playerGui:FindFirstChild(path[1])
		if target and path[2] then
			target = target:FindFirstChild(path[2])
		end
		if target and target:IsA("GuiObject") then
			target.Visible = not baby
		elseif target and target:IsA("ScreenGui") then
			for _, child in target:GetChildren() do
				if child:IsA("GuiObject") then
					child.Visible = not baby
				end
			end
		end
	end
end
localPlayer:GetAttributeChangedSignal("LifeStage"):Connect(babyMode)
task.delay(3, babyMode)
task.delay(12, babyMode)
