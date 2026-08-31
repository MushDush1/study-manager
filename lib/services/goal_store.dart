import 'package:flutter/foundation.dart';

import '../models/check_in_record.dart';
import '../models/goal.dart';
import '../models/goal_activity.dart';
import '../models/time_log.dart';
import '../utils/date_utils.dart';
import 'storage.dart';
import 'cloud_api.dart';

enum CloudBootstrapResult { restored, cloudEmpty, failed }

class ReviewEntry {
    final Goal goal;
    final CheckInRecord record;

    ReviewEntry({required this.goal, required this.record});
}

class ActivityReviewEntry {
    final Goal goal;
    final ActivityReview review;

    ActivityReviewEntry({required this.goal, required this.review});
}

class GoalStore extends ChangeNotifier {
    final CloudApi api;
    GoalStore({CloudApi? api}) : api = api ?? CloudApi();
    List<Goal> goals = [];
    int selectedIndex = 0;
    bool loaded = false;
    bool cloudConnected = false;
    bool syncPending = false;
    bool syncing = false;
    bool hasConflict = false;
    String? syncError;
    DateTime? lastSyncedAt;
    int _cloudVersion = 0;

    bool timerRunning = false;
    bool timerIsBreak = false;
    int pomodoroMinutes = 25;
    int breakMinutes = 5;
    int timerRemainingSeconds = 25 * 60;
    int timerElapsedSeconds = 0;
    String? timerGoalId;

    Goal? get selectedGoal {
        if (goals.isEmpty) {
            return null;
        }
        if (selectedIndex < 0 || selectedIndex >= goals.length) {
            return goals.first;
        }
        return goals[selectedIndex];
    }

    int get totalCheckIns {
        return goals.fold<int>(0, (sum, goal) => sum + goal.checkIns.length);
    }

    Goal? get timerGoal {
        final id = timerGoalId;
        if (id == null) {
            return selectedGoal;
        }
        return _goalById(id) ?? selectedGoal;
    }

    String get timerDisplay {
        return formatClock(timerRemainingSeconds);
    }

    List<Goal> get todayPlans {
        return goals.where((goal) => goal.isTodayPlan()).toList();
    }

    List<ReviewEntry> get reviewEntries {
        final items = <ReviewEntry>[];
        for (final goal in goals) {
            for (final record in goal.checkIns) {
                if (record.needsReview) {
                    items.add(ReviewEntry(goal: goal, record: record));
                }
            }
        }
        items.sort((a, b) {
            final dateCompare = b.record.date.compareTo(a.record.date);
            if (dateCompare != 0) {
                return dateCompare;
            }
            return a.record.nextReviewDate.compareTo(b.record.nextReviewDate);
        });
        return items;
    }

    List<ReviewEntry> get dueReviewEntries {
        return reviewEntries.where((item) => item.record.isDue()).toList();
    }

    List<ActivityReviewEntry> get activityReviewEntries {
        final items = <ActivityReviewEntry>[];
        for (final goal in goals) {
            for (final review in goal.activityReviews) {
                if (!review.finished) {
                    items.add(ActivityReviewEntry(goal: goal, review: review));
                }
            }
        }
        items.sort((a, b) {
            return a.review.nextReviewDate.compareTo(b.review.nextReviewDate);
        });
        return items;
    }

    List<ActivityReviewEntry> get dueActivityReviews {
        return activityReviewEntries.where((item) => item.review.isDue()).toList();
    }

    List<ActivityReviewEntry> filteredActivityReviews(String? goalId) {
        if (goalId == null || goalId.isEmpty) {
            return activityReviewEntries;
        }
        return activityReviewEntries.where((item) => item.goal.id == goalId).toList();
    }

    List<ReviewEntry> filteredReviewEntries(String? goalId) {
        if (goalId == null || goalId.isEmpty) {
            return reviewEntries;
        }
        return reviewEntries.where((item) => item.goal.id == goalId).toList();
    }

    int timerMinutesOn(String date, {String? goalId}) {
        final targets = goalId == null
            ? goals
            : goals.where((goal) => goal.id == goalId);
        return targets.fold<int>(
            0,
            (sum, goal) => sum + goal.timerMinutesOn(date),
        );
    }

    int timerMinutesBetween(DateTime start, DateTime end, {String? goalId}) {
        var total = 0;
        var cursor = dateOnly(start);
        final last = dateOnly(end);
        while (!cursor.isAfter(last)) {
            total += timerMinutesOn(formatDate(cursor), goalId: goalId);
            cursor = cursor.add(const Duration(days: 1));
        }
        return total;
    }

