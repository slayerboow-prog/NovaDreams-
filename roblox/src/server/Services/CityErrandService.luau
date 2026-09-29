-- CityErrandService: los «Encargos de la ciudad» (datos en shared/CityErrands).
--
--   * Alrededor de cada jugador aparece gente con un ❗ encima de la cabeza en los sitios de la ciudad
--     (súper, parque, playa, hospital, estaciones, colegio, puerto, campus, gasolinera, cafetería…).
--     Solo cerca de algún jugador, nunca a menos de 5 studs de nadie, como mucho unos pocos por zona,
--     y solo con el sitio abierto (de noche el parque se queda vacío). Si ya no queda nadie cerca, se van.
--   * Hablas con ellos (E): te cuentan qué les pasa y eliges «¡Claro!» o «Ahora no puedo».
--   * El encargo sale en el panel de misiones, en el ❓, en el GPS y con el haz de luz (atributos del
--     jugador CityErrand y CityErrandTarget). Se puede dejar (botón «Dejar» o remoto "Abandon").
--   * Pasos: recoger cosas (con o sin tiempo), entregar, hablar con alguien, ir a un sitio o acompañar a
--     quien te lo pidió (te sigue). Al acabar: dinero y experiencia (más cuanto más lejos te ha mandado).
--   * Cada persona (encargo + sitio) espera un rato antes de volver a pedirte algo (se guarda).
--   * Nada se ofrece en mitad de una conversación, una escena o una clase, ni si en horario de cole
--     sigues una misión principal (LifeStoryService.errandBlock), ni trabajando.
--   * Los objetos y la gente de tu encargo solo los ves tú (workspace.CityErrands.Items_<UserId>_<n>, con
--     el atributo ErrandOwner: Controllers/CityErrands los esconde a los demás).
-- Mapa: el atributo CityErrandMarks (JSON) dice dónde hay gente con ❗ cerca (MapUI los pinta).

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CityErrands = require(ReplicatedStorage.Shared.CityErrands)
local Format = require(ReplicatedStorage.Shared.Format)
local Ground = require(ReplicatedStorage.Shared.Ground)
local OpeningHours = require(ReplicatedStorage.Shared.OpeningHours)
local Log = require(ReplicatedStorage.Shared.Log)
local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local DialogueService = require(script.Parent.DialogueService)
local SceneService = require(script.Parent.SceneService)
local LifeStoryService = require(script.Parent.LifeStoryService)
local Npc = require(script.Parent.Parent.World.Npc)

local CityErrandService = {}

CityErrandService.StartDelay = 5 -- segundos antes del primer repaso (que el mapa esté construido)

local CFG = CityErrands.Config
local Remote: RemoteEvent
local Notify: RemoteEvent?

type Site = { Kind: string, Key: string, Instance: Instance, Center: Vector3, CFrame: CFrame, Size: Vector3 }
type Giver = {
	SiteKey: string,
	Key: string, -- encargo + sitio (las esperas)
	Site: Site,
	Template: { [string]: any },
	Model: Model,
	Position: Vector3,
	Busy: Player?, -- quien está haciendo su encargo
	Talking: Player?, -- con quien está hablando ahora
	Leaving: boolean?,
}
type Job = {
	Giver: Giver,
	Template: { [string]: any },
	Plan: { { [string]: any } },
	Step: number,
	Carry: string?,
	Money: number,
	Xp: number,
	Deadline: number?,
	Collected: number,
	Items: { Model },
	Recipient: Model?,
	Folder: Folder,
	LastPublished: string?,
}

local sites: { Site } = {}
local indexed = false
local lastIndex = -math.huge
local givers: { [string]: Giver } = {}
local active: { [Player]: Job } = {}
local siteRest: { [string]: number } = {}
local folderCount = 0
local root: Folder
local giverFolder: Folder

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function notify(player: Player, kind: string, text: string)
	if Notify then
		Notify:FireClient(player, kind, text)
	end
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function positionOf(player: Player): Vector3?
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return rootPart and rootPart.Position
end

-- La hora del juego (Lighting.ClockTime)
local function clockNow(): number
	return OpeningHours.clock()
end

-- El suelo de verdad bajo un punto (o el punto, si no se encuentra)
local function groundAt(point: Vector3): Vector3
	local ok, hit = pcall(function()
		return Ground.cast(point + Vector3.new(0, 40, 0), Vector3.new(0, -90, 0))
	end)
	if ok and hit then
		return hit.Position
	end
	return point
end

