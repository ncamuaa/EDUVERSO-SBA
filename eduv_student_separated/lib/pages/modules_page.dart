import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/lesson_page.dart';
import '../services/auth_service.dart';
import '../services/lesson_service.dart';
import '../services/modules_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});
  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<Module> _allModules = [];
  String? _studentCourse;

  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedCourse;

  static const Map<String, List<String>> _departmentCourses = {
    'College of Engineering': [
      'BS Civil Engineering',
      'BS Electrical Engineering',
      'BS Mechanical Engineering',
      'BS Computer Engineering',
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

  static const Map<String, String> _courseCodes = {
    'BS Civil Engineering': 'CE',
    'BS Electrical Engineering': 'IE',
    'BS Mechanical Engineering': 'ME',
    'BS Computer Engineering': 'CPE',
    'BS Biology': 'BIO',
    'BS Psychology': 'PSY',
    'BA Communication': 'COM',
    'BS Mathematics': 'MATH',
    'BS Accountancy': 'ACC',
    'BS Business Administration': 'BBA',
    'BS Marketing': 'MKT',
    'BS Finance': 'FIN',
    'Bachelor of Elementary Education': 'BEED',
    'Bachelor of Secondary Education': 'BSED',
    'BS Early Childhood Education': 'ECE',
    'BS Nursing': 'BSN',
    'BS Information Technology': 'IT',
    'BS Computer Science': 'CS',
    'BS Information Systems': 'IS',
  };

  static const List<String> _years = [
    '1st Year', '2nd Year', '3rd Year', '4th Year',
  ];

  List<String> get _availableCourses =>
      _selectedDepartment != null
          ? (_departmentCourses[_selectedDepartment!] ?? [])
          : [];

bool get _canSearch =>
    _selectedDepartment != null && _selectedCourse != null;

  @override
  void initState() {
    super.initState();
    _loadStudentCourse();
  }

  Future<void> _loadStudentCourse() async {
    try {
      final profile = await AuthService.getProfile();
      if (mounted) {
        final fullCourse = profile['course'] as String?;
        setState(() => _studentCourse = fullCourse != null
            ? (_courseCodes[fullCourse] ?? fullCourse)
            : null);
      }
    } catch (_) {}
  }

  Future<void> _fetchModules() async {
    if (!_canSearch) return;
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final courseCode = _selectedCourse != null
          ? (_courseCodes[_selectedCourse!] ?? _selectedCourse!)
          : null;
      final result = await ModulesService.getModules(
  grade: _selectedYear,   // already null if not selected, so no change needed
  course: courseCode,
);
      if (!mounted) return;
      setState(() { _allModules = result.modules; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _reset() {
    setState(() {
      _selectedDepartment = null;
      _selectedYear = null;
      _selectedCourse = null;
      _allModules = [];
      _searched = false;
      _error = null;
    });
  }

  Map<String, List<Module>> get _grouped {
    final map = <String, List<Module>>{};
    for (final m in _allModules) { map.putIfAbsent(m.subject, () => []).add(m); }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);
    return StudentPageBase(
      title: "Available Modules",
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FilterPanel(
          selectedDepartment: _selectedDepartment,
          selectedYear: _selectedYear,
          selectedCourse: _selectedCourse,
          availableCourses: _availableCourses,
          years: _years,
          departments: _departmentCourses.keys.toList(),
          canSearch: _canSearch,
          searched: _searched,
          onDepartmentChanged: (v) => setState(() {
            _selectedDepartment = v;
            _selectedCourse = null;
          }),
          onYearChanged: (v) => setState(() => _selectedYear = v),
          onCourseChanged: (v) => setState(() => _selectedCourse = v),
          onSearch: _fetchModules,
          onReset: _reset,
          w: w,
        ),
        Expanded(child: !_searched
          ? _PromptView(w: w)
          : _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA56BFF)))
            : _error != null
              ? _ErrorView(message: _error!, onRetry: _fetchModules, w: w)
              : _allModules.isEmpty
                ? _EmptyView(onClear: _reset, w: w)
                : _ModuleList(grouped: _grouped, studentCourse: _studentCourse, w: w)),
      ]),
    );
  }
}

