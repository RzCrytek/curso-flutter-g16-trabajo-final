import 'package:flutter/material.dart';
import 'package:primo_secreto_app/widgets/common/broken_image_widget.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/models/nomination_model.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/widgets/common/avatar_widget.dart';

class NominationCardWidget extends StatelessWidget {
  final ExchangeModel exchange;
  final NominationModel nomination;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddNominee;
  final ValueChanged<NomineeModel> onVote;
  final ValueChanged<NomineeModel> onRemoveNominee;

  const NominationCardWidget({
    super.key,
    required this.exchange,
    required this.nomination,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onAddNominee,
    required this.onVote,
    required this.onRemoveNominee,
  });

  Widget _leading(NomineeModel nominee) {
    if (nominee.person != null) {
      return AvatarWidget(
        src: nominee.person!.avatar,
        name: nominee.person!.name ?? "",
        lastName: nominee.person!.lastName,
        size: 44,
      );
    }
    if (nominee.image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          nominee.image!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: brokenImageOf(44),
        ),
      );
    }
    return CircleAvatar(radius: 22, child: Icon(Icons.format_quote));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(nomination.title, style: textTheme.titleMedium),
                ),
                if (nomination.canEdit)
                  PopupMenuButton<String>(
                    enabled: !busy,
                    onSelected: (action) =>
                        action == "edit" ? onEdit() : onDelete(),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: "edit", child: Text("Editar")),
                      PopupMenuItem(value: "delete", child: Text("Eliminar")),
                    ],
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(typeLabels[nomination.type] ?? nomination.type),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    selectionLabels[nomination.selection] ??
                        nomination.selection,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (nomination.creatorName != null)
              Text(
                "Creada por ${nomination.creatorName}",
                style: textTheme.bodySmall,
              ),
            if (exchange.votingStarted)
              Text(
                "${pluralize(nomination.totalVotes, 'voto', 'votos')} en total",
                style: textTheme.bodySmall,
              ),
            SizedBox(height: 8),
            if (nomination.nominees.isEmpty)
              Text("Todavía no hay nominados."),
            for (final nominee in nomination.nominees)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _leading(nominee),
                title: Text(
                  nominee.person != null && nominee.person!.isMe
                      ? "${nominee.name} (tú)"
                      : nominee.name,
                ),
                subtitle: nominee.votesCount == null
                    ? null
                    : Text(pluralize(nominee.votesCount!, "voto", "votos")),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nomination.canVote)
                      nominee.voted
                          ? FilledButton.icon(
                              onPressed: busy ? null : () => onVote(nominee),
                              icon: Icon(Icons.check, size: 18),
                              label: Text("Votado"),
                            )
                          : OutlinedButton(
                              onPressed: busy ? null : () => onVote(nominee),
                              child: Text("Votar"),
                            )
                    else if (nominee.voted)
                      Icon(Icons.how_to_vote, color: colors.primary),
                    if (nominee.canRemove)
                      IconButton(
                        tooltip: "Quitar nominado",
                        onPressed: busy ? null : () => onRemoveNominee(nominee),
                        icon: Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            if (nomination.canContribute &&
                nomination.nominees.length >= maxNominees)
              Text(
                "Esta nominación ya tiene el máximo de $maxNominees nominados.",
                style: textTheme.bodySmall,
              )
            else if (nomination.canContribute)
              TextButton.icon(
                onPressed: busy ? null : onAddNominee,
                icon: Icon(Icons.person_add_alt),
                label: Text("Agregar nominado"),
              ),
          ],
        ),
      ),
    );
  }
}
