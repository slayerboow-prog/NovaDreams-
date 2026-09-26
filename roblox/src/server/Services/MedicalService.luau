-- MedicalService: los hospitales y centros de salud funcionan (oficio de médico/a).
--
-- PACIENTES
--   * Llegan pacientes NPC: pasan por admisión, cogen turno y esperan sentados.
--   * Un jugador también puede "Pedir cita" en admisión: si hay médico jugador le atiende él;
--     si no, le hace una consulta rápida el médico NPC (Medical.QuickVisitPrice) y le cura.
--
-- MÉDICO/A (tablón "Trabajar" de la entrada; desde mayor de edad)
--   * Te dan una CONSULTA. En el escritorio: "Llamar al siguiente paciente" (entra y se sienta en
--     la camilla y te cuenta lo que le pasa).
--   * En tu panel exploras al paciente junto a la camilla: temperatura, auscultar, garganta,
--     tensión, palpar. Cada prueba da un resultado.
--   * Eliges el diagnóstico. Si aciertas: coges la medicina en el botiquín y "Aplicar tratamiento"
--     en la camilla. Si fallas, el paciente se va (y te dice lo que tenía).
--   * Cobras por paciente, más si aciertas; con el título de Medicina cobras más.
--     Cada paciente cuenta para la historia (JobTaskDone con JobId "Medico").

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Medical = require(ReplicatedStorage.Shared.Medical)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local MedicalService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Medical :: RemoteEvent
local JOB = Medical.Job

local ACTIVE_RANGE = 220
local BED_RANGE = 14

type Room = { Id: number, Desk: BasePart, Bed: BasePart, Meds: BasePart, Door: Vector3, Doctor: Player?, Patient: any? }
type Clinic = {
	Model: Model,
	Rooms: { Room },
	Reception: BasePart,
	Seats: { BasePart },
	Taken: { [BasePart]: boolean },
	Waiting: { any },
	Folder: Folder,
	NpcDoctor: Model?,
	LastSpawn: number,
	LastNpcCall: number,
	Count: number,
}
type Session = {
	Clinic: Clinic,
	Room: Room,
	Patient: any?,
	Exams: { [string]: string },
	Phase: "Call" | "Examine" | "Treat" | "Apply",
	Options: { string }?,
	Medicine: string?,
	Correct: boolean,
}

local clinics: { Clinic } = {}
local sessions: { [Player]: Session } = {}
local playerPatients: { [Player]: any } = {}
local nextPatient = 0

local NAMES = { "Antonio", "Pilar", "Manuel", "Lola", "Rafael", "Elena", "Jorge", "Sofía", "Luis", "Teresa", "Hugo", "Alba" }

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isDay(): boolean
	local clock = Lighting.ClockTime
	return clock >= 7 and clock < 22
end

local function clinicNear(position: Vector3, range: number): Clinic?
	local best, bestDist = nil, range
	for _, clinic in clinics do
		local d = (clinic.Reception.Position - position).Magnitude
		if d < bestDist then
			best, bestDist = clinic, d
		end
	end
	return best
end

local function point(clinic: Clinic, name: string): Vector3
	return clinic.Model:GetAttribute(name) :: Vector3
end

local function hasDoctor(clinic: Clinic): boolean
	for _, room in clinic.Rooms do
		if room.Doctor then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Panel del médico
---------------------------------------------------------------------

