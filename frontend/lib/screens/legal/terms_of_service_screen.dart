import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: const Color(0xFF1F4788),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 46), // 30 bottom + 16 normal = 46 padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('MindCare AI Terms of Service'),
            _buildDate('Effective Date: April 2026'),
            const SizedBox(height: 24),
            _buildSection(
              'Section 1 - Introduction',
              'Welcome to MindCare AI, an AI-powered mental health pre-screening platform ("Service"). These Terms of Service ("Terms") constitute a legally binding agreement between you ("User" or "you") and MindCare AI ("Company," "we," or "us"). By accessing, downloading, or using the MindCare AI application or website, you agree to be bound by these Terms. If you do not agree to any part of these Terms, you must not use the Service.',
            ),
            _buildSection(
              'Section 2 - Medical Disclaimer',
              'MindCare AI is a pre-screening tool designed to provide general information and risk assessment for depression, ADHD, and autism spectrum disorder (ASD). The results and analysis provided by this Service are NOT medical diagnoses and should NOT be used as a substitute for professional medical advice, clinical assessment, or treatment by a licensed healthcare provider. Users must not rely solely on results from MindCare AI to make medical decisions. If you are experiencing mental health concerns, thoughts of self-harm, or any emergency, please contact a mental health professional, call your local emergency services, or use the National Suicide Prevention Lifeline (US: 988).',
            ),
            _buildSection(
              'Section 3 - User Responsibilities',
              'You agree to:\n• Provide accurate, truthful, and complete information when responding to questionnaires and assessments\n• Use the Service only for lawful purposes and in compliance with these Terms\n• Not transmit harmful, illegal, or offensive content through the Service\n• Maintain the confidentiality of your account credentials\n• Seek professional medical advice for any health concerns rather than relying solely on automated assessments',
            ),
            _buildSection(
              'Section 4 - Intellectual Property Rights',
              'All content, features, and functionality of MindCare AI, including but not limited to the design, layout, algorithms, and materials, are owned by the Company or its licensors. You are granted a limited, non-exclusive, non-transferable license to use the Service for personal, non-commercial purposes. You may not reproduce, distribute, modify, or use any part of the Service for commercial purposes without explicit written consent from the Company.',
            ),
            _buildSection(
              'Section 5 - Data and Privacy',
              'Your use of personal information is governed by our separate Privacy Policy. By using MindCare AI, you consent to the collection, processing, and use of your data as outlined in our Privacy Policy. Data security is a priority, and we implement industry-standard encryption and security measures. However, no method of transmission over the internet is entirely secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              'Section 6 - Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, MindCare AI AND ITS OFFICERS, DIRECTORS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF OR INABILITY TO USE THE SERVICE, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOST PROFITS, DATA LOSS, OR BUSINESS INTERRUPTION, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. Some jurisdictions may not allow limitations on liability, so this limitation may not apply to you.',
            ),
            _buildSection(
              'Section 7 - Disclaimer of Warranties',
              'THE SERVICE IS PROVIDED ON AN "AS-IS" AND "AS-AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. THE COMPANY DISCLAIMS ALL WARRANTIES, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. MindCare AI DOES NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF VIRUSES OR HARMFUL COMPONENTS.',
            ),
            _buildSection(
              'Section 8 - Modifications to the Service',
              'The Company reserves the right to modify, suspend, or discontinue the Service at any time without notice. We are not liable to you or any third party for any modifications or discontinuations of the Service. Updates to these Terms will be posted with a new effective date.',
            ),
            _buildSection(
              'Section 9 - Termination',
              'We may terminate or suspend your account and access to the Service at any time, without cause or notice, for conduct we believe violates these Terms or is harmful to other users. Upon termination, all rights and licenses granted to you will immediately cease.',
            ),
            _buildSection(
              'Section 10 - Governing Law',
              'These Terms are governed by and construed in accordance with the laws of Egypt, without regard to its conflict of law principles. You agree to submit to the exclusive jurisdiction of the courts located in Alexandria, Egypt.',
            ),
            _buildSection(
              'Section 11 - Contact Information',
              'If you have questions about these Terms of Service, please contact us at: MindCare AI, Pharos University, Alexandria, Egypt.',
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
