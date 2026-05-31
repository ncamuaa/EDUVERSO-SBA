import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/last_lesson_store.dart';
import '../services/lesson_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';
import '../utils/xp_history.dart';
import '../services/game_progress_service.dart';

// ─────────────────────────────────────────────
//  SHARED THEME CONSTANTS
// ─────────────────────────────────────────────
const kBg      = Color(0xFF1A1A2E);
const kBg2     = Color(0xFF16213E);
const kCard    = Color(0xFF0F3460);
const kPurple  = Color(0xFFB04CFF);
const kYellow  = Color(0xFFFFCC29);
const kBlue    = Color(0xFF3657C9);
const kGreen   = Color(0xFF43E97B);
const kRed     = Color(0xFFFF6B6B);
const kOrange  = Color(0xFFFF9F43);
const kPink    = Color(0xFFFF6CAE);
const kWhite70 = Color(0xB3FFFFFF);
const kWhite60 = Color(0x99FFFFFF);
const kWhite12 = Color(0x1FFFFFFF);
const kWhite08 = Color(0x14FFFFFF);

// ─────────────────────────────────────────────
//  LESSON → GAME CONVERTERS
// ─────────────────────────────────────────────

List<Map<String, dynamic>> _guessQuestionsFromLesson(LessonDetail lesson) {
  final rng = Random();
  final result = <Map<String, dynamic>>[];

  for (final q in lesson.quiz) {
    if (q.options.isEmpty) continue;
    final options = q.options.map((o) => o.text).toList();
    final correctOption = q.options.reduce(
      (a, b) => a.orderIndex < b.orderIndex ? a : b,
    );
    final answerIndex = options.indexOf(correctOption.text);
    final sentences = q.question
        .split(RegExp(r'(?<=[.?!])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final clues = sentences.length >= 2
        ? sentences.take(3).toList()
        : [q.question, 'Think about what you learned in this lesson.', 'Re-read the slides for a hint.'];
    result.add({'concept': correctOption.text, 'clues': clues, 'options': options, 'answerIndex': answerIndex, 'question': q.question});
  }

  while (result.length < 10 && result.isNotEmpty) {
    result.addAll(List<Map<String, dynamic>>.from(result)..shuffle(rng));
  }
  result.shuffle(rng);
  return result.take(10).toList();
}

List<Map<String, dynamic>> _escapePuzzlesFromLesson(LessonDetail lesson) {
  final rng        = Random();
  final puzzles    = <Map<String, dynamic>>[];
  final codeBlocks = lesson.content.where((b) => b.type == 'code').toList();

  if (codeBlocks.isEmpty) return _textPuzzlesFromLesson(lesson, target: 10);

  const skipTokens = {'{', '}', '(', ')', '[', ']', ';', ':', ',', '//', '#', '---'};

  for (int pass = 0; pass < 4 && puzzles.length < 10; pass++) {
    for (final block in codeBlocks) {
      if (puzzles.length >= 10) break;
      final allTokens = <String>[];
      for (final line in block.body.split('\n')) {
        for (final token in line.trim().split(RegExp(r'\s+'))) {
          final clean = token.replaceAll(RegExp(r'[(){}\[\];,]'), '').trim();
          if (clean.length > 1 && !skipTokens.contains(clean)) allTokens.add(clean);
        }
      }
      if (allTokens.isEmpty) continue;
      allTokens.shuffle(rng);
      final uniqueTokens = allTokens.toSet().toList()..shuffle(rng);
      final toBlank = uniqueTokens.take(3).toList();
      if (toBlank.isEmpty) continue;
      final distractors = uniqueTokens.where((t) => !toBlank.contains(t)).take(7).toList();
      var codeStr = block.body;
      final answers = <String>[];
      for (int i = 0; i < toBlank.length; i++) {
        codeStr = codeStr.replaceFirst(RegExp(RegExp.escape(toBlank[i])), '___${i}___');
        answers.add(toBlank[i]);
      }
      final chips = [...answers, ...distractors]..shuffle(rng);
      puzzles.add({
        'title': block.language != null ? '${block.language} Puzzle ${puzzles.length + 1}' : 'Code Puzzle ${puzzles.length + 1}',
        'description': 'Fill in the missing tokens. (Round ${puzzles.length + 1})',
        'codeLines': codeStr,
        'answers': answers,
        'chips': chips.take(10).toList(),
      });
    }
  }
  return puzzles.isEmpty ? _textPuzzlesFromLesson(lesson, target: 10) : puzzles.take(10).toList();
}

List<Map<String, dynamic>> _textPuzzlesFromLesson(LessonDetail lesson, {int target = 10}) {
  final rng        = Random();
  final puzzles    = <Map<String, dynamic>>[];
  final textBlocks = lesson.content.where((b) => b.type == 'text').toList();

  for (int pass = 0; pass < 5 && puzzles.length < target; pass++) {
    for (final block in textBlocks) {
      if (puzzles.length >= target) break;
      final lines = block.body.split('\n').where((l) => l.trim().isNotEmpty && !l.startsWith('##')).toList()..shuffle(rng);
      for (final line in lines) {
        if (puzzles.length >= target) break;
        final words = line.split(' ').where((w) => w.replaceAll(RegExp(r'[^a-zA-Z]'), '').length > 4).toList()..shuffle(rng);
        if (words.isEmpty) continue;
        final toBlank = words.take(3).toList();
        var codeStr = line;
        final answers = <String>[];
        for (int i = 0; i < toBlank.length; i++) {
          codeStr = codeStr.replaceFirst(toBlank[i], '___${i}___');
          answers.add(toBlank[i]);
        }
        final allWords = line.split(' ').where((w) => w.length > 3).toList()..shuffle(rng);
        final distractors = allWords.where((w) => !answers.contains(w)).take(7).toList();
        final chips = [...answers, ...distractors]..shuffle(rng);
        puzzles.add({'title': 'Fill the Blank ${puzzles.length + 1}', 'description': 'Complete the sentence from the lesson.', 'codeLines': codeStr, 'answers': answers, 'chips': chips.take(10).toList()});
      }
    }
  }

  if (puzzles.isEmpty) {
    for (int i = 0; i < target; i++) {
      puzzles.add({'title': 'Lesson Recall ${i + 1}', 'description': 'What is the main topic of this lesson?', 'codeLines': 'The topic of this lesson is ___0___.', 'answers': [lesson.subject], 'chips': [lesson.subject, 'Math', 'Science', 'History', 'English', 'Art', 'Music', 'PE', 'Technology', 'Drama']});
    }
  }
  return puzzles.take(target).toList();
}

List<Map<String, dynamic>> _scrambleWordsFromLesson(LessonDetail lesson) {
  final rng   = Random();
  final words = <Map<String, dynamic>>[];
  for (final block in lesson.content.where((b) => b.type == 'text')) {
    for (final line in block.body.split('\n')) {
      for (final raw in line.split(' ')) {
        final w = raw.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (w.length >= 4 && w.length <= 12) {
          final scrambled = (w.split('')..shuffle(rng)).join();
          if (scrambled != w) words.add({'word': w, 'scrambled': scrambled});
        }
      }
    }
  }
  for (final q in lesson.quiz) {
    for (final o in q.options) {
      final w = o.text.trim().replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (w.length >= 4 && w.length <= 12) {
        final scrambled = (w.split('')..shuffle(rng)).join();
        if (scrambled != w) words.add({'word': w, 'scrambled': scrambled});
      }
    }
  }
  words.shuffle(rng);
  final unique = <String>{};
  final result = <Map<String, dynamic>>[];
  for (final e in words) {
    if (unique.add(e['word'] as String)) result.add(e);
    if (result.length >= 10) break;
  }
  if (result.isEmpty) result.add({'word': lesson.subject, 'scrambled': (lesson.subject.split('')..shuffle(rng)).join()});
  return result;
}

List<Map<String, dynamic>> _flashCardsFromLesson(LessonDetail lesson) {
  final cards = <Map<String, dynamic>>[];
  for (final q in lesson.quiz) {
    if (q.options.isEmpty) continue;
    final correct = q.options.reduce((a, b) => a.orderIndex < b.orderIndex ? a : b);
    cards.add({'front': q.question, 'back': correct.text});
  }
  if (cards.isEmpty) cards.add({'front': 'What is the topic of this lesson?', 'back': lesson.title});
  return cards;
}

// Speed Quiz — rapid fire questions with countdown
List<Map<String, dynamic>> _speedQuizFromLesson(LessonDetail lesson) {
  final rng    = Random();
  final result = <Map<String, dynamic>>[];
  for (final q in lesson.quiz) {
    if (q.options.isEmpty) continue;
    final options     = q.options.map((o) => o.text).toList();
    final correctOpt  = q.options.reduce((a, b) => a.orderIndex < b.orderIndex ? a : b);
    final answerIndex = options.indexOf(correctOpt.text);
    result.add({'question': q.question, 'options': options, 'answerIndex': answerIndex});
  }
  while (result.length < 8 && result.isNotEmpty) {
    result.addAll(List<Map<String, dynamic>>.from(result)..shuffle(rng));
  }
  result.shuffle(rng);
  return result.take(8).toList();
}

// True or False — derive from quiz options
List<Map<String, dynamic>> _trueFalseFromLesson(LessonDetail lesson) {
  final rng   = Random();
  final cards = <Map<String, dynamic>>[];
  for (final q in lesson.quiz) {
    if (q.options.isEmpty) continue;
    final correctOpt   = q.options.reduce((a, b) => a.orderIndex < b.orderIndex ? a : b);
    final incorrectOpts = q.options.where((o) => o.id != correctOpt.id).toList();
    // True card
    cards.add({'statement': '${q.question}\nAnswer: ${correctOpt.text}', 'isTrue': true});
    // False card — use a wrong option
    if (incorrectOpts.isNotEmpty) {
      final wrong = incorrectOpts[rng.nextInt(incorrectOpts.length)];
      cards.add({'statement': '${q.question}\nAnswer: ${wrong.text}', 'isTrue': false});
    }
  }
  if (cards.isEmpty) {
    cards.add({'statement': 'This lesson is about ${lesson.subject}.', 'isTrue': true});
    cards.add({'statement': 'This lesson is about Mathematics.', 'isTrue': lesson.subject == 'Mathematics'});
  }
  cards.shuffle(rng);
  return cards.take(10).toList();
}

// Memory Match — pairs of question + answer cards
List<Map<String, dynamic>> _memoryPairsFromLesson(LessonDetail lesson) {
  final rng   = Random();
  final pairs = <Map<String, dynamic>>[];
  for (final q in lesson.quiz) {
    if (q.options.isEmpty) continue;
    final correct = q.options.reduce((a, b) => a.orderIndex < b.orderIndex ? a : b);
    pairs.add({'q': q.question.length > 60 ? '${q.question.substring(0, 60)}…' : q.question, 'a': correct.text});
    if (pairs.length >= 6) break;
  }
  // Fallback from text
  if (pairs.length < 4) {
    for (final block in lesson.content.where((b) => b.type == 'text')) {
      for (final line in block.body.split('\n').where((l) => l.contains(':') && l.length > 10)) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          pairs.add({'q': parts[0].trim().replaceAll('##', '').trim(), 'a': parts.sublist(1).join(':').trim()});
          if (pairs.length >= 6) break;
        }
      }
      if (pairs.length >= 6) break;
    }
  }
  if (pairs.isEmpty) {
    pairs.add({'q': 'Topic', 'a': lesson.title});
    pairs.add({'q': 'Subject', 'a': lesson.subject});
    pairs.add({'q': 'Course', 'a': lesson.course});
    pairs.add({'q': 'Grade', 'a': lesson.gradeLevel});
  }
  pairs.shuffle(rng);
  return pairs.take(6).toList();
}

