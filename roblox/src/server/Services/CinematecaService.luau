-- CinematecaService (servidor): ver TODAS las escenas del juego una por una para revisarlas (solo dueño y
-- testers: lo llama TesterService.handle, que ya comprueba quién es tester). Lista: shared/LifeStory/Cinemateca.
--
-- Cada escena se ve en MODO SANDBOX, fuera de su momento de la historia:
--   * escenas del motor: HappeningService.play(…, { Sandbox = true }) — sin memoria del mundo, sin seguir la
--     historia, sin portales, sin espectadores ni grupo; los actores son los suplentes de la escena (como
--     siempre: si no está el de la misión, aparece en su marca) y se van al acabar;
--   * conversaciones: DialogueService.play SIN efectos (no se pasa `apply`: ni marcas, ni dinero, ni
--     relaciones, ni objetos); las condiciones se leen de tu partida (solo leer).
--   * Antes de empezar te lleva a su sitio (su lugar, o su ancla principal) y al acabar —también si la saltas
--     a mitad o la cortas con otra— te devuelve donde estabas. Si el sitio no está cargado (Tefra sin
--     construir), la escena se pone donde estás (escenario neutro). Cámara, controles e interfaz los
--     devuelve la pantalla como en cualquier escena (HappeningClient / DialogueUI).
--   * Nada de esto cambia la partida: ni misiones, ni marcas, ni dinero, ni mochila, ni memoria del mundo.
-- Revisiones (✅ Bien / ❌ Mal + nota + contexto): en la memoria del servidor (no se guardan en el
-- DataStore) y se escriben en el registro del servidor como «[CINEMATECA] {json}», para que se puedan leer
-- después (Output de Studio, cloud-test). «/cinemateca» en el chat (testers) las vuelve a escribir todas.
--
-- API: list() · play(player, index) · next(player) · prev(player) · replay(player) · stop(player)
--      review(player, payload) · reviews() · export() · current(player)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cinemateca = require(ReplicatedStorage.Shared.LifeStory.Cinemateca)

local CinematecaService = {}

type Session = { Index: number, Serial: number, Running: { [string]: any }?, Home: CFrame?, Ignore: { [string]: number } }
local sessions: { [Player]: Session } = {}
local reviews: { { [string]: any } } = {}
local lastVerdict: { [string]: string } = {} -- clave → "Bien" | "Mal" (la última)

local deps = {
	happening = function(): any
		return require(script.Parent.HappeningService)
	end,
	dialogue = function(): any
		return require(script.Parent.DialogueService)
	end,
	locate = function(player: Player, place: string): CFrame?
		local spot = require(script.Parent.LocationService).resolve(player, place)
		return spot and spot.CFrame
	end,
	root = function(player: Player): BasePart?
		local character = player.Character
		return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end,
	teleport = function(player: Player, cf: CFrame)
		local character = player.Character
		if character then
			character:PivotTo(cf)
		end
	end,
	send = function(_player: Player, _payload: { [string]: any }) end, -- (TesterService la pone)
	print = print,
	now = function(): number
		return os.time()
	end,
}
function CinematecaService._inject(overrides: { [string]: any })
	for k, v in overrides do
		(deps :: any)[k] = v
	end
end
function CinematecaService.setSender(fn: (Player, { [string]: any }) -> ())
	deps.send = fn
end

function CinematecaService.list(): { { [string]: any } }
	return Cinemateca.list()
end

function CinematecaService.current(player: Player): { [string]: any }?
	local s = sessions[player]
	return s and Cinemateca.get(s.Index)
end

