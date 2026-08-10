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
  - [x] esquema SQLite central versionado hasta v12
  - [x] migraciones secuenciales
  - [x] snapshots consistentes mediante SQLite backup
  - [x] validación de integridad y claves foráneas
  - [x] restauración segura
  - [x] snapshot automático pre-restore para rollback

## Fase 2 — Dominio de juego

Sprint activo: **Maps / Locations**.

- [x] Characters — SQLite v7
- [x] NPCs — SQLite v8
- [x] Creatures — SQLite v9
- [x] Ruleset Foundation — SQLite v10
- [x] Skills Foundation — SQLite v11
- [x] Inventory / Items — SQLite v12
  - [x] `ItemDefinition` dependiente de Ruleset
  - [x] catálogo tipado y filtrado por módulos activos
  - [x] objetos de campaña definidos por Ruleset o manuales/custom
  - [x] `ItemInstance` con cantidad, equipamiento, notas y timestamps
  - [x] propietario genérico o contenedor opcional
  - [x] transferencias y des-equipado automático al contener/desasignar
  - [x] rechazo de contenedores de otra campaña
  - [x] detección de ciclos de contención
  - [x] propiedades de Ruleset no duplicadas en estado mutable
  - [x] persistencia SQLite v12
  - [x] migración v11→v12 preservando Skills y binding de Ruleset
  - [x] constraints de base para cantidad, holder/contenedor y autocontención
  - [x] fixtures históricos v5–v10 saneados
  - [x] CI Core + SQLite + Flutter verde
- [ ] Maps / Locations
  - [ ] reutilizar `World/Region/Location` como geografía canónica
  - [ ] mapa/escena lógica vinculable a campaña, mundo y localización
  - [ ] espacio de coordenadas independiente del renderer
  - [ ] capas y metadata de visibilidad
  - [ ] posiciones opcionales de entidades
  - [ ] preparación para pantalla secundaria sin dependencia de UI
  - [ ] persistencia SQLite
  - [ ] tests
- [ ] Encounters

## Fase 3 — Reglas y combate

- [ ] Rules Engine que consume el Ruleset activo
- [ ] Dice / resolution engine
- [ ] Tablas versionadas
- [ ] Combat state
- [ ] Effects / conditions
- [ ] Extensibilidad de reglas
- [ ] Migración controlada entre ediciones/versiones

## Fase 4 — Interfaz multiplataforma

- [x] Base responsive/adaptativa compartida
- [x] UI técnica provisional: crear campaña + seleccionar ruleset/versión/módulos
- [x] Build web técnico automatizado como artefacto de GitHub Actions
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
