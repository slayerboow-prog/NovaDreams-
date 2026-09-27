-- Interact: reglas de lo que se puede hacer con los muebles de dentro de los edificios
-- (InteractService en el servidor, InteractClient y UseAnim en el cliente).
--
-- Cada mueble que se usa lleva la etiqueta "Interact" y el atributo Use con lo que es:
--   Sit       sillas, sofás, taburetes, bancos (te sientas)
--   Bed       camas (en tu casa duermes; en otra, solo te tumbas)
--   TV        la tele (encender/apagar: la pantalla cambia y suena)
--   Light     interruptores (encienden y apagan las luces de esa habitación)
--   Fridge    nevera (en tu casa picas algo, con límite; en las tiendas se paga)
--   Tap       grifos (sale agua)
--   Shower    ducha (agua y vapor)
--   Door      puertas entre habitaciones (se abren girando en su bisagra)
--   Wardrobe  armarios (se abren sus puertas)
--   Computer  ordenador (te sientas y escribes)
--   Piano     piano (te sientas y tocas)
--   Window    ventanas (te asomas a mirar)
--
-- A quién pertenece la sala (Access):
--   Owner     es tu vivienda
--   Guest     es la de alguien de tu grupo (estás invitado)
--   Stranger  es la vivienda de otro jugador y no estás invitado
--   Neighbor  viven vecinos (personajes del juego)
--   ForSale   está en venta (estás de visita)
--   Public    no es una vivienda (oficinas, tiendas, museos…)

local Interact = {}

export type Use = {
	Action: string, -- lo que pone el cartel
	Off: string?, -- lo que pone cuando ya está encendido/abierto
	Object: string, -- debajo, con qué
	Distance: number, -- a cuántos studs aparece el cartel
	Hold: number?, -- mantener pulsado (segundos)
	Harmless: boolean?, -- se puede hacer en casa ajena (sentarse, luces, puertas, mirar)
	Pose: string?, -- postura del personaje (UseAnim)
	Seconds: number?, -- cuánto dura (las que no son sentarse o tumbarse)
}

Interact.Uses = {
	Sit = { Action = "Sentarse", Object = "🪑 Asiento", Distance = 5, Harmless = true, Pose = "Sit" },
	Bed = { Action = "Tumbarse", Object = "🛏 Cama", Distance = 6, Hold = 0.4, Pose = "Lie" },
	TV = { Action = "Encender la tele", Off = "Apagar la tele", Object = "📺 Tele", Distance = 9, Harmless = true },
	Light = { Action = "Apagar la luz", Off = "Encender la luz", Object = "💡 Interruptor", Distance = 5, Harmless = true },
	Fridge = { Action = "Abrir la nevera", Object = "🧊 Nevera", Distance = 5, Hold = 0.3, Pose = "Fridge", Seconds = 2.6 },
	Tap = { Action = "Abrir el grifo", Object = "🚰 Grifo", Distance = 4.5, Pose = "Tap", Seconds = 3.5 },
	Shower = { Action = "Ducharse", Object = "🚿 Ducha", Distance = 5, Hold = 0.5, Pose = "Shower", Seconds = 7 },
	Door = { Action = "Abrir la puerta", Off = "Cerrar la puerta", Object = "🚪 Puerta", Distance = 6, Harmless = true },
	Wardrobe = { Action = "Abrir el armario", Off = "Cerrar el armario", Object = "👕 Armario", Distance = 5 },
	Computer = { Action = "Usar el ordenador", Object = "💻 Ordenador", Distance = 5, Pose = "Type" },
	Piano = { Action = "Tocar el piano", Object = "🎹 Piano", Distance = 5, Hold = 0.3, Pose = "Piano" },
	Window = { Action = "Mirar por la ventana", Object = "🪟 Ventana", Distance = 5, Harmless = true, Pose = "Window", Seconds = 6 },
} :: { [string]: Use }

-- Picar algo de la nevera de casa (la tuya o la de tus padres): gratis y sin límite, solo con
-- un momento entre bocado y bocado (lo que se tarda en comer)
Interact.Snack = {
	Hunger = 15, -- hambre que quita
	Cooldown = 3, -- segundos entre bocado y bocado
}
-- Bebida fresca de la nevera de una tienda o un bar (se paga)
Interact.Drink = { Name = "Bebida fresca", Price = 4, Hunger = 6, Energy = 4 }

-- Tumbarse en tu cama para dormir: la energía al máximo (como la cama de la parcela)
Interact.SleepEnergy = 100
-- Tumbarse en el sofá o la cama de otro no descansa; sentarse en casa sí un poquito
Interact.RestPerSecond = 0.05

