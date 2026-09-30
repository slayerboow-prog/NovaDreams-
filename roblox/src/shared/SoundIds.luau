-- SoundIds: GENERADO por scripts/upload-audio.sh (no editar a mano).
-- Nombre del archivo de audio (sin .ogg) -> audio subido a Roblox ("rbxassetid://…").
-- Efectos (audio/sfx: motor, lluvia…) y, si se subió con --music, la música (tema_valmar…).
-- SoundFx, Weather y StoryAudio lo miran cuando el Id de Config es 0. Si falta un nombre, se busca
-- un Sound con ese nombre en ReplicatedStorage > Sonidos (o > Musica para la música).
return {
	claxon = "rbxassetid://133145598956621",
	lluvia = "rbxassetid://87569090674146",
	metro_anden = "rbxassetid://135876824598541",
	metro_freno = "rbxassetid://85680495035860",
	metro_tren = "rbxassetid://124891700963147",
	motor = "rbxassetid://80027964764330",
	multitud = "rbxassetid://89206333222827",
	pajaros = "rbxassetid://121133670050746",
	tele = "rbxassetid://90694844300808",
	timbre = "rbxassetid://125399114456388",
	trueno = "rbxassetid://92156170627266",
	viento = "rbxassetid://109667366560792",
} :: { [string]: string }
