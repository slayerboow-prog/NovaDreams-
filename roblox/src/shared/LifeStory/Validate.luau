-- Validate: revisa que los datos de la historia estén bien escritos (claves de texto que existen,
-- lugares que existen, misiones que existen, pasos con el tipo correcto...).
-- El servidor lo ejecuta al arrancar y avisa en Output; también se usa en las pruebas automáticas.

local Chapters = require(script.Parent.Chapters)
local Quests = require(script.Parent.Quests)
local Locations = require(script.Parent.Locations)
local Stages = require(script.Parent.Stages)
local Strings = require(script.Parent.Strings)
local Roles = require(script.Parent.Parent.Roles)
local Cinematics = require(script.Parent.Cinematics)
local Config = require(script.Parent.Parent.Config)

local Validate = {}

local STEP_TYPES = {
	Reach = { "Place" },
	Event = { "Event" },
	Talk = { "Npc" },
	Choice = { "Key", "PromptKey", "Options" },
	Wait = { "GameMinutes" },
	Group = { "Steps" },
	Moment = {},
	Transition = {},
	Cinematic = { "Id" },
}
local GROUP_CHILD = { Reach = true, Event = true, Talk = true }

function Validate.run(): { string }
	local errors = {}
	local function err(fmt: string, ...)
		table.insert(errors, fmt:format(...))
	end
	local function text(where: string, key: string?)
		if key and not Strings.has(key) then
			err("%s: falta el texto '%s'", where, key)
		end
	end
	local function requirements(where: string, req: { [string]: any }?)
		if not req then
			return
		end
		if req.Stage then
			for _, s in { req.Stage.Min, req.Stage.Max } do
				if s and not Stages.isValid(s) then
					err("%s: etapa desconocida '%s'", where, s)
				end
			end
		end
		for _, id in req.Completed or {} do
			if not Quests[id] then
				err("%s: requiere una misión que no existe '%s'", where, id)
			end
		end
	end
	local function step(where: string, s: { [string]: any }, inGroup: boolean)
		local fields = STEP_TYPES[s.Type]
		if not fields then
			err("%s: tipo de paso desconocido '%s'", where, tostring(s.Type))
			return
		end
		if inGroup and not GROUP_CHILD[s.Type] then
			err("%s: un Group solo admite Reach, Event o Talk", where)
		end
		for _, field in fields do
			if s[field] == nil then
				err("%s: al paso %s le falta '%s'", where, s.Type, field)
			end
		end
		text(where, s.TextKey)
		if s.Type ~= "Moment" and s.Type ~= "Transition" and s.Type ~= "Cinematic" and not s.TextKey then
			err("%s: el paso %s necesita TextKey", where, s.Type)
		end
		if (s.Type == "Reach" or s.Place ~= nil) and not Locations.Places[s.Place] then
			err("%s: lugar desconocido '%s'", where, tostring(s.Place))
		end
		if s.Type == "Cinematic" and not Cinematics[s.Id] then
			err("%s: cinemática desconocida '%s'", where, tostring(s.Id))
		end
		if s.Cinematic and not Cinematics[s.Cinematic] then
			err("%s: cinemática desconocida '%s'", where, tostring(s.Cinematic))
		end
		if s.Type == "Choice" then
			text(where, s.PromptKey)
			for _, option in s.Options or {} do
				text(where, option.TextKey)
			end
		end
		if s.Type == "Group" then
			for i, child in s.Steps do
				step(where .. ".g" .. i, child, true)
			end
		end
		if s.SetStage and not Stages.isValid(s.SetStage) then
			err("%s: etapa desconocida '%s'", where, s.SetStage)
		end
		requirements(where .. ".If", s.If)
	end

	for id, quest in Quests do
		text(id, quest.TitleKey)
		text(id, quest.MomentKey)
		requirements(id, quest.Requires)
		if quest.Kind == "Side" then
			if not quest.Offer then
				err("%s: una secundaria necesita Offer", id)
			elseif quest.Offer.Place and not Locations.Places[quest.Offer.Place] then
				err("%s: Offer con lugar desconocido '%s'", id, quest.Offer.Place)
			end
			text(id, quest.OfferKey)
		elseif quest.Kind ~= "Main" then
			err("%s: Kind debe ser Main o Side", id)
		end
		if #quest.Steps == 0 then
			err("%s: no tiene pasos", id)
		end
		for i, s in quest.Steps do
			step(id .. ".s" .. i, s, false)
		end
		if quest.Rewards and quest.Rewards.SetStage and not Stages.isValid(quest.Rewards.SetStage) then
			err("%s: SetStage desconocida", id)
		end
	end

	for id, chapter in Chapters do
		if chapter.Id ~= id then
			err("capítulo %s: Id no coincide", id)
		end
		text(id, chapter.TitleKey)
		text(id, chapter.IntroKey)
		text(id, chapter.OutroKey)
		requirements(id, { Stage = chapter.Stage })
		for _, questId in chapter.Main do
			local quest = Quests[questId]
			if not quest then
				err("capítulo %s: misión inexistente '%s'", id, questId)
			elseif quest.Kind ~= "Main" then
				err("capítulo %s: '%s' no es Main", id, questId)
			end
		end
		for _, field in { "IntroCinematic", "OutroCinematic" } do
			if chapter[field] and not Cinematics[chapter[field]] then
				err("capítulo %s: %s desconocida '%s'", id, field, chapter[field])
			end
		end
		if chapter.Music and not Config.Audio.Music[chapter.Music] then
			err("capítulo %s: música desconocida '%s'", id, chapter.Music)
		end
		if chapter.Next and not Chapters[chapter.Next] then
			err("capítulo %s: Next inexistente '%s'", id, chapter.Next)
		end
	end

	for id, place in Locations.Places do
		text("lugar " .. id, place.NameKey)
		if not (place.Model or place.Tag or place.Special) then
			err("lugar %s: necesita Model, Tag o Special", id)
		end
	end

	for id, cine in Cinematics do
		local where = "cinemática " .. id
		if type(cine.Duration) ~= "number" or cine.Duration <= 0 then
			err("%s: falta Duration", where)
		end
		for name, anchor in cine.Anchors or {} do
			local kind, value = anchor:match("^(%a+):(.+)$")
			if anchor ~= "Player" and not (kind == "Place" and Locations.Places[value]) and not (kind == "Zone" and table.find(Locations.Zones, value)) then
				err("%s: ancla %s no válida '%s'", where, name, anchor)
			end
		end
		local function point(p: any)
			if p and not (cine.Anchors or {})[p[1]] then
				err("%s: plano con ancla sin definir '%s'", where, tostring(p[1]))
			end
		end
		for _, shot in cine.Shots or {} do
			if shot.Orbit then
				point({ shot.Orbit })
			else
				point(shot.From)
				point(shot.To)
				point(shot.Look)
				point(shot.LookTo)
			end
		end
		for _, line in cine.Lines or {} do
			text(where, line.TextKey)
		end
		for _, title in cine.Titles or {} do
			text(where, title.TextKey)
			text(where, title.SubKey)
		end
		if cine.Music and not Config.Audio.Music[cine.Music] then
			err("%s: música desconocida '%s'", where, cine.Music)
		end
		if cine.Sting and not Config.Audio.Stings[cine.Sting] then
			err("%s: efecto desconocido '%s'", where, cine.Sting)
		end
	end

	for id, role in Roles do
		text("rol " .. id, role.NameKey)
	end

	table.sort(errors)
	return errors
end

return Validate
