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
- [ ] Elegir stack tecnológico
- [ ] Definir estructura de persistencia
- [ ] Definir arquitectura de eventos
- [ ] Definir comunicación local opcional entre dispositivos del GM
- [ ] Definir estrategia de plugins/extensiones
- [ ] Crear ADRs para decisiones técnicas importantes

## Fase 1 — Core de campaña

- [ ] Campaign
- [ ] World
- [ ] Calendar / Time
- [ ] Event Engine
- [ ] State Manager
- [ ] Persistencia y snapshots

## Fase 2 — Dominio de juego

- [ ] Characters
- [ ] NPCs
- [ ] Creatures
- [ ] Skills
- [ ] Inventory / Items
- [ ] Maps / Locations
- [ ] Encounters

## Fase 3 — Reglas y combate

- [ ] Rules Engine
- [ ] Dice / resolution engine
- [ ] Combat state
- [ ] Effects / conditions
- [ ] Extensibilidad de reglas

## Fase 4 — Interfaz multiplataforma

- [ ] Workspace completo del GM en escritorio
- [ ] Layout táctil para tablet
- [ ] Vista contextual para móvil
- [ ] Sistema responsive/adaptativo compartido
- [ ] Fichas
- [ ] Mapa / escena
- [ ] Panel contextual
- [ ] Voz / tiradas / eventos / audio
- [ ] Pantalla secundaria opcional para la mesa

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

Esta fase es opcional para la primera versión estable y no implica clientes de jugador.

- [ ] Descubrimiento en red local
- [ ] Sincronización entre dispositivos del mismo GM
- [ ] Tablet como vista/control complementario
- [ ] Móvil como control rápido de voz, NPC y audio
- [ ] Gestión segura de sesión local

## Criterio de desarrollo

Rolemaster debe seguir siendo plenamente útil como soporte de una mesa presencial aunque estén desactivadas la IA, la voz, el audio avanzado y cualquier conexión a Internet.

Las interfaces de escritorio, tablet y móvil deben representar el mismo dominio y estado de campaña, pero cada una debe estar optimizada para su contexto de uso.
