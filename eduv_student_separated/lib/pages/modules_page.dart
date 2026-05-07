import 'package:flutter/material.dart';

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
  // ── State ─────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  List<Module> _allModules = [];
  List<String> _subjects = [];
  List<String> _grades = [];
  List<String> _courses = [];

  // Active filters — null means "All"
  String? _selectedSubject;
  String? _selectedGrade;
  String? _selectedCourse;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchModules() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ModulesService.getModules(
        subject: _selectedSubject,
        grade: _selectedGrade,
        course: _selectedCourse,
      );
      if (!mounted) return;
      setState(() {
        _allModules = result.modules;
        // Only update filter lists on first load (they never change)
        if (_subjects.isEmpty) _subjects = result.subjects;
        if (_grades.isEmpty) _grades = result.grades;
        if (_courses.isEmpty) _courses = result.courses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _applyFilter({String? subject, String? grade, String? course}) {
    setState(() {
      _selectedSubject = subject;
      _selectedGrade = grade;
      _selectedCourse = course;
    });
    _fetchModules();
  }

  void _clearFilters() => _applyFilter();

  bool get _hasActiveFilter =>
      _selectedSubject != null ||
      _selectedGrade != null ||
      _selectedCourse != null;

  // ── Grouping ──────────────────────────────────────────────────────────────

  /// Groups the filtered module list by subject for section headers.
  Map<String, List<Module>> get _grouped {
    final map = <String, List<Module>>{};
    for (final m in _allModules) {
      map.putIfAbsent(m.subject, () => []).add(m);
    }
    return map;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    return StudentPageBase(
      title: 'Available Modules',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter bar ────────────────────────────────────────────────────
          _FilterBar(
            subjects: _subjects,
            grades: _grades,
            courses: _courses,
            selectedSubject: _selectedSubject,
            selectedGrade: _selectedGrade,
            selectedCourse: _selectedCourse,
            hasActiveFilter: _hasActiveFilter,
            onSubjectChanged: (v) =>
                _applyFilter(subject: v, grade: _selectedGrade, course: _selectedCourse),
            onGradeChanged: (v) =>
                _applyFilter(subject: _selectedSubject, grade: v, course: _selectedCourse),
            onCourseChanged: (v) =>
                _applyFilter(subject: _selectedSubject, grade: _selectedGrade, course: v),
            onClear: _clearFilters,
            w: w,
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFA56BFF)))
                : _error != null
                    ? _ErrorView(
                        message: _error!,
                        onRetry: _fetchModules,
                        w: w,
                      )
                    : _allModules.isEmpty
                        ? _EmptyView(
                            hasFilter: _hasActiveFilter,
                            onClear: _clearFilters,
                            w: w,
                          )
                        : _ModuleList(
                            grouped: _grouped,
                            w: w,
                          ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.subjects,
    required this.grades,
    required this.courses,
    required this.selectedSubject,
    required this.selectedGrade,
    required this.selectedCourse,
    required this.hasActiveFilter,
    required this.onSubjectChanged,
    required this.onGradeChanged,
    required this.onCourseChanged,
    required this.onClear,
    required this.w,
  });

  final List<String> subjects;
  final List<String> grades;
  final List<String> courses;
  final String? selectedSubject;
  final String? selectedGrade;
  final String? selectedCourse;
  final bool hasActiveFilter;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onGradeChanged;
  final ValueChanged<String?> onCourseChanged;
  final VoidCallback onClear;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.045, w * 0.03, w * 0.045, w * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📘 Categorized Topics',
            style: TextStyle(
              fontSize: w * 0.038,
              color: AppTheme.textSoft,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: w * 0.03),
          // Three dropdowns in a row
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  hint: 'Grade',
                  value: selectedGrade,
                  items: grades,
                  onChanged: onGradeChanged,
                  w: w,
                ),
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                child: _FilterDropdown(
                  hint: 'Course',
                  value: selectedCourse,
                  items: courses,
                  onChanged: onCourseChanged,
                  w: w,
                ),
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                flex: 2,
                child: _FilterDropdown(
                  hint: 'Subject',
                  value: selectedSubject,
                  items: subjects,
                  onChanged: onSubjectChanged,
                  w: w,
                ),
              ),
            ],
          ),
          if (hasActiveFilter) ...[
            SizedBox(height: w * 0.02),
            GestureDetector(
              onTap: onClear,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close_rounded,
                      size: w * 0.04, color: const Color(0xFFA56BFF)),
                  SizedBox(width: w * 0.01),
                  Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: w * 0.033,
                      color: const Color(0xFFA56BFF),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.w,
  });

  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: w * 0.1,
      padding: EdgeInsets.symmetric(horizontal: w * 0.025),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != null
              ? const Color(0xFFA56BFF)
              : Colors.white.withOpacity(0.12),
          width: value != null ? 1.5 : 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.white54,
              fontSize: w * 0.032,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white38, size: w * 0.045),
          dropdownColor: const Color(0xFF1A1650),
          isExpanded: true,
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.032,
            decoration: TextDecoration.none,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All $hint',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: w * 0.032,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module list (grouped by subject)
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleList extends StatelessWidget {
  const _ModuleList({required this.grouped, required this.w});

  final Map<String, List<Module>> grouped;
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject section header
            Padding(
              padding: EdgeInsets.only(
                  top: si == 0 ? 0 : w * 0.04, bottom: w * 0.025),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: w * 0.045,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA56BFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: w * 0.025, vertical: w * 0.008),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA56BFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${modules.length}',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: const Color(0xFFA56BFF),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Module cards
            ...modules.map(
              (module) => Padding(
                padding: EdgeInsets.only(bottom: w * 0.04),
                child: _ModuleCard(module: module, w: w),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.w});

  final Module module;
  final double w;

  @override
  Widget build(BuildContext context) {
    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade + Course badges
          Row(
            children: [
              _badge(module.gradeLevel, const Color(0xFF6B8FFF), w),
              SizedBox(width: w * 0.02),
              _badge(module.course, const Color(0xFF4ECA8D), w),
            ],
          ),
          SizedBox(height: w * 0.03),

          Text(
            module.title,
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: w * 0.025),
          Text(
            module.description,
            style: TextStyle(
              fontSize: w * 0.038,
              color: Colors.white70,
              height: 1.35,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: w * 0.025),
          Text(
            module.subject,
            style: TextStyle(
              fontSize: w * 0.036,
              color: AppTheme.accent2,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: w * 0.04),

          SizedBox(
            width: double.infinity,
            height: w * 0.11,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: navigate to module detail page, passing module.id
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Open',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, double w) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.008),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: w * 0.029,
          color: color,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView(
      {required this.hasFilter, required this.onClear, required this.w});

  final bool hasFilter;
  final VoidCallback onClear;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📭',
                style: TextStyle(
                    fontSize: w * 0.12, decoration: TextDecoration.none)),
            SizedBox(height: w * 0.04),
            Text(
              hasFilter
                  ? 'No modules match your filters.'
                  : 'No modules available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.04,
                color: Colors.white70,
                decoration: TextDecoration.none,
              ),
            ),
            if (hasFilter) ...[
              SizedBox(height: w * 0.04),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear filters',
                    style: TextStyle(color: Color(0xFFA56BFF))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(
      {required this.message, required this.onRetry, required this.w});

  final String message;
  final VoidCallback onRetry;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚠️',
                style: TextStyle(
                    fontSize: w * 0.12, decoration: TextDecoration.none)),
            SizedBox(height: w * 0.04),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.038,
                color: Colors.white70,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: w * 0.04),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA56BFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}