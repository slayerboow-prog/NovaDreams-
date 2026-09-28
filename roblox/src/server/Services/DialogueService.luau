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
-- Además: DialogueService.bark = una frase suelta en un bocadillo encima de quien la dice, sin parar el juego ("¡Vas a llegar tarde!").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage.Shared.Log)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Emotion = require(ReplicatedStorage.Shared.LifeStory.Emotion)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local TimeContext = require(ReplicatedStorage.Shared.LifeStory.TimeContext)

local DialogueService = {}

local Remote: RemoteEvent
local SayRemote: RemoteEvent?

local TIMEOUT = 180 -- si el cliente no contesta en 3 minutos, la conversación sigue sola
-- Si el cliente no contesta en este rato, se le vuelve a mandar lo último (por si se perdió: la
-- interfaz se reinició, murió…). El cliente ignora lo que ya está enseñando o ya contestó.
DialogueService.ResendAfter = 45
DialogueService.MaxResends = 3

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
	OnCancel: (() -> ())?,
	Deadline: number,
	Seq: number, -- número del último trozo mandado (el cliente no repite un trozo que ya tiene)
	LastPayload: { [string]: any }?,
	LastSent: number,
	Resends: number,
	Speakers: { [string]: boolean }, -- quién habla (para girarse hacia el jugador)
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
	if line.S ~= nil and line.S ~= "Narrador" then
		text = TimeContext.adapt(text, TimeContext.now()) -- el saludo de la hora que es
	end
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

