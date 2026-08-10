# Rolemaster — Checklist maestro

Este archivo es el tablero operativo principal del proyecto. El `ROADMAP.md` mantiene la vista general; este checklist define el orden de ejecución y los criterios de cierre.

## Posición actual

- **Último completado:** Fase 3.7 — Encounters + persistencia SQLite v14.
- **Activo:** Fase 4.1 — Rules Engine Foundation: resolver Ruleset efectivo = paquete exacto + módulos activos + overlay de campaña.
- **Siguiente:** Fase 4.2 — Dice / Resolution Engine.
- **Regla:** no iniciar la fase gráfica definitiva hasta completar Backend/Core Freeze. La Visual Alpha queda congelada por ahora; se retoma cuando sea útil para validar una función concreta.

---

# Fase 0 — Producto y arquitectura

- [x] Rolemaster definido como asistente del GM para mesa presencial.
- [x] Jugadores sin cliente obligatorio.
- [x] Escritorio, tablet y móvil.
- [x] Local-first/offline para funciones esenciales.
- [x] Pantalla secundaria opcional controlada por el GM.
- [x] Flutter + Dart.
- [x] `rolemaster_core` independiente de Flutter.
- [x] SQLite local.
- [x] IA, voz y audio desacoplados y opcionales.
- [x] CI remoto.
- [ ] Comunicación local entre dispositivos del GM.
- [ ] Estrategia de plugins/extensiones.
- [ ] Runners Windows/Android validados en toolchain real.

---

# Fase 1 — Fundaciones verificables

## CI y persistencia
- [x] GitHub Actions para Core, SQLite y Flutter.
- [x] Gates de formato, análisis y tests.
- [x] Build web técnico automatizado.
- [x] Artefacto descargable `rolemaster-web-preview`.
- [ ] GitHub Pages para URL directa — pendiente habilitación del repositorio.
- [x] Esquema SQLite central versionado hasta v14.
- [x] Migraciones secuenciales e históricas.
- [x] Snapshots, integridad, restore y rollback pre-restore.

---

# Fase 2 — Core de campaña

- [x] Campaign.
- [x] World / Region / Location.
- [x] Calendar / Time.
- [x] Event Engine.
- [x] State Manager.
- [x] Snapshots / backup.

**Cierre Fase 2:** COMPLETADO.

---

# Fase 3 — Dominio de juego

## 3.1 Characters
- [x] Entidad y ciclo de vida.
- [x] Metadata narrativa.
- [x] Persistencia SQLite v7.

## 3.2 NPCs
- [x] Entidad y ciclo de vida.
- [x] Idiomas y ubicación World/Location.
- [x] Persistencia SQLite v8.
- [ ] Inteligencia/memoria/voz diferidas a sus fases opcionales.

## 3.3 Creatures
- [x] Entidad, especie/categoría, metadata y ubicación.
- [x] Persistencia SQLite v9.
- [x] Stats dependientes del sistema diferidos al Ruleset/Rules Engine.

## 3.3A Ruleset Foundation
- [x] `RulesetManifest`, módulos y paquete versionado/inmutable.
- [x] Binding exacto por campaña.
- [x] Overlay aislado y limpio por defecto.
- [x] Persistencia SQLite v10.
- [x] Reemplazo silencioso de versión bloqueado.
- [ ] Ruleset Builder / importación de manuales completa.
- [ ] Migración controlada entre ediciones/versiones.

## 3.4 Skills — COMPLETADO
- [x] Definiciones desde Ruleset.
- [x] Estado de personaje separado.
- [x] Rangos/modificadores/notas.
- [x] Validación por módulos activos.
- [x] Persistencia SQLite v11.
- [x] CI completo verde.

## 3.5 Inventory / Items — COMPLETADO

Regla arquitectónica: las propiedades del tipo de objeto viven en el Ruleset; la campaña sólo persiste el estado mutable de cada instancia.

- [x] `ItemDefinition` desde Ruleset.
- [x] catálogo tipado y filtrado por módulos activos.
- [x] objetos de campaña definidos por Ruleset o manuales/custom.
- [x] `ItemInstance` con cantidad, equipamiento, notas y timestamps.
- [x] propietario genérico o contenedor opcional.
- [x] transferencias y detección de ciclos de contención.
- [x] propiedades de Ruleset no duplicadas en estado mutable.
- [x] Persistencia SQLite v12.
- [x] Migración v11→v12 preservando Skills y binding de Ruleset.
- [x] CI Core + SQLite + Flutter verde.

## 3.6 Maps / Locations — COMPLETADO

Regla arquitectónica: `World/Region/Location` sigue siendo la geografía canónica. Maps agrega representaciones visuales/lógicas, no una segunda jerarquía geográfica.

- [x] `SceneMap` / mapa lógico perteneciente a campaña.
- [x] Vínculo opcional a `World` y `Location` existentes.
- [x] Validación de pertenencia Campaign/World/Location.
- [x] Espacio lógico de coordenadas independiente del renderer.
- [x] Capas lógicas ordenadas.
- [x] Metadata de visibilidad GM/pública.
- [x] Posiciones opcionales de entidades por referencia genérica.
- [x] Sin dependencia de Flutter/canvas/imágenes concretas en Core.
- [x] Preparación para pantalla secundaria futura.
- [x] Persistencia SQLite v13.
- [x] Migración v12→v13 preservando inventario y datos previos.
- [x] FK compuesta impide usar capas de otro mapa.
- [x] Fixtures históricos v5–v11 compatibles con v13.
- [x] CI Core + SQLite + Flutter verde.

