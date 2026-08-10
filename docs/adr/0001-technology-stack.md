# ADR-0001 — Stack tecnológico inicial

- Estado: Aceptado
- Fecha: 2026-08-10

## Contexto

Rolemaster es un asistente multiplataforma para el Director de Juego en mesas presenciales tradicionales. Debe funcionar en escritorio, tablet y móvil, priorizando operación local/offline. No habrá clientes obligatorios para jugadores.

La IA, voz, audio avanzado y servicios externos son capacidades opcionales y no deben ser dependencias del núcleo.

## Decisión

Se adopta inicialmente:

- Dart como lenguaje principal del dominio y lógica de aplicación.
- Flutter como framework de interfaz multiplataforma.
- Arquitectura local-first.
- SQLite como motor previsto de persistencia local.
- `rolemaster_core` como paquete Dart puro, sin dependencia de Flutter.
- La aplicación Flutter consumirá el Core mediante interfaces y casos de uso.
- IA, Speech-to-Text, Text-to-Speech, audio y sincronización serán adaptadores desacoplados.
- Windows será la plataforma primaria de desarrollo.
- Android/tablet será la segunda plataforma de validación.
- iOS/iPadOS se mantendrá como objetivo soportado, sujeto a disponibilidad de toolchain Apple para compilación y pruebas.

## Estructura inicial

```text
rolemaster-
├── apps/
│   └── rolemaster_app/       # UI Flutter y adaptadores de plataforma
├── packages/
│   └── rolemaster_core/      # dominio y casos de uso en Dart puro
└── docs/
    └── adr/
```

## Reglas de dependencia

```text
Flutter UI
    ↓
Application / Use Cases
    ↓
Rolemaster Core

Infrastructure adapters → implementan puertos del Core
```

El Core no puede importar Flutter, paquetes de UI, SDK de IA ni APIs específicas del sistema operativo.

## Consecuencias

Ventajas:

- una base de UI para escritorio, tablet y móvil;
- dominio portable y testeable;
- menor acoplamiento a proveedores externos;
- capacidad de reemplazar persistencia o servicios sin modificar reglas de juego;
- funcionamiento esencial sin conexión a Internet.

Costos:

- algunas capacidades de voz/audio pueden requerir adaptadores nativos por plataforma;
- la sincronización futura entre dispositivos deberá diseñarse como una capa adicional;
- el soporte iOS requerirá toolchain Apple para compilar y validar.

## Fuera de alcance inicial

- servidor cloud obligatorio;
- cuentas de jugadores;
- clientes de jugador;
- multijugador online;
- sincronización entre dispositivos en la primera iteración;
- IA obligatoria para funciones esenciales.
