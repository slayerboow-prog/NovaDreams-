-- Taxes: la declaración de la renta de Valmar (TaxService en el servidor).
--
--   * Lo que ganas trabajando cuenta para tu renta (DataService: dinero ganado).
--   * Cada "ejercicio" (Period segundos jugados) hay campaña de la renta: toca presentar la
--     declaración en la Agencia Tributaria (ventanilla o un agente de Hacienda de servicio).
--   * Se paga Rate de lo ganado por encima del mínimo exento. Quien no presenta en Grace
--     ejercicios recibe una inspección: recargo del Surcharge sobre la cuota.

local Taxes = {}

Taxes.Rate = 0.10
Taxes.Exempt = 150 -- lo ganado hasta aquí no paga
Taxes.Period = 40 * 60 -- segundos jugados por ejercicio
Taxes.Grace = 2 -- ejercicios sin presentar antes de la inspección
Taxes.Surcharge = 0.2
Taxes.AgentPay = 20 -- por declaración tramitada
Taxes.InspectorPay = 45 -- por inspección

-- Cuota a pagar por lo ganado en un ejercicio
function Taxes.due(earned: number): number
	return math.max(0, math.floor((earned - Taxes.Exempt) * Taxes.Rate + 0.5))
end

-- Con recargo (inspección por no declarar)
function Taxes.withSurcharge(amount: number): number
	return math.floor(amount * (1 + Taxes.Surcharge) + 0.5)
end

return Taxes
