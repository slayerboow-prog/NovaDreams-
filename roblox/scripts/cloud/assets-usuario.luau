-- assets-usuario: carga con AssetService:LoadAssetAsync los modelos que ha elegido Sebastián y los vuelca
--
-- No es una prueba del juego: sirve para saber qué hay dentro (MaterialVariants, MeshParts,
-- herramientas, scripts…) antes de usarlos. El volcado sale por la consola (usa -v) y queda en el
-- registro. Resultado escrito a mano en docs/assets-usuario.md.
-- Las texturas de un MaterialVariant (ColorMap…) no se pueden leer desde el servidor: no se miran.
--
-- Uso: bash scripts/cloud-test.sh -v assets-usuario

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)
local AssetService = game:GetService("AssetService")

local IDS = {
	11392874817, 13277933714, 14527172541, 15221806045, 15446413305,
	92927007790601, 8236576991, 101748452, 5849304432,
}
local NIVELES = 4 -- niveles del árbol que se enseñan (la raíz es el 0)
local MAX_HIJOS = 1000 -- hijos enseñados por nodo como mucho (el Mega Pack tiene 524)

local function r1(n: number): string
	return ("%.1f"):format(n)
end

local function talla(v: Vector3): string
	return r1(v.X) .. "x" .. r1(v.Y) .. "x" .. r1(v.Z)
end

-- Lee una propiedad sin romper si no se puede
local function lee(inst: Instance, prop: string): string
	local ok, v = pcall(function()
		return (inst :: any)[prop]
	end)
	if not ok then
		return "¿no se puede leer: " .. tostring(v):sub(1, 80) .. "?"
	end
	return tostring(v)
end

local function detalle(inst: Instance): string
	local t = {}
	if inst:IsA("MaterialVariant") then
		table.insert(t, "BaseMaterial=" .. lee(inst, "BaseMaterial"))
		table.insert(t, "StudsPerTile=" .. lee(inst, "StudsPerTile"))
		table.insert(t, "MaterialPattern=" .. lee(inst, "MaterialPattern"))
		local okp, cpp = pcall(function()
			return (inst :: any).CustomPhysicalProperties
		end)
		if okp and cpp then
			table.insert(t, "CustomPhysicalProperties=" .. tostring(cpp))
		end
	elseif inst:IsA("BasePart") then
		table.insert(t, "talla=" .. talla(inst.Size))
		table.insert(t, "mat=" .. inst.Material.Name)
		if inst.MaterialVariant ~= "" then
			table.insert(t, "MaterialVariant=" .. inst.MaterialVariant)
		end
		if inst:IsA("MeshPart") then
			table.insert(t, "MeshId=" .. lee(inst, "MeshId"))
			local tex = lee(inst, "TextureID")
			table.insert(t, "TextureID=" .. (if tex == "" then "no" else "sí (" .. tex .. ")"))
		end
		table.insert(t, "SurfaceAppearance=" .. (if inst:FindFirstChildWhichIsA("SurfaceAppearance") then "sí" else "no"))
		local sm = inst:FindFirstChildWhichIsA("SpecialMesh")
		if sm then
			table.insert(t, "SpecialMesh(MeshId=" .. lee(sm, "MeshId") .. ", TextureId=" .. lee(sm, "TextureId") .. ", Scale=" .. lee(sm, "Scale") .. ")")
		end
	elseif inst:IsA("Tool") then -- (va antes que Model: Tool hereda de Model)
		table.insert(t, "RequiresHandle=" .. lee(inst, "RequiresHandle"))
		table.insert(t, "TextureId=" .. lee(inst, "TextureId"))
	elseif inst:IsA("Model") then
		local ok, s = pcall(inst.GetExtentsSize, inst)
		if ok and s.Magnitude > 0 then
			table.insert(t, "talla=" .. talla(s))
		end
	elseif inst:IsA("LuaSourceContainer") then
		local ok, src = pcall(function()
			return (inst :: any).Source
		end)
		table.insert(t, "⚠ SCRIPT")
		if inst:IsA("BaseScript") then
			table.insert(t, "Enabled=" .. lee(inst, "Enabled"))
		end
		table.insert(t, if ok then ("Source legible (%d caracteres)"):format(#tostring(src)) else "Source NO legible: " .. tostring(src):sub(1, 100))
		if ok then
			print("SOURCE " .. inst:GetFullName() .. " >>>\n" .. tostring(src):sub(1, 1500) .. "\n<<<")
		end
	elseif inst:IsA("SurfaceAppearance") then
		table.insert(t, "(SurfaceAppearance)")
	elseif inst:IsA("Decal") then
		table.insert(t, "Texture=" .. lee(inst, "Texture"))
	elseif inst:IsA("ValueBase") then
		table.insert(t, "Value=" .. lee(inst, "Value"))
	end
	return table.concat(t, " ")
end

local function arbol(inst: Instance, ruta: string, nivel: number, cuenta: { [string]: any })
	cuenta.total += 1
	print(("%sL%d %s [%s] %s"):format(string.rep("  ", nivel), nivel, ruta, inst.ClassName, detalle(inst)))
	if nivel >= NIVELES then
		local n = #inst:GetDescendants()
		if n > 0 then
			print(("%s(… %d descendientes más, no enseñados)"):format(string.rep("  ", nivel + 1), n))
		end
		return
	end
	for i, h in inst:GetChildren() do
		if i > MAX_HIJOS then
			print(("%s… y %d hijos más"):format(string.rep("  ", nivel + 1), #inst:GetChildren() - MAX_HIJOS))
			break
		end
		arbol(h, ruta .. "/" .. h.Name, nivel + 1, cuenta)
	end
end

-- Resumen de todo el árbol (todos los niveles)
local function resumen(raiz: Instance): string
	local mv: { [string]: number } = {}
	local scripts, clases = {}, {}
	for _, d in raiz:GetDescendants() do
		clases[d.ClassName] = (clases[d.ClassName] or 0) + 1
		if d:IsA("MaterialVariant") then
			local b = lee(d, "BaseMaterial"):gsub("^Enum%.Material%.", "")
			mv[b] = (mv[b] or 0) + 1
		elseif d:IsA("LuaSourceContainer") then
			table.insert(scripts, d.ClassName .. ":" .. d:GetFullName())
		end
	end
	local a, b = {}, {}
	for k, n in mv do
		table.insert(a, k .. "=" .. n)
	end
	for k, n in clases do
		table.insert(b, k .. "=" .. n)
	end
	table.sort(a)
	table.sort(b)
	return ("MV[%s] SCRIPTS[%d: %s] CLASES[%s]"):format(table.concat(a, ","), #scripts, table.concat(scripts, " | "), table.concat(b, ","))
end

for _, id in IDS do
	print(("===== ID %d ====="):format(id))
	local ok, res = pcall(AssetService.LoadAssetAsync, AssetService, id)
	if not ok then
		print("FALLA " .. tostring(res))
		Cloud.aviso("ID " .. id, false, tostring(res))
	else
		print("CARGA raíz=" .. res.Name .. " [" .. res.ClassName .. "]")
		print("RESUMEN " .. resumen(res))
		arbol(res, res.Name, 0, { total = 0 })
		Cloud.check("ID " .. id, true, ("%d descendientes"):format(#res:GetDescendants()))
		res:Destroy()
	end
	print(("===== FIN %d ====="):format(id))
end

return Cloud.resultado()
