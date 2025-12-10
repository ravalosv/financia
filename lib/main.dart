import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'database/database_service.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'controllers/controllers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseService.initialize();
  
  // Initialize controllers
  Get.put(DatabaseService());
  Get.put(AuthController());
  Get.put(UserController());
  Get.put(TransactionController());
  Get.put(CategoryController());
  Get.put(AccountController());
  Get.put(BudgetController());
  Get.put(GoalController());
  Get.put(DashboardController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Financia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      locale: const Locale('es', 'MX'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
