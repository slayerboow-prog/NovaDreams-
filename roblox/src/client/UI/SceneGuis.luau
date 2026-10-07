-- SceneGuis (cliente): apagar la interfaz mientras se ve una escena (Controllers/Cinematics y
-- Controllers/HappeningClient) y volver a dejarla como estaba al acabar.
--
--   local restore = SceneGuis.hide(miPantalla, { CoreAll = true, Skip = { StoryFlash = true } })
--   ...
--   restore()
--
-- * Varias escenas a la vez (una cinemática y una escena de la historia): la interfaz solo vuelve
--   cuando acaba la ÚLTIMA (antes, al acabar la primera se encendía todo encima de la otra).
-- * Una pantalla que se cierra durante la escena (el diario, el mapa, la mochila…) no se vuelve a
--   encender al acabar: quien la cierre con SceneGuis.setEnabled(gui, false) la quita de la lista, y
--   quien la abra con SceneGuis.setEnabled(gui, true) en plena escena la deja apagada hasta el final.
-- * Lo de Roblox (chat, lista de jugadores…) se apunta al empezar la primera escena y se deja igual
--   al acabar la última.

local Players = game:GetService("Players")

-- Lo de Roblox (StarterGui:SetCoreGuiEnabled): con pcall, por si no se puede (pruebas fuera de Roblox)
local function starterGui(): any
	local ok, service = pcall(function()
		return game:GetService("StarterGui")
	end)
	return if ok then service else nil
end

local SceneGuis = {}

local player = Players.LocalPlayer
local active = 0 -- escenas en pantalla
local hidden: { [ScreenGui]: boolean } = {} -- pantallas apagadas por las escenas (se encienden al final)
local own: { [ScreenGui]: boolean } = {} -- la pantalla de cada escena (nunca se enciende al final)
local core: { [Enum.CoreGuiType]: boolean }? = nil

local ATTRIBUTE = "SceneHidden"

-- ¿Hay alguna escena apagando la interfaz ahora?
function SceneGuis.active(): boolean
	return active > 0
end

local function saveCore()
	local saved: { [Enum.CoreGuiType]: boolean } = {}
	local StarterGui = starterGui()
	pcall(function()
		for _, kind in Enum.CoreGuiType:GetEnumItems() do
			if kind ~= Enum.CoreGuiType.All then
				local ok, enabled = pcall(function()
					return StarterGui:GetCoreGuiEnabled(kind)
				end)
				if ok and type(enabled) == "boolean" then
					saved[kind] = enabled
				end
			end
		end
	end)
	core = saved
end

local function restoreAll()
	for gui in hidden do
		if gui.Parent and gui:GetAttribute(ATTRIBUTE) == true and not own[gui] then
			gui.Enabled = true
		end
		pcall(function()
			gui:SetAttribute(ATTRIBUTE, nil)
		end)
	end
	table.clear(hidden)
	local saved = core
	core = nil
	local StarterGui = starterGui()
	if saved and StarterGui then
		for kind, enabled in saved do
			pcall(function()
				StarterGui:SetCoreGuiEnabled(kind, enabled)
			end)
		end
	end
end

-- Apaga todas las pantallas encendidas menos `except` (la de la escena). options.CoreAll: apaga
-- también todo lo de Roblox (si no, solo la mochila de Roblox). options.Skip: nombres que no se tocan.
-- Devuelve la función que la escena llama al acabar (una vez basta; las demás no hacen nada).
function SceneGuis.hide(except: ScreenGui?, options: { CoreAll: boolean?, Skip: { [string]: boolean }? }?): () -> ()
	local opts = options or {}
	if active == 0 then
		saveCore()
	end
	active += 1
	if except then
		own[except] = true
		hidden[except] = nil
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child ~= except and child.Enabled and not (opts.Skip and opts.Skip[child.Name]) then
			child.Enabled = false
			child:SetAttribute(ATTRIBUTE, true)
			hidden[child] = true
		end
	end
	local StarterGui = starterGui()
	pcall(function()
		if opts.CoreAll then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		else
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end
	end)
	local done = false
	return function()
		if done then
			return
		end
		done = true
		active = math.max(0, active - 1)
		if except then
			own[except] = nil
			hidden[except] = nil -- (la pantalla de una escena que acaba no la enciende nadie)
		end
		if active == 0 then
			restoreAll()
		end
	end
end

-- Encender o apagar una pantalla propia sin pelearse con las escenas: apagada por una escena, al
-- cerrarla ya no vuelve al acabar; al abrirla en plena escena se queda apagada y vuelve al final.
function SceneGuis.setEnabled(gui: ScreenGui, on: boolean)
	if active > 0 and (hidden[gui] or on) and not own[gui] then
		if on then
			gui.Enabled = false
			gui:SetAttribute(ATTRIBUTE, true)
			hidden[gui] = true
		else
			gui:SetAttribute(ATTRIBUTE, nil)
			hidden[gui] = nil
			gui.Enabled = false
		end
		return
	end
	gui.Enabled = on
end

-- ¿Está "abierta" la pantalla? (encendida, o apagada solo por la escena y volverá al final)
function SceneGuis.isOn(gui: ScreenGui): boolean
	return gui.Enabled or (hidden[gui] == true and gui:GetAttribute(ATTRIBUTE) == true)
end

-- (pruebas) empezar de cero
function SceneGuis._reset()
	active = 0
	table.clear(hidden)
	table.clear(own)
	core = nil
end

return SceneGuis
