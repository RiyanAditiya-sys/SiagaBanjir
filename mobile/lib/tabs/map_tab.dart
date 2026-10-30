import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();

  static const LatLng _lampung = LatLng(-5.3971, 105.2668);

  LatLng _currentLocation = _lampung;
  bool _isLoadingLocation = false;
  bool _hasCurrentLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Layanan lokasi belum aktif.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan.',
        );
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = location;
        _hasCurrentLocation = true;
      });

      _mapController.move(location, 14);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'terverifikasi':
        return 'Terverifikasi';
      case 'rejected':
      case 'ditolak':
        return 'Ditolak';
      case 'resolved':
      case 'selesai':
        return 'Selesai';
      default:
        return 'Menunggu verifikasi';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'terverifikasi':
        return Colors.red;
      case 'rejected':
      case 'ditolak':
        return Colors.grey;
      case 'resolved':
      case 'selesai':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  void _showReportDetail(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'pending';
    final waterHeight = data['waterHeightCm'];
    final photoUrl = data['photoUrl']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Detail Laporan Banjir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 16),

                if (photoUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      photoUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: background,
                          alignment: Alignment.center,
                          child: const Text(
                            'Foto laporan tidak dapat dimuat.',
                            style: TextStyle(color: muted),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _MapDetailRow(
                  label: 'Lokasi',
                  value: data['location']?.toString() ?? '-',
                ),
                _MapDetailRow(
                  label: 'Ketinggian Air',
                  value: waterHeight == null ? '-' : '$waterHeight cm',
                ),
                _MapDetailRow(label: 'Status', value: _statusLabel(status)),
                _MapDetailRow(
                  label: 'Tingkat Risiko',
                  value: data['severity']?.toString() ?? '-',
                ),
                _MapDetailRow(
                  label: 'Keterangan',
                  value: data['description']?.toString() ?? '-',
                ),

                const SizedBox(height: 12),
                const Text(
                  'Informasi ini berasal dari laporan masyarakat '
                  'dan bukan peringatan resmi sebelum diverifikasi.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Gagal memuat data laporan.'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = snapshot.data?.docs ?? [];

              final markers = <Marker>[];

              if (_hasCurrentLocation) {
                markers.add(
                  Marker(
                    point: _currentLocation,
                    width: 42,
                    height: 42,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                );
              }

              for (final doc in reports) {
                final data = doc.data();

                final latitude = _toDouble(data['latitude']);
                final longitude = _toDouble(data['longitude']);

                if (!_isValidCoordinate(latitude, longitude)) {
                  continue;
                }

                final status = data['status']?.toString() ?? 'pending';

                markers.add(
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 42,
                    height: 42,
                    child: GestureDetector(
                      onTap: () => _showReportDetail(data),
                      child: Icon(
                        Icons.location_on,
                        color: _statusColor(status),
                        size: 38,
                      ),
                    ),
                  ),
                );
              }

              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _lampung,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.siagabanjir',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peta Banjir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pantau laporan kondisi banjir di sekitar wilayah.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              heroTag: 'currentLocationButton',
              backgroundColor: Colors.white,
              foregroundColor: blue,
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          const Positioned(left: 16, bottom: 24, child: _MapLegend()),
        ],
      ),
    );
  }
}

class _MapDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _MapDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keterangan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          _LegendItem(color: Colors.red, label: 'Terverifikasi'),
          _LegendItem(color: Colors.orange, label: 'Menunggu'),
          _LegendItem(color: Colors.green, label: 'Selesai'),
          _LegendItem(color: Colors.grey, label: 'Ditolak'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }
}
