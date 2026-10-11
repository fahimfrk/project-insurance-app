import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/admininsuraance.dart';
import 'package:insurance/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool register = false;
  final TextEditingController user = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  // ============================================================
  // SUPABASE LOGIN (Unchanged from your original code)
  // ============================================================
  Future<void> loginUser() async {
    final email = user.text.trim();
    final password = pass.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        user.clear();
        pass.clear();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InsuranceDashboard()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  // ============================================================
  // SUPABASE REGISTER (Unchanged from your original code)
  // ============================================================
  Future<void> registerUser() async {
    final email = user.text.trim();
    final password = pass.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must contain at least 6 characters')),
      );
      return;
    }

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        user.clear();
        pass.clear();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful. You can now login.')),
        );

        setState(() {
          register = false; // Switch back to login view automatically
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  // ============================================================
  // NEW PREMIUM UI BUILDER
  // ============================================================
  @override
  Widget build(BuildContext context) {
    // Brand colors matching your dashboard screenshots
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161C19) : const Color(0xFFF4F7F5);
    final accentGreen = const Color(0xFF4ADE80); 
    final textColor = isDark ? Colors.white : Colors.black87;
    final fieldBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER / LOGO AREA
                  Row(
                    children: [
                      Icon(Icons.shield, color: accentGreen, size: 40),
                      const SizedBox(width: 10),
                      Text(
                        'Insurance',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    register ? 'Create Account' : 'Welcome Back',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    register 
                        ? 'Sign up to manage your policies.' 
                        : 'Sign in to access your dashboard.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // EMAIL FIELD
                  TextField(
                    controller: user,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      filled: true,
                      fillColor: fieldBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accentGreen, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD FIELD
                  TextField(
                    controller: pass,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      filled: true,
                      fillColor: fieldBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accentGreen, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // LOGIN / REGISTER BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (register) {
                          registerUser();
                        } else {
                          loginUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.black, // Dark text on light green
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        register ? 'Sign Up' : 'Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SWITCH LOGIN / REGISTER
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          register = !register;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: accentGreen,
                        splashFactory: NoSplash.splashFactory, // cleaner look
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: register
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                          style: TextStyle(color: Colors.grey.shade500),
                          children: [
                            TextSpan(
                              text: register ? 'Sign In' : 'Sign Up',
                              style: TextStyle(
                                color: accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}