import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/goal_activity.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/unique_id.dart';
import '../widgets/activity_review_dialog.dart';
import '../widgets/activity_task_row.dart';
import '../widgets/jump_platform_card.dart';
import 'agent_page.dart';

class HomePage extends StatelessWidget {
    final GoalStore store;
    final ValueChanged<int> onOpenCheckIn;
    final VoidCallback onOpenReview;

    const HomePage({
        super.key,
        required this.store,
        required this.onOpenCheckIn,
        required this.onOpenReview,
    });

    Future<void> _arrangeTodayPlan(BuildContext context) async {
        final selected = {
            for (final goal in store.goals) goal.id: goal.isTodayPlan(),
        };

        final saved = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
                return StatefulBuilder(
                    builder: (context, setDialogState) {
                        return AlertDialog(
                            title: const Text("安排今日计划"),
                            content: SizedBox(
                                width: 360,
                                child: SingleChildScrollView(
                                    child: Column(
                                        children: store.goals.map((goal) {
                                            final enabled = selected[goal.id] ?? false;
                                            return SwitchListTile(
                                                key: ValueKey("plan_${goal.id}"),
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(goal.title),
                                                subtitle: goal.hasActivities
                                                    ? Text(
                                                        goal.activities
                                                            .map((item) => item.title)
                                                            .join(" · "),
                                                    )
                                                    : null,
                                                value: enabled,
                                                onChanged: (value) {
                                                    setDialogState(() {
                                                        selected[goal.id] = value;
                                                    });
                                                },
                                            );
                                        }).toList(),
                                    ),
                                ),
                            ),
                            actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text("取消"),
                                ),
                                TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text("保存"),
                                ),
                            ],
                        );
                    },
                );
            },
        );

        if (saved == true) {
            for (final goal in store.goals) {
                await store.setTodayPlan(
                    goalId: goal.id,
                    enabled: selected[goal.id] ?? false,
                );
            }
        }
    }

    Future<void> _editGoal(BuildContext context, {Goal? existing}) async {
        final titleController = TextEditingController(text: existing?.title ?? "");
        final descController = TextEditingController(
            text: existing?.goalDescription ?? "",
        );
        final unitController = TextEditingController(text: existing?.unit ?? "个");
        final amountController = TextEditingController(
            text: "${existing?.targetAmount ?? 20}",
        );
        final minutesController = TextEditingController(
            text: "${existing?.plannedMinutes ?? 30}",
        );
        final activityLines = [
            for (final activity in existing?.activities ?? <GoalActivity>[])
                _ActivityLine(
                    id: activity.id,
                    controller: TextEditingController(text: activity.title),
                ),
        ];
        if (activityLines.isEmpty) {
            activityLines.add(
                _ActivityLine(
                    id: createUniqueId(),
                    controller: TextEditingController(),
                ),
            );
        }

        final saved = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
                return StatefulBuilder(
                    builder: (context, setDialogState) {
                        return AlertDialog(
                            title: Text(existing == null ? "新增目标" : "修改目标"),
                            content: SizedBox(
                                width: 360,
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            TextField(
                                                controller: titleController,
                                                decoration: const InputDecoration(
                                                    labelText: "目标名称",
                                                    hintText: "例如：雅思听力",
                                                ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                                controller: descController,
                                                decoration: const InputDecoration(
                                                    labelText: "补充说明（可选）",
                                                    hintText: "例如：以剑桥真题为主",
                                                ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    "小任务（每个可单独勾完）",
                                                    style: TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                            ),
                                            const Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                    padding: EdgeInsets.only(top: 4, bottom: 8),
                                                    child: Text(
                                                        "例如日语N4 里放：背单词、听课文、语法。保存后出现在首页，点一项完成一项。",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors.textSecondary,
                                                            height: 1.4,
                                                        ),
                                                    ),
                                                ),
                                            ),
                                            ...activityLines.map((line) {
                                                return Padding(
                                                    padding: const EdgeInsets.only(bottom: 8),
                                                    child: Row(
                                                        children: [
                                                            Expanded(
                                                                child: TextField(
                                                                    controller: line.controller,
                                                                    decoration: const InputDecoration(
                                                                        hintText: "例如：背单词",
                                                                        isDense: true,
                                                                    ),
                                                                ),
                                                            ),
                                                            IconButton(
                                                                onPressed: () {
                                                                    setDialogState(() {
                                                                        activityLines.remove(line);
                                                                        line.controller.dispose();
                                                                    });
                                                                },
                                                                icon: const Icon(Icons.close, size: 18),
                                                            ),
                                                        ],
                                                    ),
                                                );
                                            }),
                                            TextButton.icon(
                                                onPressed: () {
                                                    setDialogState(() {
                                                        activityLines.add(
                                                            _ActivityLine(
                                                                id: createUniqueId(),
                                                                controller: TextEditingController(),
                                                            ),
                                                        );
                                                    });
                                                },
                                                icon: const Icon(Icons.add, size: 18),
                                                label: const Text("加一个小任务"),
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                                controller: minutesController,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                    labelText: "每天计划分钟",
                                                    hintText: "例如：30",
                                                ),
                                            ),
                                            if (activityLines.isEmpty) ...[
                                                const SizedBox(height: 12),
                                                TextField(
                                                    controller: amountController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(
                                                        labelText: "每天数量（没有小任务时用）",
                                                        hintText: "例如：20",
                                                    ),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                    controller: unitController,
                                                    decoration: const InputDecoration(
                                                        labelText: "数量单位",
                                                        hintText: "个 / 套 / 分钟 / 篇",
                                                    ),
                                                ),
                                            ],
                                        ],
                                    ),
                                ),
                            ),
                            actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text("取消"),
                                ),
                                TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text("保存"),
                                ),
                            ],
                        );
                    },
                );
            },
        );

        if (saved == true) {
            final title = titleController.text.trim();
            final amount = int.tryParse(amountController.text.trim()) ?? 0;
            final minutes = int.tryParse(minutesController.text.trim()) ?? 30;
            final oldPlanById = {
                for (final activity in existing?.activities ?? <GoalActivity>[])
                    activity.id: activity.planDate,
            };
            final activities = activityLines
                .map(
                    (line) => GoalActivity(
                        id: line.id,
                        title: line.controller.text.trim(),
                        planDate: oldPlanById[line.id] ?? "",
                    ),
                )
                .where((item) => item.title.isNotEmpty)
                .toList();
            if (title.isNotEmpty && (activities.isNotEmpty || amount > 0)) {
                if (existing == null) {
                    await store.addGoal(
                        Goal(
                            title: title,
                            goalDescription: descController.text.trim().isEmpty
                                ? title
                                : descController.text.trim(),
                            unit: unitController.text.trim().isEmpty
                                ? "个"
                                : unitController.text.trim(),
                            targetAmount: activities.isNotEmpty
                                ? activities.length
                                : amount,
                            plannedMinutes: minutes,
                            colorValue: AppColors.accentValue(store.goals.length),
                            activities: activities,
                        ),
                    );
                } else {
                    await store.updateGoal(
                        id: existing.id,
                        title: title,
                        goalDescription: descController.text.trim().isEmpty
                            ? title
                            : descController.text.trim(),
                        unit: unitController.text.trim(),
                        targetAmount: amount,
                        plannedMinutes: minutes,
                        activities: activities,
                    );
                }
                if (activities.isNotEmpty) {
                    final goalId = existing?.id ?? store.goals.last.id;
                    await store.setTodayPlan(goalId: goalId, enabled: true);
                }
            }
        }

        titleController.dispose();
        descController.dispose();
        unitController.dispose();
        amountController.dispose();
        minutesController.dispose();
        for (final line in activityLines) {
            line.controller.dispose();
        }
    }

    Future<void> _manageGoals(BuildContext context) async {
        await showDialog<void>(
            context: context,
            builder: (dialogContext) {
                return AlertDialog(
                    title: const Text("管理每日目标"),
                    content: SizedBox(
                        width: 360,
                        child: ListenableBuilder(
                            listenable: store,
                            builder: (context, child) {
                                return SingleChildScrollView(
                                    child: Column(
                                        children: [
                                            ...store.goals.map((goal) {
                                                return ListTile(
                                                    contentPadding: EdgeInsets.zero,
                                                    title: Text(goal.title),
                                                    subtitle: Text(
                                                        goal.hasActivities
                                                            ? "${goal.activities.length} 个小任务 · 今天 ${goal.todayDoneAmount}/${goal.dailyTargetCount}"
                                                            : "每天 ${goal.targetAmount} ${goal.unit} · 今天 ${goal.todayDoneAmount}/${goal.targetAmount}",
                                                    ),
                                                    trailing: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                            IconButton(
                                                                tooltip: "修改",
                                                                onPressed: () {
                                                                    Navigator.pop(dialogContext);
                                                                    _editGoal(context, existing: goal);
                                                                },
                                                                icon: const Icon(Icons.edit_outlined, size: 20),
                                                            ),
                                                            IconButton(
                                                                tooltip: "删除",
                                                                onPressed: () async {
                                                                    await store.deleteGoal(goal.id);
                                                                },
                                                                icon: const Icon(Icons.delete_outline, size: 20),
                                                            ),
                                                        ],
                                                    ),
                                                );
                                            }),
                                            TextButton.icon(
                                                onPressed: () {
                                                    Navigator.pop(dialogContext);
                                                    _editGoal(context);
                                                },
                                                icon: const Icon(Icons.add),
                                                label: const Text("新增目标"),
                                            ),
                                        ],
                                    ),
                                );
                            },
                        ),
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("完成"),
                        ),
                    ],
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        final today = formatDate(DateTime.now());
        final todayPlans = store.todayPlans.where((goal) {
            if (!goal.hasActivities) {
                return true;
            }
            return goal.activitiesDueOn(today).isNotEmpty;
        }).toList();
        final parkedByGoal = [
            for (final goal in store.goals)
                if (goal.activitiesParkedOn(today).isNotEmpty) goal,
        ];
        final doneCount = todayPlans.where((goal) {
            if (goal.hasActivities) {
                return goal.metDailyTargetOn(today);
            }
            return goal.hasCheckInOn(today);
        }).length;
        final dueReviewCount = store.dueActivityReviews.length;

        return Scaffold(
            backgroundColor: AppColors.background,
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                    InkWell(
                        onTap: () => openAgentPage(context, store),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                                children: [
                                    Icon(
                                        Icons.auto_awesome,
                                        color: AppColors.primary,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text(
                                                    "Agent",
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.text,
                                                    ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                    "问今天学什么、下一步做什么",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textSecondary,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                    ),
                                ],
                            ),
                        ),
                    ),
                    const SizedBox(height: 12),
                    const JumpPlatformCard(),
                    const SizedBox(height: 16),
                    Row(
                        children: [
                            const Icon(Icons.today_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                                "今日计划",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                ),
                            ),
                            const Spacer(),
                            TextButton(
                                onPressed: () => _manageGoals(context),
                                child: const Text("管理目标"),
                            ),
                            TextButton(
                                onPressed: () => _arrangeTodayPlan(context),
                                child: const Text("安排"),
                            ),
                        ],
                    ),
                    const SizedBox(height: 8),
                    if (todayPlans.isEmpty && parkedByGoal.isEmpty)
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEEF5FF),
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                                "还没有今日计划。点「管理目标」给科目加上小任务，保存后会出现在这里；也可以点「安排」勾选今晚要做的科目。",
                                style: TextStyle(fontSize: 13, color: Color(0xFF3A4A6B), height: 1.5),
                            ),
                        )
                    else if (todayPlans.isNotEmpty)
                        Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                                children: [
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                            "今天 $doneCount / ${todayPlans.length} 项已完成 · 右侧可排到明天",
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                            ),
                                        ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...todayPlans.map((goal) {
                                        return _TodayPlanTile(
                                            goal: goal,
                                            today: today,
                                            store: store,
                                            onTap: () {
                                                store.selectGoalById(goal.id);
                                                onOpenCheckIn(1);
                                            },
                                            onEdit: () => _editGoal(
                                                context,
                                                existing: goal,
                                            ),
                                        );
                                    }),
                                ],
                            ),
                        ),
                    if (parkedByGoal.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEEF5FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFD7E4F5)),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                        "明天要做",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF3A4A6B),
                                        ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                        "今天列表里不出现。点「改回今天」可撤回来。",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                        ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...parkedByGoal.map((goal) {
                                        return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                    Text(
                                                        goal.title,
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.text,
                                                        ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    ...goal
                                                        .activitiesParkedOn(today)
                                                        .map((activity) {
                                                        return ActivityTaskRow(
                                                            goal: goal,
                                                            activity: activity,
                                                            dateKey: today,
                                                            onToggleDone: () {
                                                                completeActivityAndAskReview(
                                                                    context: context,
                                                                    store: store,
                                                                    goal: goal,
                                                                    activity: activity,
                                                                );
                                                            },
                                                            onDeferTomorrow: () {
                                                                store.deferActivityToTomorrow(
                                                                    goalId: goal.id,
                                                                    activityId:
                                                                        activity.id,
                                                                );
                                                            },
                                                        );
                                                    }),
                                                ],
                                            ),
                                        );
                                    }),
                                ],
                            ),
                        ),
                    ],
                    if (dueReviewCount > 0) ...[
                        const SizedBox(height: 12),
                        InkWell(
                            onTap: onOpenReview,
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                    color: AppColors.sidebarSelected,
                                    borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                    children: [
                                        const Icon(
                                            Icons.menu_book_rounded,
                                            color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                                "今天有 $dueReviewCount 条具体回看点，点这里复习",
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors.text,
                                                ),
                                            ),
                                        ),
                                        const Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppColors.textSecondary,
                                        ),
                                    ],
                                ),
                            ),
                        ),
                    ],
                ],
            ),
        );
    }
}