## Visual Alpha 0.1 — VALIDACIÓN CERRADA / CONGELADA POR AHORA

Objetivo cumplido: validar que un manual real puede alimentar un Ruleset de prueba y mostrarse en una experiencia GM antes de abrir la fase gráfica definitiva.

- [x] Cargar primer manual real de prueba: `DUNGEONS & DRAGONS.pdf`.
- [x] Identificarlo provisionalmente como compilación personalizada derivada de B/X.
- [x] Extraer un subconjunto controlado: atributos, clases, alineamiento y creación básica.
- [x] Crear campaña de prueba con Ruleset limpio.
- [x] Mostrar shell GM responsive con datos reales del Ruleset.
- [x] Probar tiradas y creación/reapertura de personaje en la alpha.
- [x] Generar build Flutter Web técnico.
- [x] Generar tester HTML autocontenido para validación en PC restringida.
- [x] Registrar decisión: congelar cambios visuales y retomar el checklist técnico.
- [ ] NPCs visuales detallados, renderer real de mapa y design system diferidos a la fase gráfica.
- [ ] Alegreya / tipografía final a resolver desde la PC central.

## 3.7 Encounters — COMPLETADO

Regla arquitectónica: Encounter modela contexto y ciclo de una escena/encuentro; no contiene todavía iniciativa, daño, HP ni resolución de combate.

- [x] `Encounter` base con `planned / active / closed`.
- [x] Participantes genéricos por `entityType + entityId` y etiqueta opcional.
- [x] Detección de participantes duplicados.
- [x] Contexto opcional World / Location / SceneMap.
- [x] Derivación de World/Location desde SceneMap cuando corresponde.
- [x] Validación de pertenencia a campaña/mundo/localización.
- [x] Agregar/quitar participantes mientras el Encounter no esté cerrado.
- [x] Inicio/cierre y consistencia temporal.
- [x] Repositorio y casos de uso Core.
- [x] Persistencia SQLite v14 para Encounter + participantes.
- [x] Guardado transaccional del agregado y reapertura completa.
- [x] Migración v13→v14 preservando Maps.
- [x] Fixtures históricos v5–v12 compatibles con v14.
- [x] CI Core + SQLite + Flutter verde.
- [ ] Resolver/validar existencia concreta de participantes contra Character/NPC/Creature — diferido hasta integración con Rules/Combat.

---

# Fase 4 — Reglas y combate

## 4.1 Rules Engine Foundation — ACTIVO
- [ ] `EffectiveRuleset` inmutable para una campaña.
- [ ] Resolver paquete exacto + binding + módulos activos + overlay.
- [ ] Validar que binding y paquete coincidan en ID/versión.
- [ ] Validar módulos activos contra el manifest y módulos obligatorios.
- [ ] Aplicar overrides de campaña sin mutar el paquete base.
- [ ] Tests de aislamiento entre campañas y paquete base inmutable.

## 4.2 Dice / Resolution Engine — SIGUIENTE
- [ ] Contrato genérico de tiradas/resolución basado en Ruleset.
- [ ] RNG inyectable/testeable.
- [ ] Resultados trazables.
- [ ] Reglas específicas suministradas por el Ruleset, no hardcodeadas en Core.

## 4.3+ Reglas avanzadas
- [ ] Tablas versionadas.
- [ ] Combat.
- [ ] Efectos/condiciones.
- [ ] Migración controlada de Ruleset.

---

# Fase 5 — Servicios opcionales

- [ ] AI Service.
- [ ] NPC Intelligence.
- [ ] STT/TTS.
- [ ] Audio Director.

---

# Fase 6 — Hardening y Backend/Core Freeze

- [ ] Suite completa verde.
- [ ] Migraciones verificadas.
- [ ] Corrupción/recuperación.
- [ ] Logging/diagnóstico.
- [ ] Benchmarks.
- [ ] Auditoría de contratos.
- [ ] Tag Backend/Core Freeze.

**Puerta obligatoria:** no iniciar UI definitiva antes de este punto.

---

# Fase 7 — Fase gráfica

## Prototipo técnico disponible
- [x] Base responsive Flutter.
- [x] Crear campaña y seleccionar Ruleset/módulos.
- [x] Build Flutter Web automatizado.
- [x] Artefacto descargable.
- [x] Visual Alpha con Ruleset alimentado por primer manual real.
- [x] Tiradas y creación de personaje como pruebas funcionales.
- [ ] URL directa GitHub Pages — pendiente habilitar Pages.

## UI definitiva
- [ ] Design system.
- [ ] Desktop GM Workspace.
- [ ] Tablet.
- [ ] Mobile.
- [ ] Fichas.
- [ ] Map/scene renderer.
- [ ] Panel contextual.
- [ ] Voz/audio.
- [ ] Secondary display.

---

# Fase 8 — Dispositivos del GM

- [ ] Descubrimiento local.
- [ ] Autorización y sync.
- [ ] PC host opcional.
- [ ] Tablet/móvil complementarios.

---

# Fase 9 — Release

- [ ] Hardening final.
- [ ] Instalador Windows.
- [ ] Android build.
- [ ] iOS/iPadOS cuando haya toolchain.
- [ ] Documentación.
- [ ] Release candidate.
- [ ] v1.0.

---

# Regla operativa por sprint

Cada sprint debe reportar: último completado, activo, siguiente, archivos, tests/CI, commit/HEAD y deuda/riesgos. No se avanza si el gate activo no está cumplido o explícitamente diferido.
