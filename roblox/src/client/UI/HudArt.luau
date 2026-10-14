-- HudArt: los sprites del HUD de vuelo (nave y avión; UI/AirCombatHud) — arcos con brillo, marcos 9-slice,
-- iconos, radar, brújula, mira… Hechos con scripts/hud/gen_hud.py (assets/hud/*.png) y subidos con
-- scripts/upload-hud.sh, que escribe shared/HudTextureIds. Lo que no tenga id se dibuja como siempre
-- (marcos y rayitas de Roblox): HudArt.has(nombre) dice si hay sprite; todas las funciones que crean algo
-- devuelven nil si no lo hay. Nada se rompe sin ids.
--
-- Los números (tamaño de los atlas, recortes 9-slice, orden de los iconos) son los de
-- assets/hud/manifest.json (scripts/test-espacio-aaa.luau comprueba que coinciden).
-- Lo puro (qué fotograma, qué color, la animación del relleno) también lo prueba esa prueba.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudArt = {}

-- Arcos: atlas de 8 x 3 fotogramas de 128 x 256 (21 estados: 0 %, 5 % … 100 %); 20 segmentos de
-- abajo (112°) arriba (248°). La base (segmentos apagados y la escala) va a 2x, del mismo encuadre.
HudArt.Arc = { FrameW = 128, FrameH = 256, Cols = 8, Frames = 21, Segments = 20, From = 112, To = 248 }
-- Recarga de las ranuras: barrido de reloj, 8 x 3 de 96 px (21 estados)
HudArt.Cool = { Frame = 96, Cols = 8, Frames = 21 }
-- Brújula: cinta de 960 x 48 (2 px por grado, de 0° a 480°); se ve una ventana de 120°
HudArt.Compass = { W = 960, H = 48, PxPerDeg = 2, Window = 120 }
-- Iconos: atlas de 8 x 4 de 128 px
HudArt.Icon = {
	Size = 128,
	Cols = 8,
	Names = {
		"escudo", "energia", "cristal", "cubo", "mineral", "misil", "laser", "camuflaje",
		"salto", "hiper", "dron", "tren", "flaps", "frenos", "camara", "armas",
		"moneda", "corazon", "emblema", "rombo", "rombo_rojo", "aviso", "avion", "bajarse",
		"motor_max", "motor_0", "palanca", "combustible", "rango", "objetivo", "estructura", "chispas",
	},
}
-- Marcos 9-slice: tamaño, recorte del centro (x0, y0, x1, y1) y margen del brillo por fuera
HudArt.Frames = {
	marco_panel = { Size = { 96, 96 }, Slice = { 30, 30, 66, 66 }, Pad = 6 },
	marco_ranura = { Size = { 96, 96 }, Slice = { 26, 26, 70, 70 }, Pad = 6 },
	marco_ranura_sel = { Size = { 96, 96 }, Slice = { 26, 26, 70, 70 }, Pad = 6 },
	marco_cabecera = { Size = { 128, 32 }, Slice = { 20, 4, 100, 28 }, Pad = 0 },
	barra = { Size = { 48, 16 }, Slice = { 8, 3, 40, 13 }, Pad = 2 },
}
-- Todos los sprites (los nombres de assets/hud/*.png)
HudArt.Files = {
	"arco_base_der", "arco_base_izq", "arco_fino_izq", "arco_grueso_der", "arco_grueso_izq", "arco_medio_der",
	"aro_avatar", "aro_widget", "barra", "brujula_cinta", "emblema", "iconos", "marco_cabecera", "marco_panel",
	"marco_ranura", "marco_ranura_sel", "mira", "radar", "radar_barrido", "recarga", "silueta_avion",
	"silueta_nave", "vortice",
}

-- Icono de cada glifo de las ranuras (ShipAbilities y los aviones)
HudArt.GlyphIcon = {
	Canon = "armas", Misil = "misil", Laser = "laser", Escudo = "escudo", Camuflaje = "camuflaje", Salto = "salto",
	Hiper = "hiper", Dron = "dron", Flaps = "flaps", Tren = "tren", Frenos = "frenos", Camara = "camara",
	Palanca = "palanca", MotorMax = "motor_max", Motor0 = "motor_0", Bajarse = "bajarse",
}

-- Colores de los indicadores: el suyo; naranja por debajo de la mitad y rojo por debajo de un cuarto
local rgb = Color3.fromRGB
HudArt.GaugeColors = {
	Speed = rgb(110, 230, 255),
	Boost = rgb(255, 150, 40),
	Shield = rgb(90, 200, 255),
	Hull = rgb(120, 240, 170),
	Energy = rgb(255, 215, 90),
	Warn = rgb(255, 160, 50),
	Danger = rgb(255, 64, 56),
}
HudArt.WarnAt = 0.5
HudArt.DangerAt = 0.25

---------------------------------------------------------------------
-- Ids (shared/HudTextureIds; vacío hasta que se suban)
---------------------------------------------------------------------
local ids: { [string]: string } = {}
do
	local ok, t = pcall(function()
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local module = shared and shared:FindFirstChild("HudTextureIds")
		return if module then require(module :: any) else nil
	end)
	if ok and type(t) == "table" then
		ids = t
	end
end

-- Cambiar los ids (las pruebas, o al llegar tarde la tabla)
function HudArt.setIds(t: { [string]: string }?)
	ids = t or {}
end

-- El id de un sprite (del Decal a su imagen si el servidor ya lo resolvió: shared/Images) o nil
function HudArt.id(name: string): string?
	local raw = ids[name]
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, image = pcall(function()
		return require(ReplicatedStorage.Shared.Images).of(raw)
	end)
	return if ok and type(image) == "string" and image ~= "" then image else raw
end

function HudArt.has(name: string): boolean
	return type(ids[name]) == "string" and ids[name] ~= ""
end

---------------------------------------------------------------------
-- Cuentas (puro)
---------------------------------------------------------------------
-- Qué fotograma (0..frames-1) toca para un relleno k (0..1)
function HudArt.frameIndex(k: number, frames: number?): number
	local n = frames or HudArt.Arc.Frames
	if k ~= k then
		k = 0
	end
	return math.clamp(math.floor(math.clamp(k, 0, 1) * (n - 1) + 0.5), 0, n - 1)
end

-- Dónde está el fotograma `index` en un atlas de `cols` columnas
function HudArt.frameOffset(index: number, cols: number, w: number, h: number): Vector2
	return Vector2.new((index % cols) * w, math.floor(index / cols) * h)
end

function HudArt.arcOffset(k: number): Vector2
	local A = HudArt.Arc
	return HudArt.frameOffset(HudArt.frameIndex(k, A.Frames), A.Cols, A.FrameW, A.FrameH)
end

-- Recarga: k = lo que falta (0 = lista)
function HudArt.coolOffset(k: number): Vector2
	local C = HudArt.Cool
	return HudArt.frameOffset(HudArt.frameIndex(k, C.Frames), C.Cols, C.Frame, C.Frame)
end

function HudArt.iconIndex(name: string): number?
	local i = table.find(HudArt.Icon.Names, name)
	return if i then i - 1 else nil
end

function HudArt.iconOffset(name: string): Vector2?
	local i = HudArt.iconIndex(name)
	if not i then
		return nil
	end
	local I = HudArt.Icon
	return HudArt.frameOffset(i, I.Cols, I.Size, I.Size)
end

-- La ventana de la cinta de la brújula para un rumbo (x en píxeles de la cinta)
function HudArt.compassOffset(heading: number): number
	local C = HudArt.Compass
	return ((heading - C.Window / 2) % 360) * C.PxPerDeg
end

-- El color de un indicador. kind: "Speed" (cian; naranja con impulso, rojo en pérdida), "Boost"
-- (siempre naranja) o "Shield"/"Hull"/"Energy" (el suyo; naranja ≤ 50 %, rojo ≤ 25 %)
function HudArt.gaugeColor(kind: string, k: number, flags: { Boost: boolean?, Stall: boolean? }?): Color3
	local C = HudArt.GaugeColors
	if kind == "Speed" then
		if flags and flags.Stall then
			return C.Danger
		end
		return if flags and flags.Boost then C.Boost else C.Speed
	end
	if kind == "Boost" then
		return C.Boost
	end
	if k <= HudArt.DangerAt then
		return C.Danger
	elseif k <= HudArt.WarnAt then
		return C.Warn
	end
	return C[kind] or C.Speed
end

-- Relleno animado: de `current` hacia `target` (sube y baja suave; llega del todo si está cerca)
function HudArt.approach(current: number?, target: number, dt: number, rate: number?): number
	if current == nil or current ~= current then
		return target
	end
	local k = 1 - math.exp(-(rate or 8) * math.max(dt, 0))
	local v = current + (target - current) * k
	if math.abs(target - v) < 0.004 then
		return target
	end
	return v
end

---------------------------------------------------------------------
-- Crear (devuelven nil si no hay sprite: quien llama deja lo de siempre)
---------------------------------------------------------------------
local function apply(obj: Instance, props: { [string]: any }?)
	for k, v in props or {} do
		if k ~= "Parent" then
			(obj :: any)[k] = v
		end
	end
end

-- Una imagen suelta (sin fondo)
function HudArt.image(parent: Instance, name: string, props: { [string]: any }?): ImageLabel?
	local id = HudArt.id(name)
	if not id then
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.Name = name
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Image = id
	img.Size = UDim2.fromScale(1, 1)
	apply(img, props)
	img.Parent = parent
	return img
end

-- Un icono del atlas
function HudArt.icon(parent: Instance, name: string, props: { [string]: any }?): ImageLabel?
	local off = HudArt.iconOffset(name)
	if not off then
		return nil
	end
	local img = HudArt.image(parent, "iconos", props)
	if img then
		img.Name = (props and props.Name) or ("Icono_" .. name)
		img.ImageRectOffset = off
		img.ImageRectSize = Vector2.new(HudArt.Icon.Size, HudArt.Icon.Size)
		img:SetAttribute("Icon", name)
	end
	return img
end

-- Cambia el icono de una imagen del atlas
function HudArt.setIcon(img: ImageLabel, name: string)
	local off = HudArt.iconOffset(name)
	if off and img.ImageRectOffset ~= off then
		img.ImageRectOffset = off
		img:SetAttribute("Icon", name)
	end
end

-- Un fondo 9-slice detrás de lo que hay en `frame` (sale por fuera el margen del brillo). Apaga el
-- fondo, el filo y las esquinas de siempre del marco. Devuelve la imagen (o nil: queda lo de siempre).
function HudArt.frame(frame: GuiObject, kind: string?, props: { [string]: any }?): ImageLabel?
	local name = kind or "marco_panel"
	local def = HudArt.Frames[name]
	if not def or not HudArt.has(name) then
		return nil
	end
	local pad = def.Pad
	local img = HudArt.image(frame, name, {
		Name = "Marco",
		Position = UDim2.fromOffset(-pad, -pad),
		Size = UDim2.new(1, pad * 2, 1, pad * 2),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(def.Slice[1], def.Slice[2], def.Slice[3], def.Slice[4]),
		ZIndex = 0,
	})
	if not img then
		return nil
	end
	apply(img, props)
	frame.BackgroundTransparency = 1
	for _, c in frame:GetChildren() do
		if c:IsA("UIStroke") and c.Name == "Edge" then
			c.Enabled = false
		elseif c.Name == "Esquina" and c:IsA("GuiObject") then
			c.Visible = false
		end
	end
	frame:SetAttribute("Sprite", name)
	return img
end

-- Tira de cabecera (degradado con muesca) detrás de un título
function HudArt.header(parent: Instance, props: { [string]: any }?): ImageLabel?
	local def = HudArt.Frames.marco_cabecera
	local img = HudArt.image(parent, "marco_cabecera", {
		Name = "Cabecera",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(def.Slice[1], def.Slice[2], def.Slice[3], def.Slice[4]),
		ZIndex = 0,
	})
	if img then
		apply(img, props)
	end
	return img
end

-- Un arco (capa de un atlas o la base): `name` = arco_grueso_izq, arco_base_der…
function HudArt.arc(parent: Instance, name: string, props: { [string]: any }?): ImageLabel?
	local img = HudArt.image(parent, name, props)
	if img and not string.find(name, "base", 1, true) then
		img.ImageRectSize = Vector2.new(HudArt.Arc.FrameW, HudArt.Arc.FrameH)
		img.ImageRectOffset = HudArt.arcOffset(0)
	end
	return img
end

-- El texto sin el emoji (y los espacios) del principio: con su icono dibujado, sobra
function HudArt.plain(text: string): string
	local s = string.gsub(text, "^[\128-\255%s]+", "")
	return s
end

return HudArt
