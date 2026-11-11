import 'package:flutter/material.dart';
import 'package:primo_secreto_app/providers/auth_provider.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await context.read<AuthProvider>().resendVerificationEmail();
      if (mounted) {
        showMessage(context, "Te enviamos un nuevo correo de verificación.");
      }
    } on ApiException catch (e) {
      if (mounted) {
        showMessage(
          context,
          e.describe("No se pudo reenviar el correo."),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _check() async {
    setState(() => _isChecking = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.refreshUser();
      if (mounted && !auth.isVerified) {
        showMessage(
          context,
          "Tu correo todavía no está verificado.",
          isError: true,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        showMessage(
          context,
          e.describe("No se pudo comprobar tu cuenta."),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text("Verifica tu correo")),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_unread_outlined, size: 64),
              SizedBox(height: 16),
              Text(
                "Enviamos un enlace a ${auth.user?.email ?? 'tu correo'}. Ábrelo y vuelve aquí para continuar.",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ButtonWidget(
                text: "Ya verifiqué mi correo",
                function: _check,
                isLoading: _isChecking,
              ),
              SizedBox(height: 12),
              ButtonWidget(
                text: "Reenviar correo",
                isOutlined: true,
                function: _resend,
                isLoading: _isResending,
              ),
              TextButton(
                onPressed: () => auth.logout(),
                child: Text("Cerrar sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
