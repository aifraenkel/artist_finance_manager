import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../models/financial_goal.dart';
import '../services/financial_goal_service.dart';
import '../services/openai_service.dart';
import '../l10n/app_localizations.dart';

/// Full-screen modal wizard for setting up financial goals
///
/// Three-step process:
/// 1. Goal Definition - text area with character counter and examples
/// 2. Timeline & Notifications - date picker and email cadence selector
/// 3. Confirmation - summary, AI acknowledgment, and save
class FinancialGoalWizard extends StatefulWidget {
  final String userId;
  final String openAIApiKey;
  final VoidCallback? onGoalSaved;
  final VoidCallback? onSkipped;

  const FinancialGoalWizard({
    super.key,
    required this.userId,
    required this.openAIApiKey,
    this.onGoalSaved,
    this.onSkipped,
  });

  @override
  State<FinancialGoalWizard> createState() => _FinancialGoalWizardState();
}

class _FinancialGoalWizardState extends State<FinancialGoalWizard> {
  final PageController _pageController = PageController();
  final TextEditingController _goalController = TextEditingController();
  final FinancialGoalService _goalService = FinancialGoalService();

  int _currentStep = 0;
  DateTime? _selectedDate;
  EmailCadence _selectedCadence = EmailCadence.weekly;
  bool _isLoading = false;
  bool _isGeneratingAcknowledgment = false;
  String? _acknowledgmentText;
  String? _errorMessage;

  static const int _maxCharacters = 2000;

  @override
  void dispose() {
    _pageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // If moving to confirmation step, generate acknowledgment and save goal
      if (_currentStep == 2) {
        _saveGoalAndGenerateAcknowledgment();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveGoalAndGenerateAcknowledgment() async {
    setState(() {
      _isLoading = true;
      _isGeneratingAcknowledgment = true;
      _acknowledgmentText = null;
      _errorMessage = null;
    });

    try {
      // Create the financial goal
      final goal = FinancialGoal(
        goal: _goalController.text.trim(),
        dueDate: _selectedDate!,
        emailCadence: _selectedCadence,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      await _goalService.saveGoal(widget.userId, goal);

      // Generate AI acknowledgment
      if (widget.openAIApiKey.isNotEmpty) {
        try {
          final openAIService = OpenAIService(apiKey: widget.openAIApiKey);
          final acknowledgment = await openAIService.acknowledgeGoal(goal);
          setState(() {
            _acknowledgmentText = acknowledgment;
            _isGeneratingAcknowledgment = false;
          });
        } catch (e) {
          // If AI generation fails, still show success but with a note
          setState(() {
            _isGeneratingAcknowledgment = false;
            _errorMessage = AppLocalizations.of(context)!
                .failedToGenerateAcknowledgment;
          });
        }
      } else {
        setState(() {
          _isGeneratingAcknowledgment = false;
          _acknowledgmentText =
              AppLocalizations.of(context)!.goalSavedSuccessfully;
        });
      }
    } catch (e) {
      setState(() {
        _isGeneratingAcknowledgment = false;
        _errorMessage =
            '${AppLocalizations.of(context)!.failedToSaveGoal}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _finish() {
    Navigator.of(context).pop();
    widget.onGoalSaved?.call();
  }

  void _skip() {
    Navigator.of(context).pop();
    widget.onSkipped?.call();
  }

  bool _canProceedFromStep1() {
    final goalText = _goalController.text.trim();
    return goalText.isNotEmpty && goalText.length <= _maxCharacters;
  }

  bool _canProceedFromStep2() {
    return _selectedDate != null && _selectedDate!.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financialGoalWizard),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        actions: [
          if (_currentStep < 2)
            TextButton(
              onPressed: _skip,
              child: Text(l10n.skipForNow),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(l10n),
                    _buildStep2(l10n),
                    _buildStep3(l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? (isCompleted ? AppColors.success : AppColors.primary)
                    : AppColors.textMuted.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(AppLocalizations l10n) {
    final remainingChars = _maxCharacters - _goalController.text.length;
    final isOverLimit = remainingChars < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.setYourFinancialGoal,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _goalController,
            decoration: InputDecoration(
              labelText: l10n.goalDescription,
              hintText: l10n.goalDescriptionHint,
              helperText: l10n.goalDescriptionHelper,
              border: const OutlineInputBorder(),
              counterText: '$remainingChars ${l10n.charactersRemaining}',
              counterStyle: TextStyle(
                color: isOverLimit ? AppColors.destructive : null,
              ),
              errorText: isOverLimit ? l10n.goalTooLong : null,
            ),
            maxLines: 5,
            maxLength: _maxCharacters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.inspiration,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildExampleGoal(l10n.exampleGoal1),
          _buildExampleGoal(l10n.exampleGoal2),
          _buildExampleGoal(l10n.exampleGoal3),
          _buildExampleGoal(l10n.exampleGoal4),
          _buildExampleGoal(l10n.exampleGoal5),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _canProceedFromStep1() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.next),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleGoal(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _goalController.text = text;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.timelineAndNotifications,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.whenDoYouWantToAchieveThis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _selectedDate == null
                  ? l10n.selectDueDate
                  : DateFormat.yMMMd().format(_selectedDate!),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.howOftenEmailUpdates,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildCadenceOption(EmailCadence.daily, l10n.emailCadenceDaily),
          _buildCadenceOption(EmailCadence.weekly, l10n.emailCadenceWeekly),
          _buildCadenceOption(
              EmailCadence.biweekly, l10n.emailCadenceBiweekly),
          _buildCadenceOption(EmailCadence.monthly, l10n.emailCadenceMonthly),
          _buildCadenceOption(EmailCadence.never, l10n.emailCadenceNever),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _canProceedFromStep2() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.next),
          ),
        ],
      ),
    );
  }

  Widget _buildCadenceOption(EmailCadence cadence, String label) {
    return RadioListTile<EmailCadence>(
      title: Text(label),
      value: cadence,
      groupValue: _selectedCadence,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCadence = value;
          });
        }
      },
    );
  }

  Widget _buildStep3(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.confirmation,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(
            l10n.yourGoal,
            _goalController.text.trim(),
            Icons.flag,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            l10n.dueDate,
            DateFormat.yMMMd().format(_selectedDate!),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            l10n.emailUpdates,
            _getCadenceLabel(_selectedCadence, l10n),
            Icons.email,
          ),
          const SizedBox(height: 32),
          if (_isGeneratingAcknowledgment)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.generatingAcknowledgment,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withAlpha(127)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: AppColors.warning, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else if (_acknowledgmentText != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withAlpha(127)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _acknowledgmentText!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isLoading || _isGeneratingAcknowledgment)
                ? null
                : _finish,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.success,
            ),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withAlpha(76)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCadenceLabel(EmailCadence cadence, AppLocalizations l10n) {
    switch (cadence) {
      case EmailCadence.daily:
        return l10n.emailCadenceDaily;
      case EmailCadence.weekly:
        return l10n.emailCadenceWeekly;
      case EmailCadence.biweekly:
        return l10n.emailCadenceBiweekly;
      case EmailCadence.monthly:
        return l10n.emailCadenceMonthly;
      case EmailCadence.never:
        return l10n.emailCadenceNever;
    }
  }
}