// ─────────────────────────────────────────────
//  GAME ARENA PAGE
// ─────────────────────────────────────────────
class GameArenaPage extends StatefulWidget {
  const GameArenaPage({super.key});
  @override
  State<GameArenaPage> createState() => _GameArenaPageState();
}

class _GameArenaPageState extends State<GameArenaPage> {
  int xp        = 0;
  int bestScore = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final lx = await GameProgressService.getXp();
    final lb = await GameProgressService.getBestScore();
    if (!mounted) return;
    setState(() { xp = lx; bestScore = lb; });
  }

  int get level          => (xp ~/ 200) + 1;
  int get currentLevelXp => xp % 200;
  LessonDetail? get _lastLesson => LastLessonStore.instance.lastLesson;

  @override
  Widget build(BuildContext context) {
    final w      = AppSize.w(context);
    final lesson = _lastLesson;

    return StudentPageBase(
      title: 'Game Arena',
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 24),
        children: [
          if (lesson != null)
            Container(
              margin: EdgeInsets.only(bottom: w * 0.04),
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(color: kPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: kPurple.withOpacity(0.35))),
              child: Row(children: [
                const Text('📚', style: TextStyle(fontSize: 20, decoration: TextDecoration.none)),
                SizedBox(width: w * 0.025),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Games based on your last lesson', style: TextStyle(fontSize: w * 0.028, color: Colors.white54, decoration: TextDecoration.none)),
                  const SizedBox(height: 2),
                  Text(lesson.title, style: TextStyle(fontSize: w * 0.036, fontWeight: FontWeight.w700, color: Colors.white, decoration: TextDecoration.none), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${lesson.subject} · ${lesson.gradeLevel}', style: TextStyle(fontSize: w * 0.028, color: kPurple, decoration: TextDecoration.none)),
                ])),
              ]),
            )
          else
            Container(
              margin: EdgeInsets.only(bottom: w * 0.04),
              padding: EdgeInsets.all(w * 0.035),
              decoration: BoxDecoration(color: kWhite08, borderRadius: BorderRadius.circular(14), border: Border.all(color: kWhite12)),
              child: Text('💡 Complete a lesson first — games will be generated from that topic!', style: TextStyle(fontSize: w * 0.034, color: Colors.white60, decoration: TextDecoration.none)),
            ),

          // Progress card
          appCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🔥 Your Progress', style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: w * 0.03),
              Text('Level $level', style: TextStyle(fontSize: w * 0.038, color: kYellow, fontWeight: FontWeight.bold)),
              SizedBox(height: w * 0.02),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: currentLevelXp / 200, minHeight: 7, backgroundColor: kWhite12, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA56BFF)))),
              SizedBox(height: w * 0.015),
              Text('$currentLevelXp / 200 XP to next level', style: TextStyle(fontSize: w * 0.032, color: Colors.white70)),
              SizedBox(height: w * 0.035),
              Row(children: [
                Expanded(child: _miniStat(w, 'Total XP', '$xp')),
                SizedBox(width: w * 0.03),
                Expanded(child: _miniStat(w, 'Best Score', '$bestScore%')),
              ]),
            ]),
          ),

          SizedBox(height: w * 0.04),

          // Leaderboard
          appCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🏆 Leaderboard', style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: w * 0.03),
              ..._buildLeaderboard(w),
            ]),
          ),

          SizedBox(height: w * 0.05),
          Text('🎮 Choose a Game', style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(height: w * 0.035),

          _gameCard(w: w, title: 'Escape The Program', description: lesson != null ? 'Fix broken ${lesson.subject} code from "${lesson.title}".' : 'Complete a lesson first to unlock this game.', dot: kPurple, emoji: '🔓', locked: lesson == null, onTap: lesson == null ? null : () => _push(EscapeTheProgramPage(lesson: lesson))),
          SizedBox(height: w * 0.03),
          _gameCard(w: w, title: 'Guess Game', description: lesson != null ? 'Use clues to identify concepts from "${lesson.title}".' : 'Complete a lesson first.', dot: kYellow, emoji: '🎯', locked: lesson == null || lesson.quiz.isEmpty, onTap: (lesson == null || lesson.quiz.isEmpty) ? null : () => _push(GuessGamePage(lesson: lesson))),
          SizedBox(height: w * 0.03),
          _gameCard(w: w, title: 'Word Scramble', description: lesson != null ? 'Unscramble key terms from "${lesson.title}".' : 'Complete a lesson first.', dot: kGreen, emoji: '🔤', locked: lesson == null, onTap: lesson == null ? null : () => _push(WordScramblePage(lesson: lesson))),
          SizedBox(height: w * 0.03),
          _gameCard(w: w, title: 'Flash Cards', description: lesson != null ? 'Tap to flip — review concepts from "${lesson.title}".' : 'Complete a lesson first.', dot: kBlue, emoji: '🃏', locked: lesson == null || lesson.quiz.isEmpty, onTap: (lesson == null || lesson.quiz.isEmpty) ? null : () => _push(FlashCardsPage(lesson: lesson))),
          SizedBox(height: w * 0.03),
          _gameCard(w: w, title: 'Speed Quiz ⚡', description: lesson != null ? 'Answer as many questions as you can before time runs out!' : 'Complete a lesson first.', dot: kOrange, emoji: '⚡', locked: lesson == null || lesson.quiz.isEmpty, onTap: (lesson == null || lesson.quiz.isEmpty) ? null : () => _push(SpeedQuizPage(lesson: lesson))),
          SizedBox(height: w * 0.03),
          _gameCard(w: w, title: 'True or False', description: lesson != null ? 'Swipe left for False, right for True. How many can you get?' : 'Complete a lesson first.', dot: kPink, emoji: '❓', locked: lesson == null || lesson.quiz.isEmpty, onTap: (lesson == null || lesson.quiz.isEmpty) ? null : () => _push(TrueOrFalsePage(lesson: lesson))),
          SizedBox(height: w * 0.03),
          _gameCard(w: w, title: 'Memory Match', description: lesson != null ? 'Match questions to their answers. Train your memory!' : 'Complete a lesson first.', dot: kRed, emoji: '🧠', locked: lesson == null || lesson.quiz.isEmpty, onTap: (lesson == null || lesson.quiz.isEmpty) ? null : () => _push(MemoryMatchPage(lesson: lesson))),
        ],
      ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _load());
  }

  Widget _miniStat(double w, String label, String value) {
    return Container(
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(color: kWhite08, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: w * 0.048, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: w * 0.01),
        Text(label, style: TextStyle(fontSize: w * 0.03, color: Colors.white60)),
      ]),
    );
  }

  List<Widget> _buildLeaderboard(double w) {
    final entries = [('You', xp), ('Alyssa', 850), ('Mark', 720), ('Jamie', 640)]..sort((a, b) => b.$2.compareTo(a.$2));
    return entries.asMap().entries.map((e) {
      final rank = e.key + 1;
      final p    = e.value;
      return Padding(
        padding: EdgeInsets.only(bottom: w * 0.025),
        child: Row(children: [
          SizedBox(width: w * 0.07, child: Text('#$rank', style: TextStyle(fontSize: w * 0.038, color: kYellow, fontWeight: FontWeight.bold))),
          Expanded(child: Text(p.$1, style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w600, color: Colors.white))),
          Text('${p.$2} XP', style: TextStyle(fontSize: w * 0.035, color: Colors.white70)),
        ]),
      );
    }).toList();
  }

  Widget _gameCard({required double w, required String title, required String description, required Color dot, required String emoji, VoidCallback? onTap, bool locked = false}) {
    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: appCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: TextStyle(fontSize: w * 0.05, decoration: TextDecoration.none)),
            SizedBox(width: w * 0.025),
            Expanded(child: Text(title, style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w800, color: Colors.white))),
            Icon(Icons.circle, size: w * 0.02, color: dot),
          ]),
          SizedBox(height: w * 0.02),
          Text(description, style: TextStyle(fontSize: w * 0.035, color: Colors.white70, height: 1.5), maxLines: 3),
          SizedBox(height: w * 0.035),
          SizedBox(
            width: double.infinity,
            height: w * 0.115,
            child: ElevatedButton(
              onPressed: locked ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: locked ? kWhite08 : dot.withOpacity(0.25),
                disabledBackgroundColor: kWhite08,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: locked ? Colors.transparent : dot.withOpacity(0.5))),
                elevation: 0,
              ),
              child: Text(locked ? 'Locked' : '▶  Play', style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w700, color: locked ? Colors.white30 : Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RESULT SCREEN
// ─────────────────────────────────────────────
class GameResultPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final int xpEarned;
  final int correct;
  final int total;
  final VoidCallback onHome;

  const GameResultPage({super.key, required this.emoji, required this.title, required this.subtitle, required this.xpEarned, required this.correct, required this.total, required this.onHome});

  @override
  Widget build(BuildContext context) {
    final w   = AppSize.w(context);
    final pct = total > 0 ? (correct * 100 ~/ total) : 0;

    return StudentPageBase(
      title: 'Results',
      child: Padding(
        padding: EdgeInsets.all(w * 0.07),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: TextStyle(fontSize: w * 0.18, decoration: TextDecoration.none)),
          SizedBox(height: w * 0.04),
          Text(title, style: TextStyle(fontSize: w * 0.065, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center),
          SizedBox(height: w * 0.02),
          Text(subtitle, style: TextStyle(fontSize: w * 0.035, color: Colors.white70), textAlign: TextAlign.center),
          SizedBox(height: w * 0.05),
          appCard(child: Center(child: Text('+$xpEarned XP Earned!', style: TextStyle(fontSize: w * 0.05, color: kYellow, fontWeight: FontWeight.w800)))),
          SizedBox(height: w * 0.04),
          Row(children: [
            Expanded(child: _resStat(w, '$correct', 'Correct', kGreen)),
            SizedBox(width: w * 0.025),
            Expanded(child: _resStat(w, '${total - correct}', 'Wrong', kRed)),
            SizedBox(width: w * 0.025),
            Expanded(child: _resStat(w, '$pct%', 'Accuracy', kPurple)),
          ]),
          SizedBox(height: w * 0.07),
          SizedBox(
            width: double.infinity,
            height: w * 0.13,
            child: ElevatedButton(
              onPressed: onHome,
              style: ElevatedButton.styleFrom(backgroundColor: kPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: Text('Back to Arena', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _resStat(double w, String val, String lbl, Color color) {
    return appCard(child: Column(children: [
      Text(val, style: TextStyle(fontSize: w * 0.055, color: color, fontWeight: FontWeight.w800)),
      SizedBox(height: w * 0.01),
      Text(lbl, style: TextStyle(fontSize: w * 0.028, color: Colors.white60)),
    ]));
  }
}

// ═════════════════════════════════════════════
//  ESCAPE THE PROGRAM
// ═════════════════════════════════════════════

class EscapeTheProgramPage extends StatefulWidget {
  final LessonDetail lesson;
  const EscapeTheProgramPage({super.key, required this.lesson});
  @override
  State<EscapeTheProgramPage> createState() => _EscapeTheProgramPageState();
}

class _EscapeTheProgramPageState extends State<EscapeTheProgramPage> {
  late List<Map<String, dynamic>> _puzzles;
  int puzzleIdx     = 0;
  int _totalCorrect = 0;
  int _totalAnswers = 0;

  late List<String?> filled;
  late List<bool>    chipUsed;
  int?  selectedBlank;
  bool  submitted = false;
  late int secondsLeft;
  Timer? _timer;

  Map<String, dynamic> get puzzle   => _puzzles[puzzleIdx];
  List<String>         get _answers => (puzzle['answers'] as List).cast<String>();
  List<String>         get _chips   => (puzzle['chips']   as List).cast<String>();
  String               get _code    => puzzle['codeLines'] as String;
  bool get _isLastPuzzle            => puzzleIdx == _puzzles.length - 1;

  @override
  void initState() { super.initState(); _puzzles = _escapePuzzlesFromLesson(widget.lesson); _initPuzzle(); }

  void _initPuzzle() {
    filled        = List.filled(_answers.length, null);
    chipUsed      = List.filled(_chips.length, false);
    selectedBlank = null;
    submitted     = false;
    secondsLeft   = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { secondsLeft--; });
      if (secondsLeft <= 0) { t.cancel(); _submit(); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _tapBlank(int idx) { if (submitted) return; setState(() => selectedBlank = idx); }

  void _tapChip(int ci) {
    if (submitted || chipUsed[ci]) return;
    final b = selectedBlank ?? filled.indexWhere((f) => f == null);
    if (b == -1) return;
    setState(() { filled[b] = _chips[ci]; chipUsed[ci] = true; selectedBlank = null; });
  }

  void _clearBlank(int idx) {
    if (submitted) return;
    final val = filled[idx];
    if (val == null) return;
    final ci = _chips.indexOf(val);
    setState(() { filled[idx] = null; if (ci >= 0) chipUsed[ci] = false; selectedBlank = idx; });
  }

  Future<void> _submit() async {
    _timer?.cancel();
    int correct = 0;
    for (int i = 0; i < _answers.length; i++) { if (filled[i] == _answers[i]) correct++; }
    _totalCorrect += correct;
    _totalAnswers += _answers.length;
    await GameProgressService.addXp(correct * 10);
    await GameProgressService.saveBestScore(_totalAnswers > 0 ? (_totalCorrect * 100 ~/ _totalAnswers) : 0);
    if (correct > 0) {
      await XpHistory.addEntry(xp: correct * 10, reason: 'Escape The Program – ${widget.lesson.title} (Puzzle ${puzzleIdx + 1})');
    }
    setState(() => submitted = true);
  }

  void _nextPuzzle() { setState(() => puzzleIdx++); _initPuzzle(); }

  void _goToResults() {
    final finalPct = _totalAnswers > 0 ? (_totalCorrect * 100 ~/ _totalAnswers) : 0;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameResultPage(
      emoji: finalPct == 100 ? '🔓' : finalPct >= 50 ? '😅' : '😬',
      title: finalPct == 100 ? 'Escaped!' : finalPct >= 50 ? 'Almost There!' : 'Keep Practicing!',
      subtitle: finalPct == 100 ? 'Perfect — you fixed every blank!' : 'Some blanks were wrong. Review and retry.',
      xpEarned: _totalCorrect * 10, correct: _totalCorrect, total: _totalAnswers,
      onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
    )));
  }

  Color _blankColor(int idx) {
    if (!submitted) return selectedBlank == idx ? Colors.white : const Color(0xFF6C63FF);
    return filled[idx] == _answers[idx] ? kGreen : kRed;
  }

  List<_Seg> _parseSegments() {
    final segs = <_Seg>[];
    final pattern = RegExp(r'___(\d+)___');
    int last = 0;
    for (final m in pattern.allMatches(_code)) {
      if (m.start > last) segs.add(_Seg.text(_code.substring(last, m.start)));
      segs.add(_Seg.blank(int.parse(m.group(1)!)));
      last = m.end;
    }
    if (last < _code.length) segs.add(_Seg.text(_code.substring(last)));
    return segs;
  }

  @override
  Widget build(BuildContext context) {
    final w          = AppSize.w(context);
    final timerColor = secondsLeft <= 10 ? kRed : Colors.white70;
    final segs       = _parseSegments();

    return StudentPageBase(
      title: puzzle['title'] as String,
      child: ListView(padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 24), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Puzzle ${puzzleIdx + 1} of ${_puzzles.length}', style: TextStyle(fontSize: w * 0.032, color: Colors.white54, decoration: TextDecoration.none)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.015),
            decoration: BoxDecoration(color: const Color(0x33FF6B6B), borderRadius: BorderRadius.circular(999)),
            child: Text('⏱ ${secondsLeft}s', style: TextStyle(fontSize: w * 0.035, color: timerColor, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
          ),
        ]),
        SizedBox(height: w * 0.025),
        Text(puzzle['description'] as String, style: TextStyle(fontSize: w * 0.035, color: Colors.white70, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.03),
        appCard(child: Container(width: double.infinity, padding: EdgeInsets.all(w * 0.04), decoration: BoxDecoration(color: const Color(0xFF0D0D1E), borderRadius: BorderRadius.circular(10)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _buildCodeWidget(segs)))),
        SizedBox(height: w * 0.04),
        if (!submitted) Text(selectedBlank != null ? 'Blank ${selectedBlank! + 1} selected — tap a chip' : 'Tap a blank to select it, then tap an answer chip', style: TextStyle(fontSize: w * 0.032, color: Colors.white60, decoration: TextDecoration.none)),
        SizedBox(height: w * 0.025),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(_chips.length, (ci) {
          return GestureDetector(
            onTap: () => _tapChip(ci),
            child: AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: chipUsed[ci] ? 0.3 : 1.0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.02),
                decoration: BoxDecoration(color: chipUsed[ci] ? kWhite08 : const Color(0xFF1E1E3A), border: Border.all(color: chipUsed[ci] ? kWhite12 : const Color(0xFF5A54CC)), borderRadius: BorderRadius.circular(10)),
                child: Text(_chips[ci], style: TextStyle(fontFamily: 'monospace', fontSize: w * 0.033, color: chipUsed[ci] ? Colors.white60 : Colors.white, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
              ),
            ),
          );
        })),
        SizedBox(height: w * 0.05),
        if (!submitted) SizedBox(width: double.infinity, height: w * 0.13, child: ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(backgroundColor: kPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text('Check Code 🔓', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: Colors.white)))),
        if (submitted && !_isLastPuzzle) SizedBox(width: double.infinity, height: w * 0.13, child: ElevatedButton(onPressed: _nextPuzzle, style: ElevatedButton.styleFrom(backgroundColor: kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text('Next Puzzle ${puzzleIdx + 2} of ${_puzzles.length} →', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: Colors.white)))),
        if (submitted && _isLastPuzzle) SizedBox(width: double.infinity, height: w * 0.13, child: ElevatedButton(onPressed: _goToResults, style: ElevatedButton.styleFrom(backgroundColor: kYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text('🏁  See Results', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: Colors.black)))),
      ]),
    );
  }

  Widget _buildCodeWidget(List<_Seg> segs) {
    const keywords = {'function', 'let', 'const', 'var', 'for', 'of', 'in', 'if', 'else', 'return', 'class', 'new', 'this', 'import', 'export', 'def', 'while', 'True', 'False', 'None', 'and', 'or', 'not', 'pass', 'break', 'continue'};
    final spans = <InlineSpan>[];
    for (final seg in segs) {
      if (!seg.isBlank) {
        Color c = Colors.white;
        if (keywords.contains(seg.text.trim())) c = const Color(0xFFA78BFA);
        if (RegExp(r'^\d+$').hasMatch(seg.text.trim())) c = const Color(0xFFFBBF24);
        if (seg.text.trim().startsWith('//') || seg.text.trim().startsWith('#')) c = const Color(0xFF555580);
        spans.add(TextSpan(text: seg.text, style: TextStyle(color: c, decoration: TextDecoration.none)));
      } else {
        final bi  = seg.blankIndex;
        final val = filled[bi];
        final bc  = _blankColor(bi);
        spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: GestureDetector(
          onTap: () => val != null ? _clearBlank(bi) : _tapBlank(bi),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: bc.withOpacity(0.18), border: Border.all(color: bc, width: 1.5), borderRadius: BorderRadius.circular(7)),
            child: Text(val ?? '  ?  ', style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: bc, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
          ),
        )));
      }
    }
    return RichText(text: TextSpan(style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.75, decoration: TextDecoration.none), children: spans));
  }
}

