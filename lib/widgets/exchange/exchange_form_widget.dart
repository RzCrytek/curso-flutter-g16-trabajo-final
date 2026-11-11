import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/pages/exchange/location_map_page.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/utils/email_utils.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:primo_secreto_app/widgets/common/image_picker_widget.dart';

class ExchangeFormData {
  String title;
  String description;
  String budgetAmount;
  String budgetCurrency;
  String eventDate;
  String location;
  double? latitude;
  double? longitude;
  String? imagePath;
  bool removeImage;
  List<String> members;
  bool includeMe;

  ExchangeFormData({
    required this.title,
    required this.description,
    required this.budgetAmount,
    required this.budgetCurrency,
    required this.eventDate,
    required this.location,
    this.latitude,
    this.longitude,
    this.imagePath,
    this.removeImage = false,
    this.members = const [],
    this.includeMe = true,
  });
}

class ExchangeFormWidget extends StatefulWidget {
  final ExchangeModel? exchange;
  final String submitLabel;

  final Future<void> Function(ExchangeFormData data) onSubmit;

  const ExchangeFormWidget({
    super.key,
    this.exchange,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<ExchangeFormWidget> createState() => _ExchangeFormWidgetState();
}

class _ExchangeFormWidgetState extends State<ExchangeFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _mapController = TextEditingController();
  final _membersController = TextEditingController();

  String _currency = defaultCurrency;
  String _eventDate = "";
  LatLng? _point;
  String? _imagePath;
  bool _removeImage = false;
  bool _includeMe = true;
  bool _isLoading = false;
  String? _message;
  Map<String, List<String>> _errors = {};

  bool get _isCreating => widget.exchange == null;

  String get _pointLabel => "Ubicación seleccionada";

  @override
  void initState() {
    super.initState();
    final exchange = widget.exchange;
    if (exchange != null) {
      _titleController.text = exchange.title;
      _descriptionController.text = exchange.description ?? "";
      _amountController.text = exchange.budget?.amount ?? "";
      _currency = exchange.budget?.currency ?? defaultCurrency;
      _eventDate = exchange.eventDate ?? "";
      _locationController.text = exchange.location ?? "";
      if (exchange.latitude != null && exchange.longitude != null) {
        _point = LatLng(exchange.latitude!, exchange.longitude!);
        _mapController.text = _pointLabel;
      }
    }
    _currencyController.text = _currency;
    _dateController.text = _eventDate.isEmpty
        ? ""
        : formatEventDate(_eventDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _mapController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final currency = await pickOption(
      context,
      title: "Moneda",
      options: {for (final item in currencies) item: item},
      selected: _currency,
    );
    if (currency != null) {
      _currency = currency;
      _currencyController.text = currency;
    }
  }

  Future<void> _pickDate() async {
    final date = await pickDate(context, initial: _eventDate);
    if (date != null) {
      setState(() {
        _eventDate = date;
        _dateController.text = formatEventDate(date);
      });
    }
  }

  Future<void> _pickPoint() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => LocationMapPage(initial: _point)),
    );
    if (point != null) {
      setState(() {
        _point = point;
        _mapController.text = _pointLabel;
      });
    }
  }

  Future<void> _pickImage(String? path) async {
    if (path != null) {
      final problem = await imageProblem(path);
      if (problem != null) {
        setState(
          () => _errors = {
            ..._errors,
            "image": [problem],
          },
        );
        return;
      }
    }
    setState(() {
      _imagePath = path;
      _removeImage = path == null;
      _errors = {..._errors}..remove("image");
    });
  }

  String? _validateAmount(String? value) {
    final amount = (value ?? "").trim();
    if (amount.isEmpty) return null;
    final isValid =
        RegExp(r"^\d{1,8}(\.\d{1,2})?$").hasMatch(amount) &&
        double.parse(amount) > 0;
    return isValid
        ? null
        : "Escribe un monto mayor que 0, con hasta 2 decimales.";
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = parseEmails(_membersController.text);
    if (parsed.invalid.isNotEmpty) {
      setState(
        () => _message = "Correos no válidos: ${parsed.invalid.join(', ')}.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _errors = {};
    });

    final amount = _amountController.text.trim();
    try {
      await widget.onSubmit(
        ExchangeFormData(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          budgetAmount: amount,
          budgetCurrency: amount.isEmpty ? "" : _currency,
          eventDate: _eventDate,
          location: _locationController.text.trim(),
          latitude: _point?.latitude,
          longitude: _point?.longitude,
          imagePath: _imagePath,
          removeImage: _removeImage,
          members: parsed.valid,
          includeMe: _includeMe,
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _errors = e.errors;
        _message = e.errors.isEmpty
            ? e.describe("No se pudo guardar el sorteo.")
            : null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_message != null) BannerWidget(text: _message!, isError: true),
          FieldWidget(
            controller: _titleController,
            label: "Nombre del sorteo",
            maxLength: 255,
            textCapitalization: TextCapitalization.sentences,
            errorText: _errors["title"]?.first,
            validator: (value) => (value ?? "").trim().isEmpty
                ? "Escribe el nombre del sorteo."
                : null,
          ),
          FieldWidget(
            controller: _descriptionController,
            label: "Descripción (opcional)",
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            errorText: _errors["description"]?.first,
          ),
          ImagePickerWidget(
            label: "Imagen (opcional)",
            currentUrl: _removeImage ? null : widget.exchange?.image,
            newPath: _imagePath,
            onChanged: _pickImage,
            errorText: _errors["image"]?.first,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: FieldWidget(
                  controller: _amountController,
                  label: "Presupuesto",
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  errorText: _errors["budget_amount"]?.first,
                  validator: _validateAmount,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FieldWidget(
                  controller: _currencyController,
                  label: "Moneda",
                  function: _pickCurrency,
                  errorText: _errors["budget_currency"]?.first,
                ),
              ),
            ],
          ),
          FieldWidget(
            controller: _dateController,
            label: "Fecha del evento (opcional)",
            function: _pickDate,
            suffixIcon: _eventDate.isEmpty
                ? Icon(Icons.calendar_today)
                : IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _eventDate = "";
                      _dateController.clear();
                    }),
                  ),
            errorText: _errors["event_date"]?.first,
          ),
          FieldWidget(
            controller: _locationController,
            label: "Lugar (opcional)",
            textCapitalization: TextCapitalization.sentences,
            errorText: _errors["location"]?.first,
          ),
          FieldWidget(
            controller: _mapController,
            label: "Ubicación en el mapa (opcional)",
            function: _pickPoint,
            suffixIcon: _point == null
                ? Icon(Icons.map_outlined)
                : IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _point = null;
                      _mapController.clear();
                    }),
                  ),
            errorText:
                _errors["latitude"]?.first ?? _errors["longitude"]?.first,
          ),
          if (_isCreating) ...[
            FieldWidget(
              controller: _membersController,
              label: "Correos de los invitados",
              hintText: "ana@correo.com, luis@correo.com",
              keyboardType: TextInputType.emailAddress,
              maxLines: 3,
              errorText:
                  _errors["members"]?.first ?? _errors["members.0"]?.first,
            ),
            Text(
              "Separa los correos con comas, espacios o saltos de línea. Se necesitan al menos $minParticipants participantes.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Yo también participo en el sorteo"),
              value: _includeMe,
              onChanged: (value) => setState(() => _includeMe = value),
            ),
          ],
          SizedBox(height: 8),
          ButtonWidget(
            text: widget.submitLabel,
            function: _submit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
