import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';

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
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.palette,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 8),
          Text(
            'Art Projects',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSummary(BuildContext context) {
    final income = globalSummary['income'] ?? 0;
    final expenses = globalSummary['expenses'] ?? 0;
    final balance = globalSummary['balance'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Projects',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Income',
                income,
                Colors.green,
              ),
              _buildSummaryItem(
                'Expenses',
                expenses,
                Colors.red,
              ),
              _buildSummaryItem(
                'Balance',
                balance,
                balance >= 0 ? Colors.blue : Colors.orange,
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
            color: Colors.grey,
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

  Widget _buildProjectList(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        if (projectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (projectProvider.projects.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No projects yet.\nCreate your first project!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: projectProvider.projects.length,
          itemBuilder: (context, index) {
            final project = projectProvider.projects[index];
            final isSelected =
                project.id == projectProvider.currentProject?.id;

            return ListTile(
              leading: Icon(
                Icons.folder,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              title: Text(
                project.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black,
                ),
              ),
              selected: isSelected,
              selectedTileColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
              onTap: () async {
                if (!isSelected) {
                  await projectProvider.selectProject(project.id);
                  onRefresh();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              trailing: !isSelected
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'rename') {
                          _showRenameDialog(context, project);
                        } else if (value == 'delete') {
                          _showDeleteDialog(context, project);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Tooltip(
                      message: 'Switch to another project to rename or delete this one.',
                      child: Icon(Icons.info_outline, color: Colors.grey),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateProjectButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Create Project'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'Enter project name',
          ),
          autofocus: true,
          onSubmitted: (_) => _createProject(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createProject(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createProject(BuildContext context, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }
    const maxLength = 50;
    if (trimmedName.length > maxLength) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project name must be at most $maxLength characters.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final project = await projectProvider.createProject(trimmedName);

    if (context.mounted) {
      Navigator.of(context).pop();

      if (project != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "$name" created'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRenameDialog(BuildContext context, Project project) {
    final controller = TextEditingController(text: project.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Project Name',
          ),
          autofocus: true,
          onSubmitted: (_) => _renameProject(context, project, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                _renameProject(context, project, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _renameProject(
      BuildContext context, Project project, String newName) async {
    if (newName.trim().isEmpty || newName.trim() == project.name) {
      return;
    }

    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final success =
        await projectProvider.renameProject(project.id, newName.trim());

    if (context.mounted) {
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project renamed to "$newName"'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to rename project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"?\n\n'
          'All transactions for this project will be lost. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteProject(context, project),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteProject(BuildContext context, Project project) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final success = await projectProvider.deleteProject(project.id);

    if (context.mounted) {
      Navigator.of(context).pop();

      if (success) {
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${project.name}" deleted'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
