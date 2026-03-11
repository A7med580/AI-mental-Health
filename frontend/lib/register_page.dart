import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/login_page.dart';
import 'package:mindful/widgets/page_transitions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabase = Supabase.instance.client;

  String firstname = '';
  String lastname = '';
  String phoneNumber = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String errorMessage = '';
  bool showError = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Registration logic (UNCHANGED) ─────────────────────────────────

  Future<void> registerUser() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final AuthResponse response = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;

      if (user == null) {
        Navigator.pop(context);
        throw Exception('User creation failed. No user returned.');
      }

      await supabase.from('users').insert({
        'id': user.id,
        'first_name': firstname.trim(),
        'last_name': lastname.trim(),
        'phone_number': phoneNumber.trim(),
        'email': email.trim(),
        'full_name': '${firstname.trim()} ${lastname.trim()}',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          AppPageRoute(page: const LoginPage()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() { errorMessage = e.message; showError = true; });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() { errorMessage = 'Error: $e'; showError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 32),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "Let's Get Started!",
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Create your MindCare AI account',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 28),

              // Name row
              Row(
                children: [
                  Expanded(
                    child: _buildField('First Name', firstnameController, Icons.person_outline, (v) {
                      firstname = v;
                      if (showError) setState(() => showError = false);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField('Last Name', lastnameController, Icons.person_outline, (v) {
                      lastname = v;
                      if (showError) setState(() => showError = false);
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildField('Phone Number', phoneNumberController, Icons.phone_outlined, (v) {
                phoneNumber = v;
                if (showError) setState(() => showError = false);
              }),

              const SizedBox(height: 16),

              _buildField('Email', emailController, Icons.email_outlined, (v) {
                email = v;
                if (showError) setState(() => showError = false);
              }, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autocorrect: false),

              const SizedBox(height: 16),

              _buildField('Password', passwordController, Icons.lock_outline, (v) {
                password = v;
                if (showError) setState(() => showError = false);
              }, obscure: _obscurePassword, suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )),

              const SizedBox(height: 16),

              _buildField('Confirm Password', confirmPasswordController, Icons.lock_outline, (v) {
                confirmPassword = v;
                if (showError) setState(() => showError = false);
              }, obscure: _obscureConfirm, suffix: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 20),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              )),

              // Error
              if (showError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(errorMessage, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _handleRegister,
                      child: Center(
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign in link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, AppPageRoute(page: const LoginPage())),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (firstname.isEmpty) {
      setState(() { errorMessage = 'Please enter your first name'; showError = true; });
      return;
    }
    if (lastname.isEmpty) {
      setState(() { errorMessage = 'Please enter your last name'; showError = true; });
      return;
    }
    if (phoneNumber.isEmpty) {
      setState(() { errorMessage = 'Please enter your phone number'; showError = true; });
      return;
    }
    if (email.isEmpty) {
      setState(() { errorMessage = 'Please enter your email'; showError = true; });
      return;
    }
    if (password.isEmpty || password.length < 6) {
      setState(() { errorMessage = 'Password must be at least 6 characters'; showError = true; });
      return;
    }
    if (confirmPassword.isEmpty || password != confirmPassword) {
      setState(() { errorMessage = 'Passwords do not match'; showError = true; });
      return;
    }
    await registerUser();
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, ValueChanged<String> onChanged, {bool obscure = false, Widget? suffix, TextInputType? keyboardType, TextInputAction? textInputAction, bool autocorrect = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autocorrect: autocorrect,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your ${label.toLowerCase()}',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
