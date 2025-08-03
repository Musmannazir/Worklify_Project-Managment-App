import 'package:flutter/material.dart';
import 'assign_task_screen.dart' as assign;
import 'task_progress_screen.dart';
import 'loginscreen.dart';
import 'view_members_screen.dart';

class ProjectManagerScreen extends StatelessWidget {
  final int userId; // Added to store logged-in user's ID
  final int projectId; // Added to store selected project's ID

  const ProjectManagerScreen({super.key, required this.userId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'title': 'Assign Task',
        'icon': Icons.assignment_add,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => assign.AssignTaskScreen(
                  projectId: projectId,
                  userId: userId,
                ),
              ),
            ),
      },
      {
        'title': 'View Members',
        'icon': Icons.group,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewMembersScreen(projectId: projectId),
              ),
            ),
      },
      {
        'title': 'Task Progress',
        'icon': Icons.timeline,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskProgressScreen(tasks: [])),
            ),
      },
      {
        'title': 'Analytics',
        'icon': Icons.analytics,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlaceholderScreen(title: 'Analytics')),
            ),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              'Project Manager Dashboard',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1,
                children: options.map((option) {
                  return HoverBox(
                    title: option['title'] as String,
                    icon: option['icon'] as IconData,
                    onTap: option['onTap'] as VoidCallback,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoverBox extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const HoverBox({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<HoverBox> createState() => _HoverBoxState();
}

class _HoverBoxState extends State<HoverBox> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovering
                ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Text(
          'This is the $title screen. Implement your content here!',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontSize: 18),
        ),
      ),
    );
  }
}