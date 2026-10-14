-- UiAudio: los sonidos de la interfaz (moverse por el menú, aceptar, volver, abrir, error).
-- Usan sonidos que ya trae Roblox con otro tono; se pueden cambiar por sonidos propios poniendo un
-- Sound con el mismo nombre en ReplicatedStorage > Sonidos (MenuMover, MenuOk, MenuAtras, MenuAbrir).

local SoundFx = require(script.Parent.Parent.Controllers.SoundFx)

local UiAudio = {}

local last = 0

function UiAudio.move()
	-- (sin ametrallar si se mantiene pulsado)
	if os.clock() - last < 0.04 then
		return
	end
	last = os.clock()
	SoundFx.play("MenuMover")
end

function UiAudio.confirm()
	SoundFx.play("MenuOk")
end

function UiAudio.cancel()
	SoundFx.play("MenuAtras")
end

function UiAudio.open()
	SoundFx.play("MenuAbrir")
end

function UiAudio.error()
	SoundFx.play("Error")
end

return UiAudio
