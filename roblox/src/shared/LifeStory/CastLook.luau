-- CastLook: caras con textura, ropa con textura y pelo con mechones para TODO el reparto de la historia
-- (pase «AAA» de oct 2026: docs/personajes/auditoria-texturas.md). Datos y aplicación; las imágenes las
-- dibuja scripts/personajes/gen.py (a partir de scripts/personajes/export.luau, que lee ESTE módulo) y
-- las sube scripts/upload-personajes.sh, que escribe shared/PersonajesTextureIds.
--
--   CastLook.spec(id, variante?)   la ficha de aspecto de un personaje: Key (la de sus caras), Kind
--                                  ("Human", "Robot", "Mask", "Holo", "Hondario", "Own" = Cosme con su
--                                  módulo, "Creature" = sin textura), Faces (las expresiones que tiene),
--                                  Face (rasgos para dibujarla), Shirt/Pants (estilo de ropa) y Hair.
--                                  `variante`: la casa decide quién es Familia (NPC.MAMA / NPC.PAPA) y Abu
--                                  (NPC.ABU_ROSA / NPC.ABU_TOMAS). Hondarios de Nácara: id "Nacara:Ilun".
--   CastLook.apply(model, id, variante?, look?)  lo viste (lo llama Npc.dress con look.Id). SOLO pone lo
--                                  que ya esté subido: sin ids se queda como estaba (colores lisos, cara
--                                  por defecto). Nunca dos caras: la cara va por shared/FaceKit.
--   CastLook.faceFor(emocion, mood) qué expresión toca (Neutral, Happy, Sad, Angry, Scared).
--   CastLook.express(model, emocion, segundos) / CastLook.rest(model) / CastLook.refresh(model)
--                                  como CosmeLook (lo llaman ActorLife.speak, el Mood de la escena y el
--                                  servidor al pasar los Decal a imagen).
--
-- Ropa: plantillas CLÁSICAS (Shirt/Pants, la manera nativa de Roblox que va bien en móvil) COMPARTIDAS
-- por estilo y casi blancas: cada personaje las tiñe con su color del reparto (Clothing.Color3). Así hay
-- ~15 imágenes de ropa para todo el reparto (atlas compartido) en vez de una por persona. La piel nunca
-- lleva textura (solo color): ninguna imagen de cuerpo sin ropa.

local CastLook = {}

CastLook.TAG = "CastLook"
CastLook.ATTR_KEY = "CastFaceKey"
CastLook.ATTR_FACE = "CastFace"

-- Expresiones. Talk es el fotograma de boca abierta al hablar (FaceKit.flap), no una emoción.
CastLook.Full = { "Neutral", "Happy", "Talk", "Sad", "Angry", "Scared" }
CastLook.Basic = { "Neutral", "Happy", "Talk" }

-- Estilos de ropa (plantillas compartidas, teñidas). Short = manga corta: el antebrazo es de piel.
CastLook.ShirtStyles = {
	Camiseta = { Short = true, Label = "camiseta de algodón" },
	Sudadera = { Label = "sudadera con capucha y bolsillo canguro" },
	Camisa = { Label = "camisa con cuello y botones" },
	Chaqueta = { Label = "chaqueta abierta sobre camiseta" },
	Rebeca = { Label = "rebeca de punto con botones" },
	Uniforme = { Label = "guerrera de uniforme con bolsillos y hombreras" },
	Bata = { Label = "bata larga de trabajo" },
	Delantal = { Short = true, Label = "camiseta con delantal" },
	Mono = { Label = "mono de trabajo (parte de arriba)" },
}
CastLook.PantsStyles = {
	Vaqueros = { Label = "vaqueros con costuras y remaches" },
	Pantalon = { Label = "pantalón de pinzas" },
	Cargo = { Label = "pantalón cargo con bolsillos" },
	Chandal = { Label = "pantalón de chándal con franja" },
	Mono = { Label = "mono de trabajo (piernas)" },
}

