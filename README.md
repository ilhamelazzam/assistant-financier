# Assistant Financier IA

Assistant financier web/mobile (Flutter) avec backend Spring Boot. L’application combine suivi budgétaire, objectifs, recommandations IA, assistant vocal et génération de rapports PDF.

## Fonctionnalités clés
- Authentification : inscription, connexion, réinitialisation par code e-mail.
- Dashboard : résumé du mois, raccourcis (assistant vocal, analyse, objectifs), notifications.
- Budgets : création/édition/suppression de catégories, seuils d’alerte, suivi d’usage.
- Objectifs financiers : création d’objectifs (montant, durée), progression, conseils IA.
- Analyses IA : revenus/dépenses, tendances, répartitions, recommandations actionnables.
- Rapports IA : score financier, analyse mensuelle, téléchargement PDF.
- Assistant vocal / chat : dialogue guidé par objectif, recommandations en contexte.
- Historique IA : conversations et recommandations sauvegardées, filtres et reprise.
- Profil : informations personnelles, localisation, bio, déconnexion.
- Notifications : alertes budget, opportunités d’économies, infos.

## Pile technique
- Frontend : Flutter (mobile & web), Provider pour l’état.
- Backend : Spring Boot (Java) – API REST, génération PDF, logique IA/LLM.
- Intégrations : voix/speech-to-text, géolocalisation, génération de rapports PDF.

## Démarrage rapide
### Backend
```bash
cd backend
./gradlew bootRun
# API sur http://localhost:8081 par défaut
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome          # web
# ou flutter run -d edge / -d emulator-5554
# Renderer HTML si besoin : flutter run -d chrome --web-renderer html
```

### Tests
- Flutter (unit/widget) : `flutter test`
- Flutter (intégration) : `flutter test integration_test`
- Backend (Spring) : `./gradlew test`

## Captures d’écran
Les captures sont dans `capture application/` :
- `Capture d'écran 2025-12-20 143605.png` – Authentification.
- `Capture d'écran 2025-12-20 143634.png` – Réinitialisation (code par e-mail).
- `Capture d'écran 2025-12-20 143946.png` – Vérifier le code / nouveau mot de passe.
- `Capture d'écran 2025-12-20 144008.png` – Création de compte.
- `Capture d'écran 2025-12-20 144154.png` – Tableau de bord / Coach financier IA.
- `Capture d'écran 2025-12-20 144323.png` – Analyse financière (revenus/dépenses).
- `Capture d'écran 2025-12-20 144341.png` – Rapport financier IA (PDF).
- `Capture d'écran 2025-12-20 144430.png` – Assistant vocal IA (chat guidé).
- `Capture d'écran 2025-12-20 144446.png` – Assistant vocal IA (réponse IA).
- `Capture d'écran 2025-12-20 144558.png` – Profil (édition).
- `Capture d'écran 2025-12-20 144714.png` – Gestion du budget (liste catégories).
- `Capture d'écran 2025-12-20 144749.png` – Ajout/édition d’un budget.
- `Capture d'écran 2025-12-20 144816.png` – Choix d’objectif.
- `Capture d'écran 2025-12-20 145452.png` – Objectifs financiers (liste).
- `Capture d'écran 2025-12-20 145503.png` – Notifications (alertes, opportunités).
- `Capture d'écran 2025-12-20 145552.png` – Rapports IA (score, reco, PDF).
- `Capture d'écran 2025-12-20 145623.png` – Historique IA (filtres, reprise).
- `Capture d'écran 2025-12-20 145640.png` – Assistant vocal IA (session active).
- `Capture d'écran 2025-12-20 145654.png` – Assistant vocal IA (actions proposées).
- `Capture d'écran 2025-12-20 145720.png` – Rapport financier IA (extrait PDF).

## Structure rapide
- `frontend/` : app Flutter (écrans auth, dashboard, budgets, objectifs, analyses, rapports, notifications, assistant vocal, profil).
- `backend/` : API Spring Boot (auth, budgets, analyses, voix/LLM, génération PDF).
- `testing_app/` : projet de démonstration pour tests Flutter (unit/widget/intégration).
- `capture application/` : captures d’écran utilisées ci-dessus.

## Notes
- Pensez à configurer vos secrets/clefs (LLM, e-mail, etc.) via variables d’environnement ou fichiers de conf dédiés.
- Les chemins des captures restent inchangés pour éviter toute suppression de fichiers existants.
