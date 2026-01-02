import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../transaction/add_transaction_screen.dart';
import '../reconciliation/reconciliation_screen.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../settings/currency_settings_screen.dart';
import '../settings/currency_selection_screen.dart';
import '../settings/category_management_screen.dart';
import 'edit_balance_dialog.dart';
import '../transaction/edit_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Watch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              );
            },
            tooltip: 'Manage Categories',
          ),
          IconButton(
            icon: const Icon(Icons.currency_exchange),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CurrencySettingsScreen(),
                ),
              );
            },
            tooltip: 'Exchange Rates',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CurrencySelectionScreen(),
                ),
              );
            },
            tooltip: 'Currency Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final balance = transactionProvider.totalBalance;
          final transactions = transactionProvider.transactions;
          final currency = transactionProvider.defaultCurrency;
          final currencySymbol = _getCurrencySymbol(currency);

          return RefreshIndicator(
            onRefresh: () async {
              // Reload transactions
            },
            child: Column(
              children: [
                // Balance Card (Tappable)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditBalanceDialog(
                        currentBalance: balance,
                        currency: currency,
                      ),
                    ).then((_) {
                      // Reload transactions after balance adjustment
                      transactionProvider.setUserId(
                        Provider.of<AuthProvider>(context, listen: false)
                            .currentUser
                            ?.id,
                      );
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currencySymbol${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currency,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to adjust',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first transaction',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final category = transactionProvider.getCategory(transaction.categoryId);
                            return _TransactionCard(
                              transaction: transaction,
                              category: category,
                              currencySymbol: currencySymbol,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          ).then((_) {
            // Reload transactions after adding
            final transactionProvider =
                Provider.of<TransactionProvider>(context, listen: false);
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            transactionProvider.setUserId(authProvider.currentUser?.id);
          });
        },
        child: const Icon(Icons.add),
      ),
    );
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
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final String currencySymbol;

  const _TransactionCard({
    required this.transaction,
    this.category,
    required this.currencySymbol,
  });

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${transaction.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.deleteTransaction(transaction.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final categoryColor = category?.color ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditTransactionScreen(transaction: transaction),
            ),
          ).then((_) {
            // Reload transactions after editing
            final transactionProvider =
                Provider.of<TransactionProvider>(context, listen: false);
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            transactionProvider.setUserId(authProvider.currentUser?.id);
          });
        },
        child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category != null
              ? categoryColor.withOpacity(0.2)
              : (isIncome
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2)),
          child: category != null
              ? Icon(
                  Icons.category,
                  color: categoryColor,
                  size: 20,
                )
              : Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category!.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${dateFormat.format(transaction.date)} at ${timeFormat.format(transaction.date)}',
        ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}$currencySymbol${transaction.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    '${transaction.quantity} × $currencySymbol${transaction.unitPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteDialog(context),
                tooltip: 'Delete Transaction',
              ),
            ],
          ),
      ),
      ),
    );
  }
}

