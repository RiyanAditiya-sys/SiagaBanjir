import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../pages/auth_page.dart';
import 'admin_map_page.dart';
import 'report_detail_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun admin?'),
        content: const Text('Yakin ingin mengakhiri sesi admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
    }
  }

  Future<void> _updateReportStatus(
    BuildContext context,
    String reportId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': status});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'verified'
                ? 'Laporan berhasil diverifikasi.'
                : 'Laporan berhasil ditolak.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui laporan: $e')));
    }
  }

  Future<void> _confirmStatusChange(
    BuildContext context,
    String reportId,
    String status,
  ) async {
    final isVerify = status == 'verified';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isVerify ? 'Verifikasi laporan?' : 'Tolak laporan?'),
        content: Text(
          isVerify
              ? 'Pastikan informasi laporan sudah diperiksa sebelum diverifikasi.'
              : 'Yakin ingin menolak laporan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isVerify ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isVerify ? 'Verifikasi' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _updateReportStatus(context, reportId, status);
    }
  }

  void _openAdminMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminMapPage()),
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
            Text('SiagaBanjir', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Panel Administrator',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat laporan. Periksa koneksi dan Firestore Rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs ?? [];

          final sortedReports = [...reports]
            ..sort((a, b) {
              final aDate = a.data()['createdAt'];
              final bDate = b.data()['createdAt'];

              if (aDate is Timestamp && bDate is Timestamp) {
                return bDate.compareTo(aDate);
              }
              if (aDate is Timestamp) return -1;
              if (bDate is Timestamp) return 1;
              return 0;
            });

          final pending = reports
              .where((doc) => doc.data()['status'] == 'pending')
              .length;

          final verified = reports
              .where((doc) => doc.data()['status'] == 'verified')
              .length;

          final rejected = reports
              .where((doc) => doc.data()['status'] == 'rejected')
              .length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Pantau dan kelola laporan kondisi banjir dari masyarakat.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 22),

              // Menu peta pemantauan admin
              InkWell(
                onTap: () => _openAdminMap(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1769E0), Color(0xFF102A43)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: blue.withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Peta Pemantauan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pantau sebaran laporan banjir secara langsung.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'Ringkasan Laporan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _StatCard(
                    title: 'Menunggu',
                    count: pending,
                    icon: Icons.hourglass_top,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Terverifikasi',
                    count: verified,
                    icon: Icons.verified,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Ditolak',
                    count: rejected,
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                  _StatCard(
                    title: 'Total Laporan',
                    count: reports.length,
                    icon: Icons.flood,
                    color: blue,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Laporan Masuk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),
                  Text(
                    '${reports.length} laporan',
                    style: const TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (sortedReports.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 44,
                          color: Colors.blueGrey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Belum ada laporan banjir.',
                          style: TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...sortedReports.take(30).map((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? 'pending').toString();
                  final location = (data['location'] ?? 'Lokasi tidak tersedia')
                      .toString();
                  final height = data['waterHeightCm'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: blue.withValues(alpha: 0.10),
                        child: const Icon(Icons.flood, color: blue),
                      ),
                      title: Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ketinggian air: $height cm'),
                            const SizedBox(height: 5),
                            _StatusBadge(status: status),
                            const SizedBox(height: 5),
                            const Text(
                              'Ketuk untuk melihat detail dan lokasi',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ],
                        ),
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(
                              reportId: doc.id,
                              report: data,
                            ),
                          ),
                        );
                      },
                      trailing: status == 'pending'
                          ? PopupMenuButton<String>(
                              tooltip: 'Aksi laporan',
                              onSelected: (value) {
                                _confirmStatusChange(context, doc.id, value);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'verified',
                                  child: Row(
                                    children: [
                                      Icon(Icons.verified, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Verifikasi'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'rejected',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Tolak laporan'),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Icon(
                              status == 'verified'
                                  ? Icons.verified
                                  : Icons.cancel_outlined,
                              color: status == 'verified'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (status) {
      case 'verified':
        color = Colors.green;
        label = 'Terverifikasi';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Ditolak';
        break;
      default:
        color = Colors.orange;
        label = 'Menunggu verifikasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
