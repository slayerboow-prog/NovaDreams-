local task = require("@lune/task")
local H = require("./lib/StoryHarness")
local Service = H.boot()
local p = H.newPlayer("Dueño", "Nino", 100)
H.Config.Testers = { p.UserId }
local data = H.profiles[p]
local story = data.Story
task.wait(1)
print("chapter", story.Chapter, "stage", data.Life.Stage, "age", data.Life.AgeYears)
for _, q in { "Cole01_PrimerDia", "Cole02_Mochila", "Cole03_Grupo", "Cole04_Malotes", "Cole05_Venganza", "Cole06_Examen" } do
	story.Completed[q] = os.time()
	story.Active[q] = nil
end
for id, prog in story.Active do print("active before", id, prog.Kind) end
story.Active.Nino_Recados = { Kind = "Main" }
Service.resetQuest(p, "Nino_Recados")
story.Active.Loco_N1_Cosme = { Kind = "Side" }
Service.resetQuest(p, "Loco_N1_Cosme")
story.Tracked = "Loco_N1_Cosme"
task.wait(0.5)
for id, prog in story.Active do print("active", id, prog.Kind, prog.Step) end
print("InDialogue", p:GetAttribute("InDialogue"))
local Tester = H.loadModule(H.ROOT .. "/server/Services/TesterService")
print("isTester", Tester.isTester(p))
local ok = Tester.handle(p, "Action", "Stage", "Adulto")
print("handle ->", ok)
task.wait(1)
print("chapter", story.Chapter, "stage", data.Life.Stage, "age", data.Life.AgeYears, p:GetAttribute("LifeStage"), p:GetAttribute("AgeYears"))
for id, prog in story.Active do print("active after", id, prog.Kind) end
print("tracked", story.Tracked)
task.wait(3)
print("later: stage", data.Life.Stage, p:GetAttribute("LifeStage"), story.Chapter)
for id, prog in story.Active do print("active later", id, prog.Kind) end
local saved = H.leave(p)
local p2 = H.rejoin(p, saved)
task.wait(1)
print("rejoin: stage", H.profiles[p2].Life.Stage, p2:GetAttribute("LifeStage"), H.profiles[p2].Life.AgeYears, H.profiles[p2].Story.Chapter)
for id, prog in H.profiles[p2].Story.Active do print("active rejoin", id, prog.Kind) end
local process = require("@lune/process")
process.exit(0)
