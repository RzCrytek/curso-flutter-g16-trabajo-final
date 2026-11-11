import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/services/exchange_service.dart';
import 'package:primo_secreto_app/utils/action_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/avatar_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/section_card_widget.dart';

class DrawWidget extends StatefulWidget {
  final ExchangeModel exchange;
  final ValueChanged<ExchangeModel> onChanged;
  final VoidCallback? onOpenGifteeWishlist;

  const DrawWidget({
    super.key,
    required this.exchange,
    required this.onChanged,
    this.onOpenGifteeWishlist,
  });

  @override
  State<DrawWidget> createState() => _DrawWidgetState();
}

class _DrawWidgetState extends State<DrawWidget> {
  final ExchangeService _exchangeService = ExchangeService();

  bool _revealed = false;
  bool _busy = false;

  ExchangeModel get _exchange => widget.exchange;

  MemberModel? get _me {
    final matches = _exchange.participants.where((member) => member.isMe);
    return matches.isEmpty ? null : matches.first;
  }

  int get _missing =>
      _exchange.participants.where((member) => !member.hasGiftee).length;

  Map<String, String> _optionsFor(MemberModel giver) => {
    for (final member in _exchange.participants)
      if (member.uuid != giver.uuid) member.uuid: member.label,
  };

  Future<void> _setGiftee(MemberModel giver, {bool clearable = false}) async {
    final options = _optionsFor(giver);
    final chosen = await pickOption(
      context,
      title: giver.isMe
          ? "¿A quién le regalas?"
          : "¿A quién regala ${giver.label}?",
      options: {if (clearable) "": "Sin elegir", ...options},
      selected: giver.isMe ? _exchange.myGiftee?.uuid : null,
    );
    if (chosen == null || !mounted) return;

    setState(() => _busy = true);
    final updated = await runAction(
      context,
      () => _exchangeService.setGiftee(
        _exchange.uuid,
        giver.uuid,
        chosen.isEmpty ? null : chosen,
      ),
      success: giver.isMe
          ? "Guardamos tu elección."
          : "Guardamos la pareja de ${giver.label}.",
    );
    if (mounted) setState(() => _busy = false);
    if (updated != null) widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_exchange.drawMethod == null) return SizedBox.shrink();

    final giftee = _exchange.myGiftee;
    final me = _me;

    return SectionCardWidget(
      title: "Sorteo",
      children: [
        Text(
          _exchange.drawMethod == "random"
              ? "La aplicación emparejó a todos los participantes."
              : "El sorteo se hizo fuera de la aplicación.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: 12),
        if (giftee != null) ...[
          Row(
            children: [
              if (_revealed)
                AvatarWidget(
                  src: giftee.avatar,
                  name: giftee.name ?? "",
                  lastName: giftee.lastName,
                  size: 48,
                )
              else
                CircleAvatar(radius: 24, child: Text("?")),
              SizedBox(width: 12),
              Expanded(
                child: _revealed
                    ? Text.rich(
                        TextSpan(
                          text: "Te toca regalar a ",
                          children: [
                            TextSpan(
                              text: giftee.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: "."),
                          ],
                        ),
                      )
                    : Text("Tu amigo secreto está oculto."),
              ),
              TextButton(
                onPressed: () => setState(() => _revealed = !_revealed),
                child: Text(_revealed ? "Ocultar" : "Mostrar"),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            "Es un secreto: nadie más puede ver tu pareja.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.onOpenGifteeWishlist != null) ...[
            SizedBox(height: 12),
            ButtonWidget(
              text: "Ver su lista de deseos",
              icon: Icons.card_giftcard,
              function: widget.onOpenGifteeWishlist,
            ),
          ],
        ] else if (_exchange.isParticipant && !_exchange.canChooseGiftee)
          Text("Aún no tienes a quién regalar."),
        if (_exchange.canChooseGiftee && me != null) ...[
          SizedBox(height: 12),
          ButtonWidget(
            text: giftee == null
                ? "Elegir a quién regalo"
                : "Cambiar a quién regalo",
            isOutlined: true,
            isLoading: _busy,
            function: () => _setGiftee(me, clearable: giftee != null),
          ),
        ],
        if (_exchange.canAssignGiftees) ...[
          Divider(height: 32),
          Text(
            "Asignar las parejas",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 4),
          Text(
            "Por privacidad no ves las parejas. Solo puedes asignar a quien aún no eligió a nadie. "
            "${_missing > 0 ? 'Faltan $_missing por asignar.' : 'Todos tienen a quién regalar.'}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final giver in _exchange.participants)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AvatarWidget(
                src: giver.avatar,
                name: giver.name ?? "",
                lastName: giver.lastName,
              ),
              title: Text(giver.label),
              subtitle: Text(giver.hasGiftee ? "Asignado" : "Sin asignar"),
              trailing: giver.hasGiftee
                  ? null
                  : TextButton(
                      onPressed: _busy ? null : () => _setGiftee(giver),
                      child: Text("Elegir"),
                    ),
            ),
        ],
      ],
    );
  }
}
