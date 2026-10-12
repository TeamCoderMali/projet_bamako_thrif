import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/constants/feature_flags.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/payment_config_service.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Repli = desactive, meme choix que partout ailleurs (voir
  // PaymentConfigService). Lot 9.
  bool _paymentEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
  }

  Future<void> _loadPaymentConfig() async {
    final enabled = await PaymentConfigService.instance.isPaymentEnabled();
    if (mounted) setState(() => _paymentEnabled = enabled);
  }

  // Slide 2 : decrit le pressing (gouverne par pressingEnabled, pas par le
  // paiement). Slide 3 : decrit le paiement (gouverne par _paymentEnabled).
  // Lot 9 : textes "equipe"/"escrow"/paiement integre retires tant que ces
  // fonctionnalites ne sont pas actives.
  // Lot 1 (2026-10-12) : nouvelles accroches validées par Fatou, sans
  // description en dessous — description laissée nullable (pas de '!')
  // pour ne pas planter si une variante future n'en fournit pas.
  List<_OnboardingSlide> get _slides => [
        const _OnboardingSlide(title: 'Chinez, vendez, en toute simplicité'),
        if (pressingEnabled)
          const _OnboardingSlide(
            title: 'Vêtements vérifiés & lavés',
            description:
                'Chaque article est inspecté et lavé par notre équipe avant la remise.',
          )
        else
          const _OnboardingSlide(
            title: 'Articles neufs et seconde main, choisis avec soin',
          ),
        if (_paymentEnabled)
          const _OnboardingSlide(
            title: 'Paiement 100% sécurisé',
            description:
                'Orange Money, Moov Money et portefeuille virtuel disponibles.',
          )
        else
          const _OnboardingSlide(title: 'Un message, et c\'est à toi !'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Icône de marque + Bouton Passer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo_danaya_icon.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Passer',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image placeholder
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.checkroom,
                            size: 100,
                            color: Color(0xFF6B7F4D),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _slides[index].title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (_slides[index].description != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _slides[index].description!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicateurs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.orange
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bouton Suivant / Commencer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      context.go(RouteNames.login);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7F4D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'Suivant' : 'Commencer',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Description optionnelle : certaines accroches n'ont plus de texte en
// dessous (lot 1, 2026-10-12) — pas de '!' sur un champ qui pourrait
// être absent.
class _OnboardingSlide {
  final String title;
  final String? description;
  const _OnboardingSlide({required this.title, this.description});
}
