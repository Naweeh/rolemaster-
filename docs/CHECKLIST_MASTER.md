# Rolemaster — Checklist maestro

Este archivo es el tablero operativo principal del proyecto. El `ROADMAP.md` mantiene la vista general; este checklist define el orden de ejecución y los criterios de cierre.

## Posición actual

- **Último completado:** Fase 2.3 — Calendar / Time: calendario personalizado, timeline, eventos temporales y persistencia SQLite v4.
- **Activo:** Fase 2.4 — Event Engine.
- **Siguiente:** Fase 2.5 — State Manager.
- **Regla:** no iniciar la fase gráfica definitiva hasta completar Backend/Core Freeze.

---

# Fase 0 — Producto y arquitectura

## 0.1 Definición de producto

- [x] Rolemaster definido como asistente del GM para mesa presencial.
- [x] Jugadores sin cliente obligatorio.
- [x] Interacción principal directa y por voz.
- [x] Soporte escritorio, tablet y móvil.
- [x] Funcionamiento local-first/offline para funciones esenciales.
- [x] Pantalla secundaria opcional controlada por el GM.
- [x] Fantasy Grounds tratado sólo como referencia de arquitectura/UI.

## 0.2 Stack y separación técnica

- [x] Dart como lenguaje principal del Core.
- [x] Flutter como UI multiplataforma.
- [x] `rolemaster_core` independiente de Flutter.
- [x] SQLite elegido como persistencia local prevista.
- [x] IA definida como capacidad opcional e intercambiable.
- [x] Voz y audio definidos como servicios desacoplados.
- [x] ADR-0001 creado.
- [x] Bootstrap remoto inicial creado.

**Cierre Fase 0:** COMPLETADO.

---

# Fase 1 — Fundaciones verificables

Objetivo: que cada cambio pueda validarse automáticamente sin depender de una PC concreta.

## 1.1 CI remoto

- [x] Crear GitHub Actions para Dart/Flutter.
- [x] Ejecutar `dart analyze` sobre `rolemaster_core`.
- [x] Ejecutar tests del Core.
- [x] Ejecutar `flutter analyze` sobre la app.
- [x] Fallar CI ante warnings/errores relevantes.
- [x] Documentar estado de CI en README.

## 1.2 Base de tests

- [x] Agregar framework y estructura de tests del Core.
- [x] Test de creación válida de Campaign.
- [x] Test de nombre vacío/inválido.
- [x] Test de generación de ID.
- [x] Test de timestamps.
- [x] Test del contrato `CampaignRepository` mediante implementaciones de prueba y SQLite.

## 1.3 Persistencia base

- [x] Seleccionar librería SQLite compatible con Windows/Android/iOS.
- [x] Crear esquema inicial y versión de base de datos.
- [x] Implementar `SqliteCampaignRepository`.
- [x] Crear bootstrap inicial y migraciones versionadas.
- [x] Guardar Campaign.
- [x] Listar Campaigns.
- [x] Cargar Campaign por ID.
- [x] Editar datos base de Campaign mediante upsert.
- [x] Archivar Campaign sin borrado destructivo.
- [x] Tests de persistencia reales.

**Criterio de cierre:** crear → guardar → cerrar contexto → reabrir repositorio → recuperar la misma campaña, cubierto por tests.

**Cierre Fase 1:** COMPLETADO.

---

# Fase 2 — Core de campaña

## 2.1 Campaign

- [x] Entidad base `Campaign`.
- [x] Puerto `CampaignRepository`.
- [x] Caso de uso `CreateCampaign`.
- [x] `GetCampaign`.
- [x] `ListCampaigns`.
- [x] `RenameCampaign`.
- [x] `UpdateCampaign` para edición general.
- [x] `ArchiveCampaign`.
- [x] Metadata de campaña.
- [x] Configuración propia de campaña.
- [x] Estado activa/archivada.
- [x] Tests del ciclo de vida inicial.
- [x] Tests completos de Campaign.

**Cierre Fase 2.1:** COMPLETADO.

## 2.2 World

- [x] Entidad `World`.
- [x] Regiones.
- [x] Lugares/localizaciones.
- [x] Relaciones jerárquicas entre lugares.
- [x] Estado persistente del mundo.
- [x] Metadata extensible.
- [x] Tests.

**Cierre Fase 2.2:** COMPLETADO.

## 2.3 Calendar / Time

- [x] Modelo de calendario desacoplado de calendario gregoriano.
- [x] Fecha y hora de campaña.
- [x] Avance manual del tiempo.
- [x] Duraciones.
- [x] Eventos temporales.
- [x] Calendarios personalizados.
- [x] Tests de bordes/cambios de fecha.
- [x] Persistencia SQLite de calendario, timeline y eventos.
- [x] Migración central SQLite v3 → v4 sin pérdida de Campaign/World.