class _Seg {
  final String text;
  final bool   isBlank;
  final int    blankIndex;
  const _Seg.text(this.text)        : isBlank = false, blankIndex = -1;
  const _Seg.blank(this.blankIndex) : isBlank = true,  text = '';
}

// ═════════════════════════════════════════════
//  GUESS GAME
// ═════════════════════════════════════════════

class GuessGamePage extends StatefulWidget {
  final LessonDetail lesson;
  const GuessGamePage({super.key, required this.lesson});
  @override
  State<GuessGamePage> createState() => _GuessGamePageState();
}

class _GuessGamePageState extends State<GuessGamePage> {
  late List<Map<String, dynamic>> _questions;
  int  qIdx     = 0;
  int  clueIdx  = 0;
  int? chosen;
  int  correct  = 0;
  bool answered = false;

  Map<String, dynamic> get q            => _questions[qIdx];
  List<String>         get _clues       => (q['clues']   as List).cast<String>();
  List<String>         get _options     => (q['options'] as List).cast<String>();
  int                  get _answerIndex => q['answerIndex'] as int;
  String               get _concept     => q['concept']     as String;
  int                  get total        => _questions.length;

  @override
  void initState() { super.initState(); _questions = _guessQuestionsFromLesson(widget.lesson); }

  void _revealClue() { if (clueIdx < _clues.length - 1) setState(() => clueIdx++); }

