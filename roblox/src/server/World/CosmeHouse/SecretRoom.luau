-- SecretRoom: la habitación secreta de Cosme (docs/historia/casa-cosme.md, punto 24), al fondo del
-- pasillo del sótano.
--
--   * No se ve: es una estantería más del pasillo. Se abre con una COMBINACIÓN (sacar tres libros en
--     orden: FÍSICA, TIEMPO, LUNA; la pista está en la caja fuerte del despacho) o con el BOTÓN de
--     dentro. La estantería gira sobre su bisagra (CosmeHouse/Interactions la mueve).
--   * Dentro cambia todo: paredes moradas casi negras, runas que brillan, objetos de otros universos
--     en vitrinas, fotos raras unidas con hilo rojo, coordenadas, el diario de Cosme y un portal
--     incompleto. Desbloquea contenido futuro (CosmeHouse/QuestHooks: «SecretOpened»).

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local PortalSystem = require(script.Parent.PortalSystem)
local Furniture = require(script.Parent.Parent.Furniture)

local SecretRoom = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local FB = Layout.FB
local DARK = rgb(28, 18, 40)
local RUNE = rgb(190, 80, 255)

SecretRoom.Combination = { "FISICA", "TIEMPO", "LUNA" }
SecretRoom.Books = {
	{ Id = "FISICA", Label = "FÍSICA", Color = rgb(40, 70, 130), Z = -27.2, Y = 5.7 },
	{ Id = "QUIMICA", Label = "QUÍMICA", Color = rgb(40, 110, 70), Z = -28.4, Y = 3.45 },
	{ Id = "TIEMPO", Label = "TIEMPO", Color = rgb(200, 160, 60), Z = -29.6, Y = 7.95 },
	{ Id = "CHISTES", Label = "CHISTES MALOS", Color = rgb(200, 90, 50), Z = -30.4, Y = 5.7 },
	{ Id = "LUNA", Label = "LUNA", Color = rgb(150, 150, 170), Z = -31, Y = 3.45 },
}

local DOOR = { X = -30, Z0 = -32, Z1 = -26, Height = 9.5 }
SecretRoom.Door = DOOR

local function wallPanel(ctx: Kit.Ctx, parent: Instance, size: Vector3, cf: CFrame)
	Kit.deco(ctx, parent, "PanelMorado", size, cf, DARK, M.Slate, nil, true)
end