    int timerMinutesInMonth(int year, int month, {String? goalId}) {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 0);
        return timerMinutesBetween(start, end, goalId: goalId);
    }

    String get timerPhaseLabel {
        return timerIsBreak ? "休息中" : "学习中";
    }

    int get currentPhaseMinutes {
        return timerIsBreak ? breakMinutes : pomodoroMinutes;
    }

    void setTimerDurations({int? workMinutes, int? restMinutes}) {
        if (timerRunning) {
            return;
        }
        if (workMinutes != null) {
            pomodoroMinutes = workMinutes < 1 ? 1 : workMinutes;
        }
        if (restMinutes != null) {
            breakMinutes = restMinutes < 1 ? 1 : restMinutes;
        }
        timerIsBreak = false;
        timerRemainingSeconds = pomodoroMinutes * 60;
        timerElapsedSeconds = 0;
        notifyListeners();
    }

    void setPomodoroMinutes(int minutes) {
        setTimerDurations(workMinutes: minutes);
    }

    void startTimer({bool asBreak = false}) {
        final goal = selectedGoal;
        if (!asBreak && goal == null) {
            return;
        }
        if (!asBreak) {
            timerGoalId ??= goal?.id;
        }
        timerIsBreak = asBreak;
        if (timerRemainingSeconds <= 0) {
            timerRemainingSeconds = currentPhaseMinutes * 60;
            timerElapsedSeconds = 0;
        }
        timerRunning = true;
        notifyListeners();
    }

    void pauseTimer() {
        timerRunning = false;
        notifyListeners();
    }

    void resetTimer() {
        timerRunning = false;
        timerIsBreak = false;
        timerRemainingSeconds = pomodoroMinutes * 60;
        timerElapsedSeconds = 0;
        notifyListeners();
    }

    Future<void> tick() async {
        if (!timerRunning) {
            return;
        }

        timerRemainingSeconds -= 1;
        timerElapsedSeconds += 1;

        if (timerRemainingSeconds <= 0) {
            timerRunning = false;
            if (timerIsBreak) {
                timerIsBreak = false;
                timerRemainingSeconds = pomodoroMinutes * 60;
                timerElapsedSeconds = 0;
            } else {
                await addTimeLog(
                    minutes: pomodoroMinutes,
                    goalId: timerGoalId,
                );
                timerIsBreak = true;
                timerRemainingSeconds = breakMinutes * 60;
                timerElapsedSeconds = 0;
                timerRunning = true;
            }
        }

        notifyListeners();
    }

    Future<void> saveElapsedAndStop() async {
        final wasBreak = timerIsBreak;
        final elapsedMinutes = (timerElapsedSeconds + 30) ~/ 60;
        timerRunning = false;

        if (!wasBreak && elapsedMinutes >= 1) {
            await addTimeLog(
                minutes: elapsedMinutes,
                goalId: timerGoalId,
            );
        }

        timerIsBreak = false;
        timerRemainingSeconds = pomodoroMinutes * 60;
        timerElapsedSeconds = 0;
        timerGoalId = null;
        notifyListeners();
        await save();
    }

    Future<void> addTimeLog({
        required int minutes,
        String? goalId,
    }) async {
        if (minutes < 1) {
            return;
        }

        final goal = goalId == null ? selectedGoal : _goalById(goalId);
        if (goal == null) {
            return;
        }

        goal.timeLogs.add(
            TimeLog(
                date: formatDate(DateTime.now()),
                minutes: minutes,
            ),
        );
        notifyListeners();
        await save();
    }

    Future<void> load() async {
        goals = await StorageService.loadGoals();
        loaded = true;
        notifyListeners();
    }

    Future<void> save() async {
        await StorageService.saveGoals(goals);
        if (cloudConnected) {
            await syncNow();
        }
    }

    Map<String, dynamic> _document() => {
        'schemaVersion': 1,
        'goals': goals.map((goal) => goal.toJson()).toList(),
    };

    Future<CloudBootstrapResult> connectCloud() async {
        syncing = true;
        syncError = null;
        notifyListeners();
        try {
            final remote = await api.getDocument();
            cloudConnected = true;
            _cloudVersion = remote.version;
            if (remote.document == null) return CloudBootstrapResult.cloudEmpty;
            _restore(remote);
            await StorageService.saveGoals(goals);
            lastSyncedAt = DateTime.now();
            syncPending = false;
            return CloudBootstrapResult.restored;
        } on CloudApiException catch (error) {
            cloudConnected = false;
            syncPending = true;
            syncError = error.message;
            return CloudBootstrapResult.failed;
        } finally {
            syncing = false;
            notifyListeners();
        }
    }

    Future<void> uploadLocal({bool force = false}) async {
        syncing = true;
        syncError = null;
        notifyListeners();
        try {
            final remote = await api.putDocument(_document(), _cloudVersion, force: force);
            _cloudVersion = remote.version;
            cloudConnected = true;
            syncPending = false;
            hasConflict = false;
            lastSyncedAt = DateTime.now();
        } on CloudConflictException catch (error) {
            hasConflict = true;
            syncPending = true;
            syncError = error.message;
        } on CloudApiException catch (error) {
            syncPending = true;
            syncError = error.message;
        } finally {
            syncing = false;
            notifyListeners();
        }
    }

    Future<void> syncNow() async {
        if (!cloudConnected || syncing) return;
        await uploadLocal();
    }

    Future<void> useCloudVersion() async {
        final remote = await api.getDocument();
        if (remote.document != null) {
            _restore(remote);
            await StorageService.saveGoals(goals);
        }
        _cloudVersion = remote.version;
        hasConflict = false;
        syncPending = false;
        lastSyncedAt = DateTime.now();
        notifyListeners();
    }

    void disconnectCloud() {
        cloudConnected = false;
        syncPending = false;
        hasConflict = false;
        syncError = null;
        _cloudVersion = 0;
        notifyListeners();
    }

    void _restore(CloudDocument remote) {
        final source = remote.document?['goals'];
        if (source is! List) throw const CloudApiException('云端学习数据格式不正确。');
        goals = source.map((item) => Goal.fromJson(Map<String, dynamic>.from(item as Map))).toList();
        selectedIndex = goals.isEmpty ? 0 : selectedIndex.clamp(0, goals.length - 1);
        _cloudVersion = remote.version;
    }

    void selectGoal(int index) {
        selectedIndex = index;
        notifyListeners();
    }

    void selectGoalById(String id) {
        final index = goals.indexWhere((goal) => goal.id == id);
        if (index == -1) {
            return;
        }
        selectedIndex = index;
        notifyListeners();
    }

    Future<void> setTodayPlan({
        required String goalId,
        required bool enabled,
        int? plannedMinutes,
        String? todayPlanContent,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }

        if (enabled) {
            goal.todayPlanDate = formatDate(DateTime.now());
            if (todayPlanContent != null) {
                goal.todayPlanContent = todayPlanContent.trim();
            }
        } else {
            goal.todayPlanDate = "";
            goal.todayPlanContent = "";
        }
        if (plannedMinutes != null && plannedMinutes > 0) {
            goal.plannedMinutes = plannedMinutes;
        }
        notifyListeners();
        await save();
    }

    Future<void> toggleActivityDone({
        required String goalId,
        required String activityId,
        DateTime? date,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }

        final dateKey = formatDate(date ?? DateTime.now());
        final exists = goal.activityDones.any((item) {
            return item.date == dateKey && item.activityId == activityId;
        });
        if (exists) {
            goal.activityDones.removeWhere((item) {
                return item.date == dateKey && item.activityId == activityId;
            });
        } else {
            goal.activityDones.add(
                ActivityDone(date: dateKey, activityId: activityId),
            );
        }
        notifyListeners();
        await save();
    }

    /// 点一次排到明天；再点一次改回今天。改期时去掉今天的勾，避免当成已完成。
    Future<void> deferActivityToTomorrow({
        required String goalId,
        required String activityId,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }

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

        final today = formatDate(DateTime.now());
        final tomorrow = formatTomorrow();
        if (activity.planDate == tomorrow) {
            activity.planDate = "";
        } else {
            activity.planDate = tomorrow;
            goal.activityDones.removeWhere((item) {
                return item.date == today && item.activityId == activityId;
            });
        }
        notifyListeners();
        await save();
    }

    Future<void> addActivityReview({
        required String goalId,
        required GoalActivity activity,
        required String doneDate,
        required String point,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }
        final text = point.trim();
        if (text.isEmpty) {
            return;
        }
        goal.activityReviews.add(
            ActivityReview(
                activityId: activity.id,
                activityTitle: activity.title,
                doneDate: doneDate,
                nextReviewDate: formatTomorrow(),
                point: text,
            ),
        );
        notifyListeners();
        await save();
    }

    Future<void> updateActivityReviewPoint({
        required String goalId,
        required String reviewId,
        required String point,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }
        for (final review in goal.activityReviews) {
            if (review.id == reviewId) {
                review.point = point.trim();
                break;
            }
        }
        notifyListeners();
        await save();
    }

    Future<void> scheduleActivityReview({
        required String goalId,
        required String reviewId,
        required int days,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }
        final safeDays = days < 1 ? 1 : days;
        for (final review in goal.activityReviews) {
            if (review.id == reviewId) {
                review.finished = false;
                review.nextReviewDate = formatDate(
                    DateTime.now().add(Duration(days: safeDays)),
                );
                break;
            }
        }
        notifyListeners();
        await save();
    }

    Future<void> finishActivityReview({
        required String goalId,
        required String reviewId,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }
        for (final review in goal.activityReviews) {
            if (review.id == reviewId) {
                review.finished = true;
                break;
            }
        }
        notifyListeners();
        await save();
    }

    Future<void> addCheckIn({
        required int quantity,
        required int minutes,
        required DateTime date,
        String title = "",
        String summary = "",
        bool needsReview = false,
    }) async {
        final goal = selectedGoal;
        if (goal == null) {
            return;
        }

        goal.checkIns.add(
            CheckInRecord(
                date: formatDate(date),
                quantity: quantity,
                minutes: minutes,
                title: title,
                summary: summary,
                needsReview: needsReview,
            ),
        );

        notifyListeners();
        await save();
    }

    Future<void> updateCheckIn({
        required String goalId,
        required String recordId,
        required int quantity,
        required int minutes,
        required String title,
        required String summary,
        required bool needsReview,
    }) async {
        final record = _recordById(goalId, recordId);
        if (record == null) {
            return;
        }

        record.quantity = quantity;
        record.minutes = minutes;
        record.title = title;
        record.summary = summary;
        record.needsReview = needsReview;
        if (!needsReview) {
            record.nextReviewDate = "";
        }
        notifyListeners();
        await save();
    }

    Future<void> deleteCheckIn({
        required String goalId,
        required String recordId,
    }) async {
        final goal = _goalById(goalId);
        if (goal == null) {
            return;
        }

        goal.checkIns.removeWhere((item) => item.id == recordId);
        notifyListeners();
        await save();
    }

    Future<void> setNeedsReview({
        required String goalId,
        required String recordId,
        required bool needsReview,
    }) async {
        final record = _recordById(goalId, recordId);
        if (record == null) {
            return;
        }

        record.needsReview = needsReview;
        if (!needsReview) {
            record.nextReviewDate = "";
        }
        notifyListeners();
        await save();
    }

    Future<void> scheduleReview({
        required String goalId,
        required String recordId,
        required int days,
    }) async {
        final record = _recordById(goalId, recordId);
        if (record == null) {
            return;
        }

        final safeDays = days < 1 ? 1 : days;
        record.needsReview = true;
        record.nextReviewDate = formatDate(
            DateTime.now().add(Duration(days: safeDays)),
        );
        notifyListeners();
        await save();
    }

    Future<void> updateGoal({
        required String id,
        required String title,
        required String goalDescription,
        required String unit,
        required int targetAmount,
        int? plannedMinutes,
        List<GoalActivity>? activities,
    }) async {
        final goal = _goalById(id);
        if (goal == null) {
            return;
        }

        goal.title = title.trim();
        goal.goalDescription = goalDescription.trim();
        goal.unit = unit.trim().isEmpty ? "个" : unit.trim();
        if (activities != null) {
            goal.activities = activities;
            if (activities.isNotEmpty) {
                goal.targetAmount = activities.length;
            } else {
                goal.targetAmount = targetAmount < 1 ? 1 : targetAmount;
            }
        } else {
            goal.targetAmount = targetAmount < 1 ? 1 : targetAmount;
        }
        if (plannedMinutes != null && plannedMinutes > 0) {
            goal.plannedMinutes = plannedMinutes;
        }
        notifyListeners();
        await save();
    }

    Future<void> updateBackupPlan(String text) async {
        final goal = selectedGoal;
        if (goal == null) {
            return;
        }
        goal.backupPlan = text;
        notifyListeners();
        await save();
    }

    Future<void> updateMaterials({
        required String videoLink,
        required String baiduVideoName,
        required String baiduFolderPath,
        required String localFilePath,
    }) async {
        final goal = selectedGoal;
        if (goal == null) {
            return;
        }

        goal.videoLink = videoLink;
        goal.baiduVideoName = baiduVideoName;
        goal.baiduFolderPath = baiduFolderPath;
        goal.localFilePath = localFilePath;
        notifyListeners();
        await save();
    }

    Future<void> addGoal(Goal goal) async {
        goals.add(goal);
        selectedIndex = goals.length - 1;
        notifyListeners();
        await save();
    }

    Future<void> deleteGoal(String id) async {
        goals.removeWhere((goal) => goal.id == id);
        if (selectedIndex >= goals.length) {
            selectedIndex = goals.isEmpty ? 0 : goals.length - 1;
        }
        notifyListeners();
        await save();
    }

    Goal? _goalById(String id) {
        for (final goal in goals) {
            if (goal.id == id) {
                return goal;
            }
        }
        return null;
    }

    CheckInRecord? _recordById(String goalId, String recordId) {
        final goal = _goalById(goalId);
        if (goal == null) {
            return null;
        }
        for (final record in goal.checkIns) {
            if (record.id == recordId) {
                return record;
            }
        }
        return null;
    }
}
