/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const StyledText(
          "Roadmap",
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: Icon(
            FluentIcons.chevron_left_24_filled,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Main Goal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RoundedContainer(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            FluentIcons.target_arrow_20_filled,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        12.hBox,
                        Expanded(
                          child: StyledText(
                            "Main Goal",
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    16.vBox,
                    StyledText(
                      "Build a consistent focus routine and improve productivity",
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),

          24.vSliverBox,

          // Roadmap Steps
          const ContentSectionHeader(
            title: "Roadmap Steps",
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 12),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final step = _roadmapSteps[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: index == _roadmapSteps.length - 1 ? 16 : 12,
                  ),
                  child: _RoadmapStepCard(step: step),
                );
              },
              childCount: _roadmapSteps.length,
            ),
          ),

          const SliverTabsBottomPadding(),
        ],
      ),
    );
  }
}

class RoadmapStep {
  final String title;
  final String description;
  final StepStatus status;
  final List<String> tasks;

  RoadmapStep({
    required this.title,
    required this.description,
    required this.status,
    required this.tasks,
  });
}

enum StepStatus {
  completed,
  inProgress,
  pending,
}

final List<RoadmapStep> _roadmapSteps = [
  RoadmapStep(
    title: "Set Up Focus Environment",
    description: "Create a distraction-free workspace",
    status: StepStatus.completed,
    tasks: [
      "Enable focus mode during work hours",
      "Block distracting apps",
      "Set up notification schedules",
    ],
  ),
  RoadmapStep(
    title: "Define Daily Goals",
    description: "Break down your main goal into daily actionable tasks",
    status: StepStatus.inProgress,
    tasks: [
      "Set screen time limits",
      "Create app usage restrictions",
      "Schedule focus sessions",
    ],
  ),
  RoadmapStep(
    title: "Track Progress",
    description: "Monitor your productivity and adjust as needed",
    status: StepStatus.pending,
    tasks: [
      "Review daily statistics",
      "Analyze app usage patterns",
      "Adjust restrictions based on progress",
    ],
  ),
  RoadmapStep(
    title: "Maintain Consistency",
    description: "Build long-term habits for sustained productivity",
    status: StepStatus.pending,
    tasks: [
      "Stick to your schedule",
      "Review and refine weekly",
      "Celebrate milestones",
    ],
  ),
];

class _RoadmapStepCard extends StatelessWidget {
  const _RoadmapStepCard({required this.step});

  final RoadmapStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(theme, step.status);
    final statusText = _getStatusText(step.status);

    return RoundedContainer(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Expanded(
                child: StyledText(
                  step.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              8.hBox,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: StyledText(
                  statusText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          8.vBox,
          StyledText(
            step.description,
            fontSize: 14,
            isSubtitle: true,
          ),
          16.vBox,
          // Tasks
          ...step.tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      step.status == StepStatus.completed
                          ? FluentIcons.checkmark_circle_20_filled
                          : FluentIcons.circle_20_regular,
                      size: 18,
                      color: step.status == StepStatus.completed
                          ? statusColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    8.hBox,
                    Expanded(
                      child: StyledText(
                        task,
                        fontSize: 14,
                        color: step.status == StepStatus.completed
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, StepStatus status) {
    switch (status) {
      case StepStatus.completed:
        return Colors.green;
      case StepStatus.inProgress:
        return theme.colorScheme.primary;
      case StepStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(StepStatus status) {
    switch (status) {
      case StepStatus.completed:
        return "Completed";
      case StepStatus.inProgress:
        return "In Progress";
      case StepStatus.pending:
        return "Pending";
    }
  }
}
