import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/auth_store.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/account_card.dart';
import '../widgets/minutes_bar_chart.dart';

enum _ChartRange { daily, weekly, monthly }

class ProfilePage extends StatefulWidget {
    final GoalStore store;
    final AuthStore auth;
    final Future<void> Function()? onCloudLogin;

    const ProfilePage({
        super.key,
        required this.store,
        required this.auth,
        this.onCloudLogin,
    });

    @override
    State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
    _ChartRange _range = _ChartRange.daily;
    String? _goalId;
    DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime _weekStart = startOfWeek(DateTime.now());

    GoalStore get store => widget.store;

    @override
    Widget build(BuildContext context) {
        Goal? selectedGoal;
        if (_goalId != null) {
            for (final goal in store.goals) {
                if (goal.id == _goalId) {
                    selectedGoal = goal;
                    break;
                }
            }
        }
        final now = DateTime.now();
        final monthTotal = store.timerMinutesInMonth(
            _month.year,
            _month.month,
            goalId: _goalId,
        );

        late List<DateTime> dates;
        late String chartTitle;
        late List<String> labels;

        if (_range == _ChartRange.daily) {
            final today = dateOnly(now);
            dates = List<DateTime>.generate(14, (index) {
                return today.subtract(Duration(days: 13 - index));
            });
            chartTitle = selectedGoal == null
                ? "近 14 天学习分钟（全部任务）"
                : "近 14 天 · ${selectedGoal.title}";
            labels = dates.map((date) => "${date.month}/${date.day}").toList();
        } else if (_range == _ChartRange.weekly) {
            dates = weekDays(_weekStart);
            chartTitle = selectedGoal == null
                ? "本周学习分钟（全部任务）"
                : "本周 · ${selectedGoal.title}";
            labels = List<String>.generate(7, (index) {
                return "${dates[index].month}/${dates[index].day}\n${weekdayLabels[index]}";
            });
        } else {
            final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
            dates = List<DateTime>.generate(daysInMonth, (index) {
                return DateTime(_month.year, _month.month, index + 1);
            });
            chartTitle = selectedGoal == null
                ? "${_month.month} 月每天学习分钟"
                : "${_month.month} 月 · ${selectedGoal.title}";
            labels = dates.map((date) => "${date.day}").toList();
        }

        final minutes = dates.map((date) {
            return store.timerMinutesOn(formatDate(date), goalId: _goalId);
        }).toList();
        final colors = selectedGoal == null
            ? (store.goals.isEmpty
                ? AppColors.accentPalette
                : store.goals.map((goal) => goal.accentColor).toList())
            : [selectedGoal.accentColor];

        return Scaffold(
            backgroundColor: AppColors.background,
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                    AccountCard(auth: widget.auth, store: store, onCloudLogin: widget.onCloudLogin),
                    const SizedBox(height: 14),
                    _Card(
                        title: "这个月学了多久",
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                    children: [
                                        TextButton(
                                            onPressed: () {
                                                setState(() {
                                                    _month = DateTime(_month.year, _month.month - 1);
                                                });
                                            },
                                            child: const Text("上月"),
                                        ),
                                        Expanded(
                                            child: Text(
                                                "${_month.year} 年 ${_month.month} 月",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                        ),
                                        TextButton(
                                            onPressed: () {
                                                setState(() {
                                                    _month = DateTime(_month.year, _month.month + 1);
                                                });
                                            },
                                            child: const Text("下月"),
                                        ),
                                    ],
                                ),
                                Center(
                                    child: Text(
                                        formatDurationMinutes(monthTotal),
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                        ),
                                    ),
                                ),
                                const SizedBox(height: 6),
                                const Center(
                                    child: Text(
                                        "来自番茄时钟计入的时间",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 14),
                    _Card(
                        title: "按任务看图",
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                        ChoiceChip(
                                            label: const Text("全部任务"),
                                            selected: _goalId == null,
                                            onSelected: (_) {
                                                setState(() {
                                                    _goalId = null;
                                                });
                                            },
                                        ),
                                        ...store.goals.map((goal) {
                                            return ChoiceChip(
                                                label: Text(goal.title),
                                                selected: _goalId == goal.id,
                                                onSelected: (_) {
                                                    setState(() {
                                                        _goalId = goal.id;
                                                    });
                                                },
                                            );
                                        }),
                                    ],
                                ),
                                const SizedBox(height: 10),
                                SegmentedButton<_ChartRange>(
                                    segments: const [
                                        ButtonSegment(
                                            value: _ChartRange.daily,
                                            label: Text("每日"),
                                        ),
                                        ButtonSegment(
                                            value: _ChartRange.weekly,
                                            label: Text("每周"),
                                        ),
                                        ButtonSegment(
                                            value: _ChartRange.monthly,
                                            label: Text("每月"),
                                        ),
                                    ],
                                    selected: {_range},
                                    onSelectionChanged: (value) {
                                        setState(() {
                                            _range = value.first;
                                        });
                                    },
                                ),
                                if (_range == _ChartRange.weekly)
                                    Row(
                                        children: [
                                            TextButton(
                                                onPressed: () {
                                                    setState(() {
                                                        _weekStart = _weekStart.subtract(
                                                            const Duration(days: 7),
                                                        );
                                                    });
                                                },
                                                child: const Text("上周"),
                                            ),
                                            const Spacer(),
                                            TextButton(
                                                onPressed: () {
                                                    setState(() {
                                                        _weekStart = _weekStart.add(
                                                            const Duration(days: 7),
                                                        );
                                                    });
                                                },
                                                child: const Text("下周"),
                                            ),
                                        ],
                                    ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 14),
                    MinutesBarChart(
                        title: chartTitle,
                        dates: dates,
                        minutes: minutes,
                        colors: colors,
                        xLabels: labels,
                    ),
                    const SizedBox(height: 14),
                    _Card(
                        title: "各任务本月时长",
                        child: Column(
                            children: store.goals.map((goal) {
                                final value = store.timerMinutesInMonth(
                                    _month.year,
                                    _month.month,
                                    goalId: goal.id,
                                );
                                return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                        children: [
                                            Expanded(child: Text(goal.title)),
                                            Text(
                                                formatDurationMinutes(value),
                                                style: TextStyle(
                                                    color: goal.accentColor,
                                                    fontWeight: FontWeight.w600,
                                                ),
                                            ),
                                        ],
                                    ),
                                );
                            }).toList(),
                        ),
                    ),
                ],
            ),
        );
    }
}

class _Card extends StatelessWidget {
    final String title;
    final Widget child;

    const _Card({required this.title, required this.child});

    @override
    Widget build(BuildContext context) {
        return Container(
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
                    Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                        ),
                    ),
                    const SizedBox(height: 12),
                    child,
                ],
            ),
        );
    }
}
