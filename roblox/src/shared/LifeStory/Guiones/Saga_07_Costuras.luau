-- GUION REESCRITO de Saga_07_Costuras (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_07_Costuras.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_07_Costuras
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_07_Costuras.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_07_Costuras.md",
	Dialogues = {
		Credencial = {
			Lines = {
				{ S = "Cosme", T = "Criatura. Ya no eres tan criatura.", To = "Yo" },
				{ S = "Cosme", T = "Pero te lo sigo llamando.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Confirmo que la criatura ha crecido. Mucho.", To = "Yo" },
				{ S = "Cosme", T = "No ayudes. Te he hecho esto. No pongas esa cara. Es oficial.", To = "Yo" },
				{ S = "Pip", T = "No es oficial. Pero él cree que sí.", To = "Yo" },
				{ S = "Cosme", T = "Gracias, Pip. Por destruir el momento.", To = "Yo" },
				{ S = "Cosme", T = "Ahora viene la parte mala.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "La costura del cielo se está soltando. Punto a punto. Lo dije.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Las costuras siempre se sueltan. Lo dijo… otro.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "El señor Cosme lleva exactamente seis años evitando decir quién.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Pip.", To = "Yo" },
				{ S = "Pip", T = "Sí, señor.", To = "Yo" },
				{ S = "DonEscamas", T = "Y hay más. MegaVerso ha pedido permiso para abrir una oficina en el Distrito Financiero.", To = "Yo" },
				{ S = "Cosme", T = "¿MegaVerso?", To = "Yo" },
				{ S = "DonEscamas", T = "MegaVerso. Sigue siendo una empresa. Eso es lo peor.", To = "Yo" },
				{ S = "DonEscamas", T = "Todavía me llegan sus boletines.", To = "Yo" },
				{ S = "DonEscamas", T = "Soy de los que no se dan de baja.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "He intentado cancelar la suscripción.", To = "Yo" },
				{ S = "Pip", T = "Me han ofrecido un viaje a una dimensión tropical.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "¿Y?", To = "Yo" },
				{ S = "Pip", T = "He dicho que no.", To = "Yo" },
				{ S = "Cosme", T = "Tres sitios. Tres costuras. Necesito que vayas.", To = "Yo" },
				{ S = "Yo", T = "No existe una decisión de diálogo." },
				{ S = "Cosme", T = "Yo no puedo. Me duele. La espalda. Y el orgullo.", To = "Yo" },
				{ S = "Pip", T = "Sobre todo el orgullo.", To = "Yo" },
				{ S = "Cosme", T = "Tú llevas años viendo estas cosas.", To = "Yo" },
				{ S = "Cosme", T = "Ahora ya eres suficientemente mayor para reconocerlas. El medidor pita. Si encuentras algo…", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "No lo toques. Llámame.", To = "Yo", Pause = 0.9 },
			},
		},
		Informe = {
			Lines = {
				{ S = "Cosme", T = "Hilachas. La costura se deshace. Y cuando se deshace… Los hilos escapan.", To = "Yo" },
				{ S = "DonEscamas", T = "Como cuando se rompe un jersey.", To = "Yo" },
				{ S = "Cosme", T = "Sí. Pero imagina que el jersey es el universo.", To = "Yo" },
				{ S = "DonEscamas", T = "Entonces no quiero llevarlo puesto.", To = "Yo" },
				{ S = "Cosme", T = "Y has visto el anuncio. MegaVerso.", To = "Yo" },
				{ S = "Cosme", T = "Desde que te habló a través de la costura…", To = "Yo", If = { Flags = { "CosimoTeHaVisto" } } },
				{ S = "Cosme", T = "Duermo con un ojo abierto. El otro también.", To = "Yo", Pause = 0.9, If = { Flags = { "CosimoTeHaVisto" } } },
				{ S = "Cosme", T = "Espero que no llegue a hablarte. Todavía no.", To = "Yo", If = { NotFlags = { "CosimoTeHaVisto" } } },
				{ S = "Cosme", T = "Sí. De Cósimo.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "El señor Cosme acaba de admitir algo importante.", To = "Yo" },
				{ S = "Pip", T = "Voy a marcarlo en el calendario.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Pip.", To = "Yo" },
				{ S = "Pip", T = "Sí, señor.", To = "Yo" },
				{ S = "Cosme", T = "Te prometí contártelo cuando fueras mayor.", To = "Yo" },
				{ S = "Cosme", T = "Aún no eres tan mayor.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Pero Pip tiene un archivo. Algún día.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Ahora ya tienes permiso para estar aquí.", To = "Yo" },
				{ S = "Cosme", T = "Aunque técnicamente nunca te lo di.", To = "Yo", Pause = 0.9 },
			},
		},
		Punto1 = {
			Lines = {
				{ S = "Narrador", T = "Finísimos. Como si alguien estuviera deshaciendo un jersey allá arriba. Uno toca el suelo.", Pause = 0.9 },
				{ S = "Narrador", T = "Donde tocan el suelo…" },
			},
		},
		Punto2 = { Lines = { { S = "Narrador", T = "Nadie parece verla." } } },
		Punto3 = {
			Lines = {
				{ S = "Narrador", T = "Clavado en el suelo. Es uno de tus anclajes.", Pause = 0.9 },
				{ S = "Narrador", T = "Lo clavaste tú.", If = { Memories = { "CoserElCielo" } } },
				{ S = "Narrador", T = "Todavía tienes el barro de aquella noche en la memoria.", Pause = 1.8, If = { Memories = { "CoserElCielo" } } },
			},
		},
	},
	Scenes = {
		Saga_07_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = { { At = 0.4, S = "Pip", T = "Consejo técnico. No deje que le hagan un jersey.", To = "Yo" } },
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Saga_07_G3_Entra" } } },
}
