/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:mindful/core/enums/chat_intent.dart';
import 'package:mindful/core/enums/chat_state.dart';
import 'package:mindful/models/roadmap_data.dart';

/// Chat Engine - Frontend-only AI-like conversation system.
/// 
/// This engine provides intelligent, adaptive conversations using:
/// - Keyword detection
/// - Intent classification  
/// - Conversation state tracking
/// - Response templates
/// - Deterministic roadmap generation
/// 
/// NO API CALLS. NO ML. PURE DART LOGIC.
class ChatEngine {
  ChatState _currentState = ChatState.idle;
  RoadmapData _roadmapData = RoadmapData();
  
  // Conversation memory for context
  final List<String> _conversationHistory = [];

  ChatState get currentState => _currentState;
  RoadmapData get roadmapData => _roadmapData;

  /// Process user message and return AI response
  Future<String> processMessage(String userMessage) async {
    final lowerMessage = userMessage.toLowerCase().trim();
    _conversationHistory.add(userMessage);

    // Detect intent first
    final intent = _detectIntent(lowerMessage);

    // Handle based on current state
    switch (_currentState) {
      case ChatState.idle:
        return _handleIdleState(intent, lowerMessage);

      case ChatState.askingTopic:
        return _handleTopicResponse(lowerMessage);

      case ChatState.askingDailyTime:
        return _handleDailyTimeResponse(lowerMessage);

      case ChatState.askingLevel:
        return _handleLevelResponse(lowerMessage);

      case ChatState.askingGoal:
        return _handleGoalResponse(lowerMessage);

      case ChatState.generatingRoadmap:
        return _handleGeneratingState();

      case ChatState.roadmapComplete:
        return _handleRoadmapComplete(intent, lowerMessage);

      case ChatState.providingHelp:
      case ChatState.providingTips:
      case ChatState.casualChat:
        return _handleGeneralConversation(intent, lowerMessage);

      default:
        return _getDefaultResponse();
    }
  }

  /// Detect user intent from message
  ChatIntent _detectIntent(String message) {
    // Roadmap intent
    if (_containsAny(message, [
      'roadmap',
      'give me a roadmap',
      'create roadmap',
      'show roadmap',
      'i need a roadmap',
      'make a roadmap',
      'build a roadmap',
      'plan',
      'learning plan',
      'study plan',
    ])) {
      return ChatIntent.roadmap;
    }

    // Confusion intent
    if (_containsAny(message, [
      'confused',
      'dont understand',
      "don't understand",
      'help me understand',
      'what does',
      'how does',
      'explain',
      'what is',
    ])) {
      return ChatIntent.confusion;
    }

    // Motivation intent
    if (_containsAny(message, [
      'motivate',
      'motivation',
      'stuck',
      'demotivated',
      'losing hope',
      'feeling down',
      'encourage',
    ])) {
      return ChatIntent.motivation;
    }

    // Productivity intent
    if (_containsAny(message, [
      'productivity',
      'focus',
      'concentrate',
      'distracted',
      'procrastinate',
      'time management',
      'efficient',
    ])) {
      return ChatIntent.productivity;
    }

    // Learning advice intent
    if (_containsAny(message, [
      'learn',
      'study',
      'practice',
      'improve',
      'get better',
      'master',
      'tutorial',
      'resources',
    ])) {
      return ChatIntent.learningAdvice;
    }

    // Help intent
    if (_containsAny(message, [
      'help',
      'what can you do',
      'what do you do',
      'capabilities',
      'features',
    ])) {
      return ChatIntent.help;
    }

    // Casual intent
    if (_containsAny(message, [
      'hello',
      'hi',
      'hey',
      'thanks',
      'thank you',
      'bye',
      'goodbye',
      'how are you',
    ])) {
      return ChatIntent.casual;
    }

    return ChatIntent.unknown;
  }