**Cierre Fase 2.3:** COMPLETADO.

## 2.4 Event Engine

- [ ] Definir `DomainEvent`.
- [ ] Bus interno de eventos.
- [ ] Eventos sin dependencia de UI.
- [ ] Registro/historial de eventos.
- [ ] Eventos de campaña, mundo, combate, voz y audio extensibles.
- [ ] Tests de publicación/consumo.

## 2.5 State Manager

- [ ] Estado autoritativo de sesión/campaña.
- [ ] Transacciones de cambios.
- [ ] Validación previa a aplicar cambios.
- [ ] Rollback lógico cuando corresponda.
- [ ] Tests.

## 2.6 Snapshots y backup

- [ ] Snapshot manual.
- [ ] Snapshot automático configurable.
- [ ] Restauración.
- [ ] Integridad de base de datos.
- [ ] Backup exportable.
- [ ] Tests de recuperación.

**Criterio de cierre Fase 2:** una campaña puede existir, persistir, avanzar en el tiempo, modificar el mundo y recuperar su estado sin UI.

---

# Fase 3 — Dominio de juego

## 3.1 Characters

- [ ] Identidad.
- [ ] Atributos/estadísticas.
- [ ] Habilidades.
- [ ] Estado.
- [ ] Inventario asociado.
- [ ] Notas e historial.
- [ ] Persistencia.
- [ ] Tests.

## 3.2 NPCs

- [ ] Identidad.
- [ ] Estadísticas y habilidades.
- [ ] Ubicación.
- [ ] Inventario.
- [ ] Personalidad.
- [ ] Conocimientos.
- [ ] Relaciones.
- [ ] Objetivos.
- [ ] Idioma nativo.
- [ ] Configuración de voz.
- [ ] Memoria estructurada opcional.
- [ ] IA habilitable/deshabilitable por NPC.
- [ ] Tests sin IA.

## 3.3 Creatures

- [ ] Modelo base.
- [ ] Estadísticas.
- [ ] Capacidades.
- [ ] Hábitat/localización.
- [ ] Tests.

## 3.4 Skills

- [ ] Catálogo de habilidades.
- [ ] Valores/rangos.
- [ ] Modificadores.
- [ ] Resolución independiente de UI.
- [ ] Tests.

## 3.5 Inventory / Items

- [ ] Item base.
- [ ] Categorías.
- [ ] Propiedades.
- [ ] Cantidades.
- [ ] Equipamiento.
- [ ] Transferencias entre entidades.
- [ ] Tests.

## 3.6 Maps / Locations

- [ ] Modelo lógico de mapas y escenas.
- [ ] Vínculo mapa ↔ localización.
- [ ] Posiciones opcionales de entidades.
- [ ] Capas/visibilidad como metadata de dominio.
- [ ] Sin dependencia de renderer.

## 3.7 Encounters

- [ ] Encounter base.
- [ ] Participantes.
- [ ] Contexto/localización.
- [ ] Estado.
- [ ] Inicio/cierre.
- [ ] Tests.

**Criterio de cierre Fase 3:** personajes, NPC, criaturas, inventario y encuentros funcionan completamente desde el Core.

---

# Fase 4 — Reglas y combate

## 4.1 Rules Engine

- [ ] Definir límites entre datos de reglas y código.
- [ ] Sistema de reglas versionable.
- [ ] Carga de tablas/datos.
- [ ] Validadores.
- [ ] Tests deterministas.

## 4.2 Dice / Resolution Engine

- [ ] Dados estándar.
- [ ] Tiradas abiertas/encadenadas si el sistema lo requiere.
- [ ] Modificadores.
- [ ] Resultado estructurado.
- [ ] Semilla controlable para tests.
- [ ] Historial de tiradas.

## 4.3 Combat

- [ ] Estado de combate.
- [ ] Participantes.
- [ ] Orden/turnos según reglas adoptadas.
- [ ] Acciones.
- [ ] Daño/estado.
- [ ] Efectos/condiciones.
- [ ] Cierre de combate.
- [ ] Tests de escenarios completos.

## 4.4 Extensibilidad de reglas

- [ ] Definir formato de contenido de reglas.
- [ ] Separar contenido del motor.
- [ ] Versionado.
- [ ] Compatibilidad/migración.

**Criterio de cierre Fase 4:** una secuencia completa de resolución y combate puede ejecutarse por tests sin Flutter.

---

# Fase 5 — Servicios opcionales

## 5.1 AI Service

- [ ] Contrato `AiProvider`.
- [ ] `DisabledAiProvider`.
- [ ] Built-in provider.
- [ ] Custom API provider.
- [ ] Local model provider.
- [ ] Configuración global y por capacidad.
- [ ] Configuración por NPC.
- [ ] Timeouts/fallbacks.
- [ ] Ningún módulo esencial depende de IA.

