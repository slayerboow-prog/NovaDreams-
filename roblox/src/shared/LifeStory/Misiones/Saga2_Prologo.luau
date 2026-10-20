-- SAGA 2 · PRÓLOGO DEL ESPACIO «La costura negra» (Varkun, el Deshilador; docs/universo/diseno-espacio.md §2,
-- villano aprobado por el dueño). Dos secundarias que se ofrecen al ATRACAR en una estación (el evento
-- VarkunSignal { Part } de Services/VarkunService, que también pone los sitios en el mundo) y avanzan con
-- VarkunStep { Step } (cuentas en shared/Cosmos/Varkun). Las frases (Cosme y NILDA por radio, Varkun)
-- son del guion: docs/historia/reescritura/Varkun_01_Costura.md y Varkun_02_Escarcha.md → Guiones/.
--   Varkun_01_Costura   «La costura negra»: la señal de socorro, las Agujas y el carrete de hilo negro
--   Varkun_02_Escarcha  «Ruido en la Escarcha»: la anomalía, el escaneo y la Rueca al fondo

return {
	{
		Id = "Varkun_01_Costura",
		Kind = "Side",
		Title = "La costura negra",
		Description = "La radio de la estación capta una señal de socorro desde la Ruta de los Saqueadores: un carguero del Gremio que no contesta. NILDA dice que la señal «suena cosida». Cosme quiere saber qué es antes que nadie.",
		Type = "Saga 2 · Prólogo del espacio (1/2)",
		Duration = { 10, 15 },
		Offer = { Event = "VarkunSignal", Match = { Part = 1 } },
		OfferKey = "Señal de socorro desde la Ruta de los Saqueadores. Nadie contesta",
		Requires = { Completed = { "Saga_24_Final" } },
		Moment = "Encontraste el primer hilo negro de Varkun en la Ruta de los Saqueadores",
		Rewards = { Money = 400, Flags = { "VarkunCarrete" } },
		Steps = {
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Wreck" }, Text = "Sigue la señal de socorro hasta la Ruta de los Saqueadores (con la nave)" },
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Ambush" }, Text = "Derriba a las tres Agujas que vigilan el carguero" },
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Delivered" }, Text = "Lleva el carrete de hilo negro a la Estación Cénit (atraca en su muelle)" },
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Vault" }, Text = "La Vigilancia guarda el carrete en su caja fuerte" },
		},
	},
	{
		Id = "Varkun_02_Escarcha",
		Kind = "Side",
		Title = "Ruido en la Escarcha",
		Description = "En la Estación Cénit el carrete de hilo negro empieza a vibrar. NILDA lo oye «cantar» hacia la Nube Escarcha, como si llamara a algo. Cosme te pide que vayas a escanear de dónde viene antes de que llame a quien no debe.",
		Type = "Saga 2 · Prólogo del espacio (2/2)",
		Duration = { 10, 15 },
		Offer = { Event = "VarkunSignal", Match = { Part = 2 } },
		OfferKey = "El carrete de hilo negro vibra. NILDA: «Está cantando hacia la Escarcha»",
		Requires = { Completed = { "Varkun_01_Costura" } },
		Moment = "Viste la Rueca de Varkun por primera vez, al fondo de la Nube Escarcha",
		Rewards = { Money = 600, Flags = { "VarkunVisto" } },
		Steps = {
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Anomaly" }, Text = "Ve a la anomalía de hilo encima de la Nube Escarcha" },
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Scanned" }, Text = "Quédate dentro de la anomalía mientras NILDA la escanea" },
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Rueca" }, Text = "Aguanta hasta que la Rueca se vaya" },
			{ Type = "Event", Event = "VarkunStep", Match = { Step = "Calma" }, Text = "Escucha a NILDA: la Rueca se ha ido" },
		},
	},
}