  void _answer(int idx) {
    if (answered) return;
    setState(() { chosen = idx; answered = true; if (idx == _answerIndex) correct++; });
  }

  void _next() {
    if (qIdx + 1 >= total) { _finish(); return; }
    setState(() { qIdx++; clueIdx = 0; chosen = null; answered = false; });
  }

  Future<void> _finish() async {
    final pct    = (correct * 100 ~/ total);
    final earned = correct * 15;
    await GameProgressService.addXp(earned);
    await GameProgressService.saveBestScore(pct);
    if (earned > 0) await XpHistory.addEntry(xp: earned, reason: 'Guess Game – ${widget.lesson.title} ($correct/$total correct)');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameResultPage(
      emoji: pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '💪',
      title: pct >= 80 ? 'Genius!' : pct >= 60 ? 'Good Job!' : 'Keep Practicing!',
      subtitle: pct >= 80 ? 'You identified every concept perfectly.' : 'Review the concepts you missed and try again.',
      xpEarned: earned, correct: correct, total: total,
      onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final w         = AppSize.w(context);
    final isCorrect = answered && chosen == _answerIndex;
    final progress  = (qIdx + 1) / total;

    return StudentPageBase(
      title: 'Guess Game',
      child: Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.045), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: kWhite12, valueColor: const AlwaysStoppedAnimation<Color>(kPurple))),
          SizedBox(height: w * 0.015),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Question ${qIdx + 1} of $total', style: TextStyle(fontSize: w * 0.032, color: Colors.white60, decoration: TextDecoration.none)),
            Text('$correct / $total correct', style: TextStyle(fontSize: w * 0.032, color: kYellow, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
          ]),
        ])),
        SizedBox(height: w * 0.02),
        Expanded(child: ListView(padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.045, w * 0.05), children: [
          appCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.01), decoration: BoxDecoration(color: const Color(0x33FFCC29), borderRadius: BorderRadius.circular(999)), child: Text('Clue ${clueIdx + 1} of ${_clues.length}', style: TextStyle(fontSize: w * 0.03, color: kYellow, fontWeight: FontWeight.w700, decoration: TextDecoration.none))),
            SizedBox(height: w * 0.025),
            ...List.generate(clueIdx + 1, (i) => Padding(padding: EdgeInsets.only(bottom: i < clueIdx ? w * 0.02 : 0), child: Text(_clues[i], style: TextStyle(fontSize: w * 0.038, color: i == clueIdx ? Colors.white : Colors.white60, fontWeight: FontWeight.w600, height: 1.4, decoration: TextDecoration.none)))),
            if (!answered && clueIdx < _clues.length - 1) ...[
              SizedBox(height: w * 0.035),
              SizedBox(width: double.infinity, child: TextButton(onPressed: _revealClue, style: TextButton.styleFrom(backgroundColor: const Color(0x26FFCC29), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('💡 Reveal next clue', style: TextStyle(fontSize: w * 0.033, color: kYellow, fontWeight: FontWeight.w600, decoration: TextDecoration.none)))),
            ],
          ])),
          SizedBox(height: w * 0.035),
          Text('What is the correct answer?', style: TextStyle(fontSize: w * 0.035, color: Colors.white70, decoration: TextDecoration.none)),
          SizedBox(height: w * 0.025),
          ...List.generate(_options.length, (i) {
            Color? borderCol; Color textCol = Colors.white; Color bgCol = kWhite08;
            if (answered) {
              if (i == _answerIndex) { borderCol = kGreen; bgCol = const Color(0x2043E97B); textCol = kGreen; }
              else if (i == chosen && chosen != _answerIndex) { borderCol = kRed; bgCol = const Color(0x20FF6B6B); textCol = kRed; }
            }
            return Padding(padding: EdgeInsets.only(bottom: w * 0.025), child: GestureDetector(onTap: () => _answer(i), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: EdgeInsets.all(w * 0.035), decoration: BoxDecoration(color: bgCol, border: Border.all(color: borderCol ?? kWhite12, width: borderCol != null ? 1.5 : 0.5), borderRadius: BorderRadius.circular(14)), child: Row(children: [
              Container(width: w * 0.07, height: w * 0.07, alignment: Alignment.center, decoration: BoxDecoration(color: kWhite12, borderRadius: BorderRadius.circular(8)), child: Text(String.fromCharCode(65 + i), style: TextStyle(fontSize: w * 0.033, color: textCol, fontWeight: FontWeight.w700, decoration: TextDecoration.none))),
              SizedBox(width: w * 0.03),
              Expanded(child: Text(_options[i], style: TextStyle(fontSize: w * 0.038, color: textCol, fontWeight: FontWeight.w600, decoration: TextDecoration.none))),
              if (answered && i == _answerIndex) Icon(Icons.check_circle_outline, color: kGreen, size: w * 0.05),
              if (answered && i == chosen && chosen != _answerIndex) Icon(Icons.cancel_outlined, color: kRed, size: w * 0.05),
            ]))));
          }),
          if (answered) ...[
            appCard(child: Text(isCorrect ? '✅ Correct! The answer is "$_concept".' : '❌ Not quite. The answer is "$_concept".', style: TextStyle(fontSize: w * 0.036, color: isCorrect ? kGreen : kRed, decoration: TextDecoration.none))),
            SizedBox(height: w * 0.035),
            SizedBox(width: double.infinity, height: w * 0.13, child: ElevatedButton(onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: qIdx + 1 >= total ? kYellow : kPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text(qIdx + 1 >= total ? '🏁  See Results' : 'Next →', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: qIdx + 1 >= total ? Colors.black : Colors.white, decoration: TextDecoration.none)))),
          ],
        ])),
      ]),
    );
  }
}