local function errandData(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	data.CityErrands = data.CityErrands or { Cooldowns = {}, Done = 0 }
	local store = data.CityErrands
	store.Cooldowns = store.Cooldowns or {}
	store.Done = store.Done or 0
	-- Las esperas que ya pasaron no se guardan para siempre
	local now = os.time()
	for key, until_ in store.Cooldowns do
		if type(until_) ~= "number" or until_ <= now then
			store.Cooldowns[key] = nil
		end
	end
	return store
end

local function setCooldown(player: Player, key: string, seconds: number)
	local store = errandData(player)
	if store then
		store.Cooldowns[key] = os.time() + seconds
	end
end

---------------------------------------------------------------------
-- Sitios del mapa (se buscan una vez; si algo se reconstruye, otra vez)
---------------------------------------------------------------------

local function boxOf(instance: Instance): (CFrame?, Vector3?)
	if instance:IsA("Model") then
		local ok, cf, size = pcall(function()
			return (instance :: Model):GetBoundingBox()
		end)
		if ok then
			return cf, size
		end
		return nil, nil
	elseif instance:IsA("BasePart") then
		return (instance :: BasePart).CFrame, (instance :: BasePart).Size
	end
	return nil, nil
end

local function attrMatches(instance: Instance, attr: { [string]: any }?): boolean
	for name, wanted in attr or {} do
		local value = instance:GetAttribute(name)
		if type(wanted) == "table" then
			if not table.find(wanted, value) then
				return false
			end
		elseif value ~= wanted then
			return false
		end
	end
	return true
end

local function buildIndex()
	lastIndex = os.clock()
	local found: { Site } = {}
	local seen: { [string]: boolean } = {}
	local function add(kind: string, instance: Instance)
		local cf, size = boxOf(instance)
		if not cf or not size then
			return
		end
		local bottom = cf.Position - Vector3.new(0, size.Y / 2, 0)
		local key = ("%s:%d,%d"):format(kind, math.round(bottom.X), math.round(bottom.Z))
		if seen[key] then
			return
		end
		seen[key] = true
		table.insert(found, { Kind = kind, Key = key, Instance = instance, Center = bottom, CFrame = cf, Size = size })
	end
	local byModel: { [string]: { string } } = {}
	for kind, def in CityErrands.Sites do
		for _, name in def.Models or {} do
			byModel[name] = byModel[name] or {}
			table.insert(byModel[name], kind)
		end
	end
	local town = workspace:FindFirstChild("Town")
	if town then
		for _, descendant in town:GetDescendants() do
			local kinds = descendant:IsA("Model") and byModel[descendant.Name]
			if kinds then
				for _, kind in kinds do
					add(kind, descendant)
				end
			end
		end
	end
	for kind, def in CityErrands.Sites do
		if def.Tag then
			for _, instance in CollectionService:GetTagged(def.Tag) do
				if attrMatches(instance, def.Attr) then
					add(kind, instance)
				end
			end
		end
	end
	table.sort(found, function(a, b)
		return a.Key < b.Key
	end)
	sites = found
	indexed = true
end

-- Sin sitios (el mapa aún no estaba) o con alguno que ya no existe: se vuelve a buscar (sin pasarse)
local function ensureIndex()
	local stale = not indexed or #sites == 0
	if not stale then
		for _, site in sites do
			if not site.Instance:IsDescendantOf(workspace) then
				stale = true
				break
			end
		end
	end
	if stale and os.clock() - lastIndex > 20 then
		buildIndex()
	end
end

function CityErrandService.reindex()
	buildIndex()
end

function CityErrandService.sites(): { Site }
	return sites
end

-- Dónde se pone alguien en un sitio: en la acera de delante de un edificio (el lado que da hacia
-- `near`), o dentro de un sitio al aire libre (parque, playa, plaza), un poco hacia el centro
local function standPoint(site: Site, near: Vector3, shift: number?): Vector3
	local cf, size = site.CFrame, site.Size
	local rel = cf:PointToObjectSpace(near)
	local hx, hz = size.X / 2, size.Z / 2
	local x, z = math.clamp(rel.X, -hx, hx), math.clamp(rel.Z, -hz, hz)
	local def = CityErrands.Sites[site.Kind]
	local p: Vector3
	if def and def.Outdoor then
		local inward = Vector3.new(-x, 0, -z)
		local move = math.min(12, inward.Magnitude)
		p = Vector3.new(x, 0, z) + (if inward.Magnitude > 0.01 then inward.Unit * move else Vector3.new())
		p += Vector3.new(shift or 0, 0, 0)
	else
		-- El borde más cercano, 5 studs hacia fuera (y desplazado a lo largo del borde si hace falta)
		if hx - math.abs(x) < hz - math.abs(z) then
			x = (if x >= 0 then 1 else -1) * (hx + 5)
			z = math.clamp(z + (shift or 0), -hz, hz)
		else
			z = (if z >= 0 then 1 else -1) * (hz + 5)
			x = math.clamp(x + (shift or 0), -hx, hx)
		end
		p = Vector3.new(x, 0, z)
	end
	return groundAt(cf:PointToWorldSpace(Vector3.new(p.X, -size.Y / 2, p.Z)))
end

-- ¿Se puede estar de pie en este suelo? (a la altura del centro, sin agua y sin techo encima).
-- Si no, el objeto o la persona acaban en un tejado, dentro de un edificio o en el mar
local function standableHit(center: Vector3, hit: RaycastResult?): boolean
	if not hit then
		return false
	end
	if math.abs(hit.Position.Y - center.Y) > 4 then
		return false
	end
	if hit.Material == Enum.Material.Water then
		return false
	end
	local ok, roof = pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		return Ground.cast(hit.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, 6, 0), params)
	end)
	return ok and roof == nil
