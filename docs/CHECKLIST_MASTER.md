# Rolemaster — Checklist maestro

Este archivo es el tablero operativo principal del proyecto. El `ROADMAP.md` mantiene la vista general; este checklist define el orden de ejecución y los criterios de cierre.

## Posición actual

- **Último completado:** Fase 3.4 — Skills Foundation + persistencia SQLite v11 + build web técnico automatizado.
- **Activo:** Fase 3.5 — Inventory / Items.
- **Siguiente:** Maps / Locations y luego Encounters.
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

**Cierre:** fundaciones principales COMPLETADAS; ítems de dispositivos/plugins diferidos explícitamente.

---

# Fase 1 — Fundaciones verificables

## CI y tests

- [x] GitHub Actions para Core Dart.
- [x] `dart format` como gate.
- [x] `dart analyze --fatal-infos`.
- [x] `dart test`.
- [x] Flutter analyze.
- [x] Job independiente para persistencia SQLite.
- [x] Build web técnico automatizado en GitHub Actions.
- [x] Artefacto descargable `rolemaster-web-preview`.
- [ ] GitHub Pages para URL directa — pendiente habilitación del repositorio.

## Persistencia

- [x] SQLite multiplataforma seleccionado.
- [x] Esquema central versionado hasta v11.
- [x] Migraciones secuenciales.
- [x] Tests de migraciones históricas.
- [x] Snapshots mediante backup SQLite.
- [x] Integridad + foreign keys.
- [x] Restauración segura.
- [x] Snapshot pre-restore automático.

**Cierre Fase 1:** COMPLETADO.

---

# Fase 2 — Core de campaña

## 2.1 Campaign
- [x] Entidad, metadata y configuración.
- [x] Create/Get/List/Update/Rename/Archive.
- [x] Persistencia.

## 2.2 World
- [x] World.
- [x] Regiones jerárquicas.
- [x] Locations jerárquicas.
- [x] Persistencia.

## 2.3 Calendar / Time
- [x] Calendario personalizado.
- [x] Campaign timeline.
- [x] Advance time.
- [x] Temporal events.
- [x] Persistencia.

## 2.4 Event Engine
- [x] `DomainEvent` extensible.
- [x] Payload JSON-safe e inmutable.
- [x] Bus interno.
- [x] Suscripciones filtrables.
- [x] Dispatcher.
- [x] Historial append-only SQLite.

## 2.5 State Manager
- [x] Revisión autoritativa por campaña.
- [x] Prevalidación.
- [x] Aplicación secuencial.
- [x] Rollback lógico.
- [x] Optimistic revisioning.
- [x] Compare-and-swap persistente.
- [x] Protección contra carrera entre repositorios/instancias.

## 2.6 Snapshots / backup
- [x] Snapshot consistente.
- [x] Validación antes de restaurar.
- [x] Restore.
- [x] Backup automático pre-restore.
- [x] Rechazo de schema futuro.

**Cierre Fase 2:** COMPLETADO.

---

# Fase 3 — Dominio de juego

## 3.1 Characters
- [x] Identidad y metadata narrativa.
- [x] Asociación a campaña.
- [x] Crear/cargar/listar/editar/archivar.
- [x] SQLite v7.
- [x] Estadísticas específicas diferidas correctamente al Ruleset.

## 3.2 NPCs
- [x] Identidad y metadata.
- [x] Idioma nativo.
- [x] Idiomas conocidos extensibles.
- [x] Ubicación World/Location.
- [x] Validaciones de pertenencia.
- [x] Crear/cargar/listar/editar/archivar.
- [x] SQLite v8.
- [ ] Personalidad dinámica — fase IA.
- [ ] Memoria — fase IA.
- [ ] Voz/TTS — fase Voz.

## 3.3 Creatures
- [x] Entidad base.
- [x] Especie/categoría.
- [x] Metadata narrativa.
- [x] Ubicación.
- [x] Lifecycle.
- [x] SQLite v9.
- [x] Stats/ataques/defensas diferidos al Ruleset/Rules Engine.

## 3.3A Ruleset Foundation

