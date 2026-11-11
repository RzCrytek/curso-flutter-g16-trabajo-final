import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/pages/exchange/location_map_page.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/widgets/exchange/status_chip_widget.dart';

class ExchangeInfoWidget extends StatelessWidget {
  final ExchangeModel exchange;

  const ExchangeInfoWidget({super.key, required this.exchange});

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exchange.image != null)
            Image.network(
              exchange.image!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => SizedBox.shrink(),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exchange.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    StatusChipWidget(
                      status: exchange.status,
                      label: exchange.statusLabel,
                    ),
                    if (exchange.isAdmin)
                      StatusChipWidget(
                        status: "in_progress",
                        label: "Administrador",
                      ),
                  ],
                ),
                if (exchange.creatorName != null) ...[
                  SizedBox(height: 8),
                  Text(
                    "Creado por ${exchange.creatorName}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (exchange.description != null) ...[
                  SizedBox(height: 12),
                  Text(exchange.description!),
                ],
                SizedBox(height: 4),
                if (exchange.adminNames.isNotEmpty)
                  _row(
                    context,
                    exchange.adminNames.length == 1
                        ? "Administrador"
                        : "Administradores",
                    exchange.adminNames.join(", "),
                  ),
                _row(context, "Código", exchange.code),
                _row(
                  context,
                  "Presupuesto",
                  exchange.budget == null
                      ? "No definido"
                      : formatBudget(exchange.budget!),
                ),
                _row(
                  context,
                  "Fecha",
                  exchange.eventDate == null
                      ? "No definida"
                      : formatEventDate(exchange.eventDate!),
                ),
                _row(
                  context,
                  "Lugar",
                  exchange.location ??
                      (exchange.latitude == null
                          ? "No definido"
                          : "Marcado en el mapa"),
                ),
                if (exchange.latitude != null && exchange.longitude != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 108),
                      child: TextButton.icon(
                        icon: Icon(Icons.map_outlined, size: 18),
                        label: Text("Ver en el mapa"),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationMapPage(
                              initial: LatLng(
                                exchange.latitude!,
                                exchange.longitude!,
                              ),
                              readOnly: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
