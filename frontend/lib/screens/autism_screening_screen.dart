import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AutismScreeningScreen extends StatelessWidget {
  const AutismScreeningScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Autism Screening',
          style: GoogleFonts.inter(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Autism Screening Flow',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This module is under development.',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
