-- ClassService: las clases, exámenes, ratos de estudio y prácticas se JUEGAN.
--
--   * Preguntas con respuestas a elegir (el servidor guarda cuál es la buena: no se puede hacer trampa).
--     Salen de QuestionBank.luau o se generan con código (QuestionGen: Matemáticas, Cálculo…).
--   * Educación Física: recorrer a tiempo los puntos que aparecen en la pista del colegio.
--   * Da la clase un profesor jugador de servicio si hay (RoleService) o, si no, un NPC.
--   * Al terminar: nota de 0 a 10, se guarda en data.Education y se avisa a la historia
--     (StoryEvents: LessonCompleted, ExamGraded, Studied, PracticeDone).
--
-- Lo usa LifeStoryService con el paso { Type = "Class", Subject, Mode, Place }.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifeStory = ReplicatedStorage.Shared.LifeStory
local Subjects = require(LifeStory.Subjects)
local QuestionGen = require(LifeStory.QuestionGen)
local Strings = require(LifeStory.Strings)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local RoleService = require(script.Parent.RoleService)

local ClassService = {}

local Remote: RemoteEvent
local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local rng = Random.new()

-- Las preguntas escritas a mano (si el archivo falta o tiene un error, se usan las generadas)
local bank: { [string]: { { Q: string, A: { string } } } } = {}
do
	local module = LifeStory:FindFirstChild("QuestionBank")
	if module then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			bank = result
		else
			warn("[ClassService] QuestionBank no se pudo cargar:", result)
		end
	end
end

export type Spec = { Subject: string, Mode: string, ExtraSeconds: number? }
export type Result = { Grade: number, Correct: number, Total: number }

type Session = {
	Spec: Spec,
	Answer: number?,
	Index: number,
	Circuit: { Vector3 }?,
	CircuitDone: number,
}
local sessions: { [Player]: Session } = {}

-- Las asignaturas de estos profesores son de universidad (los da un "ProfesorUniversidad")
local UNIVERSITY_TEACHERS = {
	["NPC.PROFE_MEDICINA"] = true,
	["NPC.PROFE_INGENIERIA"] = true,
	["NPC.PROFE_DERECHO"] = true,
	["NPC.PROFE_ECONOMIA"] = true,
}

local EVENT_FOR_MODE = {
	Clase = "LessonCompleted",
	Circuito = "LessonCompleted",
	Examen = "ExamGraded",
	Estudio = "Studied",
	Practica = "PracticeDone",
}

---------------------------------------------------------------------
-- Preguntas
---------------------------------------------------------------------