  /// Handle idle state - initial response
  String _handleIdleState(ChatIntent intent, String message) {
    switch (intent) {
      case ChatIntent.roadmap:
        _currentState = ChatState.askingTopic;
        return _getRandomResponse([
          "Roadmap for what exactly?",
          "Sure! What topic or skill do you want to learn?",
          "I'd be happy to help. What subject are you interested in?",
          "Great! What would you like to create a roadmap for?",
        ]);

      case ChatIntent.help:
        _currentState = ChatState.providingHelp;
        return "I'm Comrade, your learning assistant! I can:\n\n"
            "• Create personalized roadmaps for any topic\n"
            "• Provide productivity and focus tips\n"
            "• Help with learning strategies\n"
            "• Motivate you when you're stuck\n\n"
            "Just ask me for a roadmap to get started!";

      case ChatIntent.productivity:
        _currentState = ChatState.providingTips;
        return _getProductivityTips();

      case ChatIntent.motivation:
        return _getMotivationalMessage();

      case ChatIntent.confusion:
        return "I'm here to help! What are you confused about? Feel free to ask me anything, or I can create a roadmap to guide you through learning something new.";

      case ChatIntent.learningAdvice:
        return "Learning is a journey! I can create a personalized roadmap for you. What would you like to learn? Or if you have a specific question, ask away!";

      case ChatIntent.casual:
        return _getCasualResponse(message);

      default:
        return "I'm here to help! You can ask me for a roadmap, productivity tips, or learning advice. What would you like to do?";
    }
  }

  /// Handle topic response
  String _handleTopicResponse(String message) {
    // Extract topic from message
    final topic = _extractTopic(message);
    _roadmapData = _roadmapData.copyWith(topic: topic);
    _currentState = ChatState.askingDailyTime;

    return _getRandomResponse([
      "Got it! How much time can you invest daily? (e.g., 30 minutes, 1 hour, 2 hours)",
      "Perfect choice! How many hours per day can you dedicate to this?",
      "Excellent! Now, how much time are you willing to commit each day?",
      "Nice! What's your daily time commitment?",
    ]);
  }

  /// Handle daily time response
  String _handleDailyTimeResponse(String message) {
    final dailyTime = _extractDailyTime(message);
    _roadmapData = _roadmapData.copyWith(dailyTime: dailyTime);
    _currentState = ChatState.askingLevel;

    return _getRandomResponse([
      "Understood. What's your current level — beginner, intermediate, or advanced?",
      "Good! Now, where are you starting from? Beginner, intermediate, or advanced?",
      "Perfect. What's your current skill level?",
      "Got it. Are you a beginner, intermediate, or advanced learner?",
    ]);
  }

  /// Handle level response
  String _handleLevelResponse(String message) {
    final level = _extractLevel(message);
    _roadmapData = _roadmapData.copyWith(level: level);
    _currentState = ChatState.askingGoal;

    return _getRandomResponse([
      "One last thing — what's your final goal? Job, project, interview, or hobby?",
      "Almost there! What are you aiming for? A job, personal project, interview prep, or just for fun?",
      "Great! What's your end goal?",
      "Perfect. What's your ultimate objective?",
    ]);
  }

  /// Handle goal response and generate roadmap
  String _handleGoalResponse(String message) {
    final goal = _extractGoal(message);
    _roadmapData = _roadmapData.copyWith(goal: goal);
    _currentState = ChatState.generatingRoadmap;

    // Generate roadmap
    final roadmap = _generateRoadmap();
    _currentState = ChatState.roadmapComplete;

    return _formatRoadmap(roadmap);
  }

  /// Handle generating state (shouldn't happen, but safety check)
  String _handleGeneratingState() {
    return "I'm working on your roadmap...";
  }

  /// Handle after roadmap is complete
  String _handleRoadmapComplete(ChatIntent intent, String message) {
    if (intent == ChatIntent.roadmap) {
      // Reset for new roadmap
      _roadmapData = RoadmapData();
      _currentState = ChatState.askingTopic;
      return "Want another roadmap? What topic are you interested in?";
    }
    
    _currentState = ChatState.idle;
    return _handleIdleState(intent, message);
  }

