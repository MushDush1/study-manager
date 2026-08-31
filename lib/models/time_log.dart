class TimeLog {
    String id;
    String date;
    int minutes;

    TimeLog({
        String? id,
        required this.date,
        required this.minutes,
    }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

    Map<String, dynamic> toJson() {
        return {
            "id": id,
            "date": date,
            "minutes": minutes,
        };
    }

    factory TimeLog.fromJson(Map<String, dynamic> json) {
        return TimeLog(
            id: json["id"] as String?,
            date: (json["date"] ?? "") as String,
            minutes: (json["minutes"] ?? 0) as int,
        );
    }
}
