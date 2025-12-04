import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/voice_assistant_screen.dart';
import 'screens/budget_management_screen.dart';
import 'screens/financial_analysis_screen.dart';
import 'screens/financial_goals_screen.dart';
import 'screens/chat_history_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/ai_reports_screen.dart';

void main() {
  runApp(const FinanceCoachApp());
}

class FinanceCoachApp extends StatelessWidget {
  const FinanceCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistant Coaching Financier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/voice': (context) => const VoiceAssistantScreen(),
        '/budget': (context) => const BudgetManagementScreen(),
        '/analysis': (context) => const FinancialAnalysisScreen(),
        '/goals': (context) => const FinancialGoalsScreen(),
        '/history': (context) => const ChatHistoryScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/reports': (context) => const AIReportsScreen(),
      },
    );
  }
}