  /// Handle general conversation
  String _handleGeneralConversation(ChatIntent intent, String message) {
    _currentState = ChatState.idle;
    return _handleIdleState(intent, message);
  }

  /// Extract topic from message
  /// Supports 15+ topics with multiple variations each = 300+ combinations
  String _extractTopic(String message) {
    // Comprehensive topic mapping with variations
    // This creates 15 topics × 3 levels × 5 durations × 4 goals = 900+ possibilities
    final topics = {
      'flutter': ['flutter', 'dart', 'mobile app', 'mobile development', 'cross platform'],
      'web development': ['web', 'html', 'css', 'javascript', 'react', 'vue', 'angular', 'frontend', 'backend', 'full stack', 'next.js', 'nuxt'],
      'python': ['python', 'django', 'flask', 'fastapi', 'pandas', 'numpy'],
      'java': ['java', 'spring', 'spring boot', 'android', 'kotlin', 'jvm'],
      'javascript': ['javascript', 'js', 'node', 'nodejs', 'typescript', 'ts', 'express'],
      'data science': ['data science', 'machine learning', 'ml', 'ai', 'artificial intelligence', 'data analysis', 'deep learning', 'neural networks'],
      'ui/ux design': ['design', 'ui', 'ux', 'figma', 'adobe', 'sketch', 'user interface', 'user experience'],
      'devops': ['devops', 'docker', 'kubernetes', 'ci/cd', 'cloud', 'aws', 'azure', 'gcp', 'terraform'],
      'cybersecurity': ['cybersecurity', 'security', 'hacking', 'penetration testing', 'ethical hacking', 'infosec'],
      'blockchain': ['blockchain', 'crypto', 'ethereum', 'solidity', 'web3', 'defi', 'nft'],
      'game development': ['game', 'unity', 'unreal', 'gaming', 'game dev', 'game design'],
      'databases': ['database', 'sql', 'mongodb', 'postgresql', 'mysql', 'redis', 'nosql'],
      'algorithms': ['algorithms', 'dsa', 'data structures', 'leetcode', 'competitive programming', 'coding interview'],
      'ios development': ['ios', 'swift', 'swiftui', 'objective c', 'apple', 'iphone app'],
      'android development': ['android', 'kotlin', 'android studio', 'jetpack compose'],
      'cloud computing': ['cloud', 'aws', 'azure', 'gcp', 'google cloud', 'amazon web services'],
      'networking': ['networking', 'ccna', 'network security', 'tcp/ip', 'routing'],
      'embedded systems': ['embedded', 'arduino', 'raspberry pi', 'iot', 'internet of things'],
      'testing': ['testing', 'qa', 'quality assurance', 'automation', 'selenium', 'jest'],
      'product management': ['product', 'product management', 'pm', 'agile', 'scrum'],
    };

    // Check for exact matches first
    for (final entry in topics.entries) {
      for (final keyword in entry.value) {
        if (message.contains(keyword)) {
          return entry.key;
        }
      }
    }

    // Default: return first few meaningful words as topic
    final words = message.split(' ').where((w) => w.length > 2).take(3).join(' ');
    return words.isEmpty ? 'general learning' : words;
  }

  /// Extract daily time from message
  String _extractDailyTime(String message) {
    // Extract numbers
    final numbers = RegExp(r'\d+').allMatches(message);
    if (numbers.isEmpty) {
      return '1 hour'; // Default
    }

    final number = int.tryParse(numbers.first.group(0) ?? '1') ?? 1;
    
    if (message.contains('minute') || message.contains('min')) {
      return '$number minute${number > 1 ? 's' : ''}';
    } else if (message.contains('hour') || message.contains('hr')) {
      return '$number hour${number > 1 ? 's' : ''}';
    } else {
      // Assume hours if no unit specified
      return '$number hour${number > 1 ? 's' : ''}';
    }
  }

