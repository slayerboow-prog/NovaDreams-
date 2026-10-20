-- Witness: quién ve (u oye) un delito y qué pasa después. Reglas del dueño (Sebastián):
--   «Solo será delito y habrá persecución si hay un policía delante de mí en un rango de visión
--    óptimo, o si pego disparos en un rango de escucha. Si no hay policías, quien comete delitos
--    sale impune.»
--   «Los NPCs pueden grabarte y denunciarte a la policía, y así deberás cambiarte de ropa si no
--    quieres que te persigan.»
--   «Atacar a los extraterrestres nunca es delito.»
--
-- Cómo funciona (Services/WantedService lo aplica; aquí solo las cuentas, puras: scripts/test-wanted):
--   1. VISTA de la policía (agente a pie, patrulla, helicóptero, policía jugador de servicio, agentes
--      de la invasión): a menos de SightRange, dentro de su cono de visión (ViewDegrees; el
--      helicóptero mira a todos lados) y sin pared en medio (los cristales, lo transparente y las
--      hojas no tapan: seeThrough). Si te ve: estrellas al momento (como siempre).
--   2. OÍDO (solo disparos): un policía a menos de HearRange (menos si estás dentro de un edificio o
--      el arma lleva silenciador) lo oye. No da estrellas: la policía viene a INVESTIGAR el sitio
--      durante InvestigateSeconds; si en ese rato te VE, estrellas del delito.
--   3. Sin policía: impune en el momento. Pero un civil que lo VE (mismas cuentas de vista, con su
--      alcance) puede sacar el móvil y GRABARTE (FilmSeconds) o huir; si acaba la grabación, poco
--      después te DENUNCIA: una «denuncia» con la descripción de tu ropa (outfitKey) y el sitio, que
--      caduca (ReportSeconds). Un policía que más tarde te vea con ESA ropa te reconoce: estrellas
--      (reportStars: menos que si te pilla en el acto). Cambiarte de ropa (o de gorro, máscara…)
--      cambia la clave y ya no te reconocen. Con máscara o capucha la grabación sirve menos.
--   4. Defender Valmar de la invasión (alienígenas, rey, criaturas hostiles, naves) nunca es delito,
--      ni las balas perdidas ni los cristales rotos cerca de los alienígenas (alienExempt).

local Witness = {}

Witness.SightRange = 100 -- studs a los que la policía ve un delito (antes Wanted.PoliceSight = 90)
Witness.HeliSight = 210 -- el helicóptero, desde arriba
Witness.ViewDegrees = 116 -- cono de visión (total) de un agente o de un civil
Witness.HearRange = 180 -- un disparo se oye hasta aquí
Witness.IndoorHear = 0.5 -- disparando dentro de un edificio se oye la mitad de lejos
Witness.SuppressedHear = 0.35 -- con silenciador, aún menos
Witness.InvestigateSeconds = 25 -- la policía mira el sitio del disparo este rato
Witness.CivilianSight = 60 -- un civil ve (y puede grabar) hasta aquí
Witness.FilmSeconds = 3.5 -- lo que tarda en grabarte
Witness.ReportDelay = 4 -- de acabar de grabar a que llega la denuncia a la policía
Witness.ReportSeconds = 600 -- una denuncia caduca a los 10 minutos (solo en esta sesión: no se guarda)
Witness.MaxFilming = 3 -- como mucho tantos civiles grabando a la vez (en todo el servidor)
Witness.MaxReports = 4 -- denuncias activas por jugador (la más vieja sale)
Witness.ScareDistance = 7 -- si te acercas tanto a quien te graba, se asusta y para (se va)
Witness.MaskedClear = 0.35 -- con máscara o capucha, probabilidad de que la grabación te identifique
Witness.AlienRadius = 160 -- disparar (o romper algo) a menos de esto de un alienígena: defensa
Witness.MaxSeeThrough = 4 -- cristales u hojas seguidos que puede atravesar la mirada

