# Auditoría de Backend/Core previa al Freeze

Actualizada: 2026-09-29. Esta auditoría separa capacidades probadas de trabajo pendiente; no declara el Freeze.

## Verificación ejecutada

En los runs de GitHub Actions `36567081693` y `36568000053` pasaron Core Dart, SQLite storage, Flutter app, build Windows y build Android. SQLite ejecutó los tres benchmarks.

## Estado por contrato

### Ruleset y campaña

- Los paquetes publicados son inmutables por `rulesetId + version`.
- El binding de campaña fija ID, versión y módulos.
- El caso `MigrateCampaignRuleset` valida campaña no archivada, origen esperado, versión destino publicada, sistema/ID estables y módulos requeridos.
- SQLite hace el cambio del binding en una transacción y compara la versión de overlay leída; rechaza encuentros activos y escrituras concurrentes.
- Un overlay no vacío requiere un transformador explícito y validación de claves superiores contra el paquete destino.

**4.5C completada:** el flujo acepta mapeos explícitos de habilidades y definiciones de objetos, valida destinos en los módulos activos y actualiza esas referencias junto al binding dentro de una transacción SQLite. Las pruebas cubren la migración exitosa, el rollback si falta un destino, el rollback ante un fallo tardío al actualizar el binding y la preservación de referencias históricas.

Las estadísticas, condiciones y acciones están guardadas dentro de snapshots de combate que conservan `rulesetId + rulesetVersion`. Como la migración bloquea encuentros activos, esos snapshots pertenecen a combates cerrados y se mantienen ligados a su Ruleset original; no se traducen ni se reescriben al cambiar la versión de la campaña.

### Extensibilidad de reglas

- `ResolutionEngine` recibe intérpretes inyectables y despacha reglas por `kind`, lo que permite agregar tipos de regla sin modificar el motor.
- El registro rechaza intérpretes con `kind` duplicado y devuelve errores trazables ante reglas sin intérprete.
- Las pruebas cubren despacho de un intérprete personalizado, tipo desconocido, duplicados y trazas de tiradas ajenas al Ruleset.

La extensibilidad del motor queda completada. Los proveedores de servicios opcionales siguen desactivados; sus contratos no representan integraciones funcionales.

**Pendiente antes del Freeze:** errores capturados en límites del Core y conversión de filas, integración de SQLite en la app, y auditoría final de contratos y errores.

### SQLite, recuperación y diagnóstico

- Las migraciones de esquema están versionadas y pasan la suite completa del paquete SQLite.
- Los snapshots comprueban `integrity_check`, `foreign_key_check`, esquema Rolemaster y versión soportada.
- La restauración crea una copia previa y prueba recuperación ante un snapshot inválido.
- `SqliteDatabaseDiagnostics` abre la base en solo lectura e informa versión, integridad, referencias y presencia de esquema.
- Snapshot y restore emiten logs estructurados con metadatos operativos; no registran contenido de campaña.
- Todas las conexiones de repositorio SQLite adjuntan un observador tras inicializar el esquema. Registra recuentos por tabla/operación al confirmar o revertir transacciones, sin IDs de fila, SQL, parámetros ni valores de campaña. La app registra también los errores Flutter y de plataforma no controlados, con tipo y stack trace, sin mensaje de excepción; sus handlers tienen pruebas en CI.
- Las lecturas y escrituras SQL de repositorios registran errores con tipo de operación y excepción, sin SQL, parámetros, rutas, mensajes ni valores de campaña. La excepción original se conserva aunque falle el logger (PR #19).

**Coordinación parcial:** `SqliteApplicationCoordinator` registra los repositorios que abre, bloquea aperturas durante el restore y cierra las conexiones registradas al destino antes de reemplazar los archivos. Una prueba restaura con dos repositorios abiertos y comprueba la reapertura. No gestiona conexiones abiertas fuera de él. La Visual Alpha aún usa repositorios en memoria; cuando la app adopte SQLite debe abrirlos mediante este coordinador (PR #18).

### Servicios opcionales

- Core expone contratos de IA, sugerencias para NPC, STT/TTS y Audio Director.
- Los proveedores desactivados permiten respuesta neutral sin red ni credenciales.
- Proveedores reales e integración de UI siguen pendientes y son optativos.

### Rendimiento y plataformas

- CI ejecuta tres escenarios: 500 escrituras y 500 lecturas puntuales de campañas; 500 eventos append-only y una lectura completa del historial; 200 revisiones secuenciales de estado de combate y una lectura del snapshot final. Cada escenario usa una ronda de calentamiento y tres medidas; el resultado informa medianas y metadatos del runner.
- Tres muestras de CI comparables (Linux x64, Dart 3.13.4, 4 procesadores; cada run informa medianas de tres rondas): #371 (`36299065832`): campañas 440126/10501 µs, historial 477712/2717 µs, combate 193612/97 µs; #372 (`36299261005`): 340099/18934 µs, 359959/4036 µs, 136130/127 µs; #374 (`36299715305`): 400270/19936 µs, 397736/2840 µs, 162229/128 µs (escritura/lectura por escenario). Referencia consolidada —mediana de los tres valores por escenario—: campañas 400270/18934 µs, historial 397736/2840 µs y combate 162229/127 µs. Son referencias de runners, no objetivos para usuarios.
- Tres muestras posteriores comparables (Linux x64, Dart 3.13.5, 4 procesadores): `36566471037`, `36567081693` y `36568000053`. Referencia consolidada por escenario, escritura/lectura: campañas 460256/26498 µs, historial 505345/3951 µs y combate 190751/124 µs. La lectura de campañas osciló entre 15468 y 29637 µs; son mediciones de runners y no objetivos para usuarios.
- Umbral informativo de investigación: revisar una regresión si la mediana comparable supera 2× la referencia estable en tres ejecuciones consecutivas del mismo SO/runtime. Las tres muestras de Dart 3.13.5 no muestran una regresión sostenida; el umbral sigue sin bloquear CI y se recalibra si cambia el runner.
- CI genera los runners Windows/Android en directorios de trabajo y compila ambos destinos. No hay configuración nativa específica comprometida al repositorio.

## Bloqueos para Backend/Core Freeze

1. Auditar errores de conversión de filas y límites del Core que se capturan y manejan localmente. Las consultas SQLite y los errores no controlados de Flutter/plataforma ya se registran sin contenido de campaña.
2. Integrar SQLite en el ciclo de vida de la app mediante el coordinador probado; Visual Alpha aún usa repositorios en memoria.
3. Cerrar los contratos de servicios y errores antes del tag de Freeze.

Hasta cerrar estos puntos, la fase gráfica definitiva sigue detrás de la puerta del Freeze.
