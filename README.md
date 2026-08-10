# Rolemaster

Rolemaster es un VTT y motor de campaña independiente, diseñado para gestionar partidas, mundo persistente, personajes, NPC, reglas, calendario, eventos, audio e inteligencia artificial opcional.

## Principios del proyecto

1. **Independiente por diseño**: Rolemaster no depende de Fantasy Grounds ni de otro VTT.
2. **Referencias, no dependencias**: Fantasy Grounds Unity y otros VTT pueden servir como referencia de arquitectura, diagramación y experiencia visual.
3. **Core sin IA obligatoria**: todas las funciones esenciales deben funcionar con la IA desactivada.
4. **IA intercambiable**: la IA integrada será la opción por defecto, pero el usuario podrá usar proveedores propios, modelos locales o desactivarla.
5. **Arquitectura modular**: campaña, mundo, reglas, personajes, NPC, combate, calendario, eventos, audio e IA deben mantenerse desacoplados.
6. **Fuente de verdad propia**: los datos de campaña y estado del mundo pertenecen a Rolemaster.

## Estado

Proyecto iniciado el 10 de agosto de 2026.

La primera etapa es definir la arquitectura base y los límites entre módulos antes de seleccionar e implementar el stack definitivo.

## Documentación

- `docs/ARCHITECTURE.md`: arquitectura inicial y límites del sistema.
- `docs/ROADMAP.md`: etapas iniciales de desarrollo.