end

-- Un punto al azar alrededor de otro, entre min y max studs.
-- Prueba varios ángulos y distancias hasta dar con un sitio al que se pueda llegar andando
local function ringPoint(center: Vector3, min: number, max: number): Vector3
	for attempt = 1, 12 do
		local angle = math.random() * math.pi * 2
		-- En los últimos intentos se acerca un poco al centro (ahí suele haber calle)
		local far = if attempt > 8 then math.max(min * 0.5, 3) else min
		local distance = far + math.random() * math.max(0, max - far)
		local point = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		local ok, hit = pcall(function()
			return Ground.cast(point + Vector3.new(0, 40, 0), Vector3.new(0, -90, 0))
		end)
		if ok and standableHit(center, hit) then
			return hit.Position
		end
	end
	-- Nada sirvió: mejor al lado del centro (que sí se alcanza) que en un tejado
	local near = center + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
	local ok, hit = pcall(function()
		return Ground.cast(near + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0))
	end)
	if ok and standableHit(center, hit) then
		return hit.Position
	end
	return center
end

-- El sitio más cercano de esos tipos (sin contar el de quien pide el encargo), a una distancia de viaje
local function nearestSite(kinds: { string }, from: Vector3, exclude: Site?): Site?
	local best, bestDistance = nil, math.huge
	local fallback, fallbackDistance = nil, math.huge
	for _, site in sites do
		if table.find(kinds, site.Kind) and site ~= exclude and site.Instance ~= (exclude and exclude.Instance) then
			local d = flat(site.Center, from)
			if d >= CFG.MinTrip and d <= CFG.MaxTrip and d < bestDistance then
				best, bestDistance = site, d
			elseif d < fallbackDistance then
				fallback, fallbackDistance = site, d
			end
		end
	end
	return best or fallback
end

local function nearestPlayerDistance(point: Vector3): number
	local best = math.huge
	for _, player in Players:GetPlayers() do
		local position = positionOf(player)
		if position then
			best = math.min(best, flat(position, point))
		end
	end
	return best
end

---------------------------------------------------------------------
-- Gente con encargos
---------------------------------------------------------------------

local onGiverTriggered -- se define más abajo

local function givenCount(): number
	local n = 0
	for _ in givers do
		n += 1
	end
	return n
end

local function areaCount(point: Vector3): number
	local n = 0
	for _, giver in givers do
		if flat(giver.Position, point) <= CFG.AreaRadius then
			n += 1
		end
	end
	return n
end

local function makePrompt(parent: Instance, action: string, object: string, onTrigger: (Player) -> ()): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CFG.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	prompt.Triggered:Connect(onTrigger)
	return prompt
end

-- Los críos (Hugo, Dani, Lucas…) son más bajitos: se encoge el modelo y se vuelve a poner de pie
local function kidSize(model: Model, cf: CFrame)
	pcall(function()
		model:ScaleTo(0.72)
		Npc.placeFeet(model, cf)
	end)
end

local function despawn(giver: Giver)
	if givers[giver.SiteKey] == giver then
		givers[giver.SiteKey] = nil
	end
	if giver.Model then
		giver.Model:Destroy()
	end
end

-- Que se vaya al rato (después de dar las gracias)
local function leaveLater(giver: Giver, seconds: number)
	giver.Leaving = true
	Npc.icon(giver.Model, nil)
	siteRest[giver.SiteKey] = os.clock() + CFG.SiteRest
	task.delay(seconds, function()
		despawn(giver)
	end)
end

