import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/login_page.dart';
import 'package:mindful/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabase = Supabase.instance.client;

  // Variables
  String firstname = "";
  String lastname = "";
  String phoneNumber = "";
  String email = "";
  String password = "";
  String confirmPassword = "";
  String errorMessage = '';
  bool showError = false;

  // Controllers
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

  Future<void> registerUser() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 1️⃣ Create user in Supabase Auth
      final AuthResponse response = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;

      if (user == null) {
        Navigator.pop(context);
        throw Exception("User creation failed. No user returned.");
      }

      // 2️⃣ Insert extra user data inside users table
      await supabase.from('users').insert({
        'id': user.id,
        'first_name': firstname.trim(),
        'last_name': lastname.trim(),
        'phone_number': phoneNumber.trim(),
        'email': email.trim(),
        'full_name': '${firstname.trim()} ${lastname.trim()}',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() {
        errorMessage = e.message;
        showError = true;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() {
        errorMessage = "Error: $e";
        showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 70),

              Text(
                "Let's Get Started!",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Create an account on Mindfull \n           to get all features',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: firstnameController,
                hint: "Firstname",
                icon: Icons.person_outline_outlined,
                onChanged: (value) {
                  setState(() => firstname = value);
                  if (showError) setState(() => showError = false);
                },
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: lastnameController,
                hint: "Lastname",
                icon: Icons.person_outline_outlined,
                onChanged: (value) {
                  setState(() => lastname = value);
                  if (showError) setState(() => showError = false);
                },
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: phoneNumberController,
                hint: "Phone Number",
                icon: Icons.phone_outlined,
                onChanged: (value) {
                  setState(() => phoneNumber = value);
                  if (showError) setState(() => showError = false);
                },
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: emailController,
                hint: "Email",
                icon: Icons.email_outlined,
                onChanged: (value) {
                  setState(() => email = value);
                  if (showError) setState(() => showError = false);
                },
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                obscureText: true,
                onChanged: (value) {
                  setState(() => password = value);
                  if (showError) setState(() => showError = false);
                },
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: confirmPasswordController,
                hint: "Confirm Password",
                icon: Icons.lock_outline,
                obscureText: true,
                onChanged: (value) {
                  setState(() => confirmPassword = value);
                  if (showError) setState(() => showError = false);
                },
              ),

              const SizedBox(height: 20),

              if (showError)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: GoogleFonts.inter(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () async {
                  // VALIDATION
                  if (firstname.isEmpty) {
                    setState(() {
                      errorMessage = 'Please enter your first name';
                      showError = true;
                    });
                    return;
                  }

                  if (lastname.isEmpty) {
                    setState(() {
                      errorMessage = 'Please enter your last name';
                      showError = true;
                    });
                    return;
                  }

                  if (phoneNumber.isEmpty) {
                    setState(() {
                      errorMessage = 'Please enter your phone number';
                      showError = true;
                    });
                    return;
                  }

                  if (email.isEmpty) {
                    setState(() {
                      errorMessage = 'Please enter your email';
                      showError = true;
                    });
                    return;
                  }

                  if (password.isEmpty || password.length < 6) {
                    setState(() {
                      errorMessage = 'Password must be at least 6 characters';
                      showError = true;
                    });
                    return;
                  }

                  if (confirmPassword.isEmpty || password != confirmPassword) {
                    setState(() {
                      errorMessage = 'Passwords do not match';
                      showError = true;
                    });
                    return;
                  }

                  await registerUser();
                },

                child: Container(
                  width: 199,
                  height: 53,
                  decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(color: Colors.grey, blurRadius: 10, spreadRadius: 2)
                    ],
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'CREATE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account ?",
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
