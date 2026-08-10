# Rolemaster

Rolemaster es un **asistente digital multiplataforma para el Director de Juego** de partidas presenciales de rol.

No busca reemplazar la mesa tradicional ni convertirse en un VTT multiusuario para jugadores. Su objetivo es asistir al GM durante la preparación y la sesión mediante gestión de campaña, mundo persistente, personajes, NPC, reglas, calendario, eventos, mapas, combate, audio, voz e inteligencia artificial opcional.

## Principios del proyecto

1. **Mesa presencial primero**: la interacción principal con los jugadores sigue siendo directa, física y por voz.
2. **Herramienta del GM**: Rolemaster está centrado en el Director de Juego; los jugadores no necesitan una cuenta, cliente o dispositivo propio.
3. **Multiplataforma**: la experiencia del GM debe adaptarse a escritorio, tablet y teléfono móvil.
4. **Local-first y offline**: las funciones esenciales de campaña deben funcionar sin Internet.
5. **Independiente por diseño**: Rolemaster no depende de Fantasy Grounds ni de otro VTT.
6. **Referencias, no dependencias**: otros VTT pueden servir como referencia de arquitectura, diagramación y experiencia visual.
7. **Core sin IA obligatoria**: todas las funciones esenciales deben funcionar con la IA desactivada.
8. **IA intercambiable**: la IA integrada será la opción por defecto, pero el usuario podrá usar proveedores propios, modelos locales o desactivarla.
9. **Arquitectura modular**: campaña, mundo, reglas, personajes, NPC, combate, calendario, eventos, audio, voz e IA deben mantenerse desacoplados.
10. **Fuente de verdad propia**: los datos de campaña y estado del mundo pertenecen a Rolemaster.

## Modelo de uso

Rolemaster puede utilizarse desde una PC, notebook, tablet o teléfono del GM. En una sesión, varios dispositivos del propio GM podrán actuar como vistas o controles complementarios sobre la misma campaña local.

También se contempla una **pantalla secundaria opcional** para mostrar a la mesa únicamente el contenido que el GM decida revelar: mapas, imágenes, handouts, iniciativa u otra información pública.

## Estado

Proyecto iniciado el 10 de agosto de 2026.

La primera etapa define arquitectura, persistencia, eventos y stack tecnológico antes de implementar lógica específica del juego.

## Documentación

- `docs/ARCHITECTURE.md`: arquitectura inicial y límites del sistema.
- `docs/ROADMAP.md`: etapas iniciales de desarrollo.
