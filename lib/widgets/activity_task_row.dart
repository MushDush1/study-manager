import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/goal_activity.dart';
import '../theme/app_colors.dart';

/// 小任务一行：点左侧完成；右侧「排到明天」改期。
class ActivityTaskRow extends StatelessWidget {
    final Goal goal;
    final GoalActivity activity;
    final String dateKey;
    final VoidCallback onToggleDone;
    final VoidCallback onDeferTomorrow;
    final bool enableDefer;

    const ActivityTaskRow({
        super.key,
        required this.goal,
        required this.activity,
        required this.dateKey,
        required this.onToggleDone,
        required this.onDeferTomorrow,
        this.enableDefer = true,
    });

    @override
    Widget build(BuildContext context) {
        final checked = goal.isActivityDoneOn(activity.id, dateKey);
        final parked = goal.isActivityParkedOn(activity, dateKey);

        return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
                color: checked
                    ? goal.accentColor.withValues(alpha: 0.08)
                    : parked
                        ? const Color(0xFFEEF5FF)
                        : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                    children: [
                        Expanded(
                            child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: onToggleDone,
                                child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        10,
                                        10,
                                        8,
                                        10,
                                    ),
                                    child: Row(
                                        children: [
                                            Icon(
                                                checked
                                                    ? Icons.check_circle
                                                    : Icons.circle_outlined,
                                                size: 22,
                                                color: checked
                                                    ? goal.accentColor
                                                    : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Text(
                                                    activity.title,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        decoration: checked
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : TextDecoration.none,
                                                        color: checked
                                                            ? AppColors
                                                                .textSecondary
                                                            : AppColors.text,
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                        if (checked)
                            Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                    "已完成",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: goal.accentColor,
                                    ),
                                ),
                            )
                        else if (enableDefer)
                            TextButton(
                                onPressed: onDeferTomorrow,
                                style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: parked
                                        ? const Color(0xFF3A4A6B)
                                        : AppColors.textSecondary,
                                ),
                                child: Text(
                                    parked ? "改回今天" : "排到明天",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                    ),
                                ),
                            ),
                    ],
                ),
            ),
        );
    }
}