local function publish(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	local patient = s.Patient
	local exams = {}
	for _, e in Medical.Exams do
		table.insert(exams, { Id = e.Id, Name = e.Name, Icon = e.Icon, Result = s.Exams[e.Id] })
	end
	local options = nil
	if s.Options then
		options = {}
		for _, id in s.Options do
			table.insert(options, { Id = id, Name = Medical.byId[id].Name })
		end
	end
	Remote:FireClient(player, "Case", {
		Room = s.Room.Id,
		Phase = s.Phase,
		Waiting = #s.Clinic.Waiting,
		Patient = if patient then patient.Name else nil,
		Says = if patient then patient.Says else nil,
		Exams = exams,
		Options = options,
		Medicine = if s.Medicine then Medical.medicineById[s.Medicine].Name else nil,
	})
	if s.Phase == "Call" then
		player:SetAttribute("TaskTarget", s.Room.Desk.Position)
		player:SetAttribute("TaskText", ("Consulta %d: llama al siguiente paciente (%d esperando)"):format(s.Room.Id, #s.Clinic.Waiting))
	elseif s.Phase == "Treat" then
		player:SetAttribute("TaskTarget", s.Room.Meds.Position)
		player:SetAttribute("TaskText", "Coge la medicina en el botiquín")
	else
		player:SetAttribute("TaskTarget", s.Room.Bed.Position)
		player:SetAttribute("TaskText", if s.Phase == "Apply" then "Aplica el tratamiento en la camilla" else "Explora al paciente y elige el diagnóstico")
	end
end

---------------------------------------------------------------------
-- Pacientes
---------------------------------------------------------------------

local function newPatient(name: string): any
	nextPatient += 1
	local ailment = Medical.Ailments[math.random(1, #Medical.Ailments)]
	return { Id = nextPatient, Name = name, Ailment = ailment.Id, Says = ailment.Says[math.random(1, #ailment.Says)], State = "Waiting" }
end

local function freeSeat(clinic: Clinic, patient: any)
	if patient.Seat then
		clinic.Taken[patient.Seat] = nil
		patient.Seat = nil
	end
end

local function leaveClinic(clinic: Clinic, patient: any, text: string?)
	freeSeat(clinic, patient)
	local i = table.find(clinic.Waiting, patient)
	if i then
		table.remove(clinic.Waiting, i)
	end
	patient.State = "Done"
	local npc = patient.Model
	if npc and npc.Parent then
		task.spawn(function()
			if text then
				Npc.say(npc, text)
			end
			Npc.stand(npc, nil)
			Npc.walkTo(npc, { point(clinic, "Door"), point(clinic, "Outside") }, 7)
			npc:Destroy()
			clinic.Count -= 1
		end)
	end
end

-- El paciente entra en la consulta y se sienta en la camilla
local function bringToRoom(clinic: Clinic, room: Room, patient: any)
	freeSeat(clinic, patient)
	patient.State = "InRoom"
	room.Patient = patient
	local npc = patient.Model
	if npc and npc.Parent then
		task.spawn(function()
			Npc.stand(npc, nil)
			-- Hasta la puerta de la consulta y luego junto a la camilla (a ras de suelo)
			local bed = Vector3.new(room.Bed.Position.X, room.Door.Y, room.Bed.Position.Z)
			local toDoor = room.Door - bed
			local beside = if toDoor.Magnitude > 2 then bed + toDoor.Unit * 2 else bed
			Npc.walkTo(npc, { room.Door, beside }, 6)
			if npc.Parent and room.Patient == patient then
				Npc.sit(npc, room.Bed)
				Npc.say(npc, patient.Says)
				task.delay(6, function()
					if npc.Parent then
						Npc.say(npc, nil)
					end
				end)
			end
		end)
	elseif patient.Player then
		Notify:FireClient(patient.Player, "Info", ("🩺 Te llaman a la CONSULTA %d."):format(room.Id))
		patient.Player:SetAttribute("TaskTarget", room.Door)
		patient.Player:SetAttribute("TaskText", ("Ve a la consulta %d"):format(room.Id))
	end
end

local function healPlayer(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	playerPatients[player] = nil
end

---------------------------------------------------------------------
-- Consulta: llamar, explorar, diagnosticar, tratar
---------------------------------------------------------------------

local function nearBed(player: Player, s: Session): boolean
	local root = rootOf(player)
	return root ~= nil and (root.Position - s.Room.Bed.Position).Magnitude <= BED_RANGE
end

local function onDesk(player: Player, clinic: Clinic, room: Room)
	local s = sessions[player]
	if not s or s.Room ~= room then
		Notify:FireClient(player, "Info", if s then ("Tu consulta es la %d."):format(s.Room.Id) else "Esta consulta es para el médico de guardia.")
		return
	end
	if s.Patient then
		Notify:FireClient(player, "Info", "Primero termina con el paciente que tienes.")
		return
	end
	local patient = table.remove(clinic.Waiting, 1)
	if not patient then
		Notify:FireClient(player, "Info", "No hay nadie esperando. Espera un poco a que llegue alguien.")
		publish(player)
		return
	end
	s.Patient = patient
	s.Exams = {}
	s.Options = nil
	s.Medicine = nil
	s.Phase = "Examine"
	bringToRoom(clinic, room, patient)
	publish(player)
end

local function onExam(player: Player, examId: any)
	local s = sessions[player]
	if not s or not s.Patient or s.Phase ~= "Examine" or typeof(examId) ~= "string" then
		return
	end
	if not nearBed(player, s) then
		Notify:FireClient(player, "Info", "Acércate a la camilla para explorar al paciente.")
		return
	end
	local ailment = Medical.byId[s.Patient.Ailment]
	local result = ailment and ailment.Results[examId]
	if not result then
		return
	end
	s.Exams[examId] = result
	-- Con dos pruebas ya se puede diagnosticar: el correcto y tres más al azar
	local count = 0
	for _ in s.Exams do
		count += 1
	end
	if count >= 2 and not s.Options then
		local options = { s.Patient.Ailment }
		local pool = {}
		for _, a in Medical.Ailments do
			if a.Id ~= s.Patient.Ailment then
				table.insert(pool, a.Id)
			end
		end
		for _ = 1, 3 do
			table.insert(options, table.remove(pool, math.random(1, #pool)))
		end
		for i = #options, 2, -1 do
			local j = math.random(1, i)
			options[i], options[j] = options[j], options[i]
		end
		s.Options = options
	end
	publish(player)
end

local finishPatient -- se define más abajo

local function onDiagnose(player: Player, ailmentId: any)
	local s = sessions[player]
	if not s or not s.Patient or s.Phase ~= "Examine" or not s.Options or not table.find(s.Options, ailmentId) then
		return
	end
	if ailmentId == s.Patient.Ailment then
		s.Correct = true
		s.Phase = "Treat"
		Notify:FireClient(player, "Success", ("Diagnóstico: %s. Coge la medicina en el botiquín."):format(Medical.byId[ailmentId].Name))
		publish(player)
	else
		s.Correct = false
		Notify:FireClient(player, "Error", ("No era eso: tenía %s. El paciente se va a pedir otra opinión."):format(string.lower(Medical.byId[s.Patient.Ailment].Name)))
		finishPatient(player, false)
	end
end

local function onMeds(player: Player, room: Room)
	local s = sessions[player]
	if not s or s.Room ~= room then
		return
	end
	if s.Phase ~= "Treat" and s.Phase ~= "Apply" then
		Notify:FireClient(player, "Info", "Primero explora al paciente y haz el diagnóstico.")
		return
	end
	Remote:FireClient(player, "Meds", Medical.Medicines)
end

local function onMedicine(player: Player, medicineId: any)
	local s = sessions[player]
	if not s or (s.Phase ~= "Treat" and s.Phase ~= "Apply") or typeof(medicineId) ~= "string" or not Medical.medicineById[medicineId] then
		return
	end
	s.Medicine = medicineId
	s.Phase = "Apply"
	Notify:FireClient(player, "Info", ("Llevas: %s. Aplícalo en la camilla."):format(Medical.medicineById[medicineId].Name))
	publish(player)
end

local function onApply(player: Player, room: Room)
	local s = sessions[player]
	if not s or s.Room ~= room or not s.Patient then
		return
	end
	if s.Phase ~= "Apply" or not s.Medicine then
		Notify:FireClient(player, "Info", if s.Phase == "Treat" then "Te falta la medicina: cógela en el botiquín." else "Primero explora al paciente y haz el diagnóstico.")
		return
	end
	local ailment = Medical.byId[s.Patient.Ailment]
	if s.Medicine ~= ailment.Medicine then
		Notify:FireClient(player, "Error", ("Eso no es para %s. Vuelve al botiquín."):format(string.lower(ailment.Name)))
		s.Medicine = nil
		s.Phase = "Treat"
		publish(player)
		return
	end
	finishPatient(player, true)
end

function finishPatient(player: Player, cured: boolean)
	local s = sessions[player]
	if not s or not s.Patient then
		return
	end
	local patient = s.Patient
	s.Patient = nil
	s.Room.Patient = nil
	s.Phase = "Call"
	s.Options = nil
	s.Medicine = nil
	s.Exams = {}
	-- Sueldo
	local data = DataService.get(player)
	local degree = data and data.Education and data.Education.Degrees and data.Education.Degrees.Grado_Medicina
	local base = JOB.PerPatient + (if cured then JOB.RightDiagnosis else 0)
	local pay = math.floor(base * (if degree then JOB.DegreeMultiplier else 1) * MonetizationService.payMultiplier(player))
	if not cured then
		pay = math.floor(pay * 0.3)
	end
	DataService.addMoney(player, pay, true)
	if data then
		data.Stats.TasksDone += 1
	end
	NeedsService.change(player, 0, -JOB.EnergyCost)
	Notify:FireClient(player, "Money", ("+%s · %s"):format(Format.money(pay), if cured then "paciente curado" else "consulta"))
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Medico", Pay = pay })
	-- El paciente se va
	if patient.Player then
		if cured then
			healPlayer(patient.Player)
			Notify:FireClient(patient.Player, "Success", ("🩺 ¡Curado! Tenías %s."):format(string.lower(Medical.byId[patient.Ailment].Name)))
		else
			playerPatients[patient.Player] = nil
			patient.Player:SetAttribute("TaskTarget", nil)
			patient.Player:SetAttribute("TaskText", nil)
		end
	end
	leaveClinic(s.Clinic, patient, if cured then "¡Gracias, doctor! Ya me encuentro mejor." else "Mmm… iré a otro médico.")
	publish(player)
	if not NeedsService.canWork(player) then
		MedicalService.quit(player, true)
		Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
	end
end

---------------------------------------------------------------------
-- Admisión: pedir cita (jugadores)
---------------------------------------------------------------------

local function onReception(player: Player, clinic: Clinic)
	if sessions[player] then
		Notify:FireClient(player, "Info", "Estás de guardia: llama a los pacientes desde tu consulta.")
		return
	end
	if playerPatients[player] then
		Notify:FireClient(player, "Info", "Ya tienes cita: espera a que te llamen.")
		return
	end
	if hasDoctor(clinic) then
		local patient = newPatient(player.DisplayName or player.Name)
		patient.Player = player
		playerPatients[player] = patient
		table.insert(clinic.Waiting, patient)
		Notify:FireClient(player, "Info", ("Tienes cita. Espera en la sala: %d personas delante."):format(#clinic.Waiting - 1))
		return
	end
	-- Sin médico jugador: consulta rápida con el médico NPC
	if not DataService.spend(player, Medical.QuickVisitPrice) then
		Notify:FireClient(player, "Error", "No tienes dinero para la consulta.")
		return
	end
	Notify:FireClient(player, "Info", "🩺 El médico de guardia te atiende en un momento…")
	task.delay(3, function()
		if player.Parent then
			healPlayer(player)
			Notify:FireClient(player, "Success", "🩺 Revisión hecha: estás como nuevo.")
		end
	end)
end

---------------------------------------------------------------------
-- Pacientes NPC y médico NPC
---------------------------------------------------------------------

local function spawnPatient(clinic: Clinic)
	local free = {}
	for _, seat in clinic.Seats do
		if not clinic.Taken[seat] then
			table.insert(free, seat)
		end
	end
	if #free == 0 then
		return
	end
	local seat = free[math.random(1, #free)]
	local patient = newPatient(NAMES[math.random(1, #NAMES)])
	local npc = Npc.create("Paciente", clinic.Folder, CFrame.new(point(clinic, "Outside")), nil)
	patient.Model = npc
	patient.Seat = seat
	clinic.Taken[seat] = true
	clinic.Count += 1
	table.insert(clinic.Waiting, patient)
	task.spawn(function()
		Npc.walkTo(npc, { point(clinic, "Door"), point(clinic, "Reception") }, 6)
		if not npc.Parent or patient.State ~= "Waiting" then
			return
		end
		Npc.face(npc, clinic.Reception.Position)
		Npc.say(npc, "Buenas, tengo cita…")
		task.wait(2)
		Npc.say(npc, nil)
		if patient.State ~= "Waiting" then
			return
		end
		Npc.walkTo(npc, { seat.Position + seat.CFrame.LookVector * 1.8 - Vector3.new(0, seat.Position.Y - point(clinic, "Door").Y, 0) }, 6)
		if npc.Parent and patient.State == "Waiting" then
			Npc.sit(npc, seat)
		end
	end)
	-- Si nadie le atiende en mucho rato, se va
	task.delay(240, function()
		if patient.State == "Waiting" then
			leaveClinic(clinic, patient, "Llevo horas esperando… vuelvo mañana.")
		end
	end)
end

local function refreshStaff(clinic: Clinic, active: boolean)
	local want = active and isDay() and not hasDoctor(clinic)
	if want and not clinic.NpcDoctor then
		local spot = point(clinic, "Reception") + Vector3.new(0, 0, 5)
		clinic.NpcDoctor = Npc.create("Npc_Medico", clinic.Folder, CFrame.new(spot), { Shirt = Color3.fromRGB(245, 245, 245), Pants = Color3.fromRGB(245, 245, 245) })
	elseif not want and clinic.NpcDoctor then
		clinic.NpcDoctor:Destroy()
		clinic.NpcDoctor = nil
	end
	-- El médico NPC va pasando pacientes a la consulta 1 de vez en cuando
	if clinic.NpcDoctor and #clinic.Waiting > 0 and os.clock() - clinic.LastNpcCall > 25 then
		clinic.LastNpcCall = os.clock()
		local patient = nil
		for i, p in clinic.Waiting do
			if p.Model then
				patient = table.remove(clinic.Waiting, i)
				break
			end
		end
		if patient then
			local room = clinic.Rooms[1]
			bringToRoom(clinic, room, patient)
			task.delay(14, function()
				if room.Patient == patient then
					room.Patient = nil
				end
				leaveClinic(clinic, patient, "¡Gracias, doctora!")
			end)
		end
	end
end

local function anyoneNear(clinic: Clinic): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - clinic.Reception.Position).Magnitude < ACTIVE_RANGE then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Guardia: empezar y dejar
---------------------------------------------------------------------

function MedicalService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not Stages.inRange(player:GetAttribute("LifeStage") or "", JOB.MinStage, nil) then
		Notify:FireClient(player, "Error", "Para trabajar de médico hay que ser mayor de edad.")
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	local root = rootOf(player)
	local clinic = root and clinicNear(root.Position, 120)
	if not clinic then
		return
	end
	local room = nil
	for _, r in clinic.Rooms do
		if not r.Doctor then
			room = r
			break
		end
	end
	if not room then
		Notify:FireClient(player, "Error", "Todas las consultas están ocupadas. Vuelve más tarde.")
		return
	end
	JobService.quit(player, true)
	room.Doctor = player
	sessions[player] = { Clinic = clinic, Room = room, Patient = nil, Exams = {}, Phase = "Call", Correct = false }
	RoleService.setOnDuty(player, "Medico")
	player:SetAttribute("Job", "Medico")
	refreshStaff(clinic, true)
	Remote:FireClient(player, "Start")
	local data = DataService.get(player)
	local degree = data and data.Education and data.Education.Degrees and data.Education.Degrees.Grado_Medicina
	Notify:FireClient(player, "Success", ("¡De guardia en la consulta %d!%s"):format(room.Id, if degree then " (con tu título de Medicina cobras más)" else ""))
	publish(player)
end

function MedicalService.quit(player: Player, silent: boolean?)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	s.Room.Doctor = nil
	if s.Patient then
		-- El paciente vuelve a la sala de espera (lo atenderá otro)
		s.Room.Patient = nil
		s.Patient.State = "Waiting"
		table.insert(s.Clinic.Waiting, 1, s.Patient)
	end
	RoleService.offDuty(player, "Medico")
	if player:GetAttribute("Job") == "Medico" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado la guardia.")
	end
end

---------------------------------------------------------------------

local function jobPrompt(parent: BasePart, action: string, object: string, hold: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	p:SetAttribute("JobOnly", "Medico")
	p.Parent = parent
	return p
end

local function setupClinic(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for _, c in clinics do
		if c.Model == model then
			return
		end
	end
	local rooms: { [number]: any } = {}
	local reception
	local seats = {}
	for _, d in model:GetDescendants() do
		local id = d:GetAttribute("RoomId")
		if id then
			rooms[id] = rooms[id] or { Id = id }
			if d:HasTag("ClinicDesk") then
				rooms[id].Desk = d
			elseif d:HasTag("ClinicBed") then
				rooms[id].Bed = d
			elseif d:HasTag("ClinicMeds") then
				rooms[id].Meds = d
			end
		elseif d:HasTag("ClinicReception") then
			reception = d
		elseif d:HasTag("ClinicSeat") then
			table.insert(seats, d)
		end
	end
	if not reception then
		return
	end
	local list: { Room } = {}
	for id = 1, #rooms do
		local r = rooms[id]
		if r and r.Desk and r.Bed and r.Meds then
			r.Door = model:GetAttribute("Room" .. id .. "Door") or r.Desk.Position
			table.insert(list, r)
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "ClinicLife"
	folder.Parent = model
	local clinic: Clinic = { Model = model, Rooms = list, Reception = reception, Seats = seats, Taken = {}, Waiting = {}, Folder = folder, NpcDoctor = nil, LastSpawn = 0, LastNpcCall = 0, Count = 0 }
	table.insert(clinics, clinic)

	local ask = Instance.new("ProximityPrompt")
	ask.ActionText = "Pedir cita"
	ask.ObjectText = "🏥 Admisión"
	ask.HoldDuration = 0.3
	ask.MaxActivationDistance = 10
	ask.RequiresLineOfSight = false
	ask.Parent = reception
	ask.Triggered:Connect(function(player)
		onReception(player, clinic)
	end)
	for _, room in list do
		jobPrompt(room.Desk, "Llamar al siguiente paciente", ("🩺 Consulta %d"):format(room.Id), 0.4).Triggered:Connect(function(player)
			onDesk(player, clinic, room)
		end)
		jobPrompt(room.Meds, "Coger medicina", "💊 Botiquín", 0.3).Triggered:Connect(function(player)
			onMeds(player, room)
		end)
		jobPrompt(room.Bed, "Aplicar tratamiento", "🛏️ Camilla", 1).Triggered:Connect(function(player)
			onApply(player, room)
		end)
	end
end

function MedicalService.init()
	for _, model in CollectionService:GetTagged("Clinic") do
		setupClinic(model)
	end
	CollectionService:GetInstanceAddedSignal("Clinic"):Connect(setupClinic)
	JobService.setHandler("Medico", { Start = MedicalService.start, Quit = MedicalService.quit })

	Remote.OnServerEvent:Connect(function(player, action, value)
		if action == "Exam" then
			onExam(player, value)
		elseif action == "Diagnose" then
			onDiagnose(player, value)
		elseif action == "Medicine" then
			onMedicine(player, value)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		MedicalService.quit(player, true)
		local patient = playerPatients[player]
		if patient then
			patient.State = "Done"
			for _, clinic in clinics do
				local i = table.find(clinic.Waiting, patient)
				if i then
					table.remove(clinic.Waiting, i)
				end
			end
			playerPatients[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			task.wait(2)
			for _, clinic in clinics do
				local ok, err = pcall(function()
					local active = anyoneNear(clinic)
					refreshStaff(clinic, active)
					if active and isDay() and #clinic.Waiting < Medical.MaxWaiting and clinic.Count < Medical.MaxWaiting + 2 and os.clock() - clinic.LastSpawn > math.random(12, 22) then
						clinic.LastSpawn = os.clock()
						spawnPatient(clinic)
					end
				end)
				if not ok then
					warn("[MedicalService] " .. tostring(err))
				end
			end
			for player in sessions do
				publish(player)
			end
		end
	end)
end

return MedicalService
