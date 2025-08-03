import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'project_manager_screen.dart';
import 'employee_screen.dart';
import 'Intern.dart';
import 'admin.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedRole;
  final List<String> roles = ['Admin', 'Project Manager', 'Employee', 'Intern'];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackbar("Please fill all required fields");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackbar("Passwords do not match");
      return;
    }

    if (_selectedRole == null) {
      _showSnackbar("Please select a role");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == 'success') {
        _showSnackbar('Welcome ${_nameController.text.trim()}');

        if (_selectedRole == 'Project Manager') {
          // Fetch userId for the newly created user
          final userResponse = await http.post(
            Uri.parse('http://127.0.0.1:5000/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            }),
          );

          final userData = jsonDecode(userResponse.body);
          if (userResponse.statusCode == 200 && userData['status'] == 'success') {
            final userId = userData['user_id'];
            // Fetch projectId for the project manager
            final projectResponse = await http.get(
              Uri.parse('http://127.0.0.1:5000/get_project_for_manager/$userId'),
            );
            final projectData = jsonDecode(projectResponse.body);

            if (projectResponse.statusCode == 200 && projectData['status'] == 'success') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectManagerScreen(
                    userId: userId,
                    projectId: projectData['project_id'],
                  ),
                ),
              );
            } else {
              _showSnackbar('No project assigned to this manager');
            }
          } else {
            _showSnackbar('Failed to retrieve user data');
          }
        } else {
          _navigateBasedOnRole(_selectedRole!);
        }
      } else {
        _showSnackbar(data['message'] ?? 'Signup failed');
      }
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('Error') || message.contains('failed')
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  void _navigateBasedOnRole(String role) {
    Widget destination;
    switch (role) {
      case "Admin":
        destination = AdminScreen(onLogout: () {
          Navigator.pop(context);
        });
        break;
      case "Employee":
        // Replace with actual userId if available, otherwise parse as int
        destination = EmployeeScreen(userId: int.tryParse(_emailController.text.trim()) ?? 0);
        break;
      case "Intern":
        destination = InternScreen(userId: int.tryParse(_emailController.text.trim()) ?? 0);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                'Worklify',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create your account to begin',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock,
                isObscure: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                isObscure: true,
              ),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 20),
              _buildButton("Sign Up", _isLoading ? () {} : _handleSignup),
              const SizedBox(height: 20),
              _buildGoogleButton(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
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

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      hint: Text(
        'Sign up as',
        style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
      ),
      items: roles.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(
            role,
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value;
        });
      },
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
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement Google Sign-In
      },
      icon: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
      label: Text(
        "Sign Up with Google",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    );
  }
}