-- SpaceJobService (servidor): los TRABAJOS ESPACIALES del Sistema Valmar (docs/universo/diseno-espacio.md
-- §1; cuentas en shared/Cosmos/SpaceJobs). Por ahora: TRANSPORTISTA (cargas entre estaciones) y
-- CAZARRECOMPENSAS (objetivos con nombre en los sectores).
--
-- No tiene remoto ni bucle propios: es un ayudante de Services/SpaceService, que le llama desde lo que
-- ya tiene:
--   * board(player, estación)   el botón «🧰 Contratos» del tablón (menú con ficha de SpaceService)
--   * event(player, suceso)      «Dock» (atracar de verdad en un muelle, con el casco), «Kill» (con el id
--                                del enemigo que ha caído: AirCombatService), «Down» (derribado)
--   * tick(player)               cada segundo mientras vuela en el espacio (bucle de SpaceService): pone el
--                                objetivo de una recompensa al entrar en su sector y ve si se ha escapado
--   * onExit(player)             al bajarse de la nave: el objetivo se va (el contrato sigue)
--   * targets(player)            filas del HUD de la nave (SpaceService.infoFor)
-- Todo lo que se cobra lo decide el servidor: la entrega solo vale atracando (SpaceService.dock mira dónde
-- está la nave) y la recompensa solo si cae ESE enemigo (por su id), una vez (SpaceJobs.complete).
-- Lo guardado va en data.Space.Jobs; el objetivo vivo solo en memoria (al salir del juego desaparece).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local SpaceJobs = require(Cosmos.SpaceJobs)
local Stations = require(Cosmos.Stations)
local Zone = require(Cosmos.Zone)
local Layers = require(Cosmos.Layers)

local SpaceJobService = {}

SpaceJobService.SpawnAhead = 700 -- studs delante de la nave donde aparece el objetivo
SpaceJobService.clock = function(): number
	return os.time()
end

type Live = { Target: string, Escort: { string } }
type RState = { Live: { [string]: Live }, NextTry: { [string]: number } }
local runtime: { [Player]: RState } = {}

local function space(): any
	return require(script.Parent.SpaceService)
end

local function airCombat(): any
	return require(script.Parent.AirCombatService)
end

local function rt(player: Player): RState
	local r = runtime[player]
	if not r then
		r = { Live = {}, NextTry = {} }
		runtime[player] = r
	end
	return r
end

-- data.Space.Jobs (con lo que falte)
function SpaceJobService.jobsOf(player: Player): { [string]: any }?
	local sp = space().spaceData(player)
	if not sp then
		return nil
	end
	sp.Jobs = SpaceJobs.ensure(sp.Jobs)
	return sp.Jobs
end
local jobsOf = SpaceJobService.jobsOf

local function toast(player: Player, kind: string, text: string)
	space().toast(player, kind, text)
end

-- Cobrar un contrato UNA vez (dinero + Chispas con el tope por hora de los derribos)
local function pay(player: Player, jobs: { [string]: any }, id: string, late: boolean?): boolean
	local money, chispas, c = SpaceJobs.complete(jobs, id, SpaceJobService.clock(), late)
	if not money or not c then
		return false
	end
	local S = space()
	S.reward(player, money, 0)
	local got = if (chispas or 0) > 0 then S.grantChispas(player, chispas) else 0
	local rank = select(2, SpaceJobs.rankOf(jobs.Xp[c.Job] or 0))
	toast(player, "Success", ("%s Contrato cumplido: %s · +$%d%s · %s"):format(SpaceJobs.Jobs[c.Job].Icon, c.Title, money, if got > 0 then (" · ✨ +%d"):format(got) else "", rank.Name))
	return true
end

-- Quitar del mundo el objetivo (y su escolta) de una recompensa, sin que cuente como derribo
local function despawn(player: Player, id: string)
	local r = runtime[player]
	local live = r and r.Live[id]
	if not live then
		return
	end
	r.Live[id] = nil
	local AC = airCombat()
	pcall(AC.dropEnemy, player, live.Target)
	for _, e in live.Escort do
		pcall(AC.dropEnemy, player, e)
	end
end

local function despawnAll(player: Player)
	local r = runtime[player]
	if not r then
		return
	end
	for id in table.clone(r.Live) do
		despawn(player, id)
	end
end