local function spawnGiver(site: Site, template: { [string]: any }, near: Vector3): Giver?
	-- Nunca encima de un jugador: se prueban varios sitios a lo largo del borde
	local feet: Vector3? = nil
	for _, shift in { 0, 8, -8, 16, -16, 24 } do
		local candidate = standPoint(site, near, shift)
		if nearestPlayerDistance(candidate) >= CFG.MinPlayerGap then
			feet = candidate
			break
		end
	end
	if not feet then
		return nil
	end
	local look = Vector3.new(near.X, feet.Y, near.Z)
	local cf = if flat(look, feet) > 0.5 then CFrame.lookAt(feet, look) else CFrame.new(feet)
	local model = Npc.create(template.Giver.Name, giverFolder, cf, template.Giver.Look)
	if template.Giver.Kid then
		kidSize(model, cf)
	end
	model:SetAttribute("CityErrand", template.Id)
	model:SetAttribute("NpcName", template.Giver.Name)
	local giver: Giver = {
		SiteKey = site.Key,
		Key = CityErrands.giverKey(template.Id, site.Key),
		Site = site,
		Template = template,
		Model = model,
		Position = feet,
	}
	Npc.icon(model, "❗")
	local rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	makePrompt(rootPart :: Instance, "Hablar", template.Giver.Name, function(player)
		onGiverTriggered(player, giver)
	end)
	givers[site.Key] = giver
	Log.info("ERRAND", "aparece %s (%s) en %s", template.Giver.Name, template.Id, site.Key)
	return giver
end

-- Pone a alguien con este encargo en este sitio (para las pruebas y el panel de depuración). Si ya
-- había alguien en el sitio, se va. near = desde dónde se le ve (se pone en ese lado).
function CityErrandService.place(site: Site, templateId: string, near: Vector3): Giver?
	local template = CityErrands.ById[templateId]
	if not template then
		return nil
	end
	local old = givers[site.Key]
	if old then
		despawn(old)
	end
	siteRest[site.Key] = nil
	return spawnGiver(site, template, near)
end

---------------------------------------------------------------------
-- Planear un encargo: adónde manda cada paso y cuánto se paga
---------------------------------------------------------------------

local function planFor(giver: Giver): ({ { [string]: any } }?, number)
	local plan = {}
	local from = giver.Position
	local total = 0
	for i, step in giver.Template.Steps do
		local entry: { [string]: any } = { Index = i }
		local kinds = CityErrands.targetKinds(step.To or step.At)
		local point: Vector3
		if step.Do == "Collect" then
			local center = giver.Position
			if kinds then
				local site = nearestSite(kinds, giver.Position, giver.Site)
				if not site then
					return nil, 0
				end
				center = standPoint(site, from)
			end
			entry.Center = center
			entry.Items = {}
			local min, max = step.Min or 6, step.Max or 20
			local walk = flat(center, from)
			local last = center
			for _ = 1, step.Count or 1 do
				local item = ringPoint(center, min, max)
				table.insert(entry.Items, item)
				walk += flat(item, last)
				last = item
			end
			point = last
			entry.Leg = walk
		else
			if step.To == "Giver" then
				point = giver.Position
			elseif step.To == "Near" then
				point = ringPoint(giver.Position, step.Min or 25, step.Max or 50)
			else
				local site = kinds and nearestSite(kinds, giver.Position, giver.Site)
				if not site then
					return nil, 0
				end
				point = standPoint(site, from)
			end
			entry.Leg = flat(point, from)
		end
		entry.Point = point
		entry.Seconds = CityErrands.stepSeconds(step, entry.Leg)
		total += entry.Leg
		from = point
		table.insert(plan, entry)
	end
	return plan, total
end

---------------------------------------------------------------------
-- El encargo en marcha
---------------------------------------------------------------------

local advance -- se define más abajo

local function stepOf(job: Job): { [string]: any }?
	return job.Template.Steps[job.Step]
end

local function currentTarget(player: Player, job: Job): Vector3?
	local step = stepOf(job)
	local entry = job.Plan[job.Step]
	if not step or not entry then
		return nil
	end
	if step.Do == "Collect" then
		local me = positionOf(player)
		local best, bestDistance = nil, math.huge
		for _, item in job.Items do
			if item.Parent then
				local p = item:GetPivot().Position
				local d = if me then flat(p, me) else 0
				if d < bestDistance then
					best, bestDistance = p, d
				end
			end
		end
		return best
	elseif (step.Do == "Deliver" or step.Do == "Talk") and step.To == "Giver" then
		return job.Giver.Model:GetPivot().Position
	elseif job.Recipient and job.Recipient.Parent then
		return job.Recipient:GetPivot().Position
	end
	return entry.Point
end

local function stepText(job: Job): string
	local step = stepOf(job)
	if not step then
		return ""
	end
	local text = step.Text
	if step.Do == "Collect" and (step.Count or 1) > 1 then
		text = ("%s (%d/%d)"):format(text, job.Collected, step.Count)
	end
	return text
end

