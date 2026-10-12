-- VolleyStory (compartido): el vóley playa de la historia jugado de verdad (Sports/VolleySim).
--   Game = "Voley"  Points = 7, Team = { "Adrian" } (tu pareja), Rivals = { "…", "…" }, RivalSkill
-- result(spec, outcome) -> { Won, Score, Against, Detail } como los demás minijuegos.

local VolleyStory = {}

VolleyStory.Games = { Voley = true }

function VolleyStory.maxSeconds(spec: { [string]: any }): number
	return if type(spec.MaxSeconds) == "number" then spec.MaxSeconds else 420
end

function VolleyStory.options(spec: { [string]: any }): { [string]: any }
	return {
		Points = math.clamp(spec.Points or 7, 3, 21),
		Team = spec.Team or {},
		Rivals = spec.Rivals or {},
		Skill1 = spec.TeamSkill or 0.55,
		Skill2 = spec.RivalSkill or 0.42,
		Duration = 360,
	}
end

function VolleyStory.result(spec: { [string]: any }, outcome: { [string]: any }?, abandoned: boolean?): { [string]: any }
	local o = outcome or {}
	local a = math.max(0, math.floor(tonumber(o.Goals) or 0))
	local b = math.max(0, math.floor(tonumber(o.Against) or 0))
	return { Won = not abandoned and a > b, Score = a, Against = b, Detail = { Real = true, Draw = a == b, Abandoned = abandoned == true } }
end

return VolleyStory
