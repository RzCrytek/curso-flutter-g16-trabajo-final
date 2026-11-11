import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/pages/exchange/exchange_settings_page.dart';
import 'package:primo_secreto_app/pages/exchange/giftee_wishlist_page.dart';
import 'package:primo_secreto_app/pages/exchange/nominations_tab.dart';
import 'package:primo_secreto_app/pages/exchange/wishlist_tab.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/exchange_service.dart';
import 'package:primo_secreto_app/widgets/exchange_detail/draw_widget.dart';
import 'package:primo_secreto_app/widgets/exchange_detail/exchange_info_widget.dart';
import 'package:primo_secreto_app/widgets/exchange/members_widget.dart';

enum _LoadState { loading, notFound, failed, ready }

class ExchangeDetailPage extends StatefulWidget {
  final String uuid;

  const ExchangeDetailPage({super.key, required this.uuid});

  @override
  State<ExchangeDetailPage> createState() => _ExchangeDetailPageState();
}

class _ExchangeDetailPageState extends State<ExchangeDetailPage> {
  final ExchangeService _exchangeService = ExchangeService();

  ExchangeModel? _exchange;
  _LoadState _state = _LoadState.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _exchange = await _exchangeService.get(widget.uuid);
      _state = _LoadState.ready;
    } on ApiException catch (e) {
      if (_exchange == null) {
        _state = e.statusCode == 404 ? _LoadState.notFound : _LoadState.failed;
      }
    }
    if (mounted) setState(() {});
  }

  void _update(ExchangeModel exchange) => setState(() => _exchange = exchange);

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExchangeSettingsPage(exchange: _exchange!),
      ),
    );
    _load();
  }

  void _openGifteeWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GifteeWishlistPage(exchange: _exchange!),
      ),
    );
  }

  Widget _message(String title, String text, {bool retry = false}) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center),
              if (retry)
                TextButton(onPressed: _load, child: Text("Reintentar")),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _LoadState.loading:
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: CircularProgressIndicator()),
        );
      case _LoadState.notFound:
        return _message(
          "No encontramos este sorteo",
          "Puede que ya no exista o que no participes en él.",
        );
      case _LoadState.failed:
        return _message(
          "No se pudo cargar el sorteo",
          "Revisa tu conexión e inténtalo de nuevo.",
          retry: true,
        );
      case _LoadState.ready:
        break;
    }

    final exchange = _exchange!;
    final tabs = [
      "Sorteo",
      if (exchange.isParticipant) "Deseos",
      "Nominaciones",
    ];

    return DefaultTabController(
      key: ValueKey(tabs.length),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(exchange.title),
          actions: [
            if (exchange.canEdit || exchange.canManageMembers)
              IconButton(
                tooltip: "Configuración del sorteo",
                onPressed: _openSettings,
                icon: Icon(Icons.settings),
              ),
          ],
          bottom: TabBar(tabs: tabs.map((tab) => Tab(text: tab)).toList()),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  ExchangeInfoWidget(exchange: exchange),
                  DrawWidget(
                    exchange: exchange,
                    onChanged: _update,
                    onOpenGifteeWishlist: exchange.myGiftee == null
                        ? null
                        : _openGifteeWishlist,
                  ),
                  MembersWidget(exchange: exchange, onChanged: _update),
                ],
              ),
            ),
            if (exchange.isParticipant)
              WishlistTab(
                exchange: exchange,
                onOpenGifteeWishlist: _openGifteeWishlist,
              ),
            NominationsTab(exchange: exchange),
          ],
        ),
      ),
    );
  }
}