-- Nombres de las imágenes (assets/personajes/…/<nombre>.png → shared/PersonajesTextureIds)
function CastLook.faceFile(key: string, expression: string): string
	return ("pj_cara_%s_%s"):format(string.lower(key), string.lower(expression))
end
function CastLook.shirtFile(style: string): string
	return "pj_ropa_" .. string.lower(style)
end
function CastLook.pantsFile(style: string): string
	return "pj_pantalon_" .. string.lower(style)
end
CastLook.HAIR_FILE = "pj_pelo"

---------------------------------------------------------------------
-- Quién es quién
---------------------------------------------------------------------

local function Cast(): any
	return require(script.Parent.Cast)
end

-- Reparto con TODAS las expresiones (el principal y los de cada etapa/planeta con peso en la historia)
local FULL: { [string]: boolean } = {
	Familia_Mama = true, Familia_Papa = true, Abu_Rosa = true, Abu_Tomas = true,
	Lucia = true, Ramon = true, Marta = true, Marisa = true, Paula = true, Julian = true, Andres = true,
	Javier = true, Carmen = true, Beltran = true, Pip = true, Cosimo = true,
	GeneralCorvo = true, TobiRenn = true, DoctoraFermina = true, MadreHollin = true, Brasa = true, IngenieroOrsi = true,
	GaloPadre = true, SargentoMurria = true, ErnestoPanadero = true, EscribanoLumo = true, CapitanaFerra = true,
}

-- Personas con brillo (Glow) que son PERSONAS (el resto con Glow son criaturas: sin textura)
local GLOW_HUMAN: { [string]: string } = { Cosimo = "Human", TuMalvado = "Human", TuFuturo = "Human", Pip = "Robot", Varkun = "Mask", NILDA = "Holo" }

-- Papeles sin nombre: comparten caras por edad (arquetipos, como un atlas): Arq_<Edad>_<F|M>
local GENERIC: { [string]: boolean } = {
	Alumno1 = true, Alumno2 = true, Alumno3 = true, Alumno4 = true, Mayor1 = true, Mayor2 = true, Madre = true, Padre = true,
	Vecino = true, Paciente = true, Veterano = true, Delegada = true, PoliciaMilitar1 = true, PoliciaMilitar2 = true,
	PoliciaMilitar3 = true, SoldadoOvilla = true, RefugiadoMayor = true, Capataz = true,
}

local FEM_NAMES = { "^Doña", "^Señora", "^Abuela", "^Tía", "^La ", "^Una ", "Alumna", "Delegada", "Doctora", "Profesora", "Capitana", "Soldada", "Cobradora", "Niña", "Gnoma", "Madre ", "Agente Inés", "Chef Lola", "^Sofía", "^Irene", "^Julia$", "^Carla", "^Montse", "^Rocío", "^Alba", "^Candela", "^Funcionaria", "^Mara ", "^Luz$", "^Marisa", "^Brasa", "^Pía", "^Nina " }
local FEM_IDS: { [string]: boolean } = {
	Lucia = true, Marta = true, Marisa = true, Paula = true, Sara = true, Vega = true, Alex = true, Carmen = true, Leire = true,
	Nerea = true, Nuria = true, Lola = true, Beltran = true, Familia_Mama = true, Abu_Rosa = true, NILDA = true,
}
local MASC_IDS: { [string]: boolean } = { Familia_Papa = true, Abu_Tomas = true }