class _ActivityLine {
    final String id;
    final TextEditingController controller;

    _ActivityLine({
        required this.id,
        required this.controller,
    });
}

String _activityProgressText(Goal goal, String today) {
    final dueCount = goal.activitiesDueOn(today).length;
    return "${goal.todayDoneAmount}/$dueCount 已完成";
}

class _TodayPlanTile extends StatelessWidget {
    final Goal goal;
    final String today;
    final GoalStore store;
    final VoidCallback onTap;
    final VoidCallback? onEdit;

    const _TodayPlanTile({
        required this.goal,
        required this.today,
        required this.store,
        required this.onTap,
        this.onEdit,
    });

    @override
    Widget build(BuildContext context) {
        if (goal.hasActivities) {
            return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                                onTap: onTap,
                                onLongPress: onEdit,
                                child: Row(
                                    children: [
                                        Expanded(
                                            child: Text(
                                                goal.title,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.text,
                                                ),
                                            ),
                                        ),
                                        Text(
                                            _activityProgressText(goal, today),
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: goal.accentColor,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ),
                        ...goal.activitiesDueOn(today).map((activity) {
                            return ActivityTaskRow(
                                goal: goal,
                                activity: activity,
                                dateKey: today,
                                onToggleDone: () {
                                    completeActivityAndAskReview(
                                        context: context,
                                        store: store,
                                        goal: goal,
                                        activity: activity,
                                    );
                                },
                                onDeferTomorrow: () {
                                    store.deferActivityToTomorrow(
                                        goalId: goal.id,
                                        activityId: activity.id,
                                    );
                                },
                            );
                        }),
                    ],
                ),
            );
        }

        final done = goal.hasCheckInOn(today);
        final actual = goal.minutesOn(today);
        final content = goal.todayPlanContent.trim();

        return Material(
            color: Colors.transparent,
            child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: onTap,
                leading: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? goal.accentColor : AppColors.textSecondary,
                ),
                title: Text(
                    goal.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                    [
                        if (content.isNotEmpty) content,
                        done
                            ? "实际 $actual 分钟 / 计划 ${goal.plannedMinutes} 分钟"
                            : "计划 ${goal.plannedMinutes} 分钟 · 还没打卡",
                    ].join("\n"),
                ),
                isThreeLine: content.isNotEmpty,
                trailing: const Icon(Icons.chevron_right_rounded),
            ),
        );
    }
}
