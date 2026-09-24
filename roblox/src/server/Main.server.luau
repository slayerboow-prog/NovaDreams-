-- Punto de entrada del servidor. Construye la ciudad y arranca todos los sistemas.
-- El orden importa: primero el mapa (los servicios buscan sus tags en él).

local Services = script.Parent.Services

require(script.Parent.World.TownBuilder).build()

local order = {
	"DataService",
	"MonetizationService",
	"NeedsService",
	"WorldService",
	"JobService",
	"FoodService",
	"HouseService",
}

for _, name in order do
	local ok, err = pcall(function()
		require(Services[name]).init()
	end)
	if not ok then
		warn(("[Main] Error iniciando %s: %s"):format(name, tostring(err)))
	end
end

print("[Nova Life] Servidor listo ✅")
