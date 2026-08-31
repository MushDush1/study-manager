import 'study_entry.dart';

class Task {
  String id; // 任务唯一标识

  String title; //任务名字

  String category; // 任务分类

  List<String> sections; // 项目下的学习分类

  bool finished; //是否完成

  int plannedMinutes; // 计划学习时长

  int actualMinutes; // 实际学习时长

  String linkOrPath; // 学习资料链接或本地路径

  bool isTodayPlan; // 是否加入今日计划

  Map<String, List<StudyEntry>> sectionEntries; // 分类下的具体学习内容

  Task({
    String? id,
    required this.title,
    this.category = "",
    List<String>? sections,
    this.finished = false,
    this.plannedMinutes = 60,
    this.actualMinutes = 0,
    this.linkOrPath = "",
    this.isTodayPlan = false,
    Map<String, List<StudyEntry>>? sectionEntries,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       sections =
           sections ?? defaultSectionsFor(title: title, category: category),
       sectionEntries =
           sectionEntries ??
           buildEmptySectionEntries(
             sections ?? defaultSectionsFor(title: title, category: category),
           );

  static List<String> defaultSectionsFor({
    required String title,
    required String category,
  }) {
    final normalizedTitle = title.toLowerCase();

    if (normalizedTitle.contains("ielts") || title.contains("雅思")) {
      return ["听", "说", "读", "写"];
    }

    if (title.contains("日语")) {
      return ["单词", "语法", "听力", "阅读"];
    }

    if (title.contains("C++") || category == "编程") {
      return ["基础语法", "刷题", "项目实践", "复盘"];
    }

    if (title.contains("YOLO") || category == "项目") {
      return ["资料学习", "代码实现", "实验记录", "总结"];
    }

    return ["学习内容", "资料整理", "复习总结"];
  }

  static Map<String, List<StudyEntry>> buildEmptySectionEntries(
    List<String> sections,
  ) {
    return {for (final section in sections) section: <StudyEntry>[]};
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "category": category,
      "sections": sections,
      "finished": finished,
      "plannedMinutes": plannedMinutes,
      "actualMinutes": actualMinutes,
      "linkOrPath": linkOrPath,
      "isTodayPlan": isTodayPlan,
      "sectionEntries": sectionEntries.map(
        (key, value) =>
            MapEntry(key, value.map((entry) => entry.toJson()).toList()),
      ),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json["id"] as String?,
      title: (json["title"] ?? "") as String,
      category: (json["category"] ?? "") as String,
      sections: (json["sections"] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      finished: (json["finished"] ?? false) as bool,
      plannedMinutes: (json["plannedMinutes"] ?? 60) as int,
      actualMinutes: (json["actualMinutes"] ?? 0) as int,
      linkOrPath: (json["linkOrPath"] ?? "") as String,
      isTodayPlan: (json["isTodayPlan"] ?? false) as bool,
      sectionEntries: _parseSectionEntries(
        json["sectionEntries"],
        (json["sections"] as List<dynamic>?)
                ?.map((item) => item.toString())
                .toList() ??
            [],
      ),
    );
  }

  static Map<String, List<StudyEntry>> _parseSectionEntries(
    dynamic rawEntries,
    List<String> sections,
  ) {
    final entries = buildEmptySectionEntries(sections);

    if (rawEntries is! Map) {
      return entries;
    }

    for (final section in rawEntries.entries) {
      final sectionName = section.key.toString();
      final rawList = section.value;

      if (rawList is! List) {
        continue;
      }

      entries[sectionName] = rawList
          .map(
            (item) =>
                StudyEntry.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }

    return entries;
  }
}
