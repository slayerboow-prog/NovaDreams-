-- Pets: perros y gatos de Valmar (una sola fuente para el servidor, el cliente y las pruebas).
--
-- Cómo es la ciudad ahora (antes había 2 perros y 2 gatos SUELTOS alrededor de cada jugador, en
-- cualquier sitio: metro, dentro de casas y tiendas…; ver docs en el informe):
--   * Casi todos los perros van PASEANDO con su dueño (peatones de Controllers/Ambient y gente de los
--     parques de CrowdService / PlaceLifeService), con la correa a la vista (Pets.leash: un Beam de la
--     mano al collar).
--   * Gatos de casa: uno como mucho por casa, en la puerta o el jardín de su casa (Pets.HouseCats), y
--     pocos en toda la isla. Nunca entran en tiendas, metro, hospital…
--   * Vagabundos: muy pocos (Pets.Strays: 3 en toda la ciudad) en sitios con sentido: el patio de la
--     protectora, el callejón de al lado y un parque. Si les llamas te siguen; tras un rato, «Adoptar».
--   * Ningún animal suelto bajo tierra (metro) ni en las salas de dentro de los edificios (en el cielo):
--     Pets.looseSpotOk.
--   * Adopción en la Protectora de Valmar (Kit/AnimalKit, PetService): eliges perro o gato, raza y
--     color, le pones nombre (NameFilter + filtro de Roblox) y es tu mascota: te sigue, se sienta, la
--     llamas, se queda en casa y se guarda en tu partida (data.Pets). Gratis, con donación opcional.
--
-- Funciones puras (sin Roblox salvo Vector3): las prueban scripts/test-animals.luau y test-adoption.luau.

-- (por ReplicatedStorage y no por script.Parent: así también lo carga el constructor del mapa)
local NameFilter = require(game:GetService("ReplicatedStorage").Shared.NameFilter)

local Pets = {}

Pets.MAX_OWNED = 3 -- mascotas como mucho a la vez
Pets.NAME_MIN = 3
Pets.NAME_MAX = 16
Pets.FEE = 0 -- adoptar es gratis…
Pets.DONATIONS = { 0, 20, 50 } -- …y se puede dejar una donación a la protectora
Pets.STRAY_FOLLOW_TIME = 12 -- segundos que te tiene que seguir un vagabundo antes de poder adoptarlo
Pets.STRAY_CALL_WINDOW = 300 -- tras llamarle, cuánto tiempo vale para adoptarlo
Pets.STRAY_BACK = 1800 -- tras adoptar uno, llega otro a ese sitio a la media hora (por servidor)
Pets.WALKER_SHARE = 0.06 -- parte de los peatones del cliente que pasean perro (antes 0,11)

export type Pet = { Id: string, Kind: string, Breed: string, Coat: number, Name: string, Since: number, Stray: boolean? }
export type Look = { Coat: { number }, Accent: { number }?, Scale: number, Spots: boolean?, Fluffy: boolean? }

Pets.Kinds = {
	Perro = { Name = "Perro", Icon = "🐶", Voice = "¡Guau!" },
	Gato = { Name = "Gato", Icon = "🐱", Voice = "¡Miau!" },
}
Pets.KindOrder = { "Perro", "Gato" }

