# DialogueUI: cámara, controles, voz y gestos

> **HECHO (29-09-2026).** DialogueUI ya usa `Controls` («Dialogo»), `CineCamera.clampCFrame` (y planos
> ×0,7 dentro de edificios), `CineCamera.restore` (salvo con una escena en marcha), no mueve la cámara
> durante una escena y la recupera al acabar, corta la voz en cada frase y al cerrar, esconde nombres
> e iconos (`quietLabels`), acepta toques en el móvil, pasa `line.Gesture` a `ActorLife.speak` y se
> cierra también con `CharacterRemoving`. El servidor ya cancela al morir. `Validate` comprueba `G`.
> Lo de abajo queda como referencia.

# (Antes) Pendiente en DialogueUI

`DialogueUI.luau` lo está reescribiendo otra sesión, así que estos arreglos **no** se han metido en
él. Los módulos ya están listos; solo falta llamarlos desde DialogueUI (y una línea en el servidor).
Hay un parche de referencia con la versión completa en `DialogueUI-propuesta.patch` (junto a este
documento).

## Módulos nuevos

- `client/Controllers/Controls.luau`: quitar y devolver el control del personaje contando quién lo
  pide (`Controls.disable(motivo)`, `Controls.enable(motivo)`, `Controls.isDisabled()`). Lo usan ya
  las cinemáticas; si DialogueUI sigue llamando a PlayerModule directamente, una cinemática que acabe
  con un diálogo abierto devuelve el control a mitad de conversación.
- `client/Controllers/CineCamera.luau`:
  - `CineCamera.clamp(foco, deseado)`: la cámara no atraviesa paredes (se para 0,5 antes).
  - `CineCamera.restore(cframeGuardado)`: vuelve a donde estaba (o detrás del jugador) y pone Custom.
  - `CineCamera.inInterior()` y `CineCamera.InteriorRadius` (5): planos más cortos dentro de edificios.
  - `CineCamera.quietLabels(motivo, on)`: esconde nombres e iconos flotantes (no los bocadillos).
- `StoryAudio.stopVoice()`: corta la voz que esté sonando.
- `ActorLife.speak(modelo, emocion, segundos, gesto)`: 4.º argumento opcional con el gesto de la
  frase (`line.Gesture`, que ya manda `DialogueService.lineFor` a partir de `G` en los datos).
  También `ActorLife.gesture(modelo, "Clap")`. Gestos nuevos: ArmsCrossed, HandsOnHips, Facepalm,
  Clap, ThinkChin, WaveLite.

## Qué debe hacer DialogueUI

1. `Controls.disable("Dialogo")` al abrir y `Controls.enable("Dialogo")` al cerrar.
2. Cierre seguro: una bandera `closing` que corte la escritura, la espera de la siguiente frase, la
   espera de respuesta y la cola, sin mandar `Next` al servidor. Se activa con el "Close" del
   servidor, con `Humanoid.Died` y con `CharacterRemoving`.
3. Al cerrar: `CineCamera.restore(guardado.CFrame)`, salvo que `Cinematics.isPlaying()` (entonces la
   restaura la cinemática al acabar).
4. En el bucle de cámara: no escribir mientras `Cinematics.isPlaying()`; después volver a Scriptable.
5. En `frame()`: pasar cada posición por `CineCamera.clamp`. Primer plano a
   `math.min(3.6, distancia * 0.55)` del que habla. Dentro de edificios, desplazamientos × 0,7 y plano
   de dos como mucho a `CineCamera.InteriorRadius`.
6. `StoryAudio.stopVoice()` al empezar cada frase, al pasarla y al cerrar.
7. `CineCamera.quietLabels("Dialogo", abierto)` en `setOpen`.
8. «Toca para seguir»: aceptar también `Enum.UserInputType.Touch` si no lo ha usado un botón.
9. En `showLine`: `ActorLife.speak(modelo, line.Emotion, duracion, line.Gesture)`.

## Servidor

- Llamar a `DialogueService.cancel(player)` al morir (`Humanoid.Died`) o al quitarse el personaje;
  si no, el tiempo de espera del servidor sigue respondiendo y el diálogo vuelve a salir al
  reaparecer.
- `Effects.Gesture` de una frase se aplica al juntar el trozo (`DialogueService.pump`), antes de que
  se vea la frase: mejor usar `G` en la propia frase.
- `Validate.luau` aún no comprueba `G` (un gesto mal escrito se ignora sin avisar).
