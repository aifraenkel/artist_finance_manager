import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SummaryCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final String currencySymbol;

  const SummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    this.currencySymbol = '€', // Default to Euro for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use column layout for narrow screens (mobile portrait)
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildIncomeCard(context),
              const SizedBox(height: 12),
              _buildExpensesCard(context),
              const SizedBox(height: 12),
              _buildBalanceCard(context),
            ],
          );
        }

        // Use row layout for wider screens (tablet, desktop, mobile landscape)
        return Row(
          children: [
            Expanded(child: _buildIncomeCard(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildExpensesCard(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildBalanceCard(context)),
          ],
        );
      },
    );
  }

  Widget _buildIncomeCard(BuildContext context) {
    return Card(
      key: const ValueKey('income-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.income,
                        key: const ValueKey('income-label'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currencySymbol${totalIncome.toStringAsFixed(2)}',
                        key: const ValueKey('income-amount'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCard(BuildContext context) {
    return Card(
      key: const ValueKey('expenses-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.expenses,
                        key: const ValueKey('expenses-label'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currencySymbol${totalExpenses.toStringAsFixed(2)}',
                        key: const ValueKey('expenses-amount'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.trending_down,
                  color: Colors.red,
                  size: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final balanceColor = balance >= 0 ? Colors.blue : Colors.red;

    return Card(
      key: const ValueKey('balance-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.balance,
                        key: const ValueKey('balance-label'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balance < 0
                            ? '-$currencySymbol${balance.abs().toStringAsFixed(2)}'
                            : '$currencySymbol${balance.toStringAsFixed(2)}',
                        key: const ValueKey('balance-amount'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.attach_money,
                  color: balanceColor,
                  size: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
