import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/category.dart' as models;

class StorageService {
  static const String transactionsBoxName = 'transactions';
  static const String usersBoxName = 'users';
  static const String categoriesBoxName = 'categories';
  static const String currentUserKey = 'current_user_id';
  static const String rememberMeKey = 'remember_me';
  static const String defaultCurrencyKey = 'default_currency';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(models.CategoryAdapter());
    }
  }

  // Transaction operations
  static Box<Transaction> get transactionsBox =>
      Hive.box<Transaction>(transactionsBoxName);

  static Future<void> openBoxes() async {
    await Hive.openBox<Transaction>(transactionsBoxName);
    await Hive.openBox<User>(usersBoxName);
    await Hive.openBox<models.Category>(categoriesBoxName);
    
    // Initialize default categories if they don't exist
    await _initializeDefaultCategories();
  }
  
  static Future<void> _initializeDefaultCategories() async {
    final box = Hive.box<models.Category>(categoriesBoxName);
    final defaults = models.Category.getDefaultCategories();
    
    for (var category in defaults) {
      if (!box.containsKey(category.id)) {
        await box.put(category.id, category);
      }
    }
  }

  static Future<void> addTransaction(Transaction transaction) async {
    await transactionsBox.put(transaction.id, transaction);
  }

  static Future<void> deleteTransaction(String id) async {
    await transactionsBox.delete(id);
  }

  static List<Transaction> getAllTransactions({String? userId}) {
    final allTransactions = transactionsBox.values.toList();
    final filtered = userId != null
        ? allTransactions.where((t) => t.userId == userId).toList()
        : allTransactions;
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  static double getTotalBalance({String? userId}) {
    final transactions = getAllTransactions(userId: userId);
    double balance = 0.0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        balance += transaction.total;
      } else {
        balance -= transaction.total;
      }
    }
    return balance;
  }

  // User operations
  static Box<User> get usersBox => Hive.box<User>(usersBoxName);

  static Future<void> addUser(User user) async {
    await usersBox.put(user.id, user);
  }

  static User? getUser(String id) {
    return usersBox.get(id);
  }

  static User? getUserByEmail(String email) {
    try {
      return usersBox.values.firstWhere(
        (user) => user.email == email,
      );
    } catch (e) {
      return null;
    }
  }

  // SharedPreferences for app settings
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  static Future<void> setCurrentUser(String? userId) async {
    final prefs = await _prefs;
    if (userId != null) {
      await prefs.setString(currentUserKey, userId);
    } else {
      await prefs.remove(currentUserKey);
    }
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await _prefs;
    return prefs.getString(currentUserKey);
  }

  static Future<void> setRememberMe(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(rememberMeKey, value);
  }

  static Future<bool> getRememberMe() async {
    final prefs = await _prefs;
    return prefs.getBool(rememberMeKey) ?? false;
  }

  static Future<String> getDefaultCurrency({String? userId}) async {
    final prefs = await _prefs;
    final key = userId != null ? '${defaultCurrencyKey}_$userId' : defaultCurrencyKey;
    return prefs.getString(key) ?? 'USD';
  }
  
  static Future<void> setDefaultCurrency(String currency, {String? userId}) async {
    final prefs = await _prefs;
    final key = userId != null ? '${defaultCurrencyKey}_$userId' : defaultCurrencyKey;
    await prefs.setString(key, currency);
  }

  // Category operations
  static Box<models.Category> get categoriesBox => Hive.box<models.Category>(categoriesBoxName);

  static Future<void> addCategory(models.Category category) async {
    await categoriesBox.put(category.id, category);
  }

  static Future<void> deleteCategory(String id) async {
    await categoriesBox.delete(id);
  }

  static List<models.Category> getCategories({String? userId}) {
    final allCategories = categoriesBox.values.toList();
    // Return default categories + user's custom categories
    return allCategories.where((c) => c.isDefault || c.userId == userId).toList()
      ..sort((a, b) {
        // Default categories first, then custom
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
  }

  static models.Category? getCategory(String id) {
    return categoriesBox.get(id);
  }
}

