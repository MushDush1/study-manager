import '../utils/date_utils.dart';

class CheckInRecord {
    String id;
    String date;
    int quantity;
    int minutes;
    String title;
    String summary;
    bool needsReview;
    String nextReviewDate;

    CheckInRecord({
        String? id,
        required this.date,
        this.quantity = 0,
        this.minutes = 0,
        this.title = "",
        this.summary = "",
        this.needsReview = false,
        this.nextReviewDate = "",
    }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

    bool isDue({DateTime? now}) {
        if (!needsReview) {
            return false;
        }
        if (nextReviewDate.trim().isEmpty) {
            return true;
        }
        return nextReviewDate.compareTo(formatDate(now ?? DateTime.now())) <= 0;
    }

    bool isScheduled({DateTime? now}) {
        if (!needsReview) {
            return false;
        }
        if (nextReviewDate.trim().isEmpty) {
            return false;
        }
        return nextReviewDate.compareTo(formatDate(now ?? DateTime.now())) > 0;
    }

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "date": date,
            "quantity": quantity,
            "minutes": minutes,
            "title": title,
            "summary": summary,
            "needsReview": needsReview,
            "nextReviewDate": nextReviewDate,
        };
    }

    factory CheckInRecord.fromJson(Map<String, dynamic> json) {
        return CheckInRecord(
            id: json["id"] as String?,
            date: (json["date"] ?? "") as String,
            quantity: (json["quantity"] ?? 0) as int,
            minutes: (json["minutes"] ?? 0) as int,
            title: (json["title"] ?? "") as String,
            summary: (json["summary"] ?? json["note"] ?? "") as String,
            needsReview: (json["needsReview"] ?? false) as bool,
            nextReviewDate: (json["nextReviewDate"] ?? "") as String,
        );
    }
}
