-- StoryCreatures: las CRIATURAS de las escenas de la historia. Mismo motor que los actores (un
-- personaje R15 que anda, mira, siente y gesticula: server/LifeStory/StageActors + ActorLife), con
-- OTRA PIEL: tamaño (agrandado o encogido), colores, brillo y piezas extra soldadas (antenas, cola,
-- cuernos, ojos grandes…). Datos puros (los comprueba scripts/test-scenes.luau).
--
--   Criatura = {
--     Name     nombre que se ve
--     Scale    tamaño (1 = persona; 0.4 = mascota; 2.5 = gigante)
--     Skin/Shirt/Pants  colores del cuerpo (todo igual = criatura «de una pieza»)
--     Material material del cuerpo (Neon brilla; SmoothPlastic = juguete…)
--     HideHuman  true: el cuerpo de persona no se ve (solo las piezas extra) — como el disfraz de
--              gallina de Kit/GallinaGigante
--     Costume  disfraz hecho por otro módulo (p. ej. "GallinaGigante": se reutiliza su .costume)
--     Glow     color de brillo (Highlight + luz)
--     Parts    piezas extra: { Name, Shape = "Ball"|"Block"|"Cylinder"|"Wedge", Size = {x,y,z},
--              Attach = "Head"|"UpperTorso"|"LowerTorso"|"HumanoidRootPart"|…,
--              Offset = { x, y, z, rx?, ry?, rz? } (studs y grados, en los ejes de la pieza a la que va),
--              Color = {r,g,b}, Material?, Light? = rango }
--     Voice    sonidos de la criatura: { Id = "rbxasset://…", Pitch }
--     WalkSpeed  velocidad al andar (antes de la emoción)
--   }

local StoryCreatures = {}

export type PartSpec = { [string]: any }
export type Creature = { [string]: any }

local SHAPES = { Ball = true, Block = true, Cylinder = true, Wedge = true }
StoryCreatures.Shapes = SHAPES
StoryCreatures.AttachTo = {
	Head = true,
	UpperTorso = true,
	LowerTorso = true,
	HumanoidRootPart = true,
	LeftHand = true,
	RightHand = true,
	LeftFoot = true,
	RightFoot = true,
}

StoryCreatures.List = {
	-- Chispa: lo que trajo la estrella fugaz verde de la Grieta (Saga_02). Pequeña, verde, brillante,
	-- con dos antenas y ojos enormes. Asustadiza. Se queda a vivir en el cráter del parque.
	Chispa = {
		Name = "Chispa",
		Scale = 0.42,
		Skin = { 110, 235, 150 },
		Shirt = { 90, 210, 130 },
		Pants = { 70, 180, 110 },
		Material = "SmoothPlastic",
		Glow = { 120, 255, 170 },
		WalkSpeed = 15,
		Voice = { Id = "rbxasset://sounds/electronicpingshort.wav", Pitch = 2.2 },
		Parts = {
			{ Name = "AntenaI", Shape = "Cylinder", Size = { 1.1, 0.12, 0.12 }, Attach = "Head", Offset = { -0.3, 0.95, 0, 0, 0, 80 }, Color = { 90, 210, 130 } },
			{ Name = "AntenaD", Shape = "Cylinder", Size = { 1.1, 0.12, 0.12 }, Attach = "Head", Offset = { 0.3, 0.95, 0, 0, 0, 100 }, Color = { 90, 210, 130 } },
			{ Name = "PuntaI", Shape = "Ball", Size = { 0.32, 0.32, 0.32 }, Attach = "Head", Offset = { -0.4, 1.5, 0 }, Color = { 200, 255, 120 }, Material = "Neon", Light = 6 },
			{ Name = "PuntaD", Shape = "Ball", Size = { 0.32, 0.32, 0.32 }, Attach = "Head", Offset = { 0.4, 1.5, 0 }, Color = { 200, 255, 120 }, Material = "Neon" },
			{ Name = "OjoI", Shape = "Ball", Size = { 0.42, 0.42, 0.2 }, Attach = "Head", Offset = { -0.25, 0.12, -0.55 }, Color = { 250, 250, 250 } },
			{ Name = "OjoD", Shape = "Ball", Size = { 0.42, 0.42, 0.2 }, Attach = "Head", Offset = { 0.25, 0.12, -0.55 }, Color = { 250, 250, 250 } },
			{ Name = "PupilaI", Shape = "Ball", Size = { 0.2, 0.2, 0.1 }, Attach = "Head", Offset = { -0.25, 0.1, -0.64 }, Color = { 20, 30, 25 } },
			{ Name = "PupilaD", Shape = "Ball", Size = { 0.2, 0.2, 0.1 }, Attach = "Head", Offset = { 0.25, 0.1, -0.64 }, Color = { 20, 30, 25 } },
			{ Name = "Cola", Shape = "Cylinder", Size = { 1.4, 0.18, 0.18 }, Attach = "LowerTorso", Offset = { 0, -0.1, 0.7, 0, 90, 30 }, Color = { 90, 210, 130 } },
		},
	},
	-- Sombra gigante: un ser de la Grieta, oscuro y enorme (rig AGRANDADO). Para los actos de la saga.
	SombraGigante = {
		Name = "La Sombra",
		Scale = 2.6,
		Skin = { 24, 22, 34 },
		Shirt = { 18, 16, 28 },
		Pants = { 14, 12, 22 },
		Material = "SmoothPlastic",
		Glow = { 140, 60, 255 },
		WalkSpeed = 10,
		Voice = { Id = "rbxasset://sounds/collide.wav", Pitch = 0.5 },
		Parts = {
			{ Name = "OjoI", Shape = "Ball", Size = { 0.25, 0.12, 0.1 }, Attach = "Head", Offset = { -0.22, 0.1, -0.58 }, Color = { 200, 120, 255 }, Material = "Neon" },
			{ Name = "OjoD", Shape = "Ball", Size = { 0.25, 0.12, 0.1 }, Attach = "Head", Offset = { 0.22, 0.1, -0.58 }, Color = { 200, 120, 255 }, Material = "Neon", Light = 10 },
			{ Name = "CuernoI", Shape = "Wedge", Size = { 0.2, 0.7, 0.3 }, Attach = "Head", Offset = { -0.4, 0.75, 0, 0, 0, 15 }, Color = { 30, 26, 40 } },
			{ Name = "CuernoD", Shape = "Wedge", Size = { 0.2, 0.7, 0.3 }, Attach = "Head", Offset = { 0.4, 0.75, 0, 0, 0, -15 }, Color = { 30, 26, 40 } },
		},
	},
	-- Duende de la Grieta: ENCOGIDO (0,3), para escenas de cosas pequeñas que se cuelan de otra dimensión
	Duende = {
		Name = "Duende",
		Scale = 0.3,
		Skin = { 255, 190, 120 },
		Shirt = { 80, 160, 90 },
		Pants = { 120, 80, 50 },
		WalkSpeed = 12,
		Voice = { Id = "rbxasset://sounds/electronicpingshort.wav", Pitch = 1.8 },
		Parts = {
			{ Name = "Gorro", Shape = "Wedge", Size = { 1.1, 1.3, 1.1 }, Attach = "Head", Offset = { 0, 0.95, 0 }, Color = { 200, 40, 40 } },
		},
	},
} :: { [string]: Creature }

