import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'view_members_screen.dart';

class AssignTaskScreen extends StatefulWidget {
  final int projectId;
  final int userId;

  const AssignTaskScreen({super.key, required this.projectId, required this.userId});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  DateTime? _selectedDeadline;
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> availableMembers = [];
  List<int> selectedMemberIds = [];
  int? _editingIndex;
  bool isLoading = true;
  int? selectedTaskId; // Added to track the selected task

  @override
  void initState() {
    super.initState();
    fetchTasks();
    fetchAvailableMembers();
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_assigned_tasks/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['tasks'];
        setState(() {
          tasks = data
              .where((task) => task['project_id'] == widget.projectId)
              .cast<Map<String, dynamic>>()
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackbar('Failed to load tasks: $e');
    }
  }

  Future<void> fetchAvailableMembers() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_team_members'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['members'];
        setState(() {
          availableMembers = data.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load members: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Failed to load members: $e');
    }
  }

  Future<void> _submitTask() async {
    if (_titleController.text.isEmpty || _membersController.text.isEmpty) {
      _showSnackbar("Please fill all required fields");
      return;
    }
    if (int.tryParse(_membersController.text) == null) {
      _showSnackbar("Please enter a valid number of members");
      return;
    }
    if (_selectedDeadline == null) {
      _showSnackbar("Please select a deadline");
      return;
    }
    if (selectedMemberIds.isEmpty && _editingIndex == null) {
      _showSnackbar("Please select at least one member");
      return;
    }

    final task = {
      "project_id": widget.projectId,
      "title": _titleController.text,
      "description": _descriptionController.text,
      "number_of_members": int.parse(_membersController.text),
      "deadline": DateFormat('yyyy-MM-dd').format(_selectedDeadline!),
    };

    try {
      if (_editingIndex == null) {
        // Create new task
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/create_task'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task),
        );

        if (response.statusCode == 201) {
          final taskId = jsonDecode(response.body)['task_id'];
          // Assign the task to the project manager
          await http.post(
            Uri.parse('http://127.0.0.1:5000/assign_member_to_task'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'task_id': taskId,
              'user_id': widget.userId,
            }),
          );
          // Assign selected members
          for (var memberId in selectedMemberIds) {
            await http.post(
              Uri.parse('http://127.0.0.1:5000/assign_member_to_task'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'task_id': taskId,
                'user_id': memberId,
              }),
            );
          }
          _showSnackbar("Task created successfully");
        } else {
          final data = jsonDecode(response.body);
          _showSnackbar("Failed: ${data['message']}");
        }
      } else {
        // Update existing task
        task['task_id'] = tasks[_editingIndex!]['task_id'];
        final response = await http.put(
          Uri.parse('http://127.0.0.1:5000/update_task'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task),
        );

        if (response.statusCode == 200) {
          _showSnackbar("Task updated successfully");
        } else {
          final data = jsonDecode(response.body);
          _showSnackbar("Failed: ${data['message']}");
        }
      }
      // Refresh tasks after creation or update
      await fetchTasks();
      _clearFields();
    } catch (e) {
      _showSnackbar("Error: $e");
    }
  }

  Future<void> _deleteTask(int index) async {
    final taskId = tasks[index]['task_id'];
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_task/$taskId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          tasks.removeAt(index);
          _showSnackbar("Task deleted successfully");
        });
        await fetchTasks();
      } else {
        final data = jsonDecode(response.body);
        _showSnackbar("Failed: ${data['message']}");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    }
  }

  void _editTask(int index) {
    final task = tasks[index];
    _titleController.text = task["title"];
    _descriptionController.text = task["description"] ?? "";
    _membersController.text = task["members"];
    try {
      _selectedDeadline = DateFormat('dd-MM-yyyy').parse(task["deadline"]);
    } catch (e) {
      _selectedDeadline = null;
      _showSnackbar("Error loading deadline, please reselect");
    }
    _editingIndex = index;
    // Reset selected members (editing doesn't modify assignments here)
    selectedMemberIds.clear();
    setState(() {});
  }

  void _clearFields() {
    _titleController.clear();
    _descriptionController.clear();
    _membersController.clear();
    _selectedDeadline = null;
    _editingIndex = null;
    selectedMemberIds.clear();
    setState(() {});
  }

  void _pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, bool required = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildMemberSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Assign Members",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableMembers.map((member) {
            final isSelected = selectedMemberIds.contains(member['user_id']);
            return FilterChip(
              label: Text(
                member['name'],
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onBackground,
                ),
              ),
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedMemberIds.add(member['user_id']);
                  } else {
                    selectedMemberIds.remove(member['user_id']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Task"),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTextField(_titleController, "Task Title", required: true),
                    const SizedBox(height: 10),
                    _buildTextField(_descriptionController, "Description"),
                    const SizedBox(height: 10),
                    _buildTextField(_membersController, "Number of Members",
                        keyboardType: TextInputType.number, required: true),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDeadline == null
                                ? "No deadline selected"
                                : "Deadline: ${DateFormat('dd-MM-yyyy').format(_selectedDeadline!)}",
                            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickDeadline,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: Text("Select Deadline",
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildMemberSelection(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        _editingIndex == null ? "Assign Task" : "Update Task",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedTaskId == null && tasks.isNotEmpty) {
                          _showSnackbar("Please select a task from the list below.");
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewMembersScreen(
                              projectId: widget.projectId,
                              taskId: selectedTaskId ?? (tasks.isNotEmpty ? tasks.last['task_id'] : null),
                            ),
                          ),
                        ).then((_) => fetchTasks());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        "View All Members",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Assigned Tasks:",
                        style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    tasks.isEmpty
                        ? Text(
                            "No tasks assigned yet",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 16,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              final isSelected = selectedTaskId == task['task_id'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTaskId = isSelected ? null : task['task_id'];
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.primary,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Text(task["title"],
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.onBackground)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Members: ${task["members"]}",
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface)),
                                        Text("Deadline: ${task["deadline"]}",
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface)),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: Theme.of(context).colorScheme.primary),
                                          onPressed: () => _editTask(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _deleteTask(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}