// ─── Filter Panel ────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.selectedDepartment, required this.selectedYear,
    required this.selectedCourse, required this.availableCourses,
    required this.years, required this.departments,
    required this.canSearch, required this.searched,
    required this.onDepartmentChanged, required this.onYearChanged,
    required this.onCourseChanged, required this.onSearch,
    required this.onReset, required this.w,
  });

  final String? selectedDepartment, selectedYear, selectedCourse;
  final List<String> availableCourses, years, departments;
  final bool canSearch, searched;
  final ValueChanged<String?> onDepartmentChanged, onYearChanged, onCourseChanged;
  final VoidCallback onSearch, onReset;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.045, w * 0.03, w * 0.045, w * 0.02),
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Find Modules", style: TextStyle(
          fontSize: w * 0.04, fontWeight: FontWeight.w700,
          color: Colors.white, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.035),

        _label("Department", w),
        SizedBox(height: w * 0.015),
        _dropdown(
          hint: "Select Department",
          value: selectedDepartment,
          items: departments,
          onChanged: onDepartmentChanged,
          w: w,
        ),
        SizedBox(height: w * 0.03),

        _label("Year Level (optional)", w),
        SizedBox(height: w * 0.015),
        _dropdown(
          hint: "Select Year Level",
          value: selectedYear,
          items: years,
          onChanged: onYearChanged,
          w: w,
        ),
        SizedBox(height: w * 0.03),

        _label("Course", w),
        SizedBox(height: w * 0.015),
        _dropdown(
          hint: selectedDepartment == null ? "Select department first" : "Select Course",
          value: selectedCourse,
          items: availableCourses,
          onChanged: selectedDepartment != null ? onCourseChanged : null,
          w: w,
          enabled: selectedDepartment != null,
        ),
        SizedBox(height: w * 0.045),

        Row(children: [
          if (searched) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFA56BFF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: w * 0.035),
                ),
                child: Text("Reset", style: TextStyle(
                  color: const Color(0xFFA56BFF), fontSize: w * 0.038,
                  fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
              ),
            ),
            SizedBox(width: w * 0.03),
          ],
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: canSearch
                    ? const LinearGradient(colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)])
                    : const LinearGradient(colors: [Color(0xFF555555), Color(0xFF444444)]),
              ),
              child: ElevatedButton(
                onPressed: canSearch ? onSearch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: w * 0.035),
                ),
                child: Text("Show Modules", style: TextStyle(
                  fontSize: w * 0.038, fontWeight: FontWeight.w700,
                  color: canSearch ? Colors.white : Colors.white38,
                  decoration: TextDecoration.none)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _label(String text, double w) => Text(text,
    style: TextStyle(fontSize: w * 0.033, color: Colors.white60,
      fontWeight: FontWeight.w600, decoration: TextDecoration.none));

  Widget _dropdown({
    required String hint, required String? value,
    required List<String> items, required ValueChanged<String?>? onChanged,
    required double w, bool enabled = true,
  }) {
    return Container(
      height: w * 0.115,
      padding: EdgeInsets.symmetric(horizontal: w * 0.035),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? const Color(0xFFA56BFF).withOpacity(0.6)
              : Colors.white.withOpacity(0.1),
          width: value != null ? 1.5 : 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(
            color: Colors.white38, fontSize: w * 0.035, decoration: TextDecoration.none),
            overflow: TextOverflow.ellipsis),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: enabled ? Colors.white54 : Colors.white24, size: w * 0.05),
          dropdownColor: const Color(0xFF1A1650),
          isExpanded: true,
          style: TextStyle(color: Colors.white, fontSize: w * 0.035, decoration: TextDecoration.none),
          onChanged: onChanged,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis,
              style: const TextStyle(decoration: TextDecoration.none)),
          )).toList(),
        ),
      ),
    );
  }
}

// ─── Prompt View ─────────────────────────────────────────────────────────────

class _PromptView extends StatelessWidget {
  const _PromptView({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: EdgeInsets.all(w * 0.08),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("🎓", style: TextStyle(fontSize: w * 0.12, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.04),
        Text("Select your department, year, and course above, then tap Show Modules.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: w * 0.038, color: Colors.white54,
            height: 1.5, decoration: TextDecoration.none)),
      ]),
    ));
  }
}

// ─── Module List ─────────────────────────────────────────────────────────────

class _ModuleList extends StatelessWidget {
  const _ModuleList({required this.grouped, required this.studentCourse, required this.w});
  final Map<String, List<Module>> grouped;
  final String? studentCourse;
  final double w;

  @override
  Widget build(BuildContext context) {
    final sections = grouped.entries.toList();
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(w * 0.045, w * 0.01, w * 0.045, 18),
      itemCount: sections.length,
      itemBuilder: (ctx, si) {
        final subject = sections[si].key;
        final modules = sections[si].value;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: si == 0 ? 0 : w * 0.04, bottom: w * 0.025),
            child: Row(children: [
              Container(width: 3, height: w * 0.045,
                decoration: BoxDecoration(color: const Color(0xFFA56BFF), borderRadius: BorderRadius.circular(2))),
              SizedBox(width: w * 0.025),
              Expanded(child: Text(subject, style: TextStyle(
                fontSize: w * 0.038, fontWeight: FontWeight.w700,
                color: Colors.white70, decoration: TextDecoration.none))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.008),
                decoration: BoxDecoration(
                  color: const Color(0xFFA56BFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: Text("${modules.length}", style: TextStyle(
                  fontSize: w * 0.03, color: const Color(0xFFA56BFF),
                  fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
              ),
            ]),
          ),
          ...modules.map((module) => Padding(
            padding: EdgeInsets.only(bottom: w * 0.04),
            child: _ModuleCard(module: module, studentCourse: studentCourse, w: w))),
        ]);
      },
    );
  }
}

