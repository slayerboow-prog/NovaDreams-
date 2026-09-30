-- DefaultCommands: los comandos del juego. Para añadir uno nuevo basta con registrarlo aquí
-- (o desde cualquier otro módulo) con CommandRegistry.register.
--
-- Orden (Priority, de arriba abajo):
--   1-3   lo que tienes delante (un comando por cada cosa cercana: hablar, entrar, montar…)
--   4     más cosas cercanas, en un grupo "AQUÍ ▸"
--   5-9   lo que depende de la situación (saludar a alguien, bajarte del vehículo, atacar…)
--   50+   lo de siempre: objetos, mapa, las apps (Ir a casa, Ruta a casa, Tienda, Vehículos, Gestos,
--         Metro, Mercadillo…: las pone cada sistema con Hud.addButton, entre 52 y 56) y
--         "MÁS ▸" (misiones, mi historia, personaje, menú)
-- La complejidad crece con la edad: de bebé solo lo que tienes delante.

local CommandRegistry = require(script.Parent.CommandRegistry)
local Hud = require(script.Parent.Parent.UI.Hud)
local Actions = require(script.Parent.Parent.Controllers.Actions)
local Vehicles = require(script.Parent.Parent.Controllers.Vehicles)
local CombatController = require(script.Parent.Parent.Controllers.CombatController)
local WeaponController = require(script.Parent.Parent.Controllers.WeaponController)
local InstitutionsUI = require(script.Parent.Parent.Controllers.InstitutionsUI)
local StoryJournal = require(script.Parent.Parent.Controllers.StoryJournal)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Wanted = require(ReplicatedStorage.Shared.Wanted)

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
				Icon = "lugar",
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
		Icon = "saludar",
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
		Icon = "bajarse",
		Priority = 6,
		When = function(ctx)
			return ctx.Seated
		end,
		Run = function()
			Vehicles.dismount()
		end,
	})

	-- Pelear (el combo sale pulsando seguido; también X / RB / el botón Ataque). En plena pelea,
	-- Atacar, Habilidades, Objetos, Defensa y Huir suben arriba del todo.
	CommandRegistry.addProvider(function(ctx)
		if baby(ctx) or ctx.Seated then
			return {}
		end
		local armed = WeaponController.armed()
		local fighting = CombatController.inCombat() or armed
		local out: { Command } = {}
		if armed then
			-- Con un arma en la mano: Disparar (en vez de Atacar), Apuntar y Recargar
			table.insert(out, { Id = "Disparar", Label = "Disparar", Icon = "disparar", Priority = 0.1, Accent = true, Run = function()
				WeaponController.fire()
			end, Stay = true } :: any)
			table.insert(out, { Id = "Apuntar", Label = if WeaponController.isAiming() then "Dejar de apuntar" else "Apuntar", Icon = "objetivo", Priority = 0.12, Run = function()
				WeaponController.toggleAim()
			end, Stay = true } :: any)
			table.insert(out, { Id = "Recargar", Label = "Recargar", Icon = "recargar", Priority = 0.14, Run = function()
				WeaponController.reload()
			end, Stay = true } :: any)
			table.insert(out, { Id = "GuardarArma", Label = "Guardar el arma", Icon = "bajarse", Priority = 0.35, Run = function()
				WeaponController.holster()
			end })
		else
			table.insert(out, { Id = "Atacar", Label = "Atacar", Icon = "espada", Priority = if fighting then 0.1 else 7, Accent = fighting, Run = function()
				CombatController.attack()
			end, Stay = true } :: any)
		end
		if fighting then
			table.insert(out, { Id = "Habilidades", Label = "Habilidades", Icon = "habilidades", Priority = 0.15, Run = function()
				Hud.runCommand("Personaje")
			end })
			table.insert(out, { Id = "Defender", Label = "Defensa", Icon = "escudo", Priority = 0.2, Run = function()
				CombatController.guard(1.2)
			end, Stay = true } :: any)
			table.insert(out, { Id = "Huir", Label = "Huir", Icon = "esquivar", Priority = 0.3, Run = function()
				CombatController.flee()
			end })
		end
		return out
	end)

	-- Junto a otro jugador: robarle (desde adolescente) o, si eres policía de servicio y le buscan, detenerle
	CommandRegistry.addProvider(function(ctx)
		local other: Player? = nil
		for _, target in ctx.Targets or {} do
			if target.Prompt.Name == "PlayerPrompt" and target.Distance <= Wanted.StealRange then
				local character = target.Prompt:FindFirstAncestorOfClass("Model")
				other = character and Players:GetPlayerFromCharacter(character)
				break
			end
		end
		if not other or baby(ctx) or ctx.Seated then
			return {}
		end
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild("Wanted") :: RemoteEvent?
		local out = {}
		local me = Players.LocalPlayer
		local job = me:GetAttribute("Job")
		-- Instituciones: dar la libertad a un preso (jefes) e inspeccionar a quien no ha declarado
		if other:GetAttribute("JailUntil") and me:GetAttribute("Chief") and (job == "Funcionario" or job == "Juez") then
			table.insert(out, { Id = "Liberar", Label = "Liberar", Detail = other.DisplayName, Icon = "liberar", Priority = 4.4, Accent = true, Run = function()
				local justice = remotes and remotes:FindFirstChild("Justice") :: RemoteEvent?
				if justice then
					justice:FireServer("Release", other)
				end
			end })
		end
		if job == "Funcionario" and other:GetAttribute("JailUntil") then
			table.insert(out, { Id = "Registrar", Label = "Registrar", Detail = other.DisplayName, Icon = "registrar", Priority = 4.3, Accent = true, Run = function()
				local prison = remotes and remotes:FindFirstChild("Prison") :: RemoteEvent?
				if prison then
					prison:FireServer("Search", other)
				end
			end })
		end
		if job == "Hacienda" and other:GetAttribute("TaxOverdue") then
			table.insert(out, { Id = "Inspeccionar", Label = "Inspeccionar", Detail = other.DisplayName, Icon = "hacienda", Priority = 4.6, Accent = true, Run = function()
				local tax = remotes and remotes:FindFirstChild("Tax") :: RemoteEvent?
				if tax then
					tax:FireServer("Inspect", other)
				end
			end })
		end
		if me:GetAttribute("Job") == "Policia" and other:GetAttribute("Wanted") then
			table.insert(out, { Id = "Detener", Label = "Detener", Detail = other.DisplayName, Icon = "detener", Priority = 4.5, Accent = true, Run = function()
				if remote then
					remote:FireServer("Arrest", other)
				end
			end })
		elseif ctx.Stage == nil or Stages.inRange(ctx.Stage, Wanted.MinStage, nil) then
			table.insert(out, { Id = "Robar", Label = "Robar", Detail = other.DisplayName, Icon = "robar", Priority = 8, Run = function()
				if remote then
					remote:FireServer("Steal", other)
				end
			end })
		end
		return out
	end)

	-- Lo de siempre
	-- (Objetos va como proveedor: en plena pelea sube, entre Habilidades y Defensa)
	CommandRegistry.addProvider(function(ctx)
		if baby(ctx) then
			return {}
		end
		return {
			{ Id = "Objetos", Label = "Objetos", Icon = "mochila", Priority = if not ctx.Seated and (CombatController.inCombat() or WeaponController.armed()) then 0.18 else 50, Run = function()
				Hud.runCommand("Mochila")
			end },
		}
	end)
	CommandRegistry.register({
		Id = "Mapa",
		Label = "Mapa",
		Icon = "mapa",
		Priority = 51,
		When = function(ctx)
			return not baby(ctx)
		end,
		Run = function()
			Hud.runCommand("Mapa")
		end,
	})
	-- (El antiguo «Teléfono» abría el menú rápido: sus apps son ahora filas de esta lista)

	-- 🔧 «Modo pruebas»: solo para quien tiene el atributo Tester (lo pone el servidor). Abre el panel
	-- de pruebas (UI/TesterPanel); se carga al tocarlo y dentro de un pcall: si falta, el HUD sigue igual
	local me = Players.LocalPlayer
	CommandRegistry.register({
		Id = "ModoPruebas",
		Label = "Modo pruebas",
		Icon = "🔧",
		Priority = 59,
		When = function()
			return me:GetAttribute("Tester") == true
		end,
		Run = function()
			local ok, err = pcall(function()
				local ui = script.Parent.Parent:FindFirstChild("UI")
				local module = ui and ui:FindFirstChild("TesterPanel")
				assert(module, "no está el módulo UI/TesterPanel")
				require(module :: any).toggle()
			end)
			if not ok then
				warn("[Comandos] Modo pruebas: " .. tostring(err))
				Hud.toast("Error", "🔧 El panel de pruebas no está disponible")
			end
		end,
	})
	-- Al darte (o quitarte) el atributo, la fila sale (o se va) enseguida
	me:GetAttributeChangedSignal("Tester"):Connect(function()
		local ok, CommandMenu = pcall(require, script.Parent:FindFirstChild("CommandMenu") :: any)
		if ok and CommandMenu and CommandMenu.refresh then
			CommandMenu.refresh()
		end
	end)

	-- "MÁS": lo que se usa de vez en cuando
	local more: Command = {
		Id = "Mas",
		Label = "Más",
		Icon = "mas",
		Priority = 60,
		Open = function()
			return {
				{ Id = "Misiones", Label = "Misiones", Icon = "misiones", Priority = 1, Badge = Hud.questPending(), Run = function()
					Hud.runCommand("Misiones")
				end } :: any,
				-- 📖 «Mi historia» (el diario): en el móvil la pestaña «Tu vida» se aparta, así que va aquí
				{ Id = "Historia", Label = "Mi historia", Icon = "📖", Priority = 1.5, Run = function()
					StoryJournal.open()
				end },
				{ Id = "Personaje", Label = "Personaje", Icon = "personaje", Priority = 2, Run = function()
					Hud.runCommand("Personaje")
				end },
				{ Id = "Viviendas", Label = "Mis viviendas", Icon = "viviendas", Priority = 4.4, Run = function()
					local homes = Players.LocalPlayer:GetAttribute("Homes")
					if homes then
						for line in string.gmatch(homes, "[^\n]+") do
							Hud.toast("Info", "🏠 " .. line)
						end
					else
						Hud.toast("Info", "🏠 Aún no tienes vivienda. Entra en casas y pisos: los que tienen el cartel SE VENDE se pueden comprar.")
					end
				end },
				{ Id = "Carrera", Label = "Mi carrera", Icon = "carrera", Priority = 4.5, Run = function()
					InstitutionsUI.showCareer()
				end },
				{ Id = "Controles", Label = "Controles", Icon = "mando", Priority = 4.8, Run = function()
					Hud.runCommand("Controles")
				end },
				{ Id = "Menu", Label = "Menú", Icon = "menu", Priority = 5, Run = function()
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
