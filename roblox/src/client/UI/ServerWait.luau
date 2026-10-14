-- ServerWait: esperar a lo que crea el servidor al arrancar (remotos, carpetas de datos), SIN rendirse
-- mientras el servidor sigue arrancando.
--
-- Por qué existe (v107/v108): muchos controladores esperaban su remoto o su carpeta 10, 30 o 60 s
-- (WaitForChild con tiempo) y, si no llegaba, se rendían para toda la partida. Un servidor recién
-- abierto (versión nueva publicada: todos pasan a uno nuevo) con la ciudad entera tarda más que eso
-- en arrancar todos sus servicios: te quedabas sin mapa, sin combate, sin escenas de la historia…
-- Ahora se espera hasta que el servidor diga que ha terminado de arrancar (atributo ServerReady de
-- workspace, lo pone Main.server.luau) y, desde entonces, un margen; solo si para entonces no está
-- (su servicio falló) se devuelve nil.

local ServerWait = {}

ServerWait.GRACE = 20 -- s que se sigue esperando cuando el servidor ya está listo
ServerWait.POLL = 0.5

function ServerWait.isReady(): boolean
	return workspace:GetAttribute("ServerReady") == true
end

-- Espera (lo que haga falta) a que el servidor termine de arrancar
function ServerWait.ready()
	while not ServerWait.isReady() do
		task.wait(ServerWait.POLL)
	end
end

-- El hijo `name` de `parent`: espera mientras el servidor arranca; nil solo si, ya listo el servidor,
-- pasan `grace` segundos sin que aparezca.
function ServerWait.child(parent: Instance?, name: string, grace: number?): any
	if not parent then
		return nil
	end
	local found = parent:FindFirstChild(name)
	local readySince: number? = nil
	while not found do
		task.wait(ServerWait.POLL)
		found = parent:FindFirstChild(name)
		if not found and ServerWait.isReady() then
			readySince = readySince or os.clock()
			if os.clock() - (readySince :: number) >= (grace or ServerWait.GRACE) then
				return nil
			end
		end
	end
	return found
end

-- ReplicatedStorage.Remotes[name]
function ServerWait.remote(name: string): any
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	return ServerWait.child(remotes, name)
end

return ServerWait