-- Rasgos a mano (de la Bio de cada uno). Glasses: "Round" | "Square"; Beard: "Stubble" | "Mustache" |
-- "Goatee" | "Full"; Freckles; Shirt/Pants: estilo de ropa.
local TRAITS: { [string]: { [string]: any } } = {
	Abu_Tomas = { Beard = "Mustache", Shirt = "Rebeca", Pants = "Pantalon" },
	Abu_Rosa = { Glasses = "Round", Shirt = "Rebeca", Pants = "Pantalon" },
	Familia_Mama = { Shirt = "Camisa", Pants = "Vaqueros" },
	Familia_Papa = { Beard = "Stubble", Shirt = "Camisa", Pants = "Vaqueros" },
	Lucia = { Shirt = "Rebeca", Pants = "Pantalon" },
	Ramon = { Beard = "Mustache", Shirt = "Mono", Pants = "Mono" },
	Marta = { Shirt = "Camisa", Pants = "Pantalon" },
	Marisa = { Glasses = "Round", Shirt = "Rebeca", Pants = "Pantalon" },
	Paula = { Freckles = true, Shirt = "Camisa", Pants = "Cargo" },
	Julian = { Beard = "Full", Shirt = "Camisa", Pants = "Vaqueros" },
	Andres = { Shirt = "Sudadera", Pants = "Chandal" },
	Javier = { Glasses = "Square", Beard = "Stubble", Shirt = "Chaqueta", Pants = "Pantalon" },
	Carmen = { Shirt = "Chaqueta", Pants = "Pantalon" },
	Beltran = { Glasses = "Square", Shirt = "Chaqueta", Pants = "Pantalon" },
	Nico = { Shirt = "Camiseta", Pants = "Chandal" },
	Sara = { Glasses = "Square", Shirt = "Camiseta", Pants = "Vaqueros" },
	Omar = { Shirt = "Sudadera", Pants = "Vaqueros" },
	Mateo = { Freckles = true },
	Dani = { Freckles = true, Shirt = "Camiseta", Pants = "Chandal" },
	Iker = { Glasses = "Round" },
	Alex = { Shirt = "Camiseta", Pants = "Chandal" },
	Vega = { Freckles = true },
	Leire = { Shirt = "Chaqueta", Pants = "Vaqueros" },
	Rayo = { Shirt = "Chaqueta", Pants = "Vaqueros" },
	Nuria = { Shirt = "Bata", Pants = "Pantalon" },
	Sofia = { Glasses = "Square", Shirt = "Bata", Pants = "Pantalon" },
	Lola = { Shirt = "Delantal", Pants = "Pantalon" },
	Tomas = { Beard = "Stubble", Shirt = "Mono", Pants = "Mono" },
	Irene = { Shirt = "Sudadera", Pants = "Chandal" },
	Toni = { Beard = "Goatee", Shirt = "Sudadera", Pants = "Vaqueros" },
	Ines = { Shirt = "Uniforme", Pants = "Cargo" },
	Ignacio = { Shirt = "Chaqueta", Pants = "Pantalon" },
	Montse = { Shirt = "Chaqueta", Pants = "Pantalon" },
	Cosimo = { Beard = "Goatee", Shirt = "Chaqueta", Pants = "Pantalon" },
	TuMalvado = { Beard = "Goatee", Shirt = "Chaqueta", Pants = "Pantalon" },
	TuFuturo = { Beard = "Stubble", Shirt = "Chaqueta", Pants = "Vaqueros" },
	Ivan = { Shirt = "Sudadera", Pants = "Vaqueros" },
	Candela = { Glasses = "Square", Shirt = "Camisa", Pants = "Pantalon" },
	Portero = { Glasses = "Round", Shirt = "Rebeca", Pants = "Pantalon" },
	Pip = { Shirt = "Chaqueta", Pants = "Pantalon" },
	Varkun = { Shirt = "Bata", Pants = "Pantalon" },
	-- Tefra (Bastión Ceniza): bufandas gastadas, uniformes, delantales
	DaliaRenn = { Shirt = "Uniforme", Pants = "Cargo" },
	GeneralCorvo = { Beard = "Stubble", Shirt = "Uniforme", Pants = "Cargo" },
	TobiRenn = { Shirt = "Uniforme", Pants = "Cargo" },
	DoctoraFermina = { Shirt = "Bata", Pants = "Pantalon" },
	MadreHollin = { Shirt = "Rebeca", Pants = "Pantalon" },
	Brasa = { Freckles = true, Shirt = "Sudadera", Pants = "Cargo" },
	IngenieroOrsi = { Glasses = "Square", Shirt = "Mono", Pants = "Mono" },
	GaloPadre = { Beard = "Full", Shirt = "Chaqueta", Pants = "Cargo" },
	SargentoMurria = { Beard = "Stubble", Shirt = "Uniforme", Pants = "Cargo" },
	ErnestoPanadero = { Beard = "Mustache", Shirt = "Delantal", Pants = "Pantalon" },
	EscribanoLumo = { Glasses = "Round", Beard = "Goatee", Shirt = "Rebeca", Pants = "Pantalon" },
	CapitanaFerra = { Shirt = "Uniforme", Pants = "Cargo" },
	Capataz = { Beard = "Stubble", Shirt = "Mono", Pants = "Mono" },
}

