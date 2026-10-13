-- Boot: el arranque del servidor paso a paso, sin que un paso pueda dejar a los demás sin arrancar.
--
-- Por qué existe (v107/v108, móvil): el dueño entraba y veía «Nv. 1 · 0 € · Lunes, 1 de enero · Día 1»,
-- el reloj parado en las 8:00, la barra rápida vacía y sin misiones: los valores por defecto del
-- cliente antes de que el servidor le mande nada. Main.server.luau arrancaba ~100 servicios uno detrás
-- de otro con un pcall cada uno, pero:
--   * un pcall NO protege de un paso que se queda esperando (un WaitForChild sin tiempo, un *Async que
--     no vuelve, un bucle): todos los servicios de detrás (el reloj, el nivel, la mochila, la historia)
--     no arrancaban NUNCA en ese servidor, y el jugador se quedaba con los valores por defecto;
--   * los pasos del mundo de antes de los servicios (terreno, tráfico…) no tenían pcall: un error ahí
--     paraba el script entero;
--   * todo iba seguido sin soltar el hilo (cientos de miles de piezas): mientras tanto no corría nada
--     más del servidor (ni el reloj, ni la carga de las partidas de los que ya habían entrado).
-- Ahora cada paso corre en su propio hilo con pcall; si tarda más de su tiempo máximo se sigue con el
-- siguiente (el paso lento sigue en su hilo y termina cuando pueda); entre pasos se suelta el hilo, y al
-- final el servidor dice que está listo (atributo ServerReady de workspace), que es lo que espera la
-- pantalla de carga del cliente (UI/LoadingGate).

local Boot = {}

Boot.StepTimeout = 20 -- segundos máx. que se espera a un paso antes de seguir con el siguiente
Boot.YieldEvery = 0.05 -- se suelta el hilo si un paso (o varios seguidos) pasa de esto

export type StepResult = { Name: string, Ok: boolean, Error: string?, Seconds: number, TimedOut: boolean }

Boot.results = {} :: { StepResult }
Boot.errors = 0
Boot.timeouts = 0

local lastYield = os.clock()

local function setAttr(key: string, value: any)
	pcall(function()
		workspace:SetAttribute(key, value)
	end)
end

-- Ejecuta un paso del arranque. Nunca lanza error y nunca espera más de `timeout` segundos.
-- Devuelve true si el paso terminó sin error (y a tiempo).
function Boot.step(name: string, fn: () -> (), timeout: number?): boolean
	local limit = timeout or Boot.StepTimeout
	local started = os.clock()
	local done, ok, err = false, false, nil :: any
	setAttr("ServerBootStep", name)
	task.spawn(function()
		ok, err = pcall(fn)
		done = true
	end)
	while not done and os.clock() - started < limit do
		task.wait()
	end
	local seconds = os.clock() - started
	local result: StepResult = { Name = name, Ok = done and ok, Error = if done and not ok then tostring(err) else nil, Seconds = seconds, TimedOut = not done }
	table.insert(Boot.results, result)
	if not done then
		Boot.timeouts += 1
		warn(("[Main] %s sigue sin terminar tras %.0f s: se sigue arrancando lo demás (él seguirá en su hilo)"):format(name, seconds))
	elseif not ok then
		Boot.errors += 1
		warn(("[Main] Error iniciando %s: %s"):format(name, tostring(err)))
	end
	-- Soltar el hilo de vez en cuando: el reloj, la carga de partidas y la red siguen mientras arranca
	if os.clock() - lastYield >= Boot.YieldEvery then
		task.wait()
		lastYield = os.clock()
	end
	return done and ok
end

-- El servidor ha terminado de arrancar (con o sin errores): lo ve el cliente (UI/LoadingGate)
function Boot.ready()
	setAttr("ServerBootStep", nil)
	setAttr("ServerBootErrors", Boot.errors + Boot.timeouts)
	setAttr("ServerReady", true)
end

return Boot
