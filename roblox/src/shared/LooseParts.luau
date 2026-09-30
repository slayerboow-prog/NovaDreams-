-- LooseParts: qué pieza suelta (sin anclar y sin soldar a nada fijo) se retira del mundo y cuándo
-- (cuentas puras, se prueban fuera de Roblox: scripts/test-props.luau). Lo usa SweepService.
--
-- Solo cuenta lo que se crea durante la partida (el mapa viene anclado: scripts/test-props.luau lo
-- comprueba). Un trozo que se ha soltado y se queda en el suelo (en la calle, en un cruce…) se quita
-- pasado un rato quieto; lo que tiene dueño (personas, vehículos enteros, juguetes, puertas que se
-- arreglan solas) no se toca nunca.

local LooseParts = {}

LooseParts.RestSeconds = 40 -- quieta en el suelo este rato: se retira
LooseParts.MaxSeconds = 180 -- suelta este rato (aunque se siga moviendo, p. ej. rodando en una cuesta): se retira
LooseParts.VoidY = -300 -- por debajo de esto se ha caído del mapa: se retira ya
LooseParts.RestSpeed = 1 -- studs/s: más despacio que esto cuenta como quieta

export type Info = {
	Anchored: boolean, -- la pieza (o su conjunto) está anclada
	Grounded: boolean, -- soldada a algo anclado
	Person: boolean, -- es de un personaje (jugador o NPC: tiene Humanoid)
	Vehicle: boolean, -- sigue unida a la base de un vehículo (Chassis)
	Keep: boolean, -- marcada para quedarse (atributo KeepLoose, etiqueta Toy…)
	Speed: number,
	Y: number,
}

-- ¿Tiene dueño (no se toca)?
function LooseParts.owned(info: Info): boolean
	return info.Anchored or info.Grounded or info.Person or info.Vehicle or info.Keep
end

-- Qué hacer con ella: "Keep" (no es basura), "Wait" (suelta: se sigue mirando) o "Sweep" (se quita).
-- restFor: segundos que lleva quieta; looseFor: segundos que lleva suelta.
function LooseParts.verdict(info: Info, restFor: number, looseFor: number): string
	if LooseParts.owned(info) then
		return "Keep"
	end
	if info.Y < LooseParts.VoidY then
		return "Sweep"
	end
	if restFor >= LooseParts.RestSeconds or looseFor >= LooseParts.MaxSeconds then
		return "Sweep"
	end
	return "Wait"
end

-- Tiempo quieta después de un vistazo que llega `dt` segundos después del anterior
function LooseParts.rest(previous: number, speed: number, dt: number): number
	return if speed < LooseParts.RestSpeed then previous + dt else 0
end

return LooseParts
