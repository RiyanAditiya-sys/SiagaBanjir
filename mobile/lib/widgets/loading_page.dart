import 'package:flutter/material.dart';

import '../core/constants.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: background,
      body: Center(
        child: CircularProgressIndicator(
          color: blue,
        ),
      ),
    );
  }
}