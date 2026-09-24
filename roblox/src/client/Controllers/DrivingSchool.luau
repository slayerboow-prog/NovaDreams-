-- DrivingSchool: ventanas de la autoescuela (elegir carnet y examen teórico).
-- El examen práctico se ve con la línea guía azul y el aviso amarillo bajo el reloj.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Dialog = require(script.Parent.Parent.UI.Dialog)

local DrivingSchool = {}

local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DrivingSchool") :: RemoteEvent

local function menu(token: string, licenses: { any })
	local options, keys = {}, {}
	for _, license in licenses do
		if license.Owned then
			table.insert(options, "✅ " .. license.Name .. " (ya lo tienes)")
			table.insert(keys, false)
		else
			table.insert(options, ("%s · matrícula %s"):format(license.Name, Format.money(license.Price)))
			table.insert(keys, license.Key)
		end
	end
	local choice = Dialog.choose("🚦 Autoescuela", "Primero un examen teórico (5 preguntas) y después el práctico por las calles del pueblo.", options)
	local key = choice and keys[choice]
	Remote:FireServer("Choose", token, if key then key else nil)
end

local function theory(token: string, exam: { [string]: any })
	local answers = {}
	for i, question in exam.Questions do
		local choice = Dialog.choose(("📝 %s · pregunta %d de %d"):format(exam.License, i, #exam.Questions), question.Text, question.Options)
		answers[i] = choice or 0
	end
	Remote:FireServer("Answers", token, answers)
end

function DrivingSchool.init()
	Remote.OnClientEvent:Connect(function(action, token, payload)
		if action == "Menu" then
			menu(token, payload)
		elseif action == "Theory" then
			theory(token, payload)
		end
	end)
end

return DrivingSchool
