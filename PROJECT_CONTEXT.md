# Project Context: Financia

## 1. Objetivo del producto

`Financia` es una app Flutter de finanzas personales enfocada en:

- registrar ingresos, gastos y traspasos entre cuentas
- administrar cuentas y categorias
- mostrar resumen mensual e insights simples
- guardar datos de forma local, con foco en privacidad
- permitir backup/exportacion e importacion de datos

Objetivo real hoy:

- MVP/local-first para control financiero personal
- experiencia centrada en dashboard, transacciones, cuentas y categorias
- analitica basica con graficas y resumen mensual

Objetivo prometido en branding/copy pero no totalmente implementado:

- IA / AI-powered insights
- autenticacion biometrica
- cifrado real de datos
- compras dentro de la app
- modulos completos de presupuestos y metas en UI

## 2. Stack y decisiones base

- Framework: Flutter
- Lenguaje: Dart `^3.10.1`
- Estado y navegacion: `GetX`
- Persistencia principal usada por app: `Hive`
- Persistencia secundaria inicializada pero casi no usada en runtime: `sqflite`
- Graficas: `fl_chart`
- OCR de recibos: `google_mlkit_text_recognition` + `image_picker`
- Backup/import-export: `file_picker`

Decision arquitectonica dominante:

- app usa controladores globales de `GetX` como source of truth
- vistas leen/escriben directo contra controladores
- no hay capa separada de servicios de dominio / repositorios
- `DatabaseService` mezcla bootstrap, acceso a Hive, SQLite y utilidades de import/export

## 3. Estructura de carpetas

- `lib/main.dart`: arranque, inicializacion de DB y registro global de controladores
- `lib/controllers/`: logica de negocio y estado observable
- `lib/models/`: entidades de negocio y serializacion Hive/JSON
- `lib/views/`: pantallas principales
- `lib/routes/`: rutas de navegacion GetX
- `lib/theme/`: tokens visuales y `ThemeData`
- `lib/database/`: servicio de persistencia local
- `lib/utils/`: helpers

Estructura actual es "feature-lite by layer", no "feature-first".

## 4. Flujo principal de la app

1. `main.dart` inicializa `DatabaseService`.
2. Registra controladores con `Get.put(...)`.
3. App abre en `SplashScreen`.
4. `SplashScreen` revisa `AuthController.isAuthenticated`.
5. Si hay usuario en Hive, navega a dashboard.
6. Si no hay usuario, navega a onboarding y luego login/register.

Nota importante:

- autenticacion es local y simplificada
- login/register no validan password real contra hash/cifrado
- se toma primer usuario existente o match por email

## 5. Modulos reales

### Implementados y visibles en UI

- Splash
- Onboarding
- Login / Register
- Dashboard
- Cuentas
- Categorias
- Transacciones
- Traspasos entre cuentas
- OCR basico de recibos desde dashboard
- Configuracion de moneda base
- Exportacion / importacion JSON
- Visor de base de datos/local data

### Implementados en codigo pero con exposicion parcial o nula

- Presupuestos (`BudgetController`)
- Metas (`GoalController`)
- Alertas e indicadores de salud financiera
- Export de dashboard/budgets

### Declarados en rutas/branding pero no conectados de forma real

- `payment`
- `budgets`
- `reports`
- `goals`
- `import`
- `ocr`
- `aiChat`
- forgot password
- biometria
- cifrado efectivo de datos
- IA remota/local

## 6. Patrones de codigo

## Estado

- `Rx<T>` y `.obs` para estado reactivo
- `Obx` en vistas para refrescar UI
- controladores singleton globales
- watchers con `ever(...)` en dashboard para recomputar metricas

## Navegacion

- `GetMaterialApp`
- rutas nombradas en `AppRoutes`
- navegacion directa con strings o `AppRoutes.*`

## Persistencia

- Hive guarda entidades reales consumidas por app
- SQLite crea tablas e indices, pero flujo principal no consulta esas tablas para pantallas
- existe duplicidad conceptual Hive/SQLite

## Modelado

- modelos con `copyWith`, `toJson`, `fromJson`
- ids generados por helper
- transacciones son fuente principal para balances
- balances de cuentas se derivan, no se persisten como verdad final

## UI

- pantallas `StatefulWidget` con bastante logica local
- formularios modales via `showModalBottomSheet`
- listas CRUD con `Dismissible`
- tarjetas resumen con decoracion compartida

## 7. Look and feel

Estilo visual dominante:

- limpio, claro, blanco/gris suave
- Material 3
- tarjetas con sombra leve y esquinas redondeadas
- color coding financiero claro:
  - verde = ingreso/exito
  - rojo = gasto/error
  - azul = accion primaria / marca
  - ambar = advertencia

Sensacion de producto:

- dashboard-first
- utilitario / productivity
- no premium-luxury ni altamente branded
- mezcla de UX moderna con componentes Material estandar

Tokens centrales en `AppTheme`:

- `accentColor`: azul
- `incomeColor`: verde
- `expenseColor`: rojo
- `secondaryBackground`: gris muy claro
- `cardBorderRadius`: 12
- `buttonBorderRadius`: 8

Observaciones de consistencia visual:

