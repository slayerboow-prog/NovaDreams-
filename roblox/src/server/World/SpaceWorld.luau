-- SpaceWorld: las piezas del puerto espacial de Valmar, los portales y el espacio de encima de la
-- ciudad (estaciones y campos de asteroides). Las formas y los sitios salen de shared/Cosmos (Access,
-- Stations, Zone): lo que aquí es un asteroide, para la nave es una esfera del mismo tamaño.
--
--   SpaceWorld.buildPort()            el puerto del islote (al arrancar: es pequeño). Devuelve sus carteles.
--   SpaceWorld.buildBeachPortal(cf)   el portal de la playa (al puerto espacial)
--   SpaceWorld.buildSpace()           estaciones y asteroides (la PRIMERA vez que alguien sube: nunca al
--                                     arrancar). Se cargan por zonas (streaming): solo los ve quien está
--                                     cerca (a 3400+ studs de altura, nadie en la ciudad los recibe).
--   SpaceWorld.setRockLit(id, lleno)  un asteroide vacío apaga sus vetas; al rellenarse vuelven a brillar
--   SpaceWorld.setRockDamage(id, n)   grietas que brillan (0..3); hideRock / showRock: roto y de vuelta
-- Los asteroides son rocas irregulares (shared/Cosmos/AsteroidBuild; docs/espacio-aaa/asteroides.md).
-- Nada de marcas ni logos: formas sencillas, metal, cristal y neón. Se prueba en scripts/test-space.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Builder)
local Cosmos = ReplicatedStorage.Shared.Cosmos
local Access = require(Cosmos.Access)
local Stations = require(Cosmos.Stations)
local Zone = require(Cosmos.Zone)
local Asteroids = require(Cosmos.Asteroids)
local AsteroidBuild = require(Cosmos.AsteroidBuild)
local AsteroidMeshes = require(script.Parent.AsteroidMeshes)
local ShipInfo = require(ReplicatedStorage.Shared.AirCombat.ShipInfo)

local SpaceWorld = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local M = Enum.Material

export type Prompts = { [string]: ProximityPrompt }

local function decor(props: { [string]: any }): BasePart
	return Builder.decor(props)
end

local function solid(props: { [string]: any }): BasePart
	props.CastShadow = false
	return Builder.part(props)
end

local function prompt(parent: Instance, action: string, object: string, key: string): ProximityPrompt
	local p = Builder.prompt(parent, action, object, 0.25)
	p.MaxActivationDistance = 14
	p.Name = "SpacePrompt"
	p:SetAttribute("SpaceAction", key)
	return p
end

local function sign(parent: Instance, text: string, cf: CFrame, size: Vector3, color: Color3)
	local board = decor({ Name = "Cartel", Size = size, CFrame = cf, Color = rgb(20, 24, 34), Material = M.SmoothPlastic, Parent = parent })
	Builder.sign(board, text, Enum.NormalId.Front, color)
	Builder.sign(board, text, Enum.NormalId.Back, color)
end

-- Un portal redondo de pie (aro de neón por segmentos y un disco que brilla). cf: centro del suelo,
-- mirando hacia donde se cruza.
local function portal(parent: Instance, name: string, cf: CFrame, color: Color3, glow: Color3): BasePart
	local model = Builder.model(name, parent)
	local radius = 7
	local center = cf * CFrame.new(0, radius + 1.5, 0)
	for i = 1, 18 do
		local a = (i - 1) / 18 * math.pi * 2
		decor({
			Name = "Aro",
			Size = V(1.4, 2.7, 1.4),
			CFrame = center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a),
			Color = color,
			Material = M.Neon,
			Parent = model,
		})
	end
	local disc = decor({
		Name = "Velo",
		Shape = Enum.PartType.Cylinder,
		Size = V(0.4, radius * 2 - 1, radius * 2 - 1),
		CFrame = center * CFrame.Angles(0, math.pi / 2, 0),
		Color = glow,
		Material = M.Neon,
		Transparency = 0.45,
		Parent = model,
	})
	solid({ Name = "Base", Size = V(radius * 2 + 4, 1, 5), CFrame = cf * CFrame.new(0, 0.5, 0), Color = rgb(60, 64, 76), Material = M.Metal, Parent = model })
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 18
	light.Brightness = 1.4
	light.Parent = disc
	return disc