## 5.2 NPC Intelligence

- [ ] Context builder.
- [ ] Memoria controlada.
- [ ] Conocimientos permitidos.
- [ ] Relaciones/objetivos.
- [ ] Generación de respuesta.
- [ ] Preview para GM.
- [ ] Edición manual.
- [ ] Respuesta manual.

## 5.3 Voice

- [ ] Contrato Speech-to-Text.
- [ ] Contrato Text-to-Speech.
- [ ] Context routing.
- [ ] Selección del NPC destinatario.
- [ ] Idioma nativo.
- [ ] Voz configurable.
- [ ] Funcionamiento manual cuando voz esté desactivada.

## 5.4 Audio

- [ ] `AudioDirector`.
- [ ] Música.
- [ ] Ambientes.
- [ ] SFX.
- [ ] Reacción a Domain Events.
- [ ] Control manual del GM.

**Criterio de cierre Fase 5:** IA/voz/audio pueden encenderse o apagarse sin modificar el Core ni romper una campaña.

---

# Fase 6 — Hardening y Backend/Core Freeze

## 6.1 Calidad

- [ ] Suite completa de tests.
- [ ] Cobertura de casos críticos.
- [ ] Tests de migraciones.
- [ ] Tests de backup/restauración.
- [ ] Tests de corrupción/errores recuperables.
- [ ] Logging estructurado.
- [ ] Diagnóstico del sistema.

## 6.2 Rendimiento

- [ ] Benchmark carga de campaña grande.
- [ ] Benchmark consultas NPC/personajes.
- [ ] Benchmark historial de eventos.
- [ ] Benchmark reglas/combate.
- [ ] Objetivos de rendimiento documentados.

## 6.3 Freeze

- [ ] Contratos públicos del Core auditados.
- [ ] Duplicaciones eliminadas.
- [ ] Arquitectura documentada.
- [ ] Migraciones verificadas.
- [ ] Suite verde.
- [ ] Tag/versión de Backend/Core Freeze.

**Puerta obligatoria:** NO iniciar UI definitiva antes de este punto, salvo wireframes/prototipos descartables de validación.

---

# Fase 7 — Fase gráfica

## 7.1 Design system

- [ ] Tipografía.
- [ ] Espaciado.
- [ ] Colores.
- [ ] Estados.
- [ ] Componentes base.
- [ ] Accesibilidad.
- [ ] Touch targets.

## 7.2 Desktop GM Workspace

- [ ] Navegación principal.
- [ ] Dashboard/campaña.
- [ ] Personajes.
- [ ] NPC.
- [ ] Mundo/lugares.
- [ ] Calendario.
- [ ] Combate.
- [ ] Reglas/consulta.
- [ ] Audio/voz.
- [ ] Panel contextual.

## 7.3 Tablet

- [ ] Navegación táctil.
- [ ] Layout adaptado.
- [ ] Controles de sesión rápidos.
- [ ] NPC/voz/combate prioritarios.

## 7.4 Mobile

- [ ] Vista contextual.
- [ ] NPC activo.
- [ ] Voz.
- [ ] Tiradas.
- [ ] Audio.
- [ ] Consulta rápida.

## 7.5 Pantalla secundaria

- [ ] Mapa/escena.
- [ ] Imágenes.
- [ ] Handouts.
- [ ] Información pública controlada por GM.

**Criterio de cierre Fase 7:** mismas capacidades del Core accesibles con flujos adecuados para escritorio, tablet y móvil.

---

# Fase 8 — Sincronización opcional entre dispositivos del GM

- [ ] Descubrimiento local.
- [ ] Autorización segura.
- [ ] PC como host opcional.
- [ ] Tablet como control complementario.
- [ ] Móvil como control rápido.
- [ ] Resolución de conflictos.
- [ ] Funcionamiento sin Internet.

---

# Fase 9 — Release / estabilidad

- [ ] Auditoría funcional completa.
- [ ] Auditoría visual.
- [ ] Accesibilidad.
- [ ] Instalador Windows.
- [ ] Build Android.
- [ ] Build iOS/iPadOS cuando exista toolchain disponible.
- [ ] Backup/import/export verificados.
- [ ] Documentación de usuario.
- [ ] Documentación técnica.
- [ ] Checklist de privacidad/credenciales.
- [ ] Release candidate.
- [ ] v1.0.

---

# Regla operativa para cada sprint

Cada sprint debe reportar siempre:

1. **Último completado**.
2. **Activo**.
3. **Siguiente**.
4. Archivos modificados.
5. Tests ejecutados y resultado.
6. Estado Git/commit.
7. Riesgos o deuda técnica detectada.

No se avanza al siguiente bloque si el criterio de cierre del bloque activo no está cumplido o explícitamente diferido y documentado.
