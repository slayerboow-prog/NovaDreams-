-- test-ciudadmallas: los edificios y objetos de calle de Blender de las ciudades de los planetas
-- (World/PlanetCityMeshes + shared/Cosmos/CiudadMalla; los coloca World/PlanetMetroBuilder).
-- lune run scripts/test-ciudadmallas.luau

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local check = L.check
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Instance = roblox.Instance

local Malla = L.load("src/shared/Cosmos/CiudadMalla")
local Ids = L.load("src/shared/Cosmos/CiudadAssetIds")
local Meshes = L.load("src/server/World/PlanetCityMeshes")
local Registry = L.load("src/shared/Cosmos/PlanetRegistry")
local PMB = L.load("src/server/World/PlanetMetroBuilder")

-- Una plantilla de mentira con las medidas del manifiesto (como llegaría de Roblox); flip: girada media vuelta
local function fake(name: string, flip: boolean, scale: number?)
	local info = Malla[name]
	local model = Instance.new("Model")
	local k = scale or 1
	local shift = Vector3.new(500, 80, -300) -- (LoadAsset la deja en cualquier sitio)
	for key, p in info.Parts do
		local part = Instance.new("Part")
		part.Name = name .. "_" .. key
		part.Size = p.S * k
		local c = if flip then Vector3.new(-p.C.X, p.C.Y, -p.C.Z) else p.C
		part.CFrame = CFrame.new(c * k + shift)
		part.Parent = model
	end
	return model
end

print("📦 Manifiesto e ids")
local names = {}
for name, info in Malla do
	table.insert(names, name)
	local okFile = fs.isFile("assets/ciudades/" .. name .. ".fbx")
	check(okFile, name .. ": está su FBX")
	check(info.W > 0 and info.D > 0 and info.Base > 0, name .. ": medidas nominales")
	local tris, secs = info.Tris, {}
	for key in info.Parts do
		secs[string.match(key, "^(%a+)_") or "?"] = true
	end
	check(tris <= 8000, ("%s: ligero (%d triángulos)"):format(name, tris))
	check(secs.Base and (info.Mid == 0 or (secs.Medio and secs.Tope)), name .. ": tiene sus secciones")
