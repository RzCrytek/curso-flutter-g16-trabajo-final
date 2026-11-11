import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/models/wishlist_model.dart';
import 'package:primo_secreto_app/pages/exchange/wish_form_page.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/wishlist_service.dart';
import 'package:primo_secreto_app/utils/action_utils.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/banner_widget.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:primo_secreto_app/widgets/common/field_widget.dart';
import 'package:primo_secreto_app/widgets/common/section_card_widget.dart';
import 'package:primo_secreto_app/widgets/exchange/wish_item_widget.dart';

class WishlistTab extends StatefulWidget {
  final ExchangeModel exchange;
  final VoidCallback onOpenGifteeWishlist;

  const WishlistTab({
    super.key,
    required this.exchange,
    required this.onOpenGifteeWishlist,
  });

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab>
    with AutomaticKeepAliveClientMixin {
  final WishlistService _wishlistService = WishlistService();
  final _dislikesController = TextEditingController();

  WishlistModel? _wishlist;
  bool _loadFailed = false;
  bool _savingDislikes = false;

  @override
  bool get wantKeepAlive => true;

  bool get _closed => widget.exchange.wishlistClosed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dislikesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _setWishlist(await _wishlistService.mine(widget.exchange.uuid));
      _loadFailed = false;
    } on ApiException catch (_) {
      _loadFailed = _wishlist == null;
    }
    if (mounted) setState(() {});
  }

  void _setWishlist(WishlistModel wishlist) {
    _wishlist = wishlist;
    _dislikesController.text = wishlist.dislikes ?? "";
  }

  Future<void> _openForm([WishItemModel? item]) async {
    final saved = await Navigator.push<WishlistModel>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WishFormPage(exchangeUuid: widget.exchange.uuid, item: item),
      ),
    );
    if (saved != null && mounted) setState(() => _setWishlist(saved));
  }

  Future<void> _remove(WishItemModel item) async {
    final confirmed = await confirmDialog(
      context,
      title: "Eliminar deseo",
      message: "¿Eliminar «${item.title}» de tu lista?",
      confirmLabel: "Eliminar",
    );
    if (!confirmed || !mounted) return;

    await runVoidAction(
      context,
      () => _wishlistService.removeItem(widget.exchange.uuid, item.uuid),
      success: "Eliminamos el deseo.",
    );
    _load();
  }

  Future<void> _saveDislikes() async {
    setState(() => _savingDislikes = true);
    final saved = await runAction(
      context,
      () => _wishlistService.saveDislikes(
        widget.exchange.uuid,
        _dislikesController.text,
      ),
      success: "Guardamos lo que no quieres recibir.",
    );
    if (!mounted) return;
    setState(() {
      _savingDislikes = false;
      if (saved != null) _setWishlist(saved);
    });
  }

  String? _statusNote() {
    final exchange = widget.exchange;
    if (exchange.wishlistClosed) {
      return exchange.wishlistLocked || exchange.wishlistDeadline == null
          ? "Las listas de deseos están cerradas: ya no se pueden editar."
          : "Las listas de deseos se cerraron el ${formatEventDate(exchange.wishlistDeadline!)}: ya no se pueden editar.";
    }
    if (exchange.wishlistDeadline != null) {
      return "Puedes editar tu lista hasta el ${formatEventDate(exchange.wishlistDeadline!)}.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final note = _statusNote();
    final wishlist = _wishlist;

    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("No se pudo cargar tu lista."),
            TextButton(onPressed: _load, child: Text("Reintentar")),
          ],
        ),
      );
    }
    if (wishlist == null) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (note != null) BannerWidget(text: note, isError: _closed),
          if (widget.exchange.myGiftee != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ButtonWidget(
                text: "Lista de mi amigo secreto",
                icon: Icons.card_giftcard,
                isOutlined: true,
                function: widget.onOpenGifteeWishlist,
              ),
            ),
          SectionCardWidget(
            title: "Mis deseos",
            children: [
              if (wishlist.items.isEmpty)
                Text(
                  _closed
                      ? "No agregaste nada a tu lista."
                      : "Todavía no agregaste nada. Cuéntale a tu amigo secreto qué te gustaría recibir.",
                ),
              for (final item in wishlist.items)
                WishItemWidget(
                  item: item,
                  onEdit: _closed ? null : () => _openForm(item),
                  onDelete: _closed ? null : () => _remove(item),
                ),
              if (!_closed) SizedBox(height: 12),
              if (!_closed)
                ButtonWidget(
                  text: "Agregar deseo",
                  icon: Icons.add,
                  function: _openForm,
                ),
            ],
          ),
          SectionCardWidget(
            title: "Lo que no quiero recibir",
            children: [
              if (_closed)
                Text(wishlist.dislikes ?? "No escribiste nada.")
              else ...[
                FieldWidget(
                  controller: _dislikesController,
                  label: "Cosas que prefieres que no te regalen",
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                ButtonWidget(
                  text: "Guardar",
                  function: _saveDislikes,
                  isLoading: _savingDislikes,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
