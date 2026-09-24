-- Stages: las etapas de la vida, en orden. Las misiones y capítulos piden una etapa mínima o máxima.

local Stages = {}

Stages.Order = { "Bebe", "Nino", "Adolescente", "AdultoJoven", "Adulto", "Mayor" }

Stages.Rank = {} :: { [string]: number }
for index, stage in Stages.Order do
	Stages.Rank[stage] = index
end

function Stages.isValid(stage: string?): boolean
	return stage ~= nil and Stages.Rank[stage] ~= nil
end

-- ¿Está la etapa dentro del rango [min, max]? (cualquiera de los dos puede faltar)
function Stages.inRange(stage: string, min: string?, max: string?): boolean
	local rank = Stages.Rank[stage]
	if not rank then
		return false
	end
	if min and rank < Stages.Rank[min] then
		return false
	end
	if max and rank > Stages.Rank[max] then
		return false
	end
	return true
end

-- ¿Puede alguien de esta etapa hacer esta acción? (Config.StageLimits: Work, ClaimHome, Travel...)
-- Devuelve también la etapa mínima, para explicárselo al jugador.
function Stages.allows(stage: string?, action: string, limits: { [string]: string }): (boolean, string?)
	local min = limits[action]
	if not min then
		return true
	end
	return stage ~= nil and Stages.inRange(stage, min, nil), min
end

return Stages
