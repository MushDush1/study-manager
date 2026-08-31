import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

class BoardPage extends StatefulWidget {
    final GoalStore store;
    final ValueChanged<String>? onOpenGoal;

    const BoardPage({
        super.key,
        required this.store,
        this.onOpenGoal,
    });

    @override
    State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
    late DateTime _weekStart;
    DateTime? _selectedDay;

    @override
    void initState() {
        super.initState();
        _weekStart = startOfWeek(DateTime.now());
        _selectedDay = dateOnly(DateTime.now());
    }

    void _jumpTo(DateTime date) {
        final day = dateOnly(date);
        setState(() {
            _weekStart = startOfWeek(day);
            _selectedDay = day;
        });
    }

    void _shiftWeek(int days) {
        setState(() {
            _weekStart = _weekStart.add(Duration(days: days));
            if (_selectedDay != null) {
                _selectedDay = _selectedDay!.add(Duration(days: days));
            }
        });
    }

    Future<void> _pickDate() async {
        final today = dateOnly(DateTime.now());
        final initial = _selectedDay ?? today;
        final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(2024, 1, 1),
            lastDate: DateTime(today.year + 1, 12, 31),
            currentDate: today,
            initialEntryMode: DatePickerEntryMode.calendar,
            helpText: "跳转到日期",
            cancelText: "取消",
            confirmText: "确定",
            fieldHintText: "年/月/日",
            fieldLabelText: "日期",
        );
        if (picked == null || !mounted) {
            return;
        }
        _jumpTo(picked);
    }

    @override
    Widget build(BuildContext context) {
        final days = weekDays(_weekStart);
        final weekEnd = days.last;
        final today = dateOnly(DateTime.now());
        final selected = _selectedDay ?? today;
        final selectedKey = formatDate(selected);
        final goals = widget.store.goals;

        var weekMinutes = 0;
        var weekHits = 0;
        var weekSlots = 0;
        for (final day in days) {
            final key = formatDate(day);
            final isFuture = day.isAfter(today);
            for (final goal in goals) {
                weekMinutes += goal.recordedMinutesOn(key);
                if (!isFuture) {
                    weekSlots += 1;
                    if (goal.metDailyTargetOn(key)) {
                        weekHits += 1;
                    }
                }
            }
        }

        final todayKey = formatDate(today);
        final todayDone = goals.where((goal) => goal.hasActivityOn(todayKey)).length;
        final selectedGoals = goals
            .where((goal) => goal.hasActivityOn(selectedKey))
            .toList();

        return Scaffold(
            backgroundColor: AppColors.background,
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                    Row(
                        children: [
                            IconButton(
                                tooltip: "上一周",
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _shiftWeek(-7),
                                icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Expanded(
                                child: Tooltip(
                                    message: "点这里打开日历，直接跳到某一天",
                                    child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: _pickDate,
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 4,
                                            ),
                                            child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                    Flexible(
                                                        child: Text(
                                                            "${_weekStart.month}/${_weekStart.day} – ${weekEnd.month}/${weekEnd.day}",
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight: FontWeight.w700,
                                                                color: AppColors.text,
                                                            ),
                                                        ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                        Icons.calendar_month_outlined,
                                                        size: 18,
                                                        color: AppColors.primary,
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                            IconButton(
                                tooltip: "下一周",
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _shiftWeek(7),
                                icon: const Icon(Icons.chevron_right_rounded),
                            ),
                            TextButton(
                                onPressed: () => _jumpTo(today),
                                child: const Text("今天"),
                            ),
                        ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                        children: [
                            Expanded(
                                child: _StatChip(
                                    label: "本周时长",
                                    value: formatDurationMinutes(weekMinutes),
                                ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _StatChip(
                                    label: "达标格子",
                                    value: "$weekHits / $weekSlots",
                                ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _StatChip(
                                    label: "今日痕迹",
                                    value: "$todayDone / ${goals.length}",
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                            children: List.generate(7, (index) {
                                final day = days[index];
                                final key = formatDate(day);
                                final minutes = goals.fold<int>(
                                    0,
                                    (sum, goal) => sum + goal.recordedMinutesOn(key),
                                );
                                final doneCount = goals
                                    .where((goal) => goal.hasActivityOn(key))
                                    .length;
                                return Expanded(
                                    child: _DayChip(
                                        weekday: weekdayLabels[index],
                                        day: day.day,
                                        minutes: minutes,
                                        doneCount: doneCount,
                                        isToday: day == today,
                                        isSelected: day == selected,
                                        isFuture: day.isAfter(today),
                                        onTap: () {
                                            setState(() {
                                                _selectedDay = day;
                                            });
                                        },
                                    ),
                                );
                            }),
                        ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        "打卡和番茄钟会自动点亮，不用在这里填表。点科目可去打卡。",
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                            height: 1.4,
                        ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                        child: Row(
                            children: [
                                const SizedBox(width: 26),
                                const Expanded(child: SizedBox()),
                                ...weekdayLabels.map((label) {
                                    return Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: SizedBox(
                                            width: 24,
                                            child: Text(
                                                label,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.w600,
                                                ),
                                            ),
                                        ),
                                    );
                                }),
                            ],
                        ),
                    ),
                    const SizedBox(height: 6),
                    ...goals.map((goal) {
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _GoalWeekRow(
                                goal: goal,
                                days: days,
                                today: today,
                                onOpen: widget.onOpenGoal == null
                                    ? null
                                    : () => widget.onOpenGoal!(goal.id),
                            ),
                        );
                    }),
                    const SizedBox(height: 8),
                    Text(
                        "${selected.month}/${selected.day} ${weekdayLabels[selected.weekday - 1]}",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                        ),
                    ),
                    const SizedBox(height: 8),
                    if (selected.isAfter(today))
                        const _EmptyHint(text: "这一天还没到。")
                    else if (selectedGoals.isEmpty)
                        const _EmptyHint(text: "这一天还没有学习记录。去打卡或开番茄钟就会出现。")
                    else
                        ...selectedGoals.map((goal) {
                            return _DayDetailTile(
                                goal: goal,
                                dateKey: selectedKey,
                                onOpen: widget.onOpenGoal == null
                                    ? null
                                    : () => widget.onOpenGoal!(goal.id),
                            );
                        }),
                ],
            ),
        );
    }
}

class _StatChip extends StatelessWidget {
    final String label;
    final String value;

    const _StatChip({
        required this.label,
        required this.value,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
            ),
            child: Column(
                children: [
                    Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                        ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                        label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                        ),
                    ),
                ],
            ),
        );
    }
}

