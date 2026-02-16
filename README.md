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
<img width="248" height="455" alt="Capture d’écran 2025-12-20 144341" src="https://github.com/user-attachments/assets/2bb4d643-35d4-4799-ba17-3ed7f18b77d5" />
<img width="246" height="377" alt="Capture d’écran 2025-12-20 144430" src="https://github.com/user-attachments/assets/36ce56f2-65a0-4548-ac05-3a68bb9e2594" />
<img width="245" height="450" alt="Capture d’écran 2025-12-20 144446" src="https://github.com/user-attachments/assets/7972cd4c-b2af-4233-8ce1-f4d01056020e" />
<img width="246" height="403" alt="Capture d’écran 2025-12-20 144558" src="https://github.com/user-attachments/assets/a2ebdc86-7c7d-4b03-a677-e2948d17cb49" />
<img width="249" height="452" alt="Capture d’écran 2025-12-20 144714" src="https://github.com/user-attachments/assets/86443535-cb0d-4ca9-a423-79ae0660257a" />
<img width="436" height="254" alt="Capture d’écran 2025-12-20 144749" src="https://github.com/user-attachments/assets/ef58689a-6d2c-42c8-9229-478b1e170f8b" />
<img width="708" height="283" alt="Capture d’écran 2025-12-20 144816" src="https://github.com/user-attachments/assets/ed174b16-545e-412b-834d-5e5852d8de55" />
<img width="246" height="355" alt="Capture d’écran 2025-12-20 145452" src="https://github.com/user-attachments/assets/a5478052-3cc5-4dd9-bca3-7d8fca06791f" />
<img width="248" height="451" alt="Capture d’écran 2025-12-20 145503" src="https://github.com/user-attachments/assets/3ae45980-c815-40d0-a401-233fb15c2d5a" />
<img width="250" height="452" alt="Capture d’écran 2025-12-20 145552" src="https://github.com/user-attachments/assets/9f98fe0a-e7a7-44d6-a674-89cd1b6b70d0" />
<img width="248" height="314" alt="Capture d’écran 2025-12-20 145623" src="https://github.com/user-attachments/assets/2b1d4ade-f312-4bb7-aa66-696465ce9fcd" />
<img width="247" height="360" alt="Capture d’écran 2025-12-20 145640" src="https://github.com/user-attachments/assets/fb89da4e-5601-4394-b531-aba79dfc389d" />
<img width="250" height="265" alt="Capture d’écran 2025-12-20 145654" src="https://github.com/user-attachments/assets/9921b44b-1d73-4e49-bd01-bdf27ae6e09d" />
<img width="247" height="298" alt="Capture d’écran 2025-12-20 145720" src="https://github.com/user-attachments/assets/050f55d6-c827-4537-a4aa-33dc8a86e08d" />


## Structure rapide
- `frontend/` : app Flutter (écrans auth, dashboard, budgets, objectifs, analyses, rapports, notifications, assistant vocal, profil).
- `backend/` : API Spring Boot (auth, budgets, analyses, voix/LLM, génération PDF).
- `testing_app/` : projet de démonstration pour tests Flutter (unit/widget/intégration).
- `capture application/` : captures d’écran utilisées ci-dessus.

## Notes
- Pensez à configurer vos secrets/clefs (LLM, e-mail, etc.) via variables d’environnement ou fichiers de conf dédiés.
- Les chemins des captures restent inchangés pour éviter toute suppression de fichiers existants.
