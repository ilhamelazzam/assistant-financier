import 'package:coaching_financier/main.dart';
import 'package:coaching_financier/models/analysis_models.dart';
import 'package:coaching_financier/models/auth_response.dart';
import 'package:coaching_financier/models/budget_models.dart';
import 'package:coaching_financier/models/user_profile.dart';
import 'package:coaching_financier/services/backend_api.dart';
import 'package:coaching_financier/services/backend_factory.dart';
import 'package:coaching_financier/services/location_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class FakeBackendApi extends BackendApi {
  AuthResponse _user = AuthResponse(
    userId: 1,
    email: 'test@example.com',
    displayName: 'Test User',
  );

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    _user = AuthResponse(userId: 1, email: email, displayName: 'Test User');
    return _user;
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String? location,
  }) async {
    _user = AuthResponse(
      userId: 1,
      email: email,
      displayName: displayName ?? 'Test User',
    );
    return _user;
  }

  @override
  Future<BudgetSnapshot> fetchBudgetSnapshot({int? year, int? month}) async {
    final now = DateTime.now();
    return BudgetSnapshot(
      month: now.month,
      year: now.year,
      totalBudget: 1200,
      totalSpent: 400,
      remaining: 800,
      categories: [
        BudgetCategory(
          id: 1,
          category: 'Alimentation',
          budgetAmount: 500,
          spentAmount: 200,
          remaining: 300,
          usage: 0.4,
          periodType: BudgetPeriodType.monthly,
          periodMonth: now.month,
          periodYear: now.year,
          periodLabel: 'Mois en cours',
          alertThreshold: 80,
          note: 'Test',
          customStart: null,
          customEnd: null,
        ),
      ],
      advice: const BudgetTip(
        tone: 'info',
        message: 'Continuez ainsi',
        category: 'general',
      ),
    );
  }

  @override
  Future<FinancialAnalysis> fetchFinancialAnalysis() async {
    final month = PeriodAnalysis(
      revenue: 3200,
      revenueChange: 5,
      expense: 1500,
      expenseChange: -3,
      revenueTrend: const [3000, 3200, 3300],
      expenseTrend: const [1400, 1500, 1550],
      distribution: const [
        CategoryShare(label: 'Logement', value: 40, colorHex: '#4A90E2'),
        CategoryShare(label: 'Courses', value: 20, colorHex: '#00B8A9'),
      ],
      insightTitle: 'Analyse IA',
      insightBody: 'Vos depenses restent maitrisees.',
      recommendations: const ['Continuer a surveiller les loisirs'],
    );
    return FinancialAnalysis(periods: {AnalysisPeriod.month: month});
  }

  @override
  Future<UserProfile> fetchUserProfile(int userId) async {
    return UserProfile(
      id: userId,
      displayName: _user.displayName,
      email: _user.email,
      phoneNumber: '0612345678',
      location: 'Paris, France',
      memberSince: DateTime(2024, 1, 1),
      bio: 'Bio test',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    BackendFactory.overrideInstance = FakeBackendApi();
    LocationFactory.resolver = () async => 'Paris, France';
  });

  tearDownAll(() {
    BackendFactory.overrideInstance = null;
    LocationFactory.resolver = null;
  });

  testWidgets('flux de connexion et bascule inscription', (tester) async {
    await tester.pumpWidget(const FinanceCoachApp());
    await tester.pump();

    expect(find.text('Authentification'), findsOneWidget);

    await tester.tap(find.text("S'inscrire"));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Confirmer le mot de passe'), findsWidgets);
  });

  testWidgets('saisie des champs en mode inscription', (tester) async {
    await tester.pumpWidget(const FinanceCoachApp());
    await tester.pump();

    await tester.tap(find.text("S'inscrire"));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).at(0), 'signup@example.com'); // email
    await tester.enterText(find.byType(TextField).at(1), 'Password123!'); // mot de passe
    await tester.enterText(find.byType(TextField).at(2), 'Password123!'); // confirmation
    await tester.enterText(find.byType(TextField).at(3), '0612345678'); // téléphone
    await tester.enterText(find.byType(TextField).at(4), 'Paris'); // localisation
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('signup@example.com'), findsOneWidget);
    expect(find.text('Password123!'), findsNWidgets(2));
    expect(find.text('0612345678'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
  });

  testWidgets('connexion puis navigation dashboard/budget/rapports', (tester) async {
    await tester.pumpWidget(const FinanceCoachApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Password123!');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bonjour'), findsOneWidget);
    expect(find.text('Taches rapides'), findsOneWidget);

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Gestion du Budget'), findsOneWidget);
    expect(find.text('Alimentation'), findsOneWidget);

    await tester.tap(find.text('Rapports'));
    await tester.pumpAndSettle();
    expect(find.text('Rapports IA'), findsOneWidget);
  });
}
