# Auditoría de Backend/Core previa al Freeze

Fecha: 2026-09-25. Esta auditoría separa capacidades probadas de trabajo pendiente; no declara el Freeze.

## Verificación ejecutada

En el run de GitHub Actions `36183374729` pasaron Core Dart, SQLite storage, Flutter app, build Windows y build Android. SQLite ejecutó además un benchmark informativo.

## Estado por contrato

### Ruleset y campaña

- Los paquetes publicados son inmutables por `rulesetId + version`.
- El binding de campaña fija ID, versión y módulos.
- El caso `MigrateCampaignRuleset` valida campaña no archivada, origen esperado, versión destino publicada, sistema/ID estables y módulos requeridos.
- SQLite hace el cambio del binding en una transacción y compara la versión de overlay leída; rechaza encuentros activos y escrituras concurrentes.
- Un overlay no vacío requiere un transformador explícito y validación de claves superiores contra el paquete destino.

**4.5C completada:** el flujo acepta mapeos explícitos de habilidades y definiciones de objetos, valida destinos en los módulos activos y actualiza esas referencias junto al binding dentro de una transacción SQLite. Las pruebas cubren la migración, el rollback si falta un destino y la preservación de referencias históricas.

Las estadísticas, condiciones y acciones están guardadas dentro de snapshots de combate que conservan `rulesetId + rulesetVersion`. Como la migración bloquea encuentros activos, esos snapshots pertenecen a combates cerrados y se mantienen ligados a su Ruleset original; no se traducen ni se reescriben al cambiar la versión de la campaña.

**Pendiente antes del Freeze:** logging operativo general del Core y repositorios, objetivos y escenarios de benchmark representativos, coordinación de restore frente a conexiones vivas, y auditoría final de contratos y errores.

### SQLite, recuperación y diagnóstico

- Las migraciones de esquema están versionadas y pasan la suite completa del paquete SQLite.
- Los snapshots comprueban `integrity_check`, `foreign_key_check`, esquema Rolemaster y versión soportada.
- La restauración crea una copia previa y prueba recuperación ante un snapshot inválido.
- `SqliteDatabaseDiagnostics` abre la base en solo lectura e informa versión, integridad, referencias y presencia de esquema.
- Snapshot y restore emiten logs estructurados con metadatos operativos; no registran contenido de campaña.

**Limitación operativa:** la capa de aplicación debe cerrar conexiones al destino antes de restaurar. La coordinación de sesión todavía no lo impone.

### Servicios opcionales

- Core expone contratos de IA, sugerencias para NPC, STT/TTS y Audio Director.
- Los proveedores desactivados permiten respuesta neutral sin red ni credenciales.
- Proveedores reales e integración de UI siguen pendientes y son optativos.

### Rendimiento y plataformas

- CI ejecuta un benchmark repetible de 500 altas y 500 lecturas de Campaign Repository, con una ronda de calentamiento y tres medidas.
- La medición es una referencia del runner; no mide carga de sesión, combate, sincronización ni dispositivos finales.
- CI genera los runners Windows/Android en directorios de trabajo y compila ambos destinos. No hay configuración nativa específica comprometida al repositorio.

## Bloqueos para Backend/Core Freeze

1. Diseñar y probar la migración de referencias de datos de campaña entre versiones de Ruleset.
2. Definir logging operativo para repositorios y errores del Core, más allá de snapshots.
3. Acordar escenarios y objetivos de benchmark representativos; medirlos y conservar una referencia comparable.
4. Auditar restore frente a conexiones vivas y cerrar esa brecha en la coordinación de aplicación.
5. Cerrar los contratos de servicios y errores antes del tag de Freeze.

Hasta cerrar estos puntos, la fase gráfica definitiva sigue detrás de la puerta del Freeze.
