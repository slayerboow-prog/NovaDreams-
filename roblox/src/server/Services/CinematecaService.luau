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
-- Revisiones (✅ Bien / ❌ Mal + etiquetas + nota + contexto): en la memoria del servidor, en el registro
-- («[CINEMATECA] {json}») y GUARDADAS en un DataStore APARTE, solo de la Cinemateca:
-- «CinematecaRevisiones_v1» (nunca el de las partidas: Config.DataStoreName). Una clave por día
-- («dia_AAAAMMDD», y «_2», «_3»… si se llena) con una lista de revisiones cortas, más «indice» con los
-- días. Se escribe por tandas (como mucho una vez cada FLUSH_EVERY s) y solo lo que mandan los testers.
-- Leerlas: «/cinemateca exportar» en el chat (y en el panel) o `bash scripts/cloud-test.sh -v
-- cinemateca-revisiones` (scripts/cloud/cinemateca-revisiones.luau).
--
-- API: list() · play(player, index) · next(player) · prev(player) · replay(player) · stop(player)
--      review(player, payload) · reviews() · export() · exportAll(player) · flush() · pause(player, on)
--      current(player)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cinemateca = require(ReplicatedStorage.Shared.LifeStory.Cinemateca)

local CinematecaService = {}

CinematecaService.STORE = "CinematecaRevisiones_v1" -- (un DataStore SOLO para esto)
CinematecaService.FLUSH_EVERY = 20 -- segundos mínimos entre dos escrituras
CinematecaService.PAGE = 600 -- revisiones por clave como mucho (luego «_2», «_3»…)
CinematecaService.MAX_PER_PLAYER = 400 -- revisiones por tester y servidor (contra un bucle)
-- Etiquetas rápidas (el botón «💬 Comentar»)
CinematecaService.Tags = { "Cámara mal", "Actores mal colocados", "Lugar equivocado", "Aburrida", "Texto tapa", "Otro" }
local TAG_OK: { [string]: boolean } = {}
for _, tag in CinematecaService.Tags do
	TAG_OK[tag] = true
end


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
	locate = function(player: Player, place: string, options: { [string]: any }?): CFrame?
		local spot = require(script.Parent.LocationService).resolve(player, place, options)
		return spot and spot.CFrame
	end,
	zone = function(name: string): Vector3?
		return require(script.Parent.LocationService).zoneCenter(name)
	end,
	-- Que el mapa cargue el sitio antes de llevarte (se carga por trozos)
	stream = function(player: Player, position: Vector3)
		pcall(function()
			player:RequestStreamAroundAsync(position, 4)
		end)
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
	-- El DataStore de las revisiones (las pruebas ponen uno de mentira: nunca se escribe el de verdad)
	store = function(): any
		return game:GetService("DataStoreService"):GetDataStore(CinematecaService.STORE)
	end,
	later = function(seconds: number, fn: () -> ())
		task.delay(seconds, fn)
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

-- Dónde se pone la escena (v125.5: se ponía donde estabas —en el puerto espacial— y los actores se
-- amontonaban detrás de ti). Por orden: el sitio del paso que la pide, el de sus actores, el último sitio
-- al que te llevó la misión, el ancla principal de la escena (Center) y sus anclas de lugar o de zona.
-- Devuelve (CFrame, nil) si lo encuentra; (nil, "Lugar no disponible") si la escena tiene sitio pero no
-- existe ahora (Tefra sin construir, una sala que no está); (nil, nil) si no tiene sitio fijo (pasa donde
-- estés, como en el juego).
function CinematecaService.stageOf(player: Player, entry: { [string]: any }): (CFrame?, string?)
	local candidates: { { [string]: any } } = {}
	local function add(kind: string, value: any, options: { [string]: any }?)
		if type(value) == "string" then
			table.insert(candidates, { Kind = kind, Value = value, Options = options })
		end
	end
	add("Place", entry.Place)
	for _, a in entry.Actors or {} do
		add("Place", a.Place)
	end
	add("Place", entry.Before)
	if entry.Id then
		local HappeningIndex = require(ReplicatedStorage.Shared.LifeStory.HappeningIndex)
		local def = HappeningIndex.get(entry.Id)
		local anchors = (def and def.Anchors) or {}
		local names = {}
		if def and type(def.Center) == "string" and anchors[def.Center] then
			table.insert(names, def.Center)
		end
		local sorted = {}
		for name in anchors do
			table.insert(sorted, name)
		end
		table.sort(sorted)
		for _, name in sorted do
			table.insert(names, name)
		end
		for _, name in names do
			local spec = anchors[name]
			if type(spec) == "table" then
				add("Place", spec.Place, { Offset = spec.Offset })
			elseif type(spec) == "string" then
				add("Place", spec:match("^Place:(.+)$"))
				add("Zone", spec:match("^Zone:(.+)$"))
			end
		end
	end
	if #candidates == 0 then
		return nil, nil
	end
	for _, c in candidates do
		local ok, cf = pcall(function(): CFrame?
			if c.Kind == "Zone" then
				local center = deps.zone(c.Value)
				return if center then CFrame.new(center) else nil
			end
			return deps.locate(player, c.Value, c.Options)
		end)
		if ok and cf then
			return cf, nil
		end
	end
	return nil, "Lugar no disponible"
