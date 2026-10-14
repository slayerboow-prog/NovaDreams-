-- PhoneInbox: los mensajes del ValPhone (app Mensajes) y quién los enseña.
--
--   PhoneInbox.push({ Icon = "📱", From = "Abu Rosa", Text = "…", App = "Mensajes" })
--
-- Los avisos «📱 Abu Rosa quiere hablar contigo…» de la historia (Controllers/LifeStory) llegan aquí:
-- con el teléfono cerrado bajan como notificación desde el ValPhone; dentro, en Mensajes.
-- Sin nada de Roblox (se prueba con Lune).

local PhoneInbox = {}

-- Open: la app que abre tocar el mensaje (p. ej. "Misiones")
export type Message = { Id: number, Icon: string, From: string?, Text: string, App: string, Open: string?, At: number, Read: boolean }

local MAX = 30
local messages: { Message } = {}
local listeners: { (Message?) -> () } = {}
local display: ((Message) -> ())? = nil
local nextId = 0

local function notify(message: Message?)
	for _, fn in table.clone(listeners) do
		local ok, err = pcall(fn, message)
		if not ok then
			warn("[ValPhone] " .. tostring(err))
		end
	end
end

-- Un mensaje nuevo (arriba del todo). Devuelve el mensaje guardado.
function PhoneInbox.push(data: { [string]: any }): Message
	nextId += 1
	local message: Message = {
		Id = nextId,
		Icon = if type(data.Icon) == "string" then data.Icon else "📱",
		From = if type(data.From) == "string" then data.From else nil,
		Text = tostring(data.Text or ""),
		App = if type(data.App) == "string" then data.App else "Mensajes",
		Open = if type(data.Open) == "string" then data.Open else nil,
		At = if type(data.At) == "number" then data.At else os.clock(),
		Read = false,
	}
	table.insert(messages, 1, message)
	while #messages > MAX do
		table.remove(messages)
	end
	if display then
		local ok, err = pcall(display :: any, message)
		if not ok then
			warn("[ValPhone] " .. tostring(err))
		end
	end
	notify(message)
	return message
end

function PhoneInbox.list(): { Message }
	return table.clone(messages)
end

function PhoneInbox.unread(): number
	local count = 0
	for _, message in messages do
		if not message.Read then
			count += 1
		end
	end
	return count
end

function PhoneInbox.markAllRead()
	local changed = false
	for _, message in messages do
		if not message.Read then
			message.Read = true
			changed = true
		end
	end
	if changed then
		notify(nil)
	end
end

function PhoneInbox.onChanged(fn: (Message?) -> ())
	table.insert(listeners, fn)
end

-- Quien enseña los mensajes nuevos (el ValPhone: una notificación que baja). Sin nadie, quien manda
-- el mensaje lo enseña a su manera (LifeStory: el aviso de siempre arriba).
function PhoneInbox.setDisplay(fn: ((Message) -> ())?)
	display = fn
end

function PhoneInbox.hasDisplay(): boolean
	return display ~= nil
end

-- (pruebas) empezar de cero
function PhoneInbox._reset()
	messages = {}
	listeners = {}
	display = nil
	nextId = 0
end

return PhoneInbox
