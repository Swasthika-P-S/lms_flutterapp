/// Course model for DSA, DBMS, OOPs, C++, Java
class CourseModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final List<Topic> topics;
  final int totalProblems;
  
  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.topics,
    this.totalProblems = 0,
  });
  
  factory CourseModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CourseModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '📚',
      color: data['color'] ?? '#6366F1',
      topics: (data['topics'] as List<dynamic>?)
          ?.map((t) => Topic.fromMap(t))
          .toList() ?? [],
      totalProblems: data['totalProblems'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'topics': topics.map((t) => t.toMap()).toList(),
      'totalProblems': totalProblems,
    };
  }
  
  // Predefined courses
  static List<CourseModel> defaultCourses = [
    CourseModel(
      id: 'dsa',
      title: 'Data Structures & Algorithms',
      description: 'Master DSA for technical interviews',
      icon: '🌳',
      color: '#8B5CF6',
      topics: Topic.dsaTopics,
      totalProblems: 150,
    ),
    CourseModel(
      id: 'dbms',
      title: 'Database Management',
      description: 'SQL and database concepts',
      icon: '🗄️',
      color: '#10B981',
      topics: Topic.dbmsTopics,
      totalProblems: 80,
    ),
    CourseModel(
      id: 'oops',
      title: 'Object-Oriented Programming',
      description: 'OOP principles and design patterns',
      icon: '🎯',
      color: '#F59E0B',
      topics: Topic.oopsTopics,
      totalProblems: 60,
    ),
    CourseModel(
      id: 'cpp',
      title: 'C++ Programming',
      description: 'C++ for competitive programming',
      icon: '⚡',
      color: '#3B82F6',
      topics: Topic.cppTopics,
      totalProblems: 100,
    ),
    CourseModel(
      id: 'java',
      title: 'Java Development',
      description: 'Java fundamentals and collections',
      icon: '☕',
      color: '#EF4444',
      topics: Topic.javaTopics,
      totalProblems: 90,
    ),
  ];
}

/// Topic within a course
class Topic {
  final String id;
  final String name;
  final String description;
  final int problemCount;
  final int totalQuestions;
  
  Topic({
    required this.id,
    required this.name,
    required this.description,
    this.problemCount = 0,
    this.totalQuestions = 0,
  });
  
  factory Topic.fromMap(Map<String, dynamic> data) {
    return Topic(
      id: data['id'] ?? data['_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      problemCount: data['problemCount'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'problemCount': problemCount,
    };
  }
  
  // DSA Topics
  static List<Topic> dsaTopics = [
    Topic(id: 'arrays', name: 'Arrays', description: 'Array manipulation and algorithms', problemCount: 25),
    Topic(id: 'linked_lists', name: 'Linked Lists', description: 'Singly and doubly linked lists', problemCount: 20),
    Topic(id: 'stacks_queues', name: 'Stacks & Queues', description: 'Stack and queue implementations', problemCount: 15),
    Topic(id: 'trees', name: 'Trees', description: 'Binary trees, BST, AVL trees', problemCount: 25),
    Topic(id: 'graphs', name: 'Graphs', description: 'Graph algorithms and traversals', problemCount: 20),
    Topic(id: 'sorting', name: 'Sorting', description: 'Sorting algorithms', problemCount: 10),
    Topic(id: 'searching', name: 'Searching', description: 'Binary search and variants', problemCount: 10),
    Topic(id: 'dynamic_programming', name: 'Dynamic Programming', description: 'DP patterns and problems', problemCount: 25),
  ];
  
  // DBMS Topics
  static List<Topic> dbmsTopics = [
    Topic(id: 'sql_basics', name: 'SQL Basics', description: 'SELECT, INSERT, UPDATE, DELETE', problemCount: 15),
    Topic(id: 'joins', name: 'Joins', description: 'INNER, LEFT, RIGHT, FULL joins', problemCount: 12),
    Topic(id: 'aggregation', name: 'Aggregation', description: 'GROUP BY, HAVING, aggregate functions', problemCount: 10),
    Topic(id: 'subqueries', name: 'Subqueries', description: 'Nested queries and correlated subqueries', problemCount: 10),
    Topic(id: 'indexes', name: 'Indexing', description: 'Database indexing and optimization', problemCount: 8),
    Topic(id: 'transactions', name: 'Transactions', description: 'ACID properties and transactions', problemCount: 10),
    Topic(id: 'normalization', name: 'Normalization', description: 'Database normalization forms', problemCount: 8),
    Topic(id: 'design', name: 'Database Design', description: 'ER diagrams and schema design', problemCount: 7),
  ];
  
  // OOPs Topics
  static List<Topic> oopsTopics = [
    Topic(id: 'encapsulation', name: 'Encapsulation', description: 'Data hiding and access modifiers', problemCount: 8),
    Topic(id: 'inheritance', name: 'Inheritance', description: 'Class inheritance and polymorphism', problemCount: 10),
    Topic(id: 'polymorphism', name: 'Polymorphism', description: 'Method overloading and overriding', problemCount: 8),
    Topic(id: 'abstraction', name: 'Abstraction', description: 'Abstract classes and interfaces', problemCount: 8),
    Topic(id: 'design_patterns', name: 'Design Patterns', description: 'Common OOP design patterns', problemCount: 15),
    Topic(id: 'solid_principles', name: 'SOLID Principles', description: 'SOLID design principles', problemCount: 11),
  ];
  
  // C++ Topics
  static List<Topic> cppTopics = [
    Topic(id: 'basics', name: 'C++ Basics', description: 'Syntax, data types, operators', problemCount: 15),
    Topic(id: 'pointers', name: 'Pointers', description: 'Pointer operations and memory', problemCount: 12),
    Topic(id: 'stl', name: 'STL', description: 'Standard Template Library', problemCount: 20),
    Topic(id: 'templates', name: 'Templates', description: 'Function and class templates', problemCount: 10),
    Topic(id: 'file_io', name: 'File I/O', description: 'File handling and streams', problemCount: 8),
    Topic(id: 'competitive', name: 'Competitive Programming', description: 'CP tips and tricks', problemCount: 35),
  ];
  
  // Java Topics
  static List<Topic> javaTopics = [
    Topic(id: 'fundamentals', name: 'Java Fundamentals', description: 'Basic Java syntax and concepts', problemCount: 15),
    Topic(id: 'collections', name: 'Collections Framework', description: 'List, Set, Map interfaces', problemCount: 20),
    Topic(id: 'multithreading', name: 'Multithreading', description: 'Threads and concurrency', problemCount: 12),
    Topic(id: 'exceptions', name: 'Exception Handling', description: 'Try-catch and custom exceptions', problemCount: 10),
    Topic(id: 'streams', name: 'Streams API', description: 'Java 8+ streams and lambdas', problemCount: 15),
    Topic(id: 'io', name: 'I/O Operations', description: 'File and network I/O', problemCount: 8),
    Topic(id: 'best_practices', name: 'Best Practices', description: 'Java coding best practices', problemCount: 10),
  ];
}
