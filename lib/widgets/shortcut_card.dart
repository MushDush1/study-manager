import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../theme/app_colors.dart';

class ShortcutCard extends StatelessWidget {
    final Goal goal;
    final VoidCallback onTap;
    final VoidCallback? onLongPress;

    const ShortcutCard({
        super.key,
        required this.goal,
        required this.onTap,
        this.onLongPress,
    });

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                onLongPress: onLongPress,
                child: Ink(
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                        child: Column(
                            children: [
                                Icon(
                                    goal.iconData,
                                    color: goal.accentColor,
                                    size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    goal.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                    ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    "今天 ${goal.todayDoneAmount}/${goal.dailyTargetCount}",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: goal.accentColor,
                                        fontWeight: FontWeight.w600,
                                    ),
                                ),
                                const Spacer(),
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                        value: goal.todayProgress,
                                        minHeight: 4,
                                        backgroundColor: AppColors.border,
                                        color: goal.accentColor,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
