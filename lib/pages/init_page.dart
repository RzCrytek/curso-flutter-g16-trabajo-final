import 'package:flutter/material.dart';
import 'package:primo_secreto_app/pages/auth/verify_email_page.dart';
import 'package:primo_secreto_app/pages/home_page.dart';
import 'package:primo_secreto_app/pages/welcome_page.dart';
import 'package:primo_secreto_app/providers/auth_provider.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:provider/provider.dart';

class InitPage extends StatelessWidget {
  const InitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.loading:
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.offline:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 56),
                  SizedBox(height: 16),
                  Text(
                    "No pudimos conectarnos con el servidor.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ButtonWidget(text: "Reintentar", function: () => auth.init()),
                ],
              ),
            ),
          ),
        );
      case AuthStatus.unauthenticated:
        return WelcomePage();
      case AuthStatus.authenticated:
        return auth.isVerified ? HomePage() : VerifyEmailPage();
    }
  }
}
