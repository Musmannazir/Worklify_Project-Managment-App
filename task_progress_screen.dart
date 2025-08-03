import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskProgressScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;

  const TaskProgressScreen({super.key, required this.tasks});

  @override
  State<TaskProgressScreen> createState() => _TaskProgressScreenState();
}

class _TaskProgressScreenState extends State<TaskProgressScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Progress"),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Task Progress Overview:",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.tasks.length,
                itemBuilder: (context, index) {
                  final task = widget.tasks[index];
                  // Simulate progress (e.g., 0% to 100% based on deadline proximity or manual input)
                  double progress = _calculateProgress(task);
                  return _buildTaskProgressBox(context, task, progress, index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateProgress(Map<String, dynamic> task) {
    // Simple simulation: progress increases as deadline approaches (replace with real logic)
    DateTime deadline = DateFormat('dd-MM-yyyy').parse(task["deadline"]);
    DateTime now = DateTime.now();
    int totalDays = deadline.difference(now).inDays + 1; // Total days until deadline
    if (totalDays <= 0) return 100.0; // Completed if past deadline
    int elapsedDays = DateTime.now().difference(DateTime.now().subtract(Duration(days: totalDays))).inDays;
    return (elapsedDays / totalDays) * 100 > 100 ? 100 : (elapsedDays / totalDays) * 100;
  }

  Widget _buildTaskProgressBox(BuildContext context, Map<String, dynamic> task, double progress, int index) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              // Optional: Add tap action if needed (e.g., edit progress)
            },
            child: AnimatedContainer(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              height: 150, // Increased height to accommodate progress bar
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task["title"],
                    style: TextStyle(
                      color: isHovered
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Members: ${task["members"]}",
                    style: TextStyle(
                      color: isHovered
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Deadline: ${task["deadline"]}",
                    style: TextStyle(
                      color: isHovered
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Progress: ${progress.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: isHovered
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}