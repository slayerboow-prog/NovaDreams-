-- VehicleBuild: la «Build» de un vehículo personalizado (qué pieza hay en cada hueco) y cómo se
-- pone en un modelo. Ver docs/personalizar-vehiculos.md.
--
--   VehicleBuild.default()                          -> Build de serie (todo "" / 0)
--   VehicleBuild.validate(build, ownedParts, kind)  -> (Build limpia, { avisos })
--       Pura: sin servicios. Lo desconocido, bloqueado o que no vale para ese tipo/carrocería se
--       quita (vuelve a serie) con un aviso. Nunca da error, pase lo que pase en `build`.
--   VehicleBuild.apply(model, build, options?)      -> (piezas nuevas, { avisos })
--       Pone la build en un modelo de Rides.build (antes o después de Rides.prepare). Recolorea
--       zonas y añade piezas "Mod_" SIN colisión en las anclas de VehicleParts. Solo API de
--       instancias, sin azar: misma entrada -> mismas piezas (servidor y vista previa del cliente).
--       Empieza siempre con clear(model), así que se puede aplicar las veces que se quiera.
--   VehicleBuild.clear(model)
--       Quita todo lo del taller: borra las piezas Mod_ y devuelve colores, materiales,
--       transparencias y textos de matrícula a como estaban.
--
-- Reglas (las comprueba scripts/test-vehicleparts.luau):
--   * No mueve, borra, renombra ni cambia la colisión de ninguna pieza de serie. Las que se
--     «sustituyen» (llantas, parachoques) se esconden (Transparency = 1) y siguen ahí: la caja de
--     choque y lo que buscan otros sistemas no cambia.
--   * Nunca toca Headlight*, Taillight, Indicator*, Reverse, ThirdBrake, Chassis, DriverSeat,
--     RideSeat, Kickstand… (VehicleParts.Reserved). «Body» solo se pinta (color, material, brillo).
--   * Piezas nuevas: CanCollide/CanQuery/CanTouch = false, Massless, dentro de la caja del chasis
--     (Rides.Spec[kind].Size) + 0,3 studs, y como mucho VehicleParts.Budget[kind].
--   * Ninguna pieza cambia el rendimiento: aquí no hay ni velocidad, ni frenada, ni giro.

local VehicleParts = require(script.Parent.VehicleParts)

local VehicleBuild = {}

VehicleBuild.VERSION = 1

-- Campos de la Build (versión 1). Todos texto (id de pieza, "" = de serie) salvo Tint (número).
export type Build = {
	V: number,
	Body: string, -- carrocería del coche ("Berlina", "Compacto", "Todoterreno"; "" = berlina)
	Paint: string,
	Finish: string,
	Paint2: string,
	Rims: string,
	RimColor: string,
	Tires: string,
	Tint: number, -- 0..3
	Spoiler: string,
	BumperF: string,
	BumperR: string,
	Neon: string,
	Plate: string, -- texto YA FILTRADO por el servidor ("" = la de serie)
}

-- Campo -> hueco de VehicleParts (Paint2 usa la paleta de Paint)
local FIELD_SLOT = {
	Paint = "Paint",
	Finish = "Finish",
	Paint2 = "Paint",
	Rims = "Rims",
	RimColor = "RimColor",
	Tires = "Tires",
	Spoiler = "Spoiler",
	BumperF = "BumperF",
	BumperR = "BumperR",
	Neon = "Neon",
}
local ID_FIELDS = { "Paint", "Finish", "Paint2", "Rims", "RimColor", "Tires", "Spoiler", "BumperF", "BumperR", "Neon" }
local KNOWN = { V = true, Body = true, Tint = true, Plate = true }
for field in FIELD_SLOT do
	KNOWN[field] = true
end
VehicleBuild.Fields = table.clone(ID_FIELDS)
table.insert(VehicleBuild.Fields, "Body")
table.insert(VehicleBuild.Fields, "Tint")
table.insert(VehicleBuild.Fields, "Plate")

-- Una build de un servidor más nuevo (V mayor) conserva hasta este número de campos que aquí no se
-- entienden (sencillos: texto corto, número o sí/no), para no perderlos al guardar.
VehicleBuild.MaxExtraFields = 16

