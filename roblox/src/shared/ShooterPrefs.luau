-- ShooterPrefs: los ajustes de disparar a pie (menú ⚙️ / MENÚ), que se guardan con la partida
-- (Services/SettingsService: data.Shooter) y llegan al entrar en los atributos del jugador.
--
--   Assist   «🎯 Ayuda al apuntar»: Auto (en el móvil y el mando sí, con ratón casi nada), Si o No
--   AutoFire «🔫 Disparo automático»: en el móvil, dispara solo con la mira encima de un enemigo
--   Numbers  «🔢 Números de daño»: los números que saltan al acertar
--
-- Cuentas puras (scripts/test-shooter).

local ShooterPrefs = {}

ShooterPrefs.Keys = { "Assist", "AutoFire", "Numbers" }
ShooterPrefs.Defaults = { Assist = "Auto", AutoFire = true, Numbers = true }
ShooterPrefs.AssistValues = { "Auto", "Si", "No" }
ShooterPrefs.Attributes = { Assist = "ShooterAssist", AutoFire = "ShooterAutoFire", Numbers = "ShooterNumbers" }

function ShooterPrefs.valid(key: any, value: any): boolean
	if key == "Assist" then
		return table.find(ShooterPrefs.AssistValues, value) ~= nil
	elseif key == "AutoFire" or key == "Numbers" then
		return type(value) == "boolean"
	end
	return false
end

-- Lo guardado, limpio (lo que falte o no valga: el de por defecto)
function ShooterPrefs.sanitize(raw: any): { Assist: string, AutoFire: boolean, Numbers: boolean }
	local out = table.clone(ShooterPrefs.Defaults)
	if type(raw) == "table" then
		for _, key in ShooterPrefs.Keys do
			if ShooterPrefs.valid(key, raw[key]) then
				out[key] = raw[key]
			end
		end
	end
	return out :: any
end

-- El siguiente valor al tocar el botón del menú
function ShooterPrefs.next(key: string, value: any): any
	if key == "Assist" then
		local i = table.find(ShooterPrefs.AssistValues, value) or 1
		return ShooterPrefs.AssistValues[i % #ShooterPrefs.AssistValues + 1]
	end
	return not (value == true)
end

-- ¿Está la ayuda puesta para este perfil de AimAssist (Touch, Gamepad, Mouse)?
function ShooterPrefs.assistOn(value: any, profile: string): boolean
	if value == "No" then
		return false
	elseif value == "Si" then
		return true
	end
	return profile ~= "Mouse" -- Auto: móvil y mando sí; ratón con lo mínimo (el imán de la bala, pequeño)
end

function ShooterPrefs.label(key: string, value: any): string
	if key == "Assist" then
		return "🎯 Ayuda al apuntar: " .. (if value == "Si" then "Sí" elseif value == "No" then "No" else "Auto")
	elseif key == "AutoFire" then
		return "🔫 Disparo automático (móvil): " .. (if value == false then "No" else "Sí")
	end
	return "🔢 Números de daño: " .. (if value == false then "No" else "Sí")
end

return ShooterPrefs
