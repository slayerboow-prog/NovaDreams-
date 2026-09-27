-- Toys: los objetos con física que se pueden patear o empujar (balones, conos…).
-- El mapa los coloca (Toys.make) y el servidor los hace físicos (ToyService): cuando pasas
-- corriendo o les das una patada salen disparados, botan, ruedan y flotan en el agua.

local Toys = {}

export type Kind = {
	Name: string,
	Size: Vector3,
	Color: Color3,
	Shape: Enum.PartType?,
	Material: Enum.Material?,
	Density: number, -- ligero = sale volando (el de playa); pesado = casi no se mueve
	Elasticity: number, -- cuánto bota
	Friction: number,
	Kick: number, -- fuerza de la patada (1 = balón de fútbol)
	Lift: number, -- cuánto sube al patearlo
}

local rgb = Color3.fromRGB

Toys.Kinds = {
	Futbol = {
		Name = "Balón de fútbol", Size = Vector3.new(2, 2, 2), Color = rgb(245, 245, 245), Shape = Enum.PartType.Ball,
		Density = 0.25, Elasticity = 0.6, Friction = 0.5, Kick = 1, Lift = 1,
	},
	Playa = {
		Name = "Balón de playa", Size = Vector3.new(2.6, 2.6, 2.6), Color = rgb(250, 90, 80), Shape = Enum.PartType.Ball,
		Density = 0.08, Elasticity = 0.75, Friction = 0.4, Kick = 0.7, Lift = 1.6,
	},
	Baloncesto = {
		Name = "Balón de baloncesto", Size = Vector3.new(1.2, 1.2, 1.2), Color = rgb(230, 110, 40), Shape = Enum.PartType.Ball,
		Density = 0.35, Elasticity = 0.8, Friction = 0.6, Kick = 0.7, Lift = 1.2,
	},
	Cono = {
		Name = "Cono", Size = Vector3.new(0.8, 1.2, 0.8), Color = rgb(250, 120, 30),
		Density = 0.3, Elasticity = 0.1, Friction = 0.8, Kick = 0.45, Lift = 0.4,
	},
} :: { [string]: Kind }

-- Velocidad que coge al darle: hacia donde va el jugador (o, si está quieto, alejándose de él),
-- más fuerte cuanto más rápido vaya. Devuelve la velocidad que hay que sumarle.
function Toys.kickVelocity(kind: Kind, toyPosition: Vector3, playerPosition: Vector3, playerVelocity: Vector3): Vector3
	local flatVelocity = Vector3.new(playerVelocity.X, 0, playerVelocity.Z)
	local away = Vector3.new(toyPosition.X - playerPosition.X, 0, toyPosition.Z - playerPosition.Z)
	local direction: Vector3
	if flatVelocity.Magnitude > 2 then
		-- Mezcla: sobre todo hacia donde corres, un poco hacia donde le has dado
		local mix = flatVelocity.Unit * 0.7 + (if away.Magnitude > 0.01 then away.Unit * 0.3 else Vector3.zero)
		direction = if mix.Magnitude > 0.01 then mix.Unit else flatVelocity.Unit
	elseif away.Magnitude > 0.01 then
		direction = away.Unit
	else
		direction = Vector3.new(0, 0, -1)
	end
	local speed = math.min(flatVelocity.Magnitude, 30)
	local forward = (12 + speed * 0.9) * kind.Kick
	local up = (5 + speed * 0.35) * kind.Lift
	return direction * forward + Vector3.new(0, up, 0)
end

-- ¿Hay que devolverlo a su sitio? (se ha caído del mapa, o está lejos y no hay nadie cerca)
function Toys.shouldReset(position: Vector3, home: Vector3, nearestPlayer: number): boolean
	if position.Y < home.Y - 60 then
		return true
	end
	local moved = (position - home).Magnitude
	if moved > 250 then
		return true
	end
	return nearestPlayer > 120 and moved > 3
end

-- La pieza del juguete en el mapa (quieta hasta que alguien se acerca: ToyService)
function Toys.make(kindName: string, cf: CFrame, parent: Instance): BasePart
	local kind = Toys.Kinds[kindName]
	local part = Instance.new("Part")
	part.Name = "Toy_" .. kindName
	part.Size = kind.Size
	part.Color = kind.Color
	part.Material = kind.Material or Enum.Material.SmoothPlastic
	if kind.Shape then
		part.Shape = kind.Shape
	end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = cf
	part.Anchored = true
	part:SetAttribute("Toy", kindName)
	part:AddTag("Toy")
	part.Parent = parent
	return part
end

return Toys