function VehicleBuild.default(): Build
	return {
		V = VehicleBuild.VERSION,
		Body = "",
		Paint = "",
		Finish = "",
		Paint2 = "",
		Rims = "",
		RimColor = "",
		Tires = "",
		Tint = 0,
		Spoiler = "",
		BumperF = "",
		BumperR = "",
		Neon = "",
		Plate = "",
	}
end

-- Carrocería efectiva de una build de coche
function VehicleBuild.bodyOf(build: { [string]: any }?): string
	local body = if type(build) == "table" then build.Body else nil
	if type(body) == "string" and table.find(VehicleParts.Bodies, body) then
		return body
	end
	return "Berlina"
end

---------------------------------------------------------------------
-- Migraciones: migrate[n] pasa una build de la versión n a la n + 1
---------------------------------------------------------------------
VehicleBuild.migrate = {
	-- V0 (sin campo V: el primer prototipo) usaba "Color" para la pintura y "Wheels" para las llantas
	[0] = function(old: { [string]: any }): { [string]: any }
		local new = table.clone(old)
		if new.Paint == nil and type(old.Color) == "string" then
			new.Paint = old.Color
		end
		if new.Rims == nil and type(old.Wheels) == "string" then
			new.Rims = old.Wheels
		end
		new.Color = nil
		new.Wheels = nil
		new.V = 1
		return new
	end,
}

---------------------------------------------------------------------
-- Validación
---------------------------------------------------------------------
local function isSimple(value: any): boolean
	local t = type(value)
	if t == "string" then
		return #value <= 64
	elseif t == "number" then
		return value == value and value ~= math.huge and value ~= -math.huge
	end
	return t == "boolean"
end

function VehicleBuild.validate(build: any, ownedParts: any, vehicleKind: any): (Build, { string })
	local warnings = {}
	local clean = VehicleBuild.default()
	local function warn(text: string)
		if #warnings < 40 then
			table.insert(warnings, text)
		end
	end
	if not VehicleParts.isCustomizable(vehicleKind) then
		warn("Este vehículo no se personaliza: " .. tostring(vehicleKind))
		return clean, warnings
	end
	local kind = vehicleKind :: string
	if type(build) ~= "table" then
		if build ~= nil then
			warn("La build no es una tabla")
		end
		return clean, warnings
	end
	local owned = if type(ownedParts) == "table" then ownedParts else {}

	-- Versión: migrar hacia delante; una del futuro se conserva
	local source = build
	local version = if type(build.V) == "number" and build.V == build.V then math.floor(build.V) else 0
	local future = version > VehicleBuild.VERSION
	if version < 0 then
		version = 0
	end
	local guard = 0
	while version < VehicleBuild.VERSION and guard < 16 do
		guard += 1
		local step = VehicleBuild.migrate[version]
		if not step then
			warn("Versión de build sin migración: " .. version)
			break
		end
		local ok, result = pcall(step, source)
		if not ok or type(result) ~= "table" then
			warn("Falló la migración desde la versión " .. version)
			break
		end
		source = result
		version += 1
	end
	if future then
		clean.V = version
	end

	-- Carrocería (solo coche)
	local body = "Berlina"
	if kind == "Coche" then
		local raw = source.Body
		if raw ~= nil and raw ~= "" then
			local part = if type(raw) == "string" then VehicleParts.Parts["Body_" .. raw] else nil
			if not part then
				warn("Carrocería desconocida: " .. tostring(raw))
			elseif not VehicleParts.isUsable(part, kind, owned) then
				warn("Carrocería no desbloqueada: " .. raw)
			else
				clean.Body = raw
				body = raw
			end
		end
	elseif source.Body ~= nil and source.Body ~= "" then
		warn("Solo el coche tiene carrocería")
	end

	-- Piezas por id
	for _, field in ID_FIELDS do
		local raw = source[field]
		if raw == nil or raw == "" then
			continue
		end
		if type(raw) ~= "string" then
			warn(field .. ": tipo equivocado (" .. type(raw) .. ")")
			continue
		end
		local part = VehicleParts.get(raw)
		if not part then
			warn(field .. ": pieza desconocida " .. string.sub(raw, 1, 40))
			continue
		end
		if part.Slot ~= FIELD_SLOT[field] then
			warn(field .. ": " .. raw .. " no es de este hueco")
			continue
		end
		if field == "Paint2" and not VehicleParts.Paint2Kinds[kind] then
			warn("Paint2: este vehículo no tiene pintura secundaria")
			continue
		end
		if not VehicleParts.fits(part, kind, body) then
			warn(field .. ": " .. raw .. " no vale para " .. kind .. (if kind == "Coche" then " " .. body else ""))
			continue
		end
		if not VehicleParts.isUsable(part, kind, owned) then
			warn(field .. ": " .. raw .. " no está desbloqueada")
			continue
		end
		clean[field] = raw
	end

	-- Lunas tintadas (0..3, coche, con el kit)
	local tint = source.Tint
	if tint ~= nil and tint ~= 0 then
		if type(tint) ~= "number" or tint ~= tint then
			warn("Tint: tiene que ser un número")
		elseif kind ~= "Coche" then
			warn("Tint: solo el coche lleva lunas tintadas")
		elseif not VehicleParts.isOwned(VehicleParts.Parts.Kit_Tint, kind, owned) then
			warn("Tint: falta comprar las lunas tintadas")
		else
			clean.Tint = math.clamp(math.floor(tint), 0, VehicleParts.MaxTint)
		end
	end

	-- Matrícula (el filtro de Roblox lo pasa el servidor ANTES de guardarla)
	local plate = source.Plate
	if plate ~= nil and plate ~= "" then
		if not VehicleParts.Plate.Kinds[kind] then
			warn("Plate: este vehículo no lleva matrícula")
		else
			local text, reason = VehicleParts.plateText(plate)
			if text then
				clean.Plate = text
			else
				warn("Plate: " .. tostring(reason))
			end
		end
	end

	-- Campos desconocidos: fuera (salvo en una build del futuro, que conserva unos pocos)
	local extras, dropped = 0, 0
	for key, value in source do
		if KNOWN[key] then
			continue
		end
		if future and type(key) == "string" and #key <= 32 and isSimple(value) and extras < VehicleBuild.MaxExtraFields then
			extras += 1
			(clean :: any)[key] = value
		else
			dropped += 1
		end
	end
	if dropped > 0 then
		warn(("Se quitaron %d campos desconocidos"):format(dropped))
	end
	return clean, warnings
