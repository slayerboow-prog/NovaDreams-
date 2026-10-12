-- RaceStory (compartido): los pasos de atletismo de la historia jugados de verdad (Sports/RaceSim).
--
--   Game = "Carrera"  Rivals = { "Alumno1", … } (una calle cada uno), Puesto = 2 (hay que llegar
--                     entre los N primeros para ganar), RivalSkill
--   Game = "Relevo"   Team = { 3 compañeros } (corres la última posta), Rivals = { 4 rivales },
--                     Puesto = 1, RivalSkill
--
-- result(spec, outcome) -> { Won, Score (el puesto), Detail } como los demás minijuegos.

local RaceStory = {}

RaceStory.Games = { Carrera = true, Relevo = true }

function RaceStory.maxSeconds(spec: { [string]: any }): number
	if type(spec.MaxSeconds) == "number" then
		return spec.MaxSeconds
	end
	return if spec.Game == "Relevo" then 150 else 110
end

function RaceStory.options(spec: { [string]: any }): { [string]: any }
	if spec.Game == "Relevo" then
		return {
			Mode = "Relevo",
			Team = spec.Team or {},
			Rivals = spec.Rivals or {},
			Skill1 = spec.TeamSkill or 0.5,
			Skill2 = spec.RivalSkill or 0.45,
			Puesto = spec.Puesto or 1,
		}
	end
	return {
		Mode = "Carrera",
		Rivals = spec.Rivals or {},
		Lanes = math.clamp((#(spec.Rivals or {})) + 1, 2, 6),
		Skill2 = spec.RivalSkill or 0.45,
		Puesto = spec.Puesto or 1,
	}
end

function RaceStory.result(spec: { [string]: any }, outcome: { [string]: any }?, abandoned: boolean?): { [string]: any }
	local o = outcome or {}
	local place = tonumber(o.Place)
	local need = spec.Puesto or 1
	local won = not abandoned and place ~= nil and place <= need
	return { Won = won, Score = place or 0, Detail = { Real = true, Place = place, Time = o.Time, Disqualified = o.Disqualified == true, Abandoned = abandoned == true } }
end

return RaceStory
