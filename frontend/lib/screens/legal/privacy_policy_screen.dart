import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
                    child: const Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mindful AI Privacy',
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
                    'Mindful AI is committed to protecting your privacy and ensuring transparency in how we collect, use, and protect your personal data. This Privacy Policy explains our data practices. By using Mindful AI, you acknowledge that you have read and understood this Privacy Policy.',
                    Icons.info_outline,
                  ),
                  _buildSectionCard(
                    '2.1 Personal Information',
                    'We collect the following personal information when you create an account:\n\n• Name\n• Email address\n• Age and demographic information\n• Phone number (optional)',
                    Icons.person_outline,
                  ),
                  _buildSectionCard(
                    '2.2 Assessment Data',
                    'When you use Mindful AI\'s assessment tools, we collect responses to questionnaires, voice/audio data (if provided), and facial images (if camera access is enabled). This data is used exclusively for generating pre-screening results and improving the accuracy of our models. All assessment data is treated as sensitive health information.',
                    Icons.health_and_safety_outlined,
                  ),
                  _buildSectionCard(
                    '2.3 Device & Usage Info',
                    'We automatically collect device type, operating system, app version, IP address, and usage statistics (pages visited, features used, session duration) to improve the Service and diagnose technical issues.',
                    Icons.phone_iphone_outlined,
                  ),
                  _buildSectionCard(
                    '3. How We Use Information',
                    'We use collected data for:\n\n• Generating personalized mental health pre-screening results\n• Improving our AI models and algorithms through research\n• Sending you relevant notifications about your assessments or new features\n• Providing customer support\n• Complying with legal obligations',
                    Icons.data_usage_outlined,
                  ),
                  _buildSectionCard(
                    '4. Data Security',
                    'We implement industry-standard encryption (SSL/TLS) for data in transit and use secure database systems for data at rest. Sensitive information such as health data is encrypted using AES-256 encryption. However, no security system is impenetrable, and we cannot guarantee absolute protection against all potential breaches. We conduct regular security audits and maintain data protection protocols compliant with international standards.',
                    Icons.security_outlined,
                  ),
                  _buildSectionCard(
                    '5. Data Retention',
                    'We retain personal information only as long as necessary to fulfill the purposes outlined in this Policy or as required by law. Assessment data may be retained for model improvement and research purposes, subject to anonymization. You may request deletion of your data by contacting us, subject to legal retention requirements.',
                    Icons.save_outlined,
                  ),
                  _buildSectionCard(
                    '6. Sharing Your Information',
                    'We do not sell or rent your personal information to third parties. We may share data with: (1) service providers who assist us in operating the platform (with strict confidentiality agreements), (2) research institutions for scientific advancement (with anonymized data only), and (3) legal authorities if required by law or to protect our rights.',
                    Icons.share_outlined,
                  ),
                  _buildSectionCard(
                    '7. Your Rights',
                    'Depending on your location, you may have the following rights:\n\n• Right to access your personal data\n• Right to correct or update inaccurate information\n• Right to request deletion of your data\n• Right to data portability\n• Right to withdraw consent for data processing',
                    Icons.gavel_outlined,
                  ),
                  _buildSectionCard(
                    '8. Third-Party Services',
                    'Mindful AI may use third-party services (e.g., cloud hosting providers) that have their own privacy policies. We are not responsible for third-party privacy practices, and we recommend reviewing their policies independently.',
                    Icons.cloud_outlined,
                  ),
                  _buildSectionCard(
                    '9. Policy Updates',
                    'We may update this Privacy Policy periodically. We will notify you of material changes by posting the updated policy with a new effective date. Your continued use of the Service after updates constitutes acceptance of the revised policy.',
                    Icons.update_outlined,
                  ),
                  _buildSectionCard(
                    '10. Contact Us',
                    'If you have questions or concerns about our privacy practices, please contact us at:\n\nMindful AI\nPharos University\nAlexandria, Egypt',
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

  Widget _buildSectionCard(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.1)),
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
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
