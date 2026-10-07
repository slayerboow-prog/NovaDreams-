-- Mapa del guion reescrito de Bebe_HoraDeSalir (lo lee scripts/audit/aplicar-reescritura.luau).
-- En el juego: 1 = asomarte al ventanal (LookedOutside; al hacerlo, BabyService pone la escena del
-- ventanal con tu familia) y 2 = el cambio de etapa (Transition con el montaje Montaje_Bebe_Nino).
return {
	Prefijo = "Bebe_Salir",
	-- PASO 1 (asomarte al ventanal) es la escena del ventanal que pone BabyService al mirar: se cuenta
	-- con el guion nuevo. PASO 2-6 son el MONTAJE de cambio de etapa: no se aplican (ver Informe).
	Escenas = { ["1"] = "Bebe_VentanalFamilia" },
	Pasos = { ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["6"] = false },
	Lugares = { "HomeSalon", "Ventanal", "CasaFamiliar", "HomeDormitorio", "EntradaColegio", "Patio", "PasilloColegio", "AulaA", "Colegio", "FamiliaAbu", "FamiliaPadre" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu", Lucia = "EntradaColegio", Nico = "Patio", Sara = "Patio", Omar = "Patio" },
	Hablantes = { ["Mamá/Papá"] = "Familia" },
	Sujetos = {
		["Mamá/Papá"] = "Familia",
		["Salón"] = "Lugar:HomeSalon",
		Ventanal = "Lugar:Ventanal",
		Valmar = "Grande:CasaFamiliar",
		Ciudad = "Grande:CasaFamiliar",
		Casa = "Grande:CasaFamiliar",
		["Habitación"] = "Lugar:HomeDormitorio",
		["Fotografía familiar"] = "Lugar:HomeSalon",
		["Fotografía"] = "Lugar:HomeSalon",
		["Fotografías"] = "Lugar:HomeSalon",
		Bloques = "Lugar:HomeDormitorio",
		Juguete = "Lugar:HomeDormitorio",
		["Zapatos infantiles"] = "Lugar:HomeSalon",
		Parque = "Grande:CasaFamiliar",
		["Niño"] = "Yo",
		["Mano infantil"] = "Yo",
		Mano = "Yo",
		Mochila = "Yo",
		["Entrada de Los Pinos"] = "Lugar:EntradaColegio",
		Entrada = "Lugar:EntradaColegio",
		["Puerta del colegio"] = "Lugar:EntradaColegio",
		Patio = "Lugar:Patio",
		["Lápiz de Omar"] = "Omar",
		Colegio = "Grande:Colegio",
		Pasillo = "Lugar:PasilloColegio",
		Aula = "Lugar:AulaA",
		["Cuaderno vacío"] = "Lugar:AulaA",
	},
	Informe = "PASO 1 (el ventanal) reescribe la escena Bebe_VentanalFamilia, la que pone BabyService cuando te asomas (el paso 1 de la misión se cumple igual: asomarte). PASO 2-6 (los años que pasan, Los Pinos, la Profe Lucía en la puerta, el aula) son el montaje de cambio de etapa Montaje_Bebe_Nino, que NO se cambia: el montaje tiene un diseño fijo que comprueba test-etapas (25-40 s, «fotos vivas» de los recuerdos que de verdad viviste, el jugador solo aparece en la llegada, la música de «Pasan los años»…) y el guion lo convierte en una película de casi 4 minutos con planos del niño creciendo. Queda pendiente decidir si se acorta el guion a ese formato o se cambia el diseño del montaje; mientras, el montaje de siempre sigue. La llegada a Los Pinos con la Profe Lucía ya la cuenta el principio de Cole01 (también reescrito). FLAG DE MEMORIA: la etapa (Nino), la misión completada y que se desbloquee Cole01 ya los hace el juego; los recuerdos «ElPrimerColegio» y «LaVistaDesdeElVentanal» no existen en Memories y no se inventan.",
}