local UNIFORM_IDS = { "^Policia", "^Soldado", "^General", "^Sargento", "^Capitan", "^Comandante", "^Cobrador", "^Agente" }

-- Ojos: colores naturales (el iris lleva degradado y brillos al dibujarlo)
CastLook.EyeColors = {
	{ 92, 60, 38 }, -- marrón
	{ 60, 40, 28 }, -- marrón oscuro
	{ 120, 96, 52 }, -- avellana
	{ 70, 110, 70 }, -- verde
	{ 70, 110, 160 }, -- azul
	{ 100, 110, 120 }, -- gris
}

local function hash(s: string): number
	local h = 7
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % 1000003
	end
	return h
end

local function isFem(id: string, person: { [string]: any }): boolean
	if FEM_IDS[id] then
		return true
	end
	if MASC_IDS[id] then
		return false
	end
	if person.Voice == "Mujer" or person.Voice == "Rectora" then
		return true
	end
	if person.Voice == "Hombre" then
		return false
	end
	local name = type(person.Name) == "string" and person.Name or ""
	for _, pattern in FEM_NAMES do
		if string.find(name, pattern) then
			return true
		end
	end
	return false
end

local function ageOf(person: { [string]: any }): string
	if person.Kid then
		return "Kid"
	elseif person.Teen then
		return "Teen"
	elseif person.Old then
		return "Old"
	end
	return "Adult"
end

local function rgbOf(c: any): { number }?
	if typeof(c) == "Color3" then
		return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
	end
	return nil
end

local function uniformId(id: string): boolean
	for _, pattern in UNIFORM_IDS do
		if string.find(id, pattern) then
			return true
		end
	end
	return false
end

local function defaultShirt(id: string, person: { [string]: any }, age: string, fem: boolean): (string, string)
	if uniformId(id) then
		return "Uniforme", "Cargo"
	end
	local h = hash(id)
	if age == "Kid" or age == "Teen" then
		local shirt = if person.LongSleeves then "Sudadera" else "Camiseta"
		return shirt, if h % 3 == 0 then "Chandal" else "Vaqueros"
	end
	if age == "Old" then
		return if person.LongSleeves then (if fem then "Rebeca" else "Chaqueta") else "Camisa", "Pantalon"
	end
	if not person.LongSleeves then
		return "Camiseta", if h % 2 == 0 then "Vaqueros" else "Pantalon"
	end
	return if h % 2 == 0 then "Camisa" else "Chaqueta", if h % 3 == 0 then "Vaqueros" else "Pantalon"
end

export type Spec = {
	Id: string,
	Key: string,
	Kind: string,
	Name: string,
	Faces: { string },
	Face: { [string]: any },
	Shirt: string?,
	Pants: string?,
	Hair: boolean,
	Colors: { [string]: { number }? },
}

-- Hondarios de Nácara (shared/Sea/Nacara.People y Sea/Civ.People)
local function seaLists(): { { { [string]: any } } }
	local out = {}
	for _, name in { "Nacara", "Civ" } do
		local ok, list = pcall(function()
			return (require((script.Parent.Parent.Sea :: any)[name]) :: any).People
		end)
		if ok and type(list) == "table" then
			table.insert(out, list)
		end
	end
	return out
end

