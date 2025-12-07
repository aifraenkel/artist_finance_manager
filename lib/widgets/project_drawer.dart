import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import '../screens/dashboard_screen.dart';
import '../l10n/app_localizations.dart';

/// Drawer widget for displaying projects and global financial summary.
///
/// Features:
/// - Global financial summary (across all projects)
/// - List of all projects
/// - Create new project button
/// - Select project to view
/// - Edit/delete project options
class ProjectDrawer extends StatelessWidget {
  final Map<String, double> globalSummary;
  final VoidCallback onRefresh;

  const ProjectDrawer({
    super.key,
    required this.globalSummary,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          _buildGlobalSummary(context),
          const Divider(),
          _buildAnalyticsButton(context),
          const Divider(),
          Expanded(
            child: _buildProjectList(context),
          ),
          const Divider(),
          _buildCreateProjectButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const SafeArea(
        child: Text(
          'Art Finance Hub',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final income = globalSummary['income'] ?? 0;
    final expenses = globalSummary['expenses'] ?? 0;
    final balance = globalSummary['balance'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.balance,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                l10n.totalIncome,
                income,
                AppColors.income,
              ),
              _buildSummaryItem(
                l10n.totalExpenses,
                expenses,
                AppColors.expense,
              ),
              _buildSummaryItem(
                l10n.balance,
                balance,
                balance >= 0 ? AppColors.primary : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            );
          },
          icon: const Icon(Icons.analytics),
          label: Text(l10n.viewAnalytics),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectList(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        if (projectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (projectProvider.projects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.createProjectToStart,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: projectProvider.projects.length,
          itemBuilder: (context, index) {
            final project = projectProvider.projects[index];
            final isSelected = project.id == projectProvider.currentProject?.id;

            return ListTile(
              leading: Icon(
                Icons.folder,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              title: Text(
                project.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedTileColor: AppColors.primarySurface,
              onTap: () async {
                if (!isSelected) {
                  await projectProvider.selectProject(project.id);
                  onRefresh();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameDialog(context, project);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, project);
                  }
                },
                itemBuilder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.rename),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateProjectButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.createProject),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createProject),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.projectName,
            hintText: l10n.enterProjectName,
          ),
          autofocus: true,
          onSubmitted: (_) => _createProject(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => _createProject(context, controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _createProject(BuildContext context, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }
    const maxLength = 50;
    if (trimmedName.length > maxLength) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.projectNameTooLong),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final project = await projectProvider.createProject(trimmedName);

      if (context.mounted) {
        Navigator.of(context).pop();

        if (project != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  l10n.projectCreatedSuccess.replaceAll('\$name', trimmedName)),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = projectProvider.error ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(l10n.failedToCreateProject.replaceAll('\$error', error)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n.failedToCreateProject.replaceAll('\$error', '$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRenameDialog(BuildContext context, Project project) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: project.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameProject),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.projectName,
          ),
          autofocus: true,
          onSubmitted: (_) => _renameProject(context, project, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => _renameProject(context, project, controller.text),
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
  }

  void _renameProject(
      BuildContext context, Project project, String newName) async {
    final l10n = AppLocalizations.of(context)!;
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty || trimmedName == project.name) {
      return;
    }

    const maxLength = 50;
    if (trimmedName.length > maxLength) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.projectNameTooLong),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final success =
        await projectProvider.renameProject(project.id, trimmedName);

    if (context.mounted) {
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                l10n.projectRenamedSuccess.replaceAll('\$name', trimmedName)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = projectProvider.error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n.failedToRenameProject.replaceAll('\$error', error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, Project project) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProject),
        content: Text(
          l10n.deleteProjectWarning.replaceAll('\$name', project.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => _deleteProject(context, project),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _deleteProject(BuildContext context, Project project) async {
    final l10n = AppLocalizations.of(context)!;
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final success = await projectProvider.deleteProject(project.id);

    if (context.mounted) {
      Navigator.of(context).pop();

      if (success) {
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                l10n.projectDeletedSuccess.replaceAll('\$name', project.name)),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final error = projectProvider.error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n.failedToDeleteProject.replaceAll('\$error', error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
