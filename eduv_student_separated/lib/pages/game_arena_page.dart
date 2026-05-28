import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  SHARED THEME CONSTANTS
// ─────────────────────────────────────────────
const kBg       = Color(0xFF1A1A2E);
const kBg2      = Color(0xFF16213E);
const kCard     = Color(0xFF0F3460);
const kPurple   = Color(0xFFB04CFF);
const kYellow   = Color(0xFFFFCC29);
const kBlue     = Color(0xFF3657C9);
const kGreen    = Color(0xFF43E97B);
const kRed      = Color(0xFFFF6B6B);
const kWhite70  = Color(0xB3FFFFFF);
const kWhite60  = Color(0x99FFFFFF);
const kWhite12  = Color(0x1FFFFFFF);
const kWhite08  = Color(0x14FFFFFF);

TextStyle _ts(double size, {Color color = Colors.white, FontWeight fw = FontWeight.normal}) =>
    TextStyle(fontSize: size, color: color, fontWeight: fw);

// ─────────────────────────────────────────────
//  GAME PROGRESS SERVICE  (in-memory for demo)
// ─────────────────────────────────────────────
class GameProgressService {
  static int _xp = 0;
  static int _bestScore = 0;
  static Future<int>  getXp()        async => _xp;
  static Future<int>  getBestScore() async => _bestScore;
  static Future<void> addXp(int v)   async => _xp += v;
  static Future<void> setBest(int v) async { if (v > _bestScore) _bestScore = v; }
}

// ─────────────────────────────────────────────
//  GAME ARENA PAGE  (the hub)
// ─────────────────────────────────────────────
class GameArenaPage extends StatefulWidget {
  const GameArenaPage({super.key});
  @override
  State<GameArenaPage> createState() => _GameArenaPageState();
}

