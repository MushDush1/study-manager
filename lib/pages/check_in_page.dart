import 'package:flutter/material.dart';

import '../models/check_in_record.dart';
import '../models/goal.dart';
import '../models/goal_activity.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/activity_review_dialog.dart';
import '../widgets/activity_task_row.dart';
import '../widgets/pomodoro_panel.dart';
import '../widgets/resource_jump_bar.dart';

class CheckInPage extends StatefulWidget {
    final GoalStore store;

    const CheckInPage({super.key, required this.store});

    @override
    State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
    final TextEditingController _quantityController = TextEditingController(text: "1");
    final TextEditingController _minutesController = TextEditingController(text: "30");
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _summaryController = TextEditingController();
    DateTime _selectedDate = DateTime.now();
    bool _needsReview = false;
    String? _prefilledGoalId;

    @override
    void dispose() {
        _quantityController.dispose();
        _minutesController.dispose();
        _titleController.dispose();
        _summaryController.dispose();
        super.dispose();
    }

    Future<void> _submit() async {
        final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
        final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
        final goal = widget.store.selectedGoal;
        final dateKey = formatDate(_selectedDate);

        if (goal != null && goal.hasActivities) {
            if (minutes <= 0 && goal.activityDoneCountOn(dateKey) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("请勾选完成的事项，或填写分钟")),
                );
                return;
            }
        } else if (quantity <= 0 && minutes <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("请至少填写数量或分钟")),
            );
            return;
        }

        await widget.store.addCheckIn(
            quantity: quantity,
            minutes: minutes,
            date: _selectedDate,
            title: _titleController.text.trim(),
            summary: _summaryController.text.trim(),
            needsReview: _needsReview,
        );

        if (!mounted) {
            return;
        }

        _titleController.clear();
        _summaryController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text("打卡成功"),
            ),
        );
    }

    Future<void> _editBackupPlan(Goal goal) async {
        final controller = TextEditingController(text: goal.backupPlan);
        final result = await showDialog<String>(
            context: context,
            builder: (dialogContext) {
                return AlertDialog(
                    title: const Text("编辑预案"),
                    content: TextField(
                        controller: controller,
                        maxLines: 4,
                        decoration: const InputDecoration(hintText: "写一条完不成时的替代方案"),
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("取消"),
                        ),
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
                            child: const Text("保存"),
                        ),
                    ],
                );
            },
        );

        if (result != null) {
            await widget.store.updateBackupPlan(result);
        }
    }

    Future<void> _editMaterials(Goal goal) async {
        final linkController = TextEditingController(text: goal.videoLink);
        final baiduNameController = TextEditingController(text: goal.baiduVideoName);
        final baiduPathController = TextEditingController(text: goal.baiduFolderPath);
        final localPathController = TextEditingController(text: goal.localFilePath);

        final saved = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
                return AlertDialog(
                    title: const Text("编辑学习资料"),
                    content: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                TextField(
                                    controller: linkController,
                                    decoration: const InputDecoration(
                                        hintText: "B站或网页链接",
                                    ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: baiduNameController,
                                    decoration: const InputDecoration(
                                        hintText: "百度网盘视频 / 课程名",
                                    ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: baiduPathController,
                                    decoration: const InputDecoration(
                                        hintText: "百度网盘文件夹位置",
                                    ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: localPathController,
                                    decoration: const InputDecoration(
                                        hintText: "本地 Excel / PDF / 文件夹路径",
                                    ),
                                ),
                            ],
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

        if (saved == true) {
            await widget.store.updateMaterials(
                videoLink: linkController.text.trim(),
                baiduVideoName: baiduNameController.text.trim(),
                baiduFolderPath: baiduPathController.text.trim(),
                localFilePath: localPathController.text.trim(),
            );
        }

        linkController.dispose();
        baiduNameController.dispose();
        baiduPathController.dispose();
        localPathController.dispose();
    }

    Future<void> _editRecord(Goal goal, CheckInRecord record) async {
        final titleController = TextEditingController(text: record.title);
        final summaryController = TextEditingController(text: record.summary);
        final quantityController = TextEditingController(text: "${record.quantity}");
        final minutesController = TextEditingController(text: "${record.minutes}");
        var needsReview = record.needsReview;

        final saved = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
                return StatefulBuilder(
                    builder: (context, setDialogState) {
                        return AlertDialog(
                            title: const Text("编辑这条计划总结"),
                            content: SingleChildScrollView(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        TextField(
                                            controller: titleController,
                                            decoration: const InputDecoration(hintText: "今天学了什么"),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                            controller: summaryController,
                                            maxLines: 4,
                                            decoration: const InputDecoration(hintText: "复习总结"),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                            controller: quantityController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(hintText: "数量"),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                            controller: minutesController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(hintText: "分钟"),
                                        ),
                                        SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text("加入后期复习"),
                                            value: needsReview,
                                            onChanged: (value) {
                                                setDialogState(() {
                                                    needsReview = value;
                                                });
                                            },
                                        ),
                                    ],
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
            await widget.store.updateCheckIn(
                goalId: goal.id,
                recordId: record.id,
                quantity: int.tryParse(quantityController.text.trim()) ?? record.quantity,
                minutes: int.tryParse(minutesController.text.trim()) ?? record.minutes,
                title: titleController.text.trim(),
                summary: summaryController.text.trim(),
                needsReview: needsReview,
            );
        }

        titleController.dispose();
        summaryController.dispose();
        quantityController.dispose();
        minutesController.dispose();
    }

    Future<void> _deleteRecord(Goal goal, CheckInRecord record) async {
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
                return AlertDialog(
                    title: const Text("删除这条记录？"),
                    content: const Text("总结会一起删掉，复习箱里也不会再出现。"),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text("取消"),
                        ),
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text("删除"),
                        ),
                    ],
                );
            },
        );

        if (confirmed == true) {
            await widget.store.deleteCheckIn(goalId: goal.id, recordId: record.id);
        }
    }

    void _syncPlanPrefill(Goal goal) {
        if (_prefilledGoalId == goal.id) {
            return;
        }
        _prefilledGoalId = goal.id;
        if (!goal.isTodayPlan()) {
            return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
                return;
            }
            if (goal.todayPlanContent.trim().isNotEmpty &&
                _titleController.text.trim().isEmpty) {
                _titleController.text = goal.todayPlanContent;
            }
            _minutesController.text = "${goal.plannedMinutes}";
        });
    }

    @override
    Widget build(BuildContext context) {
        final goal = widget.store.selectedGoal;

        return Scaffold(
            backgroundColor: AppColors.background,
            body: LayoutBuilder(
                builder: (context, constraints) {
                    final useSidebar = constraints.maxWidth >= 720;

                    if (goal == null) {
                        return const Center(child: Text("还没有目标"));
                    }

                    _syncPlanPrefill(goal);

                    final detail = _GoalDetailPane(
                        goal: goal,
                        quantityController: _quantityController,
                        minutesController: _minutesController,
                        titleController: _titleController,
                        summaryController: _summaryController,
                        selectedDate: _selectedDate,
                        needsReview: _needsReview,
                        onNeedsReviewChanged: (value) {
                            setState(() {
                                _needsReview = value;
                            });
                        },
                        onToggleTodayPlan: (enabled) {
                            widget.store.setTodayPlan(goalId: goal.id, enabled: enabled);
                        },
                        onToggleActivity: (activityId) {
                            GoalActivity? activity;
                            for (final item in goal.activities) {
                                if (item.id == activityId) {
                                    activity = item;
                                    break;
                                }
                            }
                            if (activity == null) {
                                return;
                            }
                            completeActivityAndAskReview(
                                context: context,
                                store: widget.store,
                                goal: goal,
                                activity: activity,
                                date: _selectedDate,
                            );
                        },
                        onDeferActivity: (activityId) {
                            widget.store.deferActivityToTomorrow(
                                goalId: goal.id,
                                activityId: activityId,
                            );
                        },
                        onPickDate: () async {
                            final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                                setState(() {
                                    _selectedDate = picked;
                                });
                            }
                        },
                        onSubmit: _submit,
                        onEditBackup: () => _editBackupPlan(goal),
                        onEditMaterials: () => _editMaterials(goal),
                        onEditRecord: (record) => _editRecord(goal, record),
                        onDeleteRecord: (record) => _deleteRecord(goal, record),
                    );

                    if (!useSidebar) {
                        return ListView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                            children: [
                                SizedBox(
                                    height: 52,
                                    child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: widget.store.goals.length,
                                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                            final item = widget.store.goals[index];
                                            final selected = index == widget.store.selectedIndex;
                                            return ChoiceChip(
                                                label: Text("${item.title} ${item.todayProgressPercent}%"),
                                                selected: selected,
                                                onSelected: (_) => widget.store.selectGoal(index),
                                                selectedColor: AppColors.sidebarSelected,
                                            );
                                        },
                                    ),
                                ),
                                const SizedBox(height: 12),
                                PomodoroPanel(store: widget.store),
                                const SizedBox(height: 12),
                                detail,
                            ],
                        );
                    }

                    return Row(
                        children: [
                            SizedBox(
                                width: 220,
                                child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                                    itemCount: widget.store.goals.length,
                                    itemBuilder: (context, index) {
                                        final item = widget.store.goals[index];
                                        final selected = index == widget.store.selectedIndex;
                                        return InkWell(
                                            onTap: () => widget.store.selectGoal(index),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                                margin: const EdgeInsets.only(bottom: 6),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                    color: selected
                                                        ? AppColors.sidebarSelected
                                                        : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                    children: [
                                                        Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration: BoxDecoration(
                                                                color: item.accentColor,
                                                                shape: BoxShape.circle,
                                                            ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                            child: Text(
                                                                item.title,
                                                                style: TextStyle(
                                                                    fontSize: 13,
                                                                    fontWeight: selected
                                                                        ? FontWeight.w700
                                                                        : FontWeight.w500,
                                                                    color: AppColors.text,
                                                                ),
                                                            ),
                                                        ),
                                                        Text(
                                                            "${item.todayProgressPercent}%",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: item.accentColor,
                                                                fontWeight: FontWeight.w600,
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        );
                                    },
                                ),
                            ),
                            Expanded(
                                child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 24),
                                    child: Column(
                                        children: [
                                            PomodoroPanel(store: widget.store),
                                            const SizedBox(height: 12),
                                            detail,
                                        ],
                                    ),
                                ),
                            ),
                        ],
                    );
                },
            ),
        );
    }
}

