import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ── Preferences ───────────────────────────────────────────────────────────
  bool notifications  = true;
  bool sound          = true;
  bool reducedMotion  = false;
  bool twoFactor      = false;
  bool showActivity   = true;
  int  accentIndex    = 1;

  /// True while preferences are still loading from disk (prevents a flicker).
  bool _prefsLoading = true;

  // ── Expandable flags ──────────────────────────────────────────────────────
  bool _profileOpen  = false;
  bool _emailOpen    = false;
  bool _passwordOpen = false;
  bool _phoneOpen    = false;

  // ── Loading flags (one per section) ──────────────────────────────────────
  bool _loadingProfile  = false;
  bool _loadingEmail    = false;
  bool _loadingPassword = false;
  bool _loadingPhone    = false;

  // ── Controllers ───────────────────────────────────────────────────────────
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _usernameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _oldPwCtrl      = TextEditingController();
  final _newPwCtrl      = TextEditingController();
  final _confirmPwCtrl  = TextEditingController();
  final _phoneCtrl      = TextEditingController();

  // ── Display state (shown in the UI) ──────────────────────────────────────
  String _displayName  = '';
  String _displayEmail = '';
  String _displayPhone = 'Not set';
  String _pwStrength   = '';

  // ── Password visibility ───────────────────────────────────────────────────
  bool _showOldPw     = false;
  bool _showNewPw     = false;
  bool _showConfirmPw = false;

  static const _accents = [
    Color(0xFF6B8FFF),
    Color(0xFFA56BFF),
    Color(0xFFD0A06A),
    Color(0xFF7FC7C9),
    Color(0xFFFF7BA3),
    Color(0xFF4ECA8D),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data loading
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads user profile AND persisted preferences in parallel.
  Future<void> _loadAll() async {
    await Future.wait([
      _loadCachedUser(),
      _loadPreferences(),
    ]);
    if (mounted) setState(() => _prefsLoading = false);
  }

  Future<void> _loadCachedUser() async {
    final user = await AuthService.getCachedUser();
    if (user == null || !mounted) return;

    final fullName = user['full_name'] as String? ?? '';
    final parts    = fullName.trim().split(' ');

    setState(() {
      _displayName  = fullName;
      _displayEmail = user['email'] as String? ?? '';
      _displayPhone = (user['phone'] as String?)?.isNotEmpty == true
          ? user['phone'] as String
          : 'Not set';
      _firstNameCtrl.text = parts.isNotEmpty ? parts[0] : '';
      _lastNameCtrl.text  =
          parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _usernameCtrl.text  = user['username'] as String? ?? '';
    });
  }

  Future<void> _loadPreferences() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      notifications = p.getBool('pref_notifications') ?? true;
      sound         = p.getBool('pref_sound')         ?? true;
      reducedMotion = p.getBool('pref_reduced_motion') ?? false;
      twoFactor     = p.getBool('pref_two_factor')     ?? false;
      showActivity  = p.getBool('pref_show_activity')  ?? true;
      accentIndex   = p.getInt('pref_accent_index')    ?? 1;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is bool) p.setBool(key, value);
    if (value is int)  p.setInt(key, value);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Preference setters — update state + persist immediately
  // ─────────────────────────────────────────────────────────────────────────

  void _setNotifications(bool v) { setState(() => notifications = v); _savePref('pref_notifications', v); }
  void _setSound(bool v)         { setState(() => sound = v);         _savePref('pref_sound', v); }
  void _setReducedMotion(bool v) { setState(() => reducedMotion = v); _savePref('pref_reduced_motion', v); }
  void _setTwoFactor(bool v)     { setState(() => twoFactor = v);     _savePref('pref_two_factor', v); }
  void _setShowActivity(bool v)  { setState(() => showActivity = v);  _savePref('pref_show_activity', v); }
  void _setAccentIndex(int i)    { setState(() => accentIndex = i);   _savePref('pref_accent_index', i); }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Color get _accentColor => _accents[accentIndex];

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  void _checkPwStrength(String v) {
    setState(() {
      if (v.isEmpty) {
        _pwStrength = '';
      } else if (v.length < 6) {
        _pwStrength = '⚠ Weak';
      } else if (v.length < 10) {
        _pwStrength = '◎ Fair';
      } else {
        _pwStrength = '✓ Strong';
      }
    });
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFFF5F7E) : const Color(0xFF4ECA8D),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save handlers — delegate to AuthService
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    if (fn.isEmpty || ln.isEmpty) {
      _toast('Name cannot be empty', isError: true);
      return;
    }
    setState(() => _loadingProfile = true);
    try {
      await AuthService.updateProfile(
        fullName: '$fn $ln',
        username: _usernameCtrl.text.trim(),
      );
      setState(() {
        _displayName = '$fn $ln';
        _profileOpen = false;
      });
      _toast('Profile saved!');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _saveEmail() async {
    final v = _emailCtrl.text.trim();
    if (v.isEmpty || !v.contains('@')) {
      _toast('Enter a valid email address', isError: true);
      return;
    }
    setState(() => _loadingEmail = true);
    try {
      await AuthService.updateEmail(email: v);
      setState(() {
        _displayEmail = v;
        _emailCtrl.clear();
        _emailOpen = false;
      });
      _toast('Email updated!');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _savePassword() async {
    if (_oldPwCtrl.text.isEmpty) {
      _toast('Enter your current password', isError: true);
      return;
    }
    if (_newPwCtrl.text.length < 8) {
      _toast('Password must be at least 8 characters', isError: true);
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _toast('Passwords do not match', isError: true);
      return;
    }
    setState(() => _loadingPassword = true);
    try {
      await AuthService.updatePassword(
        currentPassword: _oldPwCtrl.text,
        newPassword: _newPwCtrl.text,
      );
      _oldPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      setState(() {
        _pwStrength   = '';
        _passwordOpen = false;
      });
      _toast('Password updated!');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loadingPassword = false);
    }
  }

  Future<void> _savePhone() async {
    final v = _phoneCtrl.text.trim();
    if (v.isEmpty) {
      _toast('Enter a phone number', isError: true);
      return;
    }
    setState(() => _loadingPhone = true);
    try {
      await AuthService.updatePhone(phone: v);
      setState(() {
        _displayPhone = v;
        _phoneCtrl.clear();
        _phoneOpen = false;
      });
      _toast('Phone number saved!');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loadingPhone = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    // Optionally clear prefs on logout: (await SharedPreferences.getInstance()).clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    // Show a full-page loader while prefs are hydrating so the switches
    // never flicker to their defaults and back.
    if (_prefsLoading) {
      return StudentPageBase(
        title: 'Settings',
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    return StudentPageBase(
      title: 'Settings',
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.045, 10, w * 0.045, 32),
        children: [
          // ── PROFILE ──────────────────────────────────────────────────────
          _sectionLabel('Profile', w),
          appCard(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _profileOpen = !_profileOpen),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: w * 0.06,
                        backgroundColor: _accentColor.withOpacity(0.3),
                        child: Text(
                          _displayName.isEmpty ? '?' : _initials(_displayName),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: w * 0.045,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.035),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName.isEmpty
                                  ? 'Your Name'
                                  : _displayName,
                              style: TextStyle(
                                fontSize: w * 0.042,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: w * 0.005),
                            Text(
                              _displayEmail.isEmpty
                                  ? 'your@email.com'
                                  : _displayEmail,
                              style: TextStyle(
                                fontSize: w * 0.033,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _profileOpen ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                if (_profileOpen) ...[
                  SizedBox(height: w * 0.04),
                  _inputField('First Name', _firstNameCtrl, w),
                  SizedBox(height: w * 0.03),
                  _inputField('Last Name', _lastNameCtrl, w),
                  SizedBox(height: w * 0.03),
                  _inputField('Username', _usernameCtrl, w),
                  SizedBox(height: w * 0.03),
                  _actionButton('Save Profile', _saveProfile, w,
                      loading: _loadingProfile),
                ],
              ],
            ),
          ),
          SizedBox(height: w * 0.03),

          // ── ACCOUNT ───────────────────────────────────────────────────────
          _sectionLabel('Account', w),
          appCard(
            child: Column(
              children: [
                // Change Email
                _expandableRow(
                  icon: Icons.email_outlined,
                  title: 'Change Email',
                  subtitle: _displayEmail.isEmpty
                      ? 'your@email.com'
                      : _displayEmail,
                  isOpen: _emailOpen,
                  onTap: () => setState(() => _emailOpen = !_emailOpen),
                  expandedChild: Column(
                    children: [
                      SizedBox(height: w * 0.03),
                      _inputField('New email address', _emailCtrl, w,
                          keyboardType: TextInputType.emailAddress),
                      SizedBox(height: w * 0.03),
                      _actionButton('Update Email', _saveEmail, w,
                          loading: _loadingEmail),
                    ],
                  ),
                  w: w,
                ),
                _divider(),

                // Change Password
                _expandableRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Keep your account secure',
                  isOpen: _passwordOpen,
                  onTap: () =>
                      setState(() => _passwordOpen = !_passwordOpen),
                  expandedChild: Column(
                    children: [
                      SizedBox(height: w * 0.03),
                      _passwordField(
                        'Current password',
                        _oldPwCtrl,
                        _showOldPw,
                        () => setState(() => _showOldPw = !_showOldPw),
                        w,
                      ),
                      SizedBox(height: w * 0.025),
                      _passwordField(
                        'New password',
                        _newPwCtrl,
                        _showNewPw,
                        () => setState(() => _showNewPw = !_showNewPw),
                        w,
                        onChanged: _checkPwStrength,
                      ),
                      if (_pwStrength.isNotEmpty) ...[
                        SizedBox(height: w * 0.015),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _pwStrength,
                            style: TextStyle(
                              fontSize: w * 0.033,
                              color: _pwStrength.startsWith('✓')
                                  ? const Color(0xFF4ECA8D)
                                  : _pwStrength.startsWith('◎')
                                      ? const Color(0xFFD0A06A)
                                      : const Color(0xFFFF5F7E),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: w * 0.025),
                      _passwordField(
                        'Confirm new password',
                        _confirmPwCtrl,
                        _showConfirmPw,
                        () => setState(
                            () => _showConfirmPw = !_showConfirmPw),
                        w,
                      ),
                      SizedBox(height: w * 0.03),
                      _actionButton('Update Password', _savePassword, w,
                          loading: _loadingPassword),
                    ],
                  ),
                  w: w,
                ),
                _divider(),

                // Phone Number
                _expandableRow(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  subtitle: _displayPhone,
                  isOpen: _phoneOpen,
                  onTap: () => setState(() => _phoneOpen = !_phoneOpen),
                  expandedChild: Column(
                    children: [
                      SizedBox(height: w * 0.03),
                      _inputField('+63 9XX XXX XXXX', _phoneCtrl, w,
                          keyboardType: TextInputType.phone),
                      SizedBox(height: w * 0.03),
                      _actionButton('Save Number', _savePhone, w,
                          loading: _loadingPhone),
                    ],
                  ),
                  w: w,
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.03),

          // ── PREFERENCES ───────────────────────────────────────────────────
          _sectionLabel('Preferences', w),
          _switchCard(
            Icons.notifications_outlined,
            'Notifications',
            'Enable reminders',
            notifications,
            _setNotifications, // ← persisted
            w,
          ),
          SizedBox(height: w * 0.03),
          _switchCard(
            Icons.volume_up_outlined,
            'Sound',
            'UI click sounds',
            sound,
            _setSound, // ← persisted
            w,
          ),
          SizedBox(height: w * 0.03),
          _switchCard(
            Icons.animation_outlined,
            'Reduced Motion',
            'Less animations',
            reducedMotion,
            _setReducedMotion, // ← persisted
            w,
          ),

          // ── APPEARANCE ────────────────────────────────────────────────────
          _sectionLabel('Appearance', w),
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accent Color',
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: w * 0.03),
                Wrap(
                  spacing: w * 0.03,
                  runSpacing: w * 0.03,
                  children: List.generate(_accents.length, (i) {
                    return GestureDetector(
                      onTap: () => _setAccentIndex(i), // ← persisted
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: w * 0.09,
                        height: w * 0.09,
                        decoration: BoxDecoration(
                          color: _accents[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == accentIndex
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: i == accentIndex
                              ? [
                                  BoxShadow(
                                    color: _accents[i].withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.03),

          // ── PRIVACY & SECURITY ────────────────────────────────────────────
          _sectionLabel('Privacy & Security', w),
          appCard(
            child: Column(
              children: [
                _inlineSwitch(
                  Icons.shield_outlined,
                  'Two-Factor Auth',
                  'Extra login security',
                  twoFactor,
                  _setTwoFactor, // ← persisted
                  w,
                ),
                _divider(),
                _inlineSwitch(
                  Icons.visibility_outlined,
                  'Show Activity',
                  'Let others see online status',
                  showActivity,
                  _setShowActivity, // ← persisted
                  w,
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.03),

          // ── DANGER ZONE ───────────────────────────────────────────────────
          _sectionLabel('Danger Zone', w),
          appCard(
            child: Column(
              children: [
                _dangerRow(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  color: Colors.white,
                  onTap: () => _confirmDialog(
                    title: 'Log Out',
                    message: 'Are you sure you want to log out?',
                    onConfirm: _logout,
                  ),
                  w: w,
                ),
                _divider(),
                _dangerRow(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account',
                  color: const Color(0xFFFF5F7E),
                  onTap: () => _confirmDialog(
                    title: 'Delete Account',
                    message:
                        'This is permanent and cannot be undone. All your data will be lost.',
                    onConfirm: () =>
                        _toast('Contact support to delete your account'),
                    destructive: true,
                  ),
                  w: w,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reusable widgets  (unchanged from original)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label, double w) => Padding(
        padding: EdgeInsets.only(left: 4, bottom: w * 0.02, top: w * 0.01),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: w * 0.03,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _divider() => Container(
        height: 0.5,
        color: Colors.white.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(vertical: 4),
      );

  Widget _inputField(
    String hint,
    TextEditingController ctrl,
    double w, {
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Container(
        height: w * 0.12,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: EdgeInsets.symmetric(horizontal: w * 0.03),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.white, fontSize: w * 0.038),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white38, fontSize: w * 0.038),
          ),
        ),
      );

  Widget _passwordField(
    String hint,
    TextEditingController ctrl,
    bool visible,
    VoidCallback toggleVisibility,
    double w, {
    ValueChanged<String>? onChanged,
  }) =>
      Container(
        height: w * 0.12,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: EdgeInsets.symmetric(horizontal: w * 0.03),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: ctrl,
          obscureText: !visible,
          onChanged: onChanged,
          style: TextStyle(color: Colors.white, fontSize: w * 0.038),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white38, fontSize: w * 0.038),
            suffixIcon: GestureDetector(
              onTap: toggleVisibility,
              child: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: w * 0.05,
              ),
            ),
          ),
        ),
      );

  Widget _actionButton(
    String label,
    VoidCallback onPressed,
    double w, {
    bool loading = false,
  }) =>
      SizedBox(
        width: double.infinity,
        height: w * 0.12,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            disabledBackgroundColor: _accentColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      );

  Widget _expandableRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isOpen,
    required VoidCallback onTap,
    required Widget expandedChild,
    required double w,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.01),
        child: Column(
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(icon, color: Colors.white60, size: w * 0.055),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                        SizedBox(height: w * 0.005),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: w * 0.032,
                                color: Colors.white54),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white38),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: expandedChild,
              crossFadeState: isOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      );

  Widget _switchCard(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    double w,
  ) =>
      appCard(
        child: Row(
          children: [
            Icon(icon, color: Colors.white60, size: w * 0.055),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  SizedBox(height: w * 0.01),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: w * 0.033, color: Colors.white70)),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: _accentColor,
                activeTrackColor: _accentColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );

  Widget _inlineSwitch(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    double w,
  ) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.01),
        child: Row(
          children: [
            Icon(icon, color: Colors.white60, size: w * 0.055),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(height: w * 0.005),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: w * 0.032, color: Colors.white54)),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: _accentColor,
                activeTrackColor: _accentColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );

  Widget _dangerRow({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required double w,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.02),
          child: Row(
            children: [
              Icon(icon, color: color.withOpacity(0.8), size: w * 0.055),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5), size: w * 0.05),
            ],
          ),
        ),
      );

  void _confirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool destructive = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1650),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              title,
              style: TextStyle(
                color: destructive
                    ? const Color(0xFFFF5F7E)
                    : const Color(0xFF9E7AFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}