class _DayChip extends StatelessWidget {
    final String weekday;
    final int day;
    final int minutes;
    final int doneCount;
    final bool isToday;
    final bool isSelected;
    final bool isFuture;
    final VoidCallback onTap;

    const _DayChip({
        required this.weekday,
        required this.day,
        required this.minutes,
        required this.doneCount,
        required this.isToday,
        required this.isSelected,
        required this.isFuture,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        final bg = isSelected
            ? AppColors.primary
            : isToday
                ? AppColors.sidebarSelected
                : Colors.transparent;
        final fg = isSelected ? Colors.white : AppColors.text;
        final sub = isSelected
            ? Colors.white.withValues(alpha: 0.85)
            : AppColors.textSecondary;

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                            children: [
                                Text(
                                    weekday,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: sub,
                                        fontWeight: FontWeight.w600,
                                    ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                    "$day",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: fg,
                                    ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                    isFuture
                                        ? "—"
                                        : minutes > 0
                                            ? "${minutes}m"
                                            : doneCount > 0
                                                ? "$doneCount项"
                                                : "·",
                                    style: TextStyle(fontSize: 10, color: sub),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

class _GoalWeekRow extends StatelessWidget {
    final Goal goal;
    final List<DateTime> days;
    final DateTime today;
    final VoidCallback? onOpen;

    const _GoalWeekRow({
        required this.goal,
        required this.days,
        required this.today,
        this.onOpen,
    });

    @override
    Widget build(BuildContext context) {
        return Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                    child: Row(
                        children: [
                            Icon(goal.iconData, color: goal.accentColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                        Text(
                                            "今天 ${goal.todayDoneAmount}/${goal.targetAmount} ${goal.unit}",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: goal.accentColor,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            ...days.map((day) {
                                final key = formatDate(day);
                                final future = day.isAfter(today);
                                final met = goal.metDailyTargetOn(key);
                                final active = goal.hasActivityOn(key);
                                return Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: _StatusDot(
                                        color: goal.accentColor,
                                        met: met,
                                        active: active,
                                        isToday: day == today,
                                        isFuture: future,
                                    ),
                                );
                            }),
                        ],
                    ),
                ),
            ),
        );
    }
}

class _StatusDot extends StatelessWidget {
    final Color color;
    final bool met;
    final bool active;
    final bool isToday;
    final bool isFuture;

    const _StatusDot({
        required this.color,
        required this.met,
        required this.active,
        required this.isToday,
        required this.isFuture,
    });

    @override
    Widget build(BuildContext context) {
        Color fill;
        Color border;
        if (isFuture) {
            fill = Colors.transparent;
            border = AppColors.border;
        } else if (met) {
            fill = color;
            border = color;
        } else if (active) {
            fill = color.withValues(alpha: 0.28);
            border = color.withValues(alpha: 0.5);
        } else if (isToday) {
            fill = Colors.white;
            border = AppColors.primary;
        } else {
            fill = const Color(0xFFF3EDEE);
            border = AppColors.border;
        }

        return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: isToday && !met ? 1.6 : 1),
            ),
            child: met
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
        );
    }
}

class _DayDetailTile extends StatelessWidget {
    final Goal goal;
    final String dateKey;
    final VoidCallback? onOpen;

    const _DayDetailTile({
        required this.goal,
        required this.dateKey,
        this.onOpen,
    });

    @override
    Widget build(BuildContext context) {
        final quantity = goal.quantityOn(dateKey);
        final minutes = goal.recordedMinutesOn(dateKey);
        final parts = <String>[];
        if (quantity > 0) {
            parts.add("$quantity ${goal.unit}");
        }
        if (minutes > 0) {
            parts.add("$minutes 分钟");
        }
        if (goal.metDailyTargetOn(dateKey)) {
            parts.add("已达标");
        }

        return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
                onTap: onOpen,
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                ),
                tileColor: AppColors.card,
                leading: Icon(goal.iconData, color: goal.accentColor),
                title: Text(goal.title),
                subtitle: Text(parts.join(" · ")),
                trailing: const Icon(Icons.chevron_right_rounded),
            ),
        );
    }
}

class _EmptyHint extends StatelessWidget {
    final String text;

    const _EmptyHint({required this.text});

    @override
    Widget build(BuildContext context) {
        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFEEF5FF),
                borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
                text,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3A4A6B),
                    height: 1.45,
                ),
            ),
        );
    }
}
