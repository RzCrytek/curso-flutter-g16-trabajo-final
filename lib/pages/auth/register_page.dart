import 'package:flutter/material.dart';
import 'package:primo_secreto_app/pages/auth/login_page.dart';
import 'package:primo_secreto_app/providers/auth_provider.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  Map<String, List<String>> _errors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
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
      await context.read<AuthProvider>().register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _confirmationController.text,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      setState(() {
        _errors = e.errors;
        _message = e.errors.isEmpty
            ? e.describe("No se pudo crear la cuenta.")
            : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear cuenta")),
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
                  controller: _nameController,
                  label: "Nombre",
                  textCapitalization: TextCapitalization.words,
                  errorText: _errors["name"]?.first,
                  validator: (value) => (value ?? "").trim().isEmpty
                      ? "Escribe tu nombre."
                      : null,
                ),
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
                  validator: (value) => (value ?? "").length < 8
                      ? "La contraseña debe tener al menos 8 caracteres."
                      : null,
                ),
                FieldWidget(
                  controller: _confirmationController,
                  label: "Confirma tu contraseña",
                  obscureText: true,
                  validator: (value) => value != _passwordController.text
                      ? "Las contraseñas no coinciden."
                      : null,
                ),
                SizedBox(height: 8),
                ButtonWidget(
                  text: "Crear cuenta",
                  function: _submit,
                  isLoading: _isLoading,
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  ),
                  child: Text("¿Ya tienes cuenta? Inicia sesión"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
