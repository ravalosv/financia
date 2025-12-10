import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static const String _databaseName = 'financia.db';
  static const int _databaseVersion = 1;

  static const String usersBox = 'users';
  static const String accountsBox = 'accounts';
  static const String categoriesBox = 'categories';
  static const String transactionsBox = 'transactions';
  static const String budgetsBox = 'budgets';
  static const String goalsBox = 'goals';
  static const String receiptsBox = 'receipts';

  static sql.Database? _database;
  static bool _hiveInitialized = false;

  // Initialize both Hive and SQLite
  static Future<void> initialize() async {
    await _initHive();
    await _initSQLite();
  }

  // Initialize Hive for key-value storage
  static Future<void> _initHive() async {
    if (_hiveInitialized) return;

    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(ReceiptAdapter());

    // Open all boxes
    await Hive.openBox<User>(usersBox);
    await Hive.openBox<Account>(accountsBox);
    await Hive.openBox<Category>(categoriesBox);
    await Hive.openBox<Transaction>(transactionsBox);
    await Hive.openBox<Budget>(budgetsBox);
    await Hive.openBox<Goal>(goalsBox);
    await Hive.openBox<Receipt>(receiptsBox);

    _hiveInitialized = true;
  }

  // Initialize SQLite for complex queries
  static Future<void> _initSQLite() async {
    if (_database != null) return;

    _database = await sql.openDatabase(
      join(await sql.getDatabasesPath(), _databaseName),
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Create SQLite tables
  static Future<void> _onCreate(sql.Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        currency TEXT DEFAULT 'USD',
        biometric_enabled BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('cash', 'checking', 'savings', 'credit', 'investment')),
        currency TEXT NOT NULL,
        balance DECIMAL(15,2) DEFAULT 0.00,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        icon TEXT DEFAULT 'category',
        color TEXT DEFAULT '#6B7280',
        budget_limit DECIMAL(15,2),
        is_custom BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        transaction_date DATE NOT NULL,
        description TEXT,
        merchant TEXT,
        is_recurring BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        month_year TEXT NOT NULL,
        spent DECIMAL(15,2) DEFAULT 0.00,
        remaining DECIMAL(15,2) DEFAULT 0.00,
        rollover_from_previous DECIMAL(15,2) DEFAULT 0.00,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
        UNIQUE(user_id, category_id, month_year)
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_amount DECIMAL(15,2) NOT NULL,
        current_amount DECIMAL(15,2) DEFAULT 0.00,
        target_date DATE,
        category TEXT,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Receipts table
    await db.execute('''
      CREATE TABLE receipts (
        id TEXT PRIMARY KEY,
        transaction_id TEXT,
        image_path TEXT NOT NULL,
        extracted_text TEXT,
        confidence_score DECIMAL(5,2),
        processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for performance
    await db.execute(
      'CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_account ON transactions(account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_budgets_user_month ON budgets(user_id, month_year DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_goals_user_active ON goals(user_id, is_active)',
    );
    await db.execute(
      'CREATE INDEX idx_categories_user_type ON categories(user_id, type)',
    );
  }

  // Get SQLite database instance
  static Future<sql.Database> get database async {
    if (_database == null) {
      await _initSQLite();
    }
    return _database!;
  }

  // Close database connections
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    if (_hiveInitialized) {
      await Hive.close();
      _hiveInitialized = false;
    }
  }

  // Clear all data
  static Future<void> clearAll() async {
    await Hive.box<User>(usersBox).clear();
    await Hive.box<Account>(accountsBox).clear();
    await Hive.box<Category>(categoriesBox).clear();
    await Hive.box<Transaction>(transactionsBox).clear();
    await Hive.box<Budget>(budgetsBox).clear();
    await Hive.box<Goal>(goalsBox).clear();
    await Hive.box<Receipt>(receiptsBox).clear();

    final db = await database;
    await db.delete('users');
    await db.delete('accounts');
    await db.delete('categories');
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('goals');
    await db.delete('receipts');
  }

  // Hive box getters
  static Box<User> getUsersBox() => Hive.box<User>(usersBox);
  static Box<Account> getAccountsBox() => Hive.box<Account>(accountsBox);
  static Box<Category> getCategoriesBox() => Hive.box<Category>(categoriesBox);
  static Box<Transaction> getTransactionsBox() =>
      Hive.box<Transaction>(transactionsBox);
  static Box<Budget> getBudgetsBox() => Hive.box<Budget>(budgetsBox);
  static Box<Goal> getGoalsBox() => Hive.box<Goal>(goalsBox);
  static Box<Receipt> getReceiptsBox() => Hive.box<Receipt>(receiptsBox);

  // Instance CRUD helpers using Hive
  Future<List<Transaction>> getAllTransactions() async {
    return getTransactionsBox().values.toList();
  }

  Future<void> insertTransaction(Transaction t) async {
    await getTransactionsBox().put(t.id, t);
  }

  Future<void> updateTransaction(Transaction t) async {
    await getTransactionsBox().put(t.id, t);
  }

  Future<void> deleteTransaction(String id) async {
    await getTransactionsBox().delete(id);
  }

  Future<Account?> getAccountById(String id) async {
    try {
      return getAccountsBox().get(id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final account = getAccountsBox().get(accountId);
    if (account != null) {
      await updateAccount(account.copyWith(balance: newBalance));
    }
  }

  Future<List<Account>> getAllAccounts() async {
    return getAccountsBox().values.toList();
  }

  Future<void> insertAccount(Account a) async {
    await getAccountsBox().put(a.id, a);
  }

  Future<void> updateAccount(Account a) async {
    await getAccountsBox().put(a.id, a);
  }

  Future<void> deleteAccount(String id) async {
    await getAccountsBox().delete(id);
  }

  Future<List<Category>> getAllCategories() async {
    return getCategoriesBox().values.toList();
  }

  Future<void> insertCategory(Category c) async {
    await getCategoriesBox().put(c.id, c);
  }

  Future<void> updateCategory(Category c) async {
    await getCategoriesBox().put(c.id, c);
  }

  Future<void> deleteCategory(String id) async {
    await getCategoriesBox().delete(id);
  }

  Future<List<Budget>> getAllBudgets() async {
    return getBudgetsBox().values.toList();
  }

  Future<void> insertBudget(Budget b) async {
    await getBudgetsBox().put(b.id, b);
  }

  Future<void> updateBudget(Budget b) async {
    await getBudgetsBox().put(b.id, b);
  }

  Future<void> deleteBudget(String id) async {
    await getBudgetsBox().delete(id);
  }

  Future<List<Goal>> getAllGoals() async {
    return getGoalsBox().values.toList();
  }

  Future<void> insertGoal(Goal g) async {
    await getGoalsBox().put(g.id, g);
  }

  Future<void> updateGoal(Goal g) async {
    await getGoalsBox().put(g.id, g);
  }

  Future<void> deleteGoal(String id) async {
    await getGoalsBox().delete(id);
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final usersData = getUsersBox()
        .values
        .map((u) => u.toJson())
        .toList(growable: false);
    final accountsData = getAccountsBox()
        .values
        .map((a) => a.toJson())
        .toList(growable: false);
    final categoriesData = getCategoriesBox()
        .values
        .map((c) => c.toJson())
        .toList(growable: false);
    final transactionsData = getTransactionsBox()
        .values
        .map((t) => t.toJson())
        .toList(growable: false);
    final budgetsData = getBudgetsBox()
        .values
        .map((b) => b.toJson())
        .toList(growable: false);
    final goalsData = getGoalsBox()
        .values
        .map((g) => g.toJson())
        .toList(growable: false);
    final receiptsData = getReceiptsBox()
        .values
        .map((r) => r.toJson())
        .toList(growable: false);
    return {
      'version': _databaseVersion,
      'generated_at': DateTime.now().toIso8601String(),
      'users': usersData,
      'accounts': accountsData,
      'categories': categoriesData,
      'transactions': transactionsData,
      'budgets': budgetsData,
      'goals': goalsData,
      'receipts': receiptsData,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final users = (data['users'] as List<dynamic>? ?? []);
    final acc = (data['accounts'] as List<dynamic>? ?? []);
    final cat = (data['categories'] as List<dynamic>? ?? []);
    final txs = (data['transactions'] as List<dynamic>? ?? []);
    final buds = (data['budgets'] as List<dynamic>? ?? []);
    final gls = (data['goals'] as List<dynamic>? ?? []);
    final recs = (data['receipts'] as List<dynamic>? ?? []);

    for (final u in users) {
      final model = User.fromJson(Map<String, dynamic>.from(u));
      await getUsersBox().put(model.id, model);
    }
    for (final a in acc) {
      final model = Account.fromJson(Map<String, dynamic>.from(a));
      await insertAccount(model);
    }
    for (final c in cat) {
      final model = Category.fromJson(Map<String, dynamic>.from(c));
      await insertCategory(model);
    }
    for (final t in txs) {
      final model = Transaction.fromJson(Map<String, dynamic>.from(t));
      await insertTransaction(model);
    }
    for (final b in buds) {
      final model = Budget.fromJson(Map<String, dynamic>.from(b));
      await insertBudget(model);
    }
    for (final g in gls) {
      final model = Goal.fromJson(Map<String, dynamic>.from(g));
      await insertGoal(model);
    }
    for (final r in recs) {
      final model = Receipt.fromJson(Map<String, dynamic>.from(r));
      await getReceiptsBox().put(model.id, model);
    }
  }
}