function SecretRoom.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "HabitacionSecreta")
	-- Pared de la estantería (x = -30) con el hueco de la puerta secreta
	Kit.wall(ctx, m, "Z", DOOR.X, -46, -24, FB - 1, Layout.CEIL.B, { Thick = 1, Name = "InnerWall", Color = rgb(58, 64, 78), Material = M.Concrete, Openings = { { A = DOOR.Z0, B = DOOR.Z1, Bottom = FB, Top = FB + DOOR.Height } } })

	-- La estantería que gira (Model con su bisagra): libros de verdad y cinco libros especiales
	local shelf = Props.shelf(ctx, m, CF(DOOR.X, FB, (DOOR.Z0 + DOOR.Z1) / 2) * ANG(0, -math.pi / 2, 0), 5.9, DOOR.Height - 0.1)
	shelf.Name = "EstanteriaSecreta"
	shelf:AddTag("SecretDoor")
	shelf:SetAttribute("Hinge", Kit.at(ctx, DOOR.X, FB, DOOR.Z0))
	shelf:SetAttribute("Swing", math.rad(-95))
	shelf:SetAttribute("Open", false)
	for _, d in shelf:GetDescendants() do
		if d:IsA("BasePart") then
			d:AddTag("SecretDoor")
		end
	end
	for _, b in SecretRoom.Books do
		local book = Kit.deco(ctx, shelf, "LibroSecreto_" .. b.Id, V(1.25, 1.8, 0.45), CF(DOOR.X + 0.35, FB + b.Y, b.Z), b.Color, M.SmoothPlastic, nil, true)
		book:AddTag("SecretDoor")
		book:SetAttribute("Book", b.Id)
		local glow = Kit.neon(ctx, shelf, "Lomo", V(1.27, 0.2, 0.47), CF(DOOR.X + 0.35, FB + b.Y + 0.5, b.Z), rgb(255, 230, 160), 0.6)
		glow:AddTag("SecretDoor")
		Kit.signText(book, b.Label, Enum.NormalId.Right, rgb(250, 240, 220), b.Color)
		Kit.prompt(book, "Sacar el libro", "📕 «" .. b.Label .. "»", "SecretBook", { Book = b.Id })
	end

	-- Dentro: paneles morados en las paredes, techo bajo, suelo negro con un círculo
	local x0, x1, z0, z1 = -48, DOOR.X, -46, -24
	local inside = Kit.group(m, "Dentro")
	local yTop = FB + 12.5
	Kit.box(ctx, inside, "Ceiling", V(x1 - x0, 0.4, z1 - z0), CF((x0 + x1) / 2, yTop, (z0 + z1) / 2), DARK, M.Slate, { CanQuery = true })
	Kit.box(ctx, inside, "Floor", V(x1 - x0, 0.06, z1 - z0), CF((x0 + x1) / 2, FB + 0.03, (z0 + z1) / 2), rgb(18, 14, 26), M.Marble, { CanQuery = true })
	wallPanel(ctx, inside, V(0.2, yTop - FB, z1 - z0), CF(x0 + 0.6, (FB + yTop) / 2, (z0 + z1) / 2))
	wallPanel(ctx, inside, V(x1 - x0, yTop - FB, 0.2), CF((x0 + x1) / 2, (FB + yTop) / 2, z0 + 0.6))
	wallPanel(ctx, inside, V(x1 - x0, yTop - FB, 0.2), CF((x0 + x1) / 2, (FB + yTop) / 2, z1 - 0.6))
	wallPanel(ctx, inside, V(0.2, yTop - FB, -34 - z0), CF(x1 - 0.6, (FB + yTop) / 2, (z0 - 34) / 2))
	local circle = Kit.cyl(ctx, inside, "Circulo", 0.04, 10, CF(-39, FB + 0.07, -35), RUNE, M.Neon)
	circle.Transparency = 0.3
	Kit.cyl(ctx, inside, "CirculoHueco", 0.05, 9.4, CF(-39, FB + 0.075, -35), rgb(18, 14, 26), M.Marble)
	-- Runas que brillan en las paredes
	local R = ctx.Rand
	for i = 0, 13 do
		local onWest = i < 7
		local cf = if onWest then CF(x0 + 0.75, FB + R.range(3, 10), R.range(z0 + 2, z1 - 2)) * ANG(0, math.pi / 2, 0) else CF(R.range(x0 + 2, x1 - 6), FB + R.range(3, 10), z0 + 0.75)
		local rune = Kit.neon(ctx, inside, "Runa", V(R.range(0.4, 1.2), R.range(0.6, 1.6), 0.05), cf * ANG(0, 0, R.range(-0.8, 0.8)), RUNE, 0.2)
		rune.CastShadow = false
	end
	for _, p in { { -44, -27 }, { -34, -44 }, { -46, -44 } } do
		local lamp = Kit.neon(ctx, inside, "LuzMorada", V(1, 0.3, 1), CF(p[1], yTop - 0.35, p[2]), RUNE, 0.2)
		Kit.light(ctx, lamp, 18, 1, RUNE, "Secreta")
	end
	Kit.switch(ctx, inside, -30.75, FB + 4, -33.6, 90, "Secreta")
	-- Botón de dentro (abre la estantería)
	local button = Kit.neon(ctx, inside, "BotonSecreto", V(0.25, 0.8, 0.8), CF(-30.6, FB + 4.5, -25), C.Red)
	Kit.prompt(button, "Abrir la estantería", "🔴 Botón", "SecretButton")

	-- El portal incompleto (sin terminar: le falta un trozo de aro y no tiene bobinas)
	local portal = PortalSystem.build(ctx, inside, CF(-40, FB + 5.5, -43) * ANG(0, math.pi, 0), 3.6, { Name = "PortalIncompleto", Color = rgb(255, 60, 90), Depth = 2.2, Layers = 7, Broken = true, NoCoils = true, Spin = 0.05, Stand = 5.5 - 4.4, Destination = 5 })
	portal:SetAttribute("Incomplete", true)
	Kit.doc(portal:FindFirstChild("Base", true) :: BasePart, "Portal incompleto", "Una placa a medio atornillar: «PORTAL 0 — destino fijo: 66-B. NO TERMINAR NUNCA». Debajo, con otra letra, alguien ha escrito: «Ya casi, socio».", "CosmePortalIncompleto")

	-- Vitrinas con objetos de otros universos
	local objects = {
		{ "Cristal que canta", "Viene de un universo donde las piedras cantan ópera. Este desafina.", rgb(120, 255, 220), "Ball" },
		{ "Reloj de 13 horas", "Marca la hora 13. Cosme dice que es la hora de los inventos.", rgb(255, 210, 90), "Disc" },
		{ "Hoja de un árbol que no existe", "Es azul, cuadrada y huele a lunes.", rgb(90, 140, 255), "Leaf" },
		{ "Moneda 66-B (copia)", "La cara de Cosme… con perilla. Una copia de la que cayó de la grieta.", rgb(220, 180, 80), "Disc" },
		{ "Calavera de… algo", "Tiene tres ojos y una sonrisa educada. Cosme la llama Tomás.", rgb(240, 236, 220), "Skull" },
	}
	local spots = { { -46, -25.6 }, { -43.4, -25.6 }, { -36.5, -25.6 }, { -33.4, -44 }, { -46, -40 } }
	for i, o in objects do
		local p = spots[i]
		local ped = Kit.group(inside, "Vitrina")
		local base = Kit.box(ctx, ped, "Pedestal", V(2, 3, 2), CF(p[1], FB + 1.5, p[2]), rgb(40, 30, 56), M.Marble)
		Kit.neon(ctx, ped, "Borde", V(2.1, 0.12, 2.1), CF(p[1], FB + 3.06, p[2]), RUNE, 0.3)
		local obj: BasePart
		if o[4] == "Ball" then
			obj = Kit.ball(ctx, ped, "Objeto", 0.9, CF(p[1], FB + 4.2, p[2]), o[3], M.Neon, 0.2)
		elseif o[4] == "Disc" then
			obj = Kit.cylX(ctx, ped, "Objeto", 0.2, 0.9, CF(p[1], FB + 3.8, p[2]) * ANG(0, 0.6, 0), o[3], M.Metal)
		elseif o[4] == "Leaf" then
			obj = Kit.deco(ctx, ped, "Objeto", V(0.9, 0.05, 0.9), CF(p[1], FB + 4, p[2]) * ANG(0.4, 0.7, 0), o[3], M.Neon)
		else
			obj = Kit.ball(ctx, ped, "Objeto", 1, CF(p[1], FB + 3.6, p[2]), o[3], M.Marble)
			for k = -1, 1 do
				Kit.ball(ctx, ped, "Ojo", 0.2, CF(p[1] + k * 0.25, FB + 3.75, p[2] + 0.45), C.Dark, M.SmoothPlastic)
			end
		end
		if o[4] ~= "Skull" then
			Kit.anomaly(obj)
			Kit.spin(obj, 0.1, "Y")
		end
		Kit.glass(ctx, ped, "Campana", V(1.8, 2.2, 1.8), CF(p[1], FB + 4.15, p[2]), rgb(220, 200, 255), 0.75, false)
		Kit.doc(base, o[1], o[2], "CosmeObjeto" .. i)
	end
	-- Pared de fotos raras unidas con hilo rojo (pared este, sur de la puerta) y coordenadas (oeste)
	for i, kind in { "Anomalies", "Stars", "Camera", "Map" } do
		local z = -44 + (i - 1) * 2.6
		local y = FB + 5 + (i % 2) * 2.2
		Kit.wallScreen(ctx, inside, CF(-30.75, y, z) * ANG(0, math.pi / 2, 0), 2, 1.6, kind)
	end
	for i = 1, 3 do
		Kit.neon(ctx, inside, "HiloRojo", V(0.05, 0.06, 3), CF(-30.95, FB + 6.1, -44 + (i - 0.5) * 2.6) * ANG(if i % 2 == 0 then 0.6 else -0.6, 0, 0), C.Red, 0.1)
	end
	local coords = Kit.wallScreen(ctx, inside, CF(-47.25, FB + 6, -33) * ANG(0, -math.pi / 2, 0), 5, 3.2, "Coords")
	Kit.doc(coords, "Coordenadas", "66-B · 1100 · ANCLA\n\nUna lista de sitios de Valmar con una chincheta cada uno. Todas las chinchetas forman una flecha que apunta a… la casa de al lado.", "CosmeCoordenadas")
	-- Mesa con el diario de Cosme
	local f = Kit.furn(ctx, inside, rgb(50, 36, 60))
	Furniture.desk(f, Kit.at(ctx, -46.4, FB, -36, -90), { Width = 5, Computer = false, Chair = true }, inside)
	local journal = Kit.deco(ctx, inside, "Diario", V(1.1, 0.3, 1.5), CF(-46.4, FB + 3.17, -35.2) * ANG(0, 0.3, 0), rgb(110, 40, 40), M.Leather, nil, true)
	Kit.doc(journal, "Diario de Cosme", "«Día 4.017. La grieta crece. Cósimo sigue al otro lado y sigue hablando de la Gran Fusión: unir su Valmar con la nuestra. Si lo consigue, habrá dos de todo. Dos veces tú. Dos veces yo. Y solo un batido de apio.\n\nSi la criatura de al lado encuentra esta habitación: no tengas miedo. Lee todo. Y luego ven a buscarme.»", "CosmeDiario")
	Props.make(ctx, inside, "Lamp", CF(-46.8, FB + 3.02, -37.6))
	Props.make(ctx, inside, "Papers", CF(-46, FB + 3.02, -37))
	-- Cosas que flotan y setas que brillan
	local cube = Kit.neon(ctx, inside, "CuboFlotante", V(1.2, 1.2, 1.2), CF(-35.5, FB + 6, -38) * ANG(0.6, 0.6, 0), RUNE, 0.2)
	Kit.anomaly(cube)
	Kit.spin(cube, 0.15, "Y")
	Kit.fx(cube, "Dust", 6)
	for _, p in { { -47, -45 }, { -31.5, -45 }, { -47, -26 } } do
		for k = 0, 2 do
			Kit.cyl(ctx, inside, "Pie", 0.6 + k * 0.3, 0.2, CF(p[1] + k * 0.4, FB + 0.3 + k * 0.15, p[2]), rgb(220, 220, 240), M.SmoothPlastic)
			Kit.ball(ctx, inside, "Seta", 0.6 + k * 0.2, CF(p[1] + k * 0.4, FB + 0.7 + k * 0.3, p[2]), C.Cyan, M.Neon, 0.2)
		end
	end
	local alert = Kit.wallScreen(ctx, inside, CF(-39, FB + 9.5, -24.65), 4, 1.6, "Text", "SI LEES ESTO, YA SABES DEMASIADO")
	alert.Name = "Aviso"
	return m
end

return SecretRoom
