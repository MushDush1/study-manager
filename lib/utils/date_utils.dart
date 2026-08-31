String formatDurationMinutes(int minutes) {
    if (minutes < 60) {
        return "$minutes 分钟";
    }
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) {
        return "$hours 小时";
    }
    return "$hours 小时 $rest 分钟";
}

String formatClock(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, "0");
    final seconds = (safe % 60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
}

String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "${date.year}-$month-$day";
}

String formatTomorrow({DateTime? now}) {
    final current = now ?? DateTime.now();
    return formatDate(current.add(const Duration(days: 1)));
}

String formatSlashDate(DateTime date) {
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "${date.year}/$month/$day";
}

DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
}

DateTime parseDate(String text) {
    final normalized = text.replaceAll("/", "-");
    return DateTime.parse(normalized);
}

/// 本周一（按周一为一周开始）
DateTime startOfWeek(DateTime date) {
    final current = dateOnly(date);
    return current.subtract(Duration(days: current.weekday - 1));
}

List<DateTime> weekDays(DateTime weekStart) {
    return List<DateTime>.generate(7, (index) {
        return weekStart.add(Duration(days: index));
    });
}

const List<String> weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"];
