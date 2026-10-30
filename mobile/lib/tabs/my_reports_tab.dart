import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';

class MyReportsTab extends StatelessWidget {
  const MyReportsTab({super.key});

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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'terverifikasi':
        return Icons.verified_rounded;
      case 'rejected':
      case 'ditolak':
        return Icons.cancel_rounded;
      case 'resolved':
      case 'selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Laporan Saya',
          style: TextStyle(color: navy, fontWeight: FontWeight.bold),
        ),
        backgroundColor: background,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _ReportMessage(
              icon: Icons.error_outline_rounded,
              message: 'Gagal memuat laporan.',
              description: 'Periksa koneksi internet dan coba kembali.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs ?? [];

          if (reports.isEmpty) {
            return const _ReportMessage(
              icon: Icons.description_outlined,
              message: 'Belum ada laporan',
              description: 'Laporan banjir yang kamu buat akan muncul di sini.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index].data();

              final location =
                  data['location']?.toString() ?? 'Lokasi tidak tersedia';

              final waterLevel = data['waterLevel']?.toString() ?? '-';

              final status = data['status']?.toString() ?? 'pending';

              final statusColor = _statusColor(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCEBFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(
                            Icons.water_drop_outlined,
                            color: muted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Ketinggian air',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            '$waterLevel cm',
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const Divider(height: 1),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Icon(
                            _statusIcon(status),
                            color: statusColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Status laporan',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (data['description'] != null &&
                          data['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          data['description'].toString(),
                          style: const TextStyle(
                            color: muted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String description;

  const _ReportMessage({
    required this.icon,
    required this.message,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: muted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
