-- SkyMoods: CAMBIOS DE CIELO PUNTUALES de la historia (la luz se vuelve verde cuando la Grieta escupe
-- algo, se oscurece con una tormenta que solo ves tú, apagón…). No sustituyen al ciclo del día: son
-- capas que Controllers/DayLight mezcla ENCIMA de la luz de la hora y del tiempo (DayLight.pushLayer /
-- popLayer, con fundido), y al quitarlas todo vuelve a ser como era. Solo en la pantalla de quien
-- vive la escena.
--
-- Cada capa dice algunos valores de la luz (los nombres de shared/DayGrade: Brightness, Exposure,
-- Ambient, Outdoor, AtmColor, Decay, Density, Haze, Tint, Saturation, Contrast, CCBright, Cover,
-- CloudDensity, CloudColor, Bloom, Rays…). Lo que no dice se queda como está.

local SkyMoods = {}

local rgb = Color3.fromRGB

SkyMoods.List = {
	-- La Grieta se enciende: verde enfermizo, más contraste, nubes que se tiñen
	GrietaVerde = {
		Tint = rgb(196, 255, 214),
		Saturation = 0.05,
		Contrast = 0.24,
		AtmColor = rgb(120, 200, 150),
		Decay = rgb(40, 110, 70),
		CloudColor = rgb(150, 210, 170),
		Haze = 2.2,
		Bloom = 1.1,
	},
	-- Algo malo va a pasar: más oscuro, frío y apagado
	Ominoso = {
		Brightness = 1.4,
		Exposure = -0.1,
		Tint = rgb(200, 205, 225),
		Saturation = -0.25,
		Contrast = 0.22,
		Density = 0.42,
		Haze = 2.4,
		Cover = 0.8,
		CloudDensity = 0.55,
		CloudColor = rgb(90, 92, 104),
	},
	-- Tormenta local (la de la receta LocalStorm): cielo plomizo y casi sin sombras
	Tormenta = {
		Brightness = 1.1,
		Exposure = -0.18,
		Outdoor = rgb(80, 86, 100),
		Tint = rgb(190, 200, 215),
		Saturation = -0.3,
		Contrast = 0.18,
		Density = 0.45,
		Haze = 2.6,
		AtmColor = rgb(96, 100, 112),
		Cover = 0.86,
		CloudDensity = 0.75,
		CloudColor = rgb(60, 62, 72),
		Rays = 0,
	},
	-- Apagón: noche cerrada de golpe (para la ciudad sin luz)
	Apagon = {
		Brightness = 0.6,
		Exposure = -0.35,
		Ambient = rgb(20, 22, 30),
		Outdoor = rgb(28, 32, 46),
		Tint = rgb(170, 180, 220),
		Saturation = -0.2,
		CCBright = -0.05,
		Bloom = 0.6,
		Rays = 0,
	},
	-- Recuerdo / flashback: sepia suave
	Sepia = {
		Tint = rgb(255, 228, 190),
		Saturation = -0.55,
		Contrast = 0.12,
		CCBright = 0.02,
	},
	-- Magia buena: dorado cálido
	Dorado = {
		Tint = rgb(255, 236, 200),
		Saturation = 0.12,
		Bloom = 1.3,
		AtmColor = rgb(255, 210, 160),
		Rays = 0.18,
	},
}

function SkyMoods.get(name: any): { [string]: any }?
	return if type(name) == "string" then SkyMoods.List[name] else nil
end

function SkyMoods.names(): { [string]: boolean }
	local set = {}
	for name in SkyMoods.List do
		set[name] = true
	end
	return set
end

-- La luz de la hora `k` con la capa encima a peso w (0..1). mix = DayGrade.mix (se pasa para que
-- este módulo no dependa de DayGrade y se pueda probar solo)
function SkyMoods.apply(k: { [string]: any }, mood: { [string]: any }, w: number, mix: (any, any, number) -> any): { [string]: any }
	if w <= 0.001 then
		return k
	end
	local target = table.clone(k)
	for name, value in mood do
		if k[name] ~= nil then
			target[name] = value
		end
	end
	return mix(k, target, math.clamp(w, 0, 1))
end

return SkyMoods
