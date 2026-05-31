import 'lesson_service.dart';

class LastLessonStore {
  LastLessonStore._();
  static final LastLessonStore instance = LastLessonStore._();

  LessonDetail? lastLesson;

  void set(LessonDetail lesson) => lastLesson = lesson;
  void clear() => lastLesson = null;
}