### Modelo
- [x] `RulesetModuleDefinition`.
- [x] `RulesetManifest`.
- [x] `RulesetPackage`.
- [x] Paquete base inmutable.
- [x] Datos de paquete JSON-safe e inmutables en profundidad.
- [x] Edición y versión exactas.
- [x] Módulos obligatorios, default y opcionales.

### Campaña
- [x] `CampaignRulesetBinding`.
- [x] `CampaignRulesOverlay`.
- [x] Cada campaña nueva comienza con overlay limpio.
- [x] Una campaña nunca hereda automáticamente house rules de otra.
- [x] Reset elimina overrides pero conserva binding.
- [x] Re-inicialización silenciosa bloqueada.
- [x] Cambio silencioso de versión bloqueado.

### Persistencia v10
- [x] Catálogo `ruleset_packages`.
- [x] Binding/overlay `campaign_rulesets`.
- [x] Paquetes publicados inmutables por `(ruleset_id, version)`.
- [x] Migración v9→v10.
- [x] Fixtures históricos compatibles con schema actual.
- [x] CI Core + SQLite + Flutter verde.

### Manuales / contenido
- [ ] Ruleset Builder.
- [ ] Importación PDF/manuales.
- [ ] Extracción y normalización.
- [ ] Revisión del GM antes de publicar.
- [ ] Publicación de nueva versión inmutable.
- [ ] Presets de house rules separados del Ruleset base.
- [ ] Importación explícita de preset/configuración de otra campaña.
- [ ] Preview de migración entre versiones/ediciones.
- [ ] Snapshot automático antes de migrar Ruleset.
- [ ] Conversión y resolución manual de campos incompatibles.

## 3.4 Skills — COMPLETADO

Regla arquitectónica: la definición de una habilidad pertenece al Ruleset; el valor/rango concreto pertenece al personaje/campaña.

- [x] `SkillDefinition` versionada dentro del Ruleset.
- [x] IDs estables de definición dentro de cada paquete/version.
- [x] Categoría/descripcion/tags como metadata tipada.
- [x] Asociación opcional a módulo del Ruleset.
- [x] `RulesetSkillCatalog` desde `RulesetPackage.data['skills']`.
- [x] Rechazo de IDs duplicados.
- [x] Rechazo de módulos inexistentes.
- [x] `CharacterSkillState` separado de la definición.
- [x] Rangos.
- [x] Modificadores nombrados.
- [x] Notas.
- [x] Validación contra Ruleset exacto y módulos activos de campaña.
- [x] Bloqueo de modificación sobre personaje archivado.
- [x] Listado que une definición activa + estado opcional del personaje.
- [x] Persistencia SQLite v11.
- [x] Migración v10→v11 preservando el binding de Ruleset.
- [x] Reapertura y upsert verificados.
- [x] Fixtures históricos v5–v9 saneados para schema v11.
- [x] CI Core + SQLite + Flutter verde.
- [x] Atributos derivados, fórmulas y costes diferidos al Rules Engine para evitar hardcodear reglas en el dominio.

## 3.5 Inventory / Items — ACTIVO
- [ ] `ItemDefinition` dependiente de Ruleset cuando corresponda.
- [ ] IDs estables de definición.
- [ ] Categoría y metadata base.
- [ ] `ItemInstance` perteneciente a campaña.
- [ ] Propietario/contenedor opcional.
- [ ] Cantidad.
- [ ] Estado de equipamiento.
- [ ] Transferencias entre entidades/contenedores.
- [ ] Validación contra Ruleset activo cuando exista definición.
- [ ] Persistencia SQLite.
- [ ] Tests.

## 3.6 Maps / Locations
- [ ] Modelo lógico de mapas/escenas.
- [ ] Vínculo con World/Location.
- [ ] Sin dependencia del renderer.

## 3.7 Encounters
- [ ] Encounter.
- [ ] Participantes.
- [ ] Contexto/localización.
- [ ] Inicio/cierre/estado.
- [ ] Tests.

**Criterio de cierre Fase 3:** entidades de juego y sus estados funcionan sin Flutter, y cualquier dato dependiente del sistema referencia definiciones del Ruleset activo en vez de quedar hardcodeado en el Core.

---

# Fase 4 — Reglas y combate

