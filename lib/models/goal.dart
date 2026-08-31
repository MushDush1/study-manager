import 'package:flutter/material.dart';

import '../utils/unique_id.dart';
import 'check_in_record.dart';
import 'goal_activity.dart';
import 'time_log.dart';

class Goal {
    String id;
    String title;
    String goalDescription;
    String unit;
    int targetAmount;
    String backupPlan;
    String videoLink;
    String baiduVideoName;
    String baiduFolderPath;
    String localFilePath;
    String todayPlanDate;
    String todayPlanContent;
    int plannedMinutes;
    int colorValue;
    String iconName;
    List<CheckInRecord> checkIns;
    List<TimeLog> timeLogs;
    List<GoalActivity> activities;
    List<ActivityDone> activityDones;
    List<ActivityReview> activityReviews;

    Goal({
        String? id,
        required this.title,
        required this.goalDescription,
        this.unit = "个",
        this.targetAmount = 100,
        this.backupPlan = "",
        this.videoLink = "",
        this.baiduVideoName = "",
        this.baiduFolderPath = "",
        this.localFilePath = "",
        this.todayPlanDate = "",
        this.todayPlanContent = "",
        this.plannedMinutes = 30,
        this.colorValue = 0xFFE85A71,
        this.iconName = "book",
        List<CheckInRecord>? checkIns,
        List<TimeLog>? timeLogs,
        List<GoalActivity>? activities,
        List<ActivityDone>? activityDones,
        List<ActivityReview>? activityReviews,
    }) : id = id ?? createUniqueId(),
         checkIns = checkIns ?? <CheckInRecord>[],
         timeLogs = timeLogs ?? <TimeLog>[],
         activities = activities ?? <GoalActivity>[],
         activityDones = activityDones ?? <ActivityDone>[],
         activityReviews = activityReviews ?? <ActivityReview>[];

    Color get accentColor => Color(colorValue);

    int get todayQuantity {
        return quantityOn(_formatDate(DateTime.now()));
    }

    int get todayMinutes {
        return minutesOn(_formatDate(DateTime.now()));
    }

    bool get hasActivities => activities.isNotEmpty;

    int get dailyTargetCount {
        if (hasActivities) {
            return activitiesDueOn(_formatDate(DateTime.now())).length;
        }
        return targetAmount;
    }

    String get progressUnit => hasActivities ? "项" : unit;

    int get todayDoneAmount {
        if (hasActivities) {
            return activityDoneCountOn(_formatDate(DateTime.now()));
        }
        if (unit == "分钟") {
            return todayMinutes;
        }
        return todayQuantity;
    }

    int get todayRemaining {
        final value = dailyTargetCount - todayDoneAmount;
        return value < 0 ? 0 : value;
    }

    double get todayProgress {
        if (dailyTargetCount <= 0) {
            return 0;
        }
        final value = todayDoneAmount / dailyTargetCount;
        if (value < 0) {
            return 0;
        }
        if (value > 1) {
            return 1;
        }
        return value;
    }

    int get todayProgressPercent => (todayProgress * 100).round();

    int get actualAmount {
        return checkIns.fold<int>(0, (sum, item) => sum + item.quantity);
    }

    int get actualMinutes {
        return checkIns.fold<int>(0, (sum, item) => sum + item.minutes);
    }

    int get remainingAmount {
        final value = targetAmount - actualAmount;
        return value < 0 ? 0 : value;
    }

    double get progress {
        if (targetAmount <= 0) {
            return 0;
        }
        final value = actualAmount / targetAmount;
        if (value < 0) {
            return 0;
        }
        if (value > 1) {
            return 1;
        }
        return value;
    }

    int get progressPercent => (progress * 100).round();

    IconData get iconData {
        switch (iconName) {
            case "vocab":
                return Icons.star_rounded;
            case "listen":
                return Icons.headphones_rounded;
            case "speak":
                return Icons.record_voice_over_rounded;
            case "read":
                return Icons.menu_book_rounded;
            case "write":
                return Icons.edit_note_rounded;
            case "code":
                return Icons.code_rounded;
            case "practice":
                return Icons.checklist_rounded;
            case "project":
                return Icons.laptop_chromebook_rounded;
            case "japanese":
                return Icons.translate_rounded;
            case "review":
                return Icons.insights_rounded;
            default:
                return Icons.bookmark_rounded;
        }
    }

    int consecutiveDays({DateTime? now}) {
        if (checkIns.isEmpty) {
            return 0;
        }

        final dates = checkIns.map((item) => item.date).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

        final today = now ?? DateTime.now();
        var cursor = DateTime(today.year, today.month, today.day);
        var streak = 0;

        for (final dateText in dates) {
            final expected = _formatDate(cursor);
            if (dateText == expected) {
                streak += 1;
                cursor = cursor.subtract(const Duration(days: 1));
                continue;
            }

            if (streak == 0 && dateText == _formatDate(cursor.subtract(const Duration(days: 1)))) {
                cursor = cursor.subtract(const Duration(days: 1));
                streak += 1;
                cursor = cursor.subtract(const Duration(days: 1));
                continue;
            }
            break;
        }

        return streak;
    }

