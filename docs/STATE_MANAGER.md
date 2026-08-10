# Rolemaster — State Manager

## Objetivo

`StateManager` coordina mutaciones autoritativas de una campaña sin duplicar en memoria el estado que pertenece a Campaign, World, Calendar u otros dominios.

Sus responsabilidades son:

- secuenciar mutaciones por campaña;
- validar todos los cambios antes de aplicar el primero;
- mantener una revisión monotónica por campaña;
- detectar revisiones obsoletas;
- ejecutar rollback lógico en orden inverso cuando una mutación falla;
- impedir que dos instancias guarden exitosamente sobre la misma revisión;
- dejar la persistencia concreta detrás de `CampaignStateRepository`.

## Revisión autoritativa

Una campaña comienza conceptualmente en revisión `0`.

Cada transacción exitosa avanza exactamente una revisión:

```text
0 → 1 → 2 → 3 → ...
```

La transacción declara `expectedRevision`. Antes de aplicar cambios, `StateManager` compara esa revisión con el estado actual.

La persistencia vuelve a comparar la revisión al guardar mediante compare-and-swap (CAS). Esta segunda comparación es obligatoria: un lock local no protege contra otra instancia o un futuro segundo dispositivo del GM.

## Transacción

```text
StateTransaction
├── campaignId
├── expectedRevision
├── changedAt
└── changes[]
```

Cada `StateChange` implementa:

```text
validate()
apply()
rollback()
```

Flujo:

```text
leer revisión actual
        ↓
comparar expectedRevision
        ↓
validar TODOS los cambios
        ↓
aplicar cambios en orden
        ↓
guardar nueva revisión con CAS
        ↓
éxito
```

Si `apply()` o la persistencia falla:

```text
fallo
  ↓
rollback de cambios invocados
  ↓
orden inverso
```

Los fallos de rollback se conservan dentro de `StateTransactionException` y no ocultan la causa original.

## Concurrencia

Hay dos defensas distintas.

### Una instancia

`StateManager` evita dos transacciones simultáneas sobre la misma campaña dentro de su propia instancia.

### Varias instancias

`CampaignStateRepository.save(... expectedRevision)` debe ser atómico.

Ejemplo:

```text
Instancia A lee revisión 7
Instancia B lee revisión 7

B guarda 8 → OK
A intenta guardar 8 esperando 7 → RECHAZADO
A ejecuta rollback lógico
```

De esta forma una futura tablet o teléfono del GM no puede sobrescribir silenciosamente un cambio realizado por otro dispositivo.

## SQLite

`SqliteCampaignStateRepository` guarda el estado autoritativo en `campaign_states` y usa operaciones condicionadas por revisión.

Actualmente la tabla se crea de manera idempotente por el adaptador mientras se termina de consolidar el versionado global de esquema. Antes del cierre de persistencia/backup, esta tabla debe quedar incorporada formalmente a la siguiente migración central de SQLite.

## Regla arquitectónica

El State Manager no contiene reglas de Rolemaster, lógica de UI, IA, voz ni audio. Sólo coordina cambios de estado y sus garantías transaccionales.
