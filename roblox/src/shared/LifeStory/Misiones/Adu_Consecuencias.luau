-- Consecuencias de la vida adulta: misiones pequeñas que nacen de lo que hiciste (Later), horas después.

local V = Vector3.new

return {
	{
		Id = "Eco_Factura",
		Kind = "Side",
		Title = "Un aviso en el buzón",
		Description = "Las facturas que dejaste para luego han vuelto. Con amigos.",
		Type = "Consecuencia (2 h después de «Mi primer contrato», si dejaste las facturas para luego)",
		Duration = { 3, 5 },
		Npcs = { "Ignacio" },
		Requires = { Stage = { Min = "AdultoJoven" } },
		Moment = "Aprendiste lo que es un recargo",
		Steps = {
			{ Type = "Reach", Place = "Banco", Text = "Te ha llegado un aviso de recargo: ve al banco a pagar las facturas",
				Actors = { { Npc = "Ignacio", Place = "Banco", Offset = V(0, 0, 4) } } },
			{ Type = "Talk", Npc = "Ignacio", Dialogue = "Recargo", Text = "Habla con Ignacio",
				Actors = { { Npc = "Ignacio", Place = "Banco", Offset = V(0, 0, 4) } } },
		},
		Dialogues = {
			Recargo = { Lines = {
				{ S = "Ignacio", T = "Las facturas de la planta, ¿eh? Todo el mundo lo hace una vez. Ahora vienen con un pequeño recargo por el retraso." },
				{ S = "Ignacio", T = "Lo pagamos y te enseño a domiciliarlas: se pagan solas el día uno. Así la planta puede volver a ser solo una planta." },
			}, Effects = { Spend = 75, Unflags = { "FacturaPendiente" }, Traits = { Responsabilidad = 1 } } },
		},
	},
}