// ═════════════════════════════════════════════
//  WORD SCRAMBLE
// ═════════════════════════════════════════════

class WordScramblePage extends StatefulWidget {
  final LessonDetail lesson;
  const WordScramblePage({super.key, required this.lesson});
  @override
  State<WordScramblePage> createState() => _WordScramblePageState();
}

class _WordScramblePageState extends State<WordScramblePage> {
  late List<Map<String, dynamic>> _words;
  int     _idx      = 0;
  int     _score    = 0;
  String  _input    = '';
  bool    _answered = false;
  bool    _correct  = false;
  final   _ctrl     = TextEditingController();

  @override
  void initState() { super.initState(); _words = _scrambleWordsFromLesson(widget.lesson); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Map<String, dynamic> get _current => _words[_idx];
  bool get _isLast => _idx == _words.length - 1;

  void _check() {
    if (_answered) return;
    final ok = _input.trim().toLowerCase() == (_current['word'] as String).toLowerCase();
    setState(() { _answered = true; _correct = ok; if (ok) _score++; });
  }

  Future<void> _next() async {
    if (_isLast) {
      final earned = _score * 12;
      await GameProgressService.addXp(earned);
      await GameProgressService.saveBestScore(_score * 100 ~/ _words.length);
      if (earned > 0) await XpHistory.addEntry(xp: earned, reason: 'Word Scramble – ${widget.lesson.title} ($_score/${_words.length} correct)');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameResultPage(
        emoji: _score == _words.length ? '🏆' : _score >= _words.length ~/ 2 ? '👍' : '💪',
        title: _score == _words.length ? 'Perfect!' : _score >= _words.length ~/ 2 ? 'Good Job!' : 'Keep Practicing!',
        subtitle: 'You unscrambled $_score out of ${_words.length} words.',
        xpEarned: earned, correct: _score, total: _words.length,
        onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
      )));
      return;
    }
    _ctrl.clear();
    setState(() { _idx++; _input = ''; _answered = false; _correct = false; });
  }

  @override
  Widget build(BuildContext context) {
    final w         = AppSize.w(context);
    final scrambled = _current['scrambled'] as String;
    final answer    = _current['word']      as String;

    return StudentPageBase(
      title: 'Word Scramble',
      child: ListView(padding: EdgeInsets.fromLTRB(w * 0.045, 16, w * 0.045, 24), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Word ${_idx + 1} of ${_words.length}', style: TextStyle(fontSize: w * 0.032, color: Colors.white54, decoration: TextDecoration.none)),
          Text('$_score correct', style: TextStyle(fontSize: w * 0.032, color: kGreen, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        ]),
        SizedBox(height: w * 0.02),
        ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: (_idx + 1) / _words.length, minHeight: 6, backgroundColor: kWhite12, valueColor: const AlwaysStoppedAnimation<Color>(kGreen))),
        SizedBox(height: w * 0.05),
        appCard(child: Column(children: [
          Text('Unscramble this word:', style: TextStyle(fontSize: w * 0.035, color: Colors.white60, decoration: TextDecoration.none)),
          SizedBox(height: w * 0.04),
          Wrap(spacing: w * 0.02, children: scrambled.split('').map((ch) => Container(
            width: w * 0.1, height: w * 0.1, alignment: Alignment.center,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: kGreen.withOpacity(0.4))),
            child: Text(ch.toUpperCase(), style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w900, color: kGreen, decoration: TextDecoration.none)),
          )).toList()),
          SizedBox(height: w * 0.02),
          Text('${answer.length} letters', style: TextStyle(fontSize: w * 0.03, color: Colors.white38, decoration: TextDecoration.none)),
        ])),
        SizedBox(height: w * 0.04),
        if (!_answered)
          Container(
            decoration: BoxDecoration(color: kWhite08, borderRadius: BorderRadius.circular(14), border: Border.all(color: kGreen.withOpacity(0.4))),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _input = v),
              onSubmitted: (_) => _check(),
              style: TextStyle(color: Colors.white, fontSize: w * 0.04, decoration: TextDecoration.none),
              decoration: InputDecoration(hintText: 'Type your answer...', hintStyle: TextStyle(color: Colors.white38, fontSize: w * 0.038), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.04)),
            ),
          ),
        if (_answered)
          appCard(child: Column(children: [
            Text(_correct ? '✅ Correct!' : '❌ Wrong!', style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: _correct ? kGreen : kRed, decoration: TextDecoration.none)),
            if (!_correct) ...[SizedBox(height: w * 0.02), Text('The answer was: ${answer.toUpperCase()}', style: TextStyle(fontSize: w * 0.038, color: Colors.white70, decoration: TextDecoration.none))],
          ])),
        SizedBox(height: w * 0.04),
        if (!_answered) SizedBox(width: double.infinity, height: w * 0.13, child: ElevatedButton(onPressed: _input.trim().isEmpty ? null : _check, style: ElevatedButton.styleFrom(backgroundColor: kGreen, disabledBackgroundColor: kWhite08, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text('Check ✓', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: Colors.white, decoration: TextDecoration.none)))),
        if (_answered) SizedBox(width: double.infinity, height: w * 0.13, child: ElevatedButton(onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: _isLast ? kYellow : kPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text(_isLast ? '🏁  See Results' : 'Next →', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: _isLast ? Colors.black : Colors.white, decoration: TextDecoration.none)))),
      ]),
    );
  }
}