class _GameArenaPageState extends State<GameArenaPage> {
  int xp = 0;
  int bestScore = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lx = await GameProgressService.getXp();
    final lb = await GameProgressService.getBestScore();
    if (!mounted) return;
    setState(() { xp = lx; bestScore = lb; });
  }

  int get level         => (xp ~/ 200) + 1;
  int get currentLevelXp => xp % 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text('Game Arena', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildStatsCard(),
          const SizedBox(height: 14),
          _buildLeaderboard(),
          const SizedBox(height: 20),
          Text('🎮 Choose a Game', style: _ts(18, fw: FontWeight.w800)),
          const SizedBox(height: 14),
          _gameCard(
            title: 'Escape The Program',
            description: 'Fix broken code before the timer runs out.\nFill in the blanks and escape the maze!',
            dot: kPurple,
            onTap: () => _push(const EscapeTheProgramPage()),
          ),
          const SizedBox(height: 12),
          _gameCard(
            title: 'Guess Game',
            description: 'Read clues and guess the programming concept.\nUnlock hints if you are stuck!',
            dot: kYellow,
            onTap: () => _push(const GuessGamePage()),
          ),
          const SizedBox(height: 12),
          _gameCard(
            title: 'Coming Soon',
            description: 'More games on the way. Stay tuned!',
            dot: kBlue,
            locked: true,
          ),
        ],
      ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _load());
  }

  // ── Stats card ──
  Widget _buildStatsCard() {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔥 Your Progress', style: _ts(16, fw: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('Level $level', style: _ts(14, color: kYellow, fw: FontWeight.bold)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: currentLevelXp / 200,
              minHeight: 7,
              backgroundColor: kWhite12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA56BFF)),
            ),
          ),
          const SizedBox(height: 6),
          Text('$currentLevelXp / 200 XP to next level', style: _ts(12, color: kWhite70)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Total XP', '$xp')),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Best Score', '$bestScore%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite08,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: _ts(18, fw: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: _ts(11, color: kWhite60)),
        ],
      ),
    );
  }

  // ── Leaderboard ──
  Widget _buildLeaderboard() {
    final entries = [
      ('You', xp),
      ('Alyssa', 850),
      ('Mark', 720),
      ('Jamie', 640),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 Leaderboard', style: _ts(16, fw: FontWeight.w800)),
          const SizedBox(height: 10),
          ...entries.asMap().entries.map((e) {
            final rank = e.key + 1;
            final p    = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('#$rank', style: _ts(14, color: kYellow, fw: FontWeight.bold)),
                  ),
                  Expanded(child: Text(p.$1, style: _ts(14, fw: FontWeight.w600))),
                  Text('${p.$2} XP', style: _ts(13, color: kWhite70)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Game card ──
  Widget _gameCard({
    required String title,
    required String description,
    required Color dot,
    VoidCallback? onTap,
    bool locked = false,
  }) {
    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: _AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: dot),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: _ts(15, fw: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: _ts(13, color: kWhite70), maxLines: 3),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: locked ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWhite12,
                  disabledBackgroundColor: kWhite08,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  locked ? 'Locked' : '▶  Play',
                  style: _ts(14, fw: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED APP CARD
// ─────────────────────────────────────────────
class _AppCard extends StatelessWidget {
  final Widget child;
  const _AppCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite08,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kWhite12),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  RESULT SCREEN  (shared)
// ─────────────────────────────────────────────
class GameResultPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final int xpEarned;
  final int correct;
  final int total;
  final VoidCallback onHome;

  const GameResultPage({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.xpEarned,
    required this.correct,
    required this.total,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct * 100 ~/ total) : 0;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(title, style: _ts(26, fw: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle, style: _ts(14, color: kWhite70), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x26FFCC29),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('+$xpEarned XP Earned!',
                    style: _ts(20, color: kYellow, fw: FontWeight.w800)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _resStat('$correct', 'Correct', kGreen)),
                  const SizedBox(width: 10),
                  Expanded(child: _resStat('${total - correct}', 'Wrong', kRed)),
                  const SizedBox(width: 10),
                  Expanded(child: _resStat('$pct%', 'Accuracy', kPurple)),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Back to Arena', style: _ts(16, fw: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resStat(String val, String lbl, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: kWhite08,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(val, style: _ts(22, color: color, fw: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(lbl, style: _ts(11, color: kWhite60)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ESCAPE THE PROGRAM
// ─────────────────────────────────────────────
class _EscapePuzzle {
  final String title;
  final String description;
  // Each segment: either plain text or a blank (index >= 0)
  final List<_Seg> segments;
  final List<String> answers;   // correct answer per blank index
  final List<String> chips;     // all draggable chips

  const _EscapePuzzle({
    required this.title,
    required this.description,
    required this.segments,
    required this.answers,
    required this.chips,
  });
}

class _Seg {
  final String text;
  final bool isBlank;
  final int blankIndex;
  final bool isKeyword;
  final bool isNumber;
  final bool isComment;
  const _Seg.text(this.text, {this.isKeyword=false, this.isNumber=false, this.isComment=false})
      : isBlank = false, blankIndex = -1;
  const _Seg.blank(this.blankIndex)
      : isBlank = true, text = '', isKeyword = false, isNumber = false, isComment = false;
}

final _kPuzzles = <_EscapePuzzle>[
  _EscapePuzzle(
    title: 'Sum Even Numbers',
    description: 'Fix the function that sums all even numbers in a list.',
    segments: [
      _Seg.text('// Sum even numbers\n', isComment: true),
      _Seg.text('function ', isKeyword: true),
      _Seg.text('sumEvens(arr) {\n  '),
      _Seg.text('let ', isKeyword: true),
      _Seg.text('total = '), _Seg.blank(0), _Seg.text(';\n  '),
      _Seg.text('for ', isKeyword: true),
      _Seg.text('('), _Seg.text('let ', isKeyword: true), _Seg.text('n '),
      _Seg.text('of ', isKeyword: true), _Seg.text('arr) {\n    '),
      _Seg.text('if ', isKeyword: true),
      _Seg.text('(n '), _Seg.blank(1), _Seg.text(' 2 === '), _Seg.text('0', isNumber: true),
      _Seg.text(') {\n      total '), _Seg.blank(2), _Seg.text(' n;\n    }\n  }\n  '),
      _Seg.text('return ', isKeyword: true), _Seg.blank(3), _Seg.text(';\n}'),
    ],
    answers: ['0', '%', '+=', 'total'],
    chips:   ['0', '%', '+=', 'total', 'null', '*', 'return', '1', '-=', 'arr[0]'],
  ),
  _EscapePuzzle(
    title: 'Find the Maximum',
    description: 'Complete the function that returns the largest number.',
    segments: [
      _Seg.text('// Find largest in array\n', isComment: true),
      _Seg.text('function ', isKeyword: true),
      _Seg.text('findMax(arr) {\n  '),
      _Seg.text('let ', isKeyword: true),
      _Seg.text('max = '), _Seg.blank(0), _Seg.text(';\n  '),
      _Seg.text('for ', isKeyword: true),
      _Seg.text('('), _Seg.text('let ', isKeyword: true),
      _Seg.text('i = '), _Seg.blank(1), _Seg.text('; i < arr.length; i++) {\n    '),
      _Seg.text('if ', isKeyword: true),
      _Seg.text('(arr[i] '), _Seg.blank(2), _Seg.text(' max) {\n      max = '),
      _Seg.blank(3), _Seg.text(';\n    }\n  }\n  '),
      _Seg.text('return ', isKeyword: true), _Seg.text('max;\n}'),
    ],
    answers: ['arr[0]', '0', '>', 'arr[i]'],
    chips:   ['arr[0]', '0', '>', 'arr[i]', 'null', '<', '1', 'arr[1]', '+=', 'max'],
  ),
  _EscapePuzzle(
    title: 'Reverse a String',
    description: 'Fix the function that reverses a string.',
    segments: [
      _Seg.text('// Reverse string\n', isComment: true),
      _Seg.text('function ', isKeyword: true),
      _Seg.text('reverseStr(s) {\n  '),
      _Seg.text('let ', isKeyword: true),
      _Seg.text('result = '), _Seg.blank(0), _Seg.text(';\n  '),
      _Seg.text('for ', isKeyword: true),
      _Seg.text('('), _Seg.text('let ', isKeyword: true),
      _Seg.text('i = s.length '), _Seg.blank(1), _Seg.text(' 1; i >= '),
      _Seg.text('0', isNumber: true),
      _Seg.text('; i--) {\n    result '), _Seg.blank(2), _Seg.text(' s[i];\n  }\n  '),
      _Seg.text('return ', isKeyword: true), _Seg.blank(3), _Seg.text(';\n}'),
    ],
    answers: ["''", '-', '+=', 'result'],
    chips:   ["''", '-', '+=', 'result', 'null', '+', '0', 's', '-=', '[]'],
  ),
];

class EscapeTheProgramPage extends StatefulWidget {
  const EscapeTheProgramPage({super.key});
  @override
  State<EscapeTheProgramPage> createState() => _EscapeTheProgramPageState();
}

class _EscapeTheProgramPageState extends State<EscapeTheProgramPage> {
  int puzzleIdx = 0;
  late List<String?> filled;
  late List<bool> chipUsed;
  int? selectedBlank;
  bool submitted = false;
  late int secondsLeft;
  Timer? _timer;

  _EscapePuzzle get puzzle => _kPuzzles[puzzleIdx % _kPuzzles.length];

  @override
  void initState() {
    super.initState();
    _initPuzzle();
  }

  void _initPuzzle() {
    filled       = List.filled(puzzle.answers.length, null);
    chipUsed     = List.filled(puzzle.chips.length, false);
    selectedBlank = null;
    submitted    = false;
    secondsLeft  = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { secondsLeft--; });
      if (secondsLeft <= 0) { t.cancel(); _submit(); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _tapBlank(int idx) {
    if (submitted) return;
    setState(() => selectedBlank = idx);
  }

  void _tapChip(int ci) {
    if (submitted || chipUsed[ci]) return;
    final b = selectedBlank ?? filled.indexWhere((f) => f == null);
    if (b == -1) return;
    setState(() {
      filled[b]   = puzzle.chips[ci];
      chipUsed[ci] = true;
      selectedBlank = null;
    });
  }

  void _clearBlank(int idx) {
    if (submitted) return;
    final val = filled[idx];
    if (val == null) return;
    final ci = puzzle.chips.indexOf(val);
    setState(() {
      filled[idx] = null;
      if (ci >= 0) chipUsed[ci] = false;
      selectedBlank = idx;
    });
  }

  void _submit() {
    _timer?.cancel();
    setState(() => submitted = true);
    int correct = 0;
    for (int i = 0; i < puzzle.answers.length; i++) {
      if (filled[i] == puzzle.answers[i]) correct++;
    }
    final pct    = (correct * 100 ~/ puzzle.answers.length);
    final earned = correct * 10;
    GameProgressService.addXp(earned);
    GameProgressService.setBest(pct);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameResultPage(
            emoji:    pct == 100 ? '🔓' : pct >= 50 ? '😅' : '😬',
            title:    pct == 100 ? 'Escaped!' : pct >= 50 ? 'Almost There!' : 'Keep Practicing!',
            subtitle: pct == 100
                ? 'Perfect code — you fixed every blank!'
                : 'Some blanks were wrong. Review and retry.',
            xpEarned: earned,
            correct:  correct,
            total:    puzzle.answers.length,
            onHome:   () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ),
      );
    });
  }

  Color _blankColor(int idx) {
    if (!submitted) {
      return selectedBlank == idx ? Colors.white : const Color(0xFF6C63FF);
    }
    return filled[idx] == puzzle.answers[idx] ? kGreen : kRed;
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = secondsLeft <= 10 ? kRed : kWhite70;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(puzzle.title, style: _ts(16, fw: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x33FF6B6B),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('⏱ ${secondsLeft}s', style: _ts(13, color: timerColor, fw: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(puzzle.description, style: _ts(13, color: kWhite70)),
          const SizedBox(height: 12),
          // ── Code Block ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kWhite12),
            ),
            child: _buildCodeLines(),
          ),
          const SizedBox(height: 16),
          // ── Tap a blank hint ──
          if (!submitted)
            Text(
              selectedBlank != null
                  ? 'Blank ${selectedBlank! + 1} selected — tap a chip below'
                  : 'Tap a blank to select it, then tap an answer chip',
              style: _ts(12, color: kWhite60),
            ),
          const SizedBox(height: 10),
          // ── Chips ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(puzzle.chips.length, (ci) {
              return GestureDetector(
                onTap: () => _tapChip(ci),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: chipUsed[ci] ? 0.3 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: chipUsed[ci] ? kWhite08 : const Color(0xFF1E1E3A),
                      border: Border.all(color: chipUsed[ci] ? kWhite12 : const Color(0xFF5A54CC)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      puzzle.chips[ci],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: chipUsed[ci] ? kWhite60 : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          if (!submitted)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Check Code 🔓', style: _ts(16, fw: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCodeLines() {
    // Render code as inline spans
    final spans = <InlineSpan>[];
    int blankCount = 0;
    for (final seg in puzzle.segments) {
      if (!seg.isBlank) {
        Color c = Colors.white;
        if (seg.isKeyword) c = const Color(0xFFA78BFA);
        if (seg.isNumber)  c = const Color(0xFFFBBF24);
        if (seg.isComment) c = const Color(0xFF555580);
        spans.add(TextSpan(text: seg.text, style: TextStyle(color: c)));
      } else {
        final bi  = seg.blankIndex;
        final val = filled[bi];
        blankCount++;
        final bc = _blankColor(bi);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => val != null ? _clearBlank(bi) : _tapBlank(bi),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: bc.withOpacity(0.18),
                  border: Border.all(
                    color: bc,
                    width: 1.5,
                    style: submitted ? BorderStyle.solid : BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  val ?? '  ?  ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: bc,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.75),
        children: spans,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GUESS GAME
// ─────────────────────────────────────────────
class _GuessQuestion {
  final String concept;
  final List<String> clues;   // revealed one by one
  final List<String> options;
  final int answerIndex;
  const _GuessQuestion({
    required this.concept,
    required this.clues,
    required this.options,
    required this.answerIndex,
  });
}

final _kGuessQuestions = <_GuessQuestion>[
  _GuessQuestion(
    concept: 'List',
    clues: [
      'I store multiple items in a single variable.',
      'You access my items using a number called an index.',
      'In Python I look like this: [1, 2, 3].',
    ],
    options: ['Dictionary', 'List', 'Tuple', 'Set'],
    answerIndex: 1,
  ),
  _GuessQuestion(
    concept: 'Dictionary',
    clues: [
      'I pair keys with values.',
      'You look up data by key, not by position.',
      'In Python I use curly braces: {"name": "Alex"}.',
    ],
    options: ['List', 'Dictionary', 'Array', 'Queue'],
    answerIndex: 1,
  ),
  _GuessQuestion(
    concept: 'Function',
    clues: [
      'I let you reuse a block of code without rewriting it.',
      'You define me once and call me as many times as you need.',
      'In Python you start me with the keyword "def".',
    ],
    options: ['Loop', 'Variable', 'Function', 'Class'],
    answerIndex: 2,
  ),
  _GuessQuestion(
    concept: 'While loop',
    clues: [
      'I keep running a block of code repeatedly.',
      'I stop only when a condition becomes false.',
      'My keyword is "while".',
    ],
    options: ['For loop', 'While loop', 'Recursion', 'If statement'],
    answerIndex: 1,
  ),
  _GuessQuestion(
    concept: 'Variable',
    clues: [
      'I am a named container that holds a value.',
      'My value can change as the program runs.',
      'In Python you create me simply by writing: x = 5.',
    ],
    options: ['Constant', 'Function', 'Class', 'Variable'],
    answerIndex: 3,
  ),
  _GuessQuestion(
    concept: 'Class',
    clues: [
      'I am a blueprint for creating objects.',
      'I bundle data and behaviour together.',
      'In Python I start with the keyword "class".',
    ],
    options: ['Function', 'Module', 'Class', 'Interface'],
    answerIndex: 2,
  ),
  _GuessQuestion(
    concept: 'Boolean',
    clues: [
      'I can only be one of two values.',
      'Those two values are True or False.',
      'I am used heavily in conditions and comparisons.',
    ],
    options: ['Integer', 'String', 'Boolean', 'Float'],
    answerIndex: 2,
  ),
];

class GuessGamePage extends StatefulWidget {
  const GuessGamePage({super.key});
  @override
  State<GuessGamePage> createState() => _GuessGamePageState();
}

class _GuessGamePageState extends State<GuessGamePage> {
  late List<_GuessQuestion> questions;
  int qIdx       = 0;
  int clueIdx    = 0;       // how many clues revealed
  int? chosen;              // which option was tapped
  int correct    = 0;
  bool answered  = false;

  static const int total = 5;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    questions = List<_GuessQuestion>.from(_kGuessQuestions)..shuffle(rng);
    questions = questions.take(total).toList();
  }

  _GuessQuestion get q => questions[qIdx];

  void _revealClue() {
    if (clueIdx < q.clues.length - 1) {
      setState(() => clueIdx++);
    }
  }

  void _answer(int idx) {
    if (answered) return;
    setState(() {
      chosen   = idx;
      answered = true;
      if (idx == q.answerIndex) correct++;
    });
  }

  void _next() {
    if (qIdx + 1 >= total) {
      _finish();
      return;
    }
    setState(() {
      qIdx++;
      clueIdx  = 0;
      chosen   = null;
      answered = false;
    });
  }

  void _finish() {
    final pct    = (correct * 100 ~/ total);
    final earned = correct * 15;
    GameProgressService.addXp(earned);
    GameProgressService.setBest(pct);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultPage(
          emoji:    pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '💪',
          title:    pct >= 80 ? 'Genius!' : pct >= 60 ? 'Good Job!' : 'Keep Practicing!',
          subtitle: pct >= 80
              ? 'You identified every concept perfectly.'
              : 'Review the concepts you missed and try again.',
          xpEarned: earned,
          correct:  correct,
          total:    total,
          onHome:   () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = answered && chosen == q.answerIndex;
    final progress  = (qIdx + 1) / total;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text('Guess Game', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('$correct / $total', style: _ts(14, color: kYellow, fw: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: kWhite12,
                valueColor: const AlwaysStoppedAnimation<Color>(kPurple),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Question ${qIdx + 1} of $total', style: _ts(11, color: kWhite60)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                // ── Clue card ──
                _AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x33FFCC29),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Clue ${clueIdx + 1} of ${q.clues.length}',
                                style: _ts(11, color: kYellow, fw: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(clueIdx + 1, (i) => Padding(
                        padding: EdgeInsets.only(bottom: i < clueIdx ? 8 : 0),
                        child: Text(
                          q.clues[i],
                          style: _ts(15, color: i == clueIdx ? Colors.white : kWhite60, fw: FontWeight.w600),
                        ),
                      )),
                      if (!answered && clueIdx < q.clues.length - 1) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _revealClue,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0x26FFCC29),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('💡 Reveal next clue (-5 XP bonus)',
                                style: _ts(13, color: kYellow, fw: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── Options ──
                Text('What concept is being described?',
                    style: _ts(13, color: kWhite70)),
                const SizedBox(height: 10),
                ...List.generate(q.options.length, (i) {
                  Color? borderCol;
                  Color textCol = Colors.white;
                  Color bgCol   = kWhite08;
                  if (answered) {
                    if (i == q.answerIndex) {
                      borderCol = kGreen;
                      bgCol     = const Color(0x2043E97B);
                      textCol   = kGreen;
                    } else if (i == chosen && chosen != q.answerIndex) {
                      borderCol = kRed;
                      bgCol     = const Color(0x20FF6B6B);
                      textCol   = kRed;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _answer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: bgCol,
                          border: Border.all(
                            color: borderCol ?? kWhite12,
                            width: borderCol != null ? 1.5 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: kWhite12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: _ts(13, color: textCol, fw: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(q.options[i], style: _ts(15, color: textCol, fw: FontWeight.w600)),
                            ),
                            if (answered && i == q.answerIndex)
                              const Icon(Icons.check_circle_outline, color: kGreen, size: 20),
                            if (answered && i == chosen && chosen != q.answerIndex)
                              const Icon(Icons.cancel_outlined, color: kRed, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // ── Feedback ──
                if (answered) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0x1743E97B) : const Color(0x17FF6B6B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isCorrect
                          ? '✅ Correct! The answer is "${q.concept}".'
                          : '❌ Not quite. The concept is "${q.concept}".',
                      style: _ts(14, color: isCorrect ? kGreen : kRed),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        qIdx + 1 >= total ? 'See Results →' : 'Next →',
                        style: _ts(16, fw: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}