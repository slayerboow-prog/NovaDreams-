-- DefaultCommands: los comandos de NovaLife. Para añadir uno nuevo basta con registrarlo aquí
-- (o desde cualquier otro módulo) con CommandRegistry.register.
--
-- Orden (Priority, de arriba abajo):
--   1-3   lo que tienes delante (un comando por cada cosa cercana: hablar, entrar, montar…)
--   4     más cosas cercanas, en un grupo "AQUÍ ▸"
--   5-9   lo que depende de la situación (saludar a alguien, bajarte del vehículo, atacar…)
--   50+   lo de siempre: objetos, mapa, teléfono y "MÁS ▸" (misiones, personaje, gestos, menú)
-- La complejidad crece con la edad: de bebé solo lo que tienes delante.

local CommandRegistry = require(script.Parent.CommandRegistry)
local Hud = require(script.Parent.Parent.UI.Hud)
local Actions = require(script.Parent.Parent.Controllers.Actions)
local Vehicles = require(script.Parent.Parent.Controllers.Vehicles)
local CombatController = require(script.Parent.Parent.Controllers.CombatController)

type Command = CommandRegistry.Command

local DefaultCommands = {}

local TOP_TARGETS = 3

local function baby(ctx): boolean
	return ctx.Stage == "Bebe"
end

-- Un nombre estable para cada cartel (el menú recuerda cuál tenías elegido)
local ids: { [ProximityPrompt]: string } = setmetatable({}, { __mode = "k" }) :: any
local nextId = 0
local function idOf(prompt: ProximityPrompt): string
	local id = ids[prompt]
	if not id then
		nextId += 1
		id = "Aqui" .. nextId
		ids[prompt] = id
	end
	return id
end

local function targetCommand(target, priority: number): Command
	return {
		Id = idOf(target.Prompt),
		Label = target.Label,
		Detail = if target.Detail ~= "" then target.Detail else nil,
		Icon = target.Icon,
		Priority = priority,
		Prompt = target.Prompt,
		Accent = true,
	}
end

function DefaultCommands.register()
	-- Lo que tienes delante: cada cartel de interacción cercano es un comando
	CommandRegistry.addProvider(function(ctx)
		local out = {}
		local targets = ctx.Targets or {}
		for i = 1, math.min(TOP_TARGETS, #targets) do
			table.insert(out, targetCommand(targets[i], i))
		end
		if #targets > TOP_TARGETS then
			table.insert(out, {
				Id = "AquiMas",
				Label = "Aquí",
				Detail = ("%d más"):format(#targets - TOP_TARGETS),
				Icon = "📍",
				Priority = 4,
				Open = function(now)
					local list = {}
					for i = TOP_TARGETS + 1, #now.Targets do
						table.insert(list, targetCommand(now.Targets[i], i))
					end
					return list
				end,
			})
		end
		return out
	end)

	-- Delante de una persona: saludarla
	CommandRegistry.register({
		Id = "Saludar",
		Label = "Saludar",
		Icon = "👋",
		Priority = 5,
		When = function(ctx)
			return not baby(ctx) and not ctx.Seated and ctx.Target ~= nil and ctx.Target.Kind == "Npc"
		end,
		Run = function()
			Actions.emote("Saludar")
		end,
	})

	-- Montado en un vehículo: bajarse
	CommandRegistry.register({
		Id = "Bajarse",
		Label = "Bajarse",
		Icon = "⬇",
		Priority = 6,
		When = function(ctx)
			return ctx.Seated
		end,
		Run = function()
			Vehicles.dismount()
		end,
	})

	-- Pelear (el combo sale pulsando seguido; también X / RB / 👊)
	CommandRegistry.register({
		Id = "Atacar",
		Label = "Atacar",
		Icon = "👊",
		Priority = 7,
		When = function(ctx)
			return not baby(ctx) and not ctx.Seated
		end,
		Run = function()
			CombatController.attack()
		end,
		Stay = true,
	} :: any)

	-- Lo de siempre
	CommandRegistry.register({
		Id = "Objetos",
		Label = "Objetos",
		Icon = "🎒",
		Priority = 50,
		When = function(ctx)
			return not baby(ctx)
		end,
		Run = function()
			Hud.runCommand("Mochila")
		end,
	})
	CommandRegistry.register({
		Id = "Mapa",
		Label = "Mapa",
		Icon = "🗺",
		Priority = 51,
		When = function(ctx)
			return not baby(ctx)
		end,
		Run = function()
			Hud.runCommand("Mapa")
		end,
	})
	CommandRegistry.register({
		Id = "Telefono",
		Label = "Teléfono",
		Icon = "📱",
		Priority = 52,
		When = function(ctx)
			return not baby(ctx)
		end,
		Run = function()
			Hud.runCommand("Telefono")
		end,
	})

	-- "MÁS": lo que se usa de vez en cuando
	local more: Command = {
		Id = "Mas",
		Label = "Más",
		Icon = "✦",
		Priority = 60,
		Open = function()
			return {
				{ Id = "Misiones", Label = "Misiones", Icon = "📋", Priority = 1, Badge = Hud.questPending(), Run = function()
					Hud.runCommand("Misiones")
				end } :: any,
				{ Id = "Personaje", Label = "Personaje", Icon = "⭐", Priority = 2, Run = function()
					Hud.runCommand("Personaje")
				end },
				{ Id = "Vehiculos", Label = "Vehículos", Icon = "🚲", Priority = 3, Run = function()
					Vehicles.open()
				end },
				{
					Id = "Gestos",
					Label = "Gestos",
					Icon = "😀",
					Priority = 4,
					Open = function()
						local list = {}
						for i, emote in Actions.emotes() do
							table.insert(list, { Id = "Gesto" .. i, Label = emote.Name, Icon = emote.Icon, Priority = i, Run = function()
								Actions.emote(emote.Name)
							end })
						end
						return list
					end,
				},
				{ Id = "Menu", Label = "Menú", Icon = "☰", Priority = 5, Run = function()
					Hud.runCommand("Menu")
				end },
			}
		end,
	}
	-- (va como proveedor para que el punto rojo de misión nueva salga también aquí)
	CommandRegistry.addProvider(function(ctx)
		if baby(ctx) then
			return {}
		end
		local command = table.clone(more) :: any
		command.Badge = Hud.questPending()
		return { command }
	end)
end

return DefaultCommands