// ═════════════════════════════════════════════
//  FLASH CARDS
// ═════════════════════════════════════════════

class FlashCardsPage extends StatefulWidget {
  final LessonDetail lesson;
  const FlashCardsPage({super.key, required this.lesson});
  @override
  State<FlashCardsPage> createState() => _FlashCardsPageState();
}

class _FlashCardsPageState extends State<FlashCardsPage> with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _cards;
  int  _idx     = 0;
  bool _flipped = false;
  int  _known   = 0;

  late AnimationController _flipCtrl;
  late Animation<double>   _flipAnim;

  @override
  void initState() {
    super.initState();
    _cards = _flashCardsFromLesson(widget.lesson);
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _flipCtrl.dispose(); super.dispose(); }

  Map<String, dynamic> get _current => _cards[_idx];
  bool get _isLast => _idx == _cards.length - 1;

  void _flip() {
    if (_flipped) { _flipCtrl.reverse(); } else { _flipCtrl.forward(); }
    setState(() => _flipped = !_flipped);
  }

  void _mark(bool known) {
    if (known) _known++;
    if (_isLast) { _finish(); return; }
    _flipCtrl.reset();
    setState(() { _idx++; _flipped = false; });
  }

  Future<void> _finish() async {
    final earned = _known * 8;
    await GameProgressService.addXp(earned);
    await GameProgressService.saveBestScore(_known * 100 ~/ _cards.length);
    if (earned > 0) await XpHistory.addEntry(xp: earned, reason: 'Flash Cards – ${widget.lesson.title} ($_known/${_cards.length} known)');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameResultPage(
      emoji: _known == _cards.length ? '🧠' : _known >= _cards.length ~/ 2 ? '👍' : '📖',
      title: _known == _cards.length ? 'Mastered!' : _known >= _cards.length ~/ 2 ? 'Good Progress!' : 'Keep Reviewing!',
      subtitle: 'You knew $_known out of ${_cards.length} cards.',
      xpEarned: earned, correct: _known, total: _cards.length,
      onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);
    return StudentPageBase(
      title: 'Flash Cards',
      child: Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.045), child: Column(children: [
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: (_idx + 1) / _cards.length, minHeight: 6, backgroundColor: kWhite12, valueColor: const AlwaysStoppedAnimation<Color>(kBlue))),
          SizedBox(height: w * 0.02),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Card ${_idx + 1} of ${_cards.length}', style: TextStyle(fontSize: w * 0.032, color: Colors.white54, decoration: TextDecoration.none)),
            Text('$_known known', style: TextStyle(fontSize: w * 0.032, color: kGreen, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
          ]),
        ])),
        SizedBox(height: w * 0.06),
        Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.045), child: GestureDetector(
          onTap: _flip,
          child: AnimatedBuilder(animation: _flipAnim, builder: (_, __) {
            final angle    = _flipAnim.value * 3.14159;
            final showBack = _flipAnim.value > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: showBack ? [const Color(0xFF0F3460), const Color(0xFF1A1A5E)] : [const Color(0xFF1A1A3E), const Color(0xFF0D0B2E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: showBack ? kBlue.withOpacity(0.5) : kPurple.withOpacity(0.4), width: 1.5),
                  boxShadow: [BoxShadow(color: (showBack ? kBlue : kPurple).withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(showBack ? 3.14159 : 0),
                  child: Padding(padding: EdgeInsets.all(w * 0.07), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(showBack ? 'ANSWER' : 'QUESTION', style: TextStyle(fontSize: w * 0.028, color: showBack ? kBlue : kPurple, fontWeight: FontWeight.w800, letterSpacing: 1.5, decoration: TextDecoration.none)),
                    SizedBox(height: w * 0.04),
                    Text(showBack ? _current['back'] as String : _current['front'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4, decoration: TextDecoration.none)),
                    SizedBox(height: w * 0.05),
                    Text(showBack ? '' : 'Tap to reveal answer', style: TextStyle(fontSize: w * 0.03, color: Colors.white24, decoration: TextDecoration.none)),
                  ])),
                ),
              ),
            );
          }),
        ))),
        SizedBox(height: w * 0.05),
        if (_flipped)
          Padding(padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.045, w * 0.05), child: Row(children: [
            Expanded(child: SizedBox(height: w * 0.13, child: ElevatedButton(onPressed: () => _mark(false), style: ElevatedButton.styleFrom(backgroundColor: kRed.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: kRed.withOpacity(0.5))), elevation: 0), child: Text("❌  Didn't Know", style: TextStyle(fontSize: w * 0.035, fontWeight: FontWeight.w700, color: kRed, decoration: TextDecoration.none))))),
            SizedBox(width: w * 0.03),
            Expanded(child: SizedBox(height: w * 0.13, child: ElevatedButton(onPressed: () => _mark(true), style: ElevatedButton.styleFrom(backgroundColor: kGreen.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: kGreen.withOpacity(0.5))), elevation: 0), child: Text('✅  Got It!', style: TextStyle(fontSize: w * 0.035, fontWeight: FontWeight.w700, color: kGreen, decoration: TextDecoration.none))))),
          ]))
        else
          Padding(padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.045, w * 0.05), child: Text('Tap the card to flip it', textAlign: TextAlign.center, style: TextStyle(fontSize: w * 0.035, color: Colors.white38, decoration: TextDecoration.none))),
      ]),
    );
  }
}

// ═════════════════════════════════════════════
//  SPEED QUIZ ⚡
//  Rapid-fire: 8 questions, 7 seconds each.
//  No skipping — answer or time runs out.
// ═════════════════════════════════════════════

class SpeedQuizPage extends StatefulWidget {
  final LessonDetail lesson;
  const SpeedQuizPage({super.key, required this.lesson});
  @override
  State<SpeedQuizPage> createState() => _SpeedQuizPageState();
}