-- Delitos que son disparos (se oyen)
Witness.GunCrimes = { Disparos = true, Disparo = true }
-- Delitos «de la defensa»: sin víctima (disparar al aire, romper un cristal). Cerca de los
-- alienígenas no son delito. Los que tienen víctima (pegar o disparar a una persona, a un agente…)
-- siguen siéndolo aunque haya una invasión.
Witness.DefenseCrimes = { Disparos = true, Danos = true }

local function cosHalf(degrees: number): number
	return math.cos(math.rad(degrees / 2))
end

-- ¿Está `target` dentro del cono de visión de quien está en `eye` mirando hacia `look`, a menos de
-- `range`? look = nil: ve a todos lados (helicóptero). Solo la geometría (sin paredes).
function Witness.inView(eye: Vector3, look: Vector3?, target: Vector3, range: number, degrees: number?): boolean
	local offset = target - eye
	local distance = offset.Magnitude
	if distance > range then
		return false
	end
	if distance < 3 or look == nil then
		return true -- (pegado a ti te ve aunque estés a su lado)
	end
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local flatOff = Vector3.new(offset.X, 0, offset.Z)
	if flatLook.Magnitude < 1e-3 or flatOff.Magnitude < 1e-3 then
		return true
	end
	return flatLook.Unit:Dot(flatOff.Unit) >= cosHalf(degrees or Witness.ViewDegrees)
end

-- ¿Deja ver a través? Cristales, piezas muy transparentes, hojas y ramas (y lo que no choca y es fino)
local SEE_MATERIALS = { Glass = true, ForceField = true, Grass = false, LeafyGrass = false }
local LEAF_NAMES = { "hoja", "leaf", "leaves", "copa", "arbusto", "bush", "foliage", "seto", "rama" }
function Witness.seeThrough(part: any): boolean
	if type(part) ~= "table" and typeof(part) ~= "Instance" then
		return false
	end
	local okT, transparency = pcall(function()
		return part.Transparency
	end)
	if okT and type(transparency) == "number" and transparency >= 0.5 then
		return true
	end
	local okM, material = pcall(function()
		return part.Material
	end)
	local mname = if okM and material ~= nil then (if type(material) == "string" then material else tostring(material.Name)) else ""
	if SEE_MATERIALS[mname] then
		return true
	end
	local okN, name = pcall(function()
		return part.Name
	end)
	local lower = if okN and type(name) == "string" then string.lower(name) else ""
	for _, word in LEAF_NAMES do
		if string.find(lower, word, 1, true) then
			return true
		end
	end
	return false
end

-- ¿Hay línea de vista de `from` a `to`? cast(from, to, skip) -> la pieza que tapa (o nil); skip es la
-- lista de piezas que ya se han atravesado (cristales, hojas). Pura: el servidor pasa workspace:Raycast.
function Witness.clearLine(from: Vector3, to: Vector3, cast: (Vector3, Vector3, { any }) -> any?): boolean
	local skip = {}
	for _ = 1, Witness.MaxSeeThrough + 1 do
		local hit = cast(from, to, skip)
		if hit == nil then
			return true
		end
		if not Witness.seeThrough(hit) then
			return false
		end
		table.insert(skip, hit)
	end
	return false
end

-- ¿Lo ve? (cono + alcance + nada en medio)
function Witness.sees(eye: Vector3, look: Vector3?, target: Vector3, range: number, cast: (Vector3, Vector3, { any }) -> any?, degrees: number?): boolean
	return Witness.inView(eye, look, target, range, degrees) and Witness.clearLine(eye, target, cast)
end

-- ¿Oye un disparo hecho en `at` alguien que está en `ear`? (dentro de un edificio y con silenciador,
-- menos lejos). Las paredes no tapan el ruido, solo lo atenúa estar dentro.
function Witness.hearRange(indoors: boolean?, suppressed: boolean?): number
	local range = Witness.HearRange
	if indoors then
		range *= Witness.IndoorHear
	end
	if suppressed then
		range *= Witness.SuppressedHear
	end
	return range
end
function Witness.hears(ear: Vector3, at: Vector3, indoors: boolean?, suppressed: boolean?): boolean
	return (ear - at).Magnitude <= Witness.hearRange(indoors, suppressed)
