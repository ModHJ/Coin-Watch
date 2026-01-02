import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';

class CurrencySelectionScreen extends StatelessWidget {
  const CurrencySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currentCurrency = transactionProvider.defaultCurrency;
    
    final currencies = [
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
      {'code': 'MAD', 'name': 'Moroccan Dirham', 'symbol': 'د.م.'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
      {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: currencies.length,
        itemBuilder: (context, index) {
          final currency = currencies[index];
          final isSelected = currency['code'] == currentCurrency;

          return Card(
            color: isSelected ? Colors.blue.withOpacity(0.1) : null,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected
                    ? Colors.blue
                    : Colors.grey.withOpacity(0.2),
                child: Text(
                  currency['symbol']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                currency['name']!,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(currency['code']!),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () async {
                await transactionProvider.setDefaultCurrency(currency['code']!);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Currency set to ${currency['code']}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

