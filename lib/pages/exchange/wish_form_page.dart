import 'dart:io';

import 'package:flutter/material.dart';
import 'package:primo_secreto_app/widgets/common/broken_image_widget.dart';
import 'package:primo_secreto_app/models/wishlist_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/wishlist_service.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:primo_secreto_app/widgets/common/image_picker_widget.dart';

class WishFormPage extends StatefulWidget {
  final String exchangeUuid;
  final WishItemModel? item;

  const WishFormPage({super.key, required this.exchangeUuid, this.item});

  @override
  State<WishFormPage> createState() => _WishFormPageState();
}

class _WishFormPageState extends State<WishFormPage> {
  final WishlistService _wishlistService = WishlistService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();

  late final List<String> _links;
  late final List<WishImageModel> _keptImages;
  final List<String> _removedImages = [];
  final List<String> _newImages = [];

  bool _isLoading = false;
  String? _linkError;
  String? _imageError;
  String? _message;
  Map<String, List<String>> _errors = {};

  int get _imageCount => _keptImages.length + _newImages.length;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController.text = item?.title ?? "";
    _descriptionController.text = item?.description ?? "";
    _links = item?.links.map((link) => link.url).toList() ?? [];
    _keptImages = [...?item?.images];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _addLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;

    final uri = Uri.tryParse(link);
    String? error;
    if (uri == null ||
        !(uri.scheme == "http" || uri.scheme == "https") ||
        uri.host.isEmpty) {
      error = "Escribe un enlace que empiece con http:// o https://.";
    } else if (_links.length >= maxWishLinks) {
      error = "Puedes agregar hasta $maxWishLinks enlaces.";
    } else if (_links.contains(link)) {
      error = "Ese enlace ya está en la lista.";
    }

    setState(() {
      _linkError = error;
      if (error == null) {
        _links.add(link);
        _linkController.clear();
      }
    });
  }

  Future<void> _addImages() async {
    final paths = await pickManyImages(context);
    String? error;

    for (final path in paths) {
      if (_imageCount >= maxWishImages) {
        error = "Puedes agregar hasta $maxWishImages imágenes por deseo.";
        break;
      }
      final problem = await imageProblem(path);
      if (problem != null) {
        error = problem;
        continue;
      }
      _newImages.add(path);
    }
    if (mounted) setState(() => _imageError = error);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _message = null;
      _errors = {};
    });

    try {
      final item = widget.item;
      final saved = item == null
          ? await _wishlistService.addItem(
              widget.exchangeUuid,
              title: _titleController.text,
              description: _descriptionController.text,
              links: _links,
              newImagePaths: _newImages,
            )
          : await _wishlistService.updateItem(
              widget.exchangeUuid,
              item.uuid,
              title: _titleController.text,
              description: _descriptionController.text,
              links: _links,
              newImagePaths: _newImages,
              removeImages: _removedImages,
            );
      if (!mounted) return;
      showMessage(
        context,
        item == null ? "Agregamos el deseo." : "Guardamos los cambios.",
      );
      Navigator.pop(context, saved);
    } on ApiException catch (e) {
      setState(() {
        _errors = e.errors;
        _message = e.errors.isEmpty
            ? e.describe("No se pudo guardar el deseo.")
            : null;
        _isLoading = false;
      });
    }
  }

  Widget _thumbnail({
    required ImageProvider image,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: image,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: brokenImageOf(80),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? "Nuevo deseo" : "Editar deseo"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_message != null)
                  BannerWidget(text: _message!, isError: true),
                FieldWidget(
                  controller: _titleController,
                  label: "¿Qué te gustaría recibir?",
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  errorText: _errors["title"]?.first,
                  validator: (value) => (value ?? "").trim().isEmpty
                      ? "Escribe qué te gustaría recibir."
                      : null,
                ),
                FieldWidget(
                  controller: _descriptionController,
                  label: "Detalles (opcional)",
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  errorText: _errors["description"]?.first,
                ),
                Text("Enlaces", style: Theme.of(context).textTheme.labelLarge),
                SizedBox(height: 8),
                for (final link in _links)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.link),
                    title: Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => setState(() => _links.remove(link)),
                    ),
                  ),
                FieldWidget(
                  controller: _linkController,
                  label: "Agregar un enlace",
                  hintText: "https://…",
                  keyboardType: TextInputType.url,
                  errorText: _linkError ?? _errors["links"]?.first,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addLink,
                  ),
                ),
                Text(
                  "Imágenes ($_imageCount/$maxWishImages)",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final image in _keptImages)
                      _thumbnail(
                        image: NetworkImage(image.url),
                        onRemove: () => setState(() {
                          _keptImages.remove(image);
                          _removedImages.add(image.uuid);
                        }),
                      ),
                    for (final path in _newImages)
                      _thumbnail(
                        image: FileImage(File(path)),
                        onRemove: () => setState(() => _newImages.remove(path)),
                      ),
                  ],
                ),
                if (_imageCount < maxWishImages)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addImages,
                      icon: Icon(Icons.add_photo_alternate_outlined),
                      label: Text("Agregar imágenes"),
                    ),
                  ),
                if (_imageError != null ||
                    _errors["images"] != null ||
                    _errors["images.0"] != null)
                  Text(
                    _imageError ??
                        _errors["images"]?.first ??
                        _errors["images.0"]!.first,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Text(
                  "JPG, PNG o WebP, máximo 2 MB cada una y $maxWishImages por deseo.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 16),
                ButtonWidget(
                  text: "Guardar",
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