function StoryCreatures.get(id: any): Creature?
	return if type(id) == "string" then StoryCreatures.List[id] else nil
end

function StoryCreatures.names(): { [string]: boolean }
	local set = {}
	for id in StoryCreatures.List do
		set[id] = true
	end
	return set
end

function StoryCreatures.rgb(c: { number }?): Color3?
	if type(c) ~= "table" then
		return nil
	end
	return Color3.fromRGB(c[1] or 0, c[2] or 0, c[3] or 0)
end

-- Desplazamiento de una pieza extra en los ejes de la pieza a la que va (escala 1)
function StoryCreatures.offsetOf(spec: PartSpec, scale: number?): CFrame
	local o = spec.Offset or {}
	local k = scale or 1
	return CFrame.new((o[1] or 0) * k, (o[2] or 0) * k, (o[3] or 0) * k) * CFrame.Angles(math.rad(o[4] or 0), math.rad(o[5] or 0), math.rad(o[6] or 0))
end

-- Errores de una criatura (pruebas)
function StoryCreatures.check(id: string, c: Creature): { string }
	local errors = {}
	local function err(fmt: string, ...)
		table.insert(errors, ("criatura %s: " .. fmt):format(id, ...))
	end
	if type(c.Scale) ~= "number" or c.Scale < 0.1 or c.Scale > 8 then
		err("escala fuera de rango (%s)", tostring(c.Scale))
	end
	if type(c.Name) ~= "string" then
		err("sin nombre")
	end
	local names = {}
	for i, p in c.Parts or {} do
		if not SHAPES[p.Shape] then
			err("pieza %d: forma desconocida '%s'", i, tostring(p.Shape))
		end
		if not StoryCreatures.AttachTo[p.Attach] then
			err("pieza %d: va pegada a algo que no existe '%s'", i, tostring(p.Attach))
		end
		if type(p.Size) ~= "table" or #p.Size ~= 3 then
			err("pieza %d: tamaño {x,y,z}", i)
		end
		if p.Name and names[p.Name] then
			err("pieza repetida '%s'", p.Name)
		end
		names[p.Name or i] = true
	end
	if #(c.Parts or {}) > 40 then
		err("demasiadas piezas (%d > 40)", #c.Parts)
	end
	return errors
end

return StoryCreatures
