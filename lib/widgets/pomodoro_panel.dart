import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/goal_store.dart';
import '../theme/app_colors.dart';

class PomodoroPanel extends StatefulWidget {
    final GoalStore store;

    const PomodoroPanel({super.key, required this.store});

    @override
    State<PomodoroPanel> createState() => _PomodoroPanelState();
}

class _PomodoroPanelState extends State<PomodoroPanel> {
    late final TextEditingController _workController;
    late final TextEditingController _breakController;

    GoalStore get store => widget.store;

    @override
    void initState() {
        super.initState();
        _workController = TextEditingController(text: "${store.pomodoroMinutes}");
        _breakController = TextEditingController(text: "${store.breakMinutes}");
    }

    @override
    void dispose() {
        _workController.dispose();
        _breakController.dispose();
        super.dispose();
    }

    void _applyDurations() {
        final work = int.tryParse(_workController.text.trim()) ?? store.pomodoroMinutes;
        final rest = int.tryParse(_breakController.text.trim()) ?? store.breakMinutes;
        store.setTimerDurations(workMinutes: work, restMinutes: rest);
    }

    @override
    Widget build(BuildContext context) {
        final goal = store.timerGoal;
        final elapsedMinutes = store.timerElapsedSeconds ~/ 60;
        final isBreak = store.timerIsBreak;
        final canEdit = !store.timerRunning;

        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isBreak ? const Color(0xFFB7E3C8) : AppColors.border,
                ),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Icon(
                                isBreak ? Icons.coffee_rounded : Icons.timer_outlined,
                                color: isBreak ? const Color(0xFF2E9E5B) : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                                isBreak ? "休息时间" : "番茄时钟",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                            const Spacer(),
                            Text(
                                isBreak
                                    ? "休息 ${store.breakMinutes} 分钟"
                                    : (goal == null ? "先选一个任务" : "正在计：${goal.title}"),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                        child: Text(
                            store.timerDisplay,
                            style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: isBreak ? const Color(0xFF2E9E5B) : AppColors.text,
                                letterSpacing: 2,
                            ),
                        ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                        child: Text(
                            isBreak
                                ? "休息倒计时，结束后会回到学习时长"
                                : "已计时 $elapsedMinutes 分钟 · 今日该任务 ${goal?.todayTimerMinutes ?? 0} 分钟",
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                            ),
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    controller: _workController,
                                    enabled: canEdit,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (_) => _applyDurations(),
                                    decoration: const InputDecoration(
                                        labelText: "学习分钟",
                                        hintText: "自己填，比如 23",
                                        isDense: true,
                                    ),
                                ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: TextField(
                                    controller: _breakController,
                                    enabled: canEdit,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (_) => _applyDurations(),
                                    decoration: const InputDecoration(
                                        labelText: "休息分钟",
                                        hintText: "自己填，比如 5",
                                        isDense: true,
                                    ),
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                        children: [
                            Expanded(
                                child: FilledButton.icon(
                                    onPressed: goal == null && !isBreak
                                        ? null
                                        : () {
                                            if (store.timerRunning) {
                                                store.pauseTimer();
                                            } else {
                                                if (canEdit) {
                                                    _applyDurations();
                                                }
                                                store.startTimer(asBreak: isBreak);
                                            }
                                        },
                                    style: FilledButton.styleFrom(
                                        backgroundColor: isBreak
                                            ? const Color(0xFF2E9E5B)
                                            : AppColors.primary,
                                    ),
                                    icon: Icon(
                                        store.timerRunning
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                    ),
                                    label: Text(store.timerRunning ? "暂停" : "开始"),
                                ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: OutlinedButton.icon(
                                    onPressed: isBreak
                                        ? () {
                                            store.resetTimer();
                                        }
                                        : (store.timerElapsedSeconds < 30
                                            ? null
                                            : () async {
                                                await store.saveElapsedAndStop();
                                                if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                            content: Text("已把这次学习时间记入当前任务"),
                                                        ),
                                                    );
                                                }
                                            }),
                                    icon: Icon(
                                        isBreak ? Icons.skip_next_rounded : Icons.check_rounded,
                                    ),
                                    label: Text(isBreak ? "跳过休息" : "结束计入"),
                                ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                                tooltip: "重置",
                                onPressed: store.resetTimer,
                                icon: const Icon(Icons.refresh_rounded),
                            ),
                        ],
                    ),
                    TextButton(
                        onPressed: store.timerRunning
                            ? null
                            : () {
                                _applyDurations();
                                store.startTimer(asBreak: true);
                            },
                        child: const Text("直接开始休息"),
                    ),
                ],
            ),
        );
    }
}
