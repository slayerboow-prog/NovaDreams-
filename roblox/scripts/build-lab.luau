--!nocheck
-- Laboratorio de cine: un archivo LIGERO del juego para revisar escenas en un PC modesto
-- (shared/Laboratorio explica el porqué).
--
--   lune run scripts/build-lab.luau [RealLifeSimulator.rbxl] [LaboratorioCine.rbxl]
--
-- Parte del archivo de siempre YA construido (rojo build + scripts/build-place.luau) y:
--   * de la ciudad (Workspace.Town) se queda solo con lo que está cerca de donde pasa la historia
--     (Zonas, abajo): Los Pinos —casa familiar, colegio, parque y casa de Cosme—, el campus y la plaza;
--   * marca workspace con el atributo «LaboratorioCine»: Main (servidor y cliente) se salta lo pesado.
-- El archivo de siempre no se toca. LaboratorioCine.rbxl no se publica nunca (va en .gitignore).

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local input = process.args[1] or "RealLifeSimulator.rbxl"
local output = process.args[2] or "LaboratorioCine.rbxl"

-- Círculos (X, Z, radio en studs) de la ciudad que se quedan. Medidos en el archivo construido:
-- casas familiares de Los Pinos (513..886, -2204), su colegio (580, -1930), su parque (820, -2020) y la
-- casa de Cosme (350..431, -2176..-2246); el campus (Facultad, Estadio, Biblioteca, colegio y parque de
-- al lado: 2490..2960, 1031..1660); la plaza del centro (-60, -32).
local Zonas = {
	{ Name = "Los Pinos", X = 650, Z = -2100, R = 600 },
	{ Name = "Campus", X = 2720, Z = 1350, R = 450 },
	{ Name = "Plaza", X = -60, Z = -32, R = 250 },
}

local function inside(cf: any, size: any): boolean
	local p = cf.Position
	-- (una pieza larga, como una calle o el suelo, se queda si cualquier trozo suyo entra)
	local reach = math.max(size.X, size.Z) * 0.5
	for _, z in Zonas do
		local dx, dz = p.X - z.X, p.Z - z.Z
		if math.sqrt(dx * dx + dz * dz) - reach <= z.R then
			return true
		end
	end
	return false
end

local started = os.clock()
local game = roblox.deserializePlace(fs.readFile(input))
local workspace = game:GetService("Workspace")
local town = workspace:FindFirstChild("Town")
assert(town, "El archivo no trae la ciudad (Workspace.Town): constrúyelo antes con scripts/build-place.luau")

local before = #town:GetDescendants()
local removed = 0
for _, item in town:GetDescendants() do
	if item:IsA("BasePart") and item.Parent then
		local ok, keep = pcall(function()
			return inside(item.CFrame, item.Size)
		end)
		if ok and not keep then
			item:Destroy()
			removed += 1
		end
	end
end

-- Modelos y carpetas que se han quedado vacíos (de dentro hacia fuera)
local emptied = 0
local changed = true
while changed do
	changed = false
	for _, item in town:GetDescendants() do
		if (item:IsA("Model") or item:IsA("Folder")) and #item:GetChildren() == 0 then
			item:Destroy()
			emptied += 1
			changed = true
		end
	end
end

workspace:SetAttribute("LaboratorioCine", true)
local after = #town:GetDescendants()
fs.writeFile(output, roblox.serializePlace(game))
print(("Laboratorio de cine en %s: ciudad de %d a %d objetos (%d piezas fuera, %d grupos vacíos) en %.0f s"):format(output, before, after, removed, emptied, os.clock() - started))
for _, z in Zonas do
	print(("  se queda: %s (%d, %d) radio %d"):format(z.Name, z.X, z.Z, z.R))
end
