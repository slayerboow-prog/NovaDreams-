-- assets-usuario-4: cuarta tanda de 63 modelos elegidos por Sebastián (palmeras, casas, coches, trenes, cielos…)
--
-- Como assets-usuario-3.luau: los carga con AssetService:LoadAssetAsync y los vuelca por la consola
-- (usa -v; el registro completo queda en ${TMPDIR:-/tmp}/cloud-test/assets-usuario-4.log).
-- Resultado escrito a mano en docs/assets-usuario-4.md.
-- Además de lo de la 2ª tanda: por cada objeto, los nombres de sus piezas y cuántas parecen carrocería,
-- ruedas, cristales, asientos o motor (coches y barcos); Sky, Atmosphere y efectos de Lighting con sus
-- propiedades; luces, partículas y Tools. Los scripts repetidos (mismo Source) se enseñan una sola vez,
-- pero en todos se buscan las palabras peligrosas.
-- Nuevo en la 4ª tanda: de cada Sound y Animation se pide GetProductInfo (creador y si es público); se
-- enseñan los atributos de cualquier objeto (el virus de la 3ª tanda esconde código en uno) y el Value de
-- los NumberPose (otro virus esconde ahí el número de un require); se baja al nivel 3 (vehículos dentro de
-- dos carpetas) y los scripts con algo grave se enseñan enteros.
-- (Los triángulos por malla no se pueden contar: EditableMesh da «no permission» con mallas de otros.)
-- Son 63 assets: se hace en varias ejecuciones cambiando IDS. El autobús 18912826861 hace fallar la
-- tarea (error interno de Roblox) con este volcado: se miró aparte con uno mínimo.
--
-- Uso: bash scripts/cloud-test.sh -v assets-usuario-4

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)
local AssetService = game:GetService("AssetService")

local IDS = { -- @@IDS@@
	14887624955, 115493232746766, 2161748423, 130967743753364, 11877329379, 13583409363, 16845477360,
	120631576642977, 113349334619202, 122782784244668, 139484418601989, 95946642626421, 102765136165948,
	83730474928094, 113036863157630, 78033796632460, 8380605189, 8386763665, 10887600145, 18577576400,
	18912826861, 18777387875, 116641210728889, 107730003845316, 106442157390222, 135266547724797,
	111283915226740, 17536656565, 13843689263, 8294099223, 79665094662717, 123778443128832, 82136423205151,
	95413639317338, 133967929770771, 92375378852064, 114397068371248, 72475149726020, 109211499509239,
	126164979250031, 8649374407, 14062245022, 131772048424194, 8043394685, 9658188636, 11188629897, 12110426279,
	13188926423, 14800241387, 82460675146164, 131247677717086, 78188971759943, 114120925733217, 99043731526992,
	93376997873263, 124865259344404, 130817699186912, 124581242124664, 130974691456028, 4573650411, 10897563593,
	10935800149, 97902046131324,
}
local MAX_FILAS = 200 -- filas como mucho por lista y asset
-- Packs enormes (la consola de la API solo guarda las ~5 000 últimas líneas): sin lista de mallas y con
-- el principio de cada script más corto
local CORTO = {
	[115493232746766] = true, [18577576400] = true, [4573650411] = true, [10897563593] = true,
	[10935800149] = true, [8380605189] = true,
}
local MarketplaceService = game:GetService("MarketplaceService")
local INFO_MAX = 40 -- GetProductInfo como mucho por asset (sonidos y animaciones)
-- Palabras que, si salen, hay que enseñar siempre (aunque el script esté repetido)
local GRAVE = {
	["require(NÚMERO) ⛔"] = true, getfenv = true, setfenv = true, loadstring = true, HttpService = true,
	MarketplaceService = true, TeleportService = true, InsertService = true, LoadAsset = true,
	["string.char"] = true, ["string.reverse"] = true, ["\\x"] = true, Kick = true,
}
-- Palabras que en un script de la comunidad pueden ser una puerta trasera o algo raro
local PELIGRO = {
	"require(", "getfenv", "setfenv", "loadstring", "HttpService", "MarketplaceService", "TeleportService",
	"InsertService", "LoadAsset", "string.reverse", "string.char", "\\x", "Kick", "Destroy()", "ChildAdded",
	"PlayerAdded", "RemoteEvent", "FireServer", "FireClient",
}