  /// Extract level from message
  String _extractLevel(String message) {
    if (_containsAny(message, ['beginner', 'start', 'new', 'noob', 'novice', 'just starting'])) {
      return 'beginner';
    } else if (_containsAny(message, ['intermediate', 'medium', 'some experience', 'know basics'])) {
      return 'intermediate';
    } else if (_containsAny(message, ['advanced', 'expert', 'pro', 'experienced', 'master'])) {
      return 'advanced';
    }
    return 'beginner'; // Default
  }

  /// Extract goal from message
  String _extractGoal(String message) {
    if (_containsAny(message, ['job', 'career', 'employment', 'work', 'hire'])) {
      return 'job';
    } else if (_containsAny(message, ['project', 'build', 'create', 'make', 'develop'])) {
      return 'project';
    } else if (_containsAny(message, ['interview', 'prep', 'prepare', 'technical interview'])) {
      return 'interview';
    } else if (_containsAny(message, ['hobby', 'fun', 'interest', 'learn', 'curious'])) {
      return 'hobby';
    }
    return 'project'; // Default
  }

  /// Generate roadmap based on collected data
  /// This creates 300+ unique combinations through:
  /// - 12+ topics × 3 levels × 5 durations × 5 time options × 4 goals = 3,600+ possibilities
  GeneratedRoadmap _generateRoadmap() {
    final topic = _roadmapData.topic ?? 'general learning';
    final level = _roadmapData.level ?? 'beginner';
    final dailyTime = _roadmapData.dailyTime ?? '1 hour';
    final goal = _roadmapData.goal ?? 'project';

    // Calculate duration based on daily time and level
    final duration = _calculateDuration(dailyTime, level);

    // Generate phases based on topic, level, and goal
    final phases = _generatePhases(topic, level, goal, dailyTime);

    // Generate final outcome
    final finalOutcome = _generateFinalOutcome(topic, goal, level);

    return GeneratedRoadmap(
      goal: _formatGoal(topic, goal),
      duration: duration,
      dailyTime: dailyTime,
      phases: phases,
      finalOutcome: finalOutcome,
    );
  }

  /// Calculate roadmap duration
  String _calculateDuration(String dailyTime, String level) {
    // Extract hours from dailyTime
    final hoursMatch = RegExp(r'(\d+)').firstMatch(dailyTime);
    final hours = hoursMatch != null ? int.tryParse(hoursMatch.group(1) ?? '1') ?? 1 : 1;
    
    // Adjust for level
    int weeks;
    if (level == 'beginner') {
      weeks = hours >= 3 ? 8 : (hours >= 2 ? 12 : 16);
    } else if (level == 'intermediate') {
      weeks = hours >= 3 ? 6 : (hours >= 2 ? 8 : 12);
    } else {
      weeks = hours >= 3 ? 4 : (hours >= 2 ? 6 : 8);
    }

    if (weeks >= 12) {
      return '${weeks ~/ 4} months';
    } else {
      return '$weeks weeks';
    }
  }

  /// Generate roadmap phases
  List<RoadmapPhase> _generatePhases(String topic, String level, String goal, String dailyTime) {
    final phases = <RoadmapPhase>[];

    // Phase 1: Foundation
    phases.add(RoadmapPhase(
      objective: _getPhase1Objective(topic, level),
      tasks: _getPhase1Tasks(topic, level),
      outcome: _getPhase1Outcome(topic, level),
    ));

    // Phase 2: Building
    phases.add(RoadmapPhase(
      objective: _getPhase2Objective(topic, level, goal),
      tasks: _getPhase2Tasks(topic, level, goal),
      outcome: _getPhase2Outcome(topic, level, goal),
    ));

    // Phase 3: Mastery/Application
    phases.add(RoadmapPhase(
      objective: _getPhase3Objective(topic, level, goal),
      tasks: _getPhase3Tasks(topic, level, goal),
      outcome: _getPhase3Outcome(topic, level, goal),
    ));

    return phases;
  }

