-- Mapa del guion reescrito de Ins02_Clubes (lo lee scripts/audit/aplicar-reescritura.luau).
-- 40 PASO = los 29 pasos del juego con sus subpasos (los cinco puestos, la investigación de los murales
-- y el paseo fotográfico). Cada club conserva su rama (If) y su minijuego.
return {
	Prefijo = "Ins02",
	Variables = {
		["existe la decision original de perdonar a ruben"] = { If = { Flags = { "Ruben_Perdonado" } } },
		["la decision original de perdonar a ruben"] = { If = { Flags = { "Ruben_Perdonado" } } },
		-- (la audición de teatro: el minijuego del paso 11)
		["lo hace bien"] = { Gana = "11" },
	},
	Informe = "La mecánica es la de siempre: la feria (al menos tres puestos), el club que eliges y su rama (baloncesto, teatro, robótica con el robot que se escapa, periódico con los murales de Vega, fotografía), el dilema y el evento del club o el cumpleaños de Nico. Lo que Rubén dice si le perdonaste en primaria sale con Ruben_Perdonado. «Si lo hace bien» en la audición es ganar el minijuego del paso 11.",
}
