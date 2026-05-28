import 'package:flutter/material.dart';
import '../services/game_progress_service.dart';

class QuizPage extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;
  final List questions;
  final bool alreadyCompleted;
  final int? previousScore;

  const QuizPage({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.questions,
    required this.alreadyCompleted,
    required this.previousScore,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentIndex = 0;
  int score = 0;
  int? selectedIndex;
  bool answered = false;
  bool finished = false;

  List get questions => widget.questions;

  void answerQuestion(int index) {
    if (answered) return;

    final question = questions[currentIndex];
    final correctIndex = question.correctIndex ?? 0;

    setState(() {
      selectedIndex = index;
      answered = true;

      if (index == correctIndex) {
        score++;
      }
    });
  }

  Future<void> nextQuestion() async {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
        answered = false;
      });
    } else {
      final percent = ((score / questions.length) * 100).round();
      final xpEarned = score * 50;

      await GameProgressService.addXp(xpEarned);
      await GameProgressService.saveBestScore(percent);

      setState(() {
        finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return _emptyQuiz();
    }

    if (finished) {
      return _resultPage();
    }

    final q = questions[currentIndex];
    final choices = q.choices ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF130A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF130A3A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              backgroundColor: Colors.white12,
              color: const Color(0xFFA56BFF),
            ),
            const SizedBox(height: 20),
            Text(
              'Question ${currentIndex + 1} of ${questions.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Text(
              q.question ?? 'Question',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(choices.length, (index) {
              final isSelected = selectedIndex == index;
              final isCorrect = index == (q.correctIndex ?? 0);

              Color bg = Colors.white.withOpacity(.10);
              if (answered && isCorrect) bg = Colors.green.withOpacity(.6);
              if (answered && isSelected && !isCorrect) {
                bg = Colors.red.withOpacity(.6);
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => answerQuestion(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      choices[index].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: answered ? nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA56BFF),
                  disabledBackgroundColor: Colors.white12,
                ),
                child: Text(
                  currentIndex == questions.length - 1 ? 'Finish Quiz' : 'Next',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultPage() {
    final percent = ((score / questions.length) * 100).round();
    final xpEarned = score * 50;

    return Scaffold(
      backgroundColor: const Color(0xFF130A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF130A3A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Quiz Result', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: $score/${questions.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '+$xpEarned XP earned',
                  style: const TextStyle(
                    color: Color(0xFF4ECA8D),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Lesson'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyQuiz() {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: const Center(
        child: Text('No quiz questions available.'),
      ),
    );
  }
}