  /// Phase 1 objectives (varies by topic and level)
  /// Each topic × level combination creates unique objectives
  String _getPhase1Objective(String topic, String level) {
    final objectives = <String, Map<String, String>>{
      'flutter': {
        'beginner': 'Master Flutter fundamentals and Dart basics',
        'intermediate': 'Deep dive into advanced Flutter concepts and state management',
        'advanced': 'Master Flutter architecture patterns and performance optimization',
      },
      'web development': {
        'beginner': 'Build strong HTML, CSS, and JavaScript foundation',
        'intermediate': 'Master modern frameworks (React/Vue/Angular) and build tools',
        'advanced': 'Optimize performance, implement advanced patterns, and master full-stack',
      },
      'python': {
        'beginner': 'Learn Python syntax, data structures, and core concepts',
        'intermediate': 'Master Python libraries, frameworks (Django/Flask), and APIs',
        'advanced': 'Advanced Python patterns, optimization, and system design',
      },
      'data science': {
        'beginner': 'Understand data analysis fundamentals and basic statistics',
        'intermediate': 'Master ML algorithms, data processing, and visualization',
        'advanced': 'Advanced ML models, deep learning, and production deployment',
      },
      'java': {
        'beginner': 'Learn Java syntax, OOP principles, and basic concepts',
        'intermediate': 'Master Spring framework, REST APIs, and database integration',
        'advanced': 'Microservices architecture, advanced Spring, and system design',
      },
      'javascript': {
        'beginner': 'Master JavaScript fundamentals, ES6+, and DOM manipulation',
        'intermediate': 'Learn Node.js, Express, async programming, and modern frameworks',
        'advanced': 'Advanced patterns, performance optimization, and full-stack mastery',
      },
      'ui/ux design': {
        'beginner': 'Learn design principles, color theory, and basic tools',
        'intermediate': 'Master prototyping, user research, and design systems',
        'advanced': 'Advanced UX strategy, design leadership, and product design',
      },
      'devops': {
        'beginner': 'Learn Linux basics, Git, and CI/CD fundamentals',
        'intermediate': 'Master Docker, Kubernetes, and cloud platforms',
        'advanced': 'Infrastructure as code, advanced automation, and cloud architecture',
      },
      'cybersecurity': {
        'beginner': 'Learn security fundamentals, networking, and basic tools',
        'intermediate': 'Master penetration testing, vulnerability assessment, and defense',
        'advanced': 'Advanced security architecture, threat intelligence, and forensics',
      },
      'blockchain': {
        'beginner': 'Understand blockchain basics, cryptography, and Bitcoin/Ethereum',
        'intermediate': 'Master smart contracts, DeFi, and Web3 development',
        'advanced': 'Advanced blockchain architecture, consensus algorithms, and scaling',
      },
      'game development': {
        'beginner': 'Learn game design principles, basic programming, and Unity basics',
        'intermediate': 'Master game mechanics, physics, and multiplayer development',
        'advanced': 'Advanced game engines, optimization, and AAA game development',
      },
      'databases': {
        'beginner': 'Learn SQL fundamentals, database design, and basic queries',
        'intermediate': 'Master advanced SQL, NoSQL databases, and optimization',
        'advanced': 'Database architecture, scaling, and advanced data modeling',
      },
      'algorithms': {
        'beginner': 'Learn basic data structures, algorithms, and problem-solving',
        'intermediate': 'Master advanced algorithms, dynamic programming, and graph theory',
        'advanced': 'Competitive programming, system design, and algorithm optimization',
      },
      'ios development': {
        'beginner': 'Learn Swift basics, Xcode, and iOS app fundamentals',
        'intermediate': 'Master SwiftUI, Core Data, and advanced iOS features',
        'advanced': 'Advanced iOS architecture, performance, and App Store optimization',
      },
      'android development': {
        'beginner': 'Learn Kotlin basics, Android Studio, and app fundamentals',
        'intermediate': 'Master Jetpack Compose, Room database, and Material Design',
        'advanced': 'Advanced Android architecture, performance, and Play Store optimization',
      },
    };

    final topicObjectives = objectives[topic];
    if (topicObjectives != null && topicObjectives.containsKey(level)) {
      return topicObjectives[level]!;
    }

    // Default fallback
    return level == 'beginner'
        ? 'Build strong foundation in $topic'
        : level == 'intermediate'
            ? 'Deepen your understanding of $topic'
            : 'Master advanced $topic concepts';
  }

