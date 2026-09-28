-- Controls (cliente): quita y devuelve el control del personaje con un contador por motivo.
-- Antes cada sistema (conversaciones, cinemáticas) llamaba a Enable/Disable por su cuenta y, si se
-- solapaban, el primero en acabar devolvía el control a mitad del otro. Ahora cada uno pide
-- Controls.disable("Motivo") y lo suelta con Controls.enable("Motivo"): el personaje solo vuelve a
-- moverse cuando ya no queda ningún motivo. Pedir dos veces el mismo motivo cuenta como uno.

local Players = game:GetService("Players")

local Controls = {}

local player = Players.LocalPlayer
local holders: { [string]: boolean } = {}
local watching = false

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

local function watch()
	if watching then
		return
	end
	watching = true
	-- Al reaparecer, el módulo de Roblox vuelve a encender los controles: se reaplica lo pedido
	player.CharacterAdded:Connect(function()
		task.defer(function()
			if next(holders) ~= nil then
				apply()
			end
		end)
	end)
end

function Controls.disable(reason: string)
	watch()
	holders[reason] = true
	apply()
end

function Controls.enable(reason: string)
	if not holders[reason] then
		return
	end
	holders[reason] = nil
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
