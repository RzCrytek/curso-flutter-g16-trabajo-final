import 'package:flutter/material.dart';
import 'package:primo_secreto_app/pages/auth/forgot_password_page.dart';
import 'package:primo_secreto_app/pages/auth/register_page.dart';
import 'package:primo_secreto_app/providers/auth_provider.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  Map<String, List<String>> _errors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _message = null;
      _errors = {};
    });

    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      setState(() {
        _errors = e.errors;
        _message = e.errors.isEmpty
            ? e.describe("No se pudo iniciar sesión.")
            : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Iniciar sesión")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_message != null)
                  BannerWidget(text: _message!, isError: true),
                FieldWidget(
                  controller: _emailController,
                  label: "Correo electrónico",
                  keyboardType: TextInputType.emailAddress,
                  errorText: _errors["email"]?.first,
                  validator: (value) => (value ?? "").trim().isEmpty
                      ? "Escribe tu correo."
                      : null,
                ),
                FieldWidget(
                  controller: _passwordController,
                  label: "Contraseña",
                  obscureText: true,
                  errorText: _errors["password"]?.first,
                  validator: (value) =>
                      (value ?? "").isEmpty ? "Escribe tu contraseña." : null,
                ),
                SizedBox(height: 8),
                ButtonWidget(
                  text: "Entrar",
                  function: _submit,
                  isLoading: _isLoading,
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordPage(),
                    ),
                  ),
                  child: Text("¿Olvidaste tu contraseña?"),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterPage(),
                    ),
                  ),
                  child: Text("¿No tienes cuenta? Créala"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
