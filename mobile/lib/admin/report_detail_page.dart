import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> report;

  const ReportDetailPage({
    super.key,
    required this.reportId,
    required this.report,
  });

  String _text(dynamic value, [String fallback = 'Tidak tersedia']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  double? _coordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu verifikasi';
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _dateText(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
      if (date == null) return value;
    }

    if (date == null) return 'Tidak tersedia';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year}, $hour:$minute';
  }

  Future<void> _openMap(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka lokasi: $e')));
    }
  }

  Future<void> _changeStatus(BuildContext context, String status) async {
    final isVerified = status == 'verified';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isVerified ? 'Verifikasi laporan?' : 'Tolak laporan?'),
        content: Text(
          isVerified
              ? 'Pastikan informasi laporan sudah diperiksa sebelum diverifikasi.'
              : 'Laporan ini akan ditandai sebagai ditolak. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isVerified ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isVerified ? 'Verifikasi' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': status});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVerified
                ? 'Laporan berhasil diverifikasi.'
                : 'Laporan berhasil ditolak.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status laporan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _text(report['status'], 'pending');
    final location = _text(report['location']);
    final height = _text(report['waterHeightCm']);
    final severity = _text(report['severity']);
    final userId = _text(report['userId']);
    final description = _text(report['description'] ?? report['details']);

    final photoUrl = _text(
      report['photoUrl'] ??
          report['imageUrl'] ??
          report['imageURL'] ??
          report['photoURL'],
      '',
    );

    final latitude = _coordinate(report['latitude']);
    final longitude = _coordinate(report['longitude']);

    final hasValidCoordinates =
        latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;

    final timestamp = report['createdAt'] ?? report['timestamp'];
    final isPending = status == 'pending';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFE1ECFF),
                  child: Icon(Icons.flood, size: 30, color: blue),
                ),
                SizedBox(height: 14),
                Text(
                  'Informasi Laporan Banjir',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Periksa informasi dan kondisi lapangan sebelum mengambil keputusan.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (photoUrl.isNotEmpty) ...[
            const Text(
              'Foto Kondisi Banjir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photoUrl,
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                          color: Colors.blueGrey,
                        ),
                        SizedBox(height: 8),
                        Text('Foto tidak dapat dimuat.'),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            'Informasi Utama',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 10),

          _InfoTile(
            icon: Icons.location_on_outlined,
            title: 'Lokasi',
            value: location,
          ),

          if (hasValidCoordinates) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.my_location, color: blue),
                        SizedBox(width: 10),
                        Text(
                          'Koordinat Lokasi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      'Latitude: $latitude\nLongitude: $longitude',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openMap(context, latitude, longitude),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Buka Lokasi di Google Maps'),
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Card(
              margin: EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(Icons.location_off, color: Colors.orange),
                title: Text('Koordinat belum tersedia'),
                subtitle: Text(
                  'Laporan ini belum memiliki koordinat latitude dan longitude yang valid.',
                ),
              ),
            ),

          _InfoTile(
            icon: Icons.water,
            title: 'Ketinggian Air',
            value: '$height cm',
          ),
          _InfoTile(
            icon: Icons.warning_amber_rounded,
            title: 'Tingkat Keparahan',
            value: severity,
          ),
          _InfoTile(
            icon: Icons.access_time,
            title: 'Waktu Laporan',
            value: _dateText(timestamp),
          ),
          _InfoTile(
            icon: Icons.person_outline,
            title: 'ID Pelapor',
            value: userId,
          ),
          _InfoTile(icon: Icons.notes, title: 'Keterangan', value: description),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: Icon(
                status == 'verified'
                    ? Icons.verified
                    : status == 'rejected'
                    ? Icons.cancel_outlined
                    : Icons.hourglass_top,
                color: status == 'verified'
                    ? Colors.green
                    : status == 'rejected'
                    ? Colors.red
                    : Colors.orange,
              ),
              title: const Text('Status Laporan'),
              subtitle: Text(
                _statusLabel(status),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (isPending) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _changeStatus(context, 'verified'),
                icon: const Icon(Icons.verified),
                label: const Text('Verifikasi Laporan'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _changeStatus(context, 'rejected'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Tolak Laporan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status == 'verified'
                    ? 'Laporan sudah diverifikasi.'
                    : status == 'rejected'
                    ? 'Laporan sudah ditolak.'
                    : 'Status laporan: $status',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

          const SizedBox(height: 20),
          const Text(
            'Catatan: verifikasi admin membantu memeriksa laporan masyarakat. '
            'Laporan ini bukan peringatan resmi banjir.',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
