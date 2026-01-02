import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction.dart';

class EditBalanceDialog extends StatefulWidget {
  final double currentBalance;
  final String currency;

  const EditBalanceDialog({
    super.key,
    required this.currentBalance,
    required this.currency,
  });

  @override
  State<EditBalanceDialog> createState() => _EditBalanceDialogState();
}

class _EditBalanceDialogState extends State<EditBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _balanceController.text = widget.currentBalance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'MAD':
        return 'د.م.';
      default:
        return '$currency ';
    }
  }

  Future<void> _saveBalance() async {
    if (_formKey.currentState!.validate()) {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to adjust balance'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final newBalance = double.parse(_balanceController.text);
      final difference = newBalance - widget.currentBalance;

      if (difference == 0) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Balance unchanged'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Create adjustment transaction
      final transaction = Transaction.adjustment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: authProvider.currentUser!.id,
        amount: difference,
        date: _selectedDate,
        currency: widget.currency,
        description: 'Balance adjustment: ${widget.currentBalance.toStringAsFixed(2)} → ${newBalance.toStringAsFixed(2)}',
      );

      await transactionProvider.addTransaction(transaction);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              difference > 0
                  ? 'Balance increased by ${_getCurrencySymbol(widget.currency)}${difference.abs().toStringAsFixed(2)}'
                  : 'Balance decreased by ${_getCurrencySymbol(widget.currency)}${difference.abs().toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _getCurrencySymbol(widget.currency);
    final difference = double.tryParse(_balanceController.text) != null
        ? double.parse(_balanceController.text) - widget.currentBalance
        : 0.0;

    return AlertDialog(
      title: const Text('Adjust Balance'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Balance Display
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '$currencySymbol${widget.currentBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // New Balance Input
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'New Balance',
                  hintText: '0.00',
                  prefixText: currencySymbol,
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a balance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Difference Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: difference > 0
                      ? Colors.green.withOpacity(0.1)
                      : difference < 0
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: difference > 0
                        ? Colors.green
                        : difference < 0
                            ? Colors.red
                            : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      difference > 0
                          ? 'Increase:'
                          : difference < 0
                              ? 'Decrease:'
                              : 'No change:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      difference != 0
                          ? '${difference > 0 ? '+' : ''}$currencySymbol${difference.abs().toStringAsFixed(2)}'
                          : '$currencySymbol${0.00.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: difference > 0
                            ? Colors.green
                            : difference < 0
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date Selection
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveBalance,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

