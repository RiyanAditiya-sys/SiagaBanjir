import 'package:flutter/material.dart';

import '../core/constants.dart';

class OnboardingPage extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingPage({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),

                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.water_damage_rounded,
                          color: blue,
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'SiagaBanjir',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Bersama kita pantau kondisi banjir '
                        'dan bantu masyarakat mendapatkan informasi '
                        'yang lebih cepat.',
                        style: TextStyle(
                          fontSize: 16,
                          color: muted,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 32),

                      const _FeatureRow(
                        icon: Icons.location_on_outlined,
                        title: 'Pantau lokasi banjir',
                        subtitle: 'Lihat laporan kondisi banjir di peta.',
                      ),

                      const SizedBox(height: 20),

                      const _FeatureRow(
                        icon: Icons.campaign_outlined,
                        title: 'Laporkan kondisi',
                        subtitle: 'Bagikan informasi banjir di sekitarmu.',
                      ),

                      const SizedBox(height: 20),

                      const _FeatureRow(
                        icon: Icons.verified_outlined,
                        title: 'Informasi terverifikasi',
                        subtitle: 'Laporan dapat diperiksa oleh admin.',
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Mulai Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Center(
                        child: Text(
                          'Informasi laporan bukan peringatan resmi '
                          'sebelum divalidasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: muted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: blue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
