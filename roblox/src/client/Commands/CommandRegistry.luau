-- CommandRegistry: el registro central de comandos del menú de comandos.
--
-- Un comando se registra una vez y el menú decide solo cuándo sale, según el contexto
-- (ContextDetector): lo que tienes delante, tu edad, si conduces, si estás en una conversación…
--
--   CommandRegistry.register({
--       Id = "Mapa", Label = "Mapa", Icon = "🗺", Priority = 60,
--       When = function(ctx) return ctx.Stage ~= "Bebe" end,  -- (opcional) cuándo sale
--       Run = function(ctx) ... end,                           -- lo que hace al confirmarlo
--   })
--
-- Un comando con Open en vez de Run es un grupo: al confirmarlo se abre un submenú con la
-- lista que devuelve Open(ctx). Los "proveedores" generan comandos sobre la marcha (uno por
-- cada cosa con la que puedes interactuar ahora mismo).

local CommandRegistry = {}

export type Context = { [string]: any }
export type Command = {
	Id: string,
	Label: string,
	Detail: string?, -- segunda línea pequeña (a quién o a qué)
	Icon: string,
	Priority: number, -- más bajo = más arriba
	When: ((Context) -> boolean)?,
	Run: ((Context) -> ())?,
	Open: ((Context) -> { Command })?,
	Prompt: ProximityPrompt?, -- si el comando dispara un cartel de interacción del mapa
	Accent: boolean?, -- resaltado (lo que hay delante de ti)
}

local commands: { Command } = {}
local providers: { (Context) -> { Command } } = {}

function CommandRegistry.register(command: Command)
	for i, existing in commands do
		if existing.Id == command.Id then
			commands[i] = command
			return
		end
	end
	table.insert(commands, command)
end

-- provider(ctx) devuelve comandos que dependen del momento (lo que tienes delante)
function CommandRegistry.addProvider(provider: (Context) -> { Command })
	table.insert(providers, provider)
end

local function sorted(list: { Command }): { Command }
	table.sort(list, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority < b.Priority
		end
		return a.Id < b.Id
	end)
	return list
end

-- Los comandos que tocan ahora, ordenados
function CommandRegistry.list(ctx: Context): { Command }
	local out = {}
	for _, provider in providers do
		local ok, extra = pcall(provider, ctx)
		if ok and type(extra) == "table" then
			for _, command in extra do
				table.insert(out, command)
			end
		elseif not ok then
			warn("[Comandos] " .. tostring(extra))
		end
	end
	for _, command in commands do
		local ok, show = pcall(function()
			return command.When == nil or command.When(ctx)
		end)
		if ok and show then
			table.insert(out, command)
		end
	end
	return sorted(out)
end

-- Los comandos de un grupo (submenú)
function CommandRegistry.open(command: Command, ctx: Context): { Command }
	if not command.Open then
		return {}
	end
	local ok, list = pcall(command.Open, ctx)
	if not ok then
		warn("[Comandos] " .. tostring(list))
		return {}
	end
	local out = {}
	for _, child in list do
		if child.When == nil or child.When(ctx) then
			table.insert(out, child)
		end
	end
	return sorted(out)
end

return CommandRegistry
