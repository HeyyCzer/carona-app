import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Estrutura comum das telas de login/cadastro: conteúdo centralizado e rodapé com link.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String footerText;
  final String footerAction;
  final VoidCallback onFooterTap;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.footerText,
    required this.footerAction,
    required this.onFooterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    Text(title, style: headlineStyle),
                    const SizedBox(height: 18),
                    Text(subtitle, style: const TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.4)),
                    const SizedBox(height: 32),
                    ...children,
                    const Spacer(flex: 3),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 24),
                        child: Text.rich(
                          TextSpan(
                            text: '$footerText  ',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                            children: [
                              TextSpan(
                                text: footerAction,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()..onTap = onFooterTap,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
