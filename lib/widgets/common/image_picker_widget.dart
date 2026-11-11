import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/broken_image_widget.dart';

final ImagePicker _picker = ImagePicker();

const int maxImageBytes = 2 * 1024 * 1024;

Future<ImageSource?> _pickSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined),
            title: Text("Tomar foto"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined),
            title: Text("Elegir de la galería"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

Future<String?> _pickFrom(BuildContext context, ImageSource source) async {
  try {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1280,
    );
    return image?.path;
  } on PlatformException {
    if (context.mounted) {
      showMessage(
        context,
        source == ImageSource.camera
            ? "No se pudo abrir la cámara. Revisa el permiso en los ajustes."
            : "No se pudo abrir la galería. Revisa el permiso en los ajustes.",
        isError: true,
      );
    }
    return null;
  }
}

Future<String?> pickSingleImage(BuildContext context) async {
  final source = await _pickSource(context);
  if (source == null || !context.mounted) return null;
  return _pickFrom(context, source);
}

Future<List<String>> pickManyImages(BuildContext context) async {
  final source = await _pickSource(context);
  if (source == null || !context.mounted) return [];

  if (source == ImageSource.camera) {
    final path = await _pickFrom(context, source);
    return [?path];
  }

  try {
    final images = await _picker.pickMultiImage(
      imageQuality: 75,
      maxWidth: 1280,
    );
    return images.map((image) => image.path).toList();
  } on PlatformException {
    if (context.mounted) {
      showMessage(
        context,
        "No se pudo abrir la galería. Revisa el permiso en los ajustes.",
        isError: true,
      );
    }
    return [];
  }
}

Future<String?> imageProblem(String path) async {
  if (await File(path).length() > maxImageBytes) {
    return "Cada imagen puede pesar hasta 2 MB.";
  }
  return null;
}

class ImagePickerWidget extends StatelessWidget {
  final String label;
  final String? currentUrl;
  final String? newPath;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const ImagePickerWidget({
    super.key,
    required this.label,
    this.currentUrl,
    this.newPath,
    required this.onChanged,
    this.errorText,
  });

  Future<void> _choose(BuildContext context) async {
    final path = await pickSingleImage(context);
    if (path != null) onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = newPath != null
        ? FileImage(File(newPath!))
        : (currentUrl != null ? NetworkImage(currentUrl!) : null);

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: image == null
                      ? Icon(Icons.image_outlined)
                      : Image(
                          image: image,
                          fit: BoxFit.cover,
                          errorBuilder: brokenImage,
                        ),
                ),
              ),
              SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _choose(context),
                child: Text(image == null ? "Elegir" : "Cambiar"),
              ),
              if (image != null) ...[
                SizedBox(width: 8),
                TextButton(
                  onPressed: () => onChanged(null),
                  child: Text("Quitar"),
                ),
              ],
            ],
          ),
          if (errorText != null)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
