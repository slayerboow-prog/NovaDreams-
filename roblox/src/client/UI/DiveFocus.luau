-- DiveFocus: buceando, fuera lo del HUD que no sirve bajo el agua y estorba al de buceo (como
-- UI/FlightFocus para volar). docs/mar/diseno.md.
--
--   DiveFocus.enter()  esconde el GPS («Gira a la derecha en…»: su sitio lo usa la cápsula del objetivo
--                      del mar, HudLayout.Items.DiveObjective) y las notas y pistas (su hueco lo usa el
--                      panel de buceo, HudLayout.Items.DivePanel), y algún aviso suelto. Lo demás se
--                      queda (estado, minimapa, misión, barra rápida, Teléfono e Inventario, botones).
--   DiveFocus.exit()   todo vuelve como estaba.
-- Mientras dura, si otro sistema vuelve a encender una de esas pantallas, se apaga otra vez (y se recuerda
-- que la quería encendida).

local DiveFocus = {}

DiveFocus.Hidden = {
	"GpsGui",
	"GuideGui",
	"GuideHighlight",
	"BattlePassTip",
}

local active = false
local wanted: { [ScreenGui]: boolean } = {}
local conns: { RBXScriptConnection } = {}
local guarding = false

local function playerGui(): Instance?
	local ok, pg = pcall(function()
		return game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end)
	return if ok then pg else nil
end

local function hide(gui: ScreenGui)
	if wanted[gui] ~= nil then
		return
	end
	wanted[gui] = gui.Enabled
	gui.Enabled = false
	pcall(function()
		table.insert(conns, gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if active and not guarding and gui.Enabled then
				wanted[gui] = true
				guarding = true
				gui.Enabled = false
				guarding = false
			elseif active and not guarding then
				wanted[gui] = false
			end
		end))
	end)
end

function DiveFocus.isActive(): boolean
	return active
end

function DiveFocus.enter()
	if active then
		return
	end
	active = true
	local set = {}
	for _, name in DiveFocus.Hidden do
		set[name] = true
	end
	local pg = playerGui()
	if pg then
		for _, child in pg:GetChildren() do
			if child:IsA("ScreenGui") and set[child.Name] then
				hide(child)
			end
		end
		pcall(function()
			table.insert(conns, pg.ChildAdded:Connect(function(child)
				if active and child:IsA("ScreenGui") and set[child.Name] then
					hide(child)
				end
			end))
		end)
	end
end

function DiveFocus.exit()
	if not active then
		return
	end
	active = false
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	for gui, on in wanted do
		if gui.Parent then
			gui.Enabled = on
		end
	end
	table.clear(wanted)
end

return DiveFocus
