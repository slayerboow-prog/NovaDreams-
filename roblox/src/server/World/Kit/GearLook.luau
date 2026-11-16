-- GearLook (servidor): el EQUIPO que llevas, VISTO en tu personaje (shared/Crafting.stats → Worn). Lo pone
-- Services/GearService cuando estás en un planeta (en Valmar no: tu ropa de siempre).
--
--   * Arma en la mano derecha según su estilo (cuchillo, hacha, lanza, espada); armadura con peto y hombreras;
--     casco; escudo en el antebrazo izquierdo; botas; collar, pulsera y pendientes.
--   * Brillo por las mejoras: desde +4 un brillo azul con chispas; desde +7, dorado (en el arma, también en
--     la armadura).
--   * Todo son piezas soldadas (Weld) a su parte del cuerpo: no chocan, no pesan y se mueven con las
--     animaciones. Sirve en R15 (UpperTorso, RightHand…) y en R6 (Torso, Right Arm…).
--
-- API: GearLook.apply(character, worn, refine) (quita lo de antes y pone lo nuevo) · GearLook.clear(character)

local GearLook = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB
local FOLDER = "EquipoVisible"

-- Color de cada objeto (su material: cuero, quitina, escama, hueso, cristal, trofeo…)
GearLook.Colors = {
	ArmaduraCuero = rgb(120, 82, 52), ArmaduraQuitina = rgb(60, 70, 50), ArmaduraEscamas = rgb(70, 110, 100),
	ArmaduraHueso = rgb(210, 200, 176), ArmaduraPlanetaria = rgb(90, 130, 170), ArmaduraTrofeo = rgb(200, 160, 60),
	CascoCeniza = rgb(70, 64, 62), CascoCromo = rgb(190, 196, 206), EscudoNacar = rgb(230, 230, 220), EscudoCorteza = rgb(110, 80, 50),
	BotasDuna = rgb(170, 130, 90), BotasEscarcha = rgb(200, 220, 240),
	CuchilloColmillo = rgb(235, 228, 210), HachaHueso = rgb(220, 210, 190), LanzaEscama = rgb(90, 150, 130),
	EspadaCristal = rgb(150, 220, 255), EspadaTrofeo = rgb(255, 200, 90),
	CollarEnjambre = rgb(240, 200, 40), CollarTormenta = rgb(140, 160, 255), PulseraCobre = rgb(200, 120, 70),
	PulseraVeneno = rgb(120, 220, 120), PendientesHielo = rgb(180, 230, 255), PendientesEstelares = rgb(255, 230, 140),
}
GearLook.WeaponStyle = { CuchilloColmillo = "Cuchillo", HachaHueso = "Hacha", LanzaEscama = "Lanza", EspadaCristal = "Espada", EspadaTrofeo = "Espada" }

local function partOf(character: Model, names: { string }): BasePart?
	for _, n in names do
		local p = character:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return nil
end

local function piece(folder: Instance, attach: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = attach.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = attach
	w.Part1 = p
	w.Parent = p
	p.Parent = folder
	return p
end

local function glow(p: BasePart, level: number)
	if level < 4 then
		return
	end
	local gold = level >= 7
	local c = if gold then rgb(255, 200, 80) else rgb(110, 190, 255)
	local light = Instance.new("PointLight")
	light.Color = c
	light.Range = if gold then 10 else 7
	light.Brightness = if gold then 1.6 else 1
	light.Shadows = false
	light.Parent = p
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "BrilloMejora"
	pe.Color = ColorSequence.new(c)
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.4, 0.8)
	pe.Rate = if gold then 22 else 10
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = p
end

local function weapon(folder: Instance, torso: BasePart, id: string, level: number)
	local style = GearLook.WeaponStyle[id] or "Espada"
	local c = GearLook.Colors[id] or rgb(200, 200, 200)
	local grip = rgb(60, 44, 32)
	-- (ENVAINADA A LA ESPALDA, en diagonal: la empuñadura asoma por encima del hombro y la hoja baja por la
	-- espalda. En la mano quedaba torcida según lo que sujetaras: visto en Studio, 16-11-2026)
	local s = torso.Size
	local base = CFrame.new(0, s.Y * 0.45, s.Z / 2 + 0.3) * CFrame.Angles(0, 0, math.rad(35)) * CFrame.Angles(-math.pi / 2, 0, 0)
	local hand = torso
	if style == "Cuchillo" then
		piece(folder, hand, "Empunadura", V3(0.25, 0.25, 0.7), base * CFrame.new(0, 0, 0.1), grip, Enum.Material.Wood)
		local blade = piece(folder, hand, "Hoja", V3(0.12, 0.35, 1.3), base * CFrame.new(0, 0, -0.85), c, Enum.Material.SmoothPlastic)
		glow(blade, level)
	elseif style == "Hacha" then
		piece(folder, hand, "Mango", V3(0.25, 0.25, 3), base * CFrame.new(0, 0, -0.9), grip, Enum.Material.Wood)
		local head = piece(folder, hand, "Cabeza", V3(0.2, 1.3, 1), base * CFrame.new(0, 0.45, -2.1), c, Enum.Material.SmoothPlastic)
		glow(head, level)
	elseif style == "Lanza" then
		piece(folder, hand, "Asta", V3(0.22, 0.22, 6), base * CFrame.new(0, 0, -1.6), grip, Enum.Material.Wood)
		local tip = piece(folder, hand, "Punta", V3(0.4, 0.15, 1.1), base * CFrame.new(0, 0, -5.1), c, Enum.Material.SmoothPlastic)
		glow(tip, level)
	else
		piece(folder, hand, "Pomo", V3(0.3, 0.3, 0.3), base * CFrame.new(0, 0, 0.45), c, Enum.Material.Metal, Enum.PartType.Ball)
		piece(folder, hand, "Puno", V3(0.25, 0.25, 0.8), base * CFrame.new(0, 0, 0), grip, Enum.Material.Fabric)
		piece(folder, hand, "Guarda", V3(1.1, 0.2, 0.2), base * CFrame.new(0, 0, -0.5), rgb(80, 80, 90), Enum.Material.Metal)
		local blade = piece(folder, hand, "Hoja", V3(0.14, 0.4, 3.2), base * CFrame.new(0, 0, -2.15), c, if id == "EspadaCristal" then Enum.Material.Glass else Enum.Material.Metal)
		glow(blade, level)
	end
