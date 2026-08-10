# Arquitectura inicial de Rolemaster

## Objetivo

Rolemaster será un asistente digital multiplataforma para el Director de Juego de partidas presenciales.

Su función es apoyar la preparación y conducción de la mesa tradicional mediante campaña, mundo persistente, reglas, personajes, NPC, combate, calendario, eventos, mapas, audio, voz e IA opcional.

No se diseña como VTT multiusuario ni requiere clientes de jugador.

## Regla principal

El núcleo del sistema no puede depender de un proveedor de IA, un VTT externo, Internet ni una interfaz concreta.

Las capacidades esenciales deben seguir funcionando con IA desactivada y sin conexión externa.

## Modelo de ejecución

Rolemaster será **local-first** y multiplataforma.

El GM podrá utilizarlo desde:

- escritorio / notebook
- tablet
- teléfono móvil

La experiencia debe adaptarse al dispositivo, no replicar la misma disposición visual en todos los tamaños.

Una misma campaña podrá, en una etapa posterior, exponerse a varios dispositivos del propio GM dentro de la red local. Esto no convierte al sistema en una plataforma multiusuario para jugadores.

También se contempla una salida secundaria opcional para mostrar contenido público a la mesa: mapas, imágenes, handouts, iniciativa u otra información seleccionada por el GM.

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

La configuración podrá ser global o por capacidad, por ejemplo:

- asistente del GM
- NPC
- generación narrativa
- traducción / idiomas
- voz
- generación visual

La IA puede proponer, interpretar o ejecutar automatizaciones permitidas, pero el GM conserva el control autoritativo sobre el estado de campaña.

### 4. Voice

Subsistema para interacción por voz durante la mesa presencial.

Responsabilidades previstas:

- Speech-to-Text
- identificación del contexto
- selección del NPC o función destinataria
- diálogo asistido por IA o contenido manual
- idioma del NPC
- Text-to-Speech

Debe poder desactivarse sin afectar al resto del sistema.

### 5. Audio

Subsistema independiente para:

- voces de NPC
- música
- ambientes
- efectos sonoros

Debe responder a eventos del juego sin ser requisito para que la partida funcione.

### 6. Data

Persistencia propia de Rolemaster.

- campañas
- personajes
- NPC
- mundo
- reglas
- historial de eventos
- configuración
- contenido del usuario

El almacenamiento local es la fuente de verdad primaria. Cualquier sincronización o backup remoto futuro será complementario.

### 7. UI

Interfaces desacopladas del dominio y adaptadas al dispositivo.

#### Escritorio

Experiencia completa del GM, orientada a preparación y conducción de sesión con alta densidad de información.

#### Tablet

Experiencia táctil completa, reorganizada para conducción presencial cómoda.

#### Móvil

Vista contextual y de acceso rápido para funciones como NPC activo, voz, tiradas, audio, consulta y combate.

#### Pantalla secundaria opcional

Vista de solo presentación controlada por el GM para contenido visible por toda la mesa.

Como referencia visual inicial, el workspace de escritorio podrá organizarse en:

- navegación y biblioteca de campaña
- mapa / escena / espacio central de trabajo
- panel contextual
- franja de voz, eventos, tiradas y audio

Fantasy Grounds Unity puede utilizarse como referencia de diagramación, modularidad y flujo de uso, pero no como dependencia técnica ni como modelo obligatorio.

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
+-- Voice
|
+-- Audio
|
+-- Data
|
+-- UI
|   +-- Desktop
|   +-- Tablet
|   +-- Mobile
|   +-- Secondary Display
|
+-- Local API / Event Bus
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

## Decisiones ya tomadas

- Rolemaster es una herramienta del GM para mesa presencial.
- No requiere clientes de jugador.
- Debe funcionar en escritorio, tablet y móvil.
- Debe ser local-first y mantener funciones esenciales offline.
- La IA es opcional e intercambiable.
- Voz y audio son subsistemas desacoplados.
- Se prevé una pantalla secundaria opcional controlada por el GM.
- Fantasy Grounds y otros VTT son referencias, no dependencias.

## Decisiones todavía abiertas

Antes de implementar el producto deben definirse:

- stack del Core/backend
- framework de UI multiplataforma
- base de datos
- formato de reglas y contenido
- mecanismo de comunicación local entre dispositivos del GM
- protocolo de eventos internos
- estrategia de plugins o extensiones
- empaquetado para Windows, Android e iOS/iPadOS
