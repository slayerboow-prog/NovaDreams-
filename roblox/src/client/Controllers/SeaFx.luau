-- SeaFx (cliente): lo que se ve alrededor de quien nada, bucea o pesca (solo en tu pantalla).
--   * Caña en la mano de los demás jugadores cuando pescan (la tuya la pone FishingUI).
--   * Fusil submarino o arpón en la mano al bucear con él (atributo Speargun del jugador).
--   * Gafas y tubo en la cara, y la botella a la espalda con el equipo de buceo (atributo DiveGear).
--   * El pez que acabas de sacar, en la mano izquierda, mientras lo enseñas.
--   * Burbujas al bucear, estela al nadar a crol y salpicadura al tirarte al agua.
-- AgeMotion lo llama cada frame con el estado que ha elegido SeaMotion.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fishing = require(ReplicatedStorage.Shared.Fishing)

local SeaFx = {}

local rgb = Color3.fromRGB
local localPlayer = Players.LocalPlayer

type Fx = {
	Rod: BasePart?,
	Gun: BasePart?,
	GunKind: string?,
	Mask: { BasePart }?,
	Tank: BasePart?,
	Fish: BasePart?,
	FishId: string?,
	Bubbles: ParticleEmitter?,
	Wake: ParticleEmitter?,
	Splash: ParticleEmitter?,
	InWater: boolean,
}

