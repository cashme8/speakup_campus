import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Shared layout for the auth screens: campus photo header with a purple
/// fade, then a white rounded panel that slides over it with the form.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final double headerHeight;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.headerHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            SizedBox(
              height: headerHeight + topInset,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/campus_building.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    excludeFromSemantics: true,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x334A2BD9),
                          Color(0xCC5530E6),
                          Color(0xF24A2BD9),
                        ],
                        stops: [0, 0.6, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, topInset + 12, 24, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showBack)
                          IconButton.filledTonal(
                            onPressed: () => Navigator.maybePop(context),
                            tooltip: 'Back',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_back),
                          )
                        else
                          const _Brand(),
                        const Spacer(),
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                height: 1.15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(
                    24, 28, 24, 24 + MediaQuery.paddingOf(context).bottom),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.campaign_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 10),
        const Text('SpeakUp Campus',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
