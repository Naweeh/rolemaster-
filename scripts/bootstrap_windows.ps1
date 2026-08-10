param(
  [string]$ProjectRoot = 'D:\Proyectos\Rolemaster',
  [string]$FlutterRoot = 'D:\Tools\flutter',
  [switch]$SkipPlatformGeneration
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Require-Command([string]$Name, [string]$Help) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name no esta disponible. $Help"
  }
}

Write-Step 'Validando unidad y herramientas base'
if (-not (Test-Path 'D:\')) {
  throw 'No existe la unidad D:. Ejecuta el script indicando -ProjectRoot y -FlutterRoot en una unidad disponible.'
}

Require-Command 'git' 'Instala Git for Windows antes de continuar.'

$projectParent = Split-Path -Parent $ProjectRoot
$flutterParent = Split-Path -Parent $FlutterRoot
New-Item -ItemType Directory -Force -Path $projectParent | Out-Null
New-Item -ItemType Directory -Force -Path $flutterParent | Out-Null

Write-Step 'Preparando Flutter estable'
$flutterBat = Join-Path $FlutterRoot 'bin\flutter.bat'
if (-not (Test-Path $flutterBat)) {
  if (Test-Path $FlutterRoot) {
    $items = Get-ChildItem -Force $FlutterRoot -ErrorAction SilentlyContinue
    if ($items.Count -gt 0) {
      throw "La carpeta $FlutterRoot existe pero no contiene un SDK Flutter valido. Revisala manualmente antes de continuar."
    }
  }

  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git $FlutterRoot
}

$flutterBin = Join-Path $FlutterRoot 'bin'
if ($env:Path -notlike "*$flutterBin*") {
  $env:Path = "$flutterBin;$env:Path"
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$flutterBin*") {
  $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $flutterBin } else { "$userPath;$flutterBin" }
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
  Write-Host "Flutter agregado al PATH del usuario: $flutterBin"
}

& $flutterBat --version

Write-Step 'Preparando repositorio Rolemaster'
if (-not (Test-Path $ProjectRoot)) {
  git clone https://github.com/Naweeh/rolemaster-.git $ProjectRoot
} elseif (-not (Test-Path (Join-Path $ProjectRoot '.git'))) {
  throw "$ProjectRoot ya existe pero no es un repositorio Git. No se modifico su contenido."
} else {
  Push-Location $ProjectRoot
  try {
    $dirty = git status --porcelain
    if ($dirty) {
      Write-Warning 'El repositorio local tiene cambios sin commit. No se ejecutara git pull para no tocar trabajo local.'
    } else {
      git pull --ff-only
    }
  } finally {
    Pop-Location
  }
}

Write-Step 'Habilitando plataformas objetivo'
& $flutterBat config --enable-windows-desktop --enable-android

$appRoot = Join-Path $ProjectRoot 'apps\rolemaster_app'
if (-not (Test-Path (Join-Path $appRoot 'pubspec.yaml'))) {
  throw "No se encontro apps\rolemaster_app\pubspec.yaml en $ProjectRoot"
}

if (-not $SkipPlatformGeneration) {
  Write-Step 'Generando runners Windows y Android'
  Push-Location $appRoot
  try {
    & $flutterBat create --platforms=windows,android .
  } finally {
    Pop-Location
  }
}

Write-Step 'Instalando dependencias Dart/Flutter'
Push-Location $appRoot
try {
  & $flutterBat pub get
  & $flutterBat analyze
} finally {
  Pop-Location
}

Write-Step 'Analizando Rolemaster Core'
$dartBat = Join-Path $FlutterRoot 'bin\dart.bat'
& $dartBat analyze (Join-Path $ProjectRoot 'packages\rolemaster_core')

Write-Step 'Diagnostico de toolchains'
& $flutterBat doctor -v

Write-Host "`nBootstrap terminado." -ForegroundColor Green
Write-Host "Proyecto: $ProjectRoot"
Write-Host "Flutter:  $FlutterRoot"
Write-Host "`nSi flutter doctor marca Visual Studio o Android toolchain como faltantes, instalalos y vuelve a ejecutar este script."
Write-Host "Cuando Windows aparezca en 'flutter devices', ejecuta:"
Write-Host "  cd $appRoot"
Write-Host "  flutter run -d windows"
