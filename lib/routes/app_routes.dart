import 'package:get/get.dart';
import '../views/splash_screen.dart';
import '../views/onboarding_screen.dart';
import '../views/login_screen.dart';
import '../views/register_screen.dart';
import '../views/dashboard_screen.dart';
import '../views/categories_screen.dart';
import '../views/transactions_screen.dart';
import '../views/accounts_screen.dart';
import '../views/category_expense_detail_screen.dart';
import '../views/settings_screen.dart';
import '../views/database_viewer_screen.dart';
import '../views/cards_screen.dart';
import '../views/recurring_payments_screen.dart';
import '../views/account_statement_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String payment = '/payment';
  static const String dashboard = '/dashboard';
  static const String addTransaction = '/transaction/add';
  static const String transactionList = '/transaction/list';
  static const String categories = '/categories';
  static const String accounts = '/accounts';
  static const String categoryExpenseDetail = '/reports/category-expense';
  static const String budgets = '/budgets';
  static const String reports = '/reports';
  static const String goals = '/goals';
  static const String import = '/import';
  static const String ocr = '/ocr';
  static const String aiChat = '/ai-chat';
  static const String settings = '/settings';
  static const String dbViewer = '/db-viewer';
  static const String cards = '/cards';
  static const String recurringPayments = '/recurring-payments';
  static const String accountStatement = '/account-statement';

  static final List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: dashboard, page: () => const DashboardScreen()),
    GetPage(name: categories, page: () => const CategoriesScreen()),
    GetPage(name: transactionList, page: () => const TransactionsScreen()),
    GetPage(name: accounts, page: () => const AccountsScreen()),
    GetPage(
      name: categoryExpenseDetail,
      page: () => const CategoryExpenseDetailScreen(),
    ),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(name: dbViewer, page: () => const DatabaseViewerScreen()),
    GetPage(name: cards, page: () => const CardsScreen()),
    GetPage(
      name: recurringPayments,
      page: () => const RecurringPaymentsScreen(),
    ),
    GetPage(
      name: accountStatement,
      page: () => const AccountStatementScreen(),
    ),
  ];
}
