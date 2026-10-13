-- FxBudget: cuántos efectos del combate aéreo se permiten según el nivel gráfico (UI/Perf: Low, Medium,
-- High). Los efectos son grandes y contundentes (explosiones con chispas gordas, humo y restos en llamas
-- que caen, estelas que brillan, destellos y ondas del escudo), pero en el móvil con tope: menos
-- partículas, menos trazadoras y restos a la vez y sin luces de verdad en Bajo. Lo usa Controllers/AirCombatFx (y lo prueba scripts/test-aircombat.luau).

local FxBudget = {}

export type Budget = {
	Tracers: number, -- trazadoras de láser a la vez
	Missiles: number, -- misiles con estela a la vez
	Sparks: number, -- chispas de un estallido grande
	Debris: number, -- trozos que salen volando de un estallido
	Smoke: number, -- humo por segundo de cada misil
	Lights: boolean, -- destello con luz de verdad (PointLight)
	Trails: boolean, -- estela (Trail) en los misiles y en las trazadoras largas
	Bursts: number, -- estallidos a la vez (los de más se simplifican a un destello)
	Wrecks: number, -- restos en llamas que suelta un estallido grande
	WreckMax: number, -- restos a la vez en total
	WreckFire: number, -- fuego por segundo de cada resto
}

FxBudget.Tiers = {
	Low = { Tracers = 28, Missiles = 4, Sparks = 14, Debris = 3, Smoke = 10, Lights = false, Trails = false, Bursts = 3, Wrecks = 2, WreckMax = 8, WreckFire = 12 },
	Medium = { Tracers = 60, Missiles = 8, Sparks = 28, Debris = 6, Smoke = 22, Lights = true, Trails = true, Bursts = 5, Wrecks = 3, WreckMax = 16, WreckFire = 22 },
	High = { Tracers = 110, Missiles = 12, Sparks = 46, Debris = 10, Smoke = 36, Lights = true, Trails = true, Bursts = 8, Wrecks = 5, WreckMax = 28, WreckFire = 34 },
} :: { [string]: Budget }

function FxBudget.get(tier: string?): Budget
	return FxBudget.Tiers[tier or "Medium"] or FxBudget.Tiers.Medium
end

-- Cuántas chispas para un estallido de tamaño `size` (0..1: dron pequeño … nave)
function FxBudget.sparks(tier: string?, size: number): number
	local b = FxBudget.get(tier)
	return math.max(4, math.floor(b.Sparks * math.clamp(size, 0.2, 1) + 0.5))
end

-- Colores vivos de cada cosa (bien distintos: se lee de un vistazo en el móvil)
FxBudget.Colors = {
	Laser = Color3.fromRGB(80, 230, 255),
	LaserCore = Color3.fromRGB(230, 255, 255),
	Enemy = Color3.fromRGB(255, 70, 90),
	EnemyCore = Color3.fromRGB(255, 220, 200),
	Missile = Color3.fromRGB(255, 170, 40),
	Smoke = Color3.fromRGB(235, 230, 225),
	BoomCore = Color3.fromRGB(255, 245, 190),
	BoomGlow = Color3.fromRGB(255, 120, 40),
	BoomRing = Color3.fromRGB(255, 200, 70),
	Spark = { Color3.fromRGB(255, 225, 120), Color3.fromRGB(255, 130, 40), Color3.fromRGB(255, 250, 235), Color3.fromRGB(220, 60, 30) }, -- (fuego: amarillo, naranja, blanco y rojo)
	Shield = Color3.fromRGB(90, 200, 255),
}

return FxBudget
