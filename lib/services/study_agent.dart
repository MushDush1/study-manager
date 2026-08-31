import '../models/goal.dart';
import '../utils/date_utils.dart';
import 'goal_store.dart';

/// 本地学习 Agent：根据当前计划、打卡、番茄钟和复习箱作答，不调用外部模型。
class StudyAgent {
    static String greet(GoalStore store) {
        return "${_todayBrief(store)}\n\n可以直接问我：今天学什么、复习什么、本周进度，或下一步做什么。";
    }

    static String reply(GoalStore store, String raw) {
        final text = raw.trim();
        if (text.isEmpty) {
            return "想问今天学什么、复习，还是本周进度？";
        }

        if (_hit(text, ["复习", "到期", "回看"])) {
            return _reviewAdvice(store);
        }
        if (_hit(text, ["本周", "周", "看板", "进度", "坚持"])) {
            return _weekAdvice(store);
        }
        if (_hit(text, ["番茄", "计时", "时钟", "休息"])) {
            return _timerAdvice(store);
        }
        if (_hit(text, ["下一步", "建议", "先做", "优先"])) {
            return _nextStep(store);
        }
        if (_hit(text, ["今天", "今日", "计划", "学什么", "安排"])) {
            return _todayAdvice(store);
        }
        return "${_todayBrief(store)}\n\n也可以说「下一步建议」或「复习什么」。";
    }

    static bool _hit(String text, List<String> keys) {
        for (final key in keys) {
            if (text.contains(key)) {
                return true;
            }
        }
        return false;
    }

    static String _todayBrief(GoalStore store) {
        final today = formatDate(DateTime.now());
        final plans = store.todayPlans;
        final dueCount = store.dueReviewEntries.length;
        final activeCount = store.goals.where((goal) {
            return goal.hasActivityOn(today);
        }).length;

        if (plans.isEmpty) {
            return "今天还没安排计划。首页点「安排」勾选科目即可。";
        }

        final done = plans.where((goal) => goal.hasActivityOn(today)).length;
        return "今日计划 $done / ${plans.length} 项有记录，到期复习 $dueCount 条，全部科目里 $activeCount 个今天动过。";
    }

    static String _todayAdvice(GoalStore store) {
        final today = formatDate(DateTime.now());
        final plans = store.todayPlans;
        if (plans.isEmpty) {
            return "还没有今日计划。去首页点「安排」，勾选今天要学的科目并写上具体内容。";
        }

        final lines = <String>["今日计划："];
        for (final goal in plans) {
            final done = goal.hasActivityOn(today);
            final content = goal.todayPlanContent.trim();
            final detail = content.isEmpty ? "每天 ${goal.targetAmount} ${goal.unit}" : content;
            final mark = done ? "已有记录" : "还没开始";
            lines.add("· ${goal.title}：$detail（$mark，${goal.todayDoneAmount}/${goal.dailyTargetCount} ${goal.progressUnit}）");
            for (final activity in goal.activitiesParkedOn(today)) {
                lines.add("  · ${activity.title}：已排到明天");
            }
        }
        return lines.join("\n");
    }

    static String _reviewAdvice(GoalStore store) {
        final due = store.dueReviewEntries;
        if (due.isEmpty) {
            return "今天没有到期复习。打卡时勾选「加入复习」，之后会按 1/3/7 天回来。";
        }

        final lines = <String>["今天到期 ${due.length} 条，建议先回看："];
        final limit = due.length > 6 ? 6 : due.length;
        for (var i = 0; i < limit; i++) {
            final item = due[i];
            final title = item.record.title.trim().isEmpty
                ? item.goal.title
                : item.record.title.trim();
            lines.add("· ${item.goal.title}：$title");
        }
        if (due.length > limit) {
            lines.add("还有 ${due.length - limit} 条，去「复习」页看完整列表。");
        }
        return lines.join("\n");
    }

    static String _weekAdvice(GoalStore store) {
        final today = dateOnly(DateTime.now());
        final days = weekDays(startOfWeek(today));
        var minutes = 0;
        var hits = 0;
        var slots = 0;

        for (final day in days) {
            if (day.isAfter(today)) {
                continue;
            }
            final key = formatDate(day);
            for (final goal in store.goals) {
                minutes += goal.recordedMinutesOn(key);
                slots += 1;
                if (goal.metDailyTargetOn(key)) {
                    hits += 1;
                }
            }
        }

        return "本周截至今天：学习 ${formatDurationMinutes(minutes)}，达标格子 $hits / $slots。细节在「看板」里点日期看。";
    }

    static String _timerAdvice(GoalStore store) {
        if (store.timerRunning) {
            final goal = store.timerGoal;
            final name = goal?.title ?? "当前任务";
            return "${store.timerPhaseLabel} · $name，还剩 ${store.timerDisplay}。休息倒计时不会计入学习时长。";
        }
        return "现在没有在计时。去「打卡」页填学习分钟和休息分钟，开始后学完会自动记入当前科目。";
    }

    static String _nextStep(GoalStore store) {
        final today = formatDate(DateTime.now());
        final due = store.dueReviewEntries;
        if (due.isNotEmpty) {
            final first = due.first;
            return "先复习「${first.goal.title}」，到期 ${due.length} 条。复习完再继续今日计划。";
        }

        final plans = store.todayPlans;
        if (plans.isEmpty) {
            return "先去首页点「安排」，把今天要学的科目勾上。有计划之后我才能帮你排顺序。";
        }

        Goal? pending;
        for (final goal in plans) {
            if (!goal.hasActivityOn(today)) {
                pending = goal;
                break;
            }
        }
        if (pending == null) {
            return "今日计划都有记录了。可以开番茄钟补时长，或去看板确认本周有没有漏的科目。";
        }

        final content = pending.todayPlanContent.trim();
        if (content.isEmpty) {
            return "下一步：打卡「${pending.title}」，今天目标 ${pending.targetAmount} ${pending.unit}。";
        }
        return "下一步：${pending.title} —— $content";
    }
}