class _SpeedQuizPageState extends State<SpeedQuizPage> with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _questions;
  int   _idx      = 0;
  int   _correct  = 0;
  int   _secs     = 7;
  int?  _picked;
  bool  _answered = false;
  Timer? _timer;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _questions = _speedQuizFromLesson(widget.lesson);
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _startTimer();
  }

  @override
  void dispose() { _timer?.cancel(); _shakeCtrl.dispose(); super.dispose(); }

  Map<String, dynamic> get _q           => _questions[_idx];
  List<String>         get _opts        => (_q['options'] as List).cast<String>();
  int                  get _answerIndex => _q['answerIndex'] as int;
  bool                 get _isLast      => _idx == _questions.length - 1;

  void _startTimer() {
    _timer?.cancel();
    _secs = 7;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secs--);
      if (_secs <= 0) { t.cancel(); _timeout(); }
    });
  }

  void _timeout() {
    if (_answered) return;
    HapticFeedback.heavyImpact();
    _shakeCtrl.forward(from: 0);
    setState(() { _answered = true; _picked = null; });
    Future.delayed(const Duration(milliseconds: 1200), _advance);
  }

  void _pick(int i) {
    if (_answered) return;
    _timer?.cancel();
    HapticFeedback.lightImpact();
    setState(() { _picked = i; _answered = true; if (i == _answerIndex) _correct++; });
    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_isLast) { _finish(); return; }
    setState(() { _idx++; _answered = false; _picked = null; });
    _startTimer();
  }

  Future<void> _finish() async {
    final pct    = (_correct * 100 ~/ _questions.length);
    final earned = _correct * 20;
    await GameProgressService.addXp(earned);
    await GameProgressService.saveBestScore(pct);
    if (earned > 0) await XpHistory.addEntry(xp: earned, reason: 'Speed Quiz – ${widget.lesson.title} ($_correct/${_questions.length} correct)');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameResultPage(
      emoji: pct >= 80 ? '⚡' : pct >= 50 ? '🔥' : '💨',
      title: pct >= 80 ? 'Lightning Fast!' : pct >= 50 ? 'Hot Streak!' : 'Too Slow!',
      subtitle: 'You answered $_correct out of ${_questions.length} correctly.',
      xpEarned: earned, correct: _correct, total: _questions.length,
      onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final w         = AppSize.w(context);
    final timerFrac = _secs / 7;
    final timerCol  = _secs <= 2 ? kRed : _secs <= 4 ? kOrange : kGreen;

    return StudentPageBase(
      title: 'Speed Quiz ⚡',
      child: Padding(padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 24), child: Column(children: [
        // Timer bar
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(999), child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: timerFrac),
            duration: const Duration(milliseconds: 300),
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 10, backgroundColor: kWhite12, valueColor: AlwaysStoppedAnimation<Color>(timerCol)),
          ))),
          SizedBox(width: w * 0.03),
          AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 200), style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w900, color: timerCol, decoration: TextDecoration.none), child: Text('$_secs')),
        ]),
        SizedBox(height: w * 0.02),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Q${_idx + 1} of ${_questions.length}', style: TextStyle(fontSize: w * 0.032, color: Colors.white54, decoration: TextDecoration.none)),
          Text('$_correct correct ⚡', style: TextStyle(fontSize: w * 0.032, color: kOrange, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        ]),
        SizedBox(height: w * 0.04),

        // Question
        AnimatedBuilder(animation: _shakeAnim, builder: (_, child) {
          final offset = _shakeAnim.value == 0 ? 0.0 : (2 * (_shakeAnim.value * 10 % 2) - 1) * 6 * (1 - _shakeAnim.value);
          return Transform.translate(offset: Offset(offset, 0), child: child);
        }, child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(w * 0.05),
          decoration: BoxDecoration(
            color: kWhite08,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _answered && _picked == null ? kRed.withOpacity(0.5) : kOrange.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: kOrange.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Text(_q['question'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4, decoration: TextDecoration.none)),
        )),

        SizedBox(height: w * 0.04),

        // Options grid
        Expanded(child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: w * 0.03,
          mainAxisSpacing: w * 0.03,
          childAspectRatio: 1.6,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(_opts.length > 4 ? 4 : _opts.length, (i) {
            Color bg = kWhite08; Color border = Colors.white12; Color text = Colors.white;
            if (_answered) {
              if (i == _answerIndex) { bg = kGreen.withOpacity(0.2); border = kGreen; text = kGreen; }
              else if (i == _picked) { bg = kRed.withOpacity(0.2); border = kRed; text = kRed; }
            }
            return GestureDetector(
              onTap: () => _pick(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1.5)),
                alignment: Alignment.center,
                padding: EdgeInsets.all(w * 0.025),
                child: Text(_opts[i], textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: w * 0.034, fontWeight: FontWeight.w700, color: text, decoration: TextDecoration.none)),
              ),
            );
          }),
        )),

        if (_answered && _picked == null)
          Padding(padding: EdgeInsets.only(bottom: w * 0.03), child: Text("⏰ Time's up! The answer was: ${_opts[_answerIndex]}", textAlign: TextAlign.center, style: TextStyle(fontSize: w * 0.034, color: kRed, fontWeight: FontWeight.w600, decoration: TextDecoration.none))),
      ])),
    );
  }
}

// ═════════════════════════════════════════════
//  TRUE OR FALSE
//  Swipe right = True, left = False.
//  Tap buttons work too.
// ═════════════════════════════════════════════

class TrueOrFalsePage extends StatefulWidget {
  final LessonDetail lesson;
  const TrueOrFalsePage({super.key, required this.lesson});
  @override
  State<TrueOrFalsePage> createState() => _TrueOrFalsePageState();
}

class _TrueOrFalsePageState extends State<TrueOrFalsePage> with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _cards;
  int    _idx     = 0;
  int    _correct = 0;
  bool   _answered= false;
  bool?  _userAns;

  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  double _dragX = 0;

  @override
  void initState() {
    super.initState();
    _cards = _trueFalseFromLesson(widget.lesson);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(2, 0)).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  Map<String, dynamic> get _c      => _cards[_idx];
  bool                 get _isLast => _idx == _cards.length - 1;

  Future<void> _answer(bool userSaysTrue) async {
    if (_answered) return;
    final correct = (userSaysTrue == (_c['isTrue'] as bool));
    HapticFeedback.lightImpact();
    setState(() { _answered = true; _userAns = userSaysTrue; if (correct) _correct++; });
    // Slide card out
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset(userSaysTrue ? 1.5 : -1.5, 0)).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));
    await Future.delayed(const Duration(milliseconds: 600));
    await _slideCtrl.forward();
    if (_isLast) { _finish(); return; }
    _slideCtrl.reset();
    setState(() { _idx++; _answered = false; _userAns = null; _dragX = 0; });
  }

  Future<void> _finish() async {
    final pct    = (_correct * 100 ~/ _cards.length);
    final earned = _correct * 10;
    await GameProgressService.addXp(earned);
    await GameProgressService.saveBestScore(pct);
    if (earned > 0) await XpHistory.addEntry(xp: earned, reason: 'True or False – ${widget.lesson.title} ($_correct/${_cards.length} correct)');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameResultPage(
      emoji: pct >= 80 ? '✅' : pct >= 50 ? '🤔' : '❌',
      title: pct >= 80 ? 'Sharp Mind!' : pct >= 50 ? 'Not Bad!' : 'Keep Learning!',
      subtitle: 'You got $_correct out of ${_cards.length} correct.',
      xpEarned: earned, correct: _correct, total: _cards.length,
      onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final w        = AppSize.w(context);
    final dragFrac = (_dragX / 150).clamp(-1.0, 1.0);
    final tint     = dragFrac > 0.2 ? kGreen : dragFrac < -0.2 ? kRed : Colors.transparent;

    return StudentPageBase(
      title: 'True or False',
      child: Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.045), child: Column(children: [
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: (_idx + 1) / _cards.length, minHeight: 6, backgroundColor: kWhite12, valueColor: const AlwaysStoppedAnimation<Color>(kPink))),
          SizedBox(height: w * 0.02),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${_idx + 1} of ${_cards.length}', style: TextStyle(fontSize: w * 0.032, color: Colors.white54, decoration: TextDecoration.none)),
            Text('$_correct correct', style: TextStyle(fontSize: w * 0.032, color: kGreen, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
          ]),
        ])),
        SizedBox(height: w * 0.04),

        // Swipe hint labels
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.08), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('← FALSE', style: TextStyle(fontSize: w * 0.032, color: _dragX < -30 ? kRed : Colors.white24, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
          Text('TRUE →', style: TextStyle(fontSize: w * 0.032, color: _dragX > 30 ? kGreen : Colors.white24, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
        ])),
        SizedBox(height: w * 0.03),

        // Swipeable card
        Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.06), child: GestureDetector(
          onHorizontalDragUpdate: _answered ? null : (d) => setState(() => _dragX += d.delta.dx),
          onHorizontalDragEnd: _answered ? null : (d) {
            if (_dragX > 80) _answer(true);
            else if (_dragX < -80) _answer(false);
            else setState(() => _dragX = 0);
          },
          child: SlideTransition(position: _slideAnim, child: Transform.rotate(
            angle: (_dragX / 800),
            child: Transform.translate(offset: Offset(_dragX, 0), child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPink.withOpacity(0.15), kPurple.withOpacity(0.15)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: tint == Colors.transparent ? kPink.withOpacity(0.3) : tint.withOpacity(0.7), width: 2),
                boxShadow: [BoxShadow(color: (tint == Colors.transparent ? kPink : tint).withOpacity(0.2), blurRadius: 30)],
              ),
              child: Stack(children: [
                // Tint overlay
                if (tint != Colors.transparent)
                  Positioned.fill(child: Container(decoration: BoxDecoration(color: tint.withOpacity(0.08), borderRadius: BorderRadius.circular(26)))),
                Padding(padding: EdgeInsets.all(w * 0.07), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.015), decoration: BoxDecoration(color: kPink.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text('TRUE or FALSE?', style: TextStyle(fontSize: w * 0.028, color: kPink, fontWeight: FontWeight.w800, letterSpacing: 1.2, decoration: TextDecoration.none))),
                  SizedBox(height: w * 0.06),
                  Text(_c['statement'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w700, color: Colors.white, height: 1.5, decoration: TextDecoration.none)),
                  SizedBox(height: w * 0.06),
                  if (_answered)
                    Text(
                      (_userAns == (_c['isTrue'] as bool)) ? '✅ Correct!' : '❌ Wrong! It was ${(_c['isTrue'] as bool) ? "TRUE" : "FALSE"}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w800, color: (_userAns == (_c['isTrue'] as bool)) ? kGreen : kRed, decoration: TextDecoration.none),
                    )
                  else
                    Text('Swipe right for TRUE, left for FALSE', style: TextStyle(fontSize: w * 0.03, color: Colors.white24, decoration: TextDecoration.none)),
                ])),
              ]),
            )),
          )),
        ))),

        // Tap buttons
        if (!_answered)
          Padding(padding: EdgeInsets.fromLTRB(w * 0.045, w * 0.04, w * 0.045, w * 0.05), child: Row(children: [
            Expanded(child: SizedBox(height: w * 0.14, child: ElevatedButton(onPressed: () => _answer(false), style: ElevatedButton.styleFrom(backgroundColor: kRed.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kRed.withOpacity(0.5))), elevation: 0), child: Text('❌  FALSE', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w800, color: kRed, decoration: TextDecoration.none))))),
            SizedBox(width: w * 0.03),
            Expanded(child: SizedBox(height: w * 0.14, child: ElevatedButton(onPressed: () => _answer(true), style: ElevatedButton.styleFrom(backgroundColor: kGreen.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kGreen.withOpacity(0.5))), elevation: 0), child: Text('✅  TRUE', style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w800, color: kGreen, decoration: TextDecoration.none))))),
          ]))
        else
          SizedBox(height: w * 0.19),
      ]),
    );
  }
}

