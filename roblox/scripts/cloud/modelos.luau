-- modelos: carga modelos de la Tienda con InsertService:LoadAsset y vuelca lo que tienen dentro
--
-- No es una prueba del juego: sirve para saber qué hay dentro de cada modelo gratis de
-- docs/modelos-tienda.md (nombres, clases, tamaños, MeshParts, SurfaceAppearance, scripts…)
-- antes de usarlo desde código. El volcado sale por la consola (usa -v) y queda en el registro.
-- Resultado escrito a mano en docs/modelos-tienda-contenido.md (primera tanda, de la comunidad)
-- y docs/modelos-oficiales-2.md (segunda tanda: modelos oficiales de Roblox).
--
-- Uso: bash scripts/cloud-test.sh -v modelos

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)
local InsertService = game:GetService("InsertService")

-- Primera tanda (docs/modelos-tienda-contenido.md):
-- 6432306802, 6370681139, 10840661513, 6432233485, 3256343670, 9271152246, 10131972958, 10562894034,
-- 471214939, 12637929826, 185280084, 404475960, 8916801819, 11508587471, 8975295794, 5295646823, 12169860688
-- Segunda tanda (docs/modelos-oficiales-2.md): oficiales de Roblox (usuario 1 y grupo Roblox Resources)
local IDS = {
	-- edificios, casas y materiales
	13168370735, 6418277837, 6933556508, 13168345645, 10841357434, 10840642581,
	-- muebles
	10847897579,
	-- coches
	6418239833, 6433323089, 6418225759, 6418234850, 6418221666, 6433330180, 6433316269, 6418230807, 6433272094,
	-- grupo Roblox Resources (3529469)
	14215126016, 14447738661, 3703494811,
	-- plantillas (tienda y ciudad)
	12931234517, 12930997548,
	-- cielos
	311580, 47339, 47344, 47410,
}
local NIVELES = 3 -- niveles del árbol que se enseñan
local MAX_HIJOS = 80 -- hijos enseñados por nodo como mucho

local function r1(n: number): string
	return ("%.1f"):format(n)
end

local function talla(v: Vector3): string
	return r1(v.X) .. "x" .. r1(v.Y) .. "x" .. r1(v.Z)
end