    int quantityOn(String date) {
        return checkIns
            .where((item) => item.date == date)
            .fold<int>(0, (sum, item) => sum + item.quantity);
    }

    int minutesOn(String date) {
        return checkIns
            .where((item) => item.date == date)
            .fold<int>(0, (sum, item) => sum + item.minutes);
    }

    int timerMinutesOn(String date) {
        return timeLogs
            .where((item) => item.date == date)
            .fold<int>(0, (sum, item) => sum + item.minutes);
    }

    /// 当天有效分钟：打卡填写与番茄钟取较大值，避免重复累计
    int recordedMinutesOn(String date) {
        final checkInMinutes = minutesOn(date);
        final timerMinutes = timerMinutesOn(date);
        return checkInMinutes > timerMinutes ? checkInMinutes : timerMinutes;
    }

    bool hasActivityOn(String date) {
        return quantityOn(date) > 0 ||
            minutesOn(date) > 0 ||
            timerMinutesOn(date) > 0 ||
            activityDoneCountOn(date) > 0;
    }

    int activityDoneCountOn(String date) {
        final dueIds = {
            for (final activity in activitiesDueOn(date)) activity.id,
        };
        return activityDones.where((item) {
            return item.date == date && dueIds.contains(item.activityId);
        }).length;
    }

    bool isActivityDoneOn(String activityId, String date) {
        return activityDones.any(
            (item) => item.date == date && item.activityId == activityId,
        );
    }

    bool isActivityFinished(String activityId) {
        return activityDones.any((item) => item.activityId == activityId);
    }

    /// 未完成，且已经改期到 date 之后
    bool isActivityParkedOn(GoalActivity activity, String date) {
        if (isActivityFinished(activity.id)) {
            return false;
        }
        final plan = activity.planDate.trim();
        return plan.isNotEmpty && plan.compareTo(date) > 0;
    }

    /// 这一天应该出现在待做列表里（含当天刚勾完的）
    bool isActivityDueOn(GoalActivity activity, String date) {
        final doneDates = activityDones
            .where((item) => item.activityId == activity.id)
            .map((item) => item.date)
            .toSet();
        if (doneDates.isNotEmpty) {
            return doneDates.contains(date);
        }
        final plan = activity.planDate.trim();
        final today = _formatDate(DateTime.now());
        if (plan.isEmpty) {
            return date == today;
        }
        if (date == today) {
            return plan.compareTo(today) <= 0;
        }
        return plan == date;
    }

    List<GoalActivity> activitiesDueOn(String date) {
        return activities.where((item) => isActivityDueOn(item, date)).toList();
    }

    List<GoalActivity> activitiesParkedOn(String date) {
        return activities.where((item) => isActivityParkedOn(item, date)).toList();
    }

    /// 对照每日目标：有子事项时看完成几项，分钟科目看时长，其它看数量
    int dailyDoneOn(String date) {
        if (hasActivities) {
            return activityDoneCountOn(date);
        }
        if (unit == "分钟") {
            return recordedMinutesOn(date);
        }
        return quantityOn(date);
    }

    bool metDailyTargetOn(String date) {
        if (hasActivities) {
            final due = activitiesDueOn(date);
            if (due.isEmpty) {
                if (activities.every((item) => isActivityFinished(item.id))) {
                    return true;
                }
                final today = _formatDate(DateTime.now());
                return date == today && activitiesParkedOn(date).isNotEmpty;
            }
            return due.every((item) => isActivityDoneOn(item.id, date));
        }
        if (targetAmount <= 0) {
            return hasActivityOn(date);
        }
        return dailyDoneOn(date) >= targetAmount;
    }

    int get todayTimerMinutes {
        return timerMinutesOn(_formatDate(DateTime.now()));
    }

    bool isTodayPlan({DateTime? now}) {
        return todayPlanDate == _formatDate(now ?? DateTime.now());
    }

    bool hasCheckInOn(String date) {
        return checkIns.any((item) => item.date == date) ||
            activityDoneCountOn(date) > 0;
    }

    List<CheckInRecord> recordsNewestFirst() {
        final items = [...checkIns];
        items.sort((a, b) => b.date.compareTo(a.date));
        return items;
    }