end

function Witness.isGunCrime(crime: string, options: { [string]: any }?): boolean
	return Witness.GunCrimes[crime] == true or (options ~= nil and options.Gun == true)
end

-- Atacar a la invasión nunca es delito: ctx.Alien (el golpe o el disparo era a un alienígena) o un
-- delito «de la defensa» (disparos, daños) cerca de alienígenas.
function Witness.alienExempt(crime: string, ctx: { Alien: boolean?, AliensNear: boolean? }?): boolean
	if not ctx then
		return false
	end
	if ctx.Alien then
		return true
	end
	return ctx.AliensNear == true and Witness.DefenseCrimes[crime] == true
end

-- Qué hace un civil que ve un delito de `stars` estrellas (roll en [0, 1)): "Film", "Flee" o "Ignore".
-- Cuanto más grave, más graban (y más huyen).
function Witness.civilianReaction(stars: number, roll: number): string
	local s = math.clamp(stars, 1, 3)
	local film = ({ 0.45, 0.6, 0.7 })[s]
	local flee = ({ 0.2, 0.25, 0.3 })[s]
	if roll < film then
		return "Film"
	elseif roll < film + flee then
		return "Flee"
	end
	return "Ignore"
end

-- Estrellas de una denuncia (te reconocen después): una menos que en el acto (al menos 1)
function Witness.reportStars(stars: number): number
	return math.max(1, stars - 1)
end

-- La ropa, como clave: piezas (texto) en cualquier orden -> siempre la misma clave
function Witness.outfitKey(items: { string }): string
	local list = table.clone(items)
	table.sort(list)
	local text = table.concat(list, "|")
	-- (FNV-1a de 32 bits: corto para comparar y para guardarlo en un atributo)
	local h = 2166136261
	for i = 1, #text do
		h = bit32.bxor(h, string.byte(text, i))
		-- (× 16777619 = × 2^24 + × 403, sin pasarse de la precisión de un número)
		h = ((h % 256) * 16777216 + h * 403) % 4294967296
	end
	return string.format("%08x", h)
end

-- ¿Lleva algo que tapa la cara? (máscara, pasamontañas, capucha puesta, casco)
local MASK_WORDS = { "mask", "mascara", "máscara", "pasamonta", "balaclava", "capucha", "hood", "casco", "helmet" }
function Witness.masked(items: { string }): boolean
	for _, item in items do
		local lower = string.lower(item)
		for _, word in MASK_WORDS do
			if string.find(lower, word, 1, true) then
				return true
			end
		end
	end
	return false
end

-- ¿Sirve la grabación para reconocerte? (con la cara tapada, solo a veces)
function Witness.identifies(masked: boolean, roll: number): boolean
	return not masked or roll < Witness.MaskedClear
end

export type Report = { Crime: string, Key: string?, Vehicle: string?, At: Vector3?, Stars: number, Expires: number, Text: string? }

-- Una denuncia nueva
function Witness.newReport(crime: string, stars: number, key: string?, vehicle: string?, at: Vector3?, now: number, text: string?): Report
	return { Crime = crime, Key = key, Vehicle = vehicle, At = at, Stars = Witness.reportStars(stars), Expires = now + Witness.ReportSeconds, Text = text }
end

-- Quita las caducadas (y deja como mucho MaxReports, las más nuevas)
function Witness.prune(reports: { Report }, now: number): { Report }
	local out = {}
	for _, r in reports do
		if now < r.Expires then
			table.insert(out, r)
		end
	end
	while #out > Witness.MaxReports do
		table.remove(out, 1)
	end
	return out
end

-- ¿Alguna denuncia te describe tal y como vas ahora? (misma ropa o mismo vehículo). Devuelve cuál.
function Witness.matching(reports: { Report }, key: string?, vehicle: string?, now: number): Report?
	for _, r in reports do
		if now < r.Expires and ((r.Key ~= nil and r.Key == key) or (r.Vehicle ~= nil and r.Vehicle == vehicle)) then
			return r
		end
	end
	return nil
end

return Witness
