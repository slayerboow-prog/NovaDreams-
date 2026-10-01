-- PhoneApps: qué va al ValPhone (las apps) y qué va a la tira de acciones (lo de ahora mismo).
-- Funciones puras (sin Roblox): se prueban con Lune en scripts/test-commands.luau.
--
-- Todo sale del mismo registro de comandos (Commands/CommandRegistry), que no cambia:
--   * Priority < AppBand (50)  -> ACCIÓN DE CONTEXTO: lo que tienes delante (Hablar con Marta, Entrar,
--     Comprar billete…), Saludar, Bajarse, pelear (Atacar, Disparar, Apuntar, Recargar, Huir…),
--     Robar, Detener… Van en la tira de acciones junto a los botones (UI: Commands/ContextStrip),
--     a un toque, nunca dentro del teléfono.
--   * Priority >= AppBand      -> APP del ValPhone (Mapa, Mochila, Ir a casa, Tienda, Vehículos,
--     Gestos, Metro, Mercadillo, Pesca, Pase de temporada, Modo pruebas…). Los grupos marcados
--     Flatten (el antiguo «Más») se abren: cada hijo es una app más (Misiones, Mi historia,
--     Personaje, Viviendas, Carrera, Controles, Ajustes).
-- Un mismo comando puede cambiar de sitio con el momento: «Objetos» es una app (Mochila), pero en
-- plena pelea sube a la tira (Priority 0.18), como antes subía arriba del todo en COMANDOS.
--
-- El ValPhone es el teléfono de Valmar (el de los carteles del metro: «📱 ValPhone 12 · Más batería
-- que nunca», server/World/Kit/MetroDetails).

local PhoneApps = {}

PhoneApps.AppBand = 50
PhoneApps.Brand = "ValPhone"
PhoneApps.Model = "ValPhone 12"
PhoneApps.Slogan = "Más batería que nunca"

-- Colores de la marca (r, g, b): grafito del cartel del metro y un degradado índigo-turquesa
PhoneApps.Colors = {
	Body = { 22, 22, 30 }, -- el grafito del cartel («ValPhone 12», rgb(30, 30, 40))
	Bezel = { 8, 8, 12 },
	Edge = { 150, 156, 172 }, -- filo metálico
	WallTop = { 36, 30, 92 },
	WallMid = { 22, 70, 140 },
	WallBottom = { 10, 120, 140 },
	Accent = { 90, 200, 255 },
	Badge = { 255, 59, 48 },
}

export type Meta = { Name: string, Icon: string, Color: { number }, Screen: string? }

-- Cómo se ve cada app (por el Id del comando). Lo que no está aquí sale con su Label e Icon.
-- Screen: la app se abre DENTRO del teléfono (Ajustes, Mensajes, Cartera); el resto cierra el
-- teléfono y abre su ventana de siempre (mapa, tienda, pase…).
PhoneApps.Catalog = {
	Mapa = { Name = "Mapa", Icon = "mapa", Color = { 52, 199, 89 } },
	Objetos = { Name = "Mochila", Icon = "mochila", Color = { 196, 120, 52 } },
	["AppIr a casa"] = { Name = "Ir a casa", Icon = "casa", Color = { 40, 110, 230 } },
	["AppRuta a casa"] = { Name = "Ruta a casa", Icon = "lugar", Color = { 20, 160, 150 } },
	AppTienda = { Name = "Tienda", Icon = "tienda", Color = { 255, 159, 10 } },
	["AppVehículos"] = { Name = "Vehículos", Icon = "coche", Color = { 0, 122, 255 } },
	["AppMascotas"] = { Name = "Mascotas", Icon = "🐾", Color = { 175, 120, 70 } },
	AppGestos = { Name = "Gestos", Icon = "gestos", Color = { 230, 180, 20 } },
	GestosPase = { Name = "Gestos pase", Icon = "gestos", Color = { 175, 82, 222 } },
	AppMetro = { Name = "Metro", Icon = "🚇", Color = { 210, 40, 60 } },
	AppMercadillo = { Name = "Mercadillo", Icon = "mercadillo", Color = { 200, 90, 160 } },
	["AppGuía de pesca"] = { Name = "Pesca", Icon = "pesca", Color = { 30, 120, 190 } },
	PaseTemporada = { Name = "Pase", Icon = "🏆", Color = { 255, 190, 40 } },
	ModoPruebas = { Name = "Modo pruebas", Icon = "🔧", Color = { 99, 99, 110 } },
	Misiones = { Name = "Misiones", Icon = "misiones", Color = { 255, 120, 40 } },
	Historia = { Name = "Mi historia", Icon = "📖", Color = { 172, 112, 62 } },
	Personaje = { Name = "Personaje", Icon = "personaje", Color = { 146, 104, 255 } },
	Viviendas = { Name = "Viviendas", Icon = "viviendas", Color = { 88, 86, 214 } },
	Carrera = { Name = "Carrera", Icon = "carrera", Color = { 205, 150, 40 } },
	Controles = { Name = "Controles", Icon = "mando", Color = { 70, 76, 100 } },
	Menu = { Name = "Ajustes", Icon = "menu", Color = { 142, 142, 152 }, Screen = "Ajustes" },
	Mensajes = { Name = "Mensajes", Icon = "hablar", Color = { 48, 209, 88 }, Screen = "Mensajes" },
	Cartera = { Name = "Cartera", Icon = "dinero", Color = { 30, 150, 95 }, Screen = "Cartera" },
	Ayuda = { Name = "Ayuda", Icon = "ayuda", Color = { 10, 132, 255 } },
} :: { [string]: Meta }

