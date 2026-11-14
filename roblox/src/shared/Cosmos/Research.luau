-- Research: la INVESTIGACIÓN del laboratorio de la Estación Vigía (expansión «La Deriva», fase 2;
-- docs/espacio-aaa/expansion-15h.md §9). Cuentas puras: las usan Services/SpaceService (menú y compra),
-- Services/ShipSystems (escáner) y las pruebas (scripts/test-vigia.luau).
--
-- Da un uso de verdad a los 📡 Datos (se consiguen escaneando): mejoras PERMANENTES de la cuenta, en tres
-- ramas cortas. Cada nodo pide el anterior de su rama. Lo comprado se guarda en data.Space.Research.
--   Exploración: Escáner de largo alcance (+25 % de radio) → Lectura fina (+50 % de Datos al escanear)
--   Combate:     Reciclaje de restos (+15 % de probabilidad de Componentes) → Desguace (+1 Componente por pieza)
--   Comercio:    Aleaciones del Instituto (−15 % de dinero en los módulos) → Contactos (+20 % de paga en
--                los contratos)
-- Se abre al terminar «La anomalía que canta» (Misiones/Deriva_ActoI: Deriva_00_Canto).

local Research = {}

export type Node = { Id: string, Branch: string, Name: string, Text: string, Needs: string?, Datos: number, Money: number, Componentes: number? }

Research.Nodes = {
	{ Id = "EscanerLargo", Branch = "Exploración", Name = "Escáner de largo alcance", Text = "+25 % de radio del escáner", Needs = nil, Datos = 15, Money = 1500 },
	{ Id = "LecturaFina", Branch = "Exploración", Name = "Lectura fina", Text = "+50 % de Datos al escanear", Needs = "EscanerLargo", Datos = 35, Money = 3500 },
	{ Id = "Reciclaje", Branch = "Combate", Name = "Reciclaje de restos", Text = "+15 % de probabilidad de sacar Componentes al derribar", Needs = nil, Datos = 15, Money = 1500 },
	{ Id = "Desguace", Branch = "Combate", Name = "Desguace", Text = "+1 Componente cada vez que salen", Needs = "Reciclaje", Datos = 35, Money = 3500, Componentes = 8 },
	{ Id = "Aleaciones", Branch = "Comercio", Name = "Aleaciones del Instituto", Text = "−15 % de dinero al mejorar módulos", Needs = nil, Datos = 20, Money = 2000 },
	{ Id = "Contactos", Branch = "Comercio", Name = "Contactos en las estaciones", Text = "+20 % de paga en los contratos de los tablones", Needs = "Aleaciones", Datos = 40, Money = 4000 },
} :: { Node }

Research.ById = {} :: { [string]: Node }
for _, n in Research.Nodes do
	Research.ById[n.Id] = n
end

Research.UnlockFlag = "VigiaAbierta" -- (la bandera de la historia que abre el laboratorio)

-- ¿Se puede investigar este nodo? (true) o el motivo: "Desconocido" | "Hecho" | "Falta" (el anterior)
function Research.canBuy(done: { [string]: any }?, id: string): (boolean, string?)
	local n = Research.ById[id]
	if not n then
		return false, "Desconocido"
	end
	local d = done or {}
	if d[id] then
		return false, "Hecho"
	end
	if n.Needs and not d[n.Needs] then
		return false, "Falta"
	end
	return true, nil
end

-- Lo que dan las investigaciones hechas
function Research.effects(done: { [string]: any }?): { ScanRadius: number, DatosMult: number, CompChance: number, CompBonus: number, ModuleMoney: number, ContractPay: number }
	local d = done or {}
	return {
		ScanRadius = if d.EscanerLargo then 1.25 else 1,
		DatosMult = if d.LecturaFina then 1.5 else 1,
		CompChance = if d.Reciclaje then 0.15 else 0,
		CompBonus = if d.Desguace then 1 else 0,
		ModuleMoney = if d.Aleaciones then 0.85 else 1,
		ContractPay = if d.Contactos then 1.2 else 1,
	}
end

return Research
