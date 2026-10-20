-- MallasRetiradas: las mallas que la moderación de Roblox ha retirado (docs/bugs/moderacion/) y cómo no
-- usarlas. Una malla retirada no se puede cargar: su MeshPart sale vacía (un brazo que falta, un trozo
-- de coral invisible). Los cargadores (World/AlienMeshLoader, World/MarMeshes, World/PuertoMeshes)
-- preguntan aquí y, si una pieza principal usa una malla retirada, ESE modelo o esa pieza sigue con su
-- versión de piezas (el respaldo de siempre). Nunca lanza error.
--
--   MallasRetiradas.Ids                         { [id de la malla] = qué era }   (los avisos de Roblox)
--   MallasRetiradas.idOf(valor) -> number?      "rbxassetid://123", "…?id=123" o 123
--   MallasRetiradas.meshIdOf(part) -> number?   el id de la malla de una MeshPart
--   MallasRetiradas.bad(parts, create?, probe?) -> { [id]: true }
--       las mallas de esas piezas que NO valen: las de la lista y, si se le da create (en el servidor:
--       AssetService:CreateMeshPartAsync, ver realCreate), las que de verdad no cargan, probando solo las
--       piezas de `probe` (o todas). Si NINGUNA carga, el que falla es la prueba (sin permiso, sin red):
--       entonces solo cuenta la lista.
--   MallasRetiradas.realCreate(timeout) -> ((string) -> any)?   (solo en el servidor)

local MallasRetiradas = {}

-- Los avisos del 20 oct 2026 (v124): segmentos sueltos de los Vórtidos de cristal subidos con
-- scripts/upload-invasion.sh --solo VortidosCristal («Contenido sexual»). Desde entonces los Vórtidos se
-- suben como UNA malla con esqueleto (VortidosCristal2) y todo pasa scripts/audit/moderacion-mallas.py.
MallasRetiradas.Ids = {
	[136955064198663] = "Vórtidos de cristal v124: antebrazo (ForeArm) suelto",
	[138746120321894] = "Vórtidos de cristal v124: pierna (LowerLeg) suelta",
} :: { [number]: string }

function MallasRetiradas.idOf(value: any): number?
	if type(value) == "number" then
		return if value > 0 then value else nil
	end
	if type(value) ~= "string" then
		return nil
	end
	local n = tonumber(string.match(value, "(%d+)%s*$") or "")
	return if n and n > 0 then n else nil
end

function MallasRetiradas.meshIdOf(part: Instance?): number?
	if not part then
		return nil
	end
	local ok, value = pcall(function()
		return (part :: any).MeshId
	end)
	return if ok then MallasRetiradas.idOf(value) else nil
end

function MallasRetiradas.retired(id: number?): boolean
	return id ~= nil and MallasRetiradas.Ids[id] ~= nil
end

function MallasRetiradas.bad(parts: { Instance }, create: ((string) -> any)?, probe: { Instance }?): { [number]: boolean }
	local out: { [number]: boolean } = {}
	for _, p in parts do
		local id = MallasRetiradas.meshIdOf(p)
		if id and MallasRetiradas.Ids[id] then
			out[id] = true
		end
	end
	if not create then
		return out
	end
	local seen: { [number]: boolean } = {}
	local failed: { number } = {}
	local loaded = 0
	for _, p in probe or parts do
		local id = MallasRetiradas.meshIdOf(p)
		if id and not seen[id] and not out[id] then
			seen[id] = true
			local ok, made = pcall(create, "rbxassetid://" .. id)
			if ok and made ~= nil then
				loaded += 1
				if typeof(made) == "Instance" then
					pcall(function()
						made:Destroy()
					end)
				end
			else
				table.insert(failed, id)
			end
		end
	end
	if loaded > 0 then
		for _, id in failed do
			out[id] = true
		end
	end
	return out
end

-- (servidor) AssetService:CreateMeshPartAsync con un tope de tiempo: si tarda, se da por buena
function MallasRetiradas.realCreate(timeout: number?): ((string) -> any)?
	local ok, AssetService = pcall(function()
		return game:GetService("AssetService")
	end)
	if not ok or not AssetService then
		return nil
	end
	local limit = timeout or 8
	return function(content: string): any
		local done, result, err = false, nil, nil
		task.spawn(function()
			local okC, made = pcall(function()
				return (AssetService :: any):CreateMeshPartAsync(content)
			end)
			if okC then
				result = made
			else
				err = made
			end
			done = true
		end)
		local t0 = os.clock()
		while not done and os.clock() - t0 < limit do
			task.wait(0.1)
		end
		if not done then
			return true -- (no contestó a tiempo: no se puede decir que esté retirada)
		end
		if err ~= nil then
			error(err)
		end
		return result
	end
end

return MallasRetiradas
