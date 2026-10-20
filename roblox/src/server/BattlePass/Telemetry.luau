-- Telemetry: telemetría interna mínima del pase de temporada (contadores en memoria del servidor).
-- El juego no tenía analítica propia: esto es un gancho ligero. Cuenta aperturas, compras, niveles,
-- recompensas y misiones; opcionalmente lo manda a AnalyticsService de Roblox
-- (BattlePassConfig.Telemetry.UseAnalyticsService). Nunca rompe nada: todo va con pcall.
--
--   Telemetry.count("Open")                          -- suma 1 a un contador
--   Telemetry.count("RewardClaimed", "S1_F05")       -- contador con detalle
--   Telemetry.snapshot()                             -- copia de los contadores (depuración, pruebas)

local Telemetry = {}

local counters: { [string]: number } = {}
local useAnalytics = false
local analytics: any = nil

function Telemetry.configure(options: { UseAnalyticsService: boolean? }?)
	useAnalytics = options ~= nil and options.UseAnalyticsService == true
	if useAnalytics and not analytics then
		pcall(function()
			analytics = game:GetService("AnalyticsService")
		end)
	end
end

function Telemetry.count(event: string, detail: string?, player: Player?, amount: number?)
	local key = if detail then event .. ":" .. detail else event
	counters[key] = (counters[key] or 0) + (amount or 1)
	if useAnalytics and analytics and player then
		pcall(function()
			analytics:LogCustomEvent(player, "BattlePass_" .. event, amount or 1)
		end)
	end
end

function Telemetry.get(event: string, detail: string?): number
	return counters[if detail then event .. ":" .. detail else event] or 0
end

function Telemetry.snapshot(): { [string]: number }
	return table.clone(counters)
end

return Telemetry
