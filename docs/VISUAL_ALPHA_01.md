# Visual Alpha 0.1 — Dungeons & Dragons manual

## Objetivo

Validar visualmente que Rolemaster puede cargar una versión de reglas estructurada desde un manual, asociarla de forma limpia a una campaña y hacer que la interfaz responda a los datos de ese Ruleset sin acoplar el Core a una edición concreta.

## Fuente

- Archivo: `DUNGEONS & DRAGONS.pdf`
- Google Drive file id: `187GRO_OjPS2d4Y9-zhugppVVAfxDx2-x`
- Tamaño observado: 215 páginas
- PDF maquetado en 2024 según metadata del archivo inspeccionado.

## Clasificación provisional

El documento no declara en portada una edición oficial concreta. Por su estructura y contenido se trata, para esta prueba, como una **compilación personalizada derivada de B/X**.

El índice combina un núcleo clásico de creación de personajes, clases, equipo, encuentros, combate, monstruos y tesoro con material adicional y house rules. Por ese motivo Rolemaster no etiqueta este paquete como 5e ni como una edición oficial pura.

Identificador técnico del paquete:

`dnd-bx-compilation-2024@0.1.0-manual-alpha`

## Datos estructurados en esta alpha

### Atributos

- STR — Strength
- INT — Intelligence
- WIS — Wisdom
- DEX — Dexterity
- CON — Constitution
- CHA — Charisma

### Clases

- Cleric — WIS — d6
- Fighter — STR — d8
- Magic-User — INT — d4
- Thief — DEX — d4
- Dwarf — STR — d8
- Elf — STR/INT — d6
- Halfling — DEX/STR — d6

La alpha también conserva requisitos básicos y restricciones resumidas de armadura/armas como datos estructurados, sin copiar descripciones extensas del manual.

### Alineamiento

- Law
- Neutrality
- Chaos

### Creación inicial

- Oro inicial: `3d6 × 10 gp`
- Armor Class sin armadura: `9`
- Menor AC representa mejor defensa en este Ruleset.

## Módulos del paquete de prueba

- `bx-core` — obligatorio
- `spells` — activo por defecto
- `monsters-treasure` — activo por defecto
- `house-rules-appendix` — opcional

## Regla de campaña

La campaña de Visual Alpha se crea con un `CampaignRulesetBinding` hacia esta versión exacta y con un `CampaignRulesOverlay` limpio.

No hereda cambios de otras campañas y el paquete base no se modifica.

## UI de la Visual Alpha

La pantalla inicial muestra:

- campaña de prueba limpia;
- edición/versión del Ruleset;
- navegación conceptual a Characters, NPCs, Creatures, Inventory, Locations y Maps;
- área central Map / Scene basada en el Core de Maps v13;
- panel lateral con atributos, clases, alineamientos y reglas iniciales del manual;
- acciones futuras de Events, Rolls, Audio y System como referencias visuales;
- layout adaptativo para anchos reducidos.

## Fuera de alcance de esta prueba

Todavía no se considera importado el manual completo. Quedan fuera deliberadamente:

- tablas completas de progreso por nivel;
- listas completas de equipo;
- tablas de combate;
- saving throws;
- spells completos;
- monsters completos;
- treasure y magic items completos;
- reglas de encuentros y combate ejecutables;
- house rules del apéndice;
- importador automático de PDF / Ruleset Builder.

Esos datos se incorporarán sobre contratos tipados y versionados, no copiando el PDF directamente dentro del estado de una campaña.

## Gate

Visual Alpha 0.1 debe mantener:

- Core Dart verde;
- SQLite verde;
- Flutter analyze verde;
- Flutter Web build verde.

El preview web es un artefacto de validación. No representa el diseño visual definitivo ni abre el Backend/Core Freeze.
