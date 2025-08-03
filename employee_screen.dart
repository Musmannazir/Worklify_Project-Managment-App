import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeeScreen extends StatelessWidget {
  final int userId; // Added to pass userId for database queries

  const EmployeeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text(
                "Error loading analytics: ${snapshot.error ?? 'Unknown error'}",
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
              ),
            ),
          );
        }

        final analytics = snapshot.data!;
        final totalTasks = analytics['total_tasks'] ?? 0;
        final completedTasks = analytics['completed_tasks'] ?? 0;
        final averageProgress = analytics['average_progress']?.toStringAsFixed(1) ?? '0.0';

        final options = [
          {
            'title': 'Project Submission',
            'icon': Icons.upload_file,
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectSubmissionScreen(userId: userId),
                  ),
                ),
          },
          {
            'title': 'Profile Management',
            'icon': Icons.person,
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileManagementScreen(userId: userId),
                  ),
                ),
          },
          {
            'title': 'Assigned Tasks',
            'icon': Icons.task,
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignedTasksScreen(userId: userId),
                  ),
                ),
          },
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text("Employee Dashboard"),
            backgroundColor: Theme.of(context).colorScheme.background,
            foregroundColor: Theme.of(context).colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Text(
                  'Employee Dashboard',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Analytics Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Analytics',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Total Tasks Assigned: $totalTasks',
                        style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                      ),
                      Text(
                        'Tasks Completed: $completedTasks',
                        style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                      ),
                      Text(
                        'Average Progress: $averageProgress%',
                        style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                      ),
                    ],
                  ),
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
      },
    );
  }

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_employee_analytics/$userId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['analytics'];
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
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

class ProjectSubmissionScreen extends StatefulWidget {
  final int userId;

  const ProjectSubmissionScreen({super.key, required this.userId});

  @override
  State<ProjectSubmissionScreen> createState() => _ProjectSubmissionScreenState();
}

class _ProjectSubmissionScreenState extends State<ProjectSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _tasks = [];
  int? _selectedTaskId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
    _fetchTasks();
  }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_submissions/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['submissions'];
        setState(() {
          _submissions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load submissions: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading submissions: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_assigned_tasks/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['tasks'];
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading tasks: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _submitProject() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTaskId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please select a task"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        final submission = {
          'user_id': widget.userId,
          'project_id': _tasks.firstWhere((task) => task['task_id'] == _selectedTaskId)['project_id'],
          'task_id': _selectedTaskId,
          'title': _titleController.text,
          'description': _descriptionController.text.isEmpty ? "No description" : _descriptionController.text,
          'file_name': result.files.single.name,
          'file_url': 'https://example.com/uploads/${result.files.single.name}', // Simulated URL
        };

        try {
          final response = await http.post(
            Uri.parse('http://127.0.0.1:5000/submit_project'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(submission),
          );

          if (response.statusCode == 201) {
            // Update task progress
            await http.post(
              Uri.parse('http://127.0.0.1:5000/update_task_progress'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'task_id': _selectedTaskId,
                'progress_increment': 20.0, // Increment by 20% per submission
              }),
            );

            await _fetchSubmissions();
            _titleController.clear();
            _descriptionController.clear();
            setState(() {
              _selectedTaskId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Project submitted successfully"),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          } else {
            final data = jsonDecode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed: ${data['message']}"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No file selected"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubmission(int index) async {
    final submissionId = _submissions[index]['submission_id'];
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_submission/$submissionId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _submissions.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Submission deleted successfully"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${data['message']}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
      validator: isRequired
          ? (value) => value!.isEmpty ? "Please enter $label" : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        prefixIcon: Icon(
          label == "Project Title" ? Icons.title : Icons.description,
          color: Theme.of(context).colorScheme.primary,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Submission"),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Submit Project",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: "Project Title",
                          isRequired: true,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _descriptionController,
                          label: "Description",
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: _selectedTaskId,
                          hint: Text(
                            'Select Task',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          items: _tasks.map<DropdownMenuItem<int>>((task) {
                            return DropdownMenuItem<int>(
                              value: task['task_id'] as int,
                              child: Text(
                                task['title'],
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTaskId = value;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitProject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text("Submit Project", style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Submitted Projects",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _submissions.isEmpty
                      ? Text(
                          "No submissions yet",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 16,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _submissions.length,
                          itemBuilder: (context, index) {
                            final submission = _submissions[index];
                            bool isHovered = false;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => setState(() => isHovered = true),
                                  onExit: (_) => setState(() => isHovered = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.8)
                                          : Theme.of(context).colorScheme.surface,
                                      border: Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        submission["title"],
                                        style: TextStyle(
                                          color: isHovered
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Theme.of(context).colorScheme.onBackground,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Task: ${_tasks.firstWhere((task) => task['task_id'] == submission['task_id'], orElse: () => {'title': 'Unknown'})['title']}",
                                            style: TextStyle(
                                              color: isHovered
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            "File: ${submission["file_name"]}",
                                            style: TextStyle(
                                              color: isHovered
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            "Description: ${submission["description"]}",
                                            style: TextStyle(
                                              color: isHovered
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            "Uploaded: ${submission["upload_date"]}",
                                            style: TextStyle(
                                              color: isHovered
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _deleteSubmission(index),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}

class ProfileManagementScreen extends StatefulWidget {
  final int userId;

  const ProfileManagementScreen({super.key, required this.userId});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  String _availabilityStatus = "Available";
  String? _profileImage = "https://via.placeholder.com/150";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_profile/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['profile'];
        setState(() {
          _nameController.text = data['name'];
          _jobController.text = data['job_title'] ?? '';
          _experienceController.text = data['experience_years']?.toString() ?? '0';
          _bioController.text = data['bio'] ?? '';
          _availabilityStatus = data['availability_status'] ?? 'Available';
          _profileImage = data['profile_image_url'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading profile: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = {
        'user_id': widget.userId,
        'name': _nameController.text,
        'job_title': _jobController.text,
        'experience_years': int.parse(_experienceController.text),
        'bio': _bioController.text,
        'availability_status': _availabilityStatus,
        'profile_image_url': _profileImage,
      };

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/update_profile'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(profile),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Profile updated successfully"),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${data['message']}"),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _profileImage = 'https://example.com/uploads/${result.files.single.name}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile picture updated"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _updateAvailability(String? newStatus) {
    if (newStatus != null) {
      setState(() {
        _availabilityStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Availability status updated to $newStatus"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        prefixIcon: Icon(
          label == "Name"
              ? Icons.person
              : label == "Job Title"
                  ? Icons.work
                  : label == "Experience (Years)"
                      ? Icons.history
                      : Icons.description,
          color: Theme.of(context).colorScheme.primary,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Management"),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profile Details",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _profileImage != null ? NetworkImage(_profileImage!) : null,
                        child: _profileImage == null ? const Icon(Icons.person, size: 40) : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _uploadProfilePicture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Change Profile Picture",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: "Name",
                          validator: (value) =>
                              value!.isEmpty ? "Please enter your name" : null,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _jobController,
                          label: "Job Title",
                          validator: (value) =>
                              value!.isEmpty ? "Please enter your job title" : null,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _experienceController,
                          label: "Experience (Years)",
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) return "Please enter your experience";
                            if (int.tryParse(value) == null) {
                              return "Please enter a valid number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _bioController,
                          label: "Bio",
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _availabilityStatus,
                          hint: Text(
                            'Availability Status',
                            style:
                                TextStyle(color: Theme.of(context).colorScheme.onBackground),
                          ),
                          items: ['Available', 'On Project', 'On Leave'].map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onBackground),
                              ),
                            );
                          }).toList(),
                          onChanged: _updateAvailability,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text("Update Profile", style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AssignedTasksScreen extends StatefulWidget {
  final int userId;

  const AssignedTasksScreen({super.key, required this.userId});

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  List<Map<String, dynamic>> _assignedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_assigned_tasks/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['tasks'];
        setState(() {
          _assignedTasks = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading tasks: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Tasks"),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Assigned Tasks",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _assignedTasks.isEmpty
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
                          itemCount: _assignedTasks.length,
                          itemBuilder: (context, index) {
                            final task = _assignedTasks[index];
                            bool isHovered = false;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => setState(() => isHovered = true),
                                  onExit: (_) => setState(() => isHovered = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 15),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.8)
                                          : Theme.of(context).colorScheme.surface,
                                      border: Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2),
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
                                          "Description: ${task["description"]}",
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
                                        Text(
                                          "Members: ${task["members"]}",
                                          style: TextStyle(
                                            color: isHovered
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        LinearProgressIndicator(
                                          value: task["progress"] / 100,
                                          backgroundColor: Theme.of(context).colorScheme.surface,
                                          color: Theme.of(context).colorScheme.primary,
                                          minHeight: 10,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Progress: ${task["progress"].toStringAsFixed(1)}%",
                                          style: TextStyle(
                                            color: isHovered
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}