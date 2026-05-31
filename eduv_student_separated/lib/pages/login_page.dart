import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_size.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool hidePassword = true;
  bool isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // AuthService.login() handles:
      // - HTTP call
      // - saving token to SharedPreferences
      // - setting _cachedToken in memory
      // - fetching and caching the profile
      // - preserving last_module_* keys
      await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E22D8), Color(0xFF0B0F8C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.06,
                vertical: 20,
              ),
              child: Container(
                width: w,
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.06,
                  vertical: w * 0.08,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2DB0).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Image.asset('assets/1.png', width: w * 0.22),
                    SizedBox(height: w * 0.05),

                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: w * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: w * 0.06),

                    _inputField('Email', false, emailController, w),

                    SizedBox(height: w * 0.04),

                    _inputField(
                      'Password',
                      hidePassword,
                      passwordController,
                      w,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => hidePassword = !hidePassword),
                        child: Icon(
                          hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                          size: w * 0.045,
                        ),
                      ),
                    ),

                    SizedBox(height: w * 0.06),

                    SizedBox(
                      width: double.infinity,
                      height: w * 0.12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8F61FF), Color(0xFF6E5BFF)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: w * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: w * 0.04),

                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: Text(
                        "Don't have an account? Register",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: w * 0.035,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    bool obscure,
    TextEditingController controller,
    double w, {
    Widget? suffix,
  }) {
    return Container(
      height: w * 0.12,
      decoration: BoxDecoration(
        color: const Color(0xFF6667C7).withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.038,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: w * 0.038,
                ),
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }
}