local function publish(player: Player, job: Job?)
	if not job then
		if player:GetAttribute("CityErrand") ~= nil then
			player:SetAttribute("CityErrand", nil)
		end
		player:SetAttribute("CityErrandTarget", nil)
		return
	end
	local left = if job.Deadline then math.max(0, math.ceil(job.Deadline - os.clock())) else nil
	local state = {
		Id = job.Template.Id,
		Title = job.Template.Title,
		Giver = job.Template.Giver.Name,
		Step = stepText(job),
		StepNum = job.Step,
		StepTotal = #job.Template.Steps,
		Money = job.Money,
		Xp = job.Xp,
		Carry = job.Carry,
		Left = left,
	}
	local encoded = HttpService:JSONEncode(state)
	if encoded ~= job.LastPublished then
		job.LastPublished = encoded
		player:SetAttribute("CityErrand", encoded)
	end
	local target = currentTarget(player, job)
	if player:GetAttribute("CityErrandTarget") ~= target then
		player:SetAttribute("CityErrandTarget", target)
	end
end

local function clearStepObjects(job: Job)
	for _, item in job.Items do
		item:Destroy()
	end
	table.clear(job.Items)
	local recipient = job.Recipient
	job.Recipient = nil
	if recipient then
		-- Que se vea que te contesta antes de irse
		task.delay(6, function()
			recipient:Destroy()
		end)
	end
end

local function endJob(player: Player, job: Job)
	if active[player] == job then
		active[player] = nil
	end
	clearStepObjects(job)
	task.delay(6.5, function()
		job.Folder:Destroy()
	end)
	job.Giver.Busy = nil
	publish(player, nil)
end

local function finish(player: Player, job: Job)
	local template = job.Template
	endJob(player, job)
	DataService.addMoney(player, job.Money, true)
	ProgressionService.addXp(player, job.Xp, "CityErrand")
	local store = errandData(player)
	if store then
		store.Done += 1
	end
	setCooldown(player, job.Giver.Key, CFG.GiverCooldown)
	notify(player, "Success", ("✅ ¡Encargo hecho! «%s»: +%s y +%d XP"):format(template.Title, Format.money(job.Money), job.Xp))
	if job.Giver.Model and job.Giver.Model.Parent then
		Npc.say(job.Giver.Model, template.Thanks or "¡Mil gracias!", 5)
	end
	leaveLater(job.Giver, 6)
	Log.info("ERRAND", "%s termina %s (+%d, +%d XP)", player.Name, template.Id, job.Money, job.Xp)
end

local function fail(player: Player, job: Job, text: string, line: string?)
	endJob(player, job)
	setCooldown(player, job.Giver.Key, CFG.DeclineCooldown)
	notify(player, "Info", text)
	if job.Giver.Model and job.Giver.Model.Parent then
		Npc.say(job.Giver.Model, line or "Vaya… Bueno, no pasa nada. ¡Otra vez será!", 5)
	end
	leaveLater(job.Giver, 5)
end

local function spawnItem(player: Player, job: Job, step: { [string]: any }, at: Vector3)
	local spec = step.Item
	local ok, model = pcall(SceneService.buildProp, spec.Kind, spec)
	if not ok or not model then
		model = Instance.new("Model")
		local part = Instance.new("Part")
		part.Name = "PropBase"
		part.Size = Vector3.new(1.5, 1.5, 1.5)
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
		model.PrimaryPart = part
	end
	model.Name = spec.Name or spec.Kind
	model:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	model.Parent = job.Folder
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.85
	highlight.OutlineColor = Color3.fromRGB(80, 220, 255)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	local index = job.Step
	makePrompt(model.PrimaryPart or model, spec.Prompt or "Coger", spec.Name or spec.Kind, function(who)
		if who ~= player or active[player] ~= job or job.Step ~= index or not model.Parent then
			return
		end
		model:Destroy()
		job.Collected += 1
		local count = step.Count or 1
		if job.Collected >= count then
			job.Carry = spec.Name
			advance(player, job)
		else
			notify(player, "Info", ("%s: %d/%d"):format(spec.Name or "Recogido", job.Collected, count))
			publish(player, job)
		end
	end)
	table.insert(job.Items, model)
end

local function enterStep(player: Player, job: Job)
	local step = stepOf(job)
	local entry = job.Plan[job.Step]
	if not step or not entry then
		return
	end
	job.Deadline = if entry.Seconds then os.clock() + entry.Seconds else nil
	job.Collected = 0
	if step.Do == "Collect" then
		for _, at in entry.Items do
			spawnItem(player, job, step, at)
		end
	elseif (step.Do == "Deliver" or step.Do == "Talk") and step.To ~= "Giver" then
		local look = job.Giver.Position
		local cf = if flat(look, entry.Point) > 0.5 then CFrame.lookAt(entry.Point, Vector3.new(look.X, entry.Point.Y, look.Z)) else CFrame.new(entry.Point)
		local model = Npc.create(step.Npc, job.Folder, cf)
		if step.Kid then
			kidSize(model, cf)
		end
		model:SetAttribute("NpcName", step.Npc)
		Npc.icon(model, if step.Do == "Deliver" then "📦" else "💬")
		local index = job.Step
		local rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		makePrompt(rootPart :: Instance, step.Prompt or (if step.Do == "Deliver" then "Entregar" else "Hablar"), step.Npc, function(who)
			if who ~= player or active[player] ~= job or job.Step ~= index then
				return
			end
			Npc.icon(model, nil)
			if step.Line then
				Npc.say(model, step.Line, 6)
			end
			advance(player, job)
		end)
		job.Recipient = model
	end
	publish(player, job)
end

function advance(player: Player, job: Job)
	if active[player] ~= job then
		return
	end
	local step = stepOf(job)
	if step and step.Do == "Deliver" then
		job.Carry = nil
	end
	clearStepObjects(job)
	job.Step += 1
	if job.Step > #job.Template.Steps then
		finish(player, job)
		return
	end
	enterStep(player, job)
end

local function start(player: Player, giver: Giver, plan: { { [string]: any } }, reward: { Money: number, Xp: number })
	local folder = Instance.new("Folder")
	folderCount += 1
	folder.Name = ("Items_%d_%d"):format(player.UserId, folderCount)
	folder:SetAttribute("ErrandOwner", player.UserId)
	folder.Parent = root
	local job: Job = {
		Giver = giver,
		Template = giver.Template,
		Plan = plan,
		Step = 1,
		Carry = giver.Template.Give,
		Money = reward.Money,
		Xp = reward.Xp,
		Collected = 0,
		Items = {},
		Folder = folder,
	}
	active[player] = job
	giver.Busy = player
	Npc.icon(giver.Model, "⏳")
	notify(player, "Info", ("🧺 Encargo aceptado: «%s». Lo tienes en el panel de misiones y en el GPS."):format(giver.Template.Title))
	Log.info("ERRAND", "%s acepta %s", player.Name, giver.Template.Id)
	enterStep(player, job)
end

---------------------------------------------------------------------
-- Ofrecer
---------------------------------------------------------------------

-- ¿Se le puede ofrecer ahora este encargo? Devuelve true o false y el motivo:
-- "Busy" (conversación, escena, clase…), "Story" (misión principal en horario de cole), "Active" (ya
-- tiene uno), "Job" (trabajando), "Stage" (no es para su edad), "Closed", "Cooldown", "Taken"
function CityErrandService.canOffer(player: Player, giver: Giver): (boolean, string?)
	if not DataService.get(player) then
		return false, "Busy"
	end
	if DialogueService.isBusy(player) or player:GetAttribute("InDialogue") or player:GetAttribute("InPrologue") then
		return false, "Busy"
	end
	if player:GetAttribute("Dead") or player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil then
		return false, "Busy"
	end
	local block = LifeStoryService.errandBlock and LifeStoryService.errandBlock(player)
	if block then
		return false, block
	end
	if giver.Leaving or (giver.Busy and giver.Busy ~= player) or (giver.Talking and giver.Talking ~= player) then
		return false, "Taken"
	end
	if active[player] then
		return false, "Active"
	end
	if player:GetAttribute("Job") ~= nil then
		return false, "Job"
	end
	if not CityErrands.fitsStage(giver.Template, player:GetAttribute("LifeStage")) then
		return false, "Stage"
	end
	if not CityErrands.openNow(giver.Template, clockNow()) then
		return false, "Closed"
	end
	local store = errandData(player)
	if store and CityErrands.onCooldown(store.Cooldowns, giver.Key, os.time()) then
		return false, "Cooldown"
	end
	return true, nil
end

local function explain(player: Player, giver: Giver, reason: string?)
	local model = giver.Model
	if reason == "Stage" then
		local stage = player:GetAttribute("LifeStage")
		local kid = stage == "Nino" or stage == "Adolescente"
		Npc.say(model, if kid then "Uy, esto es cosa de mayores. ¡Pero gracias, campeón!" else "Esto mejor se lo pido a algún peque, que les hace ilusión. ¡Gracias!", 4)
	elseif reason == "Cooldown" then
		Npc.say(model, "¡Anda, otra vez tú! Ya me ayudaste antes. Vuelve más tarde, que ahora no tengo nada.", 4)
	elseif reason == "Taken" then
		Npc.say(model, "¡Ya me está echando una mano alguien! Gracias igualmente.", 4)
	elseif reason == "Closed" then
		Npc.say(model, "Uy, que ya es tarde. ¡Mañana hablamos!", 4)
	elseif reason == "Active" then
		notify(player, "Info", "Ya tienes un encargo en marcha: termínalo o déjalo (panel de misiones).")
	elseif reason == "Job" then
		notify(player, "Info", "Estás trabajando: acaba el turno y luego hablamos.")
	elseif reason == "Story" then
		notify(player, "Info", "Ahora toca ir al cole con tu misión. ¡Luego te piden el favor!")
	end
end