-- Caja de todas las piezas de un nodo (vale también para Folder)
local function tamano(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Size
	elseif inst:IsA("Model") then
		local ok, s = pcall(inst.GetExtentsSize, inst)
		if ok and s.Magnitude > 0 then
			return s
		end
	end
	local lo, hi
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			local cf, s = d.CFrame, d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = cf:PointToWorldSpace(Vector3.new(sx * s.X, sy * s.Y, sz * s.Z))
						lo = if lo then lo:Min(p) else p
						hi = if hi then hi:Max(p) else p
					end
				end
			end
		end
	end
	return if lo then hi - lo else nil
end

-- Resumen de los descendientes (incluido el propio nodo)
local function resumen(inst: Instance): string
	local piezas, mesh, sa, tex, scripts, otros, mv, asientos, luces = 0, 0, 0, 0, 0, 0, 0, 0, 0
	local function mira(d: Instance)
		if d:IsA("BasePart") then
			piezas += 1
			if d:IsA("MeshPart") then
				mesh += 1
			end
		elseif d:IsA("SurfaceAppearance") then
			sa += 1
		elseif d:IsA("Decal") then -- Texture hereda de Decal
			tex += 1
		elseif d:IsA("LuaSourceContainer") then
			scripts += 1
		elseif d:IsA("SpecialMesh") then
			otros += 1
		elseif d:IsA("MaterialVariant") then
			mv += 1
		elseif d:IsA("Light") then
			luces += 1
		end
		if d:IsA("VehicleSeat") then
			asientos += 1
		end
	end
	mira(inst)
	for _, d in inst:GetDescendants() do
		mira(d)
	end
	local t = { ("piezas=%d"):format(piezas) }
	if mesh > 0 then
		table.insert(t, "MeshPart=" .. mesh)
	end
	if otros > 0 then
		table.insert(t, "SpecialMesh=" .. otros)
	end
	if sa > 0 then
		table.insert(t, "SurfaceAppearance=" .. sa)
	end
	if tex > 0 then
		table.insert(t, "Decal/Texture=" .. tex)
	end
	if mv > 0 then
		table.insert(t, "MaterialVariant=" .. mv)
	end
	if asientos > 0 then
		table.insert(t, "VehicleSeat=" .. asientos)
	end
	if luces > 0 then
		table.insert(t, "Light=" .. luces)
	end
	if scripts > 0 then
		table.insert(t, "⚠SCRIPTS=" .. scripts)
	end
	return table.concat(t, " ")
end

local function linea(inst: Instance, ruta: string, nivel: number)
	local extra = ""
	if inst:IsA("BasePart") then
		extra = " mat=" .. inst.Material.Name
		if inst:IsA("MeshPart") then
			extra ..= " MeshId=" .. inst.MeshId
		end
	elseif inst:IsA("LuaSourceContainer") then
		extra = if inst:IsA("BaseScript") then (" Enabled=" .. tostring(inst.Enabled)) else ""
	elseif inst:IsA("Sky") then
		local sky = inst :: any
		local ok, txt = pcall(function()
			return (" Bk=%s Dn=%s Ft=%s Lf=%s Rt=%s Up=%s Sun=%s Moon=%s SunAngular=%s CelestialBodies=%s StarCount=%d"):format(
				sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp,
				sky.SunTextureId, sky.MoonTextureId, tostring(sky.SunAngularSize), tostring(sky.CelestialBodiesShown),
				sky.StarCount
			)
		end)
		extra = if ok then txt else " (no se pudieron leer las propiedades: " .. tostring(txt) .. ")"
	elseif inst:IsA("MaterialVariant") then
		local m = inst :: any
		local ok, txt = pcall(function()
			return (" Base=%s StudsPerTile=%s"):format(m.BaseMaterial.Name, tostring(m.StudsPerTile))
		end)
		extra = if ok then txt else ""
	end
	local s = tamano(inst)
	print(("%s%s [%s]%s%s %s"):format(
		string.rep("  ", nivel),
		ruta,
		inst.ClassName,
		if s then " talla=" .. talla(s) else "",
		extra,
		resumen(inst)
	))
end

-- Clases que no merece la pena enseñar como nodo (ya salen en el resumen del padre)
local function esDetalle(inst: Instance): boolean
	return inst:IsA("SurfaceAppearance")
		or inst:IsA("Decal")
		or inst:IsA("SpecialMesh")
		or inst:IsA("JointInstance")
		or inst:IsA("WeldConstraint")
		or inst:IsA("Attachment")
		or inst:IsA("TouchTransmitter")
end

local function arbol(inst: Instance, ruta: string, nivel: number)
	linea(inst, ruta, nivel)
	if nivel >= NIVELES then
		return
	end
	local hijos = {}
	local ocultos: { [string]: number } = {}
	for _, h in inst:GetChildren() do
		if esDetalle(h) then
			ocultos[h.ClassName] = (ocultos[h.ClassName] or 0) + 1
		else
			table.insert(hijos, h)
		end
	end
	for i, h in hijos do
		if i > MAX_HIJOS then
			print(("%s… y %d hijos más"):format(string.rep("  ", nivel + 1), #hijos - MAX_HIJOS))
			break
		end
		arbol(h, ruta .. "/" .. h.Name, nivel + 1)
	end
	local o = {}
	for k, n in ocultos do
		table.insert(o, k .. "×" .. n)
	end
	if #o > 0 then
		table.sort(o)
		print(("%s(además: %s)"):format(string.rep("  ", nivel + 1), table.concat(o, ", ")))
	end
end

local function cargar(id: number): (boolean, any, string)
	local ok, res = pcall(InsertService.LoadAsset, InsertService, id)
	if ok then
		return true, res, "LoadAsset"
	end
	local err = tostring(res)
	local okv, ver = pcall(InsertService.GetLatestAssetVersionAsync, InsertService, id)
	if okv then
		local ok2, res2 = pcall(InsertService.LoadAssetVersion, InsertService, ver)
		if ok2 then
			return true, res2, "LoadAssetVersion(" .. tostring(ver) .. ") tras fallar LoadAsset: " .. err
		end
		return false, nil, "LoadAsset: " .. err .. " | LoadAssetVersion(" .. tostring(ver) .. "): " .. tostring(res2)
	end
	return false, nil, "LoadAsset: " .. err .. " | GetLatestAssetVersionAsync: " .. tostring(ver)
end

for _, id in IDS do
	print(("===== ID %d ====="):format(id))
	local ok, raiz, como = cargar(id)
	if not ok then
		print("FALLA " .. como)
		Cloud.aviso("ID " .. id, false, como)
	else
		print("CARGA con " .. como)
		arbol(raiz, raiz.Name, 0)
		Cloud.check("ID " .. id, true, resumen(raiz))
		raiz:Destroy()
	end
	print(("===== FIN %d ====="):format(id))
end

return Cloud.resultado()
