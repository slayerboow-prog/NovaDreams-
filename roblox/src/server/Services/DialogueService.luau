-- DialogueService: las conversaciones de la historia, por turnos y con respuestas del jugador.
--
-- Un diálogo es una lista de líneas (datos de las misiones, ver docs/historia/11):
--   { S = "Nico", T = "¡Tú dijiste que te gusta el fútbol!", If = {…}, Effects = {…}, A = "Cheer"? }
--   (A = el gesto con que lo dice; si no se pone, se adivina por el texto: ver shared/LifeStory/Emotion)
--   { Ask = "¿Qué le dices?", Options = { { T = "…", If = {…}, Effects = {…}, Then = { líneas… } }, … } }
-- S = quién habla (Cast), "Yo" = el jugador, "Narrador" (o nada) = texto sin personaje.
--
-- El servidor decide qué líneas se ven (las condiciones se comprueban aquí, con lo que el personaje
-- recuerda), aplica los efectos y manda al cliente trozos de conversación hasta cada pregunta.
-- El cliente (DialogueUI) los enseña con cámara y voz, y devuelve la respuesta elegida.
--
-- Además: DialogueService.bark = una frase suelta en un globo, sin parar el juego ("¡Vas a llegar tarde!").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Emotion = require(ReplicatedStorage.Shared.LifeStory.Emotion)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)

local DialogueService = {}

local Remote: RemoteEvent
local SayRemote: RemoteEvent?

local TIMEOUT = 300 -- si el cliente no contesta en 5 minutos, la conversación sigue sola

export type Line = { [string]: any }
export type Context = {
	check: (({ [string]: any }?) -> boolean)?, -- ¿se cumplen estas condiciones? (líneas con If)
	apply: (({ [string]: any }?) -> ())?, -- aplicar efectos (relaciones, marcas, recuerdos…)
	actorOf: ((string) -> Instance?)?, -- el modelo de ese personaje en la escena (para la cámara)
	args: ({ [string]: any } | () -> { [string]: any })?, -- {nombre}, {familia}… (o una función: se lee en cada línea)
}

type Frame = { Lines: { Line }, Index: number }
type Session = {
	Token: number,
	Stack: { Frame },
	Context: Context,
	Options: { Line }?, -- opciones que se están preguntando ahora
	OnDone: (() -> ())?,
	Deadline: number,
}

local sessions: { [Player]: Session } = {}
local nextToken = 0

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function attributesOf(player: Player): { [string]: any }
	return {
		FamilyKey = player:GetAttribute("FamilyKey"),
		AbuKey = player:GetAttribute("AbuKey"),
	}
end

local function argsFor(player: Player, extra: any): { [string]: any }
	if type(extra) == "function" then
		extra = extra()
	end
	local args: { [string]: any } = {
		nombre = player.DisplayName,
		familia = Strings.get(Cast.nameOf("Familia", attributesOf(player))),
		abu = Strings.get(Cast.nameOf("Abu", attributesOf(player))),
	}
	for key, value in extra or {} do
		args[key] = value
	end
	return args
end

-- Nombre visible y perfil de voz de quien habla
function DialogueService.speaker(player: Player, id: string?): (string?, string?)
	if id == nil or id == "Narrador" then
		return nil, "Narrador"
	elseif id == "Yo" then
		return player.DisplayName, nil -- el jugador no tiene voz sintetizada: lo lee él
	end
	local person = Cast.People[id]
	return Strings.get(Cast.nameOf(id, attributesOf(player))), person and person.Voice or "Narrador"
end

local function passes(context: Context, condition: { [string]: any }?): boolean
	if not condition then
		return true
	end
	return if context.check then context.check(condition) else true
end

local function lineFor(player: Player, session: Session, line: Line): { [string]: any }
	local name, voice = DialogueService.speaker(player, line.S)
	local actor: Instance? = nil
	if line.S == "Yo" then
		actor = player.Character
	elseif line.S and session.Context.actorOf then
		actor = session.Context.actorOf(line.S)
	end
	local text = Strings.get(line.T or "", argsFor(player, session.Context.args))
	return {
		Name = name,
		Voice = voice,
		Text = text,
		Emotion = Emotion.of(line, text), -- con qué gesto lo dice (el cliente anima a quien habla)
		Actor = actor,
		Me = line.S == "Yo",
		Narrator = line.S == nil or line.S == "Narrador",
	}
end

---------------------------------------------------------------------
-- Avanzar la conversación: junta líneas hasta la siguiente pregunta (o el final)
---------------------------------------------------------------------

