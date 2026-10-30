import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari SiagaBanjir?',
            style: TextStyle(color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal', style: TextStyle(color: muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final email = user?.email ?? 'Pengguna SiagaBanjir';
    final displayName = user?.displayName;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(color: navy, fontWeight: FontWeight.bold),
        ),
        backgroundColor: background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),

          // Foto profil
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: blue.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 55,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: Text(
              displayName?.isNotEmpty == true
                  ? displayName!
                  : 'Pengguna SiagaBanjir',
              style: const TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              email,
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Informasi Akun',
            style: TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ProfileInfoRow(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: email,
                ),
                const Divider(height: 24),
                _ProfileInfoRow(
                  icon: Icons.verified_user_outlined,
                  title: 'Status akun',
                  value: user?.emailVerified == true
                      ? 'Terverifikasi'
                      : 'Belum terverifikasi',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Akun',
            style: TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
  color: Colors.transparent,
  borderRadius: BorderRadius.circular(16),
  clipBehavior: Clip.antiAlias,
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 6,
    ),
    leading: const Icon(Icons.logout_rounded, color: Colors.red),
    title: const Text(
      'Keluar dari akun',
      style: TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: muted,
    ),
    onTap: () => _logout(context),
  ),
),
          ),

          const SizedBox(height: 28),

          const Center(
            child: Text(
              'SiagaBanjir',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Bersama lebih tanggap terhadap banjir',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: blue, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: muted, fontSize: 11)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
