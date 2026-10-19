-- TextSpeed: la velocidad del texto de las conversaciones (menú Ajustes: «💬 Velocidad del texto») y
-- las cuentas de la máquina de escribir de la caja de diálogo (Controllers/DialogueUI).
--
--   * Cuatro velocidades: Lento, Normal (la de siempre, 55 letras por segundo), Rápido e Instantáneo
--     (la frase sale entera de golpe).
--   * Se guarda con la partida SIN campo nuevo: dentro de los ajustes de sonido que ya existían
--     (data.Audio.TextSpeed, Services/SettingsService), y llega al entrar en el atributo del jugador
--     «TextSpeed». Se cambia con el mismo remoto que los volúmenes: AudioVolume ("Set", "TextSpeed", valor).
--     Como data.Audio, sigue igual al empezar una vida nueva (es del jugador, no de la vida).
--   * Tocar: si hay una pausa, se acaba; si se está escribiendo, la frase sale entera; si ya está
--     entera, se pasa a la siguiente (con ReadingTime.TAP_GUARD: un doble toque no se come una frase).
--   * Con la voz: si se sabe lo que dura la voz de la frase, el texto Lento/Normal se acompasa para
--     terminar poco antes que la voz (sin pasarse del doble ni de la mitad de lo elegido). Rápido e
--     Instantáneo hacen caso al jugador.
--   * Tecleo: un «tic» suave cada pocas letras (como mucho ~12 por segundo), con el volumen de 🔔
--     Efectos. No suena en Instantáneo ni mientras suena (o se espera) la voz de la frase.
--
-- Cuentas puras (scripts/test-stagedirector, sección 10; scripts/test-cinematic, sección 3).

local TextSpeed = {}

TextSpeed.Values = { "Lento", "Normal", "Rapido", "Instantaneo" }
TextSpeed.Default = "Normal"
TextSpeed.Attribute = "TextSpeed" -- atributo del jugador (lo pone el servidor al cargar)
TextSpeed.Field = "TextSpeed" -- dentro de data.Audio
TextSpeed.Key = "TextSpeed" -- clave del remoto AudioVolume
-- Letras por segundo (0 = de golpe)
TextSpeed.Rates = { Lento = 30, Normal = 55, Rapido = 110, Instantaneo = 0 }
TextSpeed.Names = { Lento = "Lento", Normal = "Normal", Rapido = "Rápido", Instantaneo = "Instantáneo" }
TextSpeed.Label = "💬 Velocidad del texto"
-- Las que se acompasan con la voz
TextSpeed.Paced = { Lento = true, Normal = true }
TextSpeed.BlipsPerSecond = 12 -- tope de «tics» de tecleo por segundo

function TextSpeed.valid(value: any): boolean
	return type(value) == "string" and TextSpeed.Rates[value] ~= nil
end

-- Cualquier cosa -> una velocidad válida (lo que no vale: Normal)
function TextSpeed.sanitize(value: any): string
	return if TextSpeed.valid(value) then value else TextSpeed.Default
end

-- La siguiente al tocar el botón del menú (Lento -> Normal -> Rápido -> Instantáneo -> Lento)
function TextSpeed.next(value: any): string
	local i = table.find(TextSpeed.Values, TextSpeed.sanitize(value)) or 2
	return TextSpeed.Values[i % #TextSpeed.Values + 1]
end

-- Texto de la fila del menú: «💬 Velocidad del texto: Rápido»
function TextSpeed.label(value: any): string
	return TextSpeed.Label .. ": " .. TextSpeed.Names[TextSpeed.sanitize(value)]
end

-- Letras por segundo (0 = de golpe)
function TextSpeed.rate(value: any): number
	return TextSpeed.Rates[TextSpeed.sanitize(value)]
end

function TextSpeed.instant(value: any): boolean
	return TextSpeed.rate(value) <= 0
end

-- La velocidad con la voz: chars letras y una voz de voiceSeconds s. Si la velocidad se acompasa y la
-- voz se conoce, la frase acaba de escribirse al ~85 % de la voz, entre la mitad y el doble de lo
-- elegido (ni se arrastra ni se dispara). Si no, la elegida.
function TextSpeed.paced(value: any, chars: number, voiceSeconds: number?): number
	local base = TextSpeed.rate(value)
	if base <= 0 or not TextSpeed.Paced[TextSpeed.sanitize(value)] then
		return base
	end
	if type(voiceSeconds) ~= "number" or voiceSeconds ~= voiceSeconds or voiceSeconds < 0.5 or chars <= 0 then
		return base
	end
	local target = chars / (voiceSeconds * 0.85)
	return math.clamp(target, base * 0.5, base * 2)
end

-- Cada cuántas letras suena un «tic» a esa velocidad (nunca más de BlipsPerSecond; 0 = ninguno)
function TextSpeed.blipEvery(rate: number): number
	if rate <= 0 then
		return 0
	end
	return math.max(2, math.ceil(rate / TextSpeed.BlipsPerSecond))
end

-- ¿Suena un «tic» al pasar de `before` a `after` letras escritas? (uno como mucho por paso)
function TextSpeed.blip(before: number, after: number, every: number): boolean
	if every <= 0 or after <= before then
		return false
	end
	return math.floor(after / every) > math.floor(before / every)
end

-- Qué hace un toque en la caja: "SkipHold" (acaba la pausa), "Finish" (la frase sale entera),
-- "Advance" (la siguiente) o "Ignore" (justo acaba de salir entera: un doble toque no se la come)
function TextSpeed.tapAction(state: { Holding: boolean?, Typed: boolean?, SinceTyped: number?, Guard: number? }): string
	if state.Holding then
		return "SkipHold"
	elseif not state.Typed then
		return "Finish"
	elseif (state.SinceTyped or math.huge) >= (state.Guard or 0) then
		return "Advance"
	end
	return "Ignore"
end

return TextSpeed