local function r1(n: number): string
	return ("%.1f"):format(n)
end

local function talla(v: Vector3): string
	return r1(v.X) .. "x" .. r1(v.Y) .. "x" .. r1(v.Z)
end

local function lee(inst: Instance, prop: string): string
	local ok, v = pcall(function()
		return (inst :: any)[prop]
	end)
	if not ok then
		return "¿?"
	end
	return tostring(v)
end

local function tallaDe(inst: Instance): string
	if inst:IsA("BasePart") then
		return talla(inst.Size)
	elseif inst:IsA("Model") then
		local ok, s = pcall(inst.GetExtentsSize, inst)
		if ok then
			return talla(s)
		end
	end
	return "-"
end

-- Cuenta lo que hay debajo (y el propio nodo)
local function cuenta(inst: Instance): string
	local c = { part = 0, mesh = 0, sa = 0, tex = 0, decal = 0, sound = 0, script = 0, mv = 0 }
	local lista = inst:GetDescendants()
	table.insert(lista, inst)
	for _, d in lista do
		if d:IsA("BasePart") then
			c.part += 1
		end
		if d:IsA("MeshPart") then
			c.mesh += 1
		elseif d:IsA("SurfaceAppearance") then
			c.sa += 1
		elseif d:IsA("Texture") then
			c.tex += 1
		elseif d:IsA("Decal") then
			c.decal += 1
		elseif d:IsA("Sound") then
			c.sound += 1
		elseif d:IsA("LuaSourceContainer") then
			c.script += 1
		elseif d:IsA("MaterialVariant") then
			c.mv += 1
		end
	end
	return ("piezas=%d MeshPart=%d SA=%d Texture=%d Decal=%d Sound=%d scripts=%d MV=%d"):format(
		c.part, c.mesh, c.sa, c.tex, c.decal, c.sound, c.script, c.mv)
end

-- Qué parece cada pieza (por nombre, clase, material y transparencia): para coches y barcos
local function rol(d: BasePart): string?
	local n = d.Name:lower()
	if d:IsA("VehicleSeat") or d:IsA("Seat") or n:find("seat") or n:find("asiento") then
		return "asiento"
	elseif n:find("wheel") or n:find("tire") or n:find("tyre") or n:find("rim") or n:find("rueda") then
		return "rueda"
	elseif d.Material == Enum.Material.Glass or n:find("glass") or n:find("window") or n:find("windshield")
		or (d.Transparency > 0.05 and d.Transparency < 0.95) then
		return "cristal"
	elseif n:find("engine") or n:find("motor") or n:find("propel") then
		return "motor"
	elseif n:find("body") or n:find("chassis") or n:find("hull") or n:find("casco") or n:find("door")
		or n:find("hood") or n:find("bumper") or n:find("trunk") or n:find("fender") then
		return "carroceria"
	elseif n:find("light") or n:find("lamp") then
		return "luz"
	end
	return nil
end

