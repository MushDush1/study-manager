import '../utils/date_utils.dart';
import '../utils/unique_id.dart';

class GoalActivity {
    String id;
    String title;
    /// 计划完成日，空表示今天；例如 2026-08-29 表示排到那天再做
    String planDate;

    GoalActivity({
        String? id,
        required this.title,
        this.planDate = "",
    }) : id = id ?? createUniqueId();

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "title": title,
            "planDate": planDate,
        };
    }

    factory GoalActivity.fromJson(Map<String, dynamic> json) {
        return GoalActivity(
            id: json["id"] as String?,
            title: (json["title"] ?? "") as String,
            planDate: (json["planDate"] ?? "") as String,
        );
    }
}

class ActivityDone {
    String date;
    String activityId;

    ActivityDone({
        required this.date,
        required this.activityId,
    });

    Map<String, dynamic> toJson() {
        return {
            "date": date,
            "activityId": activityId,
        };
    }

    factory ActivityDone.fromJson(Map<String, dynamic> json) {
        return ActivityDone(
            date: (json["date"] ?? "") as String,
            activityId: (json["activityId"] ?? "") as String,
        );
    }
}

/// 针对某一条小任务的回看项，必须写清具体回看什么
class ActivityReview {
    String id;
    String activityId;
    String activityTitle;
    String doneDate;
    String nextReviewDate;
    String point;
    bool finished;

    ActivityReview({
        String? id,
        required this.activityId,
        required this.activityTitle,
        required this.doneDate,
        required this.nextReviewDate,
        this.point = "",
        this.finished = false,
    }) : id = id ?? createUniqueId();

    bool isDue({DateTime? now}) {
        if (finished) {
            return false;
        }
        final today = formatDate(now ?? DateTime.now());
        return nextReviewDate.compareTo(today) <= 0;
    }

    bool isLater({DateTime? now}) {
        if (finished) {
            return false;
        }
        final today = formatDate(now ?? DateTime.now());
        return nextReviewDate.compareTo(today) > 0;
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "activityId": activityId,
            "activityTitle": activityTitle,
            "doneDate": doneDate,
            "nextReviewDate": nextReviewDate,
            "point": point,
            "finished": finished,
        };
    }

    factory ActivityReview.fromJson(Map<String, dynamic> json) {
        return ActivityReview(
            id: json["id"] as String?,
            activityId: (json["activityId"] ?? "") as String,
            activityTitle: (json["activityTitle"] ?? "") as String,
            doneDate: (json["doneDate"] ?? "") as String,
            nextReviewDate: (json["nextReviewDate"] ?? "") as String,
            point: (json["point"] ?? "") as String,
            finished: (json["finished"] ?? false) as bool,
        );
    }
}
