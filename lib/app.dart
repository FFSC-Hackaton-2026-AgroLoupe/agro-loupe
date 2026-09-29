import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/ai_config.dart';
import 'core/constants/app_constants.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/photo_service.dart';
import 'core/theme/app_theme.dart';
import 'features/diagnosis/data/classifier_service.dart';
import 'features/diagnosis/data/diagnosis_repository.dart';
import 'features/diagnosis/data/second_opinion_service.dart';
import 'features/diagnosis/state/diagnosis_provider.dart';
import 'features/diagnosis/state/second_opinion_provider.dart';
import 'features/onboarding/data/onboarding_storage.dart';
import 'features/onboarding/state/coach_controller.dart';
import 'features/onboarding/ui/screens/onboarding_screen.dart';
import 'features/shell/ui/screens/app_shell.dart';
import 'features/treatments/data/treatment_repository.dart';
import 'features/treatments/state/treatment_provider.dart';

/// Racine de l'application : injection des dépendances, puis thème et écrans.
class AgroLoupeApp extends StatelessWidget {
  const AgroLoupeApp({
    super.key,
    this.connectivityService,
    this.diagnosisRepository,
    this.treatmentRepository,
    this.secondOpinionService,
    this.showOnboarding = false,
    this.showCoachMarks = true,
  });

  /// Affiche la présentation avant la coquille. Vrai au premier lancement.
  final bool showOnboarding;

  /// Affiche le tutoriel. Les tests le coupent pour atteindre l'application.
  final bool showCoachMarks;

  /// Permettent aux tests de fournir des doublures. En production, laisser
  /// `null` : l'application crée elle-même les instances réelles.
  final ConnectivityService? connectivityService;
  final DiagnosisRepository? diagnosisRepository;
  final TreatmentRepository? treatmentRepository;

  /// Deuxieme avis en ligne. `null` en production : l'application le construit
  /// elle-meme a partir de [AiConfig], et s'en passe s'il n'est pas configure.
  final SecondOpinionService? secondOpinionService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Services transverses (une seule instance pour toute l'application).
        Provider<ConnectivityService>(
          create: (_) => connectivityService ?? ConnectivityService(),
        ),
        Provider<PhotoService>(create: (_) => PhotoService()),
        Provider<ClassifierService>(
          create: (_) => ClassifierService(),
          // Libère les interpréteurs natifs à la fermeture.
          dispose: (_, service) => service.close(),
        ),

        // 2. Flux dérivés d'un service, lus directement par l'interface.
        //    `initialData` est optimiste : tant qu'on ne sait pas, on n'affiche
        //    aucun avertissement plutôt qu'un bandeau qui clignote au démarrage.
        StreamProvider<ConnectionStatus>(
          create: (context) =>
              context.read<ConnectivityService>().onStatusChanged,
          initialData: ConnectionStatus.online,
        ),

        // 3. Repositories : ils orchestrent les services.
        ProxyProvider2<ClassifierService, PhotoService, DiagnosisRepository>(
          update: (_, classifier, photos, _) =>
              diagnosisRepository ?? DiagnosisRepository(classifier, photos),
        ),
        Provider<TreatmentRepository>(
          create: (_) => treatmentRepository ?? TreatmentRepository(),
        ),

        // 4. États d'écran.
        ChangeNotifierProvider<DiagnosisProvider>(
          create: (context) =>
              DiagnosisProvider(context.read<DiagnosisRepository>()),
        ),
        // Les fiches sont chargées dès le démarrage : le fichier est petit, et
        // une fiche doit s'afficher sans attente après un diagnostic.
        // Sans configuration en ligne, le service reste `null` et
        // l'interface masque simplement le bouton : le diagnostic
        // hors-ligne, lui, ne depend de rien de tout cela.
        // Relance du tutoriel : demandée depuis la barre de titre de
        // l'accueil, exécutée par la coquille, qui porte le voile.
        ChangeNotifierProvider<CoachController>(
          create: (_) => CoachController(),
        ),
        ChangeNotifierProvider<SecondOpinionProvider>(
          create: (_) =>
              SecondOpinionProvider(secondOpinionService ?? _serviceEnLigne()),
        ),
        ChangeNotifierProvider<TreatmentProvider>(
          create: (context) =>
              TreatmentProvider(context.read<TreatmentRepository>())..load(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: _Entree(
          showOnboarding: showOnboarding,
          showCoachMarks: showCoachMarks,
        ),
      ),
    );
  }

  /// Crée le service en ligne, ou `null` si `.env` ne le configure pas.
  static SecondOpinionService? _serviceEnLigne() {
    if (!AiConfig.isConfigured) return null;
    return SecondOpinionService(
      baseUrl: AiConfig.baseUrl,
      apiKey: AiConfig.apiKey,
      model: AiConfig.model,
    );
  }
}

/// Présentation au premier lancement, puis l'application.
///
/// Le passage de l'une à l'autre se fait sans redémarrage : la présentation
/// n'est qu'un écran de plus, pas une étape de démarrage.
class _Entree extends StatefulWidget {
  const _Entree({required this.showOnboarding, required this.showCoachMarks});

  final bool showOnboarding;
  final bool showCoachMarks;

  @override
  State<_Entree> createState() => _EntreeState();
}

class _EntreeState extends State<_Entree> {
  late bool _presentation = widget.showOnboarding;

  void _termine() {
    // On note d'abord, on bascule ensuite : si l'écriture échoue, la
    // présentation réapparaîtra, ce qui est sans gravité.
    const OnboardingStorage().markSeen();
    setState(() => _presentation = false);
  }

  @override
  Widget build(BuildContext context) => _presentation
      ? OnboardingScreen(onDone: _termine)
      : AppShell(coachMarks: widget.showCoachMarks);
}
