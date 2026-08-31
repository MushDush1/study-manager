import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/default_goals.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../utils/unique_id.dart';

class StorageService {
    static const String _tasksKey = "tasks";
    static const String _goalsKey = "goals_v1";

    static Future<void> saveTasks(List<Task> tasks) async {
        final prefs = await SharedPreferences.getInstance();
        final data = tasks.map((task) => jsonEncode(task.toJson())).toList();
        await prefs.setStringList(_tasksKey, data);
    }

    static Future<List<Task>> loadTasks() async {
        final prefs = await SharedPreferences.getInstance();
        final data = prefs.getStringList(_tasksKey);

        if (data == null) {
            return [];
        }

        return data.map((item) {
            final json = jsonDecode(item) as Map<String, dynamic>;
            return Task.fromJson(json);
        }).toList();
    }

    static Future<void> saveGoals(List<Goal> goals) async {
        final prefs = await SharedPreferences.getInstance();
        final data = goals.map((goal) => jsonEncode(goal.toJson())).toList();
        await prefs.setStringList(_goalsKey, data);
    }

    static Future<List<Goal>> loadGoals() async {
        final prefs = await SharedPreferences.getInstance();
        final data = prefs.getStringList(_goalsKey);

        if (data == null || data.isEmpty) {
            final defaults = buildDefaultGoals();
            await saveGoals(defaults);
            return defaults;
        }

        final goals = data.map((item) {
            final json = jsonDecode(item) as Map<String, dynamic>;
            return Goal.fromJson(json);
        }).toList();

        final seen = <String>{};
        for (final goal in goals) {
            if (goal.id.trim().isEmpty || seen.contains(goal.id)) {
                goal.id = createUniqueId();
            }
            seen.add(goal.id);

            final activityIds = <String>{};
            for (final activity in goal.activities) {
                if (activity.id.trim().isEmpty || activityIds.contains(activity.id)) {
                    activity.id = createUniqueId();
                }
                activityIds.add(activity.id);
            }

            // 旧的日语N4 是「每天 20 个」，补成可分别勾完的小任务
            if (goal.activities.isEmpty &&
                (goal.id == "japanese_n4" || goal.title.contains("日语")) &&
                goal.unit == "个" &&
                goal.targetAmount == 20) {
                goal.activities = Goal.suggestedActivities(goal.title);
                if (goal.activities.isNotEmpty) {
                    goal.targetAmount = goal.activities.length;
                    goal.unit = "项";
                }
            }
        }

        // 把旧的 4000/3600 长期目标落成每天的量，并写回去重后的 id
        await saveGoals(goals);
        return goals;
    }
}