---------------------------------------------------------------------
-- El tablón de contratos
---------------------------------------------------------------------
function SpaceJobService.board(player: Player, stationId: string)
	local S = space()
	local station = Stations.ById[stationId]
	local jobs = jobsOf(player)
	if not station or not jobs then
		return
	end
	local now = SpaceJobService.clock()
	for _, c in SpaceJobs.expire(jobs, now) do
		despawn(player, c.Id)
	end
	local options = {}
	-- Los que llevas (se pueden dejar: −1 de reputación, como si caducara)
	local active = {}
	for id, c in jobs.Active do
		if type(c) == "table" then
			table.insert(active, id)
		end
	end
	table.sort(active)
	for _, id in active do
		local c = jobs.Active[id]
		table.insert(options, { Text = ("✖ Dejar «%s»"):format(c.Title), Do = function()
			if SpaceJobs.fail(jobs, id, SpaceJobs.RepExpire) then
				despawn(player, id)
				toast(player, "Info", ("Has dejado «%s»"):format(c.Title))
			end
		end })
	end
	for _, c in SpaceJobs.offers(stationId, now) do
		if jobs.Active[c.Id] or jobs.Done[c.Id] then
			continue
		end
		local ok, why = SpaceJobs.canAccept(jobs, c, stationId, now)
		local money, chispas = SpaceJobs.payFor(jobs, c)
		local price = ("$%d%s"):format(money, if chispas > 0 then (" · ✨ %d"):format(chispas) else "")
		local text = if ok or why == "Full" or why == "Hour"
			then ("%s %s · %s"):format(SpaceJobs.Jobs[c.Job].Icon, c.Title, price)
			else ("🔒 %s (rango %s)"):format(c.Title, SpaceJobs.Ranks[c.Rank].Name)
		local contractId = c.Id
		table.insert(options, { Text = text, Do = function()
			if not S.inStation(player, stationId) then
				return
			end
			-- (se vuelve a sacar del tablón de AHORA: si ha cambiado la franja, ya no vale)
			local fresh = SpaceJobs.offerById(stationId, contractId, SpaceJobService.clock())
			local accepted, reason = SpaceJobs.accept(jobs, fresh :: any, stationId, SpaceJobService.clock())
			if accepted and fresh then
				toast(player, "Success", ("%s %s: %s"):format(SpaceJobs.Jobs[fresh.Job].Icon, fresh.Title, fresh.Text))
			else
				toast(player, "Info", SpaceJobs.Why[reason or "Unknown"] or SpaceJobs.Why.Unknown)
			end
		end })
	end
	table.insert(options, { Text = "Cerrar" })
	local left = SpaceJobs.SlotSeconds - now % SpaceJobs.SlotSeconds
	local body = ("%s\n%s\nA la vez: %d/%d · contratos nuevos en %d min"):format(
		SpaceJobs.careerText(jobs, "Carga"),
		SpaceJobs.careerText(jobs, "Caza"),
		SpaceJobs.activeCount(jobs),
		SpaceJobs.MaxActive,
		math.max(1, math.ceil(left / 60))
	)
	S.menu(player, "🧰 Contratos · " .. station.Name, body, options)
end

---------------------------------------------------------------------
-- Sucesos (los manda SpaceService.event)
---------------------------------------------------------------------
function SpaceJobService.event(player: Player, ev: { [string]: any })
	local jobs = jobsOf(player)
	if not jobs or type(ev) ~= "table" then
		return
	end
	local now = SpaceJobService.clock()
	if ev.Type == "Dock" and type(ev.Station) == "string" then
		local maxHull = tonumber(ev.MaxHull) or 0
		local frac = if maxHull > 0 then (tonumber(ev.Hull) or maxHull) / maxHull else 1
		for _, res in SpaceJobs.dockResults(jobs, ev.Station, now, frac) do
			if res.Result == "Done" then
				pay(player, jobs, res.Id, false)
			elseif res.Result == "Late" then
				toast(player, "Info", ("⏱ Has llegado tarde con «%s»: cobras la mitad."):format(res.Contract.Title))
				pay(player, jobs, res.Id, true)
			elseif res.Result == "Broken" then
				SpaceJobs.fail(jobs, res.Id)
				toast(player, "Error", ("💥 «%s»: la carga frágil se ha roto (el casco estaba por debajo del %d %%)."):format(res.Contract.Title, math.floor(SpaceJobs.FragileHull * 100)))
			elseif res.Result == "Early" then
				-- (más rápido de lo que se puede volar: no se cobra; el contrato sigue)
				toast(player, "Info", ("📦 «%s»: la oficina aún no tiene registrada tu carga. Vuelve a atracar en unos segundos."):format(res.Contract.Title))
			end
		end
	elseif ev.Type == "Kill" and type(ev.Id) == "string" then
		local r = runtime[player]
		if not r then
			return
		end
		for id, live in table.clone(r.Live) do
			if live.Target == ev.Id then
				r.Live[id] = nil
				for _, e in live.Escort do
					pcall(airCombat().dropEnemy, player, e)
				end
				pay(player, jobs, id, false)
			end
		end
	elseif ev.Type == "Down" then
		despawnAll(player)
		for _, id in SpaceJobs.cargoIds(jobs) do
			local c = SpaceJobs.fail(jobs, id)
			if c then
				toast(player, "Info", ("📦 Te han derribado: la carga de «%s» se ha perdido."):format(c.Title))
			end
		end
	end