-- Razas y colores (Coats: { nombre, color, color de detalle? }). Scale: tamaño respecto al de siempre
Pets.Breeds = {
	Perro = {
		{ Id = "Mestizo", Name = "Mestizo", Text = "Listo, cariñoso y agradecido. El que más espera.", Scale = 1,
			Coats = { { "Canela", { 200, 150, 90 } }, { "Negro", { 52, 46, 42 } }, { "Blanco", { 232, 226, 212 } } } },
		{ Id = "Labrador", Name = "Labrador", Text = "Tranquilo y bueno con todo el mundo.", Scale = 1.15,
			Coats = { { "Dorado", { 222, 184, 120 } }, { "Chocolate", { 105, 68, 44 } }, { "Negro", { 34, 32, 30 } } } },
		{ Id = "Pastor", Name = "Pastor alemán", Text = "Fiel y protector. Necesita pasear mucho.", Scale = 1.2,
			Coats = { { "Fuego y negro", { 176, 118, 62 }, { 38, 32, 28 } } } },
		{ Id = "Dalmata", Name = "Dálmata", Text = "Lleno de energía (y de manchas).", Scale = 1.1, Spots = true,
			Coats = { { "Blanco con manchas", { 242, 240, 234 }, { 30, 30, 32 } } } },
		{ Id = "Beagle", Name = "Beagle", Text = "Curioso: lo huele todo.", Scale = 0.85,
			Coats = { { "Tricolor", { 240, 236, 226 }, { 150, 96, 52 } } } },
		{ Id = "Chihuahua", Name = "Chihuahua", Text = "Pequeñito y muy valiente.", Scale = 0.6,
			Coats = { { "Crema", { 232, 200, 150 } }, { "Negro", { 40, 36, 34 } } } },
	},
	Gato = {
		{ Id = "Comun", Name = "Común europeo", Text = "Independiente pero mimoso.", Scale = 1,
			Coats = { { "Atigrado naranja", { 230, 140, 50 }, { 180, 96, 34 } }, { "Gris", { 150, 150, 156 } }, { "Blanco y negro", { 240, 238, 232 }, { 36, 36, 40 } } } },
		{ Id = "Siames", Name = "Siamés", Text = "Charlatán y de ojos azules.", Scale = 1,
			Coats = { { "Crema", { 236, 222, 196 }, { 80, 60, 50 } } } },
		{ Id = "Negro", Name = "Gato negro", Text = "Da buena suerte (aunque digan lo contrario).", Scale = 1,
			Coats = { { "Negro", { 34, 34, 38 } } } },
		{ Id = "Persa", Name = "Persa", Text = "Peludo y tranquilo. Le encanta el sofá.", Scale = 1.1, Fluffy = true,
			Coats = { { "Blanco", { 246, 244, 240 } }, { "Gris azulado", { 140, 150, 165 } } } },
	},
}

-- Raza por id
function Pets.breed(kind: string, breedId: any): { [string]: any }?
	for _, b in Pets.Breeds[kind] or {} do
		if b.Id == breedId then
			return b
		end
	end
	return nil
end