end

-- Los actores del paso en sus marcas (para que la escena los coloque bien sin la misión activa):
-- { [Npc] = CFrame }
function CinematecaService.standInsOf(player: Player, entry: { [string]: any }): { [string]: CFrame }
	local out = {}
	for _, a in entry.Actors or {} do
		if out[a.Npc] == nil then
			local ok, cf = pcall(deps.locate, player, a.Place, { Index = a.Index, Offset = a.Offset })
			if ok and cf then
				out[a.Npc] = cf
			end
		end
	end
	return out
end

-- Vuelta a casa (donde estabas antes de la primera escena de la tanda)
local function goHome(player: Player, s: Session)
	if s.Home and player.Parent then
		-- (solo si te habíamos llevado a otro sitio: si sigues en casa, no se te mueve)
		local ok, root = pcall(deps.root, player)
		if ok and root and (root.Position - s.Home.Position).Magnitude < 1 then
			return
		end
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
	local stage, why = CinematecaService.stageOf(player, entry)
	s.Index = entry.Index
	if why then
		-- (tiene sitio, pero no existe ahora: mejor decirlo que ponerla en un prado)
		goHome(player, s)
		pcall(deps.send, player, { Op = "Started", Index = entry.Index, Key = entry.Key, Ok = false, Why = why })
		return false
	end
	if stage then
		deps.stream(player, stage.Position)
		pcall(deps.teleport, player, CFrame.new(stage.Position + Vector3.new(0, 3, 0)))
	end
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
			return deps.happening().play(player, entry.Id, { Sandbox = true, StandIns = CinematecaService.standInsOf(player, entry) })
		end)
		started = ok and type(duration) == "number"
	end
	if not started then
		s.Running = nil
		goHome(player, s)
	end
	pcall(deps.send, player, { Op = "Started", Index = entry.Index, Key = entry.Key, Ok = started, Why = if started then nil else "No se ha podido poner", Here = stage == nil or nil })
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

---------------------------------------------------------------------
-- Guardar las revisiones (DataStore aparte, por tandas)
---------------------------------------------------------------------
local pending: { { [string]: any } } = {}
local flushing = false
local flushScheduled = false
local lastFlush = -math.huge
local perPlayer: { [number]: number } = {}

local function dayKey(t: number): string
	return "dia_" .. os.date("!%Y%m%d", t)
end

-- Una revisión corta para guardar (claves de una letra: caben cientos por clave)
local function compact(r: { [string]: any }): { [string]: any }
	return { k = r.Key, ok = if r.Ok then 1 else 0, n = r.Note, g = r.Tags, s = r.Shot, ss = r.Shots, t = r.T, sk = if r.Skipped then 1 else nil, d = r.Device, ts = r.Time, u = r.By }
end
function CinematecaService.expand(c: { [string]: any }): { [string]: any }
	return { Key = c.k, Ok = c.ok == 1, Note = c.n, Tags = c.g, Shot = c.s, Shots = c.ss, T = c.t, Skipped = c.sk == 1, Device = c.d, Time = c.ts, By = c.u }
end

