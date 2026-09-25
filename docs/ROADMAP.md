# Roadmap inicial

## Fase 0 — Fundaciones

Objetivo: definir el producto antes de implementar lógica específica.

- [x] Crear repositorio e inicializar `main`
- [x] Definir principios de independencia y modularidad
- [x] Definir IA como capa opcional e intercambiable
- [x] Definir Rolemaster como asistente del GM para mesa presencial
- [x] Definir alcance multiplataforma: escritorio, tablet y móvil
- [x] Definir enfoque local-first y funcionamiento esencial offline
- [x] Descartar clientes obligatorios para jugadores
- [x] Prever pantalla secundaria opcional controlada por el GM
- [x] Elegir stack tecnológico: Dart + Flutter, local-first, SQLite
- [x] Crear ADR inicial de stack y reglas de dependencia
- [x] Separar `rolemaster_core` de la aplicación Flutter
- [x] Definir persistencia SQLite y migraciones secuenciales
- [x] Definir arquitectura de eventos append-only
- [x] Definir Ruleset Foundation versionada e inmutable
- [ ] Definir comunicación local opcional entre dispositivos del GM
- [ ] Definir estrategia de plugins/extensiones
- [ ] Generar y validar runners Windows/Android con toolchain Flutter real

## Fase 1 — Core de campaña

Estado: **completada**.

- [x] Campaign
- [x] World / regiones / localizaciones
- [x] Calendar / Time
- [x] Event Engine
- [x] State Manager con optimistic revisioning y CAS
- [x] Persistencia y snapshots
  - [x] esquema SQLite central versionado hasta v17
  - [x] migraciones secuenciales
  - [x] snapshots consistentes mediante SQLite backup
  - [x] validación de integridad y claves foráneas
  - [x] restauración segura
  - [x] snapshot automático pre-restore para rollback

## Fase 2 — Dominio de juego

Estado: **completada para el alcance previo a Rules Engine**.

- [x] Characters — SQLite v7
- [x] NPCs — SQLite v8
- [x] Creatures — SQLite v9
- [x] Ruleset Foundation — SQLite v10
- [x] Skills Foundation — SQLite v11
- [x] Inventory / Items — SQLite v12
- [x] Maps / Locations — SQLite v13
- [x] Encounters — SQLite v14
  - [x] Encounter pre-combate con estados planned / active / closed
  - [x] participantes genéricos y únicos
  - [x] contexto opcional World / Location / SceneMap
  - [x] derivación y validación del contexto de mapa
  - [x] persistencia transaccional del agregado
  - [x] migración v13→v14 preservando Maps
  - [x] fixtures históricos v5–v12 saneados
  - [x] CI Core + SQLite + Flutter verde

### Visual Alpha 0.1 — validación congelada por ahora

- [x] Primer manual real de prueba cargado
- [x] Clasificación provisional y módulos de prueba identificados
- [x] Ruleset de prueba controlado sin modificar paquete base
- [x] Campaña limpia ligada a esa versión
- [x] Shell GM responsive con datos reales
- [x] Tiradas y creación/reapertura de personaje probadas
- [x] Build web técnico y tester HTML autocontenido
- [ ] Renderer real, NPCs visuales detallados y design system diferidos

> La Visual Alpha fue suficiente para validar la dirección. Queda congelada mientras continúa el checklist técnico y no abre la fase gráfica definitiva.

## Fase 3 — Reglas y combate

Sprint activo: **Fase 3 — extensibilidad de reglas**. La migración 4.5C está completada.

La migración atómica del binding está implementada; todavía falta transformar datos persistidos que referencian IDs del Ruleset. Los servicios opcionales tienen contratos y proveedores desactivados. Ver `BACKEND_CORE_AUDIT.md`.

Los contratos de IA, NPC, STT/TTS y audio tienen proveedores desactivados. Las integraciones funcionales con proveedores siguen siendo optativas y quedan pendientes para después del freeze.

