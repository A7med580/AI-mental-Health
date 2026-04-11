import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF1F4788),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 46), // 30 bottom + 16 normal = 46 padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('MindCare AI Privacy Policy'),
            _buildDate('Effective Date: April 2026'),
            const SizedBox(height: 24),
            _buildSection(
              'Section 1 - Introduction',
              'MindCare AI is committed to protecting your privacy and ensuring transparency in how we collect, use, and protect your personal data. This Privacy Policy explains our data practices. By using MindCare AI, you acknowledge that you have read and understood this Privacy Policy.',
            ),
            _buildSection(
              'Section 2.1 - Personal Information',
              'We collect the following personal information when you create an account:\n• Name\n• Email address\n• Age and demographic information\n• Phone number (optional)',
            ),
            _buildSection(
              'Section 2.2 - Assessment Data',
              'When you use MindCare AI\'s assessment tools, we collect responses to questionnaires, voice/audio data (if provided), and facial images (if camera access is enabled). This data is used exclusively for generating pre-screening results and improving the accuracy of our models. All assessment data is treated as sensitive health information.',
            ),
            _buildSection(
              'Section 2.3 - Device and Usage Information',
              'We automatically collect device type, operating system, app version, IP address, and usage statistics (pages visited, features used, session duration) to improve the Service and diagnose technical issues.',
            ),
            _buildSection(
              'Section 3 - How We Use Your Information',
              'We use collected data for:\n• Generating personalized mental health pre-screening results\n• Improving our AI models and algorithms through research\n• Sending you relevant notifications about your assessments or new features\n• Providing customer support\n• Complying with legal obligations',
            ),
            _buildSection(
              'Section 4 - Data Security',
              'We implement industry-standard encryption (SSL/TLS) for data in transit and use secure database systems for data at rest. Sensitive information such as health data is encrypted using AES-256 encryption. However, no security system is impenetrable, and we cannot guarantee absolute protection against all potential breaches. We conduct regular security audits and maintain data protection protocols compliant with international standards.',
            ),
            _buildSection(
              'Section 5 - Data Retention',
              'We retain personal information only as long as necessary to fulfill the purposes outlined in this Policy or as required by law. Assessment data may be retained for model improvement and research purposes, subject to anonymization. You may request deletion of your data by contacting us, subject to legal retention requirements.',
            ),
            _buildSection(
              'Section 6 - Sharing Your Information',
              'We do not sell or rent your personal information to third parties. We may share data with: (1) service providers who assist us in operating the platform (with strict confidentiality agreements), (2) research institutions for scientific advancement (with anonymized data only), and (3) legal authorities if required by law or to protect our rights.',
            ),
            _buildSection(
              'Section 7 - Your Rights',
              'Depending on your location, you may have the following rights:\n• Right to access your personal data\n• Right to correct or update inaccurate information\n• Right to request deletion of your data\n• Right to data portability\n• Right to withdraw consent for data processing',
            ),
            _buildSection(
              'Section 8 - Third-Party Services',
              'MindCare AI may use third-party services (e.g., cloud hosting providers) that have their own privacy policies. We are not responsible for third-party privacy practices, and we recommend reviewing their policies independently.',
            ),
            _buildSection(
              'Section 9 - Policy Updates',
              'We may update this Privacy Policy periodically. We will notify you of material changes by posting the updated policy with a new effective date. Your continued use of the Service after updates constitutes acceptance of the revised policy.',
            ),
            _buildSection(
              'Section 10 - Contact Us',
              'If you have questions or concerns about our privacy practices, please contact us at: MindCare AI, Pharos University, Alexandria, Egypt.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F4788),
      ),
    );
  }

  Widget _buildDate(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5C99),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
