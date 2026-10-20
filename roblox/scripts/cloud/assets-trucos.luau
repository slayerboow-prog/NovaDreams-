-- assets-trucos: vuelve a mirar los assets de las tandas 1-3 (y los que ya usa el juego) buscando los
-- trucos de puerta trasera que aparecieron en la 4ª tanda (docs/assets-usuario-4.md):
--   * require(algo.Value) con el número escondido en un NumberPose u otro *Value ("SkyLink", "PoseLink")
--   * código escrito al revés en un atributo (PlaneConstraint) o como lista de números (string.char)
--   * GetObjects, HttpEnabled, "CoreValidation", "Texture Streaming", "TextureConfiguration"
-- Solo enseña lo que encuentra (una línea por hallazgo) y un resumen por asset. No ejecuta nada.
--
-- Uso: bash scripts/cloud-test.sh -v assets-trucos

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)
local AssetService = game:GetService("AssetService")

local IDS = { -- @@IDS@@
	100792423689137, 101748452, 103449549978145, 113264079562085, 11347783499, 11392874817, 117850698505269,
	123159368741340, 123553303846741, 12433695725, 12527638598, 130843005739076, 13168345645, 13168370735,
	13262637537, 13277933714, 13388285234, 13395313510, 13728551087, 13752145820, 13877830677, 14527172541,
	15004077857, 15221806045, 15446413305, 15666503758, 16088161488, 16879341926, 17519952806, 4609898985,
	5849304432, 7105428424, 7485807340, 82042358715900, 8236576991, 8553512581, 8919681750, 9262569938,
	92927007790601, 9432856072, 96924659951632, 9802494780, 99479110531330,
}
local MAX_POR_ASSET = 15 -- líneas de hallazgo como mucho por asset (el resto solo se cuenta)

-- Palabras en el código. Las de MUY son puerta trasera casi seguro.
local MUY = {
	"GetObjects", "HttpEnabled", "loadstring", "getfenv", "setfenv", "string.char", "string.reverse",
	"CoreValidation", "Texture Streaming", "TextureConfiguration", "Model corruption",
}
local RARO = { "MarketplaceService", "TeleportService", "InsertService", "HttpService", ":Kick(" }
-- Nombres de objeto que usan los virus de la 4ª tanda
local NOMBRES = { SkyLink = true, PoseLink = true, BloomDefect = true, VFXParticles = true, FXBuilder = true, CoreValidation = true }

local function invertir(s: string): string
	return s:reverse()
end

local function mira(raiz: Instance)
	local n, hallazgos, scripts = 0, 0, 0
	local function nota(texto: string)
		hallazgos += 1
		if hallazgos <= MAX_POR_ASSET then
			print("  ⚠ " .. texto)
		end
	end
	for _, d in raiz:GetDescendants() do
		n += 1
		if NOMBRES[d.Name] then
			nota(("NOMBRE %s [%s]"):format(d:GetFullName(), d.ClassName))
		end
		if d:IsA("NumberPose") then
			nota(("NumberPose %s Value=%s"):format(d:GetFullName(), tostring((d :: any).Value)))
		end
		-- Atributos: textos largos (código escondido) o que, al revés, dicen GetObjects/require
		local ok, atr = pcall(d.GetAttributes, d)
		if ok then
			for k, v in atr do
				if type(v) == "string" and #v > 40 then
					local r = invertir(v)
					local raro = v:find("GetObjects", 1, true) or r:find("GetObjects", 1, true)
						or v:find("require", 1, true) or r:find("require", 1, true)
					nota(("ATRIBUTO %s [%s] %s (%d letras)%s: %s"):format(d:GetFullName(), d.ClassName, k, #v,
						if raro then " ⛔" else "", (if r:find("GetObjects", 1, true) then r else v):sub(1, 200)))
				elseif type(v) == "number" and v > 1e9 and v < 1e15 and math.floor(v) == v then
					nota(("ATRIBUTO numérico %s [%s] %s=%d (¿id de asset?)"):format(d:GetFullName(), d.ClassName, k, v))
				end
			end
		end
		if d:IsA("LuaSourceContainer") then
			scripts += 1
			local okS, src = pcall(function()
				return (d :: any).Source
			end)
			local texto = if okS then tostring(src) else ""
			local hay = {}
			for _, p in MUY do
				if texto:find(p, 1, true) then
					table.insert(hay, p .. "⛔")
				end
			end
			for _, p in RARO do
				if texto:find(p, 1, true) then
					table.insert(hay, p)
				end
			end
			if texto:find("require%(%s*%d") then
				table.insert(hay, "require(NÚMERO)⛔")
			end
			-- require de algo que acaba en .Value (el número va en un objeto)
			for arg in texto:gmatch("require%(([^%)]*)%)") do
				if arg:find("%.Value") or arg:find("tonumber") then
					table.insert(hay, "require(" .. arg:sub(1, 60) .. ")⛔")
				end
			end
			if #hay > 0 then
				nota(("SCRIPT %s [%s] %d letras: %s"):format(d:GetFullName(), d.ClassName, #texto, table.concat(hay, ", ")))
			end
		end
		if Cloud.quedan and Cloud.quedan() < 20 then
			print("CORTE por tiempo")
			break
		end
	end
	return n, hallazgos, scripts
end

for _, id in IDS do
	local ok, res = pcall(AssetService.LoadAssetAsync, AssetService, id)
	if not ok then
		print(("===== %d FALLA %s"):format(id, tostring(res)))
		Cloud.aviso("ID " .. id, false, tostring(res))
	else
		print(("===== %d %s"):format(id, res:GetChildren()[1] and res:GetChildren()[1].Name or res.Name))
		local okM, n, h, s = pcall(mira, res)
		if okM then
			print(("RESUMEN %d: %d objetos, %d scripts, %d hallazgos"):format(id, n, s, h))
			Cloud.check("ID " .. id, true, ("%d hallazgos"):format(h))
		else
			print("ERROR " .. tostring(n))
		end
		res:Destroy()
	end
	if Cloud.quedan and Cloud.quedan() < 20 then
		print("CORTE por tiempo: faltan ids")
		break
	end
end

return Cloud.resultado()