-- El «dock» de abajo de la pantalla de inicio (si están): lo que más se usa
PhoneApps.Dock = { "Mapa", "Misiones", "Mensajes", "Menu" }

local DEFAULT_COLOR = { 60, 90, 160 }

-- Cómo se ve un comando como app (nombre corto, icono, color y si abre una pantalla del teléfono)
function PhoneApps.meta(command: { [string]: any }): Meta
	local known = PhoneApps.Catalog[command.Id]
	return {
		Name = if known then known.Name else command.Label,
		Icon = if known then known.Icon else command.Icon,
		Color = if known then known.Color else DEFAULT_COLOR,
		Screen = command.Screen or (known and known.Screen),
	}
end

local function isApp(command: { [string]: any }): boolean
	return (tonumber(command.Priority) or 0) >= PhoneApps.AppBand
end

-- list: comandos ya ordenados (CommandRegistry.list); open(grupo) -> sus hijos (CommandRegistry.open).
-- Devuelve (acciones de la tira, apps del teléfono), cada una en su orden.
function PhoneApps.split(list: { any }, open: ((any) -> { any })?): ({ any }, { any })
	local context, apps = {}, {}
	for _, command in list do
		if not isApp(command) then
			table.insert(context, command)
		elseif (command.Flatten or command.Id == "Mas") and command.Open and open then
			-- El antiguo «Más»: cada hijo es una app (con su punto rojo si lo tiene)
			for _, child in open(command) do
				table.insert(apps, child)
			end
		else
			table.insert(apps, command)
		end
	end
	return context, apps
end

-- Reparte las apps entre el dock (fijas abajo) y la cuadrícula (el resto, en su orden)
function PhoneApps.layout(apps: { any }): ({ any }, { any })
	local byId = {}
	for _, app in apps do
		byId[app.Id] = app
	end
	local dock, inDock = {}, {}
	for _, id in PhoneApps.Dock do
		if byId[id] then
			table.insert(dock, byId[id])
			inDock[id] = true
		end
	end
	local grid = {}
	for _, app in apps do
		if not inDock[app.Id] then
			table.insert(grid, app)
		end
	end
	return dock, grid
end

-- Punto rojo de una app: true / número > 0 (Badge del comando)
function PhoneApps.badgeCount(command: { [string]: any }): number
	local badge = command.Badge
	if badge == true then
		return 1
	elseif type(badge) == "number" and badge > 0 then
		return math.floor(badge)
	end
	return 0
end

-- Total de avisos (el numerito del teléfono cerrado)
function PhoneApps.totalBadges(apps: { any }): number
	local total = 0
	for _, app in apps do
		total += PhoneApps.badgeCount(app)
	end
	return total
end

-- Apps que acaban de encender su punto rojo (para el aviso que baja del teléfono): ids de `now` con
-- aviso que en `before` (id -> número) no lo tenían
function PhoneApps.newBadges(before: { [string]: number }, now: { any }): ({ any }, { [string]: number })
	local fresh, after = {}, {}
	for _, app in now do
		local count = PhoneApps.badgeCount(app)
		after[app.Id] = count
		if count > (before[app.Id] or 0) then
			table.insert(fresh, app)
		end
	end
	return fresh, after
end

-- ¿Se llega a todo? ids: los comandos que había en COMANDOS. Devuelve los que no están ni en la tira
-- ni en el teléfono (vacío = todo alcanzable). Sirve para las pruebas.
function PhoneApps.unreachable(ids: { string }, context: { any }, apps: { any }): { string }
	local seen = {}
	for _, command in context do
		seen[command.Id] = true
	end
	for _, app in apps do
		seen[app.Id] = true
	end
	local missing = {}
	for _, id in ids do
		if not seen[id] then
			table.insert(missing, id)
		end
	end
	return missing
end

-- Batería del teléfono: tu energía (0-100) con un mínimo del 5 % («Más batería que nunca»)
function PhoneApps.battery(energy: any): number
	local value = tonumber(energy)
	if not value then
		return 100
	end
	return math.clamp(math.floor(value + 0.5), 5, 100)
end

-- Navegación con flechas / cruceta por la cuadrícula (columns columnas, count apps): de index a dónde
function PhoneApps.step(index: number, count: number, columns: number, dx: number, dy: number): number
	if count <= 0 then
		return 1
	end
	local i = math.clamp(index, 1, count)
	if dx ~= 0 then
		i = (i - 1 + dx) % count + 1
	elseif dy ~= 0 then
		local target = i + dy * columns
		if target >= 1 and target <= count then
			i = target
		elseif dy > 0 then
			i = count
		else
			i = 1
		end
	end
	return i
end

return PhoneApps
