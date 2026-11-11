import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:primo_secreto_app/services/location_service.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';
import 'package:primo_secreto_app/widgets/common/button_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMapPage extends StatefulWidget {
  final LatLng? initial;
  final bool readOnly;

  const LocationMapPage({super.key, this.initial, this.readOnly = false});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  LatLng? _position;
  bool _hasPermission = false;
  bool _usesFallback = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.readOnly) {
      setState(() => _position = widget.initial ?? LocationService.fallback);
      return;
    }

    final hasPermission = await _locationService.requestPermission();
    final current = widget.initial == null && hasPermission
        ? await _locationService.currentPosition()
        : null;
    if (!mounted) return;

    setState(() {
      _hasPermission = hasPermission;
      _usesFallback = widget.initial == null && current == null;
      _position = widget.initial ?? current ?? LocationService.fallback;
    });
  }

  void _move(LatLng position) {
    setState(() {
      _position = position;
      _usesFallback = false;
    });
  }

  Future<bool> _open(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _go(LatLng position) async {
    final point = "${position.latitude},${position.longitude}";
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    final opened = isIos
        ? await _open("https://maps.apple.com/?daddr=$point")
        : await _open("geo:$point?q=$point") ||
              await _open(
                "https://www.google.com/maps/dir/?api=1&destination=$point",
              );

    if (!opened && mounted) {
      showMessage(
        context,
        "No encontramos una aplicación de mapas para abrir la ruta.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? "Lugar del sorteo" : "Elegir ubicación"),
      ),
      body: position == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: _usesFallback ? 12 : 16,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: _hasPermission,
                    myLocationButtonEnabled: _hasPermission,
                    onTap: widget.readOnly ? null : _move,
                    markers: {
                      Marker(
                        markerId: MarkerId("place"),
                        position: position,
                        draggable: !widget.readOnly,
                        onDragEnd: _move,
                      ),
                    },
                  ),
                ),
                if (widget.readOnly)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: ButtonWidget(
                        text: "Ir",
                        icon: Icons.directions,
                        function: () => _go(position),
                      ),
                    ),
                  )
                else
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _usesFallback
                                ? "No pudimos obtener tu ubicación. Toca el mapa para mover el marcador."
                                : "Toca el mapa o arrastra el marcador para cambiar la ubicación.",
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          ButtonWidget(
                            text: "Usar esta ubicación",
                            icon: Icons.check,
                            function: () => Navigator.pop(context, position),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