// ─── Module Card ─────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.studentCourse, required this.w});
  final Module module;
  final String? studentCourse;
  final double w;

  static Future<void> saveLastModule(Module module) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_module_title", module.title);
    await prefs.setString("last_module_subject", module.subject);
    await prefs.setInt("last_module_id", module.id);
    try {
      final lessons = await LessonService.getLessonsByModule(module.id);
      final total = lessons.length;
      if (total > 0) {
        final completed = lessons.where((l) => l["completed"] == true || l["completed"] == 1).length;
        await prefs.setDouble("last_module_progress", completed / total);
      } else {
        await prefs.setDouble("last_module_progress", 0.0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
   // IT department courses that can access IT modules
const itCourses = ['IT', 'IS', 'CS'];
final bool isLocked = studentCourse == null || 
    !(module.course == studentCourse || 
      (itCourses.contains(module.course) && itCourses.contains(studentCourse)));

    return appCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _badge(module.gradeLevel, const Color(0xFF6B8FFF)),
        SizedBox(width: w * 0.02),
        _badge(module.course, const Color(0xFF4ECA8D)),
        if (isLocked) ...[
          SizedBox(width: w * 0.02),
          Icon(Icons.lock_rounded, size: w * 0.04, color: Colors.white38)],
      ]),
      SizedBox(height: w * 0.03),
      Text(module.title, style: TextStyle(
        fontSize: w * 0.05, fontWeight: FontWeight.w800,
        color: isLocked ? Colors.white38 : Colors.white,
        height: 1.2, decoration: TextDecoration.none)),
      SizedBox(height: w * 0.025),
      Text(module.description, style: TextStyle(
        fontSize: w * 0.038,
        color: isLocked ? Colors.white24 : Colors.white70,
        height: 1.35, decoration: TextDecoration.none)),
      SizedBox(height: w * 0.025),
      Text(module.subject, style: TextStyle(
        fontSize: w * 0.036,
        color: isLocked ? Colors.white24 : AppTheme.accent2,
        decoration: TextDecoration.none)),
      SizedBox(height: w * 0.04),
      SizedBox(width: double.infinity, height: w * 0.11,
        child: isLocked
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white12)),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_rounded, size: w * 0.045, color: Colors.white38),
                SizedBox(width: w * 0.02),
                Text("Locked", style: TextStyle(
                  fontSize: w * 0.04, fontWeight: FontWeight.w700,
                  color: Colors.white38, decoration: TextDecoration.none)),
              ])))
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)])),
              child: ElevatedButton(
                onPressed: () => _openModule(context, module),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text("Open", style: TextStyle(
                  fontSize: w * 0.04, fontWeight: FontWeight.w700,
                  color: Colors.white, decoration: TextDecoration.none)),
              ))),
    ]));
  }

  Future<void> _openModule(BuildContext context, Module module) async {
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFA56BFF))));
    try {
      final lessons = await LessonService.getLessonsByModule(module.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      if (lessons.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedLessonId = prefs.getInt("last_lesson_id");
        Map<String, dynamic> lesson = lessons.firstWhere(
          (l) => savedLessonId != null && l["id"].toString() == savedLessonId.toString(),
          orElse: () => lessons.firstWhere(
            (l) => l["completed"] == 0 || l["completed"] == false || l["completed"] == null,
            orElse: () => lessons.first));
        await prefs.setString("last_module_title", module.title);
        await prefs.setString("last_module_subject", module.subject);
        await prefs.setInt("last_module_id", module.id);
        await prefs.setInt("last_lesson_id", lesson["id"] as int);
        await prefs.setString("last_lesson_title", lesson["title"] as String);
        if (!context.mounted) return;
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => LessonPage(lessonId: lesson["id"] as int, lessonTitle: lesson["title"] as String)));
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("No lessons available for ${module.title} yet."),
          backgroundColor: const Color(0xFFA56BFF), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString().replaceFirst('Exception: ', '')}"),
        backgroundColor: const Color(0xFFFF5F7E), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.008),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5)),
      child: Text(label, style: TextStyle(
        fontSize: w * 0.029, color: color,
        fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
    );
  }
}

// ─── Empty / Error Views ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onClear, required this.w});
  final VoidCallback onClear;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: EdgeInsets.all(w * 0.08),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("📭", style: TextStyle(fontSize: w * 0.12, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.04),
        Text("No modules found for your selection.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: w * 0.04, color: Colors.white70, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.04),
        TextButton(onPressed: onClear,
          child: const Text("Reset filters", style: TextStyle(color: Color(0xFFA56BFF)))),
      ])));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry, required this.w});
  final String message;
  final VoidCallback onRetry;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: EdgeInsets.all(w * 0.08),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("⚠️", style: TextStyle(fontSize: w * 0.12, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.04),
        Text(message, textAlign: TextAlign.center,
          style: TextStyle(fontSize: w * 0.038, color: Colors.white70, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.04),
        ElevatedButton(onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA56BFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text("Retry", style: TextStyle(color: Colors.white))),
      ])));
  }
}