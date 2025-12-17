# DAL App - Aplicación de Gestión de Equipos

Aplicación Flutter para gestión de equipos y rentas.

## 🚀 Características

- ✅ Autenticación con login simulado (preparado para API REST)
- ✅ Persistencia de sesión con SharedPreferences
- ✅ Navegación con 4 tabs principales: Inicio, Equipos, Renta, Configuración
- ✅ Gestión de estado con Riverpod
- ✅ Routing con GoRouter
- ✅ Arquitectura Feature-First escalable
- ✅ Tema personalizado con Material Design 3

## 📁 Estructura del Proyecto

```
lib/
├── core/                      # Funcionalidades core de la app
│   ├── router/               # Configuración de rutas
│   │   └── app_router.dart
│   ├── theme/                # Tema de la aplicación
│   │   └── app_theme.dart
│   └── constants/            # Constantes globales
│       └── app_constants.dart
│
├── features/                 # Características de la app (Feature-first)
│   ├── auth/                # Autenticación
│   │   ├── models/
│   │   ├── providers/
│   │   ├── repositories/
│   │   └── presentation/
│   │       └── screens/
│   ├── home/                # Pantalla principal
│   ├── equipos/             # Gestión de equipos
│   ├── renta/               # Gestión de rentas
│   └── configuracion/       # Configuración de la app
│
├── shared/                   # Componentes compartidos
│   └── widgets/
│
└── main.dart                # Punto de entrada de la app
```

## 🔐 Credenciales de Prueba

Para probar la aplicación, usa estas credenciales:

- **Email**: `admin@test.com`
- **Contraseña**: `123456`

## 🛠️ Tecnologías Utilizadas

- **Flutter**: 3.38.5
- **Dart**: 3.10.4
- **Riverpod**: 2.6.1 - Gestión de estado
- **GoRouter**: 14.6.2 - Navegación
- **SharedPreferences**: 2.3.3 - Persistencia local
- **Dio**: 5.7.0 - Cliente HTTP (preparado para API)

## 📦 Instalación

1. Clona el repositorio
2. Instala las dependencias:
```bash
flutter pub get
```

3. Ejecuta la aplicación:
```bash
flutter run
```

## 🔌 Integración con API REST (Futuro)

La aplicación está preparada para integración con un backend REST API. Para implementarlo:

1. Abre `lib/core/constants/app_constants.dart`
2. Cambia `baseUrl` a la URL de tu API
3. En `lib/features/auth/repositories/auth_repository.dart` está comentado el código para implementar el login con API real
4. Descomenta y adapta según tu API

### Ejemplo de implementación con API:

```dart
Future<Map<String, dynamic>> loginWithAPI(String email, String password) async {
  final dio = Dio();
  final response = await dio.post(
    '${AppConstants.baseUrl}${AppConstants.loginEndpoint}',
    data: {
      'email': email,
      'password': password,
    },
  );
  
  if (response.statusCode == 200) {
    final userData = response.data;
    // Guardar sesión...
    return userData;
  }
  throw Exception('Error en el login');
}
```

## 🎨 Personalización

### Cambiar colores del tema:
Edita `lib/core/theme/app_theme.dart`

### Agregar nuevas rutas:
Edita `lib/core/router/app_router.dart`

### Agregar nuevas features:
Crea una nueva carpeta en `lib/features/` siguiendo la estructura:
```
nueva_feature/
├── models/
├── providers/
├── repositories/
└── presentation/
    └── screens/
```

## 📱 Pantallas

1. **Login**: Autenticación de usuarios
2. **Inicio**: Dashboard con estadísticas
3. **Equipos**: Listado y gestión de equipos
4. **Renta**: Gestión de rentas activas, completadas y pendientes
5. **Configuración**: Perfil y ajustes de la app

## 🚧 Próximos Pasos

- [ ] Implementar integración con API REST real
- [ ] Agregar formularios de creación/edición de equipos
- [ ] Implementar sistema de notificaciones
- [ ] Agregar filtros y búsqueda avanzada
- [ ] Implementar reportes y estadísticas
- [ ] Agregar soporte multi-idioma

## 📝 Notas de Desarrollo

### Agregar nuevos componentes:

Para mantener la arquitectura limpia, sigue estos pasos:

1. **Nuevos widgets compartidos**: Agregar en `lib/shared/widgets/`
2. **Nuevas pantallas**: Crear dentro del feature correspondiente
3. **Nuevos providers**: Crear en la carpeta `providers` del feature
4. **Nuevos modelos**: Crear en la carpeta `models` del feature

### Ejecutar código generation (si usas freezed/json_serializable):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 👥 Contribución

Este es un proyecto en desarrollo. Para agregar nuevas características, sigue la estructura existente y las mejores prácticas de Flutter.

---

**Versión**: 1.0.0
**Última actualización**: Diciembre 2025
