import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/goal_activity.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_review_dialog.dart';

class ReviewPage extends StatefulWidget {
    final GoalStore store;

    const ReviewPage({
        super.key,
        required this.store,
    });

    @override
    State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
    String? _filterGoalId;

    @override
    Widget build(BuildContext context) {
        final allItems = widget.store.filteredActivityReviews(_filterGoalId);
        final dueItems = allItems.where((item) => item.review.isDue()).toList();
        final laterItems = allItems.where((item) => item.review.isLater()).toList();
        final subjectIds = widget.store.activityReviewEntries
            .map((item) => item.goal.id)
            .toSet();
        final subjects = widget.store.goals
            .where((goal) => subjectIds.contains(goal.id))
            .toList();

        return Scaffold(
            backgroundColor: AppColors.background,
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                    const Text(
                        "这里只放你勾完小任务时写下的回看点，例如错哪题、哪一段。",
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                        ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                            FilterChip(
                                label: const Text("全部"),
                                selected: _filterGoalId == null,
                                onSelected: (_) {
                                    setState(() {
                                        _filterGoalId = null;
                                    });
                                },
                            ),
                            ...subjects.map((goal) {
                                return FilterChip(
                                    label: Text(goal.title),
                                    selected: _filterGoalId == goal.id,
                                    onSelected: (_) {
                                        setState(() {
                                            _filterGoalId = goal.id;
                                        });
                                    },
                                );
                            }),
                        ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.store.activityReviewEntries.isEmpty)
                        const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: Text(
                                "还没有具体回看点。\n首页勾完一项后，写下「回看什么」才会出现在这里。",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.7,
                                    color: AppColors.textSecondary,
                                ),
                            ),
                        )
                    else if (dueItems.isEmpty && laterItems.isEmpty)
                        const Padding(
                            padding: EdgeInsets.only(top: 32),
                            child: Text(
                                "这个科目暂时没有回看点。",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary),
                            ),
                        )
                    else ...[
                        if (dueItems.isNotEmpty) ...[
                            Text(
                                "今天回看 ${dueItems.length} 条",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                            const SizedBox(height: 10),
                            ...dueItems.map((item) => _ReviewCard(
                                entry: item,
                                onEdit: () => _editPoint(item),
                                onDone: () => widget.store.finishActivityReview(
                                    goalId: item.goal.id,
                                    reviewId: item.review.id,
                                ),
                                onSnooze: (days) => widget.store.scheduleActivityReview(
                                    goalId: item.goal.id,
                                    reviewId: item.review.id,
                                    days: days,
                                ),
                            )),
                        ],
                        if (laterItems.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                                "以后再看 ${laterItems.length} 条",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                            const SizedBox(height: 10),
                            ...laterItems.map((item) => _ReviewCard(
                                entry: item,
                                onEdit: () => _editPoint(item),
                                onDone: () => widget.store.finishActivityReview(
                                    goalId: item.goal.id,
                                    reviewId: item.review.id,
                                ),
                                onSnooze: (days) => widget.store.scheduleActivityReview(
                                    goalId: item.goal.id,
                                    reviewId: item.review.id,
                                    days: days,
                                ),
                            )),
                        ],
                    ],
                ],
            ),
        );
    }

    Future<void> _editPoint(ActivityReviewEntry item) async {
        await showAddActivityReviewDialog(
            context: context,
            store: widget.store,
            goal: item.goal,
            activity: GoalActivity(
                id: item.review.activityId,
                title: item.review.activityTitle,
            ),
            doneDate: item.review.doneDate,
            reviewId: item.review.id,
            initialPoint: item.review.point,
        );
    }
}

class _ReviewCard extends StatelessWidget {
    final ActivityReviewEntry entry;
    final VoidCallback onEdit;
    final VoidCallback onDone;
    final ValueChanged<int> onSnooze;

    const _ReviewCard({
        required this.entry,
        required this.onEdit,
        required this.onDone,
        required this.onSnooze,
    });

    @override
    Widget build(BuildContext context) {
        final Goal goal = entry.goal;
        final ActivityReview review = entry.review;
        final later = review.isLater();

        return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                        color: goal.accentColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                        goal.title,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: goal.accentColor,
                                            fontWeight: FontWeight.w700,
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        review.activityTitle,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            review.point,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                height: 1.45,
                            ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                            later
                                ? "${review.doneDate} 做完 · 下次 ${review.nextReviewDate}"
                                : "${review.doneDate} 做完 · 今天该回看",
                            style: TextStyle(
                                fontSize: 12,
                                color: later
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: later
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                                TextButton(
                                    onPressed: onEdit,
                                    child: const Text("改回看点"),
                                ),
                                TextButton(
                                    onPressed: () => onSnooze(1),
                                    child: const Text("明天再看"),
                                ),
                                TextButton(
                                    onPressed: () => onSnooze(3),
                                    child: const Text("3天后再看"),
                                ),
                                FilledButton(
                                    onPressed: onDone,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                    ),
                                    child: const Text("记住了"),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }
}
