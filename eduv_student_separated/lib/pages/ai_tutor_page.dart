import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:file_picker/file_picker.dart';

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
  final SpeechToText _speech = SpeechToText();

  int _selectedMode = 0;
  final List<String> _labels = ['Study', 'Explain', 'Exam'];

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  int _questionsAsked = 0;
  int _topicsExplored = 0;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _addGreeting();
    _initSpeech();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _addGreeting() {
    final mode = _labels[_selectedMode];
    final greetings = {
      'Study': 'Hi Student! Ready to learn? Ask me anything! 📚',
      'Explain': 'Hi! Give me any concept and I\'ll explain it simply! 💡',
      'Exam': 'Let\'s get you exam-ready! What topic are we reviewing? 📝',
    };
    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'assistant',
        'content': greetings[mode] ?? 'Hi! Ready to learn?',
        'type': 'text',
      });
    });
  }

  void _onModeChanged(int index) {
    setState(() => _selectedMode = index);
    _addGreeting();
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available')),
      );
      return;
    }
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() => _controller.text = result.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    }
  }

  Future<void> _attachFile() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Attach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.insert_drive_file, color: Colors.white, size: 22),
              ),
              title: const Text('Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('PDF, TXT, DOC, DOCX', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFF74EEFF).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.image, color: Color(0xFF74EEFF), size: 22),
              ),
              title: const Text('Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('JPG, PNG, GIF, WEBP', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'file') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final fileName = file.name;
      final bytes = file.bytes;
      if (bytes == null) return;

      String fileContent = '';
      if (fileName.toLowerCase().endsWith('.txt')) {
        fileContent = String.fromCharCodes(bytes);
      } else {
        fileContent = '[File attached: $fileName — ${(bytes.length / 1024).toStringAsFixed(1)} KB]';
      }
      setState(() {
        _controller.text = 'I attached a file called "$fileName". Please help me with it:\n\n$fileContent';
      });
      await _sendMessage();

    } else if (choice == 'image') {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final fileName = file.name;
      final bytes = file.bytes;
      if (bytes == null) return;

      if (_isListening) {
        await _speech.stop();
        if (mounted) setState(() => _isListening = false);
      }

      setState(() {
        _messages.add({
          'role': 'user',
          'content': '📎 Image: $fileName',
          'type': 'image',
          'imageBytes': bytes,
          'fileName': fileName,
        });
        _isLoading = true;
      });
      _scrollToBottom();

      try {
        final reply = await AiTutorService.chat(
          messages: List<Map<String, dynamic>>.from(_messages),
          mode: _labels[_selectedMode],
        );
        if (mounted) {
          setState(() {
            _messages.add({'role': 'assistant', 'content': reply, 'type': 'text'});
            _isLoading = false;
            _questionsAsked++;
          });
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({'role': 'assistant', 'content': 'Sorry, I could not analyze the image. Please try again.', 'type': 'text'});
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text, 'type': 'text'});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await AiTutorService.chat(
        messages: List<Map<String, dynamic>>.from(_messages),
        mode: _labels[_selectedMode],
      );
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply, 'type': 'text'});
          _isLoading = false;
          _questionsAsked++;
          // Count unique topics loosely by every 3 questions
          _topicsExplored = (_questionsAsked / 3).floor();
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Sorry, something went wrong. Please try again.', 'type': 'text'});
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

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);
    final modeIcons = [Icons.menu_book, Icons.lightbulb, Icons.quiz];
    final modeColors = [const Color(0xFF74EEFF), const Color(0xFFFFD874), const Color(0xFFFF74A8)];

    return StudentPageBase(
      title: 'AI Tutor',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(w * 0.04, 10, w * 0.04, 10),
              children: [
                // ── Session stats card ──
                appCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip(Icons.help_outline, '$_questionsAsked', 'Questions', const Color(0xFF74EEFF)),
                      Container(width: 1, height: 36, color: Colors.white12),
                      _statChip(Icons.explore_outlined, '$_topicsExplored', 'Topics', const Color(0xFFFFD874)),
                      Container(width: 1, height: 36, color: Colors.white12),
                      _statChip(
                        modeIcons[_selectedMode],
                        _labels[_selectedMode],
                        'Mode',
                        modeColors[_selectedMode],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: w * 0.025),

                // ── Mode selector ──
                Row(
                  children: List.generate(_labels.length, (i) {
                    final active = i == _selectedMode;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == _labels.length - 1 ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => _onModeChanged(i),
                          child: Container(
                            height: w * 0.10,
                            decoration: BoxDecoration(
                              color: active ? modeColors[i] : Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(modeIcons[i], size: w * 0.04, color: active ? Colors.black87 : Colors.white54),
                                SizedBox(width: w * 0.015),
                                Text(
                                  _labels[i],
                                  style: TextStyle(
                                    fontSize: w * 0.032,
                                    fontWeight: FontWeight.w800,
                                    color: active ? Colors.black87 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: w * 0.05),

                // ── Messages ──
                ..._messages.map((msg) {
                  final isUser = msg['role'] == 'user';
                  final isImageMsg = msg['type'] == 'image';
                  final now = DateTime.now();

                  if (isUser) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: w * 0.03),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.025),
                                  decoration: BoxDecoration(color: const Color(0xFF9074FF), borderRadius: BorderRadius.circular(14)),
                                  child: isImageMsg && msg['imageBytes'] != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.memory(
                                                msg['imageBytes'] is Uint8List
                                                    ? msg['imageBytes'] as Uint8List
                                                    : Uint8List.fromList(msg['imageBytes'] as List<int>),
                                                width: w * 0.55,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            SizedBox(height: w * 0.015),
                                            Text(msg['fileName'] ?? 'Image', style: TextStyle(fontSize: w * 0.03, color: Colors.white70)),
                                          ],
                                        )
                                      : Text(msg['content'] ?? '', style: TextStyle(fontSize: w * 0.035, color: Colors.white)),
                                ),
                                SizedBox(height: w * 0.015),
                                Text(_formatTime(now), style: TextStyle(fontSize: w * 0.028, color: AppTheme.textSoft)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: w * 0.03),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: w * 0.05,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.smart_toy, color: Colors.white, size: w * 0.05),
                        ),
                        SizedBox(width: w * 0.025),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.025),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
                                child: MarkdownBody(
                                  data: msg['content'] ?? '',
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(fontSize: w * 0.035, color: Colors.white),
                                    strong: TextStyle(fontSize: w * 0.035, color: Colors.white, fontWeight: FontWeight.w800),
                                    em: TextStyle(fontSize: w * 0.035, color: Colors.white, fontStyle: FontStyle.italic),
                                    listBullet: TextStyle(fontSize: w * 0.035, color: Colors.white),
                                    code: TextStyle(fontSize: w * 0.03, color: const Color(0xFF74EEFF), backgroundColor: Colors.black26),
                                  ),
                                ),
                              ),
                              SizedBox(height: w * 0.015),
                              Text(_formatTime(now), style: TextStyle(fontSize: w * 0.028, color: AppTheme.textSoft)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.only(bottom: w * 0.03),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: w * 0.05,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.smart_toy, color: Colors.white, size: w * 0.05),
                        ),
                        SizedBox(width: w * 0.025),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.025),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [_dot(w, 0), _dot(w, 150), _dot(w, 300)],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Input bar ──
          Container(
            color: Colors.black12,
            padding: EdgeInsets.fromLTRB(w * 0.04, 8, w * 0.04, 12),
            child: Row(
              children: [
                GestureDetector(onTap: _attachFile, child: _circleAction(Icons.attach_file, w)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: w * 0.11,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.035),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.white, fontSize: w * 0.035),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: _isListening ? 'Listening...' : 'Speak or type...',
                        hintStyle: TextStyle(color: _isListening ? const Color(0xFF74EEFF) : Colors.white70, fontSize: w * 0.035),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: w * 0.18,
                  height: w * 0.11,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9074FF),
                      disabledBackgroundColor: const Color(0xFF9074FF).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('Send', style: TextStyle(fontSize: w * 0.035, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: w * 0.11,
                    height: w * 0.11,
                    decoration: BoxDecoration(
                      color: _isListening ? const Color(0xFF74EEFF) : Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.black87 : Colors.white, size: w * 0.055),
                  ),
                ),
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
          width: w * 0.018,
          height: w * 0.018,
          margin: EdgeInsets.symmetric(horizontal: w * 0.008),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, double w) {
    return Container(
      width: w * 0.11,
      height: w * 0.11,
      decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: Colors.white, size: w * 0.055),
    );
  }
}