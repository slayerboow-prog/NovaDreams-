-- CombatAI: cómo pelea un rival controlado por el servidor (Services/FighterService), con las mismas
-- reglas que un jugador (shared/Combat): combos de ligeros con su final, guardia, voltereta,
-- desvanecerse con aguante, contraataque después de defenderse y golpe cargado contra quien se
-- cubre mucho. Tres niveles (Facil, Normal, Dificil): reflejos, cuánto se defiende, esquiva y
-- contraataca, lo largos que son sus combos y su vida.
--
-- CombatAI.decide(vista, nivel, azar) -> acción. Es una función pura (el azar se pasa como función):
-- scripts/test-combos.luau la prueba sin Roblox.
--
-- Acciones: "Wait", "Approach", "Retreat", "Strafe", "Light", "Heavy", "Charged", "Block",
-- "Unblock", "Roll", "Vanish".

local Combat = require(script.Parent.Combat)

local CombatAI = {}

export type Level = {
	Name: string,
	React: number, -- segundos que tarda en reaccionar a un golpe que viene
	Block: number, -- probabilidad de cubrirse cuando le atacan
	Dodge: number, -- …de rodar
	Vanish: number, -- …de desvanecerse (si tiene aguante)
	Counter: number, -- …de contraatacar después de cubrirse
	ComboMin: number,
	ComboMax: number,
	Finisher: number, -- …de rematar el combo con el fuerte
	Charge: number, -- …de cargar el golpe contra alguien que se cubre mucho
	Speed: number, -- al andar
	Health: number,
	DamageMul: number,
	Range: number, -- a qué distancia empieza a pegar
}

CombatAI.Levels = {
	Facil = { Name = "Fácil", React = 0.6, Block = 0.2, Dodge = 0.05, Vanish = 0, Counter = 0.1, ComboMin = 1, ComboMax = 3, Finisher = 0.3, Charge = 0, Speed = 11, Health = 80, DamageMul = 0.6, Range = 5 },
	Normal = { Name = "Normal", React = 0.35, Block = 0.4, Dodge = 0.12, Vanish = 0.15, Counter = 0.35, ComboMin = 2, ComboMax = 5, Finisher = 0.6, Charge = 0.2, Speed = 14, Health = 120, DamageMul = 0.85, Range = 5 },
	Dificil = { Name = "Difícil", React = 0.18, Block = 0.55, Dodge = 0.15, Vanish = 0.3, Counter = 0.65, ComboMin = 3, ComboMax = 6, Finisher = 0.85, Charge = 0.4, Speed = 16, Health = 170, DamageMul = 1, Range = 5.5 },
} :: { [string]: Level }

function CombatAI.level(name: any): Level
	return CombatAI.Levels[name] or CombatAI.Levels.Normal
end

export type View = {
	Distance: number, -- al rival
	CanAct: boolean, -- no está aturdido, derribado ni pegando
	Ready: boolean, -- puede dar otro golpe (pasó la pausa del anterior)
	TargetAttacking: boolean, -- el rival acaba de lanzar un golpe
	TargetAttackAge: number, -- hace cuánto (segundos)
	TargetBlocking: boolean,
	TargetBlockingFor: number, -- segundos cubriéndose
	TargetDown: boolean, -- el rival está en el suelo (no se le pega)
	TargetAir: boolean?, -- el rival está en el aire (después de nuestro lanzador)
	Blocking: boolean, -- yo me estoy cubriendo
	JustBlocked: boolean, -- acabo de parar un golpe
	Stamina: number,
	ComboStep: number, -- ligeros ya dados en este combo
	ComboWant: number, -- cuántos quiere dar antes del final
	Health: number, -- 0..1
}

-- ¿Qué hace ahora? roll() da un número de 0 a 1 (math.random o uno fijo en las pruebas)
function CombatAI.decide(view: View, level: Level, roll: () -> number): string
	if not view.CanAct then
		return "Wait"
	end
	-- Le van a pegar: cubrirse, rodar o desvanecerse (si le da tiempo a reaccionar)
	if view.TargetAttacking and view.Distance <= level.Range + 3 and view.TargetAttackAge >= level.React * 0.5 then
		local r = roll()
		if r < level.Vanish and view.Stamina >= Combat.VanishCost then
			return "Vanish"
		end
		r -= level.Vanish
		if r < level.Block then
			return "Block"
		end
		r -= level.Block
		if r < level.Dodge then
			return "Roll"
		end
	end
	-- Ha parado un golpe: contraataca (o sigue cubierto)
	if view.Blocking then
		if view.JustBlocked and roll() < level.Counter then
			return "Light"
		end
		if not view.TargetAttacking or view.TargetAttackAge > 0.6 then
			return "Unblock"
		end
		return "Block"
	end
	if view.TargetDown then
		-- No se pega a quien está en el suelo: espera a que se levante (a un paso)
		return if view.Distance > level.Range + 2 then "Approach" else "Wait"
	end
	if view.Distance > level.Range then
		-- Con poca vida, a veces se aleja a recuperar aire
		if view.Health < 0.25 and view.Distance < level.Range + 4 and roll() < 0.3 then
			return "Retreat"
		end
		return "Approach"
	end
	if not view.Ready then
		return "Wait"
	end
	-- Pegado a alguien que se cubre mucho: golpe cargado (rompe la guardia)
	if view.TargetBlocking and view.TargetBlockingFor > 0.8 and roll() < level.Charge * 2 then
		return "Charged"
	end
	if view.TargetAir then
		return if view.ComboStep >= 2 then "Heavy" else "Light"
	end
	if view.ComboStep < view.ComboWant then
		return "Light"
	end
	if roll() < level.Finisher then
		return "Heavy"
	end
	return if roll() < 0.5 then "Strafe" else "Retreat"
end

-- Cuántos ligeros quiere dar en el próximo combo
function CombatAI.comboLength(level: Level, roll: () -> number): number
	return level.ComboMin + math.floor(roll() * (level.ComboMax - level.ComboMin + 0.999))
end

return CombatAI
