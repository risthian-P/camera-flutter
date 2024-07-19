# camara

A new Flutter project.

# Flutter Web App con Firebase Hosting

Esta guía cubre los pasos necesarios para configurar y desplegar una aplicación Flutter web que utiliza Firebase para almacenamiento.

## Requisitos previos

- [Flutter](https://flutter.dev/docs/get-started/install) instalado
- [Firebase CLI](https://firebase.google.com/docs/cli) instalado
- Cuenta en [Firebase](https://firebase.google.com/)

## Configuración del Proyecto

### Paso 1: Crear un nuevo proyecto Flutter

```
	flutter create my_flutter_app
	cd my_flutter_app  
```	

Paso 2: Habilitar el soporte webflutter config --enable-web
flutter create .

Paso 3: Añadir dependenciasEdita tu archivo pubspec.yaml y añade las siguientes dependencias:
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.5.0
  firebase_storage: ^11.0.0
  camera: ^0.10.0
  path_provider: ^2.0.14
  logger: ^1.1.0
Luego, ejecuta:
flutter pub get

##Configuración de Firebase
Paso 4: Crear un proyecto en FirebaseVe a la consola de Firebase.
Crea un nuevo proyecto.
Añade una aplicación web al proyecto y copia la configuración de Firebase.