end

-- Al bajarse de la nave (aterrizar, atracar, volver a Valmar): el objetivo se va; el contrato sigue
function SpaceJobService.onExit(player: Player)
	despawnAll(player)
end

---------------------------------------------------------------------
-- Cada segundo volando en el espacio: objetivos de las recompensas
---------------------------------------------------------------------
function SpaceJobService.tick(player: Player)
	local jobs = jobsOf(player)
	local AC = airCombat()
	local st = AC.status(player)
	if not jobs or not st then
		return
	end
	local now = SpaceJobService.clock()
	local r = rt(player)
	for _, c in SpaceJobs.expire(jobs, now) do
		despawn(player, c.Id)
		toast(player, "Info", ("⌛ El contrato «%s» ha caducado."):format(c.Title))
	end
	if st.Down then
		despawnAll(player)
		return
	end
	-- ¿Se ha escapado alguno? (el sistema de patrullas quita a los enemigos que quedan muy lejos)
	local alive = {}
	for _, e in AC.enemyList(player) do
		alive[e.Id] = true
	end
	for id, live in table.clone(r.Live) do
		if not alive[live.Target] then
			despawn(player, id)
			r.NextTry[id] = now + SpaceJobs.RespawnGap
			local c = jobs.Active[id]
			if c then
				toast(player, "Info", ("🎯 %s se ha escapado. Vuelve al %s para encontrarlo."):format(c.Target or c.Title, (SpaceJobs.sectorById(c.Sector or "") or { Name = c.Sector }).Name))
			end
		end
	end
	if st.Safe or next(r.Live) ~= nil then
		return -- (uno a la vez)
	end
	local sector = Zone.sectorAt(st.Pos)
	for _, c in SpaceJobs.bountiesIn(jobs, sector and sector.Id) do
		if now < (r.NextTry[c.Id] or 0) then
			continue
		end
		local plan = SpaceJobs.planOf(c)
		local look = if typeof(st.Look) == "Vector3" and st.Look.Magnitude > 0.1 then st.Look.Unit else Vector3.new(0, 0, -1)
		local p = st.Pos + look * SpaceJobService.SpawnAhead
		p = Vector3.new(p.X, math.max(p.Y, Layers.AIMinY + 120), p.Z)
		if Zone.safeAt(p) then
			r.NextTry[c.Id] = now + SpaceJobs.RespawnGap
			continue
		end
		local target = AC.spawnEnemy(player, plan.Kind, p, plan.Scale)
		if not target then
			r.NextTry[c.Id] = now + SpaceJobs.RespawnGap
			continue
		end
		local escort = {}
		for i = 1, plan.Escort do
			local a = (i / math.max(1, plan.Escort)) * math.pi * 2
			local e = AC.spawnEnemy(player, "Dron", p + Vector3.new(math.cos(a) * 60, 20, math.sin(a) * 60), { Hull = 1.2, Damage = 1, Fire = 1, Speed = 1, Level = c.Level or 1 })
			if e then
				table.insert(escort, e)
			end
		end
		r.Live[c.Id] = { Target = target, Escort = escort }
		toast(player, "Info", ("📡 Objetivo localizado: %s, delante de ti%s."):format(c.Target or c.Title, if #escort > 0 then (" con %d de escolta"):format(#escort) else ""))
		break
	end
end

-- Filas del HUD de la nave
function SpaceJobService.targets(player: Player): { { [string]: any } }
	local jobs = jobsOf(player)
	if not jobs then
		return {}
	end
	return SpaceJobs.targets(jobs, SpaceJobService.clock())
end

function SpaceJobService.init()
	Players.PlayerRemoving:Connect(function(player)
		-- (la sesión de la nave ya se cierra sola; aquí solo se olvida lo que había en memoria)
		runtime[player] = nil
	end)
end

-- (pruebas)
SpaceJobService._runtime = runtime

return SpaceJobService