local function seaPerson(id: string): { [string]: any }?
	for _, list in seaLists() do
		for _, p in list do
			if p.Id == id then
				return p
			end
		end
	end
	return nil
end

local HONDARIA = { Oriana = true, Cantora = true, Farolera = true, Viajera = true, Maresa = true, Lia = true }

function CastLook.spec(id: string, variant: string?): Spec?
	if type(id) ~= "string" then
		return nil
	end
	-- Nácara
	local seaId = string.match(id, "^Nacara:(.+)$")
	if seaId then
		local p = seaPerson(seaId)
		if not p or not p.Look then
			return nil
		end
		local look = p.Look
		return {
			Id = id,
			Key = "Nacara_" .. seaId,
			Kind = "Hondario",
			Name = p.Name or seaId,
			Faces = CastLook.Basic,
			Face = {
				Age = "Adult",
				Fem = HONDARIA[seaId] == true or (type(p.Title) == "string" and string.sub(p.Title, -1) == "a"),
				Eye = 1 + hash(seaId) % #CastLook.EyeColors,
				Scales = rgbOf(look.Scales),
				Crest = rgbOf(look.Crest),
			},
			Shirt = nil, -- (la túnica y el peto los ponen sus piezas: NacaraService.dressHondario)
			Pants = nil,
			Hair = true,
			Colors = { Skin = rgbOf(look.Skin), Hair = rgbOf(look.Hair), Shirt = rgbOf(look.Tunic), Pants = rgbOf(look.Scales) },
		}
	end
	local person = Cast().People[id]
	if not person then
		return nil
	end
	local key = id
	if id == "Familia" then
		key = if variant == "NPC.PAPA" then "Familia_Papa" else "Familia_Mama"
	elseif id == "Abu" then
		key = if variant == "NPC.ABU_TOMAS" then "Abu_Tomas" else "Abu_Rosa"
	end
	local kind = "Human"
	if person.Costume == "Cosme" then
		kind = "Own" -- (Cosme: shared/CosmeLook, sus 4 caras + la de hablar)
	elseif person.Body ~= nil then
		kind = "Creature"
	elseif person.Glow ~= nil then
		kind = GLOW_HUMAN[id] or "Creature"
	end
	local age = ageOf(person)
	local fem = isFem(key, person)
	local traits = TRAITS[key] or TRAITS[id] or {}
	local shirt, pants = defaultShirt(id, person, age, fem)
	shirt = traits.Shirt or shirt
	pants = traits.Pants or pants
	if GENERIC[id] then
		key = ("Arq_%s_%s"):format(age, if fem then "F" else "M")
	end
	local faces = if FULL[key] or table.find(Cast().Principales or {}, id) then CastLook.Full else CastLook.Basic
	local colors = {
		Skin = rgbOf(person.Skin),
		Hair = rgbOf(person.Hair),
		Shirt = rgbOf(person.Shirt),
		Pants = rgbOf(person.Pants),
	}
	if key == "Abu_Tomas" or key == "Abu_Rosa" then
		colors.Hair = colors.Hair or { 200, 200, 205 }
	end
	return {
		Id = id,
		Key = key,
		Kind = kind,
		Name = if type(person.Name) == "string" then person.Name else id,
		Faces = if kind == "Creature" or kind == "Own" then {} else faces,
		Face = {
			Age = age,
			Fem = fem,
			Eye = 1 + hash(key) % #CastLook.EyeColors,
			Glasses = traits.Glasses,
			Beard = if fem then nil else traits.Beard,
			Freckles = traits.Freckles == true,
			Generic = GENERIC[id] == true,
		},
		Shirt = if kind == "Creature" or kind == "Own" then nil else shirt,
		Pants = if kind == "Creature" or kind == "Own" then nil else pants,
		Hair = kind == "Human" or kind == "Hondario",
		Colors = colors,
	}
end

