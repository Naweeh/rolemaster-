# Rulesets versionados

## Objetivo

Rolemaster debe poder ejecutar campañas con distintas ediciones, versiones y combinaciones de manuales sin mezclar sus datos ni modificar retroactivamente campañas existentes.

## Regla principal

Un `RulesetPackage` publicado es inmutable.

Cada campaña guarda un `CampaignRulesetBinding` a una versión exacta y un `CampaignRulesOverlay` propio. Al inicializar una campaña, el overlay empieza limpio por defecto.

```text
RulesetPackage RM2 1.0.0 (inmutable)
        │
        ├── Campaña A → overlay propio
        ├── Campaña B → overlay limpio
        └── Campaña C → overlay propio
```

Los cambios hechos en una campaña nunca alteran el paquete base ni se propagan a otra campaña.

## Componentes

### RulesetManifest

Identifica de forma estable:

- sistema;
- edición;
- versión exacta;
- nombre visible;
- módulos disponibles;
- módulos obligatorios o activos por defecto;
- referencias a manuales de origen.

### RulesetPackage

Contiene el manifest y los datos normalizados del sistema: atributos, habilidades, profesiones, tablas, reglas de tirada, combate, objetos, magia u otras definiciones. Los datos deben ser JSON-safe e inmutables una vez publicado el paquete.

### CampaignRulesetBinding

Registra qué paquete y versión usa una campaña y qué módulos están activos.

Cambiar a otra edición o versión no debe sobrescribir silenciosamente este binding. Ese cambio se implementará como una migración de ruleset con preview, snapshot y confirmación del GM.

### CampaignRulesOverlay

Contiene únicamente cambios propios de la campaña, por ejemplo:

- house rules;
- tablas sobrescritas;
- reglas opcionales modificadas;
- ajustes de campaña.

Una campaña nueva recibe un overlay vacío. Restablecer reglas elimina el overlay, pero conserva el binding al ruleset seleccionado y no borra mundo, NPCs, personajes ni otros datos narrativos.

## Manuales

Los PDFs no serán la fuente de ejecución directa durante una partida. El flujo previsto es:

```text
PDF / manuales
      ↓
Ruleset Builder / importador
      ↓
extracción y normalización
      ↓
revisión del GM
      ↓
RulesetPackage versionado
      ↓
selección en campaña
```

Un conjunto puede combinar varios manuales, por ejemplo Core + Character Law + Arms Law + Spell Law + suplementos opcionales.

## Presets

Los presets serán una capa reutilizable separada del ruleset base. Nunca se aplicarán automáticamente al crear una campaña.

La creación de campaña ofrecerá conceptualmente:

- ruleset limpio — opción por defecto;
- preset guardado por el GM — elección explícita;
- importación de configuración desde otra campaña — elección explícita.

## Cambio de ruleset

Una campaña existente no cambiará de ruleset mediante un simple reemplazo destructivo. El flujo previsto es:

1. seleccionar nueva versión;
2. comparar schemas y definiciones;
3. clasificar datos compatibles, convertibles y no compatibles;
4. mostrar preview;
5. crear snapshot automático;
6. confirmar por el GM;
7. ejecutar migración;
8. validar integridad;
9. conservar rollback.

## Separación entre datos narrativos y reglas

Datos narrativos como identidad, historia, notas, NPCs, lugares o calendario no deben depender innecesariamente de una edición concreta.

Los datos derivados de reglas —atributos, skills, profesiones, bonificadores, ataques, defensas, tablas, efectos o fórmulas— deben referenciar definiciones del ruleset seleccionado.

Ejemplo futuro:

```text
RulesetPackage
   └── SkillDefinition

Character
   └── CharacterSkillState
          └── skillDefinitionId
```

La definición pertenece al ruleset; el progreso concreto pertenece a la campaña/personaje.

## Primera interfaz funcional

Una vez cerrada la persistencia inicial de Ruleset Foundation, se habilita una UI provisional funcional para:

1. crear campaña;
2. elegir sistema/edición/versión;
3. activar módulos;
4. confirmar ruleset limpio;
5. guardar y volver a abrir la campaña.

Esta UI será un instrumento de trabajo temprano y no sustituye el Backend/Core Freeze ni la fase gráfica definitiva.
