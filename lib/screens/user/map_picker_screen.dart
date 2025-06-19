import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Gunakan latlong2

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static final _initialPosition = LatLng(-6.168806, 106.595926);
  LatLng? _pickedLocation;

  void _selectLocation(TapPosition tapPosition, LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Pengiriman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed:
                _pickedLocation == null
                    ? null
                    : () {
                      Navigator.of(context).pop(_pickedLocation);
                    },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _initialPosition,
          initialZoom: 13.0,
          onTap: _selectLocation,
        ),
        children: [
          // Layer untuk menampilkan peta dari OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ffwant.kebuli_mimi',
          ),
          // Layer untuk menampilkan penanda/marker di lokasi yang dipilih
          if (_pickedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _pickedLocation!,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40.0,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