-- Grupo de trabajo (orden de prioridad para subir y revisar: docs/personajes/auditoria-texturas.md)
local SAGA2: { [string]: boolean } = {
	Cosimo = true, Varkun = true, NILDA = true, TuMalvado = true, TuFuturo = true,
	DaliaRenn = true, GeneralCorvo = true, TobiRenn = true, DoctoraFermina = true, MadreHollin = true, Brasa = true,
	IngenieroOrsi = true, GaloPadre = true, SargentoMurria = true, ErnestoPanadero = true, EscribanoLumo = true,
	CapitanaFerra = true, PoliciaMilitar1 = true, PoliciaMilitar2 = true, PoliciaMilitar3 = true, SoldadoOvilla = true,
	RefugiadoMayor = true, Capataz = true, NinaVentana = true,
	-- Siroco y Miasma (los planetas de después de Tefra)
	MaraSolis = true, ComandanteAndres = true, LeoSolis = true, AbuelaNiebla = true, MaestroOlmo = true, BrumaTaller = true,
	SenoraGarua = true, RacionadoraPia = true, SoldadoDominio1 = true, SoldadoDominio2 = true, RafaQuiroga = true,
	NinaQuiroga = true, LuzPozo = true, TavoAguador = true, CobradorHierro1 = true, CobradorHierro2 = true, MarisaDuna = true,
	AbueloTornillo = true, TiaCifra = true,
}
local SAGA1_EXTRA: { [string]: boolean } = {
	Ramon = true, Marta = true, Marisa = true, Paula = true, Julian = true, Andres = true, Beltran = true, Ivan = true,
	Candela = true, Tito = true, Portero = true, Veterano = true, Delegada = true, Dario = true, Alumno1 = true,
	Alumno2 = true, Alumno3 = true, Alumno4 = true, Mayor1 = true, Mayor2 = true, Alba = true, Rocio = true,
}
function CastLook.groupOf(spec: Spec): string
	if spec.Kind == "Hondario" then
		return "Nacara"
	end
	if SAGA2[spec.Id] then
		return "Saga2"
	end
	if spec.Id == "Familia" or spec.Id == "Abu" or SAGA1_EXTRA[spec.Id] or table.find(Cast().Principales or {}, spec.Id) then
		return "Saga1"
	end
	return "Otros"
end

-- Todas las fichas (export y pruebas): el reparto entero, las variantes de la familia y Nácara
function CastLook.all(): { Spec }
	local list = {}
	local ids = {}
	for id in Cast().People do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		if id == "Familia" then
			table.insert(list, CastLook.spec(id, "NPC.MAMA") :: Spec)
			table.insert(list, CastLook.spec(id, "NPC.PAPA") :: Spec)
		elseif id == "Abu" then
			table.insert(list, CastLook.spec(id, "NPC.ABU_ROSA") :: Spec)
			table.insert(list, CastLook.spec(id, "NPC.ABU_TOMAS") :: Spec)
		else
			table.insert(list, CastLook.spec(id) :: Spec)
		end
	end
	local seen = {}
	for _, people in seaLists() do
		for _, p in people do
			if p.Look and p.Look.Skin and not seen[p.Id] then
				seen[p.Id] = true
				local s = CastLook.spec("Nacara:" .. p.Id)
				if s then
					table.insert(list, s)
				end
			end
		end
	end
	return list
end

---------------------------------------------------------------------
-- Texturas subidas
---------------------------------------------------------------------

local ids: { [string]: string }? = nil
local function textureIds(): { [string]: string }
	if ids == nil then
		local ok, found = pcall(function()
			return require(script.Parent.Parent.PersonajesTextureIds)
		end)
		ids = if ok and type(found) == "table" then found else {}
	end
	return ids :: { [string]: string }
end

-- Para las pruebas: otra tabla de ids (nil vuelve a leer shared/PersonajesTextureIds)
function CastLook._setIds(list: { [string]: string }?)
	ids = list
end

function CastLook.textureId(name: string): string?
	local id = textureIds()[name]
	if type(id) ~= "string" or id == "" then
		return nil
	end
	local ok, image = pcall(function()
		return require(script.Parent.Parent.Images).of(id)
	end)
	return if ok and type(image) == "string" and image ~= "" then image else id
