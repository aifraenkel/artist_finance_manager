import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../l10n/app_localizations.dart';

class TransactionForm extends StatefulWidget {
  final Function(
      String description, double amount, String type, String category) onSubmit;

  const TransactionForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _type = 'expense';
  String? _category;

  final Map<String, List<String>> _categories = {
    'expense': [
      'venue',
      'musicians',
      'foodAndDrinks',
      'materialsClothes',
      'bookPrinting',
      'podcast',
      'other'
    ],
    'income': ['bookSales', 'eventTickets', 'other'],
  };

  // Helper method to get localized category name
  String _getCategoryLabel(BuildContext context, String categoryKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryKey) {
      case 'venue':
        return l10n.venue;
      case 'musicians':
        return l10n.musicians;
      case 'foodAndDrinks':
        return l10n.foodAndDrinks;
      case 'materialsClothes':
        return l10n.materialsClothes;
      case 'bookPrinting':
        return l10n.bookPrinting;
      case 'podcast':
        return l10n.podcast;
      case 'bookSales':
        return l10n.bookSales;
      case 'eventTickets':
        return l10n.eventTickets;
      case 'other':
        return l10n.other;
      default:
        return categoryKey;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      widget.onSubmit(
        _descriptionController.text,
        double.parse(_amountController.text),
        _type,
        _category!,
      );

      // Clear form
      _descriptionController.clear();
      _amountController.clear();
      setState(() {
        _category = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.addTransaction,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Type and Category row
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        _buildTypeDropdown(),
                        const SizedBox(height: 12),
                        _buildCategoryDropdown(),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _buildTypeDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCategoryDropdown()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Description and Amount row
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        _buildDescriptionField(),
                        const SizedBox(height: 12),
                        _buildAmountField(),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDescriptionField(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildAmountField(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  key: const Key('add_transaction_button'),
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      key: const Key('type_dropdown'),
      initialValue: _type,
      decoration: InputDecoration(
        labelText: l10n.type,
      ),
      items: [
        DropdownMenuItem(value: 'expense', child: Text(l10n.expense)),
        DropdownMenuItem(value: 'income', child: Text(l10n.incomeType)),
      ],
      onChanged: (value) {
        setState(() {
          _type = value!;
          _category = null; // Reset category when type changes
        });
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      key: const Key('category_dropdown'),
      initialValue: _category,
      decoration: InputDecoration(
        labelText: l10n.category,
      ),
      hint: Text(l10n.selectCategory),
      items: _categories[_type]!
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(_getCategoryLabel(context, cat)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _category = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      key: const Key('description_field'),
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: l10n.description,
        hintText: l10n.description,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      key: const Key('amount_field'),
      controller: _amountController,
      decoration: InputDecoration(
        labelText: l10n.amount,
        hintText: '0.00',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) {
          return 'Amount must be greater than 0';
        }
        return null;
      },
    );
  }
}