    List<CheckInRecord> get reviewRecords {
        return checkIns.where((item) => item.needsReview).toList();
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "title": title,
            "goalDescription": goalDescription,
            "unit": unit,
            "targetAmount": targetAmount,
            "backupPlan": backupPlan,
            "videoLink": videoLink,
            "baiduVideoName": baiduVideoName,
            "baiduFolderPath": baiduFolderPath,
            "localFilePath": localFilePath,
            "todayPlanDate": todayPlanDate,
            "todayPlanContent": todayPlanContent,
            "plannedMinutes": plannedMinutes,
            "colorValue": colorValue,
            "iconName": iconName,
            "checkIns": checkIns.map((item) => item.toJson()).toList(),
            "timeLogs": timeLogs.map((item) => item.toJson()).toList(),
            "activities": activities.map((item) => item.toJson()).toList(),
            "activityDones": activityDones.map((item) => item.toJson()).toList(),
            "activityReviews": activityReviews.map((item) => item.toJson()).toList(),
        };
    }

    factory Goal.fromJson(Map<String, dynamic> json) {
        return Goal(
            id: json["id"] as String?,
            title: (json["title"] ?? "") as String,
            goalDescription: dailyDescriptionFromJson(json),
            unit: (json["unit"] ?? "个") as String,
            targetAmount: dailyTargetFromJson(json),
            backupPlan: (json["backupPlan"] ?? "") as String,
            videoLink: (json["videoLink"] ?? "") as String,
            baiduVideoName: (json["baiduVideoName"] ?? "") as String,
            baiduFolderPath: (json["baiduFolderPath"] ?? "") as String,
            localFilePath:
                (json["localFilePath"] ?? json["localPath"] ?? "") as String,
            todayPlanDate: (json["todayPlanDate"] ?? "") as String,
            todayPlanContent: (json["todayPlanContent"] ?? "") as String,
            plannedMinutes: (json["plannedMinutes"] ?? 30) as int,
            colorValue: (json["colorValue"] ?? 0xFFE85A71) as int,
            iconName: (json["iconName"] ?? "book") as String,
            checkIns: (json["checkIns"] as List<dynamic>?)
                    ?.map(
                        (item) => CheckInRecord.fromJson(
                            Map<String, dynamic>.from(item as Map),
                        ),
                    )
                    .toList() ??
                <CheckInRecord>[],
            timeLogs: (json["timeLogs"] as List<dynamic>?)
                    ?.map(
                        (item) => TimeLog.fromJson(
                            Map<String, dynamic>.from(item as Map),
                        ),
                    )
                    .toList() ??
                <TimeLog>[],
            activities: activitiesFromJson(json),
            activityDones: (json["activityDones"] as List<dynamic>?)
                    ?.map(
                        (item) => ActivityDone.fromJson(
                            Map<String, dynamic>.from(item as Map),
                        ),
                    )
                    .toList() ??
                <ActivityDone>[],
            activityReviews: (json["activityReviews"] as List<dynamic>?)
                    ?.map(
                        (item) => ActivityReview.fromJson(
                            Map<String, dynamic>.from(item as Map),
                        ),
                    )
                    .toList() ??
                <ActivityReview>[],
        );
    }

    static String _formatDate(DateTime date) {
        final month = date.month.toString().padLeft(2, "0");
        final day = date.day.toString().padLeft(2, "0");
        return "${date.year}-$month-$day";
    }

    /// 把以前的长期总量（4000个、3600分钟）收成每天的量
    static int dailyTargetFromJson(Map<String, dynamic> json) {
        final raw = (json["targetAmount"] ?? 20) as int;
        final unit = (json["unit"] ?? "个") as String;
        final title = (json["title"] ?? "") as String;
        final looksDaily = unit == "分钟" ? raw <= 180 : raw <= 50;
        if (looksDaily) {
            return raw < 1 ? 1 : raw;
        }
        return suggestedDailyTarget(title, unit);
    }

    static String dailyDescriptionFromJson(Map<String, dynamic> json) {
        final unit = (json["unit"] ?? "个") as String;
        final raw = (json["targetAmount"] ?? 20) as int;
        final looksDaily = unit == "分钟" ? raw <= 180 : raw <= 50;
        if (looksDaily) {
            return (json["goalDescription"] ?? "") as String;
        }
        final daily = suggestedDailyTarget(
            (json["title"] ?? "") as String,
            unit,
        );
        return "每天 $daily $unit";
    }

    static int suggestedDailyTarget(String title, String unit) {
        if (title.contains("口语") || title.contains("实践")) {
            return 30;
        }
        if (title.contains("词汇") || title.contains("日语") || title.contains("单词")) {
            return 20;
        }
        if (title.contains("刷题")) {
            return 5;
        }
        if (unit == "分钟") {
            return 30;
        }
        return 1;
    }

    static List<GoalActivity> activitiesFromJson(Map<String, dynamic> json) {
        if (json.containsKey("activities")) {
            return (json["activities"] as List<dynamic>?)
                    ?.map(
                        (item) => GoalActivity.fromJson(
                            Map<String, dynamic>.from(item as Map),
                        ),
                    )
                    .where((item) => item.title.trim().isNotEmpty)
                    .toList() ??
                <GoalActivity>[];
        }
        return suggestedActivities((json["title"] ?? "") as String);
    }

    static List<GoalActivity> suggestedActivities(String title) {
        if (title.contains("听力")) {
            return [
                GoalActivity(title: "听真题"),
                GoalActivity(title: "读错误句"),
                GoalActivity(title: "总结"),
                GoalActivity(title: "看课程"),
            ];
        }
        if (title.contains("日语")) {
            return [
                GoalActivity(title: "背单词"),
                GoalActivity(title: "听课文"),
                GoalActivity(title: "语法练习"),
                GoalActivity(title: "看课程"),
            ];
        }
        return [];
    }
}