end

---------------------------------------------------------------------
-- Expresiones
---------------------------------------------------------------------

local HAPPY = { Happy = true, Laugh = true, Cheer = true, Clap = true, Dance = true, Wave = true, WaveLite = true }
local SAD = { Sad = true, Ashamed = true, Facepalm = true }
local ANGRY = { Angry = true, No = true }
local SCARED = { Surprised = true, Nervous = true, Scared = true }
local MOOD = { Joy = "Happy", Sad = "Sad", Shame = "Sad", Hurt = "Sad", Angry = "Angry", Fear = "Scared", Surprise = "Scared", Nervous = "Scared" }

function CastLook.faceFor(emotion: string?, mood: string?): string
	if emotion then
		if HAPPY[emotion] then
			return "Happy"
		elseif SAD[emotion] then
			return "Sad"
		elseif ANGRY[emotion] then
			return "Angry"
		elseif SCARED[emotion] then
			return "Scared"
		end
	end
	return (mood and MOOD[mood]) or "Neutral"
end

-- La imagen de una expresión (si no la tiene, la neutra; nil si no hay nada subido)
local function faceImage(key: string, faces: { string }, expression: string): string?
	if table.find(faces, expression) then
		local id = CastLook.textureId(CastLook.faceFile(key, expression))
		if id then
			return id
		end
	end
	return CastLook.textureId(CastLook.faceFile(key, "Neutral"))
end

local function setExpression(model: Model, expression: string): boolean
	local key = model:GetAttribute(CastLook.ATTR_KEY)
	if type(key) ~= "string" then
		return false
	end
	local faces = if model:GetAttribute("CastFaceFull") then CastLook.Full else CastLook.Basic
	local image = faceImage(key, faces, expression)
	if not image then
		return false -- (nada subido: se queda la cara que tenía)
	end
	local FaceKit = require(script.Parent.Parent.FaceKit)
	FaceKit.set(model, image, CastLook.textureId(CastLook.faceFile(key, "Talk")))
	model:SetAttribute(CastLook.ATTR_FACE, expression)
	return true
end

function CastLook.rest(model: Model)
	local mood = model:GetAttribute("Mood")
	setExpression(model, CastLook.faceFor(nil, if type(mood) == "string" then mood else nil))
end

function CastLook.express(model: Model?, emotion: string?, seconds: number?)
	if not model or model:GetAttribute(CastLook.ATTR_FACE) == nil then
		return
	end
	local mood = model:GetAttribute("Mood")
	setExpression(model, CastLook.faceFor(emotion, if type(mood) == "string" then mood else nil))
	local token = (tonumber(model:GetAttribute("CastFaceToken")) or 0) + 1
	model:SetAttribute("CastFaceToken", token)
	task.delay(math.max(1, seconds or 3) + 0.3, function()
		if model.Parent and model:GetAttribute("CastFaceToken") == token then
			CastLook.rest(model)
		end
	end)
end

---------------------------------------------------------------------
-- Vestir
---------------------------------------------------------------------

local HAIR_PARTS = { Hair = { "Top", "Back", "Left", "Right", "Front" }, HairBack = { "Back", "Left", "Right" }, Fringe = { "Front", "Top" } }

local function hairTextures(model: Model, image: string, hair: Color3?)
	for name, faces in HAIR_PARTS do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			for _, old in part:GetChildren() do
				if old:IsA("Texture") and old.Name == "Mechones" then
					old:Destroy()
				end
			end
			for _, face in faces do
				local t = Instance.new("Texture")
				t.Name = "Mechones"
				t.Texture = image
				t.Face = (Enum.NormalId :: any)[face]
				t.StudsPerTileU = 1.2
				t.StudsPerTileV = 1.2
				-- mechones más oscuros que el pelo (la imagen es gris con transparencia)
				t.Color3 = if hair then hair:Lerp(Color3.new(0, 0, 0), 0.35) else Color3.fromRGB(60, 50, 44)
				t.Transparency = 0.15
				t.Parent = part
			end
		end
	end
