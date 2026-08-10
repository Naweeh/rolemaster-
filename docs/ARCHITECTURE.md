# Arquitectura inicial de Rolemaster

## Objetivo

Rolemaster será una plataforma independiente para dirigir y jugar campañas de rol, con soporte para mundo persistente, reglas, personajes, NPC, combate, calendario, eventos, audio e IA opcional.

## Regla principal

El núcleo del sistema no puede depender de un proveedor de IA, un VTT externo ni una interfaz concreta.

## Capas

### 1. Core

Responsable del estado autoritativo de la campaña.

- Campaign Engine
- World Engine
- Calendar / Time Engine
- Rules Engine
- Event Engine
- State Manager

### 2. Game domain

Modelos y lógica de juego.

- Characters
- NPCs
- Creatures
- Skills
- Inventory
- Items
- Combat
- Encounters
- Maps / Locations

### 3. AI

Capa opcional detrás de una interfaz común.

Proveedores previstos:

- Built-in Rolemaster AI (por defecto)
- Custom API provider
- Local model provider
- Disabled provider

Ningún módulo del Core debe llamar directamente a un proveedor concreto.

La configuración podrá ser global o por función, por ejemplo:

- asistente del GM
- NPC
- generación narrativa
- traducción / idiomas
- voz
- generación visual

### 4. Audio

Subsistema independiente para:

- voces de NPC
- música
- ambientes
- efectos sonoros

Debe responder a eventos del juego sin ser requisito para que la partida funcione.

### 5. Data

Persistencia propia de Rolemaster.

- campañas
- personajes
- NPC
- mundo
- reglas
- historial de eventos
- configuración
- contenido del usuario

### 6. UI

Interfaces desacopladas del dominio.

Como referencia visual inicial, el workspace del GM podrá organizarse en tres áreas:

- navegación y biblioteca de campaña
- mapa / escena / espacio central de trabajo
- panel contextual

Con una franja inferior o secundaria para chat, eventos, tiradas y audio.

Fantasy Grounds Unity puede utilizarse como referencia de diagramación, arquitectura modular y flujo de uso, pero no como dependencia técnica.

## Esquema conceptual

```text
ROLEMASTER
|
+-- Core
|   +-- Campaign
|   +-- World
|   +-- Calendar
|   +-- Rules
|   +-- Events
|   +-- State
|
+-- Game
|   +-- Characters
|   +-- NPCs
|   +-- Combat
|   +-- Inventory
|   +-- Encounters
|   +-- Maps
|
+-- AI
|   +-- Built-in
|   +-- Custom
|   +-- Local
|   +-- Disabled
|
+-- Audio
|
+-- Data
|
+-- UI
|
+-- API
```

## NPC como entidad de primera clase

El modelo de NPC se diseñará para soportar, sin obligar a usar IA:

- identidad
- estadísticas
- habilidades
- inventario
- ubicación
- idioma nativo
- voz
- personalidad
- conocimientos
- memoria
- relaciones
- objetivos
- estado actual

Las capacidades inteligentes se añadirán sobre esos datos mediante la capa AI.

## Decisiones todavía abiertas

Antes de implementar el producto deben definirse:

- stack del backend
- base de datos
- formato de reglas y contenido
- framework de UI
- modelo cliente/servidor
- estrategia offline / online
- protocolo de eventos internos
- sistema de plugins o extensiones
