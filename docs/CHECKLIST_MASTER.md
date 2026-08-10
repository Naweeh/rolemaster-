# Rolemaster — Checklist maestro

Este archivo es el tablero operativo principal del proyecto. El `ROADMAP.md` mantiene la vista general; este checklist define el orden de ejecución y los criterios de cierre.

## Posición actual

- **Último completado:** Fase 3.6 — Maps / Locations + persistencia SQLite v13.
- **Activo:** Visual Alpha 0.1 — primera validación visual con Ruleset alimentado desde manual.
- **Siguiente:** Fase 3.7 — Encounters.
- **Regla:** no iniciar la fase gráfica definitiva hasta completar Backend/Core Freeze. La Visual Alpha es una herramienta funcional de validación y puede cambiar libremente.

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
- [x] Esquema SQLite central versionado hasta v13.
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
- [ ] Ruleset Builder / importación de manuales.
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

## Visual Alpha 0.1 — ACTIVO

Objetivo: usar datos reales del Core y un manual real como primera fuente de Ruleset para empezar a validar la experiencia del GM sin abrir todavía la fase gráfica definitiva.

- [ ] Cargar primer manual de prueba.
- [ ] Identificar edición/versión/módulos del manual.
- [ ] Extraer un subconjunto controlado de datos del Ruleset para la prueba.
- [ ] Crear campaña de prueba con ruleset limpio.
- [ ] Mostrar shell GM responsive con datos reales.
- [ ] Mostrar al menos Campaign, Ruleset, Characters/NPCs y Map/Scene.
- [ ] Generar nuevo build web técnico para revisión visual.
- [ ] Registrar feedback sin congelar design system.

## 3.7 Encounters — SIGUIENTE
- [ ] Encounter base.
- [ ] Participantes.
- [ ] Contexto/localización/mapa opcional.
- [ ] Inicio/cierre/estado.
- [ ] Persistencia.
- [ ] Tests.

---

# Fase 4 — Reglas y combate

- [ ] Rules Engine efectivo = base + módulos + overlay.
- [ ] Dice / Resolution Engine.
- [ ] Combat.
- [ ] Efectos/condiciones.
- [ ] Migración de Ruleset.

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
