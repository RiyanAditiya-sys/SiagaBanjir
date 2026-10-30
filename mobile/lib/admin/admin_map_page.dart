import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final MapController _mapController = MapController();

  static const LatLng _lampung = LatLng(-5.3971, 105.2668);

  String _selectedFilter = 'all';

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _validCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      case 'resolved':
        return 'Selesai';
      default:
        return 'Menunggu verifikasi';
    }
  }

  void _showReportDetail(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'pending';
    final photoUrl = data['photoUrl']?.toString() ?? '';
    final waterHeight = data['waterHeightCm'];

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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                            'Foto tidak dapat dimuat.',
                            style: TextStyle(color: muted),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _DetailRow(
                  label: 'Lokasi',
                  value: data['location']?.toString() ?? '-',
                ),
                _DetailRow(
                  label: 'Ketinggian air',
                  value: waterHeight == null ? '-' : '$waterHeight cm',
                ),
                _DetailRow(
                  label: 'Tingkat risiko',
                  value: data['severity']?.toString() ?? '-',
                ),
                _DetailRow(label: 'Status', value: _statusLabel(status)),
                _DetailRow(
                  label: 'Koordinat',
                  value:
                      '${data['latitude'] ?? '-'}, ${data['longitude'] ?? '-'}',
                ),
                _DetailRow(
                  label: 'Keterangan',
                  value: data['description']?.toString() ?? '-',
                ),

                const SizedBox(height: 12),
                const Text(
                  'Laporan masyarakat bukan peringatan resmi sebelum '
                  'diverifikasi oleh administrator.',
                  style: TextStyle(color: muted, fontSize: 12),
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
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peta Pemantauan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Panel Administrator',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data laporan.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs ?? [];

          final validReports = reports.where((doc) {
            final data = doc.data();
            final latitude = _toDouble(data['latitude']);
            final longitude = _toDouble(data['longitude']);

            if (!_validCoordinate(latitude, longitude)) return false;

            if (_selectedFilter == 'all') return true;

            return (data['status']?.toString() ?? 'pending') == _selectedFilter;
          }).toList();

          final pending = reports
              .where((doc) => doc.data()['status'] == 'pending')
              .length;
          final verified = reports
              .where((doc) => doc.data()['status'] == 'verified')
              .length;
          final rejected = reports
              .where((doc) => doc.data()['status'] == 'rejected')
              .length;

          final markers = validReports.map((doc) {
            final data = doc.data();
            final latitude = _toDouble(data['latitude']);
            final longitude = _toDouble(data['longitude']);
            final status = data['status']?.toString() ?? 'pending';

            return Marker(
              point: LatLng(latitude, longitude),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _showReportDetail(data),
                child: Icon(
                  Icons.location_on,
                  color: _statusColor(status),
                  size: 40,
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              FlutterMap(
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
              ),

              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Pemantauan',
                            style: TextStyle(
                              color: navy,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _SummaryItem(
                                label: 'Menunggu',
                                count: pending,
                                color: Colors.orange,
                              ),
                              _SummaryItem(
                                label: 'Terverifikasi',
                                count: verified,
                                color: Colors.red,
                              ),
                              _SummaryItem(
                                label: 'Ditolak',
                                count: rejected,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('Semua status laporan'),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Menunggu verifikasi'),
                            ),
                            DropdownMenuItem(
                              value: 'verified',
                              child: Text('Terverifikasi'),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text('Ditolak'),
                            ),
                            DropdownMenuItem(
                              value: 'resolved',
                              child: Text('Selesai'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                left: 12,
                bottom: 16,
                child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${validReports.length} titik laporan',
                        style: const TextStyle(
                          color: navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _LegendItem(
                        color: Colors.red,
                        label: 'Terverifikasi',
                      ),
                      const _LegendItem(
                        color: Colors.orange,
                        label: 'Menunggu',
                      ),
                      const _LegendItem(color: Colors.grey, label: 'Ditolak'),
                      const _LegendItem(color: Colors.green, label: 'Selesai'),
                    ],
                  ),
                ),
              ),

              Positioned(
                right: 16,
                bottom: 24,
                child: FloatingActionButton(
                  heroTag: 'adminMapCenterButton',
                  backgroundColor: Colors.white,
                  foregroundColor: blue,
                  onPressed: () {
                    _mapController.move(_lampung, 12);
                  },
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
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
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
        ],
      ),
    );
  }
}
