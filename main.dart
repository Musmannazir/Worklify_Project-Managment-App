import 'package:flutter/material.dart';
import 'loginscreen.dart';
import 'Signupscreen.dart';
import 'project_manager_screen.dart';
import 'employee_screen.dart';
import 'admin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _loggedInUserId;
  String? _loggedInRole;

  void _login(int userId, String role) {
    setState(() {
      _loggedInUserId = userId;
      _loggedInRole = role;
    });
  }

  void _logout() {
    setState(() {
      _loggedInUserId = null;
      _loggedInRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget homeScreen;
    if (_loggedInUserId == null) {
      homeScreen = LoginScreen(onLogin: _login);
    } else {
      switch (_loggedInRole) {
        case 'Project Manager':
          homeScreen = ProjectManagerScreen(userId: _loggedInUserId!, projectId: 1);
          break;
        case 'Employee':
        case 'Intern':
          homeScreen = EmployeeScreen(userId: _loggedInUserId!);
          break;
        case 'Admin':
          homeScreen = AdminScreen(onLogout: _logout);
          break;
        default:
          homeScreen = LoginScreen(onLogin: _login);
      }
    }

    return MaterialApp(
      title: 'Worklify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue[700]!,
          brightness: Brightness.dark,
          primary: Colors.blue[700],
          secondary: Colors.grey[300],
          error: Colors.redAccent,
        ),
        useMaterial3: true,
        textTheme: Typography.material2018().black.copyWith(
          bodyLarge: const TextStyle(color: Colors.white),
          headlineLarge: const TextStyle(color: Colors.white),
        ),
      ),
      home: homeScreen,
      routes: {
        '/login': (context) => LoginScreen(onLogin: _login),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}