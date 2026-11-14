-- LA DERIVA · ACTO I (expansión espacial, docs/espacio-aaa/expansion-15h.md §6, hora 4).
-- Se ofrece al ATRACAR en una estación después del prólogo de Varkun (DerivaSignal de Services/
-- DerivaService). Los pasos «Event» los avisa DerivaService (DerivaStep { Step } y DerivaFuse { N });
-- las cuentas del pecio, en shared/Cosmos/Derelicts. Las frases por radio son del guion:
-- docs/historia/reescritura/Deriva_01_Misericordia.md → Guiones/ (nunca a mano). Las dos cinemáticas
-- y los tres registros, en Happenings/Deriva.luau.
--
--   Deriva_01_Misericordia  «La nave hospital»: la Misericordia de Ovilla, a la deriva desde la guerra.
--     Dentro: tres fusibles con un sistema de seguridad que sigue activo, y en el puente el último registro
--     de la doctora Varga: una nave sin bandera pidió las coordenadas de Ovilla a cambio de evacuar a los
--     heridos… y su código de transpondedor empezaba por VIG, el prefijo de las patrullas de la Vigilancia.
--
-- Tono (regla del dueño): para 13-15 años, nada infantil. Hay muertos, pero fuera de plano.

local Derelicts = require(script.Parent.Parent.Parent.Cosmos.Derelicts)

local function step(id: string, text: string): { [string]: any }
	return { Type = "Event", Event = "DerivaStep", Match = { Step = id }, Text = text }
end

local function fuse(n: number, room: string): { [string]: any }
	return { Type = "Event", Event = "DerivaFuse", Match = { N = n }, Text = ("Fusible %d · %s"):format(n, room) }
end

local steps = {
	step("Approach", "Sigue la baliza médica en nave hasta el pecio de la Misericordia"),
	step("Board", "Acércate al aro azul de la esclusa y bájate de la nave (Salir) para entrar"),
	{ Type = "Cinematic", Id = "Deriva_Misericordia_Entrada" },
	{
		Type = "Group",
		Need = 3,
		Text = "Restaura la corriente: cambia los tres fusibles (Triaje, Cuarentena y Máquinas). Cuidado con los láseres de seguridad y el cuadro roto",
		Steps = { fuse(1, "Triaje"), fuse(2, "Cuarentena"), fuse(3, "Máquinas") },
	},
	step("Bridge", "Con la corriente restaurada, entra en el puente, al fondo del pasillo"),
	{ Type = "Cinematic", Id = "Deriva_Misericordia_Registro" },
	step("Core", "Saca el núcleo de datos de la consola del puente"),
	step("Launch", "Vuelve a la esclusa y sube a tu nave"),
	step("Ambush", "Algo te esperaba fuera: derriba a los Hilanderos"),
	step("Delivered", "Lleva el núcleo de datos al muelle de la Estación Alba"),
}

-- (los pasos tienen que ir en el mismo orden que la cuenta del servicio)
assert(#steps == #Derelicts.Steps, "Deriva_ActoI: los pasos no cuadran con shared/Cosmos/Derelicts.Steps")

local Canto = require(script.Parent.Parent.Parent.Cosmos.Canto)

local function canto(id: string, text: string): { [string]: any }
	return { Type = "Event", Event = "CantoStep", Match = { Step = id }, Text = text }
end

local cantoSteps = {
	canto("Signal", "Sigue el ruido de la radio hasta la anomalía, al otro lado de la Nube Escarcha"),
	canto("Scanned", "Quédate dentro de la anomalía 30 segundos mientras el escáner la mide. La radio y la pantalla van a fallar"),
	canto("Docked", "Lleva el escaneo al muelle de la Estación Vigía"),
	{ Type = "Cinematic", Id = "Deriva_Vigia_Ivo" },
}
assert(#cantoSteps == #Canto.Steps, "Deriva_ActoI: los pasos del canto no cuadran con shared/Cosmos/Canto.Steps")

return {
	-- «La anomalía que canta» (hora 2): la ciencia de la Deriva y la doctora Ivo. Abre el laboratorio de la
	-- Vigía (bandera VigiaAbierta: investigación con Datos, shared/Cosmos/Research).
	{
		Id = Canto.MissionId,
		Kind = "Side",
		Title = "La anomalía que canta",
		Description = "La radio de la estación repite un ruido que suena como una canción. Viene de más allá de la Nube Escarcha. El Instituto Nilda lleva años pidiendo que alguien lo mida de cerca, y nadie ha querido acercarse.",
		Type = "La Deriva · Acto I",
		Duration = { 8, 12 },
		Offer = { Event = "CantoSignal", Match = { Part = 1 } },
		OfferKey = "La radio repite un ruido que suena como una canción",
		Requires = { Completed = { "Varkun_02_Escarcha" } },
		Moment = "Aguantaste dentro de una anomalía que cantaba y conociste a la doctora Ivo",
		Memory = "CantoAnomalia",
		Rewards = { Money = 600, Flags = { "VigiaAbierta" } },
		Steps = cantoSteps,
	},
	{
		Id = Derelicts.MissionId,
		Kind = "Side",
		Title = "La nave hospital",
		Description = "La Misericordia, la nave hospital de Ovilla, lleva dos años a la deriva desde la guerra de Tefra. Esta mañana su baliza médica se ha encendido sola. Nadie sabe qué pasó con sus trescientos pacientes, y la Estación Alba quiere saberlo antes que los chatarreros.",
		Type = "La Deriva · Acto I",
		Duration = { 15, 25 },
		Offer = { Event = "DerivaSignal", Match = { Part = 1 } },
		OfferKey = "La baliza médica de la Misericordia se ha encendido sola, dos años después",
		Requires = { Completed = { "Varkun_02_Escarcha" } },
		Moment = "Entraste en la Misericordia y escuchaste el último registro de la doctora Varga",
		Memory = "Misericordia",
		Rewards = { Money = 900, Flags = { "DerivaMisericordia", "PistaVIG" } },
		Steps = steps,
	},
}
