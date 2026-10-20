-- FootballStory (compartido): los pasos de fútbol de la historia (Type = "MiniGame") jugados de
-- verdad en un campo (Sports/FootballSim) en lugar de con la barra de precisión.
--
-- Qué pide cada paso (además de Title, Icon, Hint, Win, Lose, Draw):
--   Game = "Penaltis"  Rounds = 3, Need = 2, Keeper = "Nico" (quién se pone de portero), KeeperSkill
--   Game = "Pases"     Rounds = 5, Need = 3, Receiver = "Dani", Variant = "Hueco" (corre al espacio)
--   Game = "Futbol"    Rival = "el equipo de Bruno", Team = { "Nico", … }, Rivals = { "Bruno", … },
--                      Keeper = "Omar" (vuestro portero), RivalKeeper = "Alex", Seconds = 150 (o Plays,
--                      como antes: 25 s por jugada), Size (jugadores por equipo), Position (la que
--                      eligió el jugador: Delantero, Defensa o Portero)
--
-- options(spec) -> cómo montar el partido; result(spec, outcome) -> el resultado que entiende la
-- historia ({ Won, Score, Against, Detail = { Draw } }: el mismo que daba el minijuego de antes, así
-- que las banderas y consecuencias de cada misión siguen igual). Se prueba en scripts/test-futbol.luau.

local FootballStory = {}

FootballStory.Games = { Futbol = true, Penaltis = true, Pases = true }

-- Lo más que puede durar cada uno en la historia (después, el servidor lo da por terminado)
function FootballStory.maxSeconds(spec: { [string]: any }): number
	if type(spec.MaxSeconds) == "number" then
		return spec.MaxSeconds
	end
	if spec.Game == "Futbol" then
		return FootballStory.duration(spec) + 150
	end
	local rounds = spec.Rounds or 3
	return 60 + rounds * 40
end

function FootballStory.duration(spec: { [string]: any }): number
	if type(spec.Seconds) == "number" then
		return math.clamp(spec.Seconds, 45, 600)
	end
	return math.clamp((spec.Plays or 6) * 25, 90, 240)
end

local ROLES = { Delantero = "FW", Defensa = "DF", Portero = "GK", Centro = "MF", Medio = "MF" }

function FootballStory.role(position: string?): string
	return ROLES[position or ""] or "FW"
end

-- Cómo montar el juego de un paso
function FootballStory.options(spec: { [string]: any }): { [string]: any }
	local game = spec.Game
	if game == "Penaltis" then
		return {
			Mode = "Penaltis",
			Rounds = spec.Rounds or 3,
			Need = spec.Need or 1,
			StopWhenDecided = true,
			Rivals = { spec.Keeper or "Portero" },
			Skill2 = spec.KeeperSkill or 0.35,
			HumanRole = "FW",
		}
	elseif game == "Pases" then
		return {
			Mode = "Pases",
			Rounds = spec.Rounds or 5,
			Need = spec.Need or 3,
			Variant = spec.Variant,
			StopWhenDecided = true,
			Team = { spec.Receiver or "Compañero" },
			HumanRole = "MF",
		}
	end
	local team = spec.Team or {}
	local rivals = spec.Rivals or {}
	local size = spec.Size or math.clamp(math.max(#team + 1, #rivals, 3), 3, 6)
	return {
		Mode = "Partido",
		Duration = FootballStory.duration(spec),
		Size = size,
		Team = team,
		Rivals = rivals,
		Keeper1 = spec.Keeper,
		Keeper2 = spec.RivalKeeper,
		Skill1 = spec.TeamSkill or 0.5,
		Skill2 = spec.RivalSkill or 0.42,
		KeeperSkill2 = spec.RivalKeeperSkill or 0.38,
		HumanRole = FootballStory.role(spec.Position),
		Rival = spec.Rival,
	}
end

-- outcome: lo que devuelve FootballSim.outcome (o nil si no se pudo jugar). abandoned: te fuiste.
function FootballStory.result(spec: { [string]: any }, outcome: { [string]: any }?, abandoned: boolean?): { [string]: any }
	local o = outcome or {}
	if spec.Game == "Futbol" then
		local goals = math.max(0, math.floor(tonumber(o.Goals) or 0))
		local against = math.max(0, math.floor(tonumber(o.Against) or 0))
		if abandoned then
			-- Irse a mitad de partido no gana (pero la historia sigue)
			return { Won = false, Score = goals, Against = math.max(against, goals + 1), Detail = { Draw = false, Real = true, Abandoned = true } }
		end
		return { Won = goals > against, Score = goals, Against = against, Detail = { Draw = goals == against, Real = true } }
	end
	local hits = math.max(0, math.floor(tonumber(o.Hits) or 0))
	local need = spec.Need or 1
	return { Won = not abandoned and hits >= need, Score = hits, Detail = { Real = true, Taken = o.Taken, Abandoned = abandoned == true } }
end

return FootballStory