-- Escribe lo pendiente (una tanda). Devuelve cuántas ha guardado.
function CinematecaService.flush(): number
	if flushing or #pending == 0 then
		return 0
	end
	flushing = true
	lastFlush = os.clock()
	local batch = pending
	pending = {}
	local saved = 0
	local ok, err = pcall(function()
		local store = deps.store()
		local days: { [string]: { { [string]: any } } } = {}
		for _, r in batch do
			local key = dayKey(r.Time or deps.now())
			days[key] = days[key] or {}
			table.insert(days[key], compact(r))
		end
		for day, items in days do
			local remaining = items
			local page = 1
			while #remaining > 0 and page <= 20 do
				local key = if page == 1 then day else ("%s_%d"):format(day, page)
				local taken = 0
				store:UpdateAsync(key, function(old: any)
					local list = if type(old) == "table" then old else {}
					taken = math.min(#remaining, math.max(0, CinematecaService.PAGE - #list))
					if taken == 0 then
						return nil -- (llena: a la página siguiente)
					end
					for i = 1, taken do
						table.insert(list, remaining[i])
					end
					return list
				end)
				if taken > 0 then
					saved += taken
					remaining = { table.unpack(remaining, taken + 1) }
					store:UpdateAsync("indice", function(old: any)
						local index = if type(old) == "table" then old else {}
						if table.find(index, key) then
							return nil
						end
						table.insert(index, key)
						return index
					end)
				end
				page += 1
			end
		end
	end)
	if not ok then
		-- (no se pierden: vuelven a la cola para la próxima tanda)
		for i = #batch, 1, -1 do
			table.insert(pending, 1, batch[i])
		end
		warn("[Cinemateca] no se han podido guardar las revisiones: " .. tostring(err))
		saved = 0
	end
	flushing = false
	return saved
end

local function scheduleFlush()
	if flushScheduled then
		return
	end
	flushScheduled = true
	local wait = math.max(0, CinematecaService.FLUSH_EVERY - (os.clock() - lastFlush))
	deps.later(wait, function()
		flushScheduled = false
		CinematecaService.flush()
		if #pending > 0 then
			scheduleFlush()
		end
	end)
end

-- Lee las revisiones guardadas (todas las claves del índice). Solo leer.
function CinematecaService.loadSaved(): { { [string]: any } }
	local out = {}
	local ok, err = pcall(function()
		local store = deps.store()
		local index = store:GetAsync("indice")
		for _, key in (if type(index) == "table" then index else {}) do
			local list = store:GetAsync(key)
			for _, c in (if type(list) == "table" then list else {}) do
				table.insert(out, CinematecaService.expand(c))
			end
		end
	end)
	if not ok then
		warn("[Cinemateca] no se han podido leer las revisiones guardadas: " .. tostring(err))
	end
	return out
end

-- Una revisión: { Key, Ok = true|false, Note?, Tags?, Shot?, Shots?, T?, Device?, Skipped? }
function CinematecaService.review(player: Player, payload: any): boolean
	if type(payload) ~= "table" or type(payload.Key) ~= "string" or type(payload.Ok) ~= "boolean" then
		return false
	end
	local entry = Cinemateca.get(payload.Key)
	if not entry then
		return false
	end
	if (perPlayer[player.UserId] or 0) >= CinematecaService.MAX_PER_PLAYER then
		return false
	end
	perPlayer[player.UserId] = (perPlayer[player.UserId] or 0) + 1
	local tags = nil
	if type(payload.Tags) == "table" then
		for _, tag in payload.Tags do
			if type(tag) == "string" and TAG_OK[tag] then
				tags = tags or {}
				if not table.find(tags, tag) then
					table.insert(tags, tag)
				end
			end
		end
	end
	local record = {
		Key = entry.Key,
		Ok = payload.Ok,
		Tags = tags,
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
	table.insert(pending, record)
	scheduleFlush()
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

local function line(r: { [string]: any }): string
	return ("%s %s%s%s%s"):format(
		if r.Ok then "✅" else "❌",
		tostring(r.Key),
		if r.Shot then (" (plano %d/%d)"):format(r.Shot, r.Shots or 0) else "",
		if r.Tags then " [" .. table.concat(r.Tags, ", ") .. "]" else "",
		if r.Note then " — " .. r.Note else ""
	)
end

-- Todas las revisiones, una por línea (para el panel y el registro del servidor). saved = también
-- las guardadas de otros días y servidores (las de este servidor que aún no se han guardado, aparte).
function CinematecaService.export(saved: { { [string]: any } }?): string
	local lines = {}
	local seen: { [string]: boolean } = {}
	for _, r in saved or {} do
		seen[("%s|%s|%s"):format(tostring(r.Key), tostring(r.Time), tostring(r.By))] = true
		table.insert(lines, line(r))
	end
	for _, r in reviews do
		if not seen[("%s|%s|%s"):format(tostring(r.Key), tostring(r.Time), tostring(r.By))] then
			table.insert(lines, line(r))
		end
	end
	return if #lines > 0 then table.concat(lines, "\n") else "Aún no hay revisiones."
end

-- «/cinemateca exportar»: lo guardado y lo de este servidor, al registro y a la pantalla
function CinematecaService.exportAll(player: Player?): string
	CinematecaService.flush()
	local saved = CinematecaService.loadSaved()
	for _, r in saved do
		local ok, json = pcall(function()
			return game:GetService("HttpService"):JSONEncode(r)
		end)
		deps.print("[CINEMATECA] " .. (if ok then json else tostring(r.Key)))
	end
	local text = CinematecaService.export(saved)
	if player then
		pcall(deps.send, player, { Op = "Export", Text = text })
	end
	return text
end

-- (Cinemateca) Parar / seguir la escena mientras se comenta
function CinematecaService.pause(player: Player, on: boolean): boolean
	local ok, result = pcall(function()
		return deps.happening().freeze(player, on)
	end)
	return ok and result == true
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
	-- (lo que quede sin guardar, al cerrar el servidor)
	pcall(function()
		game:BindToClose(function()
			CinematecaService.flush()
		end)
	end)
end

return CinematecaService