-- Dónde se pone la escena: su lugar (del paso), su ancla principal (Center) o la primera que sea un
-- lugar o una zona. nil: donde estás.
local function stageOf(player: Player, entry: { [string]: any }): CFrame?
	if entry.Place then
		local ok, cf = pcall(deps.locate, player, entry.Place)
		if ok and cf then
			return cf
		end
	end
	if entry.Id then
		local HappeningIndex = require(ReplicatedStorage.Shared.LifeStory.HappeningIndex)
		local def = HappeningIndex.get(entry.Id)
		if def then
			local anchors = def.Anchors or {}
			local names = {}
			if type(def.Center) == "string" and anchors[def.Center] then
				table.insert(names, def.Center)
			end
			for name in anchors do
				table.insert(names, name)
			end
			for _, name in names do
				local spec = anchors[name]
				local place = if type(spec) == "table" then spec.Place elseif type(spec) == "string" then spec:match("^Place:(.+)$") else nil
				if type(place) == "string" then
					local ok, cf = pcall(deps.locate, player, place)
					if ok and cf then
						return cf
					end
				end
			end
		end
	end
	return nil
end

-- Vuelta a casa (donde estabas antes de la primera escena de la tanda)
local function goHome(player: Player, s: Session)
	if s.Home and player.Parent then
		pcall(deps.teleport, player, s.Home)
	end
end

-- La escena en marcha acaba (sola, saltada o cortada): vuelta y aviso a la pantalla
local function ended(player: Player, s: Session, serial: number, skipped: boolean)
	if s.Serial ~= serial or not s.Running then
		return
	end
	local entry = s.Running
	s.Running = nil
	goHome(player, s)
	pcall(deps.send, player, { Op = "Ended", Index = entry.Index, Key = entry.Key, Skipped = skipped })
end

-- Corta la que esté en marcha (sin avisar a la pantalla de que ha acabado: va otra)
local function cut(player: Player, s: Session)
	local running = s.Running
	if not running then
		return
	end
	s.Running = nil
	if running.Kind == "Conversación" then
		pcall(function()
			deps.dialogue().cancel(player, "Cinemateca")
		end)
	else
		-- (su final llegará después: no es el de la escena nueva, aunque sea la misma repetida)
		s.Ignore[running.Id] = (s.Ignore[running.Id] or 0) + 1
		pcall(function()
			deps.happening().skip(player, running.Id)
		end)
	end
end

-- Pone la escena `index` de la lista. Devuelve si ha empezado.
function CinematecaService.play(player: Player, index: any): boolean
	local entry = Cinemateca.get(tonumber(index) or index)
	if not entry then
		return false
	end
	local s = sessions[player]
	if not s then
		s = { Index = entry.Index, Serial = 0, Ignore = {} }
		sessions[player] = s
	end
	cut(player, s)
	-- (te lleva a su sitio; donde estabas, para volver, se apunta solo la primera vez de la tanda)
	local root = deps.root(player)
	if root and not s.Home then
		s.Home = root.CFrame
	end
	local stage = stageOf(player, entry)
	if stage then
		pcall(deps.teleport, player, CFrame.new(stage.Position + Vector3.new(0, 3, 0)))
	end
	s.Index = entry.Index
	s.Serial += 1
	local serial = s.Serial
	s.Running = entry
	local started = false
	if entry.Kind == "Conversación" then
		local Quests = require(ReplicatedStorage.Shared.LifeStory.Quests)
		local quest = Quests[entry.Quest]
		local dialogue = quest and quest.Dialogues and quest.Dialogues[entry.Dialogue]
		if dialogue then
			local check = nil
			pcall(function()
				check = deps.happening().checker(player)
			end)
			local ok, result = pcall(function()
				-- (sin `apply`: ninguna consecuencia; solo se leen las condiciones de tu partida)
				return deps.dialogue().play(player, dialogue, { check = check }, function()
					ended(player, s, serial, false)
				end, function()
					ended(player, s, serial, true)
				end)
			end)
			started = ok and result == true
		end
	else
		local ok, duration = pcall(function()
			return deps.happening().play(player, entry.Id, { Sandbox = true })
		end)
		started = ok and type(duration) == "number"
	end
	if not started then
		s.Running = nil
		goHome(player, s)
	end
	pcall(deps.send, player, { Op = "Started", Index = entry.Index, Key = entry.Key, Ok = started })
	return started
end

function CinematecaService.next(player: Player): boolean
	local s = sessions[player]
	local list = Cinemateca.list()
	local index = if s then s.Index % #list + 1 else 1
	return CinematecaService.play(player, index)
