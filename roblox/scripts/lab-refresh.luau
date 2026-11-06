--!nocheck
-- Laboratorio de cine: pone el código de ahora en LaboratorioCine.rbxl sin volver a construir la ciudad
-- (scripts/build-lab.luau tarda ~7 min; esto, segundos). Solo los scripts: el mapa no se toca.
--
--   rojo build default.project.json -o <codigo.rbxl>      (el código, sin ciudad: segundos)
--   lune run scripts/lab-refresh.luau <codigo.rbxl> [LaboratorioCine.rbxl]
--
-- Copia, por su ruta, el Source de cada Script/LocalScript/ModuleScript de codigo.rbxl al laboratorio;
-- los que no existían se añaden (con su carpeta) y los que ya no están en el código se quitan.
-- Con Studio abierto con el laboratorio, ciérralo antes (Studio no recarga el archivo solo).

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local codePath = assert(process.args[1], "Uso: lune run scripts/lab-refresh.luau <codigo.rbxl> [LaboratorioCine.rbxl]")
local labPath = process.args[2] or "LaboratorioCine.rbxl"

local code = roblox.deserializePlace(fs.readFile(codePath))
local lab = roblox.deserializePlace(fs.readFile(labPath))

local ROOTS = { "ReplicatedStorage", "ServerScriptService", "StarterPlayer", "StarterGui", "ReplicatedFirst" }
local function isScript(i): boolean
	return i:IsA("LuaSourceContainer")
end

local function pathOf(i, root): string
	local parts = {}
	local cur = i
	while cur and cur ~= root do
		table.insert(parts, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(parts, "/")
end

local changed, added, removed = 0, 0, 0
for _, rootName in ROOTS do
	local from = code:FindFirstChild(rootName)
	local to = lab:FindFirstChild(rootName)
	if from and to then
		local wanted = {}
		for _, s in from:GetDescendants() do
			if isScript(s) then
				wanted[pathOf(s, from)] = s
			end
		end
		local have = {}
		for _, s in to:GetDescendants() do
			if isScript(s) then
				have[pathOf(s, to)] = s
			end
		end
		-- (de arriba abajo: un módulo nuevo antes que los suyos de dentro)
		local order = {}
		for path in wanted do
			table.insert(order, path)
		end
		table.sort(order, function(a, b)
			return #a < #b
		end)
		for _, path in order do
			local s = wanted[path]
			local old = have[path]
			if old and old.ClassName == s.ClassName then
				if old.Source ~= s.Source then
					old.Source = s.Source
					changed += 1
				end
			else
				-- (nuevo: se copia con su carpeta de arriba si hace falta)
				local parentPath = path:match("^(.*)/[^/]+$")
				local parent = to
				if parentPath then
					for name in parentPath:gmatch("[^/]+") do
						local nextOne = parent:FindFirstChild(name)
						if not nextOne then
							nextOne = roblox.Instance.new("Folder")
							nextOne.Name = name
							nextOne.Parent = parent
						end
						parent = nextOne
					end
				end
				if old then
					old:Destroy()
				end
				local copy = s:Clone()
				for _, child in copy:GetChildren() do
					child:Destroy()
				end
				copy.Parent = parent
				added += 1
			end
		end
		for path, s in have do
			if not wanted[path] and s.Parent then
				s:Destroy()
				removed += 1
			end
		end
	end
end

fs.writeFile(labPath, roblox.serializePlace(lab))
print(("Laboratorio al día: %d scripts cambiados, %d nuevos, %d quitados (%s)"):format(changed, added, removed, labPath))