## 4.1 Rules Engine
- [ ] Resolver el Ruleset efectivo = base + módulos + overlay.
- [ ] Definiciones de atributos/profesiones/tablas.
- [ ] Fórmulas/costes de Skills y otras definiciones dependientes del sistema.
- [ ] Validadores.
- [ ] Consultas de reglas sin UI.

## 4.2 Dice / Resolution Engine
- [ ] Dados estándar.
- [ ] Tiradas abiertas/encadenadas definibles por Ruleset.
- [ ] Modificadores.
- [ ] Resultado estructurado.
- [ ] RNG/semilla controlable para tests.
- [ ] Historial de tiradas.

## 4.3 Combat
- [ ] Combat state.
- [ ] Participantes.
- [ ] Iniciativa/turnos definidos por Ruleset.
- [ ] Acciones.
- [ ] Ataques/defensas/daño.
- [ ] Tablas y críticos.
- [ ] Efectos/condiciones.
- [ ] Tests completos.

## 4.4 Migración de Ruleset
- [ ] Comparación de schemas/definiciones.
- [ ] Compatible / convertible / decisión GM / no compatible.
- [ ] Preview.
- [ ] Snapshot.
- [ ] Confirmación GM.
- [ ] Migración.
- [ ] Validación.
- [ ] Rollback.

---

# Fase 5 — Servicios opcionales

- [ ] AI Service + Disabled/Built-in/Custom/Local providers.
- [ ] NPC Intelligence.
- [ ] Speech-to-Text.
- [ ] Text-to-Speech.
- [ ] Audio Director.
- [ ] Música / ambience / SFX.
- [ ] Ninguna capacidad esencial depende de estos servicios.

---

# Fase 6 — Hardening y Backend/Core Freeze

- [ ] Suite completa verde.
- [ ] Migraciones de todas las versiones verificadas.
- [ ] Corrupción/recuperación.
- [ ] Logging/diagnóstico.
- [ ] Benchmarks.
- [ ] Auditoría de contratos públicos.
- [ ] Eliminación de duplicaciones.
- [ ] Documentación técnica.
- [ ] Tag Backend/Core Freeze.

**Puerta obligatoria:** no iniciar UI definitiva antes de este punto.

---

# Fase 7 — Fase gráfica

## Prototipo técnico ya disponible
- [x] Base responsive Flutter.
- [x] Crear campaña desde UI técnica.
- [x] Seleccionar Ruleset/edición/versión.
- [x] Activar/desactivar módulos opcionales.
- [x] Mostrar que la campaña comienza con Ruleset limpio.
- [x] Mostrar binding/versión de campañas creadas.
- [x] Flutter analyze verde.
- [x] Build Flutter Web release automatizado.
- [x] Artefacto web descargable por GitHub Actions.
- [ ] URL directa GitHub Pages — pendiente habilitar Pages en Settings.

> Este prototipo es descartable/evolutivo y NO constituye el inicio de la UI final.

## UI definitiva
- [ ] Design system.
- [ ] Desktop GM Workspace.
- [ ] Tablet.
- [ ] Mobile.
- [ ] Fichas.
- [ ] Map/scene.
- [ ] Panel contextual.
- [ ] Reglas/consulta.
- [ ] Voz/audio.
- [ ] Secondary display.

---

# Fase 8 — Dispositivos del GM

- [ ] Descubrimiento local.
- [ ] Autorización.
- [ ] Sync.
- [ ] Conflictos.
- [ ] PC host opcional.
- [ ] Tablet/móvil complementarios.

---

# Fase 9 — Release

- [ ] Hardening final.
- [ ] Instalador Windows.
- [ ] Android build.
- [ ] iOS/iPadOS cuando haya toolchain.
- [ ] Docs usuario/técnicas.
- [ ] Release candidate.
- [ ] v1.0.

---

# Regla operativa por sprint

Cada sprint debe reportar:

1. Último completado.
2. Activo.
3. Siguiente.
4. Archivos modificados.
5. Tests/CI.
6. Commit/HEAD.
7. Riesgos o deuda técnica.

No se avanza al siguiente bloque si el criterio de cierre del bloque activo no está cumplido o explícitamente diferido y documentado.
