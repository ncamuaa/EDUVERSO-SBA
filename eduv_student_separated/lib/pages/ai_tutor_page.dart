import 'package:flutter/material.dart';
import '../services/ai_tutor_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class AITutorPage extends StatefulWidget {
  const AITutorPage({super.key});

  @override
  State<AITutorPage> createState() => _AITutorPageState();
}

class _AITutorPageState extends State<AITutorPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedMode = 0;
  final List<String> _labels = ['Study', 'Explain', 'Exam', 'Quiz'];
  bool _isLoading = false;

  int _xp = 0;
  int _level = 1;
  double _progress = 0.0;

  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    _addGreeting();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadUserStats() async {
    final cached = await AuthService.getCachedUser();
    if (cached != null && mounted) {
      setState(() {
        _xp = (cached['xpInLevel'] ?? 0) as int;
        _level = (cached['level'] ?? 1) as int;
        _progress = (cached['progress'] ?? 0.0).toDouble();
      });
    }
  }

  void _addGreeting() {
    final mode = _labels[_selectedMode];
    final greetings = {
      'Study': 'Hi Student! Ready to learn? Ask me anything! 📚',
      'Explain': 'Hi! Give me any concept and I\'ll explain it simply! 💡',
      'Exam': 'Let\'s get you exam-ready! What topic are we reviewing? 📝',
      'Quiz': 'Quiz time! What topic would you like to be quizzed on? 🎯',
    };

    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'assistant',
        'content': greetings[mode] ?? 'Hi! Ready to learn?',
      });
    });
  }

  void _onModeChanged(int index) {
    setState(() => _selectedMode = index);
    _addGreeting();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Skip greeting message from API call
      final apiMessages = _messages
          .where((m) => !(m['role'] == 'assistant' && _messages.indexOf(m) == 0))
          .toList();

      final reply = await AiTutorService.chat(
        messages: apiMessages,
        mode: _labels[_selectedMode],
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Sorry, something went wrong. Please try again.',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    return StudentPageBase(
      title: 'AI Tutor',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 12),
              children: [
                /// XP CARD
                appCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_xp',
                        style: TextStyle(
                          fontSize: w * 0.11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: w * 0.02),
                      Text(
                        'XP • Level $_level',
                        style: TextStyle(
                          fontSize: w * 0.045,
                          color: AppTheme.textSoft,
                        ),
                      ),
                      SizedBox(height: w * 0.03),
                      progressBar(_progress),
                    ],
                  ),
                ),

                SizedBox(height: w * 0.03),

                /// MODE TABS
                Row(
                  children: List.generate(_labels.length, (i) {
                    final active = i == _selectedMode;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == _labels.length - 1 ? 0 : 8,
                        ),
                        child: GestureDetector(
                          onTap: () => _onModeChanged(i),
                          child: Container(
                            height: w * 0.12,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF74EEFF)
                                  : Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _labels[i],
                              style: TextStyle(
                                fontSize: w * 0.035,
                                fontWeight: FontWeight.w800,
                                color: active ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: w * 0.06),

                /// CHAT MESSAGES
                ..._messages.asMap().entries.map((entry) {
                  final msg = entry.value;
                  final isUser = msg['role'] == 'user';
                  final now = DateTime.now();

                  if (isUser) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: w * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.04,
                                    vertical: w * 0.03,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9074FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    msg['content'] ?? '',
                                    style: TextStyle(
                                      fontSize: w * 0.04,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: w * 0.02),
                                Text(
                                  _formatTime(now),
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: AppTheme.textSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.only(bottom: w * 0.04),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: w * 0.06,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: w * 0.06,
                            ),
                          ),
                          SizedBox(width: w * 0.03),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.04,
                                    vertical: w * 0.03,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    msg['content'] ?? '',
                                    style: TextStyle(
                                      fontSize: w * 0.04,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: w * 0.02),
                                Text(
                                  _formatTime(now),
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: AppTheme.textSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),

                /// LOADING DOTS
                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.only(bottom: w * 0.04),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: w * 0.06,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: w * 0.06,
                          ),
                        ),
                        SizedBox(width: w * 0.03),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.04,
                            vertical: w * 0.03,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(w, 0),
                              _dot(w, 150),
                              _dot(w, 300),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          /// INPUT BAR
          Container(
            color: Colors.black12,
            padding: EdgeInsets.fromLTRB(w * 0.045, 10, w * 0.045, 14),
            child: Row(
              children: [
                _circleAction(Icons.attach_file, w),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: w * 0.13,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.04,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Speak or type...',
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: w * 0.2,
                  height: w * 0.13,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9074FF),
                      disabledBackgroundColor:
                          const Color(0xFF9074FF).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Send',
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _circleAction(Icons.mic, w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double w, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: w * 0.02,
          height: w * 0.02,
          margin: EdgeInsets.symmetric(horizontal: w * 0.01),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, double w) {
    return Container(
      width: w * 0.12,
      height: w * 0.12,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: w * 0.06,
      ),
    );
  }
}