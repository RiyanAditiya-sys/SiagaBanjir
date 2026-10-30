
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../pages/create_report_page.dart';
import '../widgets/stat_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<void> _openCreateReport(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateReportPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Pengguna';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // HEADER
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SiagaBanjir',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Halo, $displayName!',
                      style: const TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                backgroundColor: Color(0xFFDCEBFF),
                child: Icon(
                  Icons.waves_rounded,
                  color: blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // BANNER UTAMA
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: cyan,
                  size: 34,
                ),
                SizedBox(height: 15),
                Text(
                  'Waspada Banjir,\nSelamatkan Sesama',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Bagikan informasi kondisi banjir agar masyarakat '
                  'dapat meningkatkan kewaspadaan.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TOMBOL BUAT LAPORAN
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => _openCreateReport(context),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Buat Laporan Banjir'),
            ),
          ),

          const SizedBox(height: 26),

          // INFORMASI DAN PENGUMUMAN
          const Text(
            'Informasi & Pengumuman',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),

          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('broadcasts')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _emptyBroadcast(
                  Icons.error_outline_rounded,
                  'Gagal memuat pengumuman.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final allBroadcasts = snapshot.data?.docs ?? [];

              // Hanya tampilkan pengumuman aktif.
              final announcements = allBroadcasts.where((doc) {
                return doc.data()['active'] == true;
              }).toList();

              // Urutkan berdasarkan waktu terbaru.
              announcements.sort((a, b) {
                final dateA = a.data()['createdAt'];
                final dateB = b.data()['createdAt'];

                final timeA = dateA is Timestamp
                    ? dateA.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                final timeB = dateB is Timestamp
                    ? dateB.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                return timeB.compareTo(timeA);
              });

              if (announcements.isEmpty) {
                return _emptyBroadcast(
                  Icons.notifications_none_rounded,
                  allBroadcasts.isEmpty
                      ? 'Belum ada pengumuman dari admin.'
                      : 'Belum ada pengumuman aktif dari admin.',
                );
              }

              return Column(
                children: announcements.map((doc) {
                  final data = doc.data();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BroadcastCard(
                      title: data['title']?.toString() ?? 'Pengumuman',
                      message: data['message']?.toString() ?? '',
                      category: data['category']?.toString() ?? 'info',
                      createdAt: data['createdAt'],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          // RINGKASAN LAPORAN
          const Text(
            'Ringkasan Laporan',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),

          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Gagal memuat ringkasan laporan.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final reports = snapshot.data!.docs;

              final total = reports
                  .where(
                    (doc) => doc.data()['status'] != 'rejected',
                  )
                  .length;

              final verified = reports
                  .where(
                    (doc) => doc.data()['status'] == 'verified',
                  )
                  .length;

              final pending = reports
                  .where(
                    (doc) => doc.data()['status'] == 'pending',
                  )
                  .length;

              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total',
                      value: '$total',
                      icon: Icons.assignment_outlined,
                      color: blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Terverifikasi',
                      value: '$verified',
                      icon: Icons.verified_outlined,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Menunggu',
                      value: '$pending',
                      icon: Icons.hourglass_empty_rounded,
                      color: Colors.orange,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // DISCLAIMER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: blue,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Laporan warga bukan peringatan resmi. Periksa status '
                    'verifikasi dan ikuti informasi dari instansi berwenang.',
                    style: TextStyle(
                      height: 1.5,
                      color: navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBroadcast(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: muted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  final String title;
  final String message;
  final String category;
  final dynamic createdAt;

  const _BroadcastCard({
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
  });

  Color get categoryColor {
    switch (category) {
      case 'emergency':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return blue;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'emergency':
        return Icons.warning_rounded;
      case 'warning':
        return Icons.notifications_active_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'emergency':
        return 'DARURAT';
      case 'warning':
        return 'PERINGATAN';
      default:
        return 'INFORMASI';
    }
  }

  String get formattedDate {
    if (createdAt is! Timestamp) {
      return 'Baru saja';
    }

    final date = (createdAt as Timestamp).toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final color = categoryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                categoryIcon,
                color: color,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text(
                categoryLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.circle,
                size: 7,
                color: Colors.green,
              ),
              const SizedBox(width: 5),
              const Text(
                'Aktif',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            message,
            style: const TextStyle(
              color: muted,
              height: 1.5,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: muted,
              ),
              const SizedBox(width: 5),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
