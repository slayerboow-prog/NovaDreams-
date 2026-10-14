-- devolver-dinero: devuelve UNA vez 515 € en total a la partida de «Sibuastian» (usuario 8103097978)
--
-- ESCRIBE en el DataStore de verdad, con UpdateAsync (nunca SetAsync). Es de un solo uso: 330 € que le quitó
-- una deuda de alquiler que un niño no debía tener, 10 € de paga que se fueron a esa deuda y 175 € del
-- alquiler del 1.º D que pagó de niño (docs/diagnostico-v95.md, «Partida de Sibuastian: el dinero a 0 €» y
-- «Devolución de 330 €»). Es idempotente: Housing.MinorFix.Refund guarda lo ya devuelto y solo se suma lo
-- que falte hasta REFUND; así que volver a correrlo no devuelve dos veces.
-- No escribe si la partida está en uso (SessionLock, con la misma regla que DataService) ni si la
-- limpieza de menores de la v111 (Housing.MinorFix) aún no se ha hecho.
--
-- Uso: bash scripts/cloud-test.sh -v devolver-dinero

local Cloud = Cloud :: any

local DataStoreService = game:GetService("DataStoreService")
local Config = require(Cloud.Shared.Config)

local USER_ID = 8103097978
local REFUND = 515 -- total: 330 + 10 + 175
local LOCK_TIMEOUT = Config.AutosaveSeconds * 3 -- la misma regla que DataService

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local before, after, why = nil, nil, nil

local ok, err = pcall(function()
	store:UpdateAsync("Player_" .. USER_ID, function(data)
		before, after, why = nil, nil, nil -- UpdateAsync puede llamar a esto más de una vez
		if type(data) ~= "table" then
			why = "no hay partida guardada"
			return nil
		end
		before = data.Money
		local lock = data.SessionLock
		if type(lock) == "table" and os.time() - (lock.Time or 0) < LOCK_TIMEOUT then
			why = ("partida en uso (SessionLock de hace %d s)"):format(os.time() - (lock.Time or 0))
			return nil
		end
		local housing = data.Housing
		if type(housing) ~= "table" or type(housing.MinorFix) ~= "table" then
			why = "la limpieza de menores (Housing.MinorFix) aún no se ha hecho"
			return nil
		end
		local done = tonumber(housing.MinorFix.Refund) or 0
		if done >= REFUND then
			why = ("ya devuelto antes (Housing.MinorFix.Refund = %d)"):format(done)
			return nil
		end
		if type(data.Money) ~= "number" then
			why = "Money no es un número: " .. tostring(data.Money)
			return nil
		end
		data.Money += REFUND - done
		housing.MinorFix.Refund = REFUND
		after = data.Money
		return data
	end)
end)

if not ok then
	Cloud.check("Devolver dinero a " .. USER_ID, false, "UpdateAsync: " .. tostring(err))
elseif after then
	Cloud.check("Devolver dinero a " .. USER_ID, true, ("Money antes=%s después=%s"):format(tostring(before), tostring(after)))
else
	Cloud.check("Devolver dinero a " .. USER_ID, why and string.find(why, "ya devuelto") ~= nil, ("no se ha escrito nada: %s (Money=%s)"):format(tostring(why), tostring(before)))
end
return Cloud.resultado()