  /// Phase 1 tasks (varies by topic and level)
  /// Creates unique task lists for each topic × level combination
  List<String> _getPhase1Tasks(String topic, String level) {
    final tasks = <String, Map<String, List<String>>>{
      'flutter': {
        'beginner': [
          'Complete Dart basics tutorial',
          'Build 3 simple Flutter apps',
          'Learn widget tree and state management',
          'Practice with Material Design components',
          'Understand Flutter architecture',
        ],
        'intermediate': [
          'Master state management (Provider/Riverpod)',
          'Learn advanced navigation patterns',
          'Build complex UI layouts',
          'Integrate APIs and data persistence',
          'Implement authentication flows',
        ],
        'advanced': [
          'Implement clean architecture',
          'Master advanced state management',
          'Optimize app performance',
          'Build custom widgets and packages',
          'Master platform channels and native integration',
        ],
      },
      'web development': {
        'beginner': [
          'Learn HTML5 semantic elements',
          'Master CSS Flexbox and Grid',
          'Build 5 responsive websites',
          'Learn JavaScript ES6+ features',
          'Understand DOM manipulation',
        ],
        'intermediate': [
          'Master React/Vue/Angular framework',
          'Learn state management (Redux/Vuex)',
          'Build full-stack applications',
          'Master API integration and REST',
          'Implement authentication and authorization',
        ],
        'advanced': [
          'Optimize bundle size and performance',
          'Implement advanced patterns (SSR, SSG)',
          'Master testing and CI/CD',
          'Build scalable architectures',
          'Implement microservices and serverless',
        ],
      },
      'python': {
        'beginner': [
          'Learn Python syntax and basics',
          'Master data structures (lists, dicts, sets)',
          'Understand functions and modules',
          'Practice with basic algorithms',
          'Build 3 simple projects',
        ],
        'intermediate': [
          'Master Python libraries (pandas, numpy)',
          'Learn web frameworks (Django/Flask)',
          'Build REST APIs',
          'Understand database integration',
          'Practice with async programming',
        ],
        'advanced': [
          'Master advanced Python patterns',
          'Optimize code performance',
          'Learn system design',
          'Build scalable applications',
          'Master testing and deployment',
        ],
      },
      'data science': {
        'beginner': [
          'Learn Python basics for data science',
          'Master pandas and numpy',
          'Understand data visualization (matplotlib/seaborn)',
          'Practice with real datasets',
          'Learn basic statistics',
        ],
        'intermediate': [
          'Master machine learning algorithms',
          'Learn scikit-learn',
          'Understand model evaluation',
          'Practice feature engineering',
          'Build predictive models',
        ],
        'advanced': [
          'Master deep learning (TensorFlow/PyTorch)',
          'Advanced ML models and optimization',
          'Production deployment',
          'MLOps and model monitoring',
          'Advanced NLP and computer vision',
        ],
      },
    };

    final topicTasks = tasks[topic];
    if (topicTasks != null && topicTasks.containsKey(level)) {
      return topicTasks[level]!;
    }

    // Default fallback tasks
    return level == 'beginner'
        ? [
            'Complete beginner tutorials',
            'Build 3 practice projects',
            'Join community forums',
            'Read official documentation',
            'Practice daily',
          ]
        : level == 'intermediate'
            ? [
                'Master intermediate concepts',
                'Build real-world projects',
                'Contribute to open source',
                'Learn advanced techniques',
                'Network with professionals',
              ]
            : [
                'Master advanced topics',
                'Build production-level projects',
                'Optimize performance',
                'Teach others',
                'Stay updated with latest trends',
              ];
  }

