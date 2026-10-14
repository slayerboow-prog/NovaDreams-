-- WeaponModel: el modelo de cada arma hecho con piezas (shared/Weapons: Parts).
--
--   WeaponModel.build(weapon, scale, anchored?) -> Model "Arma"
--       PrimaryPart = "Empunadura". Las demás piezas van soldadas a ella con un Weld que se llama
--       "W_<pieza>" (así el cliente puede mover la corredera o esconder el cargador al recargar).
--       Attachments en la empuñadura: "Boca" (boca del cañón) y "Expulsion" (ventana de expulsión).
--   WeaponModel.gripOffset(scale)  dónde va la empuñadura respecto a la mano derecha (R15)
--   WeaponModel.holsterOffset(weapon, scale)  pistolera en la cadera o a la espalda
--
-- Lo usan WeaponService (el arma en la mano, para todos) y el kit de la Armería (expositor).

local Weapons = require(game:GetService("ReplicatedStorage").Shared.Weapons)

local WeaponModel = {}

local MATERIALS = {
	Metal = Enum.Material.Metal,
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Wood = Enum.Material.Wood,
	Glass = Enum.Material.Glass,
}

local function scaled(cf: CFrame, scale: number): CFrame
	return CFrame.new(cf.Position * scale) * cf.Rotation
end

function WeaponModel.build(w: Weapons.Weapon, scale: number, anchored: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "Arma"
	model:SetAttribute("Weapon", w.Id)
	local gripSpec = w.Parts[1]
	local gripAt = scaled(gripSpec.At, scale)
	local grip: BasePart? = nil
	local parts: { [string]: BasePart } = {}
	for _, spec in w.Parts do
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = spec.Size * scale
		if spec.Shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		part.Color = spec.Color
		part.Material = MATERIALS[spec.Material or ""] or Enum.Material.SmoothPlastic
		if spec.Material == "Glass" then
			part.Transparency = 0.35
		end
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		part.Anchored = anchored == true
		part.CFrame = scaled(spec.At, scale)
		part.Parent = model
		parts[spec.Name] = part
		if not grip then
			grip = part
		end
	end
	local primary = grip :: BasePart
	model.PrimaryPart = primary
	if not anchored then
		for name, part in parts do
			if part ~= primary then
				local weld = Instance.new("Weld")
				weld.Name = "W_" .. name
				weld.Part0 = primary
				weld.Part1 = part
				weld.C0 = gripAt:Inverse() * part.CFrame
				weld.Parent = primary
			end
		end
	end
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Boca"
	muzzle.CFrame = gripAt:Inverse() * CFrame.new(w.Muzzle * scale)
	muzzle.Parent = primary
	local eject = Instance.new("Attachment")
	eject.Name = "Expulsion"
	eject.CFrame = gripAt:Inverse() * CFrame.new(w.Eject * scale)
	eject.Parent = primary
	model:SetAttribute("Scale", scale)
	return model
end

-- Mano derecha R15 -> origen del arma (puño cerrado: el cañón sale por delante de los nudillos,
-- como la RightGripAttachment de Roblox), y de ahí a la empuñadura
function WeaponModel.gripOffset(w: Weapons.Weapon, scale: number): CFrame
	return CFrame.new(0, -0.15 * scale, 0) * CFrame.Angles(-math.pi / 2, 0, 0) * scaled(w.Parts[1].At, scale)
end

-- Guardada: pistolas en la cadera derecha (cañón hacia abajo) y armas largas cruzadas a la espalda
-- Devuelve (nombre de la pieza del cuerpo, desplazamiento)
function WeaponModel.holsterOffset(w: Weapons.Weapon, scale: number): (string, CFrame)
	local grip = scaled(w.Parts[1].At, scale)
	if w.Holster == "Hip" then
		return "LowerTorso", CFrame.new(1.05 * scale, -0.35 * scale, 0) * CFrame.Angles(-math.pi / 2, 0, 0) * grip
	end
	return "UpperTorso", CFrame.new(0.2 * scale, -0.25 * scale, 0.75 * scale) * CFrame.Angles(0, 0, math.rad(-45)) * CFrame.Angles(0, math.rad(90), 0) * grip
end

return WeaponModel
