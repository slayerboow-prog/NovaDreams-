-- Polideportivo del Campus (zona 8, Prado del Campus Norte; shared/OcioSitios «Campus»).
--
-- Solo el suelo y lo fijo: las líneas, la red y los cristales los pintan los deportes de verdad
-- mientras se juega (FootballService, RacketService, RaceService), así cuesta muy pocas piezas.
--   * Fútbol 7: pieza «Pitch» de césped con porterías «Goal» y balón (FootballService la encuentra sola
--     y pone sus carteles «Jugar · Fútbol»).
--   * 2 pistas «Court» de tenis y pádel (RacketService; carteles «Jugar · Tenis» y «Jugar · Pádel» de
--     Services/ZonasDeporteService).
--   * Recta de atletismo (pieza «Track» con la etiqueta PEArea: RaceService pinta las calles y la meta;
--     cartel «Correr · Carrera» de ZonasDeporteService).
--   * Grada, focos para la noche y cartel.
-- Coordenadas del sitio: X hacia el este, Z hacia el sur (la avenida queda al norte).

local Builder = require(script.Parent.Parent.Parent.Builder)
local Kit = require(script.Parent.OcioKit)
local Toys = require(game:GetService("ReplicatedStorage").Shared.Toys)
local Sitios = require(game:GetService("ReplicatedStorage").Shared.OcioSitios)

local PolideportivoCampus = {}

local rgb = Color3.fromRGB
local NORTH, SOUTH = Vector3.new(0, 0, -1), Vector3.new(0, 0, 1)

PolideportivoCampus.PITCH = { X = -50, Z = 8, Length = 90, Width = 55 }
PolideportivoCampus.COURTS = { { X = 58, Z = -36, Kind = "Tenis" }, { X = 58, Z = 36, Kind = "Padel" } }
PolideportivoCampus.TRACK = { X = -50, Z = 62, Length = 110, Width = 14 }

function PolideportivoCampus.build(parent: Instance): Model
	local site = Sitios.get("Campus") :: any
	local root = Builder.model("Ocio_Campus", parent)
	root:SetAttribute("Zone", site.Zone)
	local base = Sitios.cframe("Campus")
	local function at(x: number, z: number, dir: Vector3?): CFrame
		local p = base * CFrame.new(x, 0, z)
		return if dir then Builder.facing(p.Position, dir) else p
	end

	-- Fútbol 7
	local f = PolideportivoCampus.PITCH
	local futbol = Builder.model("Futbol7", root)
	Kit.part(futbol, "Pitch", Vector3.new(f.Length, 1.3, f.Width), at(f.X, f.Z) * CFrame.new(0, 0.5, 0), rgb(70, 146, 66), Enum.Material.Grass)
	for _, l in { { f.Length, 0.5, 0, -f.Width / 2 + 1 }, { f.Length, 0.5, 0, f.Width / 2 - 1 }, { 0.5, f.Width, -f.Length / 2 + 1, 0 }, { 0.5, f.Width, f.Length / 2 - 1, 0 }, { 0.5, f.Width, 0, 0 } } do
		Kit.decor(futbol, "Line", Vector3.new(l[1], 0.06, l[2]), at(f.X + l[3], f.Z + l[4]) * CFrame.new(0, 1.18, 0), Kit.WHITE)
	end
	for _, x in { -f.Length / 2 + 1, f.Length / 2 - 1 } do
		Kit.part(futbol, "Goal", Vector3.new(1, 6.5, 16), at(f.X + x, f.Z) * CFrame.new(0, 4.4, 0), Kit.WHITE, Enum.Material.Metal, { Transparency = 0.5 })
	end
	Toys.make("Futbol", at(f.X, f.Z) * CFrame.new(0, 2.2, 0), futbol)

	-- Pistas de tenis y pádel
	for i, c in PolideportivoCampus.COURTS do
		local m = Kit.model("Pista_" .. c.Kind, root)
		local court = Kit.part(m, "Court", Vector3.new(56, 1.3, 28), at(c.X, c.Z) * CFrame.new(0, 0.5, 0), if i == 1 then rgb(60, 110, 170) else rgb(50, 130, 110), Enum.Material.Concrete)
		court:SetAttribute("OcioRacket", c.Kind)
		court:AddTag("OcioRacketCourt")
		Kit.decor(m, "Fence", Vector3.new(58, 3, 0.2), at(c.X, c.Z + (if i == 1 then -15 else 15)) * CFrame.new(0, 2.6, 0), rgb(40, 90, 60), Enum.Material.Fabric, { Transparency = 0.3 })
	end

	-- Recta de atletismo (PEArea: RaceService)
	local t = PolideportivoCampus.TRACK
	local track = Kit.part(root, "Track", Vector3.new(t.Length, 1.3, t.Width), at(t.X, t.Z) * CFrame.new(0, 0.5, 0), rgb(176, 72, 52), Enum.Material.Rubber, { Tags = { "PEArea", "OcioTrack" } })
	track:SetAttribute("OcioRace", true)
	for k = 1, 3 do
		Kit.decor(root, "Lane", Vector3.new(t.Length, 0.04, 0.2), at(t.X, t.Z - t.Width / 2 + k * t.Width / 4) * CFrame.new(0, 1.17, 0), Kit.WHITE)
	end

	-- Grada al norte del campo (de cara al campo)
	Kit.part(root, "Grada", Vector3.new(60, 5, 8), at(f.X, f.Z - f.Width / 2 - 9, SOUTH) * CFrame.new(0, 2.5, 0), rgb(170, 170, 176), Enum.Material.Concrete, { ClassName = "WedgePart" })

	-- Focos (se encienden de noche) y cartel en la entrada
	for _, p in { { -96, -22 }, { -4, -22 }, { -96, 42 }, { -4, 42 }, { 98, 0 } } do
		Kit.floodlight(root, at(p[1], p[2]), 18)
	end
	local info = Kit.sign(root, at(20, -66, NORTH), "POLIDEPORTIVO DEL CAMPUS · fútbol 7, tenis, pádel y atletismo", 12, 2.6, rgb(120, 40, 50))
	info.Name = "CampusInfo"
	return root
end

return PolideportivoCampus
