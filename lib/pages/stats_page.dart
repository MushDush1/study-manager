import 'package:flutter/material.dart';

import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/minutes_bar_chart.dart';

class StatsPage extends StatelessWidget {
    final GoalStore store;

    const StatsPage({super.key, required this.store});

    @override
    Widget build(BuildContext context) {
        final today = dateOnly(DateTime.now());
        final dates = List<DateTime>.generate(14, (index) {
            return today.subtract(Duration(days: 13 - index));
        });
        final minutes = dates.map((date) {
            final key = formatDate(date);
            return store.goals.fold<int>(0, (sum, goal) => sum + goal.minutesOn(key));
        }).toList();
        final colors = store.goals.isEmpty
            ? AppColors.accentPalette
            : store.goals.map((goal) => goal.accentColor).toList();

        return Scaffold(
            backgroundColor: AppColors.background,
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                    MinutesBarChart(
                        dates: dates,
                        minutes: minutes,
                        colors: colors,
                    ),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const Text(
                                    "各目标累计",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                    ),
                                ),
                                const SizedBox(height: 12),
                                ...store.goals.map((goal) {
                                    return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                            children: [
                                                Expanded(child: Text(goal.title)),
                                                Text(
                                                    "${goal.actualMinutes} 分钟 · ${goal.progressPercent}%",
                                                    style: TextStyle(
                                                        color: goal.accentColor,
                                                        fontWeight: FontWeight.w600,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    );
                                }),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}
