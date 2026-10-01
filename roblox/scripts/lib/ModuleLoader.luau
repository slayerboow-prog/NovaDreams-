-- ModuleLoader: carga módulos de src/ fuera de Roblox (Lune) con un entorno parecido al de Roblox:
-- script.Parent.X, require(), Instance/Vector3/CFrame/Color3/Enum/NumberSequence… de @lune/roblox,
-- Random, task, typeof, workspace y un game:GetService con dobles que se pueden cambiar.
-- Lo usan test-scenes, test-vfx y test-worldmemory.
--
--   local L = require("./lib/ModuleLoader")
--   L.services.Players = {...}          -- dobles de servicios (antes de cargar)
--   L.mock("src/server/Services/DataService", tabla)
--   local M = L.load("src/shared/LifeStory/Sequencer")

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local L = {}

-- Random de Roblox (Lune no lo trae): misma interfaz, resultados repetibles
local TestRandom = {}
TestRandom.__index = TestRandom
function TestRandom.new(seed: number?)
	return setmetatable({ s = math.floor(seed or 12345) % 2147483648 }, TestRandom)
end
function TestRandom:NextNumber(a: number?, b: number?)
	self.s = (self.s * 1103515245 + 12345) % 2147483648
	local x = self.s / 2147483648
	if a and b then
		return a + x * (b - a)
	end
	return x
end
function TestRandom:NextInteger(a: number, b: number)
	return a + math.floor(self:NextNumber() * (b - a + 1))
end
L.Random = TestRandom

-- CFrame.lookAt de Roblox (el de Lune da la vuelta al mirar hacia -Z)
local function lookAt(at: any, target: any, up: any?): any
	local look = target - at
	if look.Magnitude < 1e-6 then
		return roblox.CFrame.new(at)
	end
	look = look.Unit
	local right = look:Cross(up or roblox.Vector3.yAxis)
	if right.Magnitude < 1e-6 then
		right = look:Cross(roblox.Vector3.zAxis)
	end
	right = right.Unit
	return roblox.CFrame.fromMatrix(at, right, right:Cross(look).Unit, -look)
end
L.CFrame = setmetatable({ lookAt = lookAt }, { __index = roblox.CFrame })

local mocks: { [string]: any } = {}
local cache: { [string]: any } = {}

local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end

-- Dobles de servicios: L.services[nombre] = tabla
L.services = {
	ReplicatedStorage = { Shared = node("src/shared") },
	HttpService = {
		JSONEncode = function(_, value)
			return serde.encode("json", value)
		end,
		JSONDecode = function(_, text)
			return serde.decode("json", text)
		end,
	},
	RunService = {
		IsStudio = function()
			return false
		end,
	},
	CollectionService = {
		AddTag = function() end,
		GetTagged = function()
			return {}
		end,
	},
}
L.services.ReplicatedStorage.FindFirstChild = function(self, name)
	return rawget(self, name)
end
L.services.ReplicatedStorage.WaitForChild = function(self, name)
	return rawget(self, name)
end

L.game = { CreatorId = 1, JobId = "prueba" }
function L.game:GetService(name)
	local s = L.services[name]
	if s == nil then
		error("Servicio sin doble: " .. name)
	end
	return s
end
L.workspace = roblox.Instance.new("Folder")

local warnings: { string } = {}
L.warnings = warnings

local function env(path: string)
	return setmetatable({
		script = node(path),
		require = function(target)
			return L.load(rawget(target, "__path"))
		end,
		game = L.game,
		workspace = L.workspace,
		task = task,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		CFrame = L.CFrame,
		UDim2 = roblox.UDim2,
		UDim = roblox.UDim,
		Enum = roblox.Enum,
		Instance = roblox.Instance,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		Random = TestRandom,
		typeof = roblox.typeof or typeof,
		warn = function(...)
			local parts = {}
			for i = 1, select("#", ...) do
				table.insert(parts, tostring((select(i, ...))))
			end
			table.insert(warnings, table.concat(parts, " "))
		end,
	}, { __index = _G })
end

function L.mock(path: string, value: any)
	mocks[path] = value
	cache[path] = nil
end

function L.load(path: string): any
	if mocks[path] ~= nil then
		return mocks[path]
	end
	if cache[path] ~= nil then
		return cache[path]
	end
	local file = path .. ".luau"
	if not fs.isFile(file) then
		error("Módulo no encontrado: " .. path)
	end
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = env(path) })
	local result = chunk()
	cache[path] = result
	return result
end

function L.reset(path: string?)
	if path then
		cache[path] = nil
	else
		table.clear(cache)
	end
end

-- Comprobaciones con ✅ / ❌
L.failures = 0
function L.check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		L.failures += 1
		print("  ❌ " .. what)
	end
end

function L.finish(name: string)
	local process = require("@lune/process")
	print("")
	if L.failures > 0 then
		print(("❌ %s: %d comprobaciones fallan"):format(name, L.failures))
		process.exit(1)
	end
	print(("✅ %s: todo correcto"):format(name))
end

-- Un jugador de mentira (atributos, Parent, Character opcional)
function L.player(name: string, userId: number)
	local p = { Name = name, DisplayName = name, UserId = userId, Parent = true, Attributes = {}, Character = nil }
	function p:SetAttribute(key, value)
		self.Attributes[key] = value
	end
	function p:GetAttribute(key)
		return self.Attributes[key]
	end
	function p:RequestStreamAroundAsync() end
	return p
end

return L
