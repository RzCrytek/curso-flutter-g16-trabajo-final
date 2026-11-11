import 'package:flutter/material.dart';
import 'package:primo_secreto_app/pages/exchange/exchange_detail_page.dart';
import 'package:primo_secreto_app/services/exchange_service.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/exchange/exchange_form_widget.dart';

class ExchangeCreatePage extends StatelessWidget {
  const ExchangeCreatePage({super.key});

  Future<void> _create(BuildContext context, ExchangeFormData data) async {
    final exchange = await ExchangeService().create(
      title: data.title,
      description: data.description,
      members: data.members,
      includeMe: data.includeMe,
      budgetAmount: data.budgetAmount,
      budgetCurrency: data.budgetCurrency,
      eventDate: data.eventDate,
      location: data.location,
      latitude: data.latitude,
      longitude: data.longitude,
      imagePath: data.imagePath,
    );
    if (!context.mounted) return;

    showMessage(context, "Creamos el sorteo.");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExchangeDetailPage(uuid: exchange.uuid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear sorteo")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: ExchangeFormWidget(
            submitLabel: "Crear sorteo",
            onSubmit: (data) => _create(context, data),
          ),
        ),
      ),
    );
  }
}
