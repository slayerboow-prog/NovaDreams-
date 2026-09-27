-- Hospital: reglas de la muerte (HospitalService en el servidor y DeathUI en el cliente).
--
--   * Se puede morir: si te quedas sin vida por un golpe primero caes K.O. (Combat), pero si
--     alguien te remata en el suelo, mueres; también al ahogarte, al caer desde muy alto…
--   * Al morir sale la pantalla de HAS MUERTO y reapareces en el hospital más cercano.
--   * El hospital cobra la factura (lo que puedas pagar) y pierdes las estrellas de búsqueda.
--   * Si estás en la cárcel, reapareces en tu celda (la enfermería de la prisión).

local Hospital = {}

Hospital.RespawnSeconds = 6 -- lo que dura la pantalla de HAS MUERTO
Hospital.Bill = 150 -- factura del hospital (si tienes menos, pagas lo que tengas)
Hospital.Models = { "Hospital", "CentroSalud" } -- edificios en los que se reaparece

-- Lo que cobra el hospital a quien tiene "money"
function Hospital.bill(money: number): number
	return math.clamp(math.floor(money), 0, Hospital.Bill)
end

return Hospital
