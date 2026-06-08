import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
  final TextEditingController sectionController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedCourse;

  static const List<String> _departments = [
    'College of Engineering',
    'College of Arts and Sciences',
    'College of Business',
    'College of Education',
    'College of Nursing',
    'College of Information Technology',
  ];

  static const List<String> _years = [
    '1st Year', '2nd Year', '3rd Year', '4th Year',
  ];

  static const Map<String, List<String>> _coursesByDepartment = {
    'College of Engineering': [
      'BS Civil Engineering', 'BS Electrical Engineering',
      'BS Mechanical Engineering', 'BS Computer Engineering',
    ],
    'College of Arts and Sciences': [
      'BS Biology', 'BS Psychology', 'BA Communication', 'BS Mathematics',
    ],
    'College of Business': [
      'BS Accountancy', 'BS Business Administration', 'BS Marketing', 'BS Finance',
    ],
    'College of Education': [
      'Bachelor of Elementary Education',
      'Bachelor of Secondary Education',
      'BS Early Childhood Education',
    ],
    'College of Nursing': ['BS Nursing'],
    'College of Information Technology': [
      'BS Information Technology', 'BS Computer Science', 'BS Information Systems',
    ],
  };

  List<String> get _availableCourses =>
      _selectedDepartment != null
          ? (_coursesByDepartment[_selectedDepartment!] ?? [])
          : [];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    sectionController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        _selectedDepartment == null ||
        _selectedYear == null ||
        _selectedCourse == null ||
        sectionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.register(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        department: _selectedDepartment!,
        course: _selectedCourse!,
        year: _selectedYear!,
        section: sectionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully! Welcome to EduVerso!')),
      );

      // ✅ Fixed: navigate to dashboard instead of onboarding
      // The OnboardingOverlay in dashboard_page.dart handles first-time users automatically
      Navigator.pushReplacementNamed(context, '/dashboard');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
              padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: 20),
              child: Container(
                width: w,
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.06, vertical: w * 0.08),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2DB0).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Image.asset('assets/1.png', width: w * 0.22),
                    SizedBox(height: w * 0.05),
                    Text('Register',
                        style: TextStyle(
                            fontSize: w * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: w * 0.06),
                    _inputField('Full Name', false, nameController, w),
                    SizedBox(height: w * 0.04),
                    _inputField('Email', false, emailController, w),
                    SizedBox(height: w * 0.04),
                    _inputField('Password', hidePassword, passwordController, w,
                        suffix: GestureDetector(
                          onTap: () => setState(() => hidePassword = !hidePassword),
                          child: Icon(
                              hidePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                              size: w * 0.045),
                        )),
                    SizedBox(height: w * 0.04),
                    _dropdownField(
                        hint: 'Department',
                        value: _selectedDepartment,
                        items: _departments,
                        w: w,
                        onChanged: (val) => setState(() {
                              _selectedDepartment = val;
                              _selectedCourse = null;
                            })),
                    SizedBox(height: w * 0.04),
                    _dropdownField(
                        hint: 'Course',
                        value: _selectedCourse,
                        items: _availableCourses,
                        w: w,
                        enabled: _selectedDepartment != null,
                        onChanged: (val) => setState(() => _selectedCourse = val)),
                    SizedBox(height: w * 0.04),
                    _dropdownField(
                        hint: 'Year',
                        value: _selectedYear,
                        items: _years,
                        w: w,
                        onChanged: (val) => setState(() => _selectedYear = val)),
                    SizedBox(height: w * 0.04),
                    _inputField('Section (e.g. A, B, C)', false, sectionController, w),
                    SizedBox(height: w * 0.06),
                    SizedBox(
                      width: double.infinity,
                      height: w * 0.12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                              colors: [Color(0xFF8F61FF), Color(0xFF6E5BFF)]),
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Register',
                                  style: TextStyle(
                                      fontSize: w * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ),
                    SizedBox(height: w * 0.04),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Already have an account? Login',
                          style: TextStyle(
                              color: Colors.white70, fontSize: w * 0.035)),
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

  Widget _inputField(String hint, bool obscure,
      TextEditingController controller, double w,
      {Widget? suffix}) {
    return Container(
      height: w * 0.12,
      decoration: BoxDecoration(
          color: const Color(0xFF6667C7).withOpacity(0.75),
          borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      alignment: Alignment.center,
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: Colors.white, fontSize: w * 0.038),
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    TextStyle(color: Colors.white70, fontSize: w * 0.038)),
          ),
        ),
        if (suffix != null) suffix,
      ]),
    );
  }

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required double w,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Container(
      height: w * 0.12,
      decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF6667C7).withOpacity(0.75)
              : const Color(0xFF6667C7).withOpacity(0.35),
          borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(
              enabled ? hint : '$hint (select department first)',
              style: TextStyle(color: Colors.white70, fontSize: w * 0.038)),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white70, size: w * 0.05),
          dropdownColor: const Color(0xFF2C2DB0),
          style: TextStyle(color: Colors.white, fontSize: w * 0.038),
          onChanged: enabled ? onChanged : null,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }
}