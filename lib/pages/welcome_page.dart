import 'package:flutter/material.dart';
import 'package:primo_secreto_app/pages/auth/login_page.dart';
import 'package:primo_secreto_app/pages/auth/register_page.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/logo.png",
                      width: 200,
                      height: 200,
                    ),
                    SizedBox(height: 16),
                    SizedBox(height: 12),
                    Text(
                      "Organiza tu amigo secreto en línea: invita a tus amigos, haz el sorteo y compartan sus listas de deseos.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              ButtonWidget(
                text: "Iniciar sesión",
                function: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                ),
              ),
              SizedBox(height: 12),
              ButtonWidget(
                text: "Crear cuenta",
                isOutlined: true,
                function: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