class _GoalDetailPane extends StatelessWidget {
    final Goal goal;
    final TextEditingController quantityController;
    final TextEditingController minutesController;
    final TextEditingController titleController;
    final TextEditingController summaryController;
    final DateTime selectedDate;
    final bool needsReview;
    final ValueChanged<bool> onNeedsReviewChanged;
    final ValueChanged<bool> onToggleTodayPlan;
    final ValueChanged<String> onToggleActivity;
    final ValueChanged<String> onDeferActivity;
    final VoidCallback onPickDate;
    final VoidCallback onSubmit;
    final VoidCallback onEditBackup;
    final VoidCallback onEditMaterials;
    final ValueChanged<CheckInRecord> onEditRecord;
    final ValueChanged<CheckInRecord> onDeleteRecord;

    const _GoalDetailPane({
        required this.goal,
        required this.quantityController,
        required this.minutesController,
        required this.titleController,
        required this.summaryController,
        required this.selectedDate,
        required this.needsReview,
        required this.onNeedsReviewChanged,
        required this.onToggleTodayPlan,
        required this.onToggleActivity,
        required this.onDeferActivity,
        required this.onPickDate,
        required this.onSubmit,
        required this.onEditBackup,
        required this.onEditMaterials,
        required this.onEditRecord,
        required this.onDeleteRecord,
    });

