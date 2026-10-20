-- _comun: lo que comparten las pruebas en los servidores de Roblox (scripts/cloud-test.sh).
--
-- scripts/cloud-test.sh pega este archivo DELANTE de cada prueba, así:
--     local Cloud = (function() <este archivo> end)()
--     <la prueba>
-- (La API de Roblox recibe un solo script de texto: no puede hacer require de archivos de aquí.)
--
-- Cómo es el servidor de una prueba (según la documentación de Open Cloud "Luau execution"):
--   * Es un servidor de verdad con la ÚLTIMA versión publicada del juego (el mapa y los módulos).
--   * La física NO corre y los Script del servidor (Main.server.luau) NO arrancan solos: nada está
--     hecho hasta que la prueba lo hace. Por eso aquí están prepararMundo() y arrancarServicios(),
--     que repiten lo que hace Main.server.luau.
--   * Lo que cambie la prueba en el mapa no se guarda. Los DataStores SÍ son los de verdad.
--   * Máximo 5 minutos por prueba: usa Cloud.quedan() para cortar a tiempo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LogService = game:GetService("LogService")

local Cloud = {}

local T0 = os.clock()
local LIMITE = 250 -- segundos que se permite gastar cada prueba (la API corta a los 300)

-- Orden de arranque de los servicios. cloud-test.sh lo copia de src/server/Main.server.luau
-- (la lista "order") en la línea de abajo, para que siempre sea el mismo que en el juego.
Cloud.ORDEN_SERVICIOS = nil :: { string }? -- @@ORDEN_SERVICIOS@@

-- Servicios que NO se arrancan en las pruebas:
--   UpdateService avisa por MessagingService a los servidores del juego de verdad de que hay una
--   versión nueva (y esos mueven a sus jugadores). Una prueba no debe hacer eso.
Cloud.NO_ARRANCAR = { UpdateService = true }

Cloud.Server = ServerScriptService:WaitForChild("Server", 30) :: Folder
Cloud.Shared = ReplicatedStorage:WaitForChild("Shared", 30) :: Folder

---------------------------------------------------------------------
-- Tiempo
---------------------------------------------------------------------
function Cloud.tiempo(): number
	return os.clock() - T0
end

function Cloud.quedan(): number
	return LIMITE - (os.clock() - T0)
end

function Cloud.limite(segundos: number)
	LIMITE = segundos
end

---------------------------------------------------------------------
-- Comprobaciones y resultado
---------------------------------------------------------------------
-- Cada comprobación: { name, ok, detail, nivel = "aviso"|"salta"|nil }
--   ok = false y nivel = "aviso" -> se enseña, pero la prueba no falla (comprobaciones aproximadas)
--   nivel = "salta"              -> no se ha podido comprobar (se explica en detail)
local checks: { { [string]: any } } = {}
local info: { [string]: any } = {}

function Cloud.check(name: string, ok: boolean, detail: string?, nivel: string?)
	table.insert(checks, { name = name, ok = ok == true, detail = detail or "", nivel = nivel })
end

function Cloud.aviso(name: string, ok: boolean, detail: string?)
	Cloud.check(name, ok, detail, if ok then nil else "aviso")
end

function Cloud.salta(name: string, detail: string)
	table.insert(checks, { name = name, ok = true, detail = detail, nivel = "salta" })
end

function Cloud.info(key: string, value: any)
	info[key] = value
end

function Cloud.resultado(): { [string]: any }
	local ok = true
	for _, c in checks do
		if not c.ok and c.nivel ~= "aviso" then
			ok = false
		end
	end
	info.segundos = math.floor(Cloud.tiempo() * 10) / 10
	return { ok = ok, checks = checks, info = info }
end

