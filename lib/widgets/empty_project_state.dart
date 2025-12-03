import 'package:flutter/material.dart';

/// Widget displayed when user has no projects.
///
/// Shows a friendly empty state with:
/// - Large icon
/// - Clear message
/// - Call-to-action button to create first project
class EmptyProjectState extends StatelessWidget {
  final VoidCallback? onCreateProject;

  const EmptyProjectState({
    super.key,
    this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large folder icon
            Icon(
              Icons.folder_open,
              size: 120,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 32),

            // Main message
            Text(
              'No Projects Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Call-to-action message
            Text(
              'Create a project to start registering your incomes and expenses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Create project button
            if (onCreateProject != null)
              ElevatedButton(
                onPressed: onCreateProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Create Your First Project',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