local function part(name: string, size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	return p
end

-- Pega una pieza a otra (la coloca con `offset` respecto a ella)
local function attach(p: BasePart, to: BasePart, offset: CFrame, model: Instance)
	p.CFrame = to.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
end

local function drop(fx: Fx, key: string)
	local thing = (fx :: any)[key]
	if typeof(thing) == "Instance" then
		thing:Destroy()
	elseif type(thing) == "table" then
		for _, p in thing do
			p:Destroy()
		end
	end
	(fx :: any)[key] = nil
end

local function emitter(name: string, color: Color3, parent: Instance): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.3
	e.Enabled = false
	e.Parent = parent
	return e
end

function SeaFx.new(): Fx
	return { InWater = false }
end

function SeaFx.clear(fx: Fx)
	for _, key in { "Rod", "Gun", "Mask", "Tank", "Fish", "Bubbles", "Wake", "Splash" } do
		drop(fx, key)
	end
	fx.InWater = false
	fx.GunKind = nil
	fx.FishId = nil
end

export type State = {
	Model: Model,
	Player: Player?,
	State: string?, -- lo que ha elegido SeaMotion
	InWater: boolean,
	Underwater: boolean,
	Vertical: number,
	Fishing: boolean, -- tiene la caña fuera (atributo FishAnim)
	FishId: string?, -- el pez que enseña
	Gun: string?, -- "Arpon" o "FusilSubmarino"
	Gear: string?, -- "Gafas" o "Botella"
}

function SeaFx.update(fx: Fx, s: State)
	local model = s.Model
	local rightHand = model:FindFirstChild("RightHand") :: BasePart?
	local leftHand = model:FindFirstChild("LeftHand") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	local torso = model:FindFirstChild("UpperTorso") :: BasePart?
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?

	-- Caña (la tuya ya la pone FishingUI)
	local wantRod = s.Fishing and not s.InWater and s.Player ~= localPlayer and rightHand ~= nil
	if wantRod and not fx.Rod then
		local rod = part("SeaRod", Vector3.new(0.14, 0.14, 7), rgb(40, 40, 44), Enum.Material.Metal)
		attach(rod, rightHand :: BasePart, CFrame.new(0, -0.2, -3.2) * CFrame.Angles(math.rad(35), 0, 0), model)
		fx.Rod = rod
	elseif not wantRod and fx.Rod then
		drop(fx, "Rod")
	end

	-- Fusil o arpón bajo el agua
	local wantGun = if s.Underwater and rightHand then s.Gun else nil
	if wantGun ~= fx.GunKind then
		drop(fx, "Gun")
		fx.GunKind = wantGun
		if wantGun then
			local arpon = wantGun == "Arpon"
			local gun = part("SeaGun", Vector3.new(0.22, if arpon then 3.6 else 2.6, 0.3), if arpon then rgb(200, 170, 70) else rgb(30, 34, 40), Enum.Material.Metal)
			attach(gun, rightHand :: BasePart, CFrame.new(0, -(gun.Size.Y / 2), -0.1), model)
			local tip = part("SeaGunTip", Vector3.new(0.08, 0.6, 0.08), rgb(210, 215, 225), Enum.Material.Metal)
			attach(tip, gun, CFrame.new(0, -(gun.Size.Y / 2 + 0.3), 0), gun)
			fx.Gun = gun
		end
	end

	-- Gafas y tubo, y botella a la espalda (solo en el agua)
	local wantMask = s.InWater and s.Gear ~= nil and head ~= nil
	if wantMask and not fx.Mask then
		local h = head :: BasePart
		local glass = part("SeaMask", Vector3.new(h.Size.X * 0.8, h.Size.Y * 0.3, 0.2), rgb(120, 200, 240), Enum.Material.Glass)
		glass.Transparency = 0.35
		attach(glass, h, CFrame.new(0, h.Size.Y * 0.08, -h.Size.Z / 2 - 0.05), model)
		local strap = part("SeaStrap", Vector3.new(h.Size.X * 1.02, 0.12, h.Size.Z * 1.02), rgb(20, 20, 24))
		attach(strap, h, CFrame.new(0, h.Size.Y * 0.08, 0), model)
		local snorkel = part("SeaSnorkel", Vector3.new(0.12, h.Size.Y * 0.9, 0.12), rgb(250, 200, 40))
		attach(snorkel, h, CFrame.new(h.Size.X / 2 + 0.05, h.Size.Y * 0.35, -0.1), model)
		fx.Mask = { glass, strap, snorkel }
	elseif not wantMask and fx.Mask then
		drop(fx, "Mask")
	end
	local wantTank = s.InWater and s.Gear == "Botella" and torso ~= nil
	if wantTank and not fx.Tank then
		local t = torso :: BasePart
		local tank = part("SeaTank", Vector3.new(0.7, t.Size.Y * 1.1, 0.7), rgb(240, 200, 40), Enum.Material.Metal, Enum.PartType.Cylinder)
		-- (el cilindro va a lo largo de X: se gira para que quede de pie)
		attach(tank, t, CFrame.new(0, 0, t.Size.Z / 2 + 0.35) * CFrame.Angles(0, 0, math.rad(90)), model)
		fx.Tank = tank
	elseif not wantTank and fx.Tank then
		drop(fx, "Tank")
	end

	-- El pez que enseña al sacarlo
	local fishId = if s.State == "Catch" and leftHand then s.FishId else nil
	if fishId ~= fx.FishId then
		drop(fx, "Fish")
		fx.FishId = fishId
		local species = fishId and (Fishing.byId[fishId] or Fishing.Bosses[fishId])
		if species then
			local kg = (species.Kg[1] + species.Kg[2]) / 2
			local len = math.clamp(0.6 + kg ^ 0.33 * 0.5, 0.6, 3.2)
			local fish = part("SeaCatch", Vector3.new(len * 0.3, len * 0.45, len), Fishing.RarityColors[species.Rarity or "Legendario"] or rgb(200, 210, 225))
			attach(fish, leftHand :: BasePart, CFrame.new(0, -0.35, -len * 0.3) * CFrame.Angles(math.rad(80), 0, 0), model)
			local tail = part("SeaCatchTail", Vector3.new(len * 0.1, len * 0.4, len * 0.25), fish.Color)
			attach(tail, fish, CFrame.new(0, 0, len * 0.55), fish)
			fx.Fish = fish
		end
	end

	-- Burbujas, estela y salpicadura
	if head and not fx.Bubbles then
		local b = emitter("SeaBubbles", rgb(220, 240, 255), head)
		b.Rate = 6
		b.Lifetime = NumberRange.new(1, 1.8)
		b.Speed = NumberRange.new(2, 4)
		b.SpreadAngle = Vector2.new(15, 15)
		b.Acceleration = Vector3.new(0, 4, 0)
		b.Size = NumberSequence.new(0.18, 0.08)
		b.Transparency = NumberSequence.new(0.2, 1)
		b.EmissionDirection = Enum.NormalId.Top
		fx.Bubbles = b
	end
	if root and not fx.Wake then
		local w = emitter("SeaWake", rgb(245, 250, 255), root)
		w.Rate = 18
		w.Lifetime = NumberRange.new(0.5, 0.9)
		w.Speed = NumberRange.new(1, 3)
		w.SpreadAngle = Vector2.new(60, 60)
		w.Size = NumberSequence.new(0.5, 1.2)
		w.Transparency = NumberSequence.new(0.35, 1)
		fx.Wake = w
		local sp = emitter("SeaSplash", rgb(235, 245, 255), root)
		sp.Lifetime = NumberRange.new(0.5, 1)
		sp.Speed = NumberRange.new(8, 16)
		sp.SpreadAngle = Vector2.new(35, 35)
		sp.Acceleration = Vector3.new(0, -30, 0)
		sp.EmissionDirection = Enum.NormalId.Top
		sp.Size = NumberSequence.new(0.6, 0.2)
		sp.Transparency = NumberSequence.new(0.1, 1)
		fx.Splash = sp
	end
	if fx.Bubbles then
		fx.Bubbles.Enabled = s.Underwater
		fx.Bubbles.Rate = if s.Gear == "Botella" then 10 else 5
	end
	if fx.Wake then
		fx.Wake.Enabled = s.State == "Crawl"
	end
	if s.InWater and not fx.InWater and fx.Splash and s.Vertical < -6 then
		fx.Splash:Emit(24)
	end
	fx.InWater = s.InWater
end

return SeaFx
