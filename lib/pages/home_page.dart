import 'package:flutter/material.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/pages/exchange/exchange_create_page.dart';
import 'package:primo_secreto_app/pages/exchange/exchange_detail_page.dart';
import 'package:primo_secreto_app/pages/profile_page.dart';
import 'package:primo_secreto_app/providers/auth_provider.dart';
import 'package:primo_secreto_app/providers/theme_provider.dart';
import 'package:primo_secreto_app/services/api_client.dart';
import 'package:primo_secreto_app/services/exchange_service.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/widgets/common/avatar_widget.dart';
import 'package:primo_secreto_app/widgets/home/exchange_card_widget.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ExchangeService _exchangeService = ExchangeService();

  List<ExchangeModel> _exchanges = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadExchanges();
  }

  Future<void> _loadExchanges() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      _exchanges = sortByEventDate(await _exchangeService.list());
    } on ApiException catch (_) {
      _loadFailed = true;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    _loadExchanges();
  }

  Widget _body() {
    if (_isLoading && _exchanges.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("No se pudieron cargar tus sorteos."),
            TextButton(
              onPressed: _loadExchanges,
              child: Text("Reintentar"),
            ),
          ],
        ),
      );
    }
    if (_exchanges.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 120),
          Icon(Icons.card_giftcard, size: 64),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Todavía no participas en ningún sorteo. Crea el primero con el botón de abajo.",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _exchanges.length,
      itemBuilder: (BuildContext context, int index) {
        final exchange = _exchanges[index];
        return ExchangeCardWidget(
          exchange: exchange,
          function: () => _open(ExchangeDetailPage(uuid: exchange.uuid)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset("assets/images/logo_96x96.png", width: 36, height: 36),
            SizedBox(width: 10),
            Text("Mis sorteos"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Cambiar tema",
            onPressed: themeProvider.toggle,
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          IconButton(
            tooltip: "Mi perfil",
            onPressed: () => _open(ProfilePage()),
            icon: AvatarWidget(
              src: user?.avatar,
              name: user?.name ?? "",
              lastName: user?.lastName,
              size: 32,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(ExchangeCreatePage()),
        icon: Icon(Icons.add),
        label: Text("Crear sorteo"),
      ),
      body: RefreshIndicator(onRefresh: _loadExchanges, child: _body()),
    );
  }
}
