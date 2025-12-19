import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'reset_password_screen.dart';
import 'voice_assistant_screen.dart';
import 'goal_selection_screen.dart';
import 'budget_management_screen.dart';
import 'financial_analysis_screen.dart';
import 'financial_goals_screen.dart';
import 'chat_history_screen.dart';
import 'user_profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'ai_reports_screen.dart';
import 'reset_password_code_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
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
        '/reset-password-code': (context) => const ResetPasswordCodeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/voice-start': (context) => const GoalSelectionScreen(),
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
