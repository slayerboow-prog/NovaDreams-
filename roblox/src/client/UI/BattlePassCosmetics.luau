-- BattlePassCosmetics (cliente): lee los cosméticos del pase que lleva cada jugador y dice cómo se ven.
-- NO decide nada: los atributos BP_* los pone SOLO el servidor (BattlePassRewardService.sync, con lo que
-- tienes Y llevas equipado). Con BattlePassConfig.Enabled = false todo devuelve «nada» y no se pinta nada.
--
--   Cosmetics.title(player)      -> texto, color   (el título encima de la cabeza: Controllers/NameTags)
--   Cosmetics.nameplate(player)  -> { Background, Stroke, Text }? (la placa del nombre: NameTags)
--   Cosmetics.emotes(player)     -> gestos del pase que tiene (Controllers/Actions los añade a los suyos)
--   Cosmetics.hudAccent(player) / phoneAccent(player) -> Color3? (tema del HUD y del teléfono)
--   Cosmetics.start()            -> tu tema del HUD y del teléfono se aplican con Theme.setAccent (solo
--                                   colores: el filo de los paneles y la pestaña de COMANDOS)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)

local Cosmetics = {}

local MAX_TITLE = 40

local config: { [string]: any }? = nil
local catalog: { [string]: any }? = nil

local function shared(name: string): any
	local ok, result = pcall(function()
		return require((ReplicatedStorage :: any).Shared.BattlePass[name])
	end)
	return if ok and type(result) == "table" then result else nil
end

function Cosmetics.enabled(): boolean
	config = config or shared("Config")
	-- (pase apagado: solo los testers, modo pruebas)
	return config ~= nil and (config.Enabled == true or Players.LocalPlayer:GetAttribute("Tester") == true)
end

-- La definición de un cosmético, solo si existe y es de ese tipo (y con el pase encendido)
function Cosmetics.def(id: any, typeName: string): { [string]: any }?
	if type(id) ~= "string" or not Cosmetics.enabled() then
		return nil
	end
	catalog = catalog or shared("Catalog")
	local def = catalog and catalog.get(id)
	return if def and def.Type == typeName then def else nil
end

function Cosmetics.title(player: Player): (string?, Color3?)
	if not Cosmetics.enabled() then
		return nil, nil
	end
	local text = player:GetAttribute("BP_Title")
	if type(text) ~= "string" or text == "" then
		return nil, nil
	end
	local color = player:GetAttribute("BP_TitleColor")
	return string.sub(text, 1, MAX_TITLE), if typeof(color) == "Color3" then color else nil
end

function Cosmetics.nameplate(player: Player): { [string]: Color3 }?
	local def = Cosmetics.def(player:GetAttribute("BP_Nameplate"), "Nameplate")
	local colors = def and def.Colors
	if type(colors) ~= "table" or typeof(colors.Background) ~= "Color3" then
		return nil
	end
	return colors
end

-- ¿Lleva título o placa? (entonces su nombre sale con nuestro cartel)
function Cosmetics.hasTag(player: Player): boolean
	return Cosmetics.title(player) ~= nil or Cosmetics.nameplate(player) ~= nil
end

local function accentOf(player: Player, attribute: string, typeName: string): Color3?
	local def = Cosmetics.def(player:GetAttribute(attribute), typeName)
	local accent = def and type(def.Colors) == "table" and def.Colors.Accent
	return if typeof(accent) == "Color3" then accent else nil
end

function Cosmetics.hudAccent(player: Player): Color3?
	return accentOf(player, "BP_HudSkin", "HudSkin")
end

function Cosmetics.phoneAccent(player: Player): Color3?
	return accentOf(player, "BP_PhoneTheme", "PhoneTheme")
end

export type Emote = { Id: string, Name: string, Icon: string, AnimationId: number, Loop: boolean, Speed: number }

-- Los gestos del pase que tiene (BP_Emotes: Ids separados por comas), en el orden del catálogo
function Cosmetics.emotes(player: Player): { Emote }
	local out = {}
	local list = if Cosmetics.enabled() then player:GetAttribute("BP_Emotes") else nil
	if type(list) ~= "string" or list == "" then
		return out
	end
	for id in string.gmatch(list, "[^,]+") do
		local def = Cosmetics.def(id, "Emote")
		if def and type(def.AnimationId) == "number" then
			table.insert(out, {
				Id = id,
				Name = tostring(def.Name or id),
				Icon = tostring(def.Icon or "✨"),
				AnimationId = def.AnimationId,
				Loop = def.Loop == true,
				Speed = if type(def.Speed) == "number" then def.Speed else 1,
			})
		end
	end
	return out
end

local started = false
function Cosmetics.start()
	if started or not Cosmetics.enabled() then
		return -- (pase apagado: el HUD y COMANDOS se quedan como siempre)
	end
	started = true
	local player = Players.LocalPlayer
	local function apply()
		Theme.setAccent("Hud", Cosmetics.hudAccent(player))
		Theme.setAccent("Phone", Cosmetics.phoneAccent(player))
	end
	player:GetAttributeChangedSignal("BP_HudSkin"):Connect(apply)
	player:GetAttributeChangedSignal("BP_PhoneTheme"):Connect(apply)
	apply()
end

return Cosmetics