end

function CinematecaService.prev(player: Player): boolean
	local s = sessions[player]
	local list = Cinemateca.list()
	local index = if s then (s.Index - 2) % #list + 1 else #list
	return CinematecaService.play(player, index)
end

function CinematecaService.replay(player: Player): boolean
	local s = sessions[player]
	return CinematecaService.play(player, if s then s.Index else 1)
end

-- Corta la que esté en marcha (la pantalla la devuelve todo y tú vuelves a tu sitio)
function CinematecaService.stop(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	local running = s.Running
	cut(player, s)
	goHome(player, s)
	if running then
		pcall(deps.send, player, { Op = "Ended", Index = running.Index, Key = running.Key, Skipped = true })
	end
end

-- Se cierra la Cinemateca: lo que quede, cortado, y a casa (la próxima tanda apunta otra vez dónde estás)
function CinematecaService.close(player: Player)
	CinematecaService.stop(player)
	sessions[player] = nil
end

local function clip(text: any, n: number): string?
	if type(text) ~= "string" then
		return nil
	end
	local clean = text:gsub("[%c]", " ")
	if utf8.len(clean) and (utf8.len(clean) :: number) > n then
		clean = clean:sub(1, utf8.offset(clean, n + 1) - 1)
	end
	return clean
end

-- Una revisión: { Key, Ok = true|false, Note?, Shot?, Shots?, T?, Device?, Skipped? }
function CinematecaService.review(player: Player, payload: any): boolean
	if type(payload) ~= "table" or type(payload.Key) ~= "string" or type(payload.Ok) ~= "boolean" then
		return false
	end
	local entry = Cinemateca.get(payload.Key)
	if not entry then
		return false
	end
	local record = {
		Key = entry.Key,
		Ok = payload.Ok,
		Note = clip(payload.Note, 200),
		Shot = tonumber(payload.Shot),
		Shots = tonumber(payload.Shots),
		T = tonumber(payload.T),
		Skipped = payload.Skipped == true or nil,
		Device = clip(payload.Device, 40),
		Time = deps.now(),
		By = player.UserId,
	}
	table.insert(reviews, record)
	lastVerdict[entry.Key] = if record.Ok then "Bien" else "Mal"
	local okJson, json = pcall(function()
		return game:GetService("HttpService"):JSONEncode(record)
	end)
	deps.print("[CINEMATECA] " .. (if okJson then json else ("%s %s %s"):format(record.Key, tostring(record.Ok), tostring(record.Note))))
	pcall(deps.send, player, { Op = "Reviewed", Key = entry.Key, Verdict = lastVerdict[entry.Key] })
	return true
end

function CinematecaService.reviews(): { { [string]: any } }
	return reviews
end

function CinematecaService.verdicts(): { [string]: string }
	return lastVerdict
end

-- Todas las revisiones, una por línea (para el panel y el registro del servidor)
function CinematecaService.export(): string
	local lines = {}
	for _, r in reviews do
		table.insert(lines, ("%s %s%s%s"):format(if r.Ok then "✅" else "❌", r.Key, if r.Shot then (" (plano %d/%d)"):format(r.Shot, r.Shots or 0) else "", if r.Note then " — " .. r.Note else ""))
	end
	return if #lines > 0 then table.concat(lines, "\n") else "Aún no hay revisiones."
end

function CinematecaService.printAll()
	for _, r in reviews do
		local ok, json = pcall(function()
			return game:GetService("HttpService"):JSONEncode(r)
		end)
		deps.print("[CINEMATECA] " .. (if ok then json else r.Key))
	end
end

function CinematecaService.init()
	-- Las escenas del motor acaban (solas o saltadas): ¿era la de la Cinemateca?
	pcall(function()
		deps.happening().onFinished(function(player, id, skipped)
			local s = sessions[player]
			if s and (s.Ignore[id] or 0) > 0 then
				s.Ignore[id] -= 1
				return
			end
			if s and s.Running and s.Running.Id == id and s.Running.Kind ~= "Conversación" then
				ended(player, s, s.Serial, skipped)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return CinematecaService
