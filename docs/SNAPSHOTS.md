# Snapshots y restauración SQLite

Estado: implementado y validado en CI.

## Objetivo

Rolemaster debe poder crear puntos de recuperación consistentes de toda la campaña local y restaurarlos sin depender de la UI, IA, voz o servicios externos.

El snapshot es una base SQLite completa. Incluye en una única copia coherente:

- campañas y configuración;
- mundos, regiones y localizaciones;
- calendarios, timeline y eventos temporales;
- historial de eventos de dominio;
- revisión autoritativa del State Manager.

## Implementación

La implementación vive en `SqliteSnapshotService` dentro de `rolemaster_storage_sqlite`.

No se hace una copia directa del archivo de base mientras puede estar activo. Se utiliza la API de backup de SQLite expuesta por `package:sqlite3`, copiando la conexión origen hacia una base destino.

### Crear snapshot

Flujo:

1. Verificar que origen y destino sean rutas diferentes.
2. Rechazar la operación si el snapshot de destino ya existe.
3. Abrir el origen y llevarlo al esquema SQLite soportado actualmente.
4. Crear la base destino.
5. Ejecutar SQLite backup.
6. Validar el snapshot resultante.
7. Eliminar cualquier copia parcial si la operación falla.

Los snapshots son inmutables desde este servicio: una ruta de snapshot existente nunca se sobrescribe.

## Validación

Antes de aceptar o restaurar un snapshot se comprueba:

- que el archivo exista;
- que `user_version` corresponda a un esquema Rolemaster soportado;
- que no sea una versión futura desconocida;
- que exista la tabla canónica `campaigns`;
- `PRAGMA integrity_check`;
- `PRAGMA foreign_key_check`.

La restauración puede aceptar un snapshot de una versión histórica soportada. Una vez copiado al destino, las migraciones secuenciales lo llevan al esquema actual antes de considerarlo restaurado correctamente.

## Restauración segura

Si ya existe una base activa en la ruta destino, el orden es:

1. Validar completamente el snapshot solicitado.
2. Crear un snapshot inmutable del estado actual con sufijo `pre-restore`.
3. Sólo después de tener esa copia, retirar los archivos SQLite de destino (`db`, `-wal`, `-shm`).
4. Restaurar el snapshot mediante SQLite backup.
5. Ejecutar migraciones soportadas hasta el esquema actual.
6. Ejecutar nuevamente las validaciones de integridad y claves foráneas.
7. Conservar el snapshot pre-restore como punto explícito de rollback.

Si la restauración falla después de retirar el destino, el servicio intenta reconstruir automáticamente la base desde el snapshot pre-restore.

## Contrato operativo

### Creación

La creación de snapshots puede realizarse sobre una base SQLite abierta, usando el mecanismo de backup de SQLite para obtener una copia coherente.

### Restauración

Antes de restaurar, la capa de aplicación debe cerrar los repositorios y conexiones Rolemaster que apunten a la base destino. La restauración reemplaza el estado autoritativo de esa base y no debe competir con conexiones que continúen escribiendo sobre ella.

Esta restricción debe resolverse en la futura coordinación de sesión/aplicación, no dentro del dominio puro.

## API actual

`SqliteSnapshotService` expone:

- `createSnapshot(...)`;
- `validateSnapshot(...)`;
- `restoreSnapshot(...)`.

Los resultados incluyen ruta, versión de esquema, tamaño del snapshot y, en restauración, la ruta del snapshot pre-restore cuando corresponde.

## Cobertura de pruebas

La suite valida actualmente:

- creación y reapertura de un snapshot completo;
- inmutabilidad respecto de mutaciones posteriores de la base viva;
- restauración de Campaign, Event History y Campaign State;
- conservación de la copia pre-restore;
- rechazo de archivos que no son bases SQLite válidas;
- rechazo de esquemas futuros no soportados.

## Evolución prevista

Más adelante pueden agregarse sin modificar el Core de campaña:

- política de retención automática;
- nombres y etiquetas de snapshots;
- exportación/importación de bundles;
- compresión;
- cifrado opcional;
- selección de ubicación desde la UI;
- sincronización opcional entre dispositivos del mismo GM.
