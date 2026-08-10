# Setup local en Windows

El script `bootstrap_windows.ps1` prepara un entorno local de Rolemaster con estos valores por defecto:

- Proyecto: `D:\Proyectos\Rolemaster`
- Flutter SDK estable: `D:\Tools\flutter`

## Qué automatiza

- verifica Git;
- crea las carpetas necesarias;
- instala Flutter estable mediante el repositorio oficial si no existe;
- agrega Flutter al `PATH` del usuario;
- clona o actualiza `Naweeh/rolemaster-` sin hacer `pull` si detecta cambios locales;
- habilita Windows y Android;
- genera los runners de Windows/Android;
- ejecuta `flutter pub get`, `flutter analyze`, análisis del Core y `flutter doctor -v`.

## Qué no instala automáticamente

Visual Studio con la carga de trabajo de C++ para escritorio y Android Studio/SDK son instalaciones grandes y con componentes seleccionables. El script las detecta mediante `flutter doctor` y no intenta modificarlas silenciosamente.

## Ejecución

Con el repositorio clonado:

```powershell
cd D:\Proyectos\Rolemaster
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\bootstrap_windows.ps1
```

Si todavía no existe la carpeta local, primero cloná:

```powershell
mkdir D:\Proyectos -Force
cd D:\Proyectos
git clone https://github.com/Naweeh/rolemaster-.git Rolemaster
cd Rolemaster
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\bootstrap_windows.ps1
```

Para usar otras carpetas:

```powershell
.\scripts\bootstrap_windows.ps1 -ProjectRoot 'C:\Proyectos\Rolemaster' -FlutterRoot 'C:\Tools\flutter'
```

## Después del diagnóstico

Cuando `flutter doctor -v` no marque bloqueos para Windows y `flutter devices` liste Windows:

```powershell
cd D:\Proyectos\Rolemaster\apps\rolemaster_app
flutter run -d windows
```
