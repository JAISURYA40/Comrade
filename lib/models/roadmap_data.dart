/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

/// Data model for storing roadmap generation parameters.
class RoadmapData {
  final String? topic;
  final String? dailyTime;
  final String? level;
  final String? goal;

  RoadmapData({
    this.topic,
    this.dailyTime,
    this.level,
    this.goal,
  });

  bool get isComplete =>
      topic != null &&
      dailyTime != null &&
      level != null &&
      goal != null;

  RoadmapData copyWith({
    String? topic,
    String? dailyTime,
    String? level,
    String? goal,
  }) {
    return RoadmapData(
      topic: topic ?? this.topic,
      dailyTime: dailyTime ?? this.dailyTime,
      level: level ?? this.level,
      goal: goal ?? this.goal,
    );
  }
}

/// Roadmap phase structure
class RoadmapPhase {
  final String objective;
  final List<String> tasks;
  final String outcome;

  RoadmapPhase({
    required this.objective,
    required this.tasks,
    required this.outcome,
  });
}

/// Complete roadmap structure
class GeneratedRoadmap {
  final String goal;
  final String duration;
  final String dailyTime;
  final List<RoadmapPhase> phases;
  final String finalOutcome;

  GeneratedRoadmap({
    required this.goal,
    required this.duration,
    required this.dailyTime,
    required this.phases,
    required this.finalOutcome,
  });
}
