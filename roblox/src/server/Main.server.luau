-- Punto de entrada del servidor. Construye la ciudad y arranca todos los sistemas.
-- El orden importa: primero el mapa (los servicios buscan sus tags en él).

local Services = script.Parent.Services

-- La ciudad ya viene construida dentro de NovaLife.rbxlx (la genera scripts/build-place.luau).
-- Si no está (por ejemplo, al usar "rojo serve"), se construye ahora.
if not workspace:FindFirstChild("Town") then
	require(script.Parent.World.TownBuilder).build()
end

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
