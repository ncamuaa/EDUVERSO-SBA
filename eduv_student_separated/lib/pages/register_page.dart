import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../utils/app_size.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool hidePassword = true;
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text,
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Register failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context); // ✅ FIXED

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
                width: w, // ✅ IMPORTANT (same as login)
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
                      'Register',
                      style: TextStyle(
                        fontSize: w * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: w * 0.06),

                    _inputField('Full Name', false, nameController, w),
                    SizedBox(height: w * 0.04),

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
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Register',
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
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Already have an account? Login',
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