local function offer(player: Player, giver: Giver): boolean
	local plan, distance = planFor(giver)
	if not plan then
		Npc.say(giver.Model, "Mmm… pensándolo mejor, ya me apaño yo. ¡Gracias!", 4)
		return false
	end
	local template = giver.Template
	local reward = CityErrands.reward(template, distance)
	local name = template.Giver.Name
	local lines: { { [string]: any } } = {}
	for _, text in template.Lines do
		table.insert(lines, { S = name, T = text })
	end
	table.insert(lines, {
		Ask = "¿Le echas una mano?",
		Options = {
			{ T = ("¡Claro, yo me encargo! (%s · %d XP)"):format(Format.money(reward.Money), reward.Xp), Effects = { CityErrand = "Accept" }, Then = { { S = name, T = "¡Eres un sol! Te lo apunto en el GPS." } } },
			{ T = "Ahora no puedo, lo siento", Effects = { CityErrand = "Decline" }, Then = { { S = name, T = "Nada, nada, otro día será." } } },
		},
	})
	local choice: string? = nil
	giver.Talking = player
	local context = {
		apply = function(effects: { [string]: any }?)
			if effects and effects.CityErrand then
				choice = effects.CityErrand
			end
		end,
		actorOf = function(id: string): Instance?
			return if id == name then giver.Model else nil
		end,
	}
	local started = DialogueService.play(player, { Lines = lines }, context, function()
		giver.Talking = nil
		if choice == "Accept" and not active[player] and not giver.Busy and giver.Model.Parent and givers[giver.SiteKey] == giver then
			start(player, giver, plan, reward)
		elseif choice == "Decline" then
			setCooldown(player, giver.Key, CFG.DeclineCooldown)
		end
	end, function()
		giver.Talking = nil
	end)
	if not started then
		giver.Talking = nil
	end
	return started
end

function onGiverTriggered(player: Player, giver: Giver)
	local job = active[player]
	if (givers[giver.SiteKey] ~= giver or giver.Leaving) and not (job and job.Giver == giver) then
		return -- (ya se va)
	end
	if job and job.Giver == giver then
		-- Vuelves con quien te lo pidió: entregar, contarle algo… o te recuerda qué falta
		local step = stepOf(job)
		if step and (step.Do == "Deliver" or step.Do == "Talk") and step.To == "Giver" then
			advance(player, job)
		elseif step then
			Npc.say(giver.Model, step.Text .. ". ¡Cuento contigo!", 4)
		end
		return
	end
	local ok, reason = CityErrandService.canOffer(player, giver)
	if not ok then
		explain(player, giver, reason)
		return
	end
	offer(player, giver)
end

-- Para las pruebas y el panel de depuración: hablar con alguien como si pulsaras E
function CityErrandService.talk(player: Player, giver: Giver)
	onGiverTriggered(player, giver)
end

---------------------------------------------------------------------
-- Dejar un encargo
---------------------------------------------------------------------

function CityErrandService.abandon(player: Player): boolean
	local job = active[player]
	if not job then
		return false
	end
	fail(player, job, ("Has dejado el encargo «%s»."):format(job.Template.Title))
	return true
end

function CityErrandService.activeOf(player: Player): Job?
	return active[player]
end

function CityErrandService.givers(): { [string]: Giver }
	return givers
end

---------------------------------------------------------------------
-- Repasos
---------------------------------------------------------------------

-- El encargo en marcha: tiempo, llegar, quien te sigue y el objetivo del GPS
local function tickJob(player: Player, job: Job)
	local step = stepOf(job)
	local entry = job.Plan[job.Step]
	if not step or not entry then
		return
	end
	if not job.Giver.Model.Parent then
		fail(player, job, ("El encargo «%s» se ha cancelado."):format(job.Template.Title))
		return
	end
	if job.Deadline and os.clock() > job.Deadline then
		fail(player, job, ("⏰ ¡Se acabó el tiempo! «%s» se queda sin hacer."):format(job.Template.Title), "¡Uy, ya es tarde! No pasa nada, otra vez será.")
		return
	end
	local me = positionOf(player)
	if not me then
		return
	end
	if step.Do == "Reach" then
		if flat(me, entry.Point) <= CFG.ReachRadius then
			advance(player, job)
			return
		end
	elseif step.Do == "Escort" then
		-- Quien te lo pidió te sigue: si se queda muy atrás, te alcanza
		local model = job.Giver.Model
		local at = model:GetPivot().Position
		local gap = flat(at, me)
		if gap > CFG.EscortLost then
			local behind = me + Vector3.new(3, 0, 3)
			Npc.placeFeet(model, CFrame.new(groundAt(behind)))
		elseif gap > 6 and not Npc.isWalking(model) then
			local dir = Vector3.new(at.X - me.X, 0, at.Z - me.Z)
			local goal = me + (if dir.Magnitude > 0.01 then dir.Unit * 4 else Vector3.new(4, 0, 0))
			task.spawn(Npc.walkTo, model, { groundAt(goal) }, 16)
		end
		at = model:GetPivot().Position
		if flat(me, entry.Point) <= CFG.ReachRadius + 4 and flat(at, entry.Point) <= CFG.ReachRadius + 14 then
			job.Giver.Position = groundAt(at)
			advance(player, job)
			return
		end
	end
	publish(player, job)
