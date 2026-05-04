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
  final List<String> _labels = ['Study', 'Explain', 'Exam', 'Quiz'];

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  int _xp = 0;
  int _level = 1;
  double _progress = 0.0;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadUserStats();
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

  Future<void> _loadUserStats() async {
    final cached = await AuthService.getCachedUser();

    if (cached != null && mounted) {
      setState(() {
        _xp = (cached['xpInLevel'] ?? 0) as int;
        _level = (cached['level'] ?? 1) as int;
        _progress = (cached['progress'] ?? 0.0).toDouble();
      });
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();

    if (mounted) {
      setState(() {});
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

      if (mounted) {
        setState(() => _isListening = false);
      }
    } else {
      setState(() => _isListening = true);

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
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
              child: Text(
                'Attach',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insert_drive_file,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: const Text(
                'Document',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'PDF, TXT, DOC, DOCX',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF74EEFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image,
                  color: Color(0xFF74EEFF),
                  size: 22,
                ),
              ),
              title: const Text(
                'Image',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'JPG, PNG, GIF, WEBP',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
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
        fileContent =
            '[File attached: $fileName — ${(bytes.length / 1024).toStringAsFixed(1)} KB]';
      }

      final message =
          'I attached a file called "$fileName". Please help me with it:\n\n$fileContent';

      setState(() {
        _controller.text = message;
      });

      await _sendMessage();
    } else if (choice == 'image') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileName = file.name;
      final bytes = file.bytes;

      if (bytes == null) return;

      if (_isListening) {
        await _speech.stop();

        if (mounted) {
          setState(() => _isListening = false);
        }
      }

      setState(() {
        _messages.add({
          'role': 'user',
          'content': '📎 Image attached: $fileName',
          'type': 'image',
          'imageBytes': bytes,
          'fileName': fileName,
        });
        _isLoading = true;
      });

      _scrollToBottom();

      try {
        final reply = await AiTutorService.chat(
          messages: [
            {
              'role': 'user',
              'content':
                  'The user attached an image named "$fileName". Image support is currently limited in this version. Please tell the student that the image was received and ask them to type the question or describe what they want help with.',
            }
          ],
          mode: _labels[_selectedMode],
        );

        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': reply,
              'type': 'text',
            });
            _isLoading = false;
          });

          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content':
                  'I received the image, but image analysis is not available yet. Please type your question or describe the image.',
              'type': 'text',
            });
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

      if (mounted) {
        setState(() => _isListening = false);
      }
    }

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'type': 'text',
      });
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final apiMessages = _messages
    .where((m) => m['type'] != 'image')
    .where((m) => m['role'] == 'user')
    .map(
      (m) => {
        'role': 'user',
        'content': m['content'] as String,
      },
    )
    .toList();

final reply = await AiTutorService.chat(
  messages: apiMessages,
  mode: _labels[_selectedMode],
);flutter run -d chrome

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': reply,
            'type': 'text',
          });
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
            'type': 'text',
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

                ..._messages.map((msg) {
                  final isUser = msg['role'] == 'user';
                  final isImageMsg = msg['type'] == 'image';
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
                                  child: isImageMsg &&
                                          msg['imageBytes'] != null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.memory(
                                                msg['imageBytes'] is Uint8List
                                                    ? msg['imageBytes']
                                                        as Uint8List
                                                    : Uint8List.fromList(
                                                        msg['imageBytes']
                                                            as List<int>,
                                                      ),
                                                width: w * 0.55,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            SizedBox(height: w * 0.02),
                                            Text(
                                              msg['fileName'] ?? 'Image',
                                              style: TextStyle(
                                                fontSize: w * 0.032,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
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
                                child: MarkdownBody(
                                  data: msg['content'] ?? '',
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      fontSize: w * 0.04,
                                      color: Colors.white,
                                    ),
                                    strong: TextStyle(
                                      fontSize: w * 0.04,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    em: TextStyle(
                                      fontSize: w * 0.04,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    listBullet: TextStyle(
                                      fontSize: w * 0.04,
                                      color: Colors.white,
                                    ),
                                    code: TextStyle(
                                      fontSize: w * 0.035,
                                      color: const Color(0xFF74EEFF),
                                      backgroundColor: Colors.black26,
                                    ),
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
                }),

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

          Container(
            color: Colors.black12,
            padding: EdgeInsets.fromLTRB(w * 0.045, 10, w * 0.045, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _attachFile,
                  child: _circleAction(Icons.attach_file, w),
                ),
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
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            _isListening ? 'Listening...' : 'Speak or type...',
                        hintStyle: TextStyle(
                          color: _isListening
                              ? const Color(0xFF74EEFF)
                              : Colors.white70,
                        ),
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
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: w * 0.12,
                    height: w * 0.12,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFF74EEFF)
                          : Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.black87 : Colors.white,
                      size: w * 0.06,
                    ),
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