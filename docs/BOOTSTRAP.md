# Bootstrap de desarrollo

## Estado de este corte

El repositorio ya contiene:

- `packages/rolemaster_core`: paquete Dart puro con el primer dominio `Campaign`.
- `apps/rolemaster_app`: fuente inicial de la aplicación Flutter.
- un repositorio de campañas en memoria usado sólo para validar el desacoplamiento entre UI y Core.

Todavía no se agregó SQLite ni se generaron los runners nativos de Windows/Android/iOS. Eso se hará desde una instalación real de Flutter para evitar versionar archivos generados por una toolchain distinta a la que use el proyecto.

## Próximo bootstrap local

En la máquina de desarrollo:

1. Instalar Flutter estable y sus herramientas para Windows/Android.
2. Ejecutar `flutter doctor` y resolver los requisitos de la plataforma primaria.
3. Clonar `Naweeh/rolemaster-`.
4. Generar los runners nativos de la app preservando la fuente existente.
5. Ejecutar análisis estático del Core y de la app.
6. Levantar primero Windows y luego Android/tablet.

No ejecutar una regeneración destructiva del proyecto sobre `apps/rolemaster_app` sin revisar antes el diff.

## Primer criterio de aceptación

La primera validación funcional será:

```text
Abrir Rolemaster
→ crear campaña
→ verla en la lista
→ cerrar
→ agregar persistencia SQLite
→ reabrir
→ verificar que la campaña continúa disponible
```

El adaptador en memoria actual cubre sólo los tres primeros pasos y será reemplazado por persistencia local sin modificar `rolemaster_core`.