-- Canales de la tele: nombre y colores de la imagen (el cliente la anima)
Interact.Channels = {
	{ Name = "📰 Noticias Valmar", Colors = { { 30, 60, 120 }, { 200, 40, 50 }, { 240, 240, 240 } }, Speed = 0.5 },
	{ Name = "⚽ Deportes 24h", Colors = { { 40, 140, 60 }, { 90, 190, 90 }, { 250, 250, 250 } }, Speed = 1.4 },
	{ Name = "🎬 Cine en casa", Colors = { { 20, 20, 40 }, { 180, 120, 60 }, { 60, 90, 160 } }, Speed = 0.7 },
	{ Name = "🦁 Documentales", Colors = { { 200, 160, 70 }, { 90, 140, 60 }, { 110, 170, 220 } }, Speed = 0.4 },
	{ Name = "🎤 Música", Colors = { { 255, 60, 160 }, { 60, 200, 255 }, { 255, 220, 60 } }, Speed = 2.2 },
	{ Name = "🧸 Dibujos", Colors = { { 255, 200, 60 }, { 90, 200, 255 }, { 255, 110, 110 } }, Speed = 1.6 },
}

-- Melodía del piano (semitonos desde el La: el cliente cambia el tono del sonido)
Interact.Melody = { 0, 4, 7, 12, 7, 4, 5, 9, 12, 9, 5, 2, 7, 11, 14, 11, 7, 4, 0, -5, 0 }

-- Tipos de sala que son tiendas o bares (su nevera es de bebidas que se pagan)
Interact.ShopKinds = { Local = true, CentroComercial = true, Ocio = true, Estacion = true }

---------------------------------------------------------------------
-- Permisos
---------------------------------------------------------------------

-- ¿Puede hacer eso quien tiene ese acceso a la sala? (y si no, por qué)
function Interact.allowed(use: string, access: string): (boolean, string?)
	local info = Interact.Uses[use]
	if not info then
		return false, nil
	end
	if access == "Owner" or access == "Guest" or access == "Public" then
		return true, nil
	end
	if info.Harmless then
		return true, nil
	end
	if access == "Stranger" then
		return false, "🔒 No es tu casa: aquí solo puedes sentarte, encender la luz o mirar."
	end
	-- En casa de los vecinos y en las que están en venta: nada de ducharse ni de abrir sus armarios
	if access == "Neighbor" and (use == "Shower" or use == "Wardrobe" or use == "Fridge") then
		return false, "🙂 Mejor no: es la casa de los vecinos."
	end
	return true, nil
end

-- ¿Dormir de verdad (recupera energía) o solo tumbarse un rato?
function Interact.canSleep(access: string): boolean
	return access == "Owner" or access == "Guest"
end

-- Qué pasa al abrir una nevera: "Free" (tu casa), "Pay" (tienda o bar) o nil (solo mirar)
function Interact.fridgeMode(access: string, kind: string?): string?
	if access == "Owner" or access == "Guest" then
		return "Free"
	end
	if access == "Public" and kind and Interact.ShopKinds[kind] then
		return "Pay"
	end
	return nil
end

-- ¿Puede picar algo ahora? last = cuándo (os.clock) dio el último bocado (nil = nunca).
-- No hay máximo: en casa se come lo que se quiera. Devuelve si puede y, si no, cuánto falta.
function Interact.canSnack(last: number?, now: number): (boolean, number)
	if last and now - last < Interact.Snack.Cooldown then
		return false, math.ceil(Interact.Snack.Cooldown - (now - last))
	end
	return true, 0
end

-- La nevera de la casa familiar (donde nace y crece el jugador): es suya si es su familia
function Interact.familyFridge(fridgeHome: any, playerHome: any): boolean
	return fridgeHome ~= nil and fridgeHome == playerHome
end

-- Texto del cartel según el estado (encendida / abierta)
function Interact.actionText(use: string, on: boolean?): string
	local info = Interact.Uses[use]
	if not info then
		return "Usar"
	end
	if use == "Light" then
		-- (la luz empieza encendida: el cartel dice lo contrario de lo que hay)
		return if on == false then info.Off :: string else info.Action
	end
	if on and info.Off then
		return info.Off
	end
	return info.Action
end

-- Siguiente canal de la tele
function Interact.nextChannel(current: number?): number
	return ((current or 0) % #Interact.Channels) + 1
end

return Interact