-- Mientras hablas: el servidor lo sabe (atributo InDialogue: no te pueden pegar, detener ni
-- abrir otras cosas) y los personajes que hablan se paran y te miran (TalkingTo)
local function setTalking(player: Player, session: Session?)
	player:SetAttribute("InDialogue", if session then true else nil)
	local who = {}
	for npc in (session and session.Speakers) or {} do
		table.insert(who, npc)
	end
	table.sort(who)
	player:SetAttribute("TalkingTo", if #who > 0 then table.concat(who, ",") else nil)
end

local function finish(player: Player, session: Session)
	if sessions[player] ~= session then
		return
	end
	sessions[player] = nil
	setTalking(player, nil)
	Log.info("DIALOGUE", "ended %s (%s)", session.Name or "?", player.Name)
	if session.OnDone then
		task.spawn(session.OnDone)
	end
end

local function send(player: Player, session: Session, payload: { [string]: any })
	session.Seq += 1
	payload.Seq = session.Seq
	session.LastPayload = payload
	session.LastSent = os.clock()
	session.Resends = 0
	Remote:FireClient(player, "Show", payload)
end

local function pump(player: Player, session: Session)
	local chunk = {}
	while true do
		local frame = session.Stack[#session.Stack]
		if not frame then
			-- Fin: se manda lo que quede y se espera a que el jugador lo lea
			session.Options = nil
			session.Deadline = os.clock() + TIMEOUT
			send(player, session, { Token = session.Token, Lines = chunk, Final = true })
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
				send(player, session, {
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
			if type(line.S) == "string" and line.S ~= "Yo" and line.S ~= "Narrador" and not session.Speakers[line.S] then
				session.Speakers[line.S] = true
				setTalking(player, session)
			end
		end
	end
end

local function answer(player: Player, token: any, choice: any, seq: any)
	local session = sessions[player]
	if not session or token ~= session.Token then
		return
	end
	-- Un "siguiente" de un trozo viejo (reenviado) no avanza dos veces
	if seq ~= nil and seq ~= session.Seq then
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

-- Empieza una conversación. dialogue = { Lines = {…}, Effects = {…}? }. onDone al terminar;
-- onCancel si se corta sin terminar (murió, se fue…). Devuelve false si ya hay otra en marcha
-- (la historia lo reintentará).
function DialogueService.play(player: Player, dialogue: { [string]: any }, context: Context?, onDone: (() -> ())?, onCancel: (() -> ())?): boolean
	if sessions[player] or not dialogue then
		return false
	end
	if player:GetAttribute("Dead") then
		return false -- nadie habla con quien está en el hospital
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
		OnCancel = onCancel,
		Deadline = os.clock() + TIMEOUT,
		Seq = 0,
		LastSent = os.clock(),
		Resends = 0,
		Speakers = {},
	}
	local first = (dialogue.Lines or dialogue)[1]
	session.Name = first and (first.S or "Narrador") or "?"
	sessions[player] = session
	setTalking(player, session)
	Log.info("DIALOGUE", "started with %s (%s)", tostring(session.Name), player.Name)
	pump(player, session)
	return true
end

-- Corta la conversación sin terminarla (el jugador murió o se fue, la misión cambió…). La caja
-- se cierra, los controles vuelven y quien la empezó se entera (onCancel) para poder repetirla.
function DialogueService.cancel(player: Player, reason: string?)
	local session = sessions[player]
	if session then
		sessions[player] = nil
		setTalking(player, nil)
		Log.info("DIALOGUE", "cancelled %s (%s): %s", tostring(session.Name), player.Name, reason or "?")
		if player.Parent then
			Remote:FireClient(player, "Close", { Token = session.Token })
		end
		if session.OnCancel then
			task.spawn(session.OnCancel)
		end
	end
end

-- Segundos desde el último trozo mandado (el vigilante de atascos lo mira)
function DialogueService.idleFor(player: Player): number?
	local session = sessions[player]
	return if session then os.clock() - session.LastSent else nil
end

-- Vuelve a mandar lo último (el cliente lo ignora si ya lo tiene). true si había algo que mandar.
function DialogueService.resend(player: Player): boolean
	local session = sessions[player]
	if not session or not session.LastPayload then
		return false
	end
	session.Resends += 1
	session.LastSent = os.clock()
	Remote:FireClient(player, "Show", session.LastPayload)
	return true
end

-- Quién busca el modelo de un personaje de la historia (LifeStoryService: los actores de su escena)
local actorFinder: ((Player, string) -> Instance?)? = nil
function DialogueService.setActorFinder(fn: (Player, string) -> Instance?)
	actorFinder = fn
end

-- El modelo de quien dice una frase suelta: el jugador, el actor de su escena o el personaje fijo
-- (la familia en casa…) más cercano con ese NpcId
local function actorFor(player: Player, speakerId: string?): Instance?
	if speakerId == nil or speakerId == "Narrador" then
		return nil
	elseif speakerId == "Yo" then
		return player.Character
	end
	if actorFinder then
		local ok, found = pcall(actorFinder, player, speakerId)
		if ok and found then
			return found
		end
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local best, bestDistance = nil, 80
	local ok = pcall(function()
		for _, npc in game:GetService("CollectionService"):GetTagged("StaticNpc") do
			if npc:IsA("Model") and npc:GetAttribute("NpcId") == speakerId and npc.Parent then
				local distance = (npc:GetPivot().Position - root.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = npc, distance
				end
			end
		end
	end)
	return if ok then best else nil
end

-- Una frase suelta en un bocadillo encima de quien la dice, sin parar el juego
-- (actor: su modelo, si ya se sabe; si no, se busca)
function DialogueService.bark(player: Player, speakerId: string?, text: string, args: { [string]: any }?, actor: Instance?)
	local name, voice = DialogueService.speaker(player, speakerId)
	if SayRemote then
		SayRemote:FireClient(player, "Say", {
			SpeakerKey = name,
			TextKey = TimeContext.adapt(Strings.get(text, argsFor(player, args)), TimeContext.now()),
			Role = voice,
			Speaker = actor or actorFor(player, speakerId),
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
	Remote.OnServerEvent:Connect(function(player, kind, token, choice, seq)
		if kind == "Next" then
			answer(player, token, choice, seq)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	-- Nadie se queda atascado en una conversación: si el cliente no contesta, se le vuelve a mandar
	-- lo último y, si aun así no contesta, sigue sola
	task.spawn(function()
		while true do
			task.wait(5)
			for player, session in sessions do
				if os.clock() > session.Deadline then
					Log.warn("WATCHDOG", "%s: conversación sin respuesta, sigue sola", player.Name)
					answer(player, session.Token, 1)
				elseif os.clock() - session.LastSent > DialogueService.ResendAfter and session.Resends < DialogueService.MaxResends then
					Log.info("WATCHDOG", "%s: conversación sin respuesta, se vuelve a mandar", player.Name)
					DialogueService.resend(player)
				end
			end
			-- El servidor no se cree un "hablando" sin conversación
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("InDialogue") and not sessions[player] then
					setTalking(player, nil)
				end
			end
		end
	end)
end

return DialogueService