-- Lista corta para el detalle ("a, b, c y 12 más")
function Cloud.lista(items: { string }, max: number?): string
	local n = max or 8
	local shown = {}
	for i = 1, math.min(#items, n) do
		shown[i] = items[i]
	end
	local text = table.concat(shown, "; ")
	if #items > n then
		text ..= ("; y %d más"):format(#items - n)
	end
	return text
end

function Cloud.v3(v: Vector3): string
	return ("(%d, %d, %d)"):format(math.floor(v.X + 0.5), math.floor(v.Y + 0.5), math.floor(v.Z + 0.5))
end

-- Nombre corto de una instancia: "Town.Colegio.Puerta" -> últimas 3 partes
function Cloud.nombre(inst: Instance?): string
	if not inst then
		return "?"
	end
	local parts = {}
	local node: Instance? = inst
	while node and node ~= game and node ~= workspace and #parts < 3 do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

---------------------------------------------------------------------
-- Errores del servidor (LogService y ScriptContext)
---------------------------------------------------------------------
-- Cloud.escuchar() empieza a guardar los errores y avisos; Cloud.oido() los devuelve.
local oidos = { errores = {} :: { string }, avisos = {} :: { string } }
local escuchando = false

function Cloud.escuchar()
	if escuchando then
		return
	end
	escuchando = true
	local visto: { [string]: boolean } = {}
	local function guardar(lista: { string }, texto: string)
		texto = string.sub(texto, 1, 400)
		if visto[texto] or #lista >= 200 then
			return
		end
		visto[texto] = true
		table.insert(lista, texto)
	end
	pcall(function()
		LogService.MessageOut:Connect(function(message, kind)
			if kind == Enum.MessageType.MessageError then
				guardar(oidos.errores, message)
			elseif kind == Enum.MessageType.MessageWarning then
				guardar(oidos.avisos, message)
			end
		end)
	end)
	pcall(function()
		game:GetService("ScriptContext").Error:Connect(function(message, trace)
			local where = string.match(trace or "", "([^\n]+)") or ""
			guardar(oidos.errores, message .. (if where ~= "" then " @ " .. where else ""))
		end)
	end)
end

function Cloud.oido(): { errores: { string }, avisos: { string } }
	return oidos
end

---------------------------------------------------------------------
-- Arrancar el mundo y los servicios (lo mismo que Main.server.luau)
---------------------------------------------------------------------
local mundoListo = false

-- Devuelve { { name, ok, err, s } } por paso
function Cloud.prepararMundo(): { { [string]: any } }
	local pasos = {}
	if mundoListo then
		return pasos
	end
	mundoListo = true
	local World = Cloud.Server:WaitForChild("World") :: Folder
	local function paso(name: string, fn: () -> ())
		local t = os.clock()
		local ok, err = pcall(fn)
		table.insert(pasos, { name = name, ok = ok, err = if ok then nil else tostring(err), s = math.floor((os.clock() - t) * 10) / 10 })
		if not ok then
			warn(("[prueba] %s: %s"):format(name, tostring(err)))
		end
	end
	local TerrainBuilder, TownBuilder
	paso("TerrainBuilder.build", function()
		TerrainBuilder = require(World:WaitForChild("TerrainBuilder")) :: any
		TerrainBuilder.build()
	end)
	paso("Ciudad (workspace.Town)", function()
		TownBuilder = require(World:WaitForChild("TownBuilder")) :: any
		if not workspace:FindFirstChild("Town") then
			warn("[prueba] El juego publicado no trae workspace.Town: se construye ahora (lento)")
			TownBuilder.build()
		end
	end)
	paso("Decor.dressTown", function()
		local town = workspace:FindFirstChild("Town")
		if town then
			require(World.Kit.Decor).dressTown(town)
		end
	end)
	paso("TerrainBuilder.removeGroundPart", function()
		if TerrainBuilder then
			TerrainBuilder.removeGroundPart()
		end
	end)
	paso("DreamIsland.build", function()
		require(World.Kit.DreamIsland).build()
	end)
	paso("Ambient.publish", function()
		local Roads = require(World.Kit.Roads) :: any
		local segments = {}
		for _, segment in Roads.segments() do
			table.insert(segments, { A = segment.A, B = segment.B, Kind = segment.Kind, Width = Roads.Kinds[segment.Kind].Road, Walk = Roads.Kinds[segment.Kind].Walk })
		end
		require(World.Ambient).publish(TownBuilder.roads(), segments)
	end)
	return pasos
end

function Cloud.ordenServicios(): { string }
	if Cloud.ORDEN_SERVICIOS and #Cloud.ORDEN_SERVICIOS > 0 then
		return Cloud.ORDEN_SERVICIOS
	end
	-- (sin la lista de Main.server.luau: todos, DataService primero y el resto por orden alfabético)
	local names = {}
	for _, child in (Cloud.Server:WaitForChild("Services") :: Folder):GetChildren() do
		if child:IsA("ModuleScript") and child.Name ~= "DataService" then
			table.insert(names, child.Name)
		end
	end
	table.sort(names)
	table.insert(names, 1, "DataService")
	return names
end

-- Arranca los servicios en el orden de Main.server.luau (cada uno en su pcall, como allí).
-- Devuelve { { name, ok, err, s, saltado?, noPublicado? } }
--   noPublicado = true: el servicio está en la lista de Main.server.luau de esta rama, pero el
--   juego publicado (con el que corre la prueba) todavía no trae su módulo. No es un fallo: se
--   salta ("aún no publicado") hasta que se publique la versión nueva.
function Cloud.arrancarServicios(): { { [string]: any } }
	local Services = Cloud.Server:WaitForChild("Services") :: Folder
	local out = {}
	for _, name in Cloud.ordenServicios() do
		if Cloud.NO_ARRANCAR[name] then
			table.insert(out, { name = name, ok = true, saltado = true, s = 0 })
			continue
		end
		if not Services:FindFirstChild(name) then
			table.insert(out, { name = name, ok = true, saltado = true, noPublicado = true, s = 0 })
			continue
		end
		local t = os.clock()
		local ok, err = pcall(function()
			local module = Services:FindFirstChild(name)
			if not module then
				error("no existe el módulo Services." .. name)
			end
			local service = require(module) :: any
			if type(service) == "table" and type(service.init) == "function" then
				service.init()
			else
				error("no tiene init()")
			end
		end)
		table.insert(out, { name = name, ok = ok, err = if ok then nil else tostring(err), s = math.floor((os.clock() - t) * 100) / 100 })
		if not ok then
			warn(("[Main] Error iniciando %s: %s"):format(name, tostring(err)))
		end
	end
	return out
end

---------------------------------------------------------------------
-- Geometría
---------------------------------------------------------------------
local Ground = require(Cloud.Shared:WaitForChild("Ground")) :: any
Cloud.Ground = Ground

-- Terreno leído en vóxeles, sin rayos. En estas pruebas la física no corre y el terreno que
-- TerrainBuilder acaba de poner puede no verse con workspace:Raycast (en la prueba "mundo" contra
-- la v66, los 6 StorySpot "sin suelo debajo, ni a 200 studs" eran justo los que solo tienen terreno
-- debajo: el pie y la cima del Monte del Silencio y dos colegios con una franja de hierba delante).
-- Por eso, si el rayo no da con nada, se mira el terreno leyendo sus vóxeles.
-- Cloud.info("suelo_de_terreno_leido_en_voxeles", n) cuenta cuántas veces ha hecho falta.
local terrenoPorVoxeles = 0
local SOLIDO_NO = { [Enum.Material.Air] = true, [Enum.Material.Water] = true }
local function terrenoBajo(p: Vector3, arriba: number, abajo: number): { [string]: any }?
	local ok, result = pcall(function()
		local terrain = workspace.Terrain
		local lo = Vector3.new(p.X - 1, p.Y - abajo, p.Z - 1)
		local hi = Vector3.new(p.X + 1, p.Y + arriba, p.Z + 1)
		local region = Region3.new(lo, hi):ExpandToGrid(4)
		local materials, occupancies = terrain:ReadVoxels(region, 4)
		local size = materials.Size
		local y0 = region.CFrame.Position.Y - region.Size.Y / 2
		-- De arriba abajo: el primer vóxel sólido (no aire ni agua) que queda por debajo del punto
		-- (o a menos de 1 stud por encima) es el suelo. Lo sólido por encima (roca sobre un túnel)
		-- no cuenta.
		for y = size.Y, 1, -1 do
			local material = materials[1][y][1]
			local occ = occupancies[1][y][1]
			if not SOLIDO_NO[material] and occ > 0.05 then
				local top = y0 + (y - 1) * 4 + 4 * math.clamp(occ, 0, 1)
				if top <= p.Y + 1 then
					if top >= p.Y - abajo then
						return { Position = Vector3.new(p.X, top, p.Z), Normal = Vector3.new(0, 1, 0), Instance = terrain, Material = material, Distance = p.Y - top }
					end
					return nil
				end
			end
		end
		return nil
	end)
	if ok and result then
		terrenoPorVoxeles += 1
		Cloud.info("suelo_de_terreno_leido_en_voxeles", terrenoPorVoxeles)
		return result
	end
	return nil
end

-- Suelo de verdad debajo de un punto (salta lo que no choca, vehículos y personajes).
-- Devuelve el impacto (o nil), mirando desde `arriba` studs por encima hasta `abajo` por debajo.
-- (Si el rayo no ve nada, mira el terreno por sus vóxeles: devuelve entonces una tabla con los
-- mismos campos que un RaycastResult: Position, Normal, Instance = workspace.Terrain, Material.)
function Cloud.suelo(p: Vector3, arriba: number?, abajo: number?, ignorar: { Instance }?): any
	local up, down = arriba or 3, abajo or 8
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if ignorar then table.clone(ignorar) else {}
	local hit = Ground.cast(p + Vector3.new(0, up, 0), Vector3.new(0, -(up + down), 0), params, 12)
	if hit then
		return hit
	end
	return terrenoBajo(p, up, down)
end

-- ¿Cabe una persona de pie en este suelo? Devuelve (cabe, lo que estorba)
-- Con la forma de verdad de cada pieza (GetPartsInPart): con GetPartBoundsInBox una pieza redonda
-- (el borde de la fuente de la plaza) estorbaba por su caja, aunque la persona quedara fuera.
-- `talla`: ancho y alto de la persona (por defecto 2 × 4.6); `holgura`: a cuánto del suelo empieza
-- la caja (por defecto 0.4; en escaleras y rampas hace falta más).
local PERSONA = Vector3.new(2, 4.6, 2)
local sonda: BasePart? = nil
local function laSonda(): BasePart
	if sonda and sonda.Parent then
		return sonda
	end
	local p = Instance.new("Part")
	p.Name = "SondaPrueba"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Transparency = 1
	p.Parent = workspace
	sonda = p
	return p
end
function Cloud.cabe(pie: Vector3, ignorar: { Instance }?, talla: Vector3?, holgura: number?): (boolean, BasePart?)
	local size = talla or PERSONA
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local lista = if ignorar then table.clone(ignorar) else {}
	local probe = laSonda()
	table.insert(lista, probe)
	params.FilterDescendantsInstances = lista
	params.RespectCanCollide = true
	params.MaxParts = 8
	local cf = CFrame.new(pie + Vector3.new(0, (holgura or 0.4) + size.Y / 2, 0))
	local ok, parts = pcall(function()
		probe.Size = size
		probe.CFrame = cf
		return workspace:GetPartsInPart(probe, params)
	end)
	if not ok then
		parts = workspace:GetPartBoundsInBox(cf, size, params)
	end
	for _, part in parts do
		if part ~= workspace.Terrain and Ground.skipOf(part) == nil then
			return false, part
		end
	end
	return true, nil
end

-- Posición de algo que puede ser una pieza, un Attachment o un modelo
function Cloud.posicion(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Attachment") then
		return inst.WorldPosition
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

return Cloud
