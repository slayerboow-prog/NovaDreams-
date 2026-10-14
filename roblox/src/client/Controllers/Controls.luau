-- Controls (cliente): quita y devuelve el control del personaje con un contador por motivo.
-- Antes cada sistema (conversaciones, cinemáticas) llamaba a Enable/Disable por su cuenta y, si se
-- solapaban, el primero en acabar devolvía el control a mitad del otro. Ahora cada uno pide
-- Controls.disable("Motivo") y lo suelta con Controls.enable("Motivo"): el personaje solo vuelve a
-- moverse cuando ya no queda ningún motivo. Pedir dos veces el mismo motivo cuenta como uno.
--
-- Red de seguridad (los controles SIEMPRE vuelven): quien quita el control puede decir cómo saber si
-- sigue haciéndole falta, Controls.disable("Cinematica", function() return hayEscena end). Si esa
-- pregunta dice que no (o falla), el motivo se suelta solo: al reaparecer y cada pocos segundos. Así,
-- si un sistema se rompe a medias sin llamar a enable, el personaje no se queda congelado para siempre.
-- Controls.releaseAll() lo suelta todo (para un caso extremo, p. ej. el modo pruebas).

local Players = game:GetService("Players")

local Controls = {}

local player = Players.LocalPlayer
local holders: { [string]: boolean } = {}
local checks: { [string]: () -> boolean } = {} -- motivo → ¿sigue haciéndole falta?
local watching = false
local sweeping = false
Controls.SweepSeconds = 2 -- cada cuánto se miran los motivos con pregunta

local function controlModule(): any
	local ok, controls = pcall(function()
		local scripts = player:WaitForChild("PlayerScripts", 5)
		local module = scripts and scripts:WaitForChild("PlayerModule", 5)
		return module and (require(module :: any) :: any):GetControls()
	end)
	return if ok then controls else nil
end

local function apply()
	local controls = controlModule()
	if not controls then
		return
	end
	-- (se mira al final: si otro motivo cambió mientras se esperaba al módulo, manda el último estado)
	pcall(function()
		if next(holders) ~= nil then
			controls:Disable()
		else
			controls:Enable()
		end
	end)
end

-- Suelta los motivos cuya pregunta dice que ya no hacen falta. Devuelve cuántos ha soltado.
function Controls.sweep(): number
	local released = 0
	for reason, check in checks do
		local ok, still = pcall(check)
		if holders[reason] and not (ok and still) then
			holders[reason] = nil
			checks[reason] = nil
			released += 1
			warn(("[Controls] '%s' tenía el control sin necesitarlo: se devuelve"):format(reason))
		elseif not holders[reason] then
			checks[reason] = nil
		end
	end
	if released > 0 then
		apply()
	end
	return released
end

local function startSweeping()
	if sweeping then
		return
	end
	sweeping = true
	task.spawn(function()
		while next(checks) ~= nil do
			task.wait(Controls.SweepSeconds)
			Controls.sweep()
		end
		sweeping = false
	end)
end

local function watch()
	if watching then
		return
	end
	watching = true
	-- Al reaparecer, el módulo de Roblox vuelve a encender los controles: se reaplica lo pedido
	-- (antes se sueltan los motivos que ya no hacen falta: morir no deja a nadie congelado)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			Controls.sweep()
			if next(holders) ~= nil then
				apply()
			end
		end)
	end)
end

-- stillNeeded (opcional): cómo saber si este motivo sigue necesitando el control quitado
function Controls.disable(reason: string, stillNeeded: (() -> boolean)?)
	watch()
	holders[reason] = true
	checks[reason] = stillNeeded
	if stillNeeded then
		startSweeping()
	end
	apply()
end

function Controls.enable(reason: string)
	checks[reason] = nil
	if not holders[reason] then
		return
	end
	holders[reason] = nil
	apply()
end

-- Lo devuelve todo (nadie se queda con el control)
function Controls.releaseAll()
	table.clear(holders)
	table.clear(checks)
	apply()
end

-- ¿Hay algo que tiene el control quitado? (o ese motivo en concreto)
function Controls.isDisabled(reason: string?): boolean
	if reason then
		return holders[reason] == true
	end
	return next(holders) ~= nil
end

return Controls