local function shuffle<T>(list: { T }): { T }
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = rng:NextInteger(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

-- Devuelve { Q, Options, Right } listas para preguntar (respuestas barajadas)
local function buildQuestions(subject: Subjects.Subject, subjectId: string, count: number)
	local raw = {}
	if subject.Generator and QuestionGen[subject.Generator] then
		for _ = 1, count do
			table.insert(raw, QuestionGen[subject.Generator](rng))
		end
	else
		local pool = shuffle(bank[subjectId] or {})
		if #pool == 0 then
			-- Sin preguntas escritas: se usan de mates para no dejar a nadie sin clase
			for _ = 1, count do
				table.insert(raw, QuestionGen.Aritmetica(rng))
			end
		else
			for i = 1, count do
				table.insert(raw, pool[(i - 1) % #pool + 1])
			end
		end
	end
	local questions = {}
	for _, q in raw do
		local correct = q.A[1]
		local options = shuffle(q.A)
		table.insert(questions, { Q = q.Q, Options = options, Right = table.find(options, correct) :: number })
	end
	return questions
end

---------------------------------------------------------------------
-- Notas
---------------------------------------------------------------------

local function recordGrade(player: Player, spec: Spec, grade: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	local education = data.Education
	education.Attendance += 1
	local entry = education.Subjects[spec.Subject]
	if not entry then
		entry = { Avg = 0, Count = 0, Knowledge = 0, Level = 1, Best = 0 }
		education.Subjects[spec.Subject] = entry
	end
	entry.Avg = math.round((entry.Avg * entry.Count + grade) / (entry.Count + 1) * 10) / 10
	entry.Count += 1
	entry.Knowledge += grade
	entry.Level = math.clamp(1 + math.floor(entry.Knowledge / 25), 1, 5)
	entry.Best = math.max(entry.Best, grade)
	if spec.Mode == "Examen" then
		education.Exams[spec.Subject] = grade
	end
end

local function finish(player: Player, session: Session, correct: number, total: number, teacher: RoleService.Assignment, onDone: (Result) -> ())
	local grade = if total > 0 then math.round(correct / total * 20) / 2 else 5
	sessions[player] = nil
	RoleService.release(teacher)
	if player.Parent then
		Remote:FireClient(player, "End", { Grade = grade, GradeKey = Subjects.gradeKey(grade), Correct = correct, Total = total })
		recordGrade(player, session.Spec, grade)
		StoryEvents.emit(player, EVENT_FOR_MODE[session.Spec.Mode] or "LessonCompleted", {
			Subject = session.Spec.Subject,
			Mode = session.Spec.Mode,
			Grade = grade,
		})
	end
	task.spawn(onDone, { Grade = grade, Correct = correct, Total = total })
end

---------------------------------------------------------------------
-- Clase de preguntas
---------------------------------------------------------------------

local function runQuiz(player: Player, session: Session, subject: Subjects.Subject, teacher: RoleService.Assignment, onDone: (Result) -> ())
	local mode = Subjects.Modes[session.Spec.Mode] or Subjects.Modes.Clase
	local questions = buildQuestions(subject, session.Spec.Subject, mode.Questions)
	local correct = 0
	task.wait(3.5) -- presentación de la clase
	for index, question in questions do
		if not player.Parent then
			break
		end
		session.Index = index
		session.Answer = nil
		Remote:FireClient(player, "Question", {
			Index = index,
			Total = #questions,
			Q = question.Q,
			Options = question.Options,
			Seconds = mode.Seconds + (session.Spec.ExtraSeconds or 0),
		})
		-- Quien ha estudiado tiene unos segundos más por pregunta (Bonus del paso de la misión)
		local deadline = os.clock() + mode.Seconds + (session.Spec.ExtraSeconds or 0) + 1
		while session.Answer == nil and os.clock() < deadline and player.Parent do
			task.wait(0.1)
		end
		local right = session.Answer == question.Right
		if right then
			correct += 1
		end
		Remote:FireClient(player, "Feedback", { Correct = right, Right = question.Right })
		task.wait(1.4)
	end
	finish(player, session, correct, #questions, teacher, onDone)
end

---------------------------------------------------------------------
-- Educación Física: circuito en la pista
---------------------------------------------------------------------

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function circuitPoints(player: Player, count: number): { Vector3 }
	local root = rootOf(player)
	local from = if root then root.Position else Vector3.zero
	-- La pista de deporte más cercana (tag PEArea); si no hay, un circuito alrededor del jugador
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, part in CollectionService:GetTagged("PEArea") do
		if part:IsA("BasePart") then
			local d = (part.Position - from).Magnitude
			if d < bestDistance then
				best, bestDistance = part, d
			end
		end
	end
	local points = {}
	for i = 1, count do
		if best and bestDistance < 400 then
			local half = best.Size / 2 * 0.8
			local local_ = Vector3.new(rng:NextNumber(-half.X, half.X), best.Size.Y / 2 + 2.5, rng:NextNumber(-half.Z, half.Z))
			table.insert(points, best.CFrame:PointToWorldSpace(local_))
		else
			local angle = (i / count) * math.pi * 2
			table.insert(points, from + Vector3.new(math.cos(angle) * 30, 0, math.sin(angle) * 30))
		end
	end
	return points
end

local function runCircuit(player: Player, session: Session, teacher: RoleService.Assignment, onDone: (Result) -> ())
	local mode = Subjects.Modes.Circuito
	local points = circuitPoints(player, mode.Points)
	session.Circuit = points
	session.CircuitDone = 0
	task.wait(3.5)
	Remote:FireClient(player, "Circuit", { Points = points, Seconds = mode.Seconds })
	local started = os.clock()
	while player.Parent and session.CircuitDone < #points and os.clock() - started < mode.Seconds do
		local root = rootOf(player)
		local target = points[session.CircuitDone + 1]
		if root then
			local offset = root.Position - target
			if Vector3.new(offset.X, 0, offset.Z).Magnitude < 7 and math.abs(offset.Y) < 12 then
				session.CircuitDone += 1
				Remote:FireClient(player, "CircuitProgress", { Done = session.CircuitDone, Total = #points })
			end
		end
		task.wait(0.15)
	end
	-- Nota: cuántos puntos y, si los hizo todos, lo rápido que fue
	local left = math.max(0, mode.Seconds - (os.clock() - started))
	local correct = session.CircuitDone
	local total = #points
	if correct == total then
		-- De 7 a 10 según el tiempo que sobró
		local grade10 = 7 + 3 * math.clamp(left / (mode.Seconds * 0.6), 0, 1)
		correct = grade10 / 10 * total
	end
	finish(player, session, correct, total, teacher, onDone)
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------

function ClassService.isRunning(player: Player): boolean
	return sessions[player] ~= nil
end

-- Empieza una sesión. onDone recibe la nota al acabar. Devuelve false si no se pudo.
function ClassService.start(player: Player, spec: Spec, onDone: (Result) -> ()): boolean
	local subject = Subjects.List[spec.Subject]
	if not subject or sessions[player] then
		return false
	end
	local session: Session = { Spec = spec, Index = 0, CircuitDone = 0 }
	sessions[player] = session

	-- ¿Quién da la clase? Un profesor jugador de servicio o, si no hay, el NPC de la asignatura
	local role = if UNIVERSITY_TEACHERS[subject.Teacher] then "ProfesorUniversidad" else "Profesor"
	local teacher = RoleService.assign(role, { Subject = spec.Subject }, player)
	local teacherName = if teacher.Kind == "Player" and teacher.Player then teacher.Player.DisplayName else nil
	if teacher.Kind == "Player" and teacher.Player then
		Notify:FireClient(teacher.Player, "Info", Strings.get("CLASS.TEACHER.STUDENT", { name = player.DisplayName, subject = Strings.get(subject.NameKey) }))
	end

	Remote:FireClient(player, "Start", {
		SubjectKey = subject.NameKey,
		ModeKey = (Subjects.Modes[spec.Mode] or Subjects.Modes.Clase).NameKey,
		TeacherKey = if teacherName then nil else subject.Teacher,
		TeacherName = teacherName,
		Circuit = subject.Circuit == true,
	})
	task.spawn(function()
		local ok, err = pcall(function()
			if subject.Circuit then
				runCircuit(player, session, teacher, onDone)
			else
				runQuiz(player, session, subject, teacher, onDone)
			end
		end)
		if not ok then
			warn("[ClassService] " .. tostring(err))
			if sessions[player] == session then
				sessions[player] = nil
				RoleService.release(teacher)
				task.spawn(onDone, { Grade = 5, Correct = 0, Total = 0 })
			end
		end
	end)
	return true
end

function ClassService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Class") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Class"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player, kind, index, choice)
		local session = sessions[player]
		if kind == "Answer" and session and index == session.Index and session.Answer == nil and type(choice) == "number" then
			session.Answer = math.floor(choice)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return ClassService
