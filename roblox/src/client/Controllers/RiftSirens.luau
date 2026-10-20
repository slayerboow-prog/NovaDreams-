-- RiftSirens (cliente): las sirenas de las comisarías y los parques de bomberos cuando la grieta del
-- cielo cambia de etapa en directo (Controllers/SkyRift las lanza; las cuentas, en shared/SkyRift.Sirens).
--
--   * Dónde: una sirena en el tejado de cada comisaría (etiqueta PoliceStation) y de cada parque de
--     bomberos (FireStation). El sitio lo publica el servidor (atributo SirenAt del modelo: Fire/PoliceService)
--     y, si no está, se calcula con las piezas que ya hayan llegado (StreamingEnabled).
--   * Cómo: un sonido 3D en una pieza invisible del mundo (solo en esta pantalla), con caída lineal:
--     a tope hasta MinDistance, en silencio desde MaxDistance. Lejos de los cuarteles no se oye.
--   * Cuándo: SOLO durante una transición en directo (la carga, el cambio y el destello, ~16 s) más una
--     cola corta que se apaga. Al acabar se paran y se quitan: nunca se quedan sonando.
--   * Grupo 🔔 Efectos (SoundService.SFX), como el resto de la grieta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Rift = require(Shared.SkyRift)
local Config = require(Shared.Config)

local RiftSirens = {}

type Siren = { Station: Instance, Kind: string, Part: BasePart, Sound: Sound, Pos: Vector3 }

local folder: Folder? = nil
local sirens: { Siren } = {}
local startedAt: number? = nil -- (reloj del que llama) cuándo empezó la transición que suena
local level = 0
local triggers = 0

local function liveConfig(): { [string]: any }
	local c = (Config :: any).SkyRift
	return if type(c) == "table" then c else {}
end

local function enabled(): boolean
	return liveConfig().StationSirens ~= false
end

local function sfxGroup(): Instance?
	local ok, group = pcall(function()
		return (require(script.Parent.SoundFx) :: any).group("SFX")
	end)
	if ok and group then
		return group
	end
	local okFind, found = pcall(function()
		return game:GetService("SoundService"):FindFirstChild("SFX")
	end)
	return if okFind then found else nil
end

local function tagged(tag: string): { Instance }
	local ok, list = pcall(function()
		return game:GetService("CollectionService"):GetTagged(tag)
	end)
	return if ok and type(list) == "table" then list else {}
end

-- Dónde va la sirena de ese edificio (nil si aún no se sabe: sin atributo y sin piezas cargadas)
local function anchorOf(station: Instance): Vector3?
	local okAttr, at = pcall(function()
		return station:GetAttribute("SirenAt")
	end)
	if okAttr and typeof(at) == "Vector3" then
		return at
	end
	local boxes = {}
	for _, d in station:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(boxes, { CFrame = (d :: BasePart).CFrame, Size = (d :: BasePart).Size })
		end
	end
	return Rift.sirenAnchor(boxes)
end

-- Las comisarías y los parques de bomberos, con su sitio
local function stations(): { { Station: Instance, Kind: string, Pos: Vector3 } }
	local out = {}
	local S = Rift.Sirens
	for _, tag in S.Tags do
		for _, station in tagged(tag) do
			if #out >= S.Max then
				break
			end
			local pos = anchorOf(station)
			if pos then
				table.insert(out, { Station = station, Kind = if tag == "FireStation" then "Bomberos" else "Policia", Pos = pos })
			end
		end
	end
	return out
end

local function clear()
	for _, s in sirens do
		pcall(function()
			s.Sound:Stop()
		end)
	end
	table.clear(sirens)
	if folder then
		folder:Destroy()
		folder = nil
	end
	level = 0
end

local function build()
	clear()
	local S = Rift.Sirens
	local f = Instance.new("Folder")
	f.Name = "SirenasGrieta"
	local group = sfxGroup()
	local gain = tonumber(liveConfig().SoundVolume) or 1
	for _, st in stations() do
		local part = Instance.new("Part")
		part.Name = "Sirena" .. st.Kind
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.new(1, 1, 1)
		part.CFrame = CFrame.new(st.Pos)
		part.Parent = f
		local sound = Instance.new("Sound")
		sound.Name = "Sirena"
		sound.SoundId = "rbxassetid://" .. S.SoundId
		sound.Looped = true
		sound.PlaybackSpeed = S.Speed
		sound.Volume = 0
		sound.RollOffMode = Enum.RollOffMode.Linear
		sound.RollOffMinDistance = S.MinDistance
		sound.RollOffMaxDistance = S.MaxDistance
		sound:SetAttribute("Base", S.Volume * gain)
		if group and group:IsA("SoundGroup") then
			sound.SoundGroup = group
		end
		sound.Parent = part
		table.insert(sirens, { Station = st.Station, Kind = st.Kind, Part = part, Sound = sound, Pos = st.Pos })
	end
	f.Parent = workspace
	folder = f
end

-- Empieza una transición en directo (now: el reloj de quien llama). Si ya sonaban (otra transición
-- seguida), siguen sin cortarse
function RiftSirens.trigger(now: number)
	if not enabled() then
		return
	end
	triggers += 1
	if startedAt and not Rift.sirenDone(now - startedAt) and #sirens > 0 then
		-- (siguen a tope: se cuenta desde ya, sin volver a subir de cero)
		startedAt = now - Rift.Sirens.FadeIn * level
		return
	end
	startedAt = now
	build()
end

-- Cada fotograma (barato si no suena nada)
function RiftSirens.update(now: number)
	local t0 = startedAt
	if not t0 then
		return
	end
	local t = now - t0
	if Rift.sirenDone(t) then
		startedAt = nil
		clear()
		return
	end
	level = Rift.sirenLevel(t)
	for _, s in sirens do
		local base = s.Sound:GetAttribute("Base")
		s.Sound.Volume = (if type(base) == "number" then base else Rift.Sirens.Volume) * level
		if level > 0.001 then
			pcall(function()
				if not s.Sound.IsPlaying then
					s.Sound:Play()
				end
			end)
		end
	end
end

-- Para ya (modo pruebas, o la grieta se va a otro sitio)
function RiftSirens.stop()
	startedAt = nil
	clear()
end

-- (pruebas) qué suena
function RiftSirens.debugState(): { [string]: any }
	local list = {}
	for _, s in sirens do
		table.insert(list, {
			Kind = s.Kind,
			Pos = s.Pos,
			Volume = s.Sound.Volume,
			Playing = (pcall(function()
				return s.Sound.IsPlaying
			end)) and s.Sound.IsPlaying,
			Looped = s.Sound.Looped,
			Min = s.Sound.RollOffMinDistance,
			Max = s.Sound.RollOffMaxDistance,
			RollOff = s.Sound.RollOffMode,
			Group = s.Sound.SoundGroup,
			Sound = s.Sound,
			Part = s.Part,
		})
	end
	return { Active = startedAt ~= nil, Level = level, Triggers = triggers, Sirens = list, Folder = folder }
end

return RiftSirens
