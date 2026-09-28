import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PickLocationResult {
  final LatLng latLng;
  final String address;

  const PickLocationResult({
    required this.latLng,
    required this.address,
  });
}

class PickLocationPage extends StatefulWidget {
  final String title;
  final LatLng initial;

  const PickLocationPage({
    super.key,
    required this.title,
    required this.initial,
  });

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  GoogleMapController? _controller;

  LatLng? _selected;
  String _address = "Tap on the map to select a location";
  bool _loadingAddress = false;

  late LatLng _cameraStart;

  @override
  void initState() {
    super.initState();
    _cameraStart = widget.initial;
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _cameraStart = here;
      });

      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: here, zoom: 15),
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _updateAddress(LatLng latLng) async {
    setState(() {
      _loadingAddress = true;
      _address = "Loading address...";
    });

    try {
      final places = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (places.isEmpty) {
        setState(() => _address = "No address found");
        return;
      }

      final p = places.first;
      final text = [
        if ((p.street ?? "").trim().isNotEmpty) p.street!.trim(),
        if ((p.subLocality ?? "").trim().isNotEmpty) p.subLocality!.trim(),
        if ((p.locality ?? "").trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? "").trim().isNotEmpty) p.administrativeArea!.trim(),
        if ((p.country ?? "").trim().isNotEmpty) p.country!.trim(),
      ].join(", ");

      setState(() => _address = text.isEmpty ? "Address not available" : text);
    } catch (_) {
      setState(() => _address = "Failed to get address");
    } finally {
      setState(() => _loadingAddress = false);
    }
  }

  void _onTap(LatLng latLng) {
    setState(() {
      _selected = latLng;
    });
    _updateAddress(latLng);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    if (_selected != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("selected"),
          position: _selected!,
        ),
      );
    }

    final canConfirm = _selected != null && !_loadingAddress;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (c) {
                _controller = c;
                c.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _cameraStart, zoom: 14),
                  ),
                );
              },
              initialCameraPosition: CameraPosition(target: _cameraStart, zoom: 14),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: _onTap,
              markers: markers,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_address, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: canConfirm
                      ? () {
                          Navigator.pop<PickLocationResult>(
                            context,
                            PickLocationResult(
                              latLng: _selected!,
                              address: _address,
                            ),
                          );
                        }
                      : null,
                  child: _loadingAddress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Confirm Location"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