end

local function face(pos: Vector3, look: Vector3): CFrame
	return Builder.facing(pos, look)
end

---------------------------------------------------------------------
-- El puerto espacial (islote)
---------------------------------------------------------------------
local port: Model? = nil
local portPrompts: Prompts = {}

function SpaceWorld.port(): Model?
	return if port and port.Parent then port else nil
end

function SpaceWorld.buildPort(): (Model, Prompts)
	local existing = SpaceWorld.port()
	if existing then
		return existing, portPrompts
	end
	local model = Builder.model("PuertoEspacial", workspace)
	Builder.streamable(model)
	local O = Access.Port
	local top = Access.PadTop
	-- Pista redonda con anillo de luces y la diana del despegue
	solid({ Name = "Pista", Shape = Enum.PartType.Cylinder, Size = V(top + 2, Access.PadRadius * 2, Access.PadRadius * 2), CFrame = CFrame.new(O + V(0, top / 2 - 1, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(70, 74, 86), Material = M.Concrete, Parent = model })
	decor({ Name = "Diana", Shape = Enum.PartType.Cylinder, Size = V(0.2, 26, 26), CFrame = CFrame.new(O + V(0, top + 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(255, 196, 60), Material = M.Neon, Transparency = 0.35, Parent = model })
	decor({ Name = "DianaCentro", Shape = Enum.PartType.Cylinder, Size = V(0.25, 20, 20), CFrame = CFrame.new(O + V(0, top + 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(70, 74, 86), Material = M.Concrete, Parent = model })
	for i = 1, 24 do
		local a = (i - 1) / 24 * math.pi * 2
		decor({ Name = "LuzPista", Size = V(1.2, 0.4, 1.2), CFrame = CFrame.new(O + V(math.cos(a) * (Access.PadRadius - 2), top + 0.2, math.sin(a) * (Access.PadRadius - 2))), Color = if i % 2 == 0 then rgb(90, 200, 255) else rgb(255, 255, 255), Material = M.Neon, Parent = model })
	end
	-- Torre de control pequeña y cartel
	solid({ Name = "Torre", Size = V(8, 26, 8), CFrame = CFrame.new(O + V(-38, top + 13, -34)), Color = rgb(225, 230, 238), Material = M.Metal, Parent = model })
	decor({ Name = "TorreCristal", Size = V(10, 5, 10), CFrame = CFrame.new(O + V(-38, top + 28.5, -34)), Color = rgb(120, 200, 255), Material = M.Glass, Transparency = 0.4, Parent = model })
	decor({ Name = "Baliza", Shape = Enum.PartType.Ball, Size = V(2, 2, 2), CFrame = CFrame.new(O + V(-38, top + 32, -34)), Color = rgb(255, 70, 60), Material = M.Neon, Parent = model })
	sign(model, "PUERTO ESPACIAL DE VALMAR", face(O + V(0, top + 9, -46), V(0, 0, 1)), V(34, 5, 0.6), rgb(140, 220, 255))
	for _, x in { -16, 16 } do
		solid({ Name = "Poste", Size = V(1, 9, 1), CFrame = CFrame.new(O + V(x, top + 4.5, -46)), Color = rgb(60, 64, 76), Material = M.Metal, Parent = model })
	end
	-- La nave de exposición: «Subir a la nave»
	local AirArena = require(script.Parent.AirArena)
	local spot = O + Access.ShipSpot + V(0, top + 3.2, 0)
	local display = AirArena.ship(face(spot, V(1, 0, 0)))
	display.Name = "NaveExpuesta"
	for _, d in display:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local seat = display:FindFirstChild("ShipSeat")
	if seat then
		seat:Destroy() -- (de exposición: nadie se sienta; «Subir a la nave» te da la tuya)
	end
	display.Parent = model
	solid({ Name = "Soporte", Size = V(6, 2, 10), CFrame = CFrame.new(spot - V(0, 2.6, 0)), Color = rgb(60, 64, 76), Material = M.Metal, Parent = model })
	-- La ficha de la nave (shared/AirCombat/ShipInfo: HX-7 Halcón, velocidad, escudos, estructura y carga)
	sign(model, ShipInfo.card(), face(spot + V(0, 6, -17), V(0, 0, 1)), V(12, 6, 0.3), rgb(150, 220, 255))
	local shipPrompt = prompt(display.PrimaryPart :: BasePart, "Subir a la nave", "Puerto espacial", "Board")
	shipPrompt.MaxActivationDistance = 18
	-- Portales: a la Estación Alba y de vuelta a la playa
	local toStation = portal(model, "PortalEstacion", face(O + Access.StationPortalSpot + V(0, top, 0), V(1, 0, -1)), rgb(190, 120, 255), rgb(150, 90, 255))
	local stationPrompt = prompt(toStation, "Viajar a la Estación Alba", "Portal", "PortalStation")
	sign(model, "ESTACIÓN ALBA", face(O + Access.StationPortalSpot + V(0, top + 19, 0), V(1, 0, -1)), V(14, 2.4, 0.4), rgb(220, 180, 255))
	local toBeach = portal(model, "PortalPlaya", face(O + Access.BeachPortalSpot + V(0, top, 0), V(-1, 0, 1)), rgb(90, 220, 140), rgb(80, 200, 255))
	local beachPrompt = prompt(toBeach, "Volver a la playa de Valmar", "Portal", "PortalBeach")
	sign(model, "VALMAR · PLAYA", face(O + Access.BeachPortalSpot + V(0, top + 19, 0), V(-1, 0, 1)), V(14, 2.4, 0.4), rgb(170, 255, 200))
	port = model
	portPrompts = { Board = shipPrompt, PortalStation = stationPrompt, PortalBeach = beachPrompt }
	return model, portPrompts
end

-- El portal de la playa (cf: el suelo donde va, mirando hacia el mar)
function SpaceWorld.buildBeachPortal(cf: CFrame): (Model, ProximityPrompt)
	local model = Builder.model("PortalPuertoEspacial", workspace)
	Builder.streamable(model)
	local disc = portal(model, "Portal", cf, rgb(90, 200, 255), rgb(120, 160, 255))
	local p = prompt(disc, "Ir al puerto espacial", "Portal", "PortalPort")
	sign(model, "🚀 PUERTO ESPACIAL", cf * CFrame.new(0, 19, 0), V(14, 2.4, 0.4), rgb(140, 220, 255))
	return model, p
end

---------------------------------------------------------------------
-- El espacio: estaciones y asteroides
---------------------------------------------------------------------
local space: Folder? = nil
local spacePrompts: { [string]: Prompts } = {}
local rockParts: { [string]: BasePart } = {}
local rockModels: { [string]: Model } = {}

function SpaceWorld.space(): Folder?
	return if space and space.Parent then space else nil
end

function SpaceWorld.stationPrompts(): { [string]: Prompts }
	return spacePrompts
end

local function buildStation(parent: Instance, st: Stations.Station): Prompts
	local model = Builder.model("Estacion" .. st.Id, parent)
	Builder.streamable(model)
	model:SetAttribute("Station", st.Id)
	local C = st.Center
	local H, T = Stations.HallHalf, Stations.HallHeight
	local metal, dark = rgb(214, 220, 230), rgb(52, 56, 68)
	-- Vestíbulo: suelo, paredes y techo de cristal (cerrado: andando no te caes al vacío)
	solid({ Name = "Suelo", Size = V(H * 2, 4, H * 2), CFrame = CFrame.new(C - V(0, 2, 0)), Color = rgb(90, 96, 110), Material = M.DiamondPlate, Parent = model })
	for _, side in { { V(H, T / 2, 0), V(2, T, H * 2) }, { V(-H, T / 2, 0), V(2, T, H * 2) }, { V(0, T / 2, H), V(H * 2, T, 2) }, { V(0, T / 2, -H), V(H * 2, T, 2) } } do
		solid({ Name = "Pared", Size = side[2], CFrame = CFrame.new(C + side[1]), Color = metal, Material = M.Metal, Parent = model })
	end
	solid({ Name = "Techo", Size = V(H * 2, 1, H * 2), CFrame = CFrame.new(C + V(0, T, 0)), Color = rgb(140, 200, 255), Material = M.Glass, Transparency = 0.6, Parent = model })
	-- Ventanales (franjas de cristal en las paredes) y luces
	for _, z in { -H + 1.2, H - 1.2 } do
		decor({ Name = "Ventanal", Size = V(H * 1.6, 8, 0.4), CFrame = CFrame.new(C + V(0, 14, z)), Color = rgb(30, 40, 70), Material = M.Glass, Transparency = 0.3, Parent = model })
	end
	for i = -1, 1 do
		local lamp = decor({ Name = "Lampara", Size = V(10, 0.6, 3), CFrame = CFrame.new(C + V(i * 26, T - 1, 0)), Color = rgb(235, 245, 255), Material = M.Neon, Parent = model })
		if i == 0 then
			local light = Instance.new("PointLight")
			light.Range = 50
			light.Brightness = 1.2
			light.Parent = lamp
		end
	end
	sign(model, st.Sign, CFrame.new(C + V(0, 20, -H + 1.4)), V(30, 4, 0.4), st.Color)
	-- Exterior: anillo de neón, paneles y el muelle
	for i = 1, 20 do
		local a = (i - 1) / 20 * math.pi * 2
		decor({ Name = "Anillo", Size = V(14, 3, 3), CFrame = CFrame.new(C + V(math.cos(a) * 92, 10, math.sin(a) * 92)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = st.Color, Material = M.Neon, Parent = model })
	end
	for _, s in { -1, 1 } do
		decor({ Name = "PanelSolar", Size = V(70, 1, 26), CFrame = CFrame.new(C + V(0, -6, s * 120)), Color = rgb(30, 50, 110), Material = M.Glass, Parent = model })
		decor({ Name = "Brazo", Size = V(3, 3, 60), CFrame = CFrame.new(C + V(0, -6, s * 74)), Color = dark, Material = M.Metal, Parent = model })
	end
	local dock = st.Dock
	for i = 1, 14 do
		local a = (i - 1) / 14 * math.pi * 2
		local right = st.Out:Cross(V(0, 1, 0)).Unit
		decor({ Name = "Muelle", Size = V(4, 4, 4), CFrame = CFrame.new(dock + right * math.cos(a) * 34 + V(0, math.sin(a) * 34, 0)), Color = rgb(80, 255, 170), Material = M.Neon, Transparency = 0.2, Parent = model })
	end
	sign(model, "MUELLE · ATRACAR AQUÍ", CFrame.new(dock + V(0, 44, 0)) * CFrame.Angles(0, math.atan2(-st.Out.X, -st.Out.Z) + math.pi, 0), V(30, 5, 0.6), rgb(120, 255, 190))
	-- Dentro: tienda, tablón, hangar y portal a Valmar
	local function kiosk(name: string, at: Vector3, color: Color3, action: string, object: string, key: string, label: string): ProximityPrompt
		local box = solid({ Name = name, Size = V(8, 5, 4), CFrame = CFrame.new(C + at + V(0, 2.5, 0)), Color = dark, Material = M.Metal, Parent = model })
		decor({ Name = name .. "Luz", Size = V(8.2, 0.6, 4.2), CFrame = CFrame.new(C + at + V(0, 5.3, 0)), Color = color, Material = M.Neon, Parent = model })
		sign(model, label, CFrame.new(C + at + V(0, 8, 0)), V(10, 2, 0.3), color)
		return prompt(box, action, object, key)
	end
	local shop = kiosk("Tienda", V(-26, 0, -20), rgb(255, 200, 80), "Abrir la tienda", "Tienda de la estación", "Shop", "TIENDA")
	local board = kiosk("Tablon", V(0, 0, -26), rgb(120, 220, 255), "Mirar el tablón", "Misiones", "Board", "MISIONES")
	local hangar = kiosk("Hangar", V(26, 0, -20), rgb(120, 255, 170), "Subir a la nave", "Hangar", "Launch", "HANGAR")
	sign(model, ShipInfo.card(), CFrame.new(C + V(26, 13, -21)), V(11, 5.5, 0.3), rgb(150, 220, 255))
	local home = portal(model, "PortalValmar", CFrame.new(C + V(0, 0, 30)) * CFrame.Angles(0, math.pi, 0), rgb(90, 220, 140), rgb(80, 200, 255))
	local homePrompt = prompt(home, "Volver a Valmar", "Portal", "Home")
	sign(model, "VOLVER A VALMAR", CFrame.new(C + V(0, 19, 30)), V(14, 2.4, 0.4), rgb(170, 255, 200))
	return { Shop = shop, Board = board, Launch = hangar, Home = homePrompt }
end

-- Un asteroide: roca irregular (shared/Cosmos/AsteroidBuild: bloques y cuñas, o la malla de Blender si
-- está cargada), con cráteres, vetas que brillan un poco, grietas ocultas y piedrecitas alrededor
local rockHome: { [string]: Instance } = {}

local function buildRock(parent: Instance, rock: Zone.Rock): Model
	local cf = CFrame.new(rock.Center) * Asteroids.baseRotation(rock.Id)
	local model = AsteroidBuild.make(rock.Id, rock.Radius, rock.Ore, rock.Field, cf, { Meshes = AsteroidMeshes.folder(), Shadows = rock.Radius >= 30 })
	Builder.streamable(model)
	model:SetAttribute("RockId", rock.Id)
	model:SetAttribute("Ore", rock.Ore)
	model:SetAttribute("Radio", rock.Radius)
	model:SetAttribute("Campo", rock.Field)
	model:AddTag("Asteroide")
	if rock.Radius >= 30 then
		local pal = Asteroids.Palettes[rock.Field] or Asteroids.Palettes.Hierro
		AsteroidBuild.dust(model, rock.Radius, pal.Light)
	end
	model.Parent = parent
	rockParts[rock.Id] = model.PrimaryPart :: BasePart
	rockModels[rock.Id] = model
	rockHome[rock.Id] = parent
	return model
end

function SpaceWorld.buildSpace(): Folder
	local existing = SpaceWorld.space()
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "EspacioValmar"
	for _, st in Stations.List do
		spacePrompts[st.Id] = buildStation(folder, st)
	end
	for _, f in Zone.Fields do
		local fm = Instance.new("Folder")
		fm.Name = "Campo" .. f.Id
		fm.Parent = folder
	end
	for _, rock in Zone.rocks() do
		buildRock(folder:FindFirstChild("Campo" .. rock.Field) or folder, rock)
	end
	folder.Parent = workspace
	space = folder
	-- (las mallas de Blender, si se han subido: al cargarse, los asteroides se rehacen con ellas)
	pcall(AsteroidMeshes.start, function()
		SpaceWorld.rebuildRocks()
	end)
	return folder
end

-- Rehace todos los asteroides (p. ej. cuando llegan las mallas); los rotos siguen ocultos
function SpaceWorld.rebuildRocks()
	if not SpaceWorld.space() then
		return
	end
	for _, rock in Zone.rocks() do
		local old = rockModels[rock.Id]
		local home = rockHome[rock.Id]
		if old and home then
			local hidden = old.Parent == nil
			local stage = old:GetAttribute("Dano")
			old:Destroy()
			local m = buildRock(home, rock)
			if type(stage) == "number" then
				AsteroidBuild.setDamage(m, stage)
			end
			if hidden then
				m.Parent = nil
			end
		end
	end
end

function SpaceWorld.rockModel(id: string): Model?
	return rockModels[id]
end

-- Nivel de daño (0..3): las grietas brillan
function SpaceWorld.setRockDamage(id: string, stage: number)
	local m = rockModels[id]
	if m then
		AsteroidBuild.setDamage(m, stage)
	end
end

-- Roto: se quita del campo (sus trozos los ve cada cliente: Controllers/AsteroidFx)
function SpaceWorld.hideRock(id: string)
	local m = rockModels[id]
	if m then
		m.Parent = nil
	end
end

-- Vuelve entero (sin grietas y con su brillo)
function SpaceWorld.showRock(id: string)
	local m = rockModels[id]
	if m then
		AsteroidBuild.setDamage(m, 0)
		m.Parent = rockHome[id]
		SpaceWorld.setRockLit(id, true)
	end
end

-- Un asteroide vacío apaga sus vetas; al rellenarse vuelven a brillar
function SpaceWorld.setRockLit(id: string, lit: boolean)
	local m = rockModels[id]
	if not m then
		return
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Vein") == id then
			local base = d:GetAttribute("BaseTransparency")
			d.Transparency = if lit then (if type(base) == "number" then base else 0) else 0.85
		end
	end
end

return SpaceWorld
