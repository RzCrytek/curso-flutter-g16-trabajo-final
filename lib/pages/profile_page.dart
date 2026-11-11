import 'package:flutter/material.dart';
import 'package:primo_secreto_app/providers/auth_provider.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/avatar_widget.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:primo_secreto_app/widgets/common/image_picker_widget.dart';
import 'package:primo_secreto_app/widgets/common/section_card_widget.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _detailsKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _savingDetails = false;
  bool _savingPhoto = false;
  bool _savingPassword = false;
  Map<String, List<String>> _detailsErrors = {};
  Map<String, List<String>> _passwordErrors = {};
  String? _passwordMessage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? "";
    _lastNameController.text = user?.lastName ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_detailsKey.currentState!.validate()) return;
    setState(() {
      _savingDetails = true;
      _detailsErrors = {};
    });
    try {
      final lastName = _lastNameController.text.trim();
      await context.read<AuthProvider>().updateProfile(
        _nameController.text.trim(),
        lastName.isEmpty ? null : lastName,
      );
      if (mounted) showMessage(context, "Guardamos tus datos.");
    } on ApiException catch (e) {
      setState(() => _detailsErrors = e.errors);
      if (mounted && e.errors.isEmpty) {
        showMessage(context, e.describe("No se pudo guardar."), isError: true);
      }
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<void> _changePhoto() async {
    final auth = context.read<AuthProvider>();
    final path = await pickSingleImage(context);
    if (path == null || !mounted) return;

    final problem = await imageProblem(path);
    if (problem != null) {
      if (mounted) showMessage(context, problem, isError: true);
      return;
    }

    setState(() => _savingPhoto = true);
    try {
      await auth.uploadPhoto(path);
      if (mounted) showMessage(context, "Actualizamos tu foto.");
    } on ApiException catch (e) {
      if (mounted) {
        showMessage(
          context,
          e.describe("No se pudo subir la foto."),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _savingPhoto = true);
    try {
      await context.read<AuthProvider>().removePhoto();
    } on ApiException catch (e) {
      if (mounted) {
        showMessage(
          context,
          e.describe("No se pudo quitar la foto."),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() {
      _savingPassword = true;
      _passwordErrors = {};
      _passwordMessage = null;
    });
    try {
      await auth.changePassword(
        auth.user!.hasPassword ? _currentPasswordController.text : null,
        _newPasswordController.text,
        _confirmationController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmationController.clear();
      if (mounted) showMessage(context, "Cambiamos tu contraseña.");
    } on ApiException catch (e) {
      setState(() {
        _passwordErrors = e.errors;
        _passwordMessage = e.errors.isEmpty
            ? e.describe("No se pudo cambiar la contraseña.")
            : null;
      });
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _unlinkGoogle() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Desvincular Google"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Escribe tu contraseña para desvincular tu cuenta de Google.",
            ),
            SizedBox(height: 12),
            FieldWidget(
              controller: controller,
              label: "Contraseña actual",
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("Desvincular"),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty || !mounted) return;

    try {
      await context.read<AuthProvider>().unlinkGoogle(password);
      if (mounted) showMessage(context, "Desvinculamos tu cuenta de Google.");
    } on ApiException catch (e) {
      if (mounted) {
        showMessage(
          context,
          e.describe("No se pudo desvincular la cuenta."),
          isError: true,
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmDialog(
      context,
      title: "Cerrar sesión",
      message: "¿Quieres cerrar tu sesión en este dispositivo?",
      confirmLabel: "Cerrar sesión",
    );
    if (confirmed && mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return Scaffold();

    return Scaffold(
      appBar: AppBar(title: Text("Mi perfil")),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            SectionCardWidget(
              children: [
                Center(
                  child: Column(
                    children: [
                      AvatarWidget(
                        src: user.avatar,
                        name: user.name,
                        lastName: user.lastName,
                        size: 96,
                      ),
                      SizedBox(height: 8),
                      Text(user.email),
                      SizedBox(height: 8),
                      if (_savingPhoto)
                        CircularProgressIndicator()
                      else
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _changePhoto,
                              child: Text("Cambiar foto"),
                            ),
                            if (user.hasCustomAvatar)
                              TextButton(
                                onPressed: _removePhoto,
                                child: Text("Quitar foto"),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SectionCardWidget(
              title: "Mis datos",
              children: [
                Form(
                  key: _detailsKey,
                  child: Column(
                    children: [
                      FieldWidget(
                        controller: _nameController,
                        label: "Nombre",
                        textCapitalization: TextCapitalization.words,
                        errorText: _detailsErrors["name"]?.first,
                        validator: (value) => (value ?? "").trim().isEmpty
                            ? "Escribe tu nombre."
                            : null,
                      ),
                      FieldWidget(
                        controller: _lastNameController,
                        label: "Apellido (opcional)",
                        textCapitalization: TextCapitalization.words,
                        errorText: _detailsErrors["last_name"]?.first,
                      ),
                      ButtonWidget(
                        text: "Guardar datos",
                        function: _saveDetails,
                        isLoading: _savingDetails,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SectionCardWidget(
              title: user.hasPassword
                  ? "Cambiar contraseña"
                  : "Crear una contraseña",
              children: [
                if (_passwordMessage != null)
                  BannerWidget(text: _passwordMessage!, isError: true),
                Form(
                  key: _passwordKey,
                  child: Column(
                    children: [
                      if (user.hasPassword)
                        FieldWidget(
                          controller: _currentPasswordController,
                          label: "Contraseña actual",
                          obscureText: true,
                          errorText: _passwordErrors["current_password"]?.first,
                          validator: (value) => (value ?? "").isEmpty
                              ? "Escribe tu contraseña actual."
                              : null,
                        ),
                      FieldWidget(
                        controller: _newPasswordController,
                        label: "Nueva contraseña",
                        obscureText: true,
                        errorText: _passwordErrors["password"]?.first,
                        validator: (value) => (value ?? "").length < 8
                            ? "Debe tener al menos 8 caracteres."
                            : null,
                      ),
                      FieldWidget(
                        controller: _confirmationController,
                        label: "Confirma la nueva contraseña",
                        obscureText: true,
                        validator: (value) =>
                            value != _newPasswordController.text
                            ? "Las contraseñas no coinciden."
                            : null,
                      ),
                      ButtonWidget(
                        text: "Guardar contraseña",
                        function: _changePassword,
                        isLoading: _savingPassword,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.hasGoogle)
              SectionCardWidget(
                title: "Cuenta de Google",
                children: [
                  Text("Tu cuenta está vinculada con Google."),
                  SizedBox(height: 8),
                  if (user.hasPassword)
                    OutlinedButton(
                      onPressed: _unlinkGoogle,
                      child: Text("Desvincular"),
                    )
                  else
                    Text(
                      "Crea una contraseña antes de poder desvincularla.",
                    ),
                ],
              ),
            ButtonWidget(
              text: "Cerrar sesión",
              isOutlined: true,
              icon: Icons.logout,
              function: _logout,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
