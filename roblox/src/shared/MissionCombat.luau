-- MissionCombat: los enemigos de un combate de misión (pasos Fight: las cucarachas, Petra…).
--
-- Regla: a un enemigo se le ATACA, nunca se le «interactúa». Antes cada enemigo llevaba un cartel
-- (ProximityPrompt «Lanzar globo de agua») y en el móvil, al acercarse, ese cartel convertía el botón
-- de Interactuar en el de atacar y le quitaba el sitio al de verdad. Ahora:
--   * El servidor (SceneService) marca al enemigo (atributos MissionEnemy = misión, Owner = jugador) y
--     no le pone cartel (wantsPrompt).
--   * El botón de atacar (Controllers/CombatController, hueco «Ataque») le da desde lejos al enemigo
--     más cercano (nearest); con un arma en la mano, cada disparo que le toca le quita la vida de su
--     arma (DamageService; la pistola de agua, a los «de juguete»: shared/EnemyStats), y si pasa
--     rozando, también (aimed: ayuda al apuntar en el móvil).
--   * Vida por puntos: EnemyHealth / EnemyMaxHealth en el modelo; EnemyDown cuando ha caído.
--   * El cliente apaga cualquier cartel que cuelgue de un enemigo (blocksPrompt) y el botón de
--     Interactuar no lo ofrece.
--
-- El cliente: MissionCombat.mine(models, userId) = los enemigos de tu combate (etiqueta MissionEnemy).
--
-- Funciones puras (sin servicios): las prueba scripts/test-cucarachas.luau.

local MissionCombat = {}

MissionCombat.ATTR = "MissionEnemy"
MissionCombat.Range = 40 -- studs: el botón de atacar llega hasta aquí (un globo de agua se lanza lejos)
MissionCombat.AimAngle = 9 -- grados: un disparo que pasa así de cerca del enemigo le da
MissionCombat.HitGap = 0.25 -- segundos entre dos impactos que cuentan (la pistola de agua dispara 8/s)

-- Marca (o desmarca, questId = nil) a un personaje como enemigo de un combate de misión.
-- spec.MaxHealth / spec.Health (LifeStoryService): su vida por puntos, en los atributos EnemyMaxHealth
-- y EnemyHealth (la barra de vida del cliente). Solo se ponen si aún no los tiene: después los lleva
-- al día la misión con cada daño (DamageService).
function MissionCombat.mark(model: Instance, questId: string?, ownerId: number?, spec: { [string]: any }?)
	model:SetAttribute(MissionCombat.ATTR, questId)
	if questId then
		model:SetAttribute("Owner", ownerId)
		model:AddTag(MissionCombat.ATTR) -- (el cliente los busca por la etiqueta)
		if spec and type(spec.MaxHealth) == "number" and model:GetAttribute("EnemyMaxHealth") == nil then
			model:SetAttribute("EnemyMaxHealth", spec.MaxHealth)
			model:SetAttribute("EnemyHealth", if type(spec.Health) == "number" then spec.Health else spec.MaxHealth)
		end
	else
		if model:HasTag(MissionCombat.ATTR) then
			model:RemoveTag(MissionCombat.ATTR)
		end
		if model:GetAttribute("EnemyMaxHealth") ~= nil then
			model:SetAttribute("EnemyMaxHealth", nil)
			model:SetAttribute("EnemyHealth", nil)
		end
	end
end

function MissionCombat.isEnemy(model: Instance?): boolean
	return model ~= nil and model:GetAttribute(MissionCombat.ATTR) ~= nil
end

-- ¿Este actor lleva cartel? Un enemigo nunca (se le ataca); los demás, salvo Prompt = false
function MissionCombat.wantsPrompt(spec: { [string]: any }): boolean
	return spec.Prompt ~= false and spec.Enemy ~= true
end

-- ¿Hay que apagar este cartel? (cuelga de un enemigo: el personaje con MissionEnemy)
function MissionCombat.blocksPrompt(prompt: Instance): boolean
	local node: Instance? = prompt.Parent
	for _ = 1, 6 do
		if not node then
			return false
		end
		if node:GetAttribute(MissionCombat.ATTR) ~= nil then
			return true
		end
		node = node.Parent
	end
	return false
end

-- El más cercano (en horizontal) de una lista { { Position = Vector3, ... } } a menos de range
function MissionCombat.nearest<T>(list: { T }, from: Vector3, range: number?, positionOf: (T) -> Vector3?): (T?, number)
	local best, bestDistance = nil, range or MissionCombat.Range
	for _, item in list do
		local at = positionOf(item)
		if at then
			local d = Vector3.new(at.X - from.X, 0, at.Z - from.Z).Magnitude
			if d <= bestDistance then
				best, bestDistance = item, d
			end
		end
	end
	return best, bestDistance
end

-- ¿Un disparo desde origin hacia direction pasa cerca de target? (ángulo pequeño y dentro del alcance)
function MissionCombat.aimed(origin: Vector3, direction: Vector3, target: Vector3, range: number, maxAngle: number?): boolean
	local to = target - origin
	local distance = to.Magnitude
	if distance < 0.01 then
		return true
	end
	if distance > range or direction.Magnitude < 0.01 then
		return false
	end
	local cos = math.clamp(to.Unit:Dot(direction.Unit), -1, 1)
	local angle = math.deg(math.acos(cos))
	-- De cerca se perdona un poco más (un bicho pequeño a tus pies)
	local allowed = (maxAngle or MissionCombat.AimAngle) * (if distance < 8 then 2 else 1)
	return angle <= allowed
end

-- Los enemigos que son de este jugador (cada uno ve solo su combate)
function MissionCombat.mine(models: { Instance }, userId: number): { Model }
	local list = {}
	for _, model in models do
		if model:IsA("Model") and model:GetAttribute(MissionCombat.ATTR) ~= nil and model:GetAttribute("Owner") == userId and model.Parent
			and not model:GetAttribute("EnemyDown") then
			table.insert(list, model)
		end
	end
	return list
end

-- ¿Ha pasado bastante desde el último impacto que contó?
function MissionCombat.ready(lastHit: number?, now: number): boolean
	return lastHit == nil or now - lastHit >= MissionCombat.HitGap
end

return MissionCombat
