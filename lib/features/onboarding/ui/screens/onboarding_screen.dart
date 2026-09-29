import 'package:flutter/material.dart';

/// Une page de la présentation : une image, un titre, une phrase.
class _Page {
  const _Page({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// Présentation affichée au tout premier lancement.
///
/// Trois pages, pas quatre. Une seule idée par page, et une phrase par idée :
/// ce qui n'est pas lu ne sert à rien, et ce qui est trop long n'est pas lu.
/// « Passer » reste visible en permanence — personne ne doit être retenu
/// devant un écran d'explication.
///
/// Elle dit ce que l'application fait, pas comment s'en servir. Le reste
/// s'apprend en faisant : l'utilisateur arrive directement sur le diagnostic,
/// et la fiche « bonne photo » est accessible au moment où elle est utile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onDone, super.key});

  /// Appelé quand l'utilisateur termine ou passe la présentation.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_Page> _pages = [
    _Page(
      icon: Icons.photo_camera_outlined,
      title: 'Photographiez une feuille',
      body:
          "Prenez en photo une feuille malade. L'application reconnaît ce qui "
          'affecte votre plante.',
    ),
    _Page(
      icon: Icons.cloud_off_outlined,
      title: 'Sans connexion',
      body:
          "L'analyse se fait sur votre téléphone. Pas besoin d'internet, ni "
          'de forfait.',
    ),
    _Page(
      icon: Icons.healing_outlined,
      title: 'Que faire ensuite',
      body:
          'Vous voyez les symptômes à vérifier, puis les soins à appliquer et '
          'comment éviter que cela revienne.',
    ),
  ];

  final PageController _controleur = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _suivant() {
    if (_index == _pages.length - 1) {
      widget.onDone();
      return;
    }
    _controleur.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final derniere = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Passer'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controleur,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _PageView(page: _pages[i]),
              ),
            ),
            _Dots(total: _pages.length, current: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _suivant,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(derniere ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 72,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? colors.primary : colors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