// ═════════════════════════════════════════════
//  MEMORY MATCH
//  Flip pairs of cards — match question to answer.
//  6 pairs = 12 cards on a grid.
// ═════════════════════════════════════════════

class MemoryMatchPage extends StatefulWidget {
  final LessonDetail lesson;
  const MemoryMatchPage({super.key, required this.lesson});
  @override
  State<MemoryMatchPage> createState() => _MemoryMatchPageState();
}

class _MemoryCard {
  final int    id;
  final String text;
  final bool   isQuestion;
  bool flipped  = false;
  bool matched  = false;

  _MemoryCard({required this.id, required this.text, required this.isQuestion});
}

class _MemoryMatchPageState extends State<MemoryMatchPage> {
  late List<_MemoryCard> _cards;
  int?  _firstIdx;
  bool  _checking = false;
  int   _moves    = 0;
  int   _matched  = 0;
  late  Stopwatch _watch;
  late  int _totalPairs;

  @override
  void initState() {
    super.initState();
    final pairs = _memoryPairsFromLesson(widget.lesson);
    _totalPairs = pairs.length;
    final deck  = <_MemoryCard>[];
    for (int i = 0; i < pairs.length; i++) {
      deck.add(_MemoryCard(id: i, text: pairs[i]['q'] as String, isQuestion: true));
      deck.add(_MemoryCard(id: i, text: pairs[i]['a'] as String, isQuestion: false));
    }
    deck.shuffle(Random());
    _cards = deck;
    _watch = Stopwatch()..start();
  }

  void _tap(int idx) {
    if (_checking) return;
    final card = _cards[idx];
    if (card.flipped || card.matched) return;

    setState(() => card.flipped = true);

    if (_firstIdx == null) {
      _firstIdx = idx;
      return;
    }

    _moves++;
    final first = _cards[_firstIdx!];
    _firstIdx = null;

    if (first.id == card.id && first.isQuestion != card.isQuestion) {
      // Match!
      HapticFeedback.lightImpact();
      setState(() { first.matched = true; card.matched = true; _matched++; });
      if (_matched == _totalPairs) _finish();
    } else {
      // No match — flip back after delay
      _checking = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() { first.flipped = false; card.flipped = false; _checking = false; });
      });
    }
  }

  Future<void> _finish() async {
    _watch.stop();
    final secs   = _watch.elapsed.inSeconds;
    final bonus  = (secs < 30) ? 20 : (secs < 60) ? 10 : 0;
    final earned = 40 + bonus; // base + speed bonus
    await GameProgressService.addXp(earned);
    await GameProgressService.saveBestScore(100);
    await XpHistory.addEntry(xp: earned, reason: 'Memory Match – ${widget.lesson.title} (${_moves} moves, ${secs}s)');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameResultPage(
      emoji: secs < 30 ? '🧠' : secs < 60 ? '👍' : '🐢',
      title: secs < 30 ? 'Memory Master!' : secs < 60 ? 'Well Done!' : 'You Got There!',
      subtitle: 'Completed in $_moves moves and ${secs}s.${bonus > 0 ? ' +$bonus speed bonus!' : ''}',
      xpEarned: earned, correct: _totalPairs, total: _totalPairs,
      onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final w       = AppSize.w(context);
    final cols    = _totalPairs <= 4 ? 2 : 3;
    final matched = _matched;

    return StudentPageBase(
      title: 'Memory Match',
      child: Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.045), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statChip(w, '🧩', '$matched/$_totalPairs', 'Matched'),
          _statChip(w, '🔄', '$_moves', 'Moves'),
          _statChip(w, '🧠', '${(_matched * 100 ~/ _totalPairs)}%', 'Progress'),
        ])),
        SizedBox(height: w * 0.04),
        Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.045), child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: w * 0.025,
            mainAxisSpacing: w * 0.025,
            childAspectRatio: 0.85,
          ),
          itemCount: _cards.length,
          itemBuilder: (_, i) {
            final card = _cards[i];
            return GestureDetector(
              onTap: () => _tap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: card.matched
                      ? kGreen.withOpacity(0.15)
                      : card.flipped
                          ? (card.isQuestion ? kPurple.withOpacity(0.2) : kBlue.withOpacity(0.2))
                          : kWhite08,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: card.matched
                        ? kGreen.withOpacity(0.6)
                        : card.flipped
                            ? (card.isQuestion ? kPurple.withOpacity(0.7) : kBlue.withOpacity(0.7))
                            : Colors.white12,
                    width: 1.5,
                  ),
                  boxShadow: card.flipped || card.matched
                      ? [BoxShadow(color: (card.matched ? kGreen : card.isQuestion ? kPurple : kBlue).withOpacity(0.2), blurRadius: 12)]
                      : null,
                ),
                child: card.flipped || card.matched
                    ? Padding(
                        padding: EdgeInsets.all(w * 0.025),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(card.isQuestion ? '❓' : '💡', style: TextStyle(fontSize: w * 0.04, decoration: TextDecoration.none)),
                          SizedBox(height: w * 0.015),
                          Text(card.text, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: w * 0.028, color: Colors.white, fontWeight: FontWeight.w600, height: 1.3, decoration: TextDecoration.none)),
                        ]),
                      )
                    : Center(child: Text('🃏', style: TextStyle(fontSize: w * 0.06, decoration: TextDecoration.none))),
              ),
            );
          },
        ))),
        SizedBox(height: w * 0.03),
      ]),
    );
  }

  Widget _statChip(double w, String icon, String val, String lbl) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
      decoration: BoxDecoration(color: kWhite08, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text('$icon $val', style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w800, color: Colors.white, decoration: TextDecoration.none)),
        Text(lbl, style: TextStyle(fontSize: w * 0.026, color: Colors.white38, decoration: TextDecoration.none)),
      ]),
    );
  }
}