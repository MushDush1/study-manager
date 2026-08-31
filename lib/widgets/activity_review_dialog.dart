import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/goal_activity.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

String reviewHintFor(String goalTitle) {
    if (goalTitle.contains("阅读")) {
        return "例如：C7T1 Q14 判断错了，回看第2段";
    }
    if (goalTitle.contains("听力")) {
        return "例如：Section 2 地图题漏听，重听 12:30";
    }
    if (goalTitle.contains("口语")) {
        return "例如：c9t3p1 第3题卡壳，再录一遍";
    }
    if (goalTitle.contains("日语")) {
        return "例如：て形那几句再写一遍";
    }
    if (goalTitle.contains("单词") || goalTitle.contains("词汇")) {
        return "例如：c1-1-3 里记混的 5 个词";
    }
    return "例如：哪一题错了、看到第几分钟、哪一页";
}

Future<void> completeActivityAndAskReview({
    required BuildContext context,
    required GoalStore store,
    required Goal goal,
    required GoalActivity activity,
    DateTime? date,
}) async {
    final dateKey = formatDate(date ?? DateTime.now());
    final alreadyDone = goal.isActivityDoneOn(activity.id, dateKey);
    await store.toggleActivityDone(
        goalId: goal.id,
        activityId: activity.id,
        date: date,
    );
    if (alreadyDone || !context.mounted) {
        return;
    }
    await showAddActivityReviewDialog(
        context: context,
        store: store,
        goal: goal,
        activity: activity,
        doneDate: dateKey,
    );
}

Future<void> showAddActivityReviewDialog({
    required BuildContext context,
    required GoalStore store,
    required Goal goal,
    required GoalActivity activity,
    required String doneDate,
    String? reviewId,
    String initialPoint = "",
}) async {
    final controller = TextEditingController(text: initialPoint);
    final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
            return AlertDialog(
                title: Text(reviewId == null ? "记下回看点" : "改回看点"),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                "${goal.title} · ${activity.title}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                                "写具体一点：错哪题、哪一段、哪分钟。空着不会进复习。",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                                controller: controller,
                                maxLines: 4,
                                autofocus: true,
                                decoration: InputDecoration(
                                    labelText: "回看什么",
                                    hintText: reviewHintFor(goal.title),
                                    alignLabelWithHint: true,
                                ),
                            ),
                        ],
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(reviewId == null ? "这次不回看" : "取消"),
                    ),
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text("加入复习"),
                    ),
                ],
            );
        },
    );
    final point = controller.text.trim();
    controller.dispose();
    if (saved != true || point.isEmpty) {
        return;
    }
    if (reviewId == null) {
        await store.addActivityReview(
            goalId: goal.id,
            activity: activity,
            doneDate: doneDate,
            point: point,
        );
        return;
    }
    await store.updateActivityReviewPoint(
        goalId: goal.id,
        reviewId: reviewId,
        point: point,
    );
}
