import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/api_service.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final ApiService _apiService = ApiService();
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'MAD', 'JPY', 'CAD', 'AUD'];
  bool _isLoadingRates = false;
  String? _errorMessage;
  Map<String, double>? _exchangeRates;
  String _baseCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates({String? baseCurrency}) async {
    setState(() {
      _isLoadingRates = true;
      _errorMessage = null;
    });

    try {
      final exchangeRate = await _apiService.getExchangeRates(
        baseCurrency: baseCurrency ?? _baseCurrency,
      );
      setState(() {
        _exchangeRates = exchangeRate.rates;
        _baseCurrency = exchangeRate.baseCurrency;
        _isLoadingRates = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingRates = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currentCurrency = transactionProvider.defaultCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Rates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchExchangeRates(),
            tooltip: 'Refresh Exchange Rates',
          ),
        ],
      ),
      body: Column(
        children: [
          // Base Currency Selection
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Base Currency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _baseCurrency,
                    isExpanded: true,
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _baseCurrency = value;
                        });
                        _fetchExchangeRates(baseCurrency: value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Exchange Rates Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exchange Rates (vs $_baseCurrency)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoadingRates)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exchange Rates List
          Expanded(
            child: _isLoadingRates
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchExchangeRates,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _exchangeRates == null
                        ? const Center(
                            child: Text('No exchange rates available'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _currencies.length,
                            itemBuilder: (context, index) {
                              final currency = _currencies[index];
                              final rate = _exchangeRates![currency];
                              final isSelected = currency == currentCurrency;

                              return Card(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : null,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    currency,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: rate != null
                                      ? Text('1 $_baseCurrency = ${rate.toStringAsFixed(4)} $currency')
                                      : const Text('Rate not available'),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: Colors.blue)
                                      : null,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

