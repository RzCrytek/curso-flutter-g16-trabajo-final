import 'package:flutter/material.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/auth_service.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _sent = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _authService.forgotPassword(_emailController.text.trim());
      setState(() => _sent = true);
    } on ApiException catch (e) {
      setState(
        () => _message = e.describe(
          "No se pudo enviar el correo. Inténtalo de nuevo.",
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recuperar contraseña")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Escribe tu correo y te enviaremos un enlace para elegir una nueva contraseña.",
                ),
                SizedBox(height: 16),
                if (_sent)
                  BannerWidget(
                    text:
                        "Si el correo está registrado, te enviamos un enlace. Ábrelo para cambiar tu contraseña.",
                  ),
                if (_message != null)
                  BannerWidget(text: _message!, isError: true),
                FieldWidget(
                  controller: _emailController,
                  label: "Correo electrónico",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value ?? "").trim().isEmpty
                      ? "Escribe tu correo."
                      : null,
                ),
                ButtonWidget(
                  text: "Enviar enlace",
                  function: _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
