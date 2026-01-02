import 'package:dio/dio.dart';
import '../models/exchange_rate.dart';

/// API Service for fetching currency exchange rates
/// Uses exchangerate-api.io (free tier, no API key required)
class ApiService {
  final Dio _dio;
  static const String baseUrl = 'https://api.exchangerate-api.com/v4';

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add interceptors for error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Handle network errors
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            error = DioException(
              requestOptions: error.requestOptions,
              error: 'Connection timeout. Please check your internet connection.',
              type: error.type,
            );
          } else if (error.type == DioExceptionType.unknown) {
            error = DioException(
              requestOptions: error.requestOptions,
              error: 'Network error. Please check your internet connection.',
              type: error.type,
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Fetch latest exchange rates for a base currency
  /// Default base currency is USD
  Future<ExchangeRate> getExchangeRates({String baseCurrency = 'USD'}) async {
    try {
      final response = await _dio.get('/latest/$baseCurrency');
      
      if (response.statusCode == 200) {
        return ExchangeRate.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to fetch exchange rates',
        );
      }
    } on DioException catch (e) {
      // Re-throw with user-friendly message
      throw Exception(
        e.error?.toString() ?? 
        'Failed to fetch exchange rates. Please try again later.',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Convert amount between two currencies
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final exchangeRate = await getExchangeRates(baseCurrency: fromCurrency);
      return exchangeRate.convert(amount, fromCurrency, toCurrency);
    } catch (e) {
      throw Exception('Currency conversion failed: ${e.toString()}');
    }
  }
}

