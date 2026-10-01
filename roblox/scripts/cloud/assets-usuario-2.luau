-- assets-usuario-2: segunda tanda de modelos elegidos por Sebastián (estanterías, árboles, ciudad…)
--
-- Como assets-usuario.luau: los carga con AssetService:LoadAssetAsync y los vuelca por la consola
-- (usa -v; el registro completo queda en ${TMPDIR:-/tmp}/cloud-test/assets-usuario-2.log).
-- Resultado escrito a mano en docs/assets-usuario-2.md.
-- Por cada asset: resumen por clases, modelos de nivel 1 y 2 con talla y piezas, MaterialVariants,
-- Decal/Texture/SurfaceAppearance, Sounds, scripts (con el principio del Source), piezas rojas
-- (¿sangre?) y palabras peligrosas en los scripts. Los triángulos no: EditableMesh no tiene permiso
-- con mallas de otros creadores (salen del toolbox, ver el doc).
--
-- Uso: bash scripts/cloud-test.sh -v assets-usuario-2

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)
local AssetService = game:GetService("AssetService")

local IDS = {
	13395313510, 15666503758, 12433695725, 12527638598, 7105428424, 96924659951632, 99479110531330,
}
local MAX_FILAS = 200 -- filas como mucho por lista y asset
-- Palabras que en un script de la comunidad pueden ser una puerta trasera o algo raro
local PELIGRO = {
	"require(", "getfenv", "setfenv", "loadstring", "HttpService", "MarketplaceService", "TeleportService",
	"InsertService", "LoadAsset", "string.reverse", "string.char", "\\x", "Kick", "Destroy()", "ChildAdded",
	"PlayerAdded", "RemoteEvent", "FireServer", "FireClient",
}

local function r1(n: number): string
	return ("%.1f"):format(n)
end

local function talla(v: Vector3): string
	return r1(v.X) .. "x" .. r1(v.Y) .. "x" .. r1(v.Z)
end

local function lee(inst: Instance, prop: string): string
	local ok, v = pcall(function()
		return (inst :: any)[prop]
	end)
	if not ok then
		return "¿?"
	end
	return tostring(v)
end

local function tallaDe(inst: Instance): string
	if inst:IsA("BasePart") then
		return talla(inst.Size)
	elseif inst:IsA("Model") then
		local ok, s = pcall(inst.GetExtentsSize, inst)
		if ok then
			return talla(s)
		end
	end
	return "-"
end

-- Cuenta lo que hay debajo (y el propio nodo)
local function cuenta(inst: Instance): string
	local c = { part = 0, mesh = 0, sa = 0, tex = 0, decal = 0, sound = 0, script = 0, mv = 0 }
	local lista = inst:GetDescendants()
	table.insert(lista, inst)
	for _, d in lista do
		if d:IsA("BasePart") then
			c.part += 1
		end
		if d:IsA("MeshPart") then
			c.mesh += 1
		elseif d:IsA("SurfaceAppearance") then
			c.sa += 1
		elseif d:IsA("Texture") then
			c.tex += 1
		elseif d:IsA("Decal") then
			c.decal += 1
		elseif d:IsA("Sound") then
			c.sound += 1
		elseif d:IsA("LuaSourceContainer") then
			c.script += 1
		elseif d:IsA("MaterialVariant") then
			c.mv += 1
		end
	end
	return ("piezas=%d MeshPart=%d SA=%d Texture=%d Decal=%d Sound=%d scripts=%d MV=%d"):format(
		c.part, c.mesh, c.sa, c.tex, c.decal, c.sound, c.script, c.mv)
end

local function fila(inst: Instance, nivel: number)
	print(("N%d %s [%s] talla=%s %s"):format(nivel, inst:GetFullName(), inst.ClassName, tallaDe(inst), cuenta(inst)))
end

