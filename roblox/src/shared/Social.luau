-- Social: reglas del menú de jugador (SocialService y PlayerMenuUI).
--
-- Al tocar a otro jugador sale su menú: invitar al grupo, chat privado y comerciar.
--   * Grupo: hasta MaxGroup jugadores. Tenéis un chat de grupo y veis quién está en él.
--   * Chat privado: usa el chat de Roblox (TextChatService), que filtra los mensajes y respeta
--     los ajustes de chat de cada cuenta. Si Roblox no deja chatear a esos dos jugadores, no se abre.
--   * Comerciar: abre el intercambio (TradeService); los dos tienen que aceptar.

local Social = {}

Social.MaxGroup = 6
Social.InviteSeconds = 30
Social.MenuRange = 60 -- a qué distancia puedes tocar a alguien para abrir su menú
Social.History = 40 -- mensajes que se guardan en cada chat

-- Nombres de los canales de chat (TextChannel dentro de TextChatService)
Social.Folder = "ValmarChats"
Social.GroupPrefix = "Grupo_"
Social.PrivatePrefix = "Privado_"

function Social.privateChannel(a: number, b: number): string
	return ("%s%d_%d"):format(Social.PrivatePrefix, math.min(a, b), math.max(a, b))
end

function Social.groupChannel(id: number): string
	return Social.GroupPrefix .. tostring(id)
end

return Social
