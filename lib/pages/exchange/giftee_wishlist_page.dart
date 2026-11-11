import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/models/wishlist_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/wishlist_service.dart';
import 'package:primo_secreto_app/widgets/common/section_card_widget.dart';
import 'package:primo_secreto_app/widgets/exchange/wish_item_widget.dart';

class GifteeWishlistPage extends StatefulWidget {
  final ExchangeModel exchange;

  const GifteeWishlistPage({super.key, required this.exchange});

  @override
  State<GifteeWishlistPage> createState() => _GifteeWishlistPageState();
}

class _GifteeWishlistPageState extends State<GifteeWishlistPage> {
  final WishlistService _wishlistService = WishlistService();

  WishlistModel? _wishlist;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      _wishlist = await _wishlistService.giftee(widget.exchange.uuid);
    } on ApiException catch (_) {
      _loadFailed = true;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final giftee = widget.exchange.myGiftee;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          giftee == null
              ? "Lista de mi amigo secreto"
              : "Lista de ${giftee.fullName}",
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("No se pudo cargar la lista."),
                  TextButton(onPressed: _load, child: Text("Reintentar")),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  if (_wishlist!.items.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Todavía no agregó nada a su lista. Vuelve a mirar más adelante.",
                      ),
                    ),
                  for (final item in _wishlist!.items)
                    WishItemWidget(item: item),
                  if (_wishlist!.dislikes != null)
                    SectionCardWidget(
                      title: "Prefiere que no le regalen",
                      children: [Text(_wishlist!.dislikes!)],
                    ),
                ],
              ),
            ),
    );
  }
}