    @override
    Widget build(BuildContext context) {
        final streak = goal.consecutiveDays();
        final dateKey = formatDate(selectedDate);
        final isSelectedToday = dateKey == formatDate(DateTime.now());

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Material(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                                children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: goal.accentColor,
                                            shape: BoxShape.circle,
                                        ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            goal.goalDescription,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.text,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                "今天 ${goal.todayDoneAmount} / ${goal.dailyTargetCount} ${goal.progressUnit}（${goal.todayProgressPercent}%）",
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                    value: goal.todayProgress,
                                    minHeight: 6,
                                    backgroundColor: AppColors.border,
                                    color: goal.accentColor,
                                ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                                streak > 0
                                    ? "已连续打卡 $streak 天 · 今天还差 ${goal.todayRemaining} ${goal.progressUnit}"
                                    : "今天还差 ${goal.todayRemaining} ${goal.progressUnit}",
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                ),
                            ),
                            const SizedBox(height: 16),
                            if (goal.hasActivities) ...[
                                const Text(
                                    "小任务（点圆圈完成，右侧「排到明天」改期）",
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                ...goal.activitiesDueOn(dateKey).map((activity) {
                                    return ActivityTaskRow(
                                        goal: goal,
                                        activity: activity,
                                        dateKey: dateKey,
                                        enableDefer: isSelectedToday,
                                        onToggleDone: () =>
                                            onToggleActivity(activity.id),
                                        onDeferTomorrow: () =>
                                            onDeferActivity(activity.id),
                                    );
                                }),
                                if (goal.activitiesParkedOn(dateKey).isNotEmpty)
                                    Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                            "另有 ${goal.activitiesParkedOn(dateKey).length} 项已排到明天，在首页「明天要做」里",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                            ),
                                        ),
                                    ),
                                const SizedBox(height: 8),
                            ],
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("加入今日计划"),
                                subtitle: Text(
                                    goal.todayPlanContent.trim().isEmpty
                                        ? "计划 ${goal.plannedMinutes} 分钟"
                                        : "今天：${goal.todayPlanContent} · ${goal.plannedMinutes} 分钟",
                                ),
                                value: goal.isTodayPlan(),
                                onChanged: onToggleTodayPlan,
                            ),
                            TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                    labelText: "今天学了什么",
                                    hintText: "例如：剑桥 16 Test 3 Section 2",
                                ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                                controller: summaryController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                    labelText: "这条计划的复习总结",
                                    hintText: "卡点、易错、下次复习时要看什么",
                                    alignLabelWithHint: true,
                                ),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("加入后期复习"),
                                subtitle: const Text("勾选后会出现在「复习」页，方便回头看"),
                                value: needsReview,
                                onChanged: onNeedsReviewChanged,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                    if (!goal.hasActivities)
                                        _LabeledField(
                                            label: "数量",
                                            controller: quantityController,
                                        ),
                                    _LabeledField(
                                        label: "分钟(估算)",
                                        controller: minutesController,
                                    ),
                                    InkWell(
                                        onTap: onPickDate,
                                        child: Container(
                                            width: 140,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppColors.border),
                                            ),
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    const Text(
                                                        "日期",
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors.textSecondary,
                                                        ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                        formatSlashDate(selectedDate),
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ),
                                    FilledButton.icon(
                                        onPressed: onSubmit,
                                        style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 22,
                                                vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(24),
                                            ),
                                        ),
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text("打卡"),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    ),
                ),
                const SizedBox(height: 14),
                Container(
                    width: double.infinity,
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
                                    const Text(
                                        "预案",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                        ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                        onPressed: onEditBackup,
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        tooltip: "编辑",
                                    ),
                                ],
                            ),
                            Text(
                                goal.backupPlan.isEmpty ? "还没有预案，点编辑补一条。" : goal.backupPlan,
                                style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: AppColors.textSecondary,
                                ),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 14),
                ResourceJumpBar(
                    goal: goal,
                    onEdit: onEditMaterials,
                ),
                const SizedBox(height: 14),
                Container(
                    width: double.infinity,
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
                                "这个目标的学习记录",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                            const SizedBox(height: 8),
                            if (goal.checkIns.isEmpty)
                                const Text(
                                    "还没有记录。打卡后，每条计划的总结都会留在这里。",
                                    style: TextStyle(color: AppColors.textSecondary),
                                )
                            else
                                ...goal.recordsNewestFirst().map((record) {
                                    final title = record.title.trim().isEmpty
                                        ? "未填写学习内容"
                                        : record.title;
                                    return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Row(
                                                        children: [
                                                            Expanded(
                                                                child: Text(
                                                                    title,
                                                                    style: const TextStyle(
                                                                        fontWeight: FontWeight.w700,
                                                                    ),
                                                                ),
                                                            ),
                                                            if (record.needsReview)
                                                                const Text(
                                                                    "待复习",
                                                                    style: TextStyle(
                                                                        fontSize: 12,
                                                                        color: AppColors.primary,
                                                                        fontWeight: FontWeight.w600,
                                                                    ),
                                                                ),
                                                        ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                        "${record.date} · ${record.quantity} ${goal.unit} · ${record.minutes} 分钟",
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors.textSecondary,
                                                        ),
                                                    ),
                                                    if (record.summary.trim().isNotEmpty) ...[
                                                        const SizedBox(height: 6),
                                                        Text(
                                                            record.summary,
                                                            style: const TextStyle(
                                                                fontSize: 13,
                                                                height: 1.5,
                                                                color: AppColors.textSecondary,
                                                            ),
                                                        ),
                                                    ],
                                                    Row(
                                                        children: [
                                                            TextButton(
                                                                onPressed: () => onEditRecord(record),
                                                                child: const Text("编辑"),
                                                            ),
                                                            TextButton(
                                                                onPressed: () => onDeleteRecord(record),
                                                                child: const Text("删除"),
                                                            ),
                                                        ],
                                                    ),
                                                ],
                                            ),
                                        ),
                                    );
                                }),
                        ],
                    ),
                ),
            ],
        );
    }
}

class _LabeledField extends StatelessWidget {
    final String label;
    final TextEditingController controller;

    const _LabeledField({
        required this.label,
        required this.controller,
    });

    @override
    Widget build(BuildContext context) {
        return SizedBox(
            width: 110,
            child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: label,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                    ),
                ),
            ),
        );
    }
}
