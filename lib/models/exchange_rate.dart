class ExchangeRate {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime timestamp;

  ExchangeRate({
    required this.baseCurrency,
    required this.rates,
    required this.timestamp,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      baseCurrency: json['base'] ?? 'USD',
      rates: Map<String, double>.from(
        json['rates'] ?? {},
      ),
      timestamp: DateTime.now(),
    );
  }

  double? getRate(String currency) {
    return rates[currency];
  }

  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    // Convert to base currency first
    double baseAmount = amount;
    if (fromCurrency != baseCurrency) {
      final fromRate = getRate(fromCurrency);
      if (fromRate == null) return amount;
      baseAmount = amount / fromRate;
    }
    
    // Convert from base to target currency
    if (toCurrency != baseCurrency) {
      final toRate = getRate(toCurrency);
      if (toRate == null) return amount;
      return baseAmount * toRate;
    }
    
    return baseAmount;
  }
}

