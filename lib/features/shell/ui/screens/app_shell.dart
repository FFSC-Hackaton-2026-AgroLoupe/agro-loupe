import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../diagnosis/state/diagnosis_provider.dart';
import '../../../diagnosis/ui/screens/home_screen.dart';
import '../../../history/ui/screens/history_screen.dart';
import '../../../onboarding/data/onboarding_storage.dart';
import '../../../onboarding/state/coach_controller.dart';
import '../../../onboarding/ui/coach_targets.dart';
import '../../../onboarding/ui/widgets/coach_overlay.dart';
import '../../../treatments/ui/screens/catalog_screen.dart';

/// Coquille de l'application : les trois onglets et leur barre de navigation.
///
/// Un seul onglet est construit à la fois, volontairement. L'état ne vit pas
/// dans les widgets mais dans les providers : un diagnostic en cours survit
/// donc à un aller-retour vers un autre onglet sans qu'il faille maintenir
/// les écrans en vie.
///
/// Garder les trois écrans montés — avec un `IndexedStack` — aurait un effet
/// de bord discret : le `PopScope` de [HomeScreen] resterait enregistré
/// depuis les autres onglets, et le bouton retour du téléphone reculerait
/// dans un diagnostic que l'utilisateur n'a plus sous les yeux.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.coachMarks = true});

  /// Affiche le tutoriel. Mis à `false` par les tests, qui veulent
  /// l'application nue.
  final bool coachMarks;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Les trois repères de l'accueil, dans l'ordre du parcours.
  static final List<CoachStep> _tutoAccueil = [
    CoachStep(
      key: CoachTargets.cropSelector,
      title: 'Choisissez votre culture',
      body:
          "L'analyse ne cherche que les maladies de cette plante. C'est ce "
          'qui rend le résultat plus sûr.',
    ),
    CoachStep(
      key: CoachTargets.photoButton,
      title: 'Photographiez une feuille',
      body:
          'Une seule feuille, de près, en plein jour. Le résultat arrive en '
          'quelques secondes, sans connexion.',
    ),
    CoachStep(
      key: CoachTargets.navBar,
      title: 'Vos trois onglets',
      body:
          'Le diagnostic ici, toutes les maladies dans le catalogue, et vos '
          "analyses passées dans l'historique.",
    ),
  ];

  /// Une seule bulle, sur l'étape que personne n'attend.
  static final List<CoachStep> _tutoConfirmation = [
    CoachStep(
      key: CoachTargets.confirmation,
      title: 'Vérifiez avant de répondre',
      body:
          "Regardez votre plant et comparez avec les symptômes décrits. Si "
          'cela ne correspond pas, répondez Non : nous proposerons autre '
          'chose. Répondre Oui sans vérifier fait passer une erreur.',
    ),
  ];

  int _onglet = 0;

  /// Séquence en cours, ou `null` si aucune.
  ///
  static const OnboardingStorage _stockage = OnboardingStorage();

  /// Séquence en cours, ou `null` si aucune.
  List<CoachStep>? _tuto;

  /// Drapeau à noter quand la séquence en cours se termine. `null` pour une
  /// relance demandée : la revoir ne change rien à ce qui est mémorisé.
  String? _drapeau;

  /// Vraies tant qu'on ne sait pas : on préfère ne rien montrer pendant la
  /// lecture du stockage plutôt que d'afficher un voile qu'il faudrait
  /// retirer aussitôt.
  bool _confirmationVue = true;

  /// Dernière demande de relance traitée.
  int _demandesVues = 0;

  @override
  void initState() {
    super.initState();
    if (widget.coachMarks) _preparer();
  }

  Future<void> _preparer() async {
    final accueilVu = await _stockage.hasSeen(OnboardingStorage.coachAccueil);
    final confirmationVue = await _stockage.hasSeen(
      OnboardingStorage.coachConfirmation,
    );
    if (!mounted) return;

    setState(() {
      _confirmationVue = confirmationVue;
      if (!accueilVu) {
        _tuto = _tutoAccueil;
        _drapeau = OnboardingStorage.coachAccueil;
      }
    });
  }

  void _tutoTermine() {
    final drapeau = _drapeau;
    if (drapeau != null) _stockage.markSeen(drapeau);
    setState(() {
      if (drapeau == OnboardingStorage.coachConfirmation) {
        _confirmationVue = true;
      }
      _tuto = null;
      _drapeau = null;
    });
  }

  /// Rejoue la présentation des trois repères, à la demande.
  void _relancer() {
    setState(() {
      _onglet = 0;
      _tuto = _tutoAccueil;
      _drapeau = null;
    });
  }

  /// Déclenche la bulle de confirmation au premier résultat obtenu.
  void _surResultat() {
    if (!widget.coachMarks || _confirmationVue || _tuto != null) return;
    // Après la trame en cours : la carte n'est pas encore posée à l'écran,
    // et le voile n'aurait rien à désigner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _confirmationVue || _tuto != null) return;
      setState(() {
        _tuto = _tutoConfirmation;
        _drapeau = OnboardingStorage.coachConfirmation;
      });
    });
  }

  void _aller(int index) => setState(() => _onglet = index);

  @override
  Widget build(BuildContext context) {
    final diagnostic = context.watch<DiagnosisProvider>().state;
    if (_onglet == 0 && diagnostic is DiagnosisSuccess) _surResultat();

    final demandes = context.watch<CoachController>().demandes;
    if (demandes != _demandesVues) {
      _demandesVues = demandes;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _relancer();
      });
    }

    final tuto = _tuto;

    return PopScope(
      // Depuis un autre onglet, le bouton retour ramène au diagnostic au lieu
      // de quitter l'application. Sur l'onglet Diagnostic, c'est le `PopScope`
      // de [HomeScreen] qui prend le relais pour remonter d'une étape.
      canPop: _onglet == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _aller(0);
      },
      child: Stack(
        children: [
          Scaffold(
            body: switch (_onglet) {
              0 => const HomeScreen(),
              1 => const CatalogScreen(),
              _ => const HistoryScreen(),
            },
            bottomNavigationBar: NavigationBar(
              key: CoachTargets.navBar,
              selectedIndex: _onglet,
              onDestinationSelected: _aller,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.eco_outlined),
                  selectedIcon: Icon(Icons.eco),
                  label: 'Diagnostic',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Catalogue',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Historique',
                ),
              ],
            ),
          ),
          // Le voile est au-dessus de la coquille, pas dedans : c'est ce qui
          // lui permet de désigner aussi bien le contenu que la barre
          // d'onglets.
          if (tuto != null)
            // `Positioned.fill` est indispensable : sans lui le voile reçoit
            // des contraintes lâches, et une pile dont tous les enfants sont
            // positionnés se réduit alors à une taille nulle.
            Positioned.fill(
              child: CoachOverlay(steps: tuto, onDone: _tutoTermine),
            ),
        ],
      ),
    );
  }
}