end

local function clothing(model: Model, class: string, name: string, template: string, tint: Color3?): boolean
	local ok = pcall(function()
		for _, old in model:GetChildren() do
			if old:IsA(class) then
				old:Destroy()
			end
		end
		local c = Instance.new(class)
		c.Name = name
		if class == "Shirt" then
			(c :: any).ShirtTemplate = template
		else
			(c :: any).PantsTemplate = template
		end
		if tint then
			(c :: any).Color3 = tint -- (las plantillas son casi blancas: se tiñen con el color del reparto)
		end
		c.Parent = model
	end)
	return ok
end

local function paintSkin(model: Model, names: { string }, skin: Color3?)
	if not skin then
		return
	end
	for _, n in names do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			p.Color = skin
		end
	end
end

-- Viste a un personaje del reparto (ya pintado y con el pelo de Npc.dress). Devuelve si ha cambiado algo.
function CastLook.apply(model: Model, id: string, variant: string?, look: { [string]: any }?): boolean
	local spec = CastLook.spec(id, variant)
	if not spec or spec.Kind == "Creature" or spec.Kind == "Own" then
		return false
	end
	local l = look or {}
	model:SetAttribute(CastLook.ATTR_KEY, spec.Key)
	model:SetAttribute("CastFaceFull", if #spec.Faces == #CastLook.Full then true else nil)
	model:SetAttribute("CastShirt", spec.Shirt)
	model:SetAttribute("CastPants", spec.Pants)
	pcall(function()
		game:GetService("CollectionService"):AddTag(model, CastLook.TAG)
	end)
	local changed = CastLook.refresh(model, l)
	pcall(function()
		model:GetAttributeChangedSignal("Mood"):Connect(function()
			if model:GetAttribute(CastLook.ATTR_FACE) ~= nil then
				CastLook.rest(model)
			end
		end)
	end)
	return changed
end

-- Pone (o vuelve a poner) lo que esté subido: ropa, mechones y cara
function CastLook.refresh(model: Model, look: { [string]: any }?): boolean
	local key = model:GetAttribute(CastLook.ATTR_KEY)
	if type(key) ~= "string" then
		return false
	end
	local l = look or {}
	local changed = false
	local shirtStyle = model:GetAttribute("CastShirt")
	local pantsStyle = model:GetAttribute("CastPants")
	local function colorOf(name: string, fallback: Color3?): Color3?
		local c = l[name]
		if typeof(c) == "Color3" then
			model:SetAttribute("Cast" .. name .. "Color", c)
			return c
		end
		local saved = model:GetAttribute("Cast" .. name .. "Color")
		return if typeof(saved) == "Color3" then saved else fallback
	end
	if type(shirtStyle) == "string" then
		local template = CastLook.textureId(CastLook.shirtFile(shirtStyle))
		if template and clothing(model, "Shirt", "CastShirt", template, colorOf("Shirt")) then
			changed = true
			local style = CastLook.ShirtStyles[shirtStyle]
			if style and style.Short then
				paintSkin(model, { "LeftLowerArm", "RightLowerArm" }, colorOf("Skin"))
			end
		end
	end
	if type(pantsStyle) == "string" then
		local template = CastLook.textureId(CastLook.pantsFile(pantsStyle))
		if template and clothing(model, "Pants", "CastPants", template, colorOf("Pants")) then
			changed = true
		end
	end
	local hairImage = CastLook.textureId(CastLook.HAIR_FILE)
	if hairImage then
		hairTextures(model, hairImage, colorOf("Hair"))
		changed = true
	end
	local face = model:GetAttribute(CastLook.ATTR_FACE)
	if type(face) == "string" then
		changed = setExpression(model, face) or changed
	else
		local mood = model:GetAttribute("Mood")
		changed = setExpression(model, CastLook.faceFor(nil, if type(mood) == "string" then mood else nil)) or changed
	end
	return changed
end

return CastLook