end
check(#names >= 19, ("edificios y objetos de calle (%d)"):format(#names))
local uploaded = 0
for _, name in names do
	if Meshes.idOf((Ids.Mallas or {})[name]) then
		uploaded += 1
	end
end
check(uploaded == #names, ("todas subidas a Roblox (%d de %d)"):format(uploaded, #names))

print("📐 Colocar una malla en un solar")
for _, flip in { false, true } do
	local label = if flip then " (llegó girada)" else ""
	local tpl = Meshes.prepare("TefraBloque", fake("TefraBloque", flip))
	check(tpl ~= nil and #tpl.Entries == 11, "plantilla con sus 11 mallas" .. label)
	if not tpl then
		continue
	end
	local parent = Instance.new("Folder")
	local cf = CFrame.new(1000, 50, 2000)
	local seen = {}
	local model, parts = Meshes.place(tpl, parent, cf, 30, 30, 54, function(group, p, sec)
		seen[group] = true
	end)
	-- 54 de alto: base 14 + dos tramos de 16 (20 → 0.8) + tope 8
	local sb, n, sm, st = Meshes.layout(tpl.Info, 54)
	check(sb == 1 and n == 2 and math.abs(sm - 0.8) < 0.01 and st == 1, "54 studs = base + 2 tramos + tope" .. label)
	check(#parts == 3 + 4 * 2 + 4, ("los tramos «Medio» se repiten (%d mallas)"):format(#parts) .. label)
	local door, bodyTop, lo = nil, 0, math.huge
	for _, p in parts do
		if p.Name == "TefraBloque_Base_Luz" then
			door = p
		end
		if string.find(p.Name, "_Cuerpo$") then
			bodyTop = math.max(bodyTop, p.CFrame.Position.Y + p.Size.Y / 2)
		end
		lo = math.min(lo, p.CFrame.Position.Y - p.Size.Y / 2)
	end
	check(door ~= nil and door.CFrame.Position.Z < 2000 - 14 and math.abs(door.CFrame.Position.X - 1000) < 1, "la puerta queda al frente (hacia -Z)" .. label)
	check(math.abs(lo - 50) < 0.3, "apoyado en el suelo del solar" .. label)
	check(bodyTop > 50 + 54 and bodyTop < 50 + 54 + 12, ("la azotea queda a la altura del solar (%.1f)"):format(bodyTop - 50) .. label)
	check(seen.Cuerpo and seen.Luz and seen.Metal and seen.Cristal and seen.Techo, "cada grupo recibe su material" .. label)
	-- más ancho que hondo: se estira en X, no en Z
	local _, wide = Meshes.place(tpl, parent, CFrame.new(0, 0, 0), 45, 30, 34, function() end)
	local wx, wz = 0, 0
	for _, p in wide do
		wx = math.max(wx, math.abs(p.CFrame.Position.X) + p.Size.X / 2)
		wz = math.max(wz, math.abs(p.CFrame.Position.Z) + p.Size.Z / 2)
	end
	check(wx > 24 and wx < 30 and wz > 15 and wz < 21, ("se estira al ancho y fondo del solar (%.1f × %.1f)"):format(wx * 2, wz * 2) .. label)
end
do
	local tpl = Meshes.prepare("SirocoCasa", fake("SirocoCasa", false, 0.01)) -- (importada 100 veces más pequeña)
	check(tpl ~= nil, "plantilla de una malla importada a otra escala")
	if tpl then
		local _, parts = Meshes.place(tpl, Instance.new("Folder"), CFrame.new(0, 0, 0), 26, 26, 20, function() end)
		local top = 0
		for _, p in parts do
			top = math.max(top, p.CFrame.Position.Y + p.Size.Y / 2)
		end
		check(top > 25 and top < 40, ("la escala se corrige (%.1f studs de alto)"):format(top))
	end
	local a, b, c, e = Meshes.layout(Malla.VerticeTorre, 420)
	check(a == 1 and b == 4 and c > 3 and e == 1, "un rascacielos: 4 tramos estirados, no cien mallas")
	local s0, n0 = Meshes.layout(Malla.TefraBloque, 14)
	check(n0 == 0 and s0 < 1, "un edificio bajo: sin tramo «Medio»")
end

print("🏙 En la ciudad (con plantillas de mentira)")
for _, id in { "Vertice", "Siroco", "Talasa", "Umbria" } do
	local S = Registry.get(id)
	local templates = {}
	for name in Malla do
		templates[name] = Meshes.prepare(name, fake(name, false))
	end
	local folder = Instance.new("Folder")
	local ok, model, stats = pcall(PMB.build, folder, S, { Meshes = templates })
	check(ok and model ~= nil, id .. ": la ciudad se construye con mallas " .. (if ok then "" else tostring(model)))
	if ok then
		if id == "Umbria" then
			check(stats.MeshBuildings == 0 and stats.Props > 10, ("%s: sin edificios de malla, con objetos de calle (%d)"):format(id, stats.Props))
		else
			check(stats.MeshBuildings > 100, ("%s: edificios de malla (%d)"):format(id, stats.MeshBuildings))
			check(stats.Props > 40, ("%s: objetos de calle (%d)"):format(id, stats.Props))
		end
		check(stats.Meshes < 9000, ("%s: mallas contenidas (%d)"):format(id, stats.Meshes))
		-- un edificio de malla conserva su choque (cuerpo invisible) y ya no tiene las franjas de piezas
		local found, collider, leftovers = false, false, false
		for _, d in model:GetDescendants() do
			if d.ClassName == "Model" and string.sub(d.Name, 1, 6) == "Malla_" and not found then
				found = true
				for _, ch in (d.Parent :: any):GetChildren() do
					if ch:IsA("BasePart") then
						if ch.Name == "Cuerpo" or ch.Name == "Zocalo" then
							collider = collider or ch.Transparency == 1
						elseif ch.Name == "Ventanas" or ch.Name == "Franja" or ch.Name == "Puerta" then
							leftovers = true
						end
					end
				end
			end
		end
		if id ~= "Umbria" then
			check(found and collider and not leftovers, id .. ": el cuerpo de piezas queda invisible para chocar y lo demás se quita")
		end
	end
end
do
	local S = Registry.get("Tefra")
	local ok, _, stats = pcall(PMB.build, Instance.new("Folder"), S, { Meshes = false })
	check(ok and stats.MeshBuildings == 0 and stats.Buildings > 100, "sin mallas, la ciudad de piezas sigue igual")
end

L.finish("test-ciudadmallas")
