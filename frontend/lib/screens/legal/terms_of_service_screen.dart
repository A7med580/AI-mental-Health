import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description_outlined, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mindful AI Terms',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Effective Date: April 2026',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionCard(
                    '1. Introduction',
                    'Welcome to Mindful AI, an AI-powered mental health pre-screening platform ("Service"). These Terms of Service ("Terms") constitute a legally binding agreement between you ("User" or "you") and Mindful AI ("Company," "we," or "us"). By accessing, downloading, or using the Mindful AI application or website, you agree to be bound by these Terms. If you do not agree to any part of these Terms, you must not use the Service.',
                    Icons.info_outline,
                  ),
                  _buildSectionCard(
                    '2. Medical Disclaimer',
                    'Mindful AI is a pre-screening tool designed to provide general information and risk assessment for depression, ADHD, and autism spectrum disorder (ASD). The results and analysis provided by this Service are NOT medical diagnoses and should NOT be used as a substitute for professional medical advice, clinical assessment, or treatment by a licensed healthcare provider.\n\nUsers must not rely solely on results from Mindful AI to make medical decisions. If you are experiencing mental health concerns, thoughts of self-harm, or any emergency, please contact a mental health professional, call your local emergency services, or use the National Suicide Prevention Lifeline.',
                    Icons.warning_amber_rounded,
                    isCritical: true,
                  ),
                  _buildSectionCard(
                    '3. User Responsibilities',
                    'You agree to:\n\n• Provide accurate, truthful, and complete information when responding to questionnaires and assessments\n• Use the Service only for lawful purposes and in compliance with these Terms\n• Not transmit harmful, illegal, or offensive content through the Service\n• Maintain the confidentiality of your account credentials\n• Seek professional medical advice for any health concerns rather than relying solely on automated assessments',
                    Icons.person_outline,
                  ),
                  _buildSectionCard(
                    '4. Intellectual Property Rights',
                    'All content, features, and functionality of Mindful AI, including but not limited to the design, layout, algorithms, and materials, are owned by the Company or its licensors. You are granted a limited, non-exclusive, non-transferable license to use the Service for personal, non-commercial purposes. You may not reproduce, distribute, modify, or use any part of the Service for commercial purposes without explicit written consent from the Company.',
                    Icons.copyright_outlined,
                  ),
                  _buildSectionCard(
                    '5. Data and Privacy',
                    'Your use of personal information is governed by our separate Privacy Policy. By using Mindful AI, you consent to the collection, processing, and use of your data as outlined in our Privacy Policy. Data security is a priority, and we implement industry-standard encryption and security measures. However, no method of transmission over the internet is entirely secure, and we cannot guarantee absolute security.',
                    Icons.lock_outline,
                  ),
                  _buildSectionCard(
                    '6. Limitation of Liability',
                    'TO THE MAXIMUM EXTENT PERMITTED BY LAW, Mindful AI AND ITS OFFICERS, DIRECTORS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF OR INABILITY TO USE THE SERVICE, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOST PROFITS, DATA LOSS, OR BUSINESS INTERRUPTION, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.',
                    Icons.gavel_outlined,
                  ),
                  _buildSectionCard(
                    '7. Disclaimer of Warranties',
                    'THE SERVICE IS PROVIDED ON AN "AS-IS" AND "AS-AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. THE COMPANY DISCLAIMS ALL WARRANTIES, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. Mindful AI DOES NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF VIRUSES OR HARMFUL COMPONENTS.',
                    Icons.shield_outlined,
                  ),
                  _buildSectionCard(
                    '8. Modifications to the Service',
                    'The Company reserves the right to modify, suspend, or discontinue the Service at any time without notice. We are not liable to you or any third party for any modifications or discontinuations of the Service. Updates to these Terms will be posted with a new effective date.',
                    Icons.update_outlined,
                  ),
                  _buildSectionCard(
                    '9. Termination',
                    'We may terminate or suspend your account and access to the Service at any time, without cause or notice, for conduct we believe violates these Terms or is harmful to other users. Upon termination, all rights and licenses granted to you will immediately cease.',
                    Icons.do_not_disturb_alt_outlined,
                  ),
                  _buildSectionCard(
                    '10. Governing Law',
                    'These Terms are governed by and construed in accordance with the laws of Egypt, without regard to its conflict of law principles. You agree to submit to the exclusive jurisdiction of the courts located in Alexandria, Egypt.',
                    Icons.public_outlined,
                  ),
                  _buildSectionCard(
                    '11. Contact Information',
                    'If you have questions about these Terms of Service, please contact us at:\n\nMindful AI\nPharos University\nAlexandria, Egypt',
                    Icons.contact_support_outlined,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String content, IconData icon, {bool isCritical = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical 
              ? AppColors.error.withValues(alpha: 0.3) 
              : AppColors.primaryPurple.withValues(alpha: 0.1),
          width: isCritical ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCritical 
                      ? AppColors.error.withValues(alpha: 0.1) 
                      : AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isCritical ? AppColors.error : AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
