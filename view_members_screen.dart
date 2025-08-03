import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ViewMembersScreen extends StatefulWidget {
  final int projectId; // Added to associate members with a project
  final int? taskId; // Optional taskId for assigning members to a specific task

  const ViewMembersScreen({super.key, required this.projectId, this.taskId});

  @override
  State<ViewMembersScreen> createState() => _ViewMembersScreenState();
}

class _ViewMembersScreenState extends State<ViewMembersScreen> {
  List<Member> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTeamMembers();
  }

  Future<void> fetchTeamMembers() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_team_members'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['members'];
        setState(() {
          members = data.map((e) => Member.fromJson(e)).toList();
          isLoading = false;
        });

        // Check which members are assigned to the task (if taskId is provided)
        if (widget.taskId != null) {
          final taskAssignmentsResponse = await http.get(
            Uri.parse('http://127.0.0.1:5000/get_assigned_tasks/${members[0].userId}'),
          );
          if (taskAssignmentsResponse.statusCode == 200) {
            final List tasks = jsonDecode(taskAssignmentsResponse.body)['tasks'];
            setState(() {
              for (var member in members) {
                member.assigned = tasks.any((task) => task['task_id'] == widget.taskId && task['user_id'] == member.userId);
              }
            });
          }
        }
      } else {
        throw Exception('Failed to load members');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load members: $e')),
      );
    }
  }

  Future<void> toggleMemberAssignment(Member member) async {
    try {
      if (widget.taskId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No task selected for assignment')),
        );
        return;
      }

      final url = member.assigned
          ? 'http://127.0.0.1:5000/remove_member_from_task'
          : 'http://127.0.0.1:5000/assign_member_to_task';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'task_id': widget.taskId,
          'user_id': member.userId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          member.assigned = !member.assigned;
          member.status = member.assigned ? 'On Another Project' : 'Available';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              member.assigned ? 'Member added to task' : 'Member removed from task',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Members"),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Company Members:",
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
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return _buildMemberBox(context, member, index);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMemberBox(BuildContext context, Member member, int index) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {},
            child: AnimatedContainer(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              height: 120,
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(member.imageUrl),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          member.name,
                          style: TextStyle(
                            color: isHovered
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onBackground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Job: ${member.job}",
                          style: TextStyle(
                            color: isHovered
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          "Experience: ${member.experience} years",
                          style: TextStyle(
                            color: isHovered
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          "Status: ${member.status}",
                          style: TextStyle(
                            color: isHovered
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      member.assigned ? Icons.remove_circle : Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => toggleMemberAssignment(member),
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

class Member {
  final int userId;
  final String name;
  final String job;
  final int experience;
  String status;
  final String imageUrl;
  bool assigned;

  Member({
    required this.userId,
    required this.name,
    required this.job,
    required this.experience,
    required this.status,
    required this.imageUrl,
    required this.assigned,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['user_id'] as int,
      name: json['name'] as String,
      job: json['job'] as String,
      experience: json['experience'] as int,
      status: json['status'] as String,
      imageUrl: json['imageUrl'] as String? ?? 'https://via.placeholder.com/50',
      assigned: json['assigned'] as bool? ?? false,
    );
  }
}