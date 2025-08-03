import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InternScreen extends StatefulWidget {
  final int userId;

  const InternScreen({super.key, required this.userId});

  @override
  State<InternScreen> createState() => _InternScreenState();
}

class _InternScreenState extends State<InternScreen> {
  // Shared state
  int _currentScreenIndex = 0;
  final PageController _pageController = PageController();

  // Project Submission state
  final _formKeyProject = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoadingProject = false;

  // Profile Management state
  final _formKeyProfile = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String _availabilityStatus = "Available";
  String? _profileImage;
  bool _isLoadingProfile = false;

  // Assigned Tasks state
  List<Map<String, dynamic>> _assignedTasks = [];
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
    _fetchProfile();
    _fetchTasks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentScreenIndex = index),
              children: [
                _buildDashboard(),
                _buildProjectSubmissionScreen(),
                _buildProfileManagementScreen(),
                _buildAssignedTasksScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final screens = ['Dashboard', 'Project Submission', 'Profile Management', 'Assigned Tasks'];
    return AppBar(
      title: Text(screens[_currentScreenIndex]),
      backgroundColor: Theme.of(context).colorScheme.background,
      foregroundColor: Theme.of(context).colorScheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: TabBar(
        onTap: (index) => _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
        tabs: screens.map((title) => Tab(text: title)).toList(),
      ),
    );
  }

  Widget _buildDashboard() {
    final options = [
      {
        'title': 'Project Submission',
        'icon': Icons.upload_file,
        'onTap': () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      },
      {
        'title': 'Profile Management',
        'icon': Icons.person,
        'onTap': () => _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      },
      {
        'title': 'Assigned Tasks',
        'icon': Icons.task,
        'onTap': () => _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            'Intern Dashboard',
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
    );
  }

  Widget _buildProjectSubmissionScreen() {
    return _isLoadingProject
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
                  key: _formKeyProject,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: "Project Title",
                        isRequired: true,
                        formKey: _formKeyProject,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _descriptionController,
                        label: "Description",
                        formKey: _formKeyProject,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                ListView.builder(
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
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                                  : Theme.of(context).colorScheme.surface,
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
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
                                    "File: ${submission["name"]}",
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
                                    "Uploaded: ${submission["uploadDate"]}",
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
                                onPressed: () async {
                                  final response = await http.delete(
                                    Uri.parse('http://127.0.0.1:5000/delete_submission/${submission["id"]}'),
                                  );
                                  if (response.statusCode == 200) {
                                    setState(() => _submissions.removeAt(index));
                                    _showSnackbar("Submission deleted successfully");
                                  } else {
                                    _showSnackbar("Failed to delete submission");
                                  }
                                },
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
          );
  }

  Widget _buildProfileManagementScreen() {
    return _isLoadingProfile
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
                      backgroundImage: _profileImage != null ? NetworkImage(_profileImage!) : null,
                      child: _profileImage == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _uploadProfilePicture,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text("Change Profile Picture", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKeyProfile,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: "Name",
                        validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                        formKey: _formKeyProfile,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Role: Intern",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _bioController,
                        label: "Bio",
                        formKey: _formKeyProfile,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _availabilityStatus,
                        hint: Text(
                          'Availability Status',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                        items: ['Available', 'On Task', 'On Leave'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                            ),
                          );
                        }).toList(),
                        onChanged: (newStatus) => setState(() => _availabilityStatus = newStatus!),
                        decoration: InputDecoration(
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
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text("Update Profile", style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildAssignedTasksScreen() {
    return _isLoadingTasks
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
                ListView.builder(
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
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                                  : Theme.of(context).colorScheme.surface,
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
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
          );
  }

  // Common methods
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    GlobalKey<FormState>? formKey,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
      validator: validator ?? (isRequired ? (value) => value!.isEmpty ? "Please enter $label" : null : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        prefixIcon: Icon(
          label == "Project Title" || label == "Name" ? Icons.person : Icons.description,
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

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoadingProject = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_submissions/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['submissions'];
        setState(() {
          _submissions = data.cast<Map<String, dynamic>>();
          _isLoadingProject = false;
        });
      } else {
        throw Exception('Failed to load submissions: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingProject = false);
      _showSnackbar('Failed to load submissions: $e');
    }
  }

  Future<void> _submitProject() async {
    if (_formKeyProject.currentState!.validate()) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        setState(() => _isLoadingProject = true);
        try {
          final response = await http.post(
            Uri.parse('http://127.0.0.1:5000/submit_project'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': widget.userId,
              'title': _titleController.text,
              'description': _descriptionController.text.isEmpty ? 'No description' : _descriptionController.text,
              'file_name': result.files.single.name,
              'upload_date': DateFormat('dd-MM-yyyy').format(DateTime.now()),
            }),
          );
          if (response.statusCode == 201) {
            _fetchSubmissions();
            _titleController.clear();
            _descriptionController.clear();
            _showSnackbar('Project submitted successfully');
          } else {
            _showSnackbar('Failed to submit project: ${jsonDecode(response.body)['message']}');
          }
        } catch (e) {
          _showSnackbar('Error: $e');
        } finally {
          setState(() => _isLoadingProject = false);
        }
      } else {
        _showSnackbar('No file selected');
      }
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_profile/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? 'Jane Doe';
          _bioController.text = data['bio'] ?? 'Intern learning project management';
          _availabilityStatus = data['availability_status'] ?? 'Available';
          _profileImage = data['profile_image'] ?? 'https://via.placeholder.com/150';
          _isLoadingProfile = false;
        });
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      _showSnackbar('Failed to load profile: $e');
    }
  }

  void _updateProfile() {
    if (_formKeyProfile.currentState!.validate()) {
      setState(() => _isLoadingProfile = true);
      http.put(
        Uri.parse('http://127.0.0.1:5000/update_profile/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'bio': _bioController.text,
          'availability_status': _availabilityStatus,
        }),
      ).then((response) {
        setState(() => _isLoadingProfile = false);
        if (response.statusCode == 200) {
          _showSnackbar('Profile updated successfully');
        } else {
          _showSnackbar('Failed to update profile');
        }
      }).catchError((e) {
        setState(() => _isLoadingProfile = false);
        _showSnackbar('Error: $e');
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() => _isLoadingProfile = true);
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/upload_profile_picture/${widget.userId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'file_name': result.files.single.name}),
        );
        if (response.statusCode == 200) {
          setState(() {
            _profileImage = 'https://via.placeholder.com/150';
            _isLoadingProfile = false;
          });
          _showSnackbar('Profile picture updated');
        } else {
          _showSnackbar('Failed to update profile picture');
        }
      } catch (e) {
        setState(() => _isLoadingProfile = false);
        _showSnackbar('Error: $e');
      }
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_assigned_tasks/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['tasks'];
        setState(() {
          _assignedTasks = data.cast<Map<String, dynamic>>();
          _isLoadingTasks = false;
        });
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingTasks = false);
      _showSnackbar('Failed to load tasks: $e');
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