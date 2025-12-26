import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/register_page.dart';
import 'package:mindful/widgets/custom_text_field.dart';
import 'package:mindful/widgets/logo_text.dart';
import 'chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final supabase = Supabase.instance.client;
  String email = '';
  String password = '';
  String errorMessage = '';
  bool showError = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 180),

                  Center(child: LogoText()),

                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Log in to existing MINDFUL account',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// EMAIL
                  CustomTextField(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.email_outlined,
                    onChanged: (value) {
                      email = value;
                      if (showError) {
                        setState(() {
                          showError = false;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  /// PASSWORD
                  CustomTextField(
                    controller: passwordController,
                    hint: "Password",
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    onChanged: (value) {
                      password = value;
                      if (showError) {
                        setState(() {
                          showError = false;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // Error Message Display
                  if (showError)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
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

                  const SizedBox(height: 15),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        // Handle password reset
                        if (email.isEmpty) {
                          setState(() {
                            errorMessage = 'Please enter your email first';
                            showError = true;
                          });
                          return;
                        }

                        try {
                          await supabase.auth.resetPasswordForEmail(
                            email.trim(),
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email sent! Check your inbox'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            _showErrorSnackBar('Failed to send reset email');
                          }
                        }
                      },
                      child: Text(
                        'Forgot Password ?',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  /// LOGIN BUTTON
                  GestureDetector(
                    onTap: () async {
                      // Validate empty fields
                      if (email.isEmpty && password.isEmpty) {
                        setState(() {
                          errorMessage = 'Please enter your email and password';
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

                      if (password.isEmpty) {
                        setState(() {
                          errorMessage = 'Please enter your password';
                          showError = true;
                        });
                        return;
                      }

                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        final response = await supabase.auth.signInWithPassword(
                          email: email.trim(),
                          password: password.trim(),
                        );

                        // Close loading dialog
                        if (mounted) Navigator.pop(context);

                        if (response.user != null) {
                          // Login successful
                          if (mounted) {
                            Navigator.pushNamed(context, '/chat');
                          }
                        }
                      } on AuthException catch (e) {
                        // Close loading dialog
                        if (mounted) Navigator.pop(context);

                        String message = '';

                        print('Supabase Auth Error: ${e.message}'); // Debug print
                        print('Status Code: ${e.statusCode}'); // Debug print

                        // Handle different Supabase auth errors
                        if (e.message.toLowerCase().contains('invalid login credentials') ||
                            e.message.toLowerCase().contains('invalid email or password')) {
                          message = 'Invalid email or password';
                        } else if (e.message.toLowerCase().contains('email not confirmed')) {
                          message = 'Please verify your email before logging in';
                        } else if (e.message.toLowerCase().contains('user not found')) {
                          message = 'No account found with this email';
                        } else if (e.statusCode == 429) {
                          message = 'Too many attempts. Please try again later';
                        } else {
                          message = e.message;
                        }

                        setState(() {
                          errorMessage = message;
                          showError = true;
                        });
                      } catch (e) {
                        // Close loading dialog
                        if (mounted) Navigator.pop(context);

                        print('General Error: $e'); // Debug print

                        setState(() {
                          errorMessage = 'An unexpected error occurred. Please try again';
                          showError = true;
                        });
                      }
                    },
                    child: Container(
                      width: 199,
                      height: 53,
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'LOG IN',
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

                  Text(
                    'Or sign in with',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // TODO: Implement Facebook OAuth with Supabase
                          // await supabase.auth.signInWithOAuth(Provider.facebook);
                          _showErrorSnackBar('Facebook login coming soon!');
                        },
                        child: Icon(
                          Ionicons.logo_facebook,
                          color: Colors.blue.shade600,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: () async {
                          // TODO: Implement Google OAuth with Supabase
                          // await supabase.auth.signInWithOAuth(Provider.google);
                          _showErrorSnackBar('Google login coming soon!');
                        },
                        child: Icon(
                          Ionicons.logo_google,
                          color: Colors.red.shade400,
                          size: 30,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// SIGN UP NAVIGATION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account ?",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
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
        ),

        /// SVG DECORATIONS
        Positioned(
          top: 0,
          left: 60,
          child: SvgPicture.asset("assets/images/box2.svg"),
        ),
        Positioned(
          right: 140,
          child: SvgPicture.asset("assets/images/box1.svg"),
        ),
      ],
    );
  }
}