- base de tema es coherente
- varias pantallas redefinen estilos localmente en vez de usar siempre `AppTheme`
- hay mezcla de copy en ingles y espanol
- branding y copy de marketing prometen mas de lo que la app hoy entrega

## 8. Pantallas clave y rol

### Dashboard

Es centro del producto. Muestra:

- filtro por cuenta
- navegacion por mes
- saldo inicial / final
- ingresos / gastos / flujo neto
- traspasos entrada/salida
- gasto por categoria con pie chart
- resumen por cuenta
- insights textuales
- transacciones recientes
- acceso a registro rapido y OCR

Notas:

- mucha logica vive dentro de la vista
- hay bloques comentados para presupuestos/metas y simulacion what-if

### Transacciones

- CRUD completo de ingresos/gastos
- filtros por cuenta, categoria, tipo y rango de fechas
- soporte para tipo de cambio manual cuando moneda de cuenta != moneda base
- manejo especial de traspasos como par de transacciones

### Cuentas

- CRUD con tipos base: cash, checking, savings, credit, investment
- switch para activar/desactivar
- balance derivado de transacciones

### Categorias

- categorias default precargadas
- CRUD de categorias custom
- separacion ingreso/egreso por tabs

### Settings

- cambia moneda base del usuario
- exporta/importa JSON
- abre visor interno de datos

## 9. Riesgos y deuda tecnica visibles

### 1. Duplicidad Hive + SQLite

- SQLite se inicializa y crea esquema
- UI/controladores operan sobre Hive
- riesgo de drift entre ambas fuentes
- futuras tareas deben decidir una verdad unica antes de ampliar persistencia

### 2. Auth simplificada

- password no se guarda ni valida de forma segura
- no hay sesion real ni cifrado
- login es mas bien seleccion local de usuario

### 3. Features prometidos pero no reales

- dependencias como `local_auth`, `encrypt`, `http`, `camera`, `in_app_purchase` no sostienen un flujo completo visible
- evitar asumir que ya existe biometria, IA o pagos

### 4. Vistas con demasiada logica

- `dashboard_screen.dart` y `transactions_screen.dart` concentran bastante logica de presentacion + negocio
- cambios grandes conviene moverlos a controlador/helper antes de seguir creciendo

### 5. Inconsistencia de idioma

- UI mezcla espanol e ingles
- decision futura recomendada: unificar a espanol o internacionalizar formalmente

### 6. Pruebas desactualizadas

- `test/widget_test.dart` sigue siendo test default de contador
- no refleja app real ni protege regresiones utiles

### 7. Rutas muertas o incompletas

- hay rutas/acciones apuntando a pantallas no registradas o no implementadas
- ejemplo: forgot password

## 10. Guia para futuras tareas

### Si vas a agregar UI nueva

- reusar tokens de `AppTheme`
- mantener cards limpias, spacing de 12/16/24 px
- usar color semantico financiero ya existente
- evitar introducir otro sistema visual paralelo

### Si vas a agregar logica nueva

- seguir patron actual: controlador GetX + modelo + vista
- preferir extraer logica pesada fuera de la vista si tocas dashboard/transacciones
- no meter mas responsabilidad en `DatabaseService` si puedes crear capa separada

### Si vas a tocar datos

- confirmar si feature vivira en Hive, SQLite o ambos
- hoy la app lee/escribe principalmente Hive
- si agregas reportes complejos, SQLite podria pasar a ser realmente util

### Si vas a tocar balances o moneda

- recordar que saldo se deriva de transacciones
- recordar que existe `exchangeRate`
- cuenta seleccionada usa monto nominal; vista global suele convertir con `exchangeRate`

### Si vas a activar features prometidos

- revisar primero dependencias ya declaradas
- validar si conviene implementar o quitar del copy/README para alinear expectativa

## 11. Convenciones utiles

- ids: generados por helper
- traspaso:
  - salida = transaccion `expense` con categoria `transfer_out`
  - entrada = transaccion `income` con categoria `transfer_in`
- cuenta default y categorias default se crean si almacenamiento esta vacio
- moneda base del usuario afecta formateo y algunas conversiones

## 12. Recomendaciones de evolucion

### Corto plazo

- unificar copy a espanol
- eliminar rutas muertas o implementarlas
- reemplazar test default por tests de smoke reales
- documentar claramente que storage canonico hoy es Hive

### Mediano plazo

- extraer servicios/repositorios por dominio
- adelgazar `dashboard_screen.dart`
- decidir estrategia unica de persistencia
- exponer UI de budgets/goals o sacar promesa de onboarding/README

### Largo plazo

- auth real con credenciales seguras
- biometria real
- cifrado en reposo
- motor de insights/IA real
- i18n formal

## 13. Resumen ejecutivo

`Financia` hoy es una app local-first de finanzas personales con buen MVP visual para dashboard, transacciones, cuentas y categorias. La arquitectura es simple y funcional, basada en GetX + Hive, pero tiene deuda en separacion de responsabilidades, consistencia de idioma y alineacion entre roadmap prometido y funcionalidad real.

Usar este contexto como regla de oro:

- asumir que Hive manda
- asumir que dashboard es centro del producto
- asumir que balances se derivan de transacciones
- no asumir que IA, biometria, pagos o cifrado ya existen de verdad
