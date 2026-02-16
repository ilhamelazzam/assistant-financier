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
<img width="249" height="451" alt="Capture d’écran 2025-12-20 143605" src="https://github.com/user-attachments/assets/0a792c33-c9b5-4e14-9013-59eba2bf4df6" />
<img width="249" height="451" alt="Capture d’écran 2025-12-20 143605" src="https://github.com/user-attachments/assets/484bd30d-6947-4220-991c-54636a01bf6f" />
<img width="250" height="450" alt="Capture d’écran 2025-12-20 143946" src="https://github.com/user-attachments/assets/dca55dfd-0f57-4044-a4f6-47d47de63c89" />
<img width="251" height="451" alt="Capture d’écran 2025-12-20 144008" src="https://github.com/user-attachments/assets/ad075b3b-6620-4d8b-b823-d0efb4d7d7f0" />
<img width="248" height="454" alt="Capture d’écran 2025-12-20 144154" src="https://github.com/user-attachments/assets/6046dbf4-d75a-4910-8511-563c5eaf6c74" />
  <img width="246" height="419" alt="Capture d’écran 2025-12-20 144323" src="https://github.com/user-attachments/assets/7ca0ad3f-a183-40c6-ad47-d3a0333be970" />
/>






## Structure rapide
- `frontend/` : app Flutter (écrans auth, dashboard, budgets, objectifs, analyses, rapports, notifications, assistant vocal, profil).
- `backend/` : API Spring Boot (auth, budgets, analyses, voix/LLM, génération PDF).
- `testing_app/` : projet de démonstration pour tests Flutter (unit/widget/intégration).
- `capture application/` : captures d’écran utilisées ci-dessus.

## Notes
- Pensez à configurer vos secrets/clefs (LLM, e-mail, etc.) via variables d’environnement ou fichiers de conf dédiés.
- Les chemins des captures restent inchangés pour éviter toute suppression de fichiers existants.