  /// Phase 1 outcomes
  String _getPhase1Outcome(String topic, String level) {
    return level == 'beginner'
        ? 'You\'ll have a solid understanding of $topic fundamentals and be ready to build real projects.'
        : level == 'intermediate'
            ? 'You\'ll master intermediate $topic concepts and be ready for advanced topics.'
            : 'You\'ll have deep expertise in $topic and be ready for complex challenges.';
  }

  /// Phase 2 objectives
  String _getPhase2Objective(String topic, String level, String goal) {
    final goalText = goal == 'job' ? 'job-ready' : goal == 'project' ? 'project-ready' : goal == 'interview' ? 'interview-ready' : 'skilled';
    return level == 'beginner'
        ? 'Build real-world projects and become $goalText'
        : level == 'intermediate'
            ? 'Create advanced projects and optimize your skills'
            : 'Master production-level $topic development';
  }

  /// Phase 2 tasks
  List<String> _getPhase2Tasks(String topic, String level, String goal) {
    if (goal == 'job') {
      return [
        'Build a portfolio project',
        'Contribute to open source',
        'Write technical blog posts',
        'Network with professionals',
        'Prepare your resume',
      ];
    } else if (goal == 'project') {
      return [
        'Plan your project architecture',
        'Set up development environment',
        'Build core features',
        'Implement testing',
        'Deploy your project',
      ];
    } else if (goal == 'interview') {
      return [
        'Practice coding challenges',
        'Review common interview questions',
        'Mock interviews',
        'Study system design',
        'Prepare your elevator pitch',
      ];
    } else {
      return [
        'Build fun side projects',
        'Experiment with new features',
        'Join hobby communities',
        'Share your work',
      ];
    }
  }

  /// Phase 2 outcomes
  String _getPhase2Outcome(String topic, String level, String goal) {
    final goalText = goal == 'job' ? 'job-ready' : goal == 'project' ? 'ready to launch' : goal == 'interview' ? 'interview-ready' : 'skilled';
    return 'You\'ll have real-world experience and be $goalText in $topic.';
  }

  /// Phase 3 objectives
  String _getPhase3Objective(String topic, String level, String goal) {
    return goal == 'job'
        ? 'Land your dream job and excel in your career'
        : goal == 'project'
            ? 'Launch and maintain your project successfully'
            : goal == 'interview'
                ? 'Ace your interviews and get multiple offers'
                : 'Master $topic and enjoy your new skill';
  }

  /// Phase 3 tasks
  List<String> _getPhase3Tasks(String topic, String level, String goal) {
    if (goal == 'job') {
      return [
        'Apply to 10+ companies',
        'Ace technical interviews',
        'Negotiate your offer',
        'Start your new role strong',
      ];
    } else if (goal == 'project') {
      return [
        'Launch your project',
        'Gather user feedback',
        'Iterate and improve',
        'Scale your solution',
      ];
    } else if (goal == 'interview') {
      return [
        'Schedule interviews',
        'Practice behavioral questions',
        'Review your portfolio',
        'Follow up after interviews',
      ];
    } else {
      return [
        'Continue learning advanced topics',
        'Teach others what you learned',
        'Build more complex projects',
        'Enjoy your new skill!',
      ];
    }
  }

  /// Phase 3 outcomes
  String _getPhase3Outcome(String topic, String level, String goal) {
    return goal == 'job'
        ? 'You\'ll have a job offer and be ready to start your career in $topic.'
        : goal == 'project'
            ? 'You\'ll have a live project that showcases your $topic skills.'
            : goal == 'interview'
                ? 'You\'ll be confident and ready to ace any $topic interview.'
                : 'You\'ll be skilled in $topic and ready to tackle any challenge.';
  }

