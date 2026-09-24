# Fase 12 — Multijugador, vida social y familias

## 12.1 Tamaño de servidor

- Un servidor de Roblox tiene un **máximo de jugadores** que se configura. En la práctica, con un mapa grande, NPCs y vehículos, recomendamos **30–40 jugadores por servidor** al lanzar y subir según las mediciones de rendimiento.
- **"Miles de jugadores" = miles repartidos en muchos servidores de la misma región**, compartiendo economía, mercado, noticias, bolsa, rankings, familias y mensajería. Así es como funcionan todos los grandes juegos de Roblox.

## 12.2 Qué es local y qué es global

| Local (cada servidor) | Global (todos los servidores) |
|---|---|
| Posiciones, NPCs, tráfico, clima exacto, emergencias | Perfiles, propiedades, vehículos, dinero |
| Negocios **abiertos** en ese servidor | Registro de negocios, sus cuentas y reputación |
| Chat de proximidad | Mensajes del teléfono entre amigos y familia |
| Eventos pequeños | Grandes eventos programados (festival de la región), noticias |
| — | Mercado inmobiliario, bolsa, anuncios de empleo entre jugadores |

Mecanismos: DataStore (verdad), MemoryStore (vivo y rápido) y MessagingService (avisos en tiempo real). Ver Fase 4.

## 12.3 Encontrarse con otros

- **Unirse a amigos y familia:** desde el teléfono ("Ir con mamá") se hace un teletransporte al servidor de ese jugador (`TeleportToPlaceInstance`) si hay hueco.
- **Registro de servidores** en MemoryStore: jugadores, eventos activos y negocios abiertos. Permite un "explorador de servidores" (por ejemplo, "servidor con más médicos" o "servidor con el festival").
- **Servidores privados** (de pago en Robux, ver Monetización) para familias y grupos de rol.

## 12.4 Relaciones

| Tipo | Cómo se crea | Qué aporta |
|---|---|---|
| Conocido → amigo → mejor amigo | Tiempo juntos, actividades compartidas, regalos | Contactos del teléfono, bonus de ánimo al estar juntos, invitaciones |
| Compañeros | Misma clase o trabajo | Bonus de trabajo en equipo |
| Pareja | **Rol dentro de un hogar** (ver 12.5) | Casa compartida, economía común opcional |
| Familia | Hogar | Ver abajo |

**Normas de Roblox (muy importante):** Roblox prohíbe experiencias diseñadas para citas o romance entre usuarios. Por eso:
- **No habrá** "ligar", puntos de romance entre jugadores, aplicaciones de citas ni contenido romántico.
- "Pareja" y "matrimonio" existen solo como **roles de un hogar** que dos jugadores aceptan (igual que "padre" o "hermano"), para el rol familiar y la economía compartida.
- Antes de implementar esta parte se revisarán las normas vigentes y el cuestionario de madurez de la experiencia. Si Roblox lo restringe, se ajusta el diseño (por ejemplo, solo "compañeros de piso" y familia).

## 12.5 Hogares y familias

Un **Hogar** es un registro global (`Household_v1`):

```lua
Household = {
	Id = "h_...", Name = "Familia García",
	Members = { { CharacterId, Role = "Padre" | "Madre" | "Pareja" | "Hijo" | "Hermano" | "Abuelo" | "CompañeroPiso" } },
	HomeProperty = "p_...", SharedAccount = "acc_...",   -- opcional
	FamilyTree = "lin_...",
}
```

- **Crear un hogar e invitar:** con aceptación explícita de ambos jugadores.
- **Tener hijos:** un hijo es un **nuevo personaje** que entra en la familia.
  - Puede ser **un jugador** que acepta una invitación de "adopción o nacimiento" y empieza como bebé en esa familia (el mismo modelo que el rol familiar de Brookhaven, pero persistente y con progresión real).
  - Puede ser **un NPC hijo** que crece con la familia. Más adelante, uno de los propios padres puede **tomar el control** de ese hijo como su siguiente personaje (generaciones).
- **Familiares desconectados:** aparecen en casa como NPC (con su apariencia) haciendo actividades sencillas. Así la casa no se siente vacía.
- **Cuidado de bebés y niños:** si el bebé es un jugador, los adultos del hogar tienen acciones de cuidado (dar de comer, bañar, dormir). Si no hay adultos conectados, un NPC "canguro" cubre las necesidades básicas. El bebé nunca se queda bloqueado.

## 12.6 Generaciones y legado

- Cada jugador tiene **linajes** (árboles familiares). Una cuenta puede tener varios personajes (huecos) dentro de uno o varios linajes.
- **Legado:** cuando un personaje mayor cierra su vida (voluntariamente, o en modo realista por edad), el jugador elige un **heredero**: un hijo NPC que pasa a controlar, un hijo jugador o un nuevo nacimiento en su linaje.
- **Herencia:** propiedades, dinero (con impuesto de sucesiones, sumidero de la economía), negocios y objetos de reliquia. Las habilidades del padre dan una pequeña ventaja inicial al heredero.
- **Árbol genealógico** visible en la app Familia, con logros de linaje ("5 generaciones", "tres médicos en la familia").

## 12.7 Seguridad entre jugadores

- Chat según la configuración y los filtros de Roblox (`TextService` obligatorio en todo texto escrito por jugadores: nombres de negocios, mensajes, carteles).
- Bloquear y denunciar desde el teléfono. Las casas tienen permisos (quién puede entrar).
- Nada de PvP ni violencia entre jugadores en el lanzamiento.
- Acciones sensibles (transferencias, invitaciones a hogar, contratos) siempre con confirmación explícita.