-- Nombres de las piezas de un objeto (los más repetidos primero) y cuántas tiene de cada rol
local function nombres(inst: Instance): string
	local nom, roles, orden = {}, {}, {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			if not nom[d.Name] then
				nom[d.Name] = 0
				table.insert(orden, d.Name)
			end
			nom[d.Name] += 1
			local r = rol(d)
			if r then
				roles[r] = (roles[r] or 0) + 1
			end
		end
	end
	table.sort(orden, function(a, b)
		return nom[a] > nom[b]
	end)
	local b = {}
	for i, k in orden do
		if i > 25 then
			table.insert(b, ("… +%d nombres"):format(#orden - 25))
			break
		end
		table.insert(b, if nom[k] > 1 then k .. "×" .. nom[k] else k)
	end
	local r = {}
	for k, v in roles do
		table.insert(r, k .. "=" .. v)
	end
	table.sort(r)
	return "ROLES " .. table.concat(r, ",") .. " | NOMBRES " .. table.concat(b, ", ")
end

-- Creador y si es público un Sound o una Animation (GetProductInfo)
local infoVista: { [string]: string } = {}
local infoN = 0
local function info(id: string): string
	local n = tonumber(id:match("%d+"))
	if not n then
		return "(sin id)"
	end
	local k = tostring(n)
	if infoVista[k] then
		return infoVista[k]
	end
	infoN += 1
	if infoN > INFO_MAX then
		return "(no se pregunta: demasiados)"
	end
	local ok, p = pcall(MarketplaceService.GetProductInfo, MarketplaceService, n)
	local r
	if ok and p then
		local c = p.Creator or {}
		r = ("«%s» de %s (%s) público=%s"):format(tostring(p.Name), tostring(c.Name), tostring(c.CreatorType),
			tostring(p.IsPublicDomain))
	else
		r = "GetProductInfo falla: " .. tostring(p)
	end
	infoVista[k] = r
	return r
end


local idActual = 0 -- asset que se está volcando
local VISTOS: { [string]: string } = {} -- Source ya enseñado -> primer script que lo tenía

-- Propiedades de Sky, Atmosphere, efectos de Lighting, luces y partículas
local PROPS = {
	Sky = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SunTextureId", "MoonTextureId",
		"SunAngularSize", "MoonAngularSize", "StarCount", "CelestialBodiesShown", "SkyboxOrientation" },
	Atmosphere = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" },
	BloomEffect = { "Enabled", "Intensity", "Size", "Threshold" },
	ColorCorrectionEffect = { "Enabled", "Brightness", "Contrast", "Saturation", "TintColor" },
	SunRaysEffect = { "Enabled", "Intensity", "Spread" },
	DepthOfFieldEffect = { "Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity" },
	BlurEffect = { "Enabled", "Size" },
	Clouds = { "Cover", "Density", "Color" },
	PointLight = { "Brightness", "Range", "Color", "Shadows" },
	SpotLight = { "Brightness", "Range", "Angle", "Color", "Shadows" },
	SurfaceLight = { "Brightness", "Range", "Angle", "Color", "Shadows" },
	ParticleEmitter = { "Texture", "Rate", "Lifetime", "Enabled" },
	Beam = { "Texture", "Enabled" },
	Fire = { "Size", "Heat" },
	Smoke = { "Size", "Opacity" },
	Tool = { "ToolTip", "RequiresHandle" },
	NumberPose = { "Value" },
	Configuration = {},
	StringValue = { "Value" },
}

local function fila(inst: Instance, nivel: number)
	print(("N%d %s [%s] talla=%s %s"):format(nivel, inst:GetFullName(), inst.ClassName, tallaDe(inst), cuenta(inst)))
	if inst:IsA("Model") then
		print("   " .. nombres(inst))
	end
end

local function vuelca(raiz: Instance)
	local clases = {}
	for _, d in raiz:GetDescendants() do
		clases[d.ClassName] = (clases[d.ClassName] or 0) + 1
	end
	local b = {}
	for k, n in clases do
		table.insert(b, k .. "=" .. n)
	end
	table.sort(b)
	print("CLASES " .. table.concat(b, ","))
	print("TOTAL " .. cuenta(raiz))

	-- Nivel 1 y 2
	local n = 0
	for _, h in raiz:GetChildren() do
		n += 1
		if n > MAX_FILAS then
			print("… más hijos de nivel 1")
			break
		end
		fila(h, 1)
		local m = 0
		for _, g in h:GetChildren() do
			if g:IsA("Model") or g:IsA("Folder") or g:IsA("BasePart") then
				m += 1
				if m > 300 then
					print("   … más hijos de nivel 2 en " .. h.Name)
					break
				end
				fila(g, 2)
				-- Nivel 3 (solo Model: p. ej. los vehículos de un pack metido en dos carpetas)
				local k = 0
				for _, h3 in g:GetChildren() do
					if h3:IsA("Model") and k < 60 then
						k += 1
						fila(h3, 3)
					end
				end
			end
		end
	end

	-- Listas por tipo
	local visAgr, visOrden, otroAgr, otroOrden, palabras = {}, {}, {}, {}, {}
	local mostrados = { obj = 0, mv = 0, sa = 0, vis = 0, sound = 0, rojo = 0, mesh = 0, scr = 0, rep = 0, fx = 0 }
	for _, d in raiz:GetDescendants() do
		if d:IsA("MaterialVariant") then
			print(("MV %s BaseMaterial=%s StudsPerTile=%s MaterialPattern=%s"):format(
				d:GetFullName(), lee(d, "BaseMaterial"), lee(d, "StudsPerTile"), lee(d, "MaterialPattern")))
		elseif d:IsA("SurfaceAppearance") then
			mostrados.sa += 1
			if mostrados.sa <= 30 then
				print(("VIS %s [SurfaceAppearance]"):format(d:GetFullName()))
			end
		elseif PROPS[d.ClassName] then
			mostrados.fx += 1
			if mostrados.fx <= 120 then
				local b = {}
				for _, pr in PROPS[d.ClassName] do
					table.insert(b, pr .. "=" .. lee(d, pr))
				end
				print(("FX %s [%s] %s"):format(d:GetFullName(), d.ClassName, table.concat(b, " ")))
			end
		elseif d:IsA("Decal") then -- (Texture hereda de Decal)
			mostrados.vis += 1
			-- (los Decal iguales —mismo nombre e imagen— se cuentan juntos y se enseñan al final)
			local k = ("%s [%s] Texture=%s"):format(d.Name, d.ClassName, lee(d, "Texture"))
			if not visAgr[k] then
				visAgr[k] = { n = 0, donde = d:GetFullName() }
				table.insert(visOrden, k)
			end
			visAgr[k].n += 1
		elseif d:IsA("TextLabel") or d:IsA("Accessory") then
			local k = ("%s [%s] %s"):format(d.Name, d.ClassName, if d:IsA("TextLabel") then "Text=" .. lee(d, "Text") else "")
			otroAgr[k] = (otroAgr[k] or 0) + 1
			if otroAgr[k] == 1 then
				table.insert(otroOrden, k)
			end
		elseif d:IsA("SpecialMesh") then
			print(("SPECIALMESH %s MeshId=%s TextureId=%s Scale=%s"):format(d:GetFullName(), lee(d, "MeshId"), lee(d, "TextureId"), lee(d, "Scale")))
		elseif d:IsA("Animation") then
			print(("ANIM %s AnimationId=%s → %s"):format(d:GetFullName(), lee(d, "AnimationId"), info(lee(d, "AnimationId"))))
		elseif d:IsA("Sound") then
			mostrados.sound += 1
			if mostrados.sound <= 40 then
				print(("SONIDO %s SoundId=%s Playing=%s Looped=%s → %s"):format(d:GetFullName(), lee(d, "SoundId"), lee(d, "Playing"),
					lee(d, "Looped"), info(lee(d, "SoundId"))))
			end
		elseif d:IsA("LuaSourceContainer") then
			local ok, src = pcall(function()
				return (d :: any).Source
			end)
			local texto = if ok then tostring(src) else ""
			local hay = {}
			for _, pal in PELIGRO do
				if texto:find(pal, 1, true) then
					table.insert(hay, pal)
				end
			end
			if texto:find("require%(%s*%d") then
				table.insert(hay, "require(NÚMERO) ⛔")
			end
			local clave = d.ClassName .. "|" .. texto
			local antes = VISTOS[clave]
			mostrados.scr += 1
			if antes then
				mostrados.rep += 1
				if mostrados.rep <= 60 then
					print(("⚠ SCRIPT %s [%s] = igual que %s"):format(d:GetFullName(), d.ClassName, antes))
				end
			else
				VISTOS[clave] = d:GetFullName()
				print(("⚠ SCRIPT %s [%s] Enabled=%s %s"):format(d:GetFullName(), d.ClassName, lee(d, "Enabled"),
					if ok then ("(%d caracteres)"):format(#texto) else "Source NO legible"))
				if ok then
					-- Si hay algo grave (o un require en un pack normal), se enseña entero (hasta 20 000)
					local entero = false
					for _, pal in hay do
						entero = entero or GRAVE[pal] == true or (pal == "require(" and not CORTO[idActual])
					end
					print("SOURCE >>>\n" .. texto:sub(1, if entero then 20000 elseif CORTO[idActual] then 300 else 1200) .. "\n<<<")
				end
			end
			local grave = false
			for _, pal in hay do
				palabras[pal] = (palabras[pal] or 0) + 1
				grave = grave or GRAVE[pal] == true
			end
			if not antes or grave then
				print("PELIGRO " .. d:GetFullName() .. ": " .. (if #hay > 0 then table.concat(hay, ", ") else "nada"))
			end
		elseif d:IsA("BasePart") then
			local c = d.Color
			local nombre = d.Name:lower()
			if (c.R > 0.45 and c.G < 0.2 and c.B < 0.2) or nombre:find("blood") or nombre:find("кров") or nombre:find("gore") then
				mostrados.rojo += 1
				if mostrados.rojo <= 40 then
					print(("ROJO %s [%s] talla=%s color=%d,%d,%d mat=%s"):format(d:GetFullName(), d.ClassName, talla(d.Size),
						math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255), d.Material.Name))
				end
			end
			if d:IsA("MeshPart") then
				mostrados.mesh += 1
				if mostrados.mesh <= MAX_FILAS and not CORTO[idActual] then
					local id = lee(d, "MeshId")
					print(("MALLA %s talla=%s MeshId=%s TextureID=%s mat=%s transp=%s"):format(d:GetFullName(), talla(d.Size), id,
						lee(d, "TextureID"), d.Material.Name, r1(d.Transparency)))
				end
			end
		end
		local okA, atr = pcall(d.GetAttributes, d)
		if okA and next(atr) then
			local b = {}
			for k, v in atr do
				table.insert(b, k .. "=" .. tostring(v):sub(1, 400))
			end
			print(("ATRIB %s [%s] %s"):format(d:GetFullName(), d.ClassName, table.concat(b, " | ")))
		end
		-- Objetos sueltos: Model o pieza cuyo padre es una Folder o la raíz (no está dentro de otro Model)
		if (d:IsA("Model") or d:IsA("BasePart")) and d.Parent and (d.Parent:IsA("Folder") or d.Parent == raiz) then
			mostrados.obj += 1
			if mostrados.obj <= 2500 then
				print(("OBJETO %s [%s] talla=%s %s"):format(d:GetFullName(), d.ClassName, tallaDe(d), cuenta(d)))
				if d:IsA("Model") then
					print("   " .. nombres(d))
				end
			end
		end
		if Cloud.quedan and Cloud.quedan() < 20 then
			print("CORTE por tiempo")
			break
		end
	end
	for i, k in visOrden do
		if i > 300 then
			print(("… %d Decal/Texture distintos más"):format(#visOrden - 300))
			break
		end
		print(("VIS %s ×%d (p. ej. %s)"):format(k, visAgr[k].n, visAgr[k].donde))
	end
	for i, k in otroOrden do
		if i > 150 then
			print(("… %d textos distintos más"):format(#otroOrden - 150))
			break
		end
		print(("OTRO %s ×%d"):format(k, otroAgr[k]))
	end
	local pb = {}
	for k, n in palabras do
		table.insert(pb, k .. "=" .. n)
	end
	table.sort(pb)
	print("PALABRAS en todos los scripts: " .. (if #pb > 0 then table.concat(pb, ", ") else "ninguna"))
	print(("CUENTAS vis=%d sonidos=%d rojos=%d mallas=%d scripts=%d (repetidos %d) fx=%d"):format(mostrados.vis,
		mostrados.sound, mostrados.rojo, mostrados.mesh, mostrados.scr, mostrados.rep, mostrados.fx))
end

for _, id in IDS do
	idActual = id
	infoN = 0
	print(("===== ID %d ====="):format(id))
	local ok, res = pcall(AssetService.LoadAssetAsync, AssetService, id)
	if not ok then
		print("FALLA " .. tostring(res))
		Cloud.aviso("ID " .. id, false, tostring(res))
	else
		print("CARGA raíz=" .. res.Name .. " [" .. res.ClassName .. "] talla=" .. tallaDe(res))
		local ok2, err = pcall(vuelca, res)
		if not ok2 then
			print("ERROR al volcar: " .. tostring(err))
		end
		Cloud.check("ID " .. id, true, ("%d descendientes"):format(#res:GetDescendants()))
		res:Destroy()
	end
	print(("===== FIN %d ====="):format(id))
end

return Cloud.resultado()