-- Aspecto (para AnimalPose.build): colores en { r, g, b } (0-255) y tamaño
function Pets.look(kind: string, breedId: any, coat: any): Look?
	local b = Pets.breed(kind, breedId)
	if not b then
		return nil
	end
	local c = b.Coats[math.clamp(math.floor(tonumber(coat) or 1), 1, #b.Coats)]
	return { Coat = c[2], Accent = c[3], Scale = b.Scale or 1, Spots = b.Spots, Fluffy = b.Fluffy }
end

-- Nombre de raza y color para enseñar ("Labrador dorado")
function Pets.describe(kind: string, breedId: any, coat: any): string
	local b = Pets.breed(kind, breedId)
	if not b then
		return (Pets.Kinds[kind] and Pets.Kinds[kind].Name) or "Mascota"
	end
	local c = b.Coats[math.clamp(math.floor(tonumber(coat) or 1), 1, #b.Coats)]
	return ("%s %s"):format(b.Name, string.lower(c[1]))
end

---------------------------------------------------------------------
-- Adopción
---------------------------------------------------------------------

-- ¿Vale este nombre de mascota? (filtro propio de palabrotas y trucos; el de Roblox va aparte, en
-- el servidor). Devuelve (vale, motivo si no, nombre limpio)
function Pets.checkName(text: any): (boolean, string?, string)
	local ok, why, name = NameFilter.check(text)
	if not ok then
		return false, why, name
	end
	local length = utf8.len(name) or #name
	if length > Pets.NAME_MAX then
		return false, ("El nombre es muy largo (máximo %d letras)."):format(Pets.NAME_MAX), name
	end
	if length < Pets.NAME_MIN then
		return false, ("El nombre es muy corto (mínimo %d letras)."):format(Pets.NAME_MIN), name
	end
	return true, nil, name
end

-- ¿Puede adoptar uno más? (owned: sus mascotas)
function Pets.canAdopt(owned: { Pet }, kind: any, breedId: any, coat: any): (boolean, string?)
	if type(kind) ~= "string" or not Pets.Kinds[kind] then
		return false, "Elige perro o gato."
	end
	local b = Pets.breed(kind, breedId)
	if not b then
		return false, "Esa raza no está en la protectora."
	end
	local n = tonumber(coat)
	if not n or n ~= math.floor(n) or n < 1 or n > #b.Coats then
		return false, "Elige un color."
	end
	if #owned >= Pets.MAX_OWNED then
		return false, ("Ya cuidas de %d mascotas: es el máximo."):format(Pets.MAX_OWNED)
	end
	return true, nil
end

-- Id nuevo que no tenga ninguna de sus mascotas
function Pets.newId(owned: { Pet }): string
	local used = {}
	for _, p in owned do
		used[p.Id] = true
	end
	local n = #owned + 1
	while used["m" .. n] do
		n += 1
	end
	return "m" .. n
end

-- Adopta (ya comprobado el nombre): añade la mascota a la lista y la devuelve
function Pets.adopt(owned: { Pet }, kind: string, breedId: string, coat: number, name: string, now: number, stray: boolean?): (Pet?, string?)
	local ok, why = Pets.canAdopt(owned, kind, breedId, coat)
	if not ok then
		return nil, why
	end
	local okName, whyName, clean = Pets.checkName(name)
	if not okName then
		return nil, whyName
	end
	local pet: Pet = { Id = Pets.newId(owned), Kind = kind, Breed = breedId, Coat = coat, Name = clean, Since = math.floor(now), Stray = if stray then true else nil }
	table.insert(owned, pet)
	return pet, nil
end

-- La lista guardada, revisada (partidas viejas o datos rotos): solo mascotas válidas, como mucho MAX_OWNED,
-- sin ids repetidos. Devuelve una lista nueva
function Pets.sanitize(raw: any): { Pet }
	local out: { Pet } = {}
	local seen = {}
	if type(raw) ~= "table" then
		return out
	end
	for _, p in raw do
		if #out >= Pets.MAX_OWNED then
			break
		end
		if type(p) ~= "table" or type(p.Id) ~= "string" or seen[p.Id] then
			continue
		end
		if not Pets.Kinds[p.Kind] or not Pets.breed(p.Kind, p.Breed) then
			continue
		end
		local okName, _, clean = Pets.checkName(p.Name)
		if not okName then
			continue
		end
		local b = Pets.breed(p.Kind, p.Breed) :: any
		local coat = math.clamp(math.floor(tonumber(p.Coat) or 1), 1, #b.Coats)
		seen[p.Id] = true
		table.insert(out, { Id = p.Id, Kind = p.Kind, Breed = p.Breed, Coat = coat, Name = clean, Since = math.floor(tonumber(p.Since) or 0), Stray = if p.Stray == true then true else nil })
	end
	return out
end

function Pets.find(owned: { Pet }, id: any): (Pet?, number?)
	for i, p in owned do
		if p.Id == id then
			return p, i
		end
	end
	return nil, nil
end

---------------------------------------------------------------------
-- Tu mascota contigo: seguirte, sentarse, esperarte en la puerta
---------------------------------------------------------------------

Pets.Follow = {
	Behind = 3.4, -- va un poco por detrás…
	Side = 2.2, -- …y a tu lado
	Stop = 1.1, -- más cerca que esto de su sitio, se para
	Walk = 6, -- velocidad andando
	Run = 22, -- corriendo para alcanzarte
	Teleport = 80, -- más lejos que esto (te has ido en coche, has viajado…), aparece a tu lado
}

-- ¿Dónde está su dueño? "hidden" = en el metro (bajo tierra) o en una sala de dentro de un edificio
-- (las salas están en el cielo): la mascota no va; "indoors" = bajo techo (tienda, portal…): te espera
-- fuera; "outside" = en la calle
function Pets.ownerPlace(y: number, roofed: boolean): string
	if y < -12 or y > 3000 then
		return "hidden"
	end
	return if roofed then "indoors" else "outside"
end

-- Un sitio suelto (vagabundo, gato de casa, animal de granja) no puede estar bajo tierra ni en el cielo
function Pets.looseSpotOk(y: number): boolean
	return y > -6 and y < 400
end

-- Sitio al que va la mascota: detrás y a un lado de su dueño (look = hacia dónde mira)
function Pets.heel(ownerPos: Vector3, look: Vector3): Vector3
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.05 then flat.Unit else Vector3.new(0, 0, -1)
	local side = Vector3.new(-flat.Z, 0, flat.X)
	return ownerPos - flat * Pets.Follow.Behind + side * Pets.Follow.Side
end

-- Sin suelo visible bajo el sitio donde tiene que ir: a la altura de los pies de su dueño (la raíz de un
-- personaje va unos 3 studs por encima del suelo), nunca a la altura que tuviera (se quedaba en el aire)
Pets.OwnerHip = 3
function Pets.fallbackGoal(target: Vector3, ownerPos: Vector3, stand: number): Vector3
	return Vector3.new(target.X, ownerPos.Y - Pets.OwnerHip + stand, target.Z)
end

-- Perro de bloques pegado a un paseante (PlaceLifeService): dónde va cada pieza respecto a la raíz del
-- dueño, con feet = la altura de sus pies respecto a la raíz (-(HipHeight + media raíz)). Las alturas
-- salen de los pies: antes iban a ojo desde la raíz y el perro, sin patas, quedaba casi un stud por
-- encima de la acera. Las patas (0,5 de alto) apoyan en el suelo.
Pets.WalkerDogLeg = 0.5
function Pets.walkerDog(feet: number): { [string]: CFrame }
	local leg = Pets.WalkerDogLeg
	local body = feet + leg + 0.45 -- (cuerpo de 0,9: la tripa justo encima de las patas)
	return {
		PerroCuerpo = CFrame.new(2.2, body, -1),
		PerroCabeza = CFrame.new(2.2, body + 0.6, -2.3),
		PerroCola = CFrame.new(2.2, body + 0.5, 0.2) * CFrame.Angles(math.rad(35), 0, 0),
		PerroPataDI = CFrame.new(1.9, feet + leg / 2, -1.7),
		PerroPataDD = CFrame.new(2.5, feet + leg / 2, -1.7),
		PerroPataTI = CFrame.new(1.9, feet + leg / 2, -0.3),
		PerroPataTD = CFrame.new(2.5, feet + leg / 2, -0.3),
	}
end

export type Follower = { Pos: Vector3, Speed: number, Moving: boolean, Facing: Vector3 }

-- Un paso de seguir: anda (o corre si se queda atrás) hacia "target". Devuelve "teleport", "walk" o "idle"
function Pets.stepFollow(f: Follower, target: Vector3, dt: number): string
	local F = Pets.Follow
	local delta = Vector3.new(target.X - f.Pos.X, 0, target.Z - f.Pos.Z)
	local d = delta.Magnitude
	if d > F.Teleport then
		f.Pos = target
		f.Speed = 0
		f.Moving = false
		return "teleport"
	end
	if d < F.Stop then
		f.Speed = math.max(0, f.Speed - 30 * dt)
		f.Moving = false
		return "idle"
	end
	local want = math.clamp(d * 1.6, F.Walk * 0.7, F.Run)
	-- (acelera y frena suave: sin tirones)
	f.Speed += math.clamp(want - f.Speed, -40 * dt, 30 * dt)
	local step = math.min(d, f.Speed * dt)
	f.Pos = Vector3.new(f.Pos.X + delta.X / d * step, f.Pos.Y + (target.Y - f.Pos.Y) * math.min(1, dt * 6), f.Pos.Z + delta.Z / d * step)
	f.Facing = delta / d
	f.Moving = true
	return "walk"
end

---------------------------------------------------------------------
-- Pocos animales sueltos, y en su sitio
---------------------------------------------------------------------

-- Vagabundos (3 en toda la ciudad). At = { x, z } (la altura la busca el cliente con un rayo).
-- Radius = cuánto se alejan de su sitio
Pets.Strays = {
	{ Id = "Canela", Kind = "Perro", Breed = "Mestizo", Coat = 1, At = { -216, -345 }, Radius = 4, Where = "Puerta de la protectora" },
	{ Id = "Tizon", Kind = "Gato", Breed = "Negro", Coat = 1, At = { -292, -316 }, Radius = 3, Where = "Callejón de la protectora" },
	{ Id = "Lucas", Kind = "Perro", Breed = "Beagle", Coat = 1, At = { 122, -470 }, Radius = 10, Where = "Parque del Distrito Financiero" },
}
Pets.STRAY_MAX = 4 -- (prueba: nunca más que esto)

function Pets.stray(id: any): { [string]: any }?
	for _, s in Pets.Strays do
		if s.Id == id then
			return s
		end
	end
	return nil
end

-- Gatos de casa: uno en la puerta o el jardín de algunas casas (nunca más de uno por casa).
-- { x, z, hacia dónde mira (grados) }. Salen de las casas de verdad del mapa (Casa/Villa con felpudo).
Pets.HouseCats = {
	{ 576.7, -2423.9, -180 },
	{ -1820.8, 2856.3, -180 },
	{ 2920.2, 1262.8, 130 },
	{ -3326.7, -1090.1, 0 },
	{ 3274.0, -1270.3, -138 },
	{ -1407.7, 452.5, -90 },
	{ -3326.7, 1409.9, 0 },
	{ -1675.4, -2342.3, 0 },
	{ -379.8, 2062.4, 130 },
	{ -1926.0, -907.7, -180 },
	{ -2598.0, 157.7, 0 },
	{ -590.7, -2590.1, 0 },
	{ -1438.8, 1893.7, 0 },
	{ -3769.3, -159.9, -180 },
}
-- Aspecto de cada gato de casa (siempre el mismo en cada casa)
function Pets.houseCatLook(index: number): (string, number)
	local breeds = { "Comun", "Comun", "Siames", "Negro", "Persa", "Comun" }
	local id = breeds[(index - 1) % #breeds + 1]
	local b = Pets.breed("Gato", id) :: any
	return id, (index * 7) % #b.Coats + 1
end
Pets.HOUSE_CAT_RADIUS = 90 -- se ven si estás a menos de esto
Pets.HOUSE_CATS_VISIBLE = 2 -- y como mucho estos a la vez

-- Animales de la protectora (en sus jaulas, para verlos al elegir): { tipo, raza, color }
Pets.ShelterResidents = {
	{ "Perro", "Labrador", 1 },
	{ "Perro", "Pastor", 1 },
	{ "Perro", "Mestizo", 2 },
	{ "Perro", "Dalmata", 1 },
	{ "Gato", "Siames", 1 },
	{ "Gato", "Comun", 1 },
}

---------------------------------------------------------------------
-- Correa: un Beam de la mano del dueño al collar del perro (se ve siempre, cuelga un poco)
---------------------------------------------------------------------
function Pets.leash(hand: BasePart, handOffset: CFrame, collar: BasePart, collarOffset: CFrame, color: Color3?): Beam
	local a0 = Instance.new("Attachment")
	a0.Name = "CorreaMano"
	a0.CFrame = handOffset
	a0.Parent = hand
	local a1 = Instance.new("Attachment")
	a1.Name = "CorreaCollar"
	a1.CFrame = collarOffset
	a1.Parent = collar
	local beam = Instance.new("Beam")
	beam.Name = "Correa"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.12
	beam.Width1 = 0.12
	beam.FaceCamera = true
	beam.Segments = 8
	beam.CurveSize0 = -0.6 -- (cuelga un poco)
	beam.CurveSize1 = 0.6
	beam.LightInfluence = 1
	beam.Color = ColorSequence.new(color or Color3.fromRGB(200, 40, 40))
	beam.Parent = hand
	return beam
end

return Pets
