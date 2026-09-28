import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurance/admininsuraance.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

Future<void> deeplink() async {}

class _LoginState extends State<Login>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  String x = 'LOGIN';
  String y = 'SIGNIN';
  void rota() {
    if (x == 'LOGIN') {
      x = 'SIGNIN';
      y = 'LOGIN';
    } else {
      y = 'SIGNIN';
      x = 'LOGIN';
    }
  }

  final TextEditingController user = TextEditingController();
  final TextEditingController pass = TextEditingController();
  void admin_auth() {
    setState(() {
      String name = user.text;
      String auth = pass.text;
      if (name == 'admin' && auth == '1234') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InsuranceDashboard()),
        );
      } else if (name == 'sales' && auth == 'sales1') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InsuranceDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid username or password"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
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

                  // 👇 rest of your UI unchanged
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        TextField(
                          controller: user,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                width: 0.3,
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        TextField(
                          controller: pass,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                width: 0.3,
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: TextButton(
                            onPressed: admin_auth,
                            child: Text(y),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                8,
                                124,
                                219,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: rota,
                          child: Text('Dont you have a account?'),
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
