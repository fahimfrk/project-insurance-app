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

bool register = false;

class _LoginState extends State<Login>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final TextEditingController user = TextEditingController();
  final TextEditingController pass = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller.dispose();

    user.dispose();
    pass.dispose();

    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  // ============================================================
  // SUPABASE LOGIN
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  // ============================================================
  // SUPABASE REGISTER
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
        const SnackBar(
          content: Text('Password must contain at least 6 characters'),
        ),
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
          const SnackBar(
            content: Text(
              'Registration successful. Check your email for verification.',
            ),
          ),
        );

        setState(() {
          register = false;
          x = 'SIGNIN';
          y = 'SIGNUP';
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  // ============================================================
  // CHANGE LOGIN / REGISTER UI
  // ============================================================

  String x = 'SIGNIN';
  String y = 'SIGNUP';

  void rota() {
    if (x == 'SIGNIN') {
      x = 'SIGNUP';
      y = 'LOGIN';
    } else {
      x = 'SIGNIN';
      y = 'SIGNUP';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.deepPurple, Colors.black]
                    : [Colors.blue, Colors.purpleAccent],
                begin: Alignment(-1 + _controller.value * 2, -1),
                end: Alignment(-1, 1 - _controller.value * 2),
              ),
            ),
            child: SafeArea(
              child: ListView(
                children: [
                  // ==================================================
                  // TITLE
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.only(
                      top: 50,
                      left: 10,
                      right: 10,
                      bottom: 80,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      x,
                      style: GoogleFonts.poppins(
                        fontSize: 50,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // ==================================================
                  // FORM
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        // EMAIL
                        TextField(
                          controller: user,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.white,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                width: 0.3,
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                width: 1,
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // PASSWORD
                        TextField(
                          controller: pass,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.white,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                width: 0.3,
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                width: 1,
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // LOGIN / REGISTER BUTTON
                        // ==================================================
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: TextButton(
                            onPressed: () {
                              if (register) {
                                registerUser();
                              } else {
                                loginUser();
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                8,
                                124,
                                219,
                              ),
                            ),
                            child: Text(
                              register ? 'SIGNUP' : 'SIGNIN',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),

                        // ==================================================
                        // SWITCH LOGIN / REGISTER
                        // ==================================================
                        TextButton(
                          onPressed: () {
                            setState(() {
                              register = !register;

                              if (register) {
                                x = 'SIGNUP';
                              } else {
                                x = 'SIGNIN';
                              }
                            });
                          },
                          child: Text(
                            register
                                ? 'Already have an account?'
                                : "Don't have an account?",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
