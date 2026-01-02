import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Transaction> _transactions = [];
  List<models.Category> _categories = [];
  double _totalBalance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  String _defaultCurrency = 'USD';
  String? _currentUserId;

  List<Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  double get totalBalance => _totalBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get defaultCurrency => _defaultCurrency;

  void setUserId(String? userId) {
    _currentUserId = userId;
    _loadTransactions();
    _loadDefaultCurrency();
    _loadCategories();
  }

  Future<void> _loadDefaultCurrency() async {
    _defaultCurrency = await StorageService.getDefaultCurrency(userId: _currentUserId);
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    _categories = StorageService.getCategories(userId: _currentUserId);
    notifyListeners();
  }

  Future<void> _loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = StorageService.getAllTransactions(userId: _currentUserId);
      _totalBalance = StorageService.getTotalBalance(userId: _currentUserId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await StorageService.addTransaction(transaction);
      await _loadTransactions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await StorageService.deleteTransaction(id);
      await _loadTransactions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }


  Future<void> setDefaultCurrency(String currency) async {
    await StorageService.setDefaultCurrency(currency, userId: _currentUserId);
    _defaultCurrency = currency;
    notifyListeners();
  }

  Future<void> addCategory(models.Category category) async {
    await StorageService.addCategory(category);
    await _loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await StorageService.deleteCategory(id);
    await _loadCategories();
  }

  models.Category? getCategory(String? categoryId) {
    if (categoryId == null) return null;
    return StorageService.getCategory(categoryId);
  }

  // Currency conversion using API
  Future<double?> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final convertedAmount = await _apiService.convertCurrency(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return convertedAmount;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