local function vuelca(raiz: Instance)
	local clases = {}
	for _, d in raiz:GetDescendants() do
		clases[d.ClassName] = (clases[d.ClassName] or 0) + 1
	end
	local b = {}
	for k, n in clases do
		table.insert(b, k .. "=" .. n)
	end
	table.sort(b)
	print("CLASES " .. table.concat(b, ","))
	print("TOTAL " .. cuenta(raiz))

	-- Nivel 1 y 2
	local n = 0
	for _, h in raiz:GetChildren() do
		n += 1
		if n > MAX_FILAS then
			print("… más hijos de nivel 1")
			break
		end
		fila(h, 1)
		local m = 0
		for _, g in h:GetChildren() do
			if g:IsA("Model") or g:IsA("Folder") or g:IsA("BasePart") then
				m += 1
				if m > 300 then
					print("   … más hijos de nivel 2 en " .. h.Name)
					break
				end
				fila(g, 2)
			end
		end
	end

	-- Listas por tipo
	local mostrados = { obj = 0, mv = 0, sa = 0, vis = 0, sound = 0, rojo = 0, mesh = 0 }
	for _, d in raiz:GetDescendants() do
		if d:IsA("MaterialVariant") then
			print(("MV %s BaseMaterial=%s StudsPerTile=%s MaterialPattern=%s"):format(
				d:GetFullName(), lee(d, "BaseMaterial"), lee(d, "StudsPerTile"), lee(d, "MaterialPattern")))
		elseif d:IsA("SurfaceAppearance") then
			mostrados.sa += 1
			if mostrados.sa <= 30 then
				print(("VIS %s [SurfaceAppearance]"):format(d:GetFullName()))
			end
		elseif d:IsA("Decal") then -- (Texture hereda de Decal)
			mostrados.vis += 1
			if mostrados.vis <= MAX_FILAS then
				print(("VIS %s [%s] Face=%s Texture=%s"):format(d:GetFullName(), d.ClassName, lee(d, "Face"), lee(d, "Texture")))
			end
		elseif d:IsA("TextLabel") or d:IsA("Accessory") then
			print(("OTRO %s [%s] %s"):format(d:GetFullName(), d.ClassName, if d:IsA("TextLabel") then "Text=" .. lee(d, "Text") else ""))
		elseif d:IsA("SpecialMesh") then
			print(("SPECIALMESH %s MeshId=%s TextureId=%s Scale=%s"):format(d:GetFullName(), lee(d, "MeshId"), lee(d, "TextureId"), lee(d, "Scale")))
		elseif d:IsA("Sound") then
			mostrados.sound += 1
			if mostrados.sound <= 40 then
				print(("SONIDO %s SoundId=%s Playing=%s Looped=%s"):format(d:GetFullName(), lee(d, "SoundId"), lee(d, "Playing"), lee(d, "Looped")))
			end
		elseif d:IsA("LuaSourceContainer") then
			local ok, src = pcall(function()
				return (d :: any).Source
			end)
			print(("⚠ SCRIPT %s [%s] Enabled=%s %s"):format(d:GetFullName(), d.ClassName, lee(d, "Enabled"),
				if ok then ("(%d caracteres)"):format(#tostring(src)) else "Source NO legible"))
			if ok then
				print("SOURCE >>>\n" .. tostring(src):sub(1, 900) .. "\n<<<")
				local hay = {}
				for _, pal in PELIGRO do
					if tostring(src):find(pal, 1, true) then
						table.insert(hay, pal)
					end
				end
				if tostring(src):find("require%(%s*%d") then
					table.insert(hay, "require(NÚMERO) ⛔")
				end
				print("PELIGRO " .. d:GetFullName() .. ": " .. (if #hay > 0 then table.concat(hay, ", ") else "nada"))
			end
		elseif d:IsA("BasePart") then
			local c = d.Color
			local nombre = d.Name:lower()
			if (c.R > 0.45 and c.G < 0.2 and c.B < 0.2) or nombre:find("blood") or nombre:find("кров") or nombre:find("gore") then
				mostrados.rojo += 1
				if mostrados.rojo <= 40 then
					print(("ROJO %s [%s] talla=%s color=%d,%d,%d mat=%s"):format(d:GetFullName(), d.ClassName, talla(d.Size),
						math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255), d.Material.Name))
				end
			end
			if d:IsA("MeshPart") then
				mostrados.mesh += 1
				if mostrados.mesh <= MAX_FILAS then
					local id = lee(d, "MeshId")
					print(("MALLA %s talla=%s MeshId=%s TextureID=%s"):format(d:GetFullName(), talla(d.Size), id,
						lee(d, "TextureID")))
				end
			end
		end
		-- Objetos sueltos: Model o pieza cuyo padre es una Folder o la raíz (no está dentro de otro Model)
		if (d:IsA("Model") or d:IsA("BasePart")) and d.Parent and (d.Parent:IsA("Folder") or d.Parent == raiz) then
			mostrados.obj += 1
			if mostrados.obj <= 2500 then
				print(("OBJETO %s [%s] talla=%s %s"):format(d:GetFullName(), d.ClassName, tallaDe(d), cuenta(d)))
			end
		end
		if Cloud.quedan and Cloud.quedan() < 20 then
			print("CORTE por tiempo")
			break
		end
	end
	print(("CUENTAS vis=%d sonidos=%d rojos=%d mallas=%d"):format(mostrados.vis, mostrados.sound, mostrados.rojo, mostrados.mesh))
end

for _, id in IDS do
	print(("===== ID %d ====="):format(id))
	local ok, res = pcall(AssetService.LoadAssetAsync, AssetService, id)
	if not ok then
		print("FALLA " .. tostring(res))
		Cloud.aviso("ID " .. id, false, tostring(res))
	else
		print("CARGA raíz=" .. res.Name .. " [" .. res.ClassName .. "] talla=" .. tallaDe(res))
		local ok2, err = pcall(vuelca, res)
		if not ok2 then
			print("ERROR al volcar: " .. tostring(err))
		end
		Cloud.check("ID " .. id, true, ("%d descendientes"):format(#res:GetDescendants()))
		res:Destroy()
	end
	print(("===== FIN %d ====="):format(id))
end

return Cloud.resultado()