end

---------------------------------------------------------------------
-- Aplicar al modelo
---------------------------------------------------------------------
local rgb = Color3.fromRGB
local DARK = rgb(40, 40, 44)
local BLACK = rgb(24, 24, 27)
local CHROME = rgb(205, 208, 214)
local WHITE = rgb(235, 235, 235)
local PREFIX = VehicleParts.Prefix

local function color3(t: { number }): Color3
	return rgb(t[1], t[2], t[3])
end
local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end
local function material(name: string?, fallback: Enum.Material): Enum.Material
	if type(name) == "string" then
		local ok, value = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		if ok and value then
			return value
		end
	end
	return fallback
end

type Ctx = {
	model: Model,
	kind: string,
	body: string,
	origin: CFrame,
	chassis: BasePart?,
	count: number,
	budget: number,
	warnings: { string },
	children: { Instance },
}

-- Piezas de serie (hijos directos) con alguno de estos nombres, en el orden del modelo
local function named(ctx: Ctx, names: { string }?): { BasePart }
	local found = {}
	if not names then
		return found
	end
	for _, child in ctx.children do
		if child:IsA("BasePart") and table.find(names, child.Name) and string.sub(child.Name, 1, #PREFIX) ~= PREFIX and not child:GetAttribute("CarHidden") then
			table.insert(found, child)
		end
	end
	return found
end

-- Piezas de la carrocería de malla (Kit/CarBodies) de una zona («Primary», «Glass»)
local function meshZone(ctx: Ctx, zone: string): { BasePart }
	local found = {}
	for _, child in ctx.children do
		if child:IsA("BasePart") and child:GetAttribute("CarZone") == zone then
			table.insert(found, child)
		end
	end
	return found
end

-- Guarda cómo era la pieza (una sola vez) para que clear() la deje igual
local function remember(part: BasePart): boolean
	if VehicleParts.isReserved(part.Name) and not VehicleParts.PaintableReserved[part.Name] then
		return false
	end
	if part:GetAttribute("ModOrigColor") == nil then
		part:SetAttribute("ModOrigColor", part.Color)
		part:SetAttribute("ModOrigMaterial", part.Material.Name)
		part:SetAttribute("ModOrigReflectance", part.Reflectance)
		part:SetAttribute("ModOrigTransparency", part.Transparency)
	end
	return true
end

local function paintPart(part: BasePart, color: Color3?, finish: { [string]: any }?)
	if not remember(part) then
		return
	end
	if color then
		part.Color = color
	end
	if finish then
		part.Material = material(finish.Material, Enum.Material.SmoothPlastic)
		part.Reflectance = finish.Reflectance or 0
	end
end

-- Esconde una pieza de serie sustituida (sigue en el modelo: misma colisión, mismos nombres)
local function hide(part: BasePart)
	if VehicleParts.isReserved(part.Name) then
		return
	end
	if remember(part) then
		part.Transparency = 1
	end
end

-- Pieza nueva del taller: sin colisión, sin sombra, soldada si el vehículo ya está preparado
local function newPart(ctx: Ctx, slot: string, name: string, size: Vector3, localCf: CFrame, color: Color3, mat: Enum.Material?, cylinder: boolean?): BasePart?
	if ctx.count >= ctx.budget then
		if #ctx.warnings < 40 then
			table.insert(ctx.warnings, "Presupuesto de piezas agotado: " .. slot .. "/" .. name)
		end
		return nil
	end
	local p = Instance.new("Part")
	p.Name = PREFIX .. name
	if cylinder then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Size = size
	p.CFrame = ctx.origin * localCf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = ctx.chassis == nil -- (Rides.prepare lo suelta y lo suelda, como a todo)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p:SetAttribute("Mod", true)
	p:SetAttribute("Slot", slot)
	p.Parent = ctx.model
	local chassis = ctx.chassis
	if chassis then
		-- Ya preparado (vista previa o sustituir en el taller): se suelda igual que en Rides.prepare
		p:SetAttribute("Collide", false)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = chassis
		weld.Part1 = p
		weld.Parent = p
	end
	ctx.count += 1
	return p
end

-- Anclas de rueda ordenadas (mismo orden siempre)
local function wheelAnchors(anchors: { [string]: { number } }): { Vector3 }
	local keys = {}
	for key in anchors do
		if string.sub(key, 1, 5) == "Wheel" then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	local list = {}
	for _, key in keys do
		table.insert(list, vec(anchors[key]))
	end
	return list
end

-- Una llanta de diseño en una rueda (≤ 8 piezas: aro, disco, radios y buje)
local function buildRim(ctx: Ctx, center: Vector3, design: { [string]: any }, color: Color3, mat: Enum.Material)
	local info = VehicleParts.wheelsFor(ctx.kind, ctx.body) or VehicleParts.Wheels[ctx.kind]
	local R = info.RimDiameter / 2
	local w = info.Width
	local base = CFrame.new(center)
	if design.Lip then
		newPart(ctx, "Rims", "Rim", Vector3.new(w + 0.04, R * 2, R * 2), base, color, mat, true)
	end
	local faceColor = if design.Face == "Color" then color elseif design.Face == "White" then WHITE else DARK
	local faceD = if design.Lip then R * 2 * 0.86 else R * 2
	newPart(ctx, "Rims", "RimFace", Vector3.new(w + 0.05, faceD, faceD), base, faceColor, if design.Face == "Color" then mat else Enum.Material.SmoothPlastic, true)
	local arms = design.Arms or 0
	local tilt = math.rad(design.Tilt or 0)
	local thick = math.max(0.05, (design.Width or 0.2) * R)
	for i = 0, arms - 1 do
		local angle
		if design.Pair then
			local groups = math.max(1, arms // 2)
			angle = (i // 2) * 360 / groups + (if i % 2 == 0 then -design.Pair / 2 else design.Pair / 2)
		elseif design.Through then
			angle = i * 180 / arms
		else
			angle = i * 360 / arms
		end
		local length, offset
		if design.Through then
			length, offset = R * 2 * 0.9, 0
		else
			length, offset = R * 0.82, R * 0.47
		end
		-- los radios girados (turbina, hélice) son un poco más estrechos para no salirse de la rueda
		local along = if tilt ~= 0 then w * 0.8 else w + 0.06
		newPart(ctx, "Rims", "RimSpoke", Vector3.new(along, thick, length), base * CFrame.Angles(math.rad(angle), 0, 0) * CFrame.new(0, 0, offset) * CFrame.Angles(0, 0, tilt), color, mat)
	end
	local hubD = R * 2 * (design.Hub or 0.35)
	local hubColor = if design.Face == "Dark" then color else CHROME
	newPart(ctx, "Rims", "RimHub", Vector3.new(w + 0.08, hubD, hubD), base, hubColor, if design.Face == "Dark" then mat else Enum.Material.Metal, true)
end

-- Bandas del neumático en el costado de fuera (coche)
local function buildBand(ctx: Ctx, center: Vector3, band: { [string]: any })
	local info = VehicleParts.wheelsFor(ctx.kind, ctx.body) or VehicleParts.Wheels[ctx.kind]
	local sx = if center.X > 0 then 1 elseif center.X < 0 then -1 else 0
	if sx == 0 then
		return
	end
	local face = center.X + sx * (info.Width / 2)
	newPart(ctx, "Tires", "TireBand", Vector3.new(0.012, band.Outer, band.Outer), CFrame.new(face + sx * 0.006, center.Y, center.Z), color3(band.Color), Enum.Material.SmoothPlastic, true)
	if band.Inner then
		newPart(ctx, "Tires", "TireBandInner", Vector3.new(0.012, band.Inner, band.Inner), CFrame.new(face + sx * 0.01, center.Y, center.Z), rgb(26, 26, 28), Enum.Material.Rubber, true)
	end
end

local function bodyPaint(finish: { [string]: any }?, paintColor: Color3): (Color3, Enum.Material, number)
	local reflect = if finish then finish.Reflectance or 0 else 0.08
	return paintColor, material(if finish then finish.Material else nil, Enum.Material.SmoothPlastic), reflect
end

local function buildSpoiler(ctx: Ctx, id: string, anchor: Vector3, paint: Color3, finish: { [string]: any }?)
	local color, mat, reflect = bodyPaint(finish, paint)
	local at = CFrame.new(anchor)
	if id == "Sp_Labio" then
		local lip = newPart(ctx, "Spoiler", "Spoiler", Vector3.new(5.2, 0.12, 0.5), at * CFrame.new(0, 0.07, 0.25) * CFrame.Angles(math.rad(8), 0, 0), color, mat)
		if lip then
			lip.Reflectance = reflect
		end
	elseif id == "Sp_Deportivo" then
		for _, sx in { -1, 1 } do
			newPart(ctx, "Spoiler", "SpoilerStrut", Vector3.new(0.14, 0.6, 0.3), at * CFrame.new(sx * 1.7, 0.3, 0.1), BLACK)
		end
		local wing = newPart(ctx, "Spoiler", "Spoiler", Vector3.new(5, 0.12, 0.8), at * CFrame.new(0, 0.65, 0.1) * CFrame.Angles(math.rad(6), 0, 0), color, mat)
		if wing then
			wing.Reflectance = reflect
		end
	elseif id == "Sp_GT" then
		for _, sx in { -1, 1 } do
			newPart(ctx, "Spoiler", "SpoilerStrut", Vector3.new(0.14, 1.2, 0.3), at * CFrame.new(sx * 1.8, 0.6, 0.2), BLACK)
		end
		newPart(ctx, "Spoiler", "Spoiler", Vector3.new(5.5, 0.14, 1), at * CFrame.new(0, 1.25, 0.15) * CFrame.Angles(math.rad(8), 0, 0), rgb(30, 30, 34), Enum.Material.SmoothPlastic)
		for _, sx in { -1, 1 } do
			local plate = newPart(ctx, "Spoiler", "SpoilerEndplate", Vector3.new(0.08, 0.6, 1.1), at * CFrame.new(sx * 2.79, 1.2, 0.15), color, mat)
			if plate then
				plate.Reflectance = reflect
			end
		end
	end
end

local function buildBumper(ctx: Ctx, slot: string, id: string, anchor: Vector3, paint: Color3, finish: { [string]: any }?)
	local color, mat, reflect = bodyPaint(finish, paint)
	local front = slot == "BumperF"
	local sz = if front then -1 else 1 -- hacia fuera del coche
	local at = CFrame.new(anchor)
	if id == "BF_Deportivo" or id == "BR_Deportivo" then
		local main = newPart(ctx, slot, "Bumper", Vector3.new(6.3, 0.75, 0.62), at * CFrame.new(0, -0.02, 0), color, mat)
		if main then
			main.Reflectance = reflect
		end
		if front then
			newPart(ctx, slot, "BumperSplitter", Vector3.new(5.6, 0.08, 0.35), at * CFrame.new(0, -0.37, sz * 0.2), BLACK, Enum.Material.Plastic)
			for _, sx in { -1, 1 } do
				newPart(ctx, slot, "BumperVent", Vector3.new(1, 0.25, 0.05), at * CFrame.new(sx * 2.0, -0.05, sz * 0.33), BLACK, Enum.Material.Plastic)
			end
		else
			newPart(ctx, slot, "BumperDiffuser", Vector3.new(3, 0.22, 0.4), at * CFrame.new(0, -0.45, sz * 0.15), BLACK, Enum.Material.Plastic)
		end
	elseif id == "BF_Defensa" then
		newPart(ctx, slot, "BullBar", Vector3.new(5, 0.2, 0.2), at * CFrame.new(0, 0.65, sz * 0.4), BLACK, Enum.Material.Metal)
		for _, sx in { -1, 1 } do
			newPart(ctx, slot, "BullBarPost", Vector3.new(0.2, 1.3, 0.2), at * CFrame.new(sx * 1.6, 0.2, sz * 0.4), BLACK, Enum.Material.Metal)
		end
		newPart(ctx, slot, "SkidPlate", Vector3.new(4, 0.1, 0.5), at * CFrame.new(0, -0.45, sz * 0.25), rgb(150, 154, 160), Enum.Material.Metal)
	elseif id == "BR_Defensa" then
		newPart(ctx, slot, "BullBar", Vector3.new(5, 0.2, 0.2), at * CFrame.new(0, 0, sz * 0.35), BLACK, Enum.Material.Metal)
		for _, sx in { -1, 1 } do
			newPart(ctx, slot, "TowHook", Vector3.new(0.3, 0.3, 0.3), at * CFrame.new(sx * 1.2, -0.3, sz * 0.3), rgb(150, 154, 160), Enum.Material.Metal)
		end
	end
end

local NEON_SIZE = {
	Coche = Vector3.new(5.6, 0.06, 11.5),
	Moto = Vector3.new(0.6, 0.06, 2.4),
	Patinete = Vector3.new(0.6, 0.04, 2),
}

-- Texto de matrícula: cambia el cartel que ya tiene o le pone uno (Mod_PlateGui)
local function setPlate(part: BasePart, text: string, face: Enum.NormalId)
	for _, gui in part:GetChildren() do
		if gui:IsA("SurfaceGui") then
			local label = gui:FindFirstChildWhichIsA("TextLabel")
			if label then
				if label:GetAttribute("ModOrigText") == nil then
					label:SetAttribute("ModOrigText", label.Text)
				end
				label.Text = text
				return
			end
		end
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = PREFIX .. "PlateGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui:SetAttribute("Mod", true)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = rgb(240, 240, 240)
	label.BackgroundTransparency = 0
	label.TextColor3 = rgb(20, 20, 24)
	label.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
	gui.Parent = part
end

-- Dónde está el vehículo: con Chassis (ya preparado) o por su pieza de referencia
local function locate(model: Model, kind: string, options: { [string]: any }, body: string?): (CFrame?, BasePart?)
	local chassis = model:FindFirstChild("Chassis")
	local prepared = if chassis and chassis:IsA("BasePart") then chassis else nil
	if typeof(options.Origin) == "CFrame" then
		return options.Origin, prepared
	end
	if prepared then
		return prepared.CFrame * CFrame.new(0, -prepared.Size.Y / 2, 0), prepared
	end
	local ref = VehicleParts.referenceFor(kind, body)
	local part = ref and model:FindFirstChild(ref.Name)
	if part and part:IsA("BasePart") then
		local o = ref.Offset
		return part.CFrame * CFrame.new(-o[1], -o[2], -o[3]), nil
	end
	return nil, nil
end

function VehicleBuild.clear(model: Model)
	local doomed = {}
	for _, item in model:GetDescendants() do
		if string.sub(item.Name, 1, #PREFIX) == PREFIX and item:GetAttribute("Mod") == true then
			table.insert(doomed, item)
		end
	end
	for _, item in doomed do
		item:Destroy()
	end
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") and item:GetAttribute("ModOrigColor") ~= nil then
			local color = item:GetAttribute("ModOrigColor")
			if typeof(color) == "Color3" then
				item.Color = color
			end
			item.Material = material(item:GetAttribute("ModOrigMaterial"), item.Material)
			local reflect, transparency = item:GetAttribute("ModOrigReflectance"), item:GetAttribute("ModOrigTransparency")
			if type(reflect) == "number" then
				item.Reflectance = reflect
			end
			if type(transparency) == "number" then
				item.Transparency = transparency
			end
			item:SetAttribute("ModOrigColor", nil)
			item:SetAttribute("ModOrigMaterial", nil)
			item:SetAttribute("ModOrigReflectance", nil)
			item:SetAttribute("ModOrigTransparency", nil)
		elseif item:IsA("TextLabel") and item:GetAttribute("ModOrigText") ~= nil then
			item.Text = tostring(item:GetAttribute("ModOrigText"))
			item:SetAttribute("ModOrigText", nil)
		end
	end
	model:SetAttribute("NeonColor", nil)
	model:SetAttribute("StyleV", nil)
	model:SetAttribute("ModParts", nil)
end

-- options: Kind (si no, el atributo Kind o el nombre del modelo), Origin (CFrame de construcción).
-- La build debería venir de validate(); aun así, aquí se vuelve a mirar que cada pieza exista y
-- valga para el tipo y la carrocería DEL MODELO (atributo Variant; sin él, berlina).
function VehicleBuild.apply(model: Model, build: any, options: { [string]: any }?): (number, { string })
	local opts = options or {}
	local warnings = {}
	VehicleBuild.clear(model)
	local kind = opts.Kind or model:GetAttribute("Kind") or model.Name
	if not VehicleParts.isCustomizable(kind) then
		table.insert(warnings, "Este vehículo no se personaliza: " .. tostring(kind))
		return 0, warnings
	end
	if type(build) ~= "table" then
		return 0, warnings
	end
	-- Carrocería: la del coche de siempre, o el id del vehículo premium del pase (coche o moto)
	local variant = model:GetAttribute("Variant")
	local premium = VehicleParts.isPremiumBody(kind, variant)
	local body = if premium then variant elseif kind == "Coche" then (if type(variant) == "string" and table.find(VehicleParts.Bodies, variant) then variant else "Berlina") else ""
	local origin, chassis = locate(model, kind, opts, body)
	if not origin then
		table.insert(warnings, "No se encuentra la pieza de referencia del vehículo")
		return 0, warnings
	end
	local ctx: Ctx = {
		model = model,
		kind = kind,
		body = body,
		origin = origin,
		chassis = chassis,
		count = 0,
		budget = VehicleParts.Budget[kind] or 20,
		warnings = warnings,
		children = model:GetChildren(),
	}
	local zones = VehicleParts.zonesFor(kind, body) or VehicleParts.Zones[kind]
	local anchors = VehicleParts.anchorsFor(kind, if kind == "Coche" or premium then body else nil) or {}
	local function pick(field: string, slot: string): { [string]: any }?
		local id = build[field]
		if type(id) ~= "string" or id == "" then
			return nil
		end
		local part = VehicleParts.get(id)
		if not part or part.Slot ~= slot then
			table.insert(warnings, field .. ": pieza desconocida " .. string.sub(id, 1, 40))
			return nil
		end
		if not VehicleParts.fits(part, kind, body) then
			table.insert(warnings, field .. ": " .. id .. " no vale para " .. kind .. " " .. body)
			return nil
		end
		return part
	end

	-- 1. Pintura, acabado y pintura secundaria (solo recolorear)
	local paint = pick("Paint", "Paint")
	local finish = pick("Finish", "Finish")
	local paint2 = if VehicleParts.Paint2Kinds[kind] then pick("Paint2", "Paint") else nil
	if paint or finish then
		local color = nil
		if paint then
			color = color3(paint.Color)
			if finish and (finish.Lighten or 0) > 0 then
				color = color:Lerp(Color3.new(1, 1, 1), finish.Lighten)
			end
		end
		for _, part in named(ctx, zones.Primary) do
			paintPart(part, color, finish)
		end
		for _, part in meshZone(ctx, "Primary") do
			paintPart(part, color, finish)
		end
	end
	if paint2 then
		for _, part in named(ctx, zones.Secondary) do
			paintPart(part, color3(paint2.Color), nil)
		end
	end
	-- Color de la carrocería ya pintada (para alerón, parachoques y «color carrocería»)
	local bodyColor = CHROME
	local primary = named(ctx, zones.Primary)
	if #primary > 0 then
		bodyColor = primary[1].Color
	end

	-- 2. Lunas tintadas (el parabrisas nunca)
	local tint = build.Tint
	if kind == "Coche" and type(tint) == "number" and tint >= 1 then
		local level = VehicleParts.Tints[math.clamp(math.floor(tint), 0, VehicleParts.MaxTint)]
		local glass = named(ctx, zones.Glass)
		for _, part in meshZone(ctx, "Glass") do
			table.insert(glass, part)
		end
		for _, part in glass do
			if remember(part) then
				local orig = part:GetAttribute("ModOrigColor")
				local base = if typeof(orig) == "Color3" then orig else part.Color
				part.Color = base:Lerp(Color3.new(0, 0, 0), level.Darken)
				part.Transparency = level.Transparency
			end
		end
	end

	-- 3. Llantas y su color
	local rims = pick("Rims", "Rims")
	local rimColor = pick("RimColor", "RimColor")
	local design = rims and rims.Design
	local wheels = wheelAnchors(anchors)
	local color, mat = CHROME, Enum.Material.Metal
	if rimColor then
		color = if rimColor.UsePaint then bodyColor elseif rimColor.Color then color3(rimColor.Color) else CHROME
		mat = material(rimColor.Material, Enum.Material.Metal)
	end
	if design then
		if design.FixedColor then
			color = color3(design.FixedColor)
		end
		if design.FixedMaterial then
			mat = material(design.FixedMaterial, mat)
		end
		for _, part in named(ctx, zones.Rim) do
			if part.Name ~= "Wheel" then
				hide(part)
			end
		end
		for _, center in wheels do
			buildRim(ctx, center, design, color, mat)
		end
	elseif rimColor then
		-- llantas de serie: solo el color (el buje se queda)
		for _, part in named(ctx, zones.Rim) do
			-- (el buje y, en los premium, el disco, la pinza y el fondo de la llanta se quedan como están)
			if part.Name ~= "Hub" and part.Name ~= "BrakeDisc" and part.Name ~= "Caliper" and part.Name ~= "RimInner" then
				paintPart(part, color, { Material = rimColor.Material or "Metal", Reflectance = part.Reflectance })
			end
		end
	end

	-- 4. Neumáticos (bandas blancas)
	local tires = pick("Tires", "Tires")
	if tires and tires.Band then
		for _, center in wheels do
			buildBand(ctx, center, tires.Band)
		end
	end

	-- 5. Alerón
	local spoiler = pick("Spoiler", "Spoiler")
	if spoiler and anchors.Trunk then
		buildSpoiler(ctx, spoiler.Id, vec(anchors.Trunk), bodyColor, finish)
	end

	-- 6. Parachoques
	for _, slot in { "BumperF", "BumperR" } do
		local bumper = pick(slot, slot)
		if bumper and not bumper.Default and anchors[slot] then
			if bumper.Replaces then
				for _, part in named(ctx, zones[slot]) do
					hide(part)
				end
			end
			buildBumper(ctx, slot, bumper.Id, vec(anchors[slot]), bodyColor, finish)
		end
	end

	-- 7. Neón bajo el vehículo (el cliente lo enciende de noche y de cerca, con NeonColor)
	local neon = pick("Neon", "Neon")
	if neon and anchors.Under and NEON_SIZE[kind] then
		local c = color3(neon.Color)
		local strip = newPart(ctx, "Neon", "Neon", NEON_SIZE[kind], CFrame.new(vec(anchors.Under)), c, Enum.Material.Neon)
		if strip then
			strip.Transparency = 0.35
			model:SetAttribute("NeonColor", c)
		end
	end

	-- 8. Matrícula (texto ya filtrado por el servidor; aquí solo se vuelve a mirar el formato)
	local plate = build.Plate
	if type(plate) == "string" and plate ~= "" and VehicleParts.Plate.Kinds[kind] then
		local text = VehicleParts.plateText(plate)
		if text then
			for _, part in named(ctx, zones.PlateRear) do
				setPlate(part, text, Enum.NormalId.Back)
			end
			for _, part in named(ctx, zones.PlateFront) do
				setPlate(part, text, Enum.NormalId.Front)
			end
		else
			table.insert(warnings, "Plate: formato no válido")
		end
	end

	model:SetAttribute("StyleV", VehicleBuild.VERSION)
	model:SetAttribute("ModParts", ctx.count)
	return ctx.count, warnings
end

return VehicleBuild
