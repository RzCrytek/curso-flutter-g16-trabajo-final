import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/widgets/exchange/status_chip_widget.dart';

class ExchangeCardWidget extends StatelessWidget {
  final ExchangeModel exchange;
  final VoidCallback function;

  const ExchangeCardWidget({
    super.key,
    required this.exchange,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: function,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: colors.primaryContainer,
                  alignment: Alignment.center,
                  child: exchange.image != null
                      ? Image.network(
                          exchange.image!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Text(exchange.initial),
                        )
                      : Text(
                          exchange.initial,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exchange.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4),
                    StatusChipWidget(
                      status: exchange.status,
                      label: exchange.statusLabel,
                    ),
                    SizedBox(height: 6),
                    Text(
                      [
                        pluralize(
                          exchange.membersCount,
                          "participante",
                          "participantes",
                        ),
                        if (exchange.eventDate != null)
                          formatEventDate(exchange.eventDate!),
                        if (exchange.budget != null)
                          formatBudget(exchange.budget!),
                      ].join(" · "),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
