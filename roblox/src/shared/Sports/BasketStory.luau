-- BasketStory (compartido): los pasos de baloncesto de la historia (Type = "MiniGame") jugados de verdad
-- en una canasta del mapa (Sports/BasketSim) en lugar de con la barra de precisión.
--
--   Game = "Canastas"    Rounds = 8, Need = 3, Spots = "Libres" (línea de tiros libres) o "Variado"
--                        (cada tiro desde otro sitio y más lejos)
--   Game = "Baloncesto"  partido: Seconds = 120, Size = 3, Team = { "Alex", … }, Rivals = { … },
--                        Rival = "4.º B" (el nombre en el marcador)
--
-- options(spec) y result(spec, outcome) como Sports/FootballStory: la misión recibe lo de siempre
-- ({ Won, Score, Against, Detail }). Se prueba en scripts/test-baloncesto.luau.

local BasketStory = {}

BasketStory.Games = { Canastas = true, Baloncesto = true }

function BasketStory.duration(spec: { [string]: any }): number
	if type(spec.Seconds) == "number" then
		return math.clamp(spec.Seconds, 45, 600)
	end
	return 120
end

function BasketStory.maxSeconds(spec: { [string]: any }): number
	if type(spec.MaxSeconds) == "number" then
		return spec.MaxSeconds
	end
	if spec.Game == "Baloncesto" then
		return BasketStory.duration(spec) + 150
	end
	return 60 + (spec.Rounds or 5) * 35
end

function BasketStory.options(spec: { [string]: any }): { [string]: any }
	if spec.Game == "Canastas" then
		return {
			Mode = "Tiros",
			Rounds = spec.Rounds or 5,
			Need = spec.Need or 1,
			Spots = spec.Spots or "Libres",
			StopWhenDecided = true,
		}
	end
	local team = spec.Team or {}
	local rivals = spec.Rivals or {}
	return {
		Mode = "Partido",
		Duration = BasketStory.duration(spec),
		Size = spec.Size or math.clamp(math.max(#team + 1, #rivals, 2), 1, 5),
		Team = team,
		Rivals = rivals,
		Skill1 = spec.TeamSkill or 0.5,
		Skill2 = spec.RivalSkill or 0.42,
		Rival = spec.Rival,
	}
end

function BasketStory.result(spec: { [string]: any }, outcome: { [string]: any }?, abandoned: boolean?): { [string]: any }
	local o = outcome or {}
	if spec.Game == "Baloncesto" then
		local points = math.max(0, math.floor(tonumber(o.Goals) or 0))
		local against = math.max(0, math.floor(tonumber(o.Against) or 0))
		if abandoned then
			return { Won = false, Score = points, Against = math.max(against, points + 1), Detail = { Draw = false, Real = true, Abandoned = true } }
		end
		return { Won = points > against, Score = points, Against = against, Detail = { Draw = points == against, Real = true } }
	end
	local hits = math.max(0, math.floor(tonumber(o.Hits) or 0))
	return { Won = not abandoned and hits >= (spec.Need or 1), Score = hits, Detail = { Real = true, Taken = o.Taken, Abandoned = abandoned == true } }
end

return BasketStory
