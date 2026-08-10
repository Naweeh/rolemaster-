# Rolemaster — Checklist maestro

Este archivo es el tablero operativo principal del proyecto. El `ROADMAP.md` mantiene la vista general; este checklist define el orden de ejecución y los criterios de cierre.

## Posición actual

- **Último completado:** Fase 3.5 — Inventory / Items + persistencia SQLite v12.
- **Activo:** Fase 3.6 — Maps / Locations.
- **Siguiente:** Fase 3.7 — Encounters.
- **Regla:** no iniciar la fase gráfica definitiva hasta completar Backend/Core Freeze. La UI actual es únicamente una herramienta funcional de validación.

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
- [x] Esquema SQLite central versionado hasta v12.
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
- [x] IDs estables, categoría, tags y propiedades JSON-safe e inmutables.
- [x] Filtrado por módulos activos.
- [x] `ItemInstance` perteneciente a campaña.
- [x] Objetos custom sin definición de Ruleset.
- [x] Cantidad positiva.
- [x] Estado equipado.
- [x] Propietario genérico mediante `InventoryHolderRef`.
- [x] Contenedor opcional mediante otra instancia de item.
- [x] Holder y contenedor mutuamente excluyentes.
- [x] Transferencias entre holder/contenedor/desasignado.
- [x] Des-equipado automático al contener/desasignar.
- [x] Rechazo de contenedor inexistente.
- [x] Rechazo de contenedor de otra campaña.
- [x] Detección de ciclos de contención.
- [x] Persistencia SQLite v12.
- [x] Reapertura y upsert.
- [x] Migración v11→v12 preservando Skills y binding de Ruleset.
- [x] Constraints SQLite de cantidad, holder/contenedor y autocontención.
- [x] Fixtures históricos v5–v10 saneados.
- [x] CI Core + SQLite + Flutter verde.

## 3.6 Maps / Locations — ACTIVO

Regla arquitectónica: `World/Region/Location` sigue siendo la geografía canónica. Este sprint agrega representaciones visuales/lógicas de una localización, no una segunda jerarquía geográfica.

- [ ] `SceneMap` / mapa lógico perteneciente a campaña.
- [ ] Vínculo opcional a `World` y `Location` existentes.
- [ ] Validación de pertenencia Campaign/World/Location.
- [ ] Espacio lógico de coordenadas independiente del renderer.
- [ ] Capas lógicas ordenadas.
- [ ] Metadata de visibilidad GM/pública.
- [ ] Posiciones opcionales de entidades por referencia genérica.
- [ ] Sin dependencia de Flutter/canvas/imágenes concretas en Core.
- [ ] Preparación para pantalla secundaria futura.
- [ ] Persistencia SQLite v13.
- [ ] Migración v12→v13 preservando inventario y datos previos.
- [ ] Tests.

## 3.7 Encounters — SIGUIENTE
- [ ] Encounter base.
- [ ] Participantes.
- [ ] Contexto/localización/mapa opcional.
- [ ] Inicio/cierre/estado.
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