- [x] Effective Ruleset = paquete exacto + módulos activos + overlay
- [x] validación de binding/versión/módulos obligatorios
- [x] overrides de campaña sin mutar el paquete base
- [x] aislamiento entre campañas
- [x] Dice Kernel con RNG inyectable y resultados trazables
- [x] Resolution Engine data-driven por `ruleId` + intérpretes por `kind`
- [x] primer intérprete genérico `dice-threshold` configurado desde Ruleset
- [x] Tablas versionadas: catálogo inmutable y lookup integrado con Resolution Engine
- [x] Combat Core: Encounter activo, participantes verificados, turnos/rondas y acciones por Resolution Engine
- [x] Persistencia SQLite v15 y recuperación de combate con revisión optimista
- [x] Estadísticas de combate definidas por Ruleset y persistidas en SQLite v16
- [x] Conditions: catálogo, duración por rondas y SQLite v17
- [x] Effects: modificadores automáticos con traza (CI `36148253242`)
- [ ] Extensibilidad de reglas
- [x] Migración atómica de IDs de habilidades y definiciones de objetos con mapeos explícitos; pruebas SQLite cubren migración y rollback.
- [x] Preservar estadísticas, condiciones y acciones de combates cerrados como historial ligado a su versión exacta del Ruleset; no se reescriben al migrar la campaña.
- [x] Migración atómica del binding y auditoría de referencias persistidas (CI `36150283531`).

## Fase 4 — Interfaz multiplataforma

- [x] Base responsive/adaptativa compartida
- [x] UI técnica provisional: crear campaña + seleccionar ruleset/versión/módulos
- [x] Build web técnico automatizado como artefacto de GitHub Actions
- [x] Visual Alpha funcional con primer manual real
- [ ] Publicación directa de preview por GitHub Pages — pendiente habilitar Pages en el repositorio
- [ ] Workspace definitivo del GM en escritorio
- [ ] Layout táctil definitivo para tablet
- [ ] Vista contextual definitiva para móvil
- [ ] Fichas
- [ ] Mapa / escena
- [ ] Panel contextual
- [ ] Voz / tiradas / eventos / audio
- [ ] Pantalla secundaria opcional para la mesa

> La UI técnica provisional es una herramienta de validación y no abre la fase gráfica definitiva. La puerta sigue siendo el Backend/Core Freeze.

## Fase 5 — IA opcional

- [ ] AI service interface
- [ ] Disabled provider
- [ ] Built-in provider
- [ ] Custom API provider
- [ ] Local model provider
- [ ] Configuración por capacidad
- [ ] Memoria y comportamiento de NPC
- [ ] Idiomas y diálogo
- [ ] Controles de aprobación del GM

## Fase 6 — Voz

- [ ] Speech-to-Text
- [ ] Context routing
- [ ] Selección de NPC / función destinataria
- [ ] Text-to-Speech
- [ ] Idioma nativo del NPC
- [ ] Modo preview / edición antes de hablar
- [ ] Modo respuesta manual

## Fase 7 — Audio

- [ ] Audio Director
- [ ] Voz de NPC
- [ ] Música
- [ ] Ambiente
- [ ] SFX
- [ ] Eventos de audio sincronizados con el estado de campaña

## Fase 8 — Dispositivos del GM

- [ ] Descubrimiento en red local
- [ ] Sincronización entre dispositivos del mismo GM
- [ ] Tablet como vista/control complementario
- [ ] Móvil como control rápido de voz, NPC y audio
- [ ] Gestión segura de sesión local

## Criterio de desarrollo

Rolemaster debe seguir siendo plenamente útil como soporte de una mesa presencial aunque estén desactivadas la IA, la voz, el audio avanzado y cualquier conexión a Internet.

Cada campaña debe quedar asociada a una versión exacta e inmutable de Ruleset. Las modificaciones de campaña se almacenan en un overlay propio y nunca contaminan el paquete base ni otras campañas.

Las interfaces de escritorio, tablet y móvil deben representar el mismo dominio y estado de campaña, pero cada una debe estar optimizada para su contexto de uso.
