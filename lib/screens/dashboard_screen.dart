import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_colors.dart';
import '../models/transaction.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_sync_service.dart';
import '../services/user_preferences.dart';
import '../services/openai_service.dart';
import '../services/budget_analysis_service.dart';
import '../services/project_service.dart';
import '../l10n/app_localizations.dart';

/// Dashboard screen showing financial analytics and insights.
///
/// Features:
/// - Budget goal analysis (if configured)
/// - Project contribution breakdown (pie chart)
/// - Timeline charts for income, expenses, and balance
/// - Top expensive projects
/// - Summary statistics
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final UserPreferences _userPreferences = UserPreferences();
  bool _isLoading = true;
  bool _isAnalyzingGoal = false;
  Map<String, List<Transaction>> _projectTransactions = {};
  Map<String, Project> _projects = {};
  String? _goalAnalysis;
  String? _goalAnalysisError;

  // Month abbreviations for timeline chart
  static const List<String> _monthAbbreviations = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadPreferencesAndAnalyzeGoal();
    });
  }

  Future<void> _loadPreferencesAndAnalyzeGoal() async {
    await _userPreferences.initialize();

    // Check if we have an active goal
    final goal = _userPreferences.budgetGoal;
    if (goal != null && goal.isActive && goal.isValid) {
      await _analyzeGoal();
    }
  }

  Future<void> _analyzeGoal() async {
    final goal = _userPreferences.budgetGoal;
    if (goal == null || !goal.isActive || !goal.isValid) {
      return;
    }

    final apiKey = _userPreferences.openaiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _goalAnalysisError = 'OpenAI API key not set';
      });
      return;
    }

    setState(() {
      _isAnalyzingGoal = true;
      _goalAnalysis = null;
      _goalAnalysisError = null;
    });

    try {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);

      final openAIService = OpenAIService(apiKey: apiKey);
      final analysisService = BudgetAnalysisService(
        projectService: projectProvider.projectService,
        createStorageService: (projectId) {
          final syncService = FirestoreSyncService(projectId: projectId);
          return StorageService(
            syncService: syncService,
            projectId: projectId,
          );
        },
        openAIService: openAIService,
      );

      final analysis = await analysisService.analyzeGoal(goal);

      if (!mounted) return;
      setState(() {
        _goalAnalysis = analysis;
        _isAnalyzingGoal = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _goalAnalysisError = e.toString().replaceAll('Exception: ', '');
        _isAnalyzingGoal = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final projects = projectProvider.projects;

    // Build projects map
    final projectsMap = <String, Project>{};
    for (final project in projects) {
      projectsMap[project.id] = project;
    }

    // Load transactions for each project
    final projectTransactions = <String, List<Transaction>>{};
    for (final project in projects) {
      final syncService = FirestoreSyncService(projectId: project.id);
      final storageService = StorageService(
        syncService: syncService,
        projectId: project.id,
      );
      await storageService.initialize();

      final transactions = await storageService.loadTransactions();
      projectTransactions[project.id] = transactions;
    }

    setState(() {
      _projectTransactions = projectTransactions;
      _projects = projectsMap;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsDashboard),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildDashboard(context),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allTransactions =
        _projectTransactions.values.expand((txns) => txns).toList();

    if (allTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDataAvailable,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addTransactionsToSeeAnalytics,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final summary = _analyticsService.calculateSummary(_projectTransactions);
    final contributions = _analyticsService.getProjectContributions(
        _projectTransactions, _projects);
    final topExpensive = _analyticsService.getTopExpensiveProjects(
      _projectTransactions,
      _projects,
      limit: 5,
    );
    final timelineData = _analyticsService.getTimelineData(
      allTransactions,
      granularity: TimelineGranularity.monthly,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Goal Analysis Section (if active)
          if (_userPreferences.budgetGoal != null &&
              _userPreferences.budgetGoal!.isActive) ...[
            _buildGoalAnalysisSection(context),
            const SizedBox(height: 24),
          ],

          // Summary statistics
          _buildSummarySection(summary),
          const SizedBox(height: 24),

          // Project contributions (pie chart)
          if (contributions.isNotEmpty) ...[
            _buildSectionTitle('Project Contributions'),
            const SizedBox(height: 16),
            _buildProjectContributionsChart(contributions),
            const SizedBox(height: 24),
          ],

          // Timeline charts
          if (timelineData['income']!.isNotEmpty) ...[
            _buildSectionTitle('Financial Timeline'),
            const SizedBox(height: 16),
            _buildTimelineChart(timelineData),
            const SizedBox(height: 24),
          ],

          // Top expensive projects
          if (topExpensive.isNotEmpty) ...[
            _buildSectionTitle('Top Expensive Projects'),
            const SizedBox(height: 16),
            _buildTopExpensiveList(topExpensive),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildGoalAnalysisSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goal = _userPreferences.budgetGoal;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Budget Goal Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Show the goal
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(76)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal?.goalText ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Show analysis result or loading/error state
            if (_isAnalyzingGoal)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Analyzing your financial goal...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            else if (_goalAnalysisError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.destructive.withAlpha(76)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.destructive, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _goalAnalysisError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_goalAnalysis != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.success.withAlpha(76)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _goalAnalysis!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              TextButton.icon(
                onPressed: _analyzeGoal,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.analyzeGoal),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(AnalyticsSummary summary) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Income',
                    '\$${summary.totalIncome.toStringAsFixed(2)}',
                    AppColors.income,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Expenses',
                    '\$${summary.totalExpenses.toStringAsFixed(2)}',
                    AppColors.expense,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Balance',
                    '\$${summary.balance.toStringAsFixed(2)}',
                    summary.balance >= 0 ? AppColors.primary : AppColors.expense,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Transactions',
                    summary.numberOfTransactions.toString(),
                    AppColors.accent,
                    Icons.receipt_long,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectContributionsChart(Map<String, double> contributions) {
    if (contributions.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = contributions.values.fold(0.0, (sum, val) => sum + val);
    if (total < 0.01) {
      return const SizedBox.shrink();
    }

    // Generate colors for each project
    final colors = _generateColors(contributions.length);
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    for (final entry in contributions.entries) {
      final percentage = (entry.value / total) * 100;
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: colors[colorIndex % colors.length],
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(contributions, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data, List<Color> colors) {
    final entries = data.entries.toList();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              entry.key,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTimelineChart(
      Map<String, List<TimelineDataPoint>> timelineData) {
    final incomeData = timelineData['income']!;
    final expensesData = timelineData['expenses']!;
    final balanceData = timelineData['balance']!;

    if (incomeData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create spots for each line
    final incomeSpots = <FlSpot>[];
    final expensesSpots = <FlSpot>[];
    final balanceSpots = <FlSpot>[];

    for (int i = 0; i < incomeData.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), incomeData[i].value));
      expensesSpots.add(FlSpot(i.toDouble(), expensesData[i].value));
      balanceSpots.add(FlSpot(i.toDouble(), balanceData[i].value));
    }

    // Find max and min values for y-axis
    final maxIncome = _findMaxValue(incomeData);
    final maxExpenses = _findMaxValue(expensesData);
    final maxBalance = _findMaxValue(balanceData);
    final minBalance = _findMinValue(balanceData);

    // Determine y-axis range, accounting for negative balances
    final maxY =
        [maxIncome, maxExpenses, maxBalance].fold(0.0, (a, b) => a > b ? a : b);
    final minY = minBalance < 0 ? minBalance : 0.0;
    final yRange = maxY - minY;

    // Avoid division by zero
    final interval = yRange > 0 ? yRange / 5 : 1.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < incomeData.length) {
                            // Show abbreviated date (e.g., "Jan", "Feb")
                            final date = incomeData[index].date;
                            final parts = date.split('-');
                            if (parts.length >= 2) {
                              try {
                                final month = int.parse(parts[1]);
                                if (month >= 1 && month <= 12) {
                                  return Text(
                                    _monthAbbreviations[month],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                              } catch (e) {
                                // Ignore parse errors and fall through to return empty text
                              }
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      color: AppColors.income,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.income.withAlpha(25),
                      ),
                    ),
                    LineChartBarData(
                      spots: expensesSpots,
                      color: AppColors.expense,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.expense.withAlpha(25),
                      ),
                    ),
                    LineChartBarData(
                      spots: balanceSpots,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minY: minY < 0 ? minY * 1.1 : 0.0,
                  maxY: maxY * 1.1 > 0 ? maxY * 1.1 : 1.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Income', AppColors.income),
        const SizedBox(width: 16),
        _buildLegendItem('Expenses', AppColors.expense),
        const SizedBox(width: 16),
        _buildLegendItem('Balance', AppColors.primary),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTopExpensiveList(List<MapEntry<String, double>> topExpensive) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: topExpensive.map((entry) {
            final project = entry.key;
            final amount = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Color> _generateColors(int count) {
    return [
      AppColors.primary,
      AppColors.income,
      AppColors.warning,
      AppColors.accent,
      AppColors.primaryLight,
      AppColors.accentLight,
      AppColors.info,
      AppColors.success,
      AppColors.primaryDark,
      AppColors.accentDark,
    ];
  }

  /// Helper method to find maximum value from timeline data points
  double _findMaxValue(List<TimelineDataPoint> data) {
    if (data.isEmpty) return 0.0;
    final max = data
        .map((d) => d.value)
        .fold(double.negativeInfinity, (max, val) => max > val ? max : val);
    return max.isInfinite ? 0.0 : max;
  }

  /// Helper method to find minimum value from timeline data points
  double _findMinValue(List<TimelineDataPoint> data) {
    if (data.isEmpty) return 0.0;
    final min = data
        .map((d) => d.value)
        .fold(double.infinity, (min, val) => min < val ? min : val);
    return min.isInfinite ? 0.0 : min;
  }
}