end

function GearLook.clear(character: Model)
	local old = character:FindFirstChild(FOLDER)
	if old then
		old:Destroy()
	end
end

-- worn: { [hueco] = id } · refine: { [id] = nivel }
function GearLook.apply(character: Model, worn: { [string]: string }, refine: { [string]: any }?)
	GearLook.clear(character)
	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	local function lvl(id: string): number
		return math.clamp(math.floor(tonumber(refine and refine[id]) or 0), 0, 9)
	end
	local torso = partOf(character, { "UpperTorso", "Torso" })
	local head = partOf(character, { "Head" })
	local lArm = partOf(character, { "LeftLowerArm", "Left Arm" })
	local rArm = partOf(character, { "RightLowerArm", "Right Arm" })
	local feet = { partOf(character, { "LeftFoot", "Left Leg" }), partOf(character, { "RightFoot", "Right Leg" }) }
	if worn.Arma and torso then
		weapon(folder, torso, worn.Arma, lvl(worn.Arma))
	end
	if worn.Armadura and torso then
		local id = worn.Armadura
		local c = GearLook.Colors[id] or rgb(120, 110, 100)
		local s = torso.Size
		local front = piece(folder, torso, "Peto", V3(s.X * 0.86, s.Y * 0.8, 0.25), CFrame.new(0, s.Y * 0.04, -s.Z / 2 - 0.1), c, Enum.Material.Metal)
		piece(folder, torso, "Espaldar", V3(s.X * 0.86, s.Y * 0.8, 0.25), CFrame.new(0, s.Y * 0.04, s.Z / 2 + 0.1), c, Enum.Material.Metal)
		for _, sx in { -1, 1 } do
			piece(folder, torso, "Hombrera", V3(s.X * 0.32, 0.35, s.Z + 0.5), CFrame.new(sx * s.X * 0.45, s.Y / 2 + 0.05, 0) * CFrame.Angles(0, 0, -sx * 0.25), c:Lerp(rgb(0, 0, 0), 0.2), Enum.Material.Metal)
		end
		if lvl(id) >= 7 then
			glow(front, lvl(id))
		end
	end
	if worn.Casco and head then
		local c = GearLook.Colors[worn.Casco] or rgb(120, 120, 120)
		local s = head.Size
		piece(folder, head, "Casco", V3(s.X * 1.12, s.Y * 0.55, s.Z * 1.12), CFrame.new(0, s.Y * 0.3, 0), c, Enum.Material.Metal)
		piece(folder, head, "Visera", V3(s.X * 1.1, 0.15, 0.35), CFrame.new(0, s.Y * 0.05, -s.Z * 0.56), c:Lerp(rgb(0, 0, 0), 0.3), Enum.Material.Metal)
	end
	if worn.Escudo and lArm then
		local c = GearLook.Colors[worn.Escudo] or rgb(150, 150, 150)
		piece(folder, lArm, "Escudo", V3(0.25, 2.4, 1.9), CFrame.new(-lArm.Size.X / 2 - 0.2, 0, 0), c, Enum.Material.SmoothPlastic)
		piece(folder, lArm, "Umbo", V3(0.4, 0.6, 0.6), CFrame.new(-lArm.Size.X / 2 - 0.35, 0, 0), rgb(90, 90, 100), Enum.Material.Metal, Enum.PartType.Ball)
	end
	if worn.Botas then
		local c = GearLook.Colors[worn.Botas] or rgb(90, 70, 50)
		for _, f in feet do
			if f then
				piece(folder, f, "Bota", V3(f.Size.X * 1.15, math.min(f.Size.Y * 1.1, 1.2), f.Size.Z * 1.12), CFrame.new(0, 0.05, 0), c, Enum.Material.Fabric)
			end
		end
	end
	if worn.Collar and torso then
		local c = GearLook.Colors[worn.Collar] or rgb(220, 200, 60)
		piece(folder, torso, "Collar", V3(0.28, 0.28, 0.14), CFrame.new(0, torso.Size.Y * 0.28, -torso.Size.Z / 2 - 0.3), c, Enum.Material.Neon, Enum.PartType.Ball)
	end
	if worn.Pulsera and rArm then
		local c = GearLook.Colors[worn.Pulsera] or rgb(200, 120, 70)
		piece(folder, rArm, "Pulsera", V3(rArm.Size.X * 1.15, 0.25, rArm.Size.Z * 1.15), CFrame.new(0, -rArm.Size.Y * 0.3, 0), c, Enum.Material.Metal)
	end
	if worn.Pendientes and head then
		local c = GearLook.Colors[worn.Pendientes] or rgb(180, 230, 255)
		for _, sx in { -1, 1 } do
			piece(folder, head, "Pendiente", V3(0.22, 0.22, 0.22), CFrame.new(sx * (head.Size.X / 2 + 0.06), -head.Size.Y * 0.15, 0), c, Enum.Material.Neon, Enum.PartType.Ball)
		end
	end
	folder.Parent = character
	return folder
end

return GearLook
