import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class AdminScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminScreen({super.key, required this.onLogout});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
    _fetchAccounts();
    _fetchProjects();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_admin_analytics'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _analytics = data['analytics'] ?? {};
          _isLoading = false;
        });
      } else {
        developer.log('Failed to load analytics: ${response.statusCode} - ${response.body}');
        setState(() => _isLoading = false);
        _showSnackbar('Failed to load analytics. Status: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Analytics fetch error: $e');
      setState(() => _isLoading = false);
      _showSnackbar('Error fetching analytics: $e');
    }
  }

  Future<void> _fetchAccounts() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_all_accounts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _accounts = (data['accounts'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
        });
      } else {
        developer.log('Failed to load accounts: ${response.statusCode} - ${response.body}');
        _showSnackbar('Failed to load accounts. Status: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Accounts fetch error: $e');
      _showSnackbar('Error fetching accounts: $e');
    }
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_all_projects'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _projects = (data['projects'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
        });
      } else {
        developer.log('Failed to load projects: ${response.statusCode} - ${response.body}');
        _showSnackbar('Failed to load projects. Status: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Projects fetch error: $e');
      _showSnackbar('Error fetching projects: $e');
    }
  }

  // --- NEW: Fetch all assigned tasks ---
  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_all_tasks'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tasks = (data['tasks'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
        });
      } else {
        developer.log('Failed to load tasks: ${response.statusCode} - ${response.body}');
        _showSnackbar('Failed to load tasks. Status: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Tasks fetch error: $e');
      _showSnackbar('Error fetching tasks: $e');
    }
  }

  // --- NEW: Show all assigned tasks dialog ---
  Future<void> _showTasksDialog(BuildContext context) async {
    await _fetchTasks();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('All Assigned Tasks'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks found.'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return ListTile(
                        title: Text(task['title'] ?? 'No Title'),
                        subtitle: Text(
                          'Assigned to: ${task['assigned_to'] ?? 'N/A'}\n'
                          'Status: ${task['status'] ?? 'N/A'}\n'
                          'Deadline: ${task['deadline'] ?? 'N/A'}',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeRole(int accountId, String newRole) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/change_role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'account_id': accountId, 'role': newRole}),
      );
      if (response.statusCode == 200) {
        _fetchAccounts();
        _showSnackbar('Role changed successfully');
      } else {
        throw Exception('Failed to change role: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Failed to change role: $e');
    }
  }

  Future<void> _deleteAccount(int accountId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'account_id': accountId}),
      );
      if (response.statusCode == 200) {
        _fetchAccounts();
        _showSnackbar('Account deleted successfully');
      } else {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Failed to delete account: $e');
    }
  }

  Future<void> _deleteProject(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:5000/delete_project'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'project_id': projectId}),
      );
      if (response.statusCode == 200) {
        _fetchProjects();
        _showSnackbar('Project deleted successfully');
      } else {
        throw Exception('Failed to delete project: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Failed to delete project: $e');
    }
  }

  Future<void> _addAccount(String name, String role) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/add_account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'role': role}),
      );
      if (response.statusCode == 200) {
        _fetchAccounts();
        _showSnackbar('Account added successfully');
      } else {
        throw Exception('Failed to add account: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Failed to add account: $e');
    }
  }

  Future<void> _addProject(String name, int progress) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/add_project'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'progress': progress, 'status': 'In Progress'}),
      );
      if (response.statusCode == 200) {
        _fetchProjects();
        _showSnackbar('Project added successfully');
      } else {
        throw Exception('Failed to add project: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Failed to add project: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.primary),
    );
  }
  
  void _showManageScreen(BuildContext context, String type, List<Map<String, dynamic>> items, Future<void> Function(String, dynamic) addFunction) {
    final _nameController = TextEditingController();
    dynamic _roleOrProgress;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Manage $type'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: type == 'Projects' ? 'Title' : 'Name'),
                ),
                if (type == 'Accounts')
                  DropdownButton<String>(
                    value: _roleOrProgress is String ? _roleOrProgress : null,
                    hint: const Text('Select Role'),
                    items: ['Admin', 'Project Manager', 'Employee', 'Intern']
                        .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                        .toList(),
                    onChanged: (value) => setState(() => _roleOrProgress = value),
                  )
                else if (type == 'Projects')
                  TextField(
                    decoration: InputDecoration(labelText: 'Progress (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _roleOrProgress = int.tryParse(value) ?? 0,
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text('${item['name']} ${type == 'Accounts' ? '(${item['role'] ?? 'N/A'})' : '(Status: ${item['status'] ?? 'N/A'}, Progress: ${item['progress']?.toStringAsFixed(1) ?? '0.0'}%)'}'),
                        subtitle: Text('ID: ${item['id'] ?? 'N/A'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            final id = item['id'] as int?;
                            if (id != null) {
                              if (type == 'Accounts') _deleteAccount(id);
                              else _deleteProject(id);
                            } else {
                              _showSnackbar('Invalid ID for deletion');
                            }
                            Navigator.pop(context);
                            _showManageScreen(context, type, items, addFunction);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (type == 'Accounts' && _roleOrProgress is String && _nameController.text.isNotEmpty) {
                  addFunction(_nameController.text, _roleOrProgress);
                } else if (type == 'Projects' && _roleOrProgress is int && _nameController.text.isNotEmpty) {
                  addFunction(_nameController.text, _roleOrProgress);
                } else {
                  _showSnackbar('Please fill all fields correctly');
                }
                Navigator.pop(context);
                _showManageScreen(context, type, items, addFunction);
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    List<Map<String, dynamic>> _members = [];
    bool _isLoadingMembers = true;

    // Fetch members
    Future<void> _fetchMembers() async {
      try {
        final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_team_members'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _members = (data['members'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
            _isLoadingMembers = false;
          });
        } else {
          developer.log('Failed to load members: ${response.statusCode} - ${response.body}');
          _showSnackbar('Failed to load members. Status: ${response.statusCode}');
        }
      } catch (e) {
        developer.log('Members fetch error: $e');
        _showSnackbar('Error fetching members: $e');
      }
    }

    // Assign member to project
    Future<void> _assignMemberToProject(int userId, int projectId) async {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/assign_member_to_project'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'project_id': projectId}),
        );
        if (response.statusCode == 201) {
          _showSnackbar('Member assigned to project successfully');
          _fetchMembers();
        } else {
          throw Exception('Failed to assign member: ${response.statusCode}');
        }
      } catch (e) {
        _showSnackbar('Failed to assign member: $e');
      }
    }

    _fetchMembers();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Members & Permissions'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return ListTile(
                        title: Text('${member['name']} (${member['job']})'),
                        subtitle: Text('Status: ${member['status']} | Experience: ${member['experience']} years'),
                        trailing: DropdownButton<int>(
                          hint: const Text('Assign to Project'),
                          items: _projects
                              .map<DropdownMenuItem<int>>((project) => DropdownMenuItem<int>(
                                    value: project['id'] as int,
                                    child: Text(project['name']),
                                  ))
                              .toList(),
                          onChanged: (projectId) {
                            if (projectId != null) {
                              _assignMemberToProject(member['user_id'], projectId);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'title': 'Accounts',
        'icon': Icons.account_circle,
        'onTap': () => _showManageScreen(context, 'Accounts', _accounts, (name, value) => _addAccount(name, value as String)),
      },
      {
        'title': 'Projects',
        'icon': Icons.work,
        'onTap': () => _showTasksDialog(context), // <-- Show all assigned tasks
      },
      {
        'title': 'Members & Permissions',
        'icon': Icons.group,
        'onTap': () => _showPermissionsDialog(context),
      },
      {
        'title': 'Analytics',
        'icon': Icons.analytics,
        'onTap': () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Analytics Charts'),
              content: Container(
                width: 400,
                height: 300,
                child: CanvasPanel(
                  child: Column(
                    children: [
                      const Text('Project Status Distribution'),
                      CustomPaint(
                        painter: BarChartPainter([
                          {'value': _analytics['completed_projects'] ?? 0, 'label': 'Completed'},
                          {'value': _analytics['pending_projects'] ?? 0, 'label': 'Pending'},
                          {'value': _analytics['in_progress_projects'] ?? 0, 'label': 'In Progress'},
                        ]),
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
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
                          'Analytics Overview',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Projects: ${_analytics['total_projects'] ?? 0}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                        Text(
                          'Completed Projects: ${_analytics['completed_projects'] ?? 0}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                        Text(
                          'Pending Projects: ${_analytics['pending_projects'] ?? 0}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                        Text(
                          'In Progress Projects: ${_analytics['in_progress_projects'] ?? 0}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                        Text(
                          'Total Members: ${_analytics['total_members'] ?? 0}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                        Text(
                          'Active Managers: ${_analytics['active_managers'] ?? 0}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: options.map((option) {
                      return HoverBox(
                        title: option['title'] as String,
                        icon: option['icon'] as IconData,
                        onTap: option['onTap'] as VoidCallback,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      widget.onLogout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text("Logout", style: TextStyle(fontSize: 16)),
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

class CanvasPanel extends StatelessWidget {
  final Widget child;

  const CanvasPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      developer.log('No data to render in BarChartPainter');
      return;
    }
    final paint = Paint()..color = Colors.blue;
    final double barWidth = size.width / (data.length * 2);
    double maxValue = data.map((d) => d['value'] as num).reduce((a, b) => a > b ? a : b).toDouble();

    for (int i = 0; i < data.length; i++) {
      final value = data[i]['value'] as num;
      final height = (value / maxValue) * (size.height - 20);
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth * 2,
          size.height - height,
          barWidth,
          height,
        ),
        paint,
      );
      TextPainter(
        text: TextSpan(text: '${data[i]['label']}: ${value.toString()}', style: const TextStyle(color: Colors.white)),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(i * barWidth * 2, size.height - height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}