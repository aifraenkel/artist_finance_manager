import 'package:flutter/material.dart';

class SummaryCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  const SummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use column layout for narrow screens (mobile portrait)
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildIncomeCard(),
              const SizedBox(height: 12),
              _buildExpensesCard(),
              const SizedBox(height: 12),
              _buildBalanceCard(),
            ],
          );
        }

        // Use row layout for wider screens (tablet, desktop, mobile landscape)
        return Row(
          children: [
            Expanded(child: _buildIncomeCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildExpensesCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildBalanceCard()),
          ],
        );
      },
    );
  }

  Widget _buildIncomeCard() {
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
                      const Text(
                        'Income',
                        key: ValueKey('income-label'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€${totalIncome.toStringAsFixed(2)}',
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

  Widget _buildExpensesCard() {
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
                      const Text(
                        'Expenses',
                        key: ValueKey('expenses-label'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€${totalExpenses.toStringAsFixed(2)}',
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

  Widget _buildBalanceCard() {
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
                      const Text(
                        'Balance',
                        key: ValueKey('balance-label'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balance < 0
                            ? '-€${balance.abs().toStringAsFixed(2)}'
                            : '€${balance.toStringAsFixed(2)}',
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
