# Rolemaster

Rolemaster es un asistente digital multiplataforma para el Director de Juego de una mesa presencial tradicional. Gestiona campañas, mundo persistente, personajes, NPC, reglas, calendario, eventos y herramientas de sesión, con capacidades opcionales de IA, voz y audio.

## Principios del proyecto

1. **Independiente por diseño**: Rolemaster no depende de Fantasy Grounds ni de otro VTT.
2. **Referencias, no dependencias**: Fantasy Grounds Unity y otros VTT pueden servir como referencia de arquitectura, diagramación y experiencia visual.
3. **Mesa presencial primero**: los jugadores interactúan de forma directa o por voz; Rolemaster asiste al GM y no reemplaza la dinámica física de la mesa.
4. **Multiplataforma**: la interfaz debe adaptarse a escritorio, tablet y móvil.
5. **Local-first**: campaña, reglas y funciones esenciales deben seguir operativas sin Internet.
6. **Core sin IA obligatoria**: todas las funciones esenciales deben funcionar con la IA desactivada.
7. **IA intercambiable**: la IA integrada será la opción por defecto, pero el usuario podrá usar proveedores propios, modelos locales o desactivarla.
8. **Arquitectura modular**: campaña, mundo, reglas, personajes, NPC, combate, calendario, eventos, voz, audio e IA deben mantenerse desacoplados.
9. **Fuente de verdad propia**: los datos de campaña y estado del mundo pertenecen a Rolemaster.
10. **GM en control**: las automatizaciones y respuestas inteligentes deben poder previsualizarse, editarse, omitirse o reemplazarse manualmente.

## Alcance de interfaces

- **Escritorio**: workspace completo del GM.
- **Tablet**: interfaz táctil optimizada para dirigir la sesión.
- **Móvil**: vista contextual y controles rápidos para NPC, voz, tiradas y audio.
- **Pantalla secundaria opcional**: salida controlada por el GM para mapa, imágenes, handouts u otra información destinada a la mesa.

Los jugadores no necesitan una cuenta ni un cliente Rolemaster para participar.

## Estado

Proyecto iniciado el 10 de agosto de 2026.

**Activo: Fase 6 — Hardening y Backend/Core Freeze.** La Fase 7 gráfica
definitiva comienza cuando se cierren los bloqueos del Freeze.

El proyecto ya dispone de:

- Core Dart independiente de Flutter.
- GitHub Actions para validar Core, almacenamiento SQLite y app Flutter.
- campañas, mundo, calendario, eventos, personajes, NPC, objetos, mapas y encuentros.
- motor de reglas y combate extensible, con Rulesets versionados y migración controlada.
- persistencia SQLite con esquema versionado v17, snapshots, restore y rollback.
- Visual Alpha responsive y build web de prueba; usa repositorios en memoria.
- compilaciones Windows y Android en CI.

La posición exacta, los bloqueos y el siguiente sprint están en
`docs/CHECKLIST_MASTER.md` y `docs/BACKEND_CORE_AUDIT.md`.

## CI

El workflow `.github/workflows/ci.yml` ejecuta en cada push y pull request a `main`:

- `dart format`, `dart analyze --fatal-infos` y `dart test` para `rolemaster_core`.
- formato, análisis, tests y benchmark para `rolemaster_storage_sqlite`.
- análisis y tests de la app Flutter, más builds Windows y Android.

Un error de formato, análisis, test o warning tratado como fatal bloquea el job correspondiente.

## Documentación

- `docs/ARCHITECTURE.md`: arquitectura y límites del sistema.
- `docs/ROADMAP.md`: etapas generales de desarrollo.
- `docs/CHECKLIST_MASTER.md`: tablero operativo y posición actual del proyecto.