local function finish(player: Player, session: Session)
	if sessions[player] ~= session then
		return
	end
	sessions[player] = nil
	if session.OnDone then
		task.spawn(session.OnDone)
	end
end

local function pump(player: Player, session: Session)
	local chunk = {}
	while true do
		local frame = session.Stack[#session.Stack]
		if not frame then
			-- Fin: se manda lo que quede y se espera a que el jugador lo lea
			session.Options = nil
			session.Deadline = os.clock() + TIMEOUT
			Remote:FireClient(player, "Show", { Token = session.Token, Lines = chunk, Final = true })
			return
		end
		frame.Index += 1
		local line = frame.Lines[frame.Index]
		if not line then
			table.remove(session.Stack)
			continue
		end
		if not passes(session.Context, line.If) then
			continue
		end
		if line.Ask then
			local options = {}
			local visible = {}
			for _, option in line.Options or {} do
				if passes(session.Context, option.If) then
					table.insert(options, option)
					table.insert(visible, Strings.get(option.T or "", argsFor(player, session.Context.args)))
				end
			end
			if #options > 0 then
				session.Options = options
				session.Deadline = os.clock() + TIMEOUT
				Remote:FireClient(player, "Show", {
					Token = session.Token,
					Lines = chunk,
					Ask = Strings.get(line.Ask, argsFor(player, session.Context.args)),
					Options = visible,
				})
				return
			end
			continue
		end
		if line.Effects and session.Context.apply then
			session.Context.apply(line.Effects)
		end
		if line.T then
			table.insert(chunk, lineFor(player, session, line))
		end
	end
end

local function answer(player: Player, token: any, choice: any)
	local session = sessions[player]
	if not session or token ~= session.Token then
		return
	end
	local options = session.Options
	if options then
		local index = if type(choice) == "number" then math.floor(choice) else 1
		local option = options[index] or options[1]
		session.Options = nil
		if session.Context.apply then
			session.Context.apply(option.Effects)
		end
		if option.Then then
			table.insert(session.Stack, { Lines = option.Then, Index = 0 })
		end
		pump(player, session)
	elseif #session.Stack == 0 then
		finish(player, session)
	end
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------

function DialogueService.isBusy(player: Player): boolean
	return sessions[player] ~= nil
end

-- Empieza una conversación. dialogue = { Lines = {…}, Effects = {…}? }. onDone al terminar.
-- Devuelve false si ya hay otra conversación en marcha (la historia lo reintentará).
function DialogueService.play(player: Player, dialogue: { [string]: any }, context: Context?, onDone: (() -> ())?): boolean
	if sessions[player] or not dialogue then
		return false
	end
	nextToken += 1
	local ctx = context or {}
	local session: Session = {
		Token = nextToken,
		Stack = { { Lines = dialogue.Lines or dialogue, Index = 0 } },
		Context = ctx,
		OnDone = function()
			if dialogue.Effects and ctx.apply then
				ctx.apply(dialogue.Effects)
			end
			if onDone then
				onDone()
			end
		end,
		Deadline = os.clock() + TIMEOUT,
	}
	sessions[player] = session
	pump(player, session)
	return true
end

-- Corta la conversación sin terminarla (el jugador se fue, la misión cambió…)
function DialogueService.cancel(player: Player)
	local session = sessions[player]
	if session then
		sessions[player] = nil
		if player.Parent then
			Remote:FireClient(player, "Close", { Token = session.Token })
		end
	end
end

-- Una frase suelta en un globo, sin parar el juego
function DialogueService.bark(player: Player, speakerId: string?, text: string, args: { [string]: any }?)
	local name, voice = DialogueService.speaker(player, speakerId)
	if SayRemote then
		SayRemote:FireClient(player, "Say", {
			SpeakerKey = name,
			TextKey = Strings.get(text, argsFor(player, args)),
			Role = voice,
		})
	end
end

function DialogueService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Dialogue") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Dialogue"
		Remote.Parent = remotes
	end
	SayRemote = remotes:FindFirstChild("Baby") :: RemoteEvent? -- el globo de diálogo de siempre
	Remote.OnServerEvent:Connect(function(player, kind, token, choice)
		if kind == "Next" then
			answer(player, token, choice)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	-- Nadie se queda atascado en una conversación: si el cliente no contesta, sigue sola
	task.spawn(function()
		while true do
			task.wait(5)
			for player, session in sessions do
				if os.clock() > session.Deadline then
					answer(player, session.Token, 1)
				end
			end
		end
	end)
end

return DialogueService