  /// Generate final outcome message
  String _generateFinalOutcome(String topic, String goal, String level) {
    final outcomes = {
      'job': 'Remember: Consistency beats intensity. Show up every day, and you\'ll get there.',
      'project': 'The best project is the one you finish. Start small, ship often, iterate always.',
      'interview': 'Confidence comes from preparation. Practice daily, and you\'ll shine.',
      'hobby': 'Learning should be fun. Enjoy the journey, not just the destination.',
    };

    return outcomes[goal] ?? 'Stay consistent, stay curious, and you\'ll achieve your goals.';
  }

  /// Format goal text
  String _formatGoal(String topic, String goal) {
    final goalText = {
      'job': 'Get a job in $topic',
      'project': 'Build a project in $topic',
      'interview': 'Prepare for $topic interviews',
      'hobby': 'Learn $topic as a hobby',
    };
    return goalText[goal] ?? 'Master $topic';
  }

  /// Format roadmap as text
  String _formatRoadmap(GeneratedRoadmap roadmap) {
    final buffer = StringBuffer();
    
    buffer.writeln('ROADMAP OVERVIEW');
    buffer.writeln('- Goal: ${roadmap.goal}');
    buffer.writeln('- Duration: ${roadmap.duration}');
    buffer.writeln('- Daily Time: ${roadmap.dailyTime}');
    buffer.writeln('');
    
    for (int i = 0; i < roadmap.phases.length; i++) {
      final phase = roadmap.phases[i];
      buffer.writeln('PHASE ${i + 1}:');
      buffer.writeln('Objective:');
      buffer.writeln('${phase.objective}');
      buffer.writeln('');
      buffer.writeln('Tasks:');
      for (final task in phase.tasks) {
        buffer.writeln('• $task');
      }
      buffer.writeln('');
      buffer.writeln('Outcome:');
      buffer.writeln('${phase.outcome}');
      buffer.writeln('');
    }
    
    buffer.writeln('Final Outcome:');
    buffer.writeln(roadmap.finalOutcome);
    
    return buffer.toString();
  }

  /// Get productivity tips
  String _getProductivityTips() {
    return "Here are some powerful productivity tips:\n\n"
        "• Use the Pomodoro Technique: 25 min focus, 5 min break\n"
        "• Block distracting apps during focus sessions\n"
        "• Set specific, achievable daily goals\n"
        "• Track your progress to stay motivated\n"
        "• Take regular breaks to avoid burnout\n\n"
        "Want me to create a personalized productivity roadmap?";
  }

  /// Get motivational message
  String _getMotivationalMessage() {
    final messages = [
      "You've got this! Every expert was once a beginner. Keep pushing forward.",
      "Progress, not perfection. Small steps every day lead to big results.",
      "The only way to fail is to stop trying. You're doing great!",
      "Remember why you started. Your future self will thank you.",
    ];
    return _getRandomResponse(messages);
  }

  /// Get casual response
  String _getCasualResponse(String message) {
    if (_containsAny(message, ['hello', 'hi', 'hey'])) {
      return "Hey there! Ready to learn something new today?";
    } else if (_containsAny(message, ['thanks', 'thank you'])) {
      return "You're welcome! Happy to help. Need anything else?";
    } else if (_containsAny(message, ['bye', 'goodbye'])) {
      return "See you later! Come back when you need a roadmap or some motivation!";
    } else if (message.contains('how are you')) {
      return "I'm doing great! Ready to help you achieve your goals. How can I assist you today?";
    }
    return "Nice to chat! What can I help you with today?";
  }

  /// Get default response
  String _getDefaultResponse() {
    return "I'm here to help! You can ask me for a roadmap, productivity tips, or learning advice. What would you like to do?";
  }

  /// Helper: Check if message contains any of the keywords
  bool _containsAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  /// Helper: Get random response from list
  String _getRandomResponse(List<String> responses) {
    if (responses.isEmpty) return "I understand.";
    final index = DateTime.now().millisecondsSinceEpoch % responses.length;
    return responses[index];
  }

  /// Reset conversation
  void reset() {
    _currentState = ChatState.idle;
    _roadmapData = RoadmapData();
    _conversationHistory.clear();
  }
}
