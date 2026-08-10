# Roadmap inicial

## Fase 0 — Fundaciones

Objetivo: definir el producto antes de implementar lógica específica.

- [x] Crear repositorio e inicializar `main`
- [x] Definir principios de independencia y modularidad
- [x] Definir IA como capa opcional e intercambiable
- [ ] Elegir stack tecnológico
- [ ] Definir modelo de ejecución: local, cliente/servidor o híbrido
- [ ] Definir estructura de persistencia
- [ ] Definir arquitectura de eventos
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

## Fase 4 — Interfaz base

- [ ] Workspace del GM
- [ ] Workspace del jugador
- [ ] Fichas
- [ ] Mapa / escena
- [ ] Panel contextual
- [ ] Chat / tiradas / eventos

## Fase 5 — IA opcional

- [ ] AI service interface
- [ ] Disabled provider
- [ ] Built-in provider
- [ ] Custom API provider
- [ ] Local model provider
- [ ] Configuración por capacidad
- [ ] Memoria y comportamiento de NPC
- [ ] Idiomas y diálogo

## Fase 6 — Audio

- [ ] Audio Director
- [ ] Voz de NPC
- [ ] Música
- [ ] Ambiente
- [ ] SFX
- [ ] Eventos de audio sincronizados con el estado de campaña

## Criterio de desarrollo

Ninguna fase de IA o audio debe impedir el funcionamiento completo del Core, las reglas, los personajes o la campaña cuando esas capacidades estén desactivadas.