end

-- Quién aparece y quién se va (alrededor de cada jugador)
local function scan()
	ensureIndex()
	local now = os.clock()
	local clock = clockNow()
	for _, giver in givers do
		if not giver.Busy and not giver.Talking and not giver.Leaving then
			if not giver.Model.Parent or nearestPlayerDistance(giver.Position) > CFG.DespawnRange or not CityErrands.openNow(giver.Template, clock) then
				despawn(giver)
			end
		end
	end
	for _, player in Players:GetPlayers() do
		local position = positionOf(player)
		local stage = player:GetAttribute("LifeStage")
		if position and type(stage) == "string" and stage ~= "Bebe" then
			local store = errandData(player)
			local near = {}
			for _, site in sites do
				local d = flat(site.Center, position)
				if d <= CFG.SpawnRange then
					table.insert(near, { Site = site, D = d })
				end
			end
			table.sort(near, function(a, b)
				return a.D < b.D
			end)
			local spawned = 0
			for _, entry in near do
				if spawned >= CFG.SpawnsPerScan or givenCount() >= CFG.MaxTotal then
					break
				end
				local site = entry.Site
				if not givers[site.Key] and (siteRest[site.Key] or 0) <= now and areaCount(site.Center) < CFG.MaxPerArea then
					local choices = {}
					for _, template in CityErrands.forSite(site.Kind, stage, clock) do
						local key = CityErrands.giverKey(template.Id, site.Key)
						if not (store and CityErrands.onCooldown(store.Cooldowns, key, os.time())) then
							table.insert(choices, template)
						end
					end
					if #choices > 0 and spawnGiver(site, choices[math.random(1, #choices)], position) then
						spawned += 1
					end
				end
			end
		end
	end
	-- Los ❗ del mapa de cada jugador: los que tiene cerca y le pueden pedir algo
	for _, player in Players:GetPlayers() do
		local position = positionOf(player)
		local store = errandData(player)
		local stage = player:GetAttribute("LifeStage")
		local marks = {}
		if position then
			for _, giver in givers do
				if not giver.Busy and not giver.Leaving and flat(giver.Position, position) <= CFG.MarkRange
					and CityErrands.fitsStage(giver.Template, stage)
					and not (store and CityErrands.onCooldown(store.Cooldowns, giver.Key, os.time())) then
					table.insert(marks, {
						Id = giver.SiteKey,
						Title = giver.Template.Title,
						Giver = giver.Template.Giver.Name,
						X = math.round(giver.Position.X), Y = math.round(giver.Position.Y), Z = math.round(giver.Position.Z),
					})
				end
			end
		end
		table.sort(marks, function(a, b)
			return a.Id < b.Id
		end)
		local encoded = HttpService:JSONEncode(marks)
		if player:GetAttribute("CityErrandMarks") ~= encoded then
			player:SetAttribute("CityErrandMarks", encoded)
		end
	end
end

function CityErrandService.scan()
	scan()
end

function CityErrandService.tick()
	for player, job in active do
		if player.Parent then
			local ok, err = pcall(tickJob, player, job)
			if not ok then
				Log.warn("ERRAND", "%s: %s", player.Name, tostring(err))
			end
		end
	end
end

function CityErrandService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("CityErrand") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "CityErrand"
		Remote.Parent = remotes
	end
	Notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	root = Instance.new("Folder")
	root.Name = "CityErrands"
	root.Parent = workspace
	giverFolder = Instance.new("Folder")
	giverFolder.Name = "Givers"
	giverFolder.Parent = root
	Remote.OnServerEvent:Connect(function(player, kind)
		if kind == "Abandon" then
			CityErrandService.abandon(player)
		elseif kind == "Sync" then
			publish(player, active[player])
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local job = active[player]
		if job then
			endJob(player, job)
			leaveLater(job.Giver, 0)
		end
		for _, giver in givers do
			if giver.Talking == player then
				giver.Talking = nil
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(CFG.TickEvery)
			CityErrandService.tick()
		end
	end)
	task.spawn(function()
		task.wait(CityErrandService.StartDelay)
		while true do
			local ok, err = pcall(scan)
			if not ok then
				Log.warn("ERRAND", "repaso: %s", tostring(err))
			end
			task.wait(CFG.ScanEvery)
		end
	end)
end

return CityErrandService
