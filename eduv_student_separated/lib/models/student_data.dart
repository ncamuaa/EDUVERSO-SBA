class StudentData {
  static const name = 'Las Trial';
  static const email = 'abc@gmail.com';
  static const level = 1;
  static const xp = 60;
  static const streak = 0;

  static final modules = [
    ModuleItem(
      title: 'Control Structures',
      description:
          'The building blocks of programming that allow a program to make decisions, repeat actions, and control the flow of execution.',
      category: 'Programming Fundamentals',
    ),
    ModuleItem(
      title: 'Variables, Data Types and Operators',
      description:
          'In programming, variables, data types, and operators work together to allow a computer to store, understand, and manipulate information.',
      category: 'Programming Fundamentals',
    ),
    ModuleItem(
      title: 'Introduction to Programming',
      description:
          'The foundation course that teaches the basic concepts of how computers follow instructions to perform tasks.',
      category: 'Programming Fundamentals',
    ),
    ModuleItem(
      title: 'Web Development Fundamentals',
      description:
          'Essential concepts, tools, and technologies beginners need to create functional, interactive, and visually appealing websites.',
      category: 'Web Development',
    ),
  ];

  static final peerFeedback = [
    FeedbackItem(
      title: 'Active Participation',
      body:
          'Las actively participates in group activities and shares thoughtful ideas. She stays engaged and helps clarify instructions for others.',
      date: '12/10/2025',
    ),
    FeedbackItem(
      title: 'Great Team Collaboration',
      body:
          'Consistently works well with the group and contributes helpful ideas during discussions. Keep up the positive attitude.',
      date: '12/10/2025',
    ),
  ];

  static final announcements = [
    AnnouncementItem(
      title: 'Update Software',
      body:
          'We will be updating the system software to improve performance, enhance security, and add new features.',
      tag: 'INFO',
      badge: 'NEW',
      date: 'Dec 10',
    )
  ];
}

class ModuleItem {
  final String title;
  final String description;
  final String category;
  ModuleItem({required this.title, required this.description, required this.category});
}

class FeedbackItem {
  final String title;
  final String body;
  final String date;
  FeedbackItem({required this.title, required this.body, required this.date});
}

class AnnouncementItem {
  final String title;
  final String body;
  final String tag;
  final String badge;
  final String date;
  AnnouncementItem({required this.title, required this.body, required this.tag, required this.badge, required this.date});
}
