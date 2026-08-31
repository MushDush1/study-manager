class StudyEntry {
  String id;
  String title; // 具体学习内容
  String videoLink; // B站或网页链接
  String baiduVideoName; // 百度网盘中的视频名
  String baiduFolderPath; // 百度网盘中的文件夹位置
  String localFilePath; // 本地文件路径，如 Excel/PDF/文件夹
  int studyMinutes; // 学习时长
  String reviewSummary; // 复习总结
  String studyDate; // 学习日期
  bool finished; // 是否完成

  StudyEntry({
    String? id,
    required this.title,
    this.videoLink = "",
    this.baiduVideoName = "",
    this.baiduFolderPath = "",
    this.localFilePath = "",
    this.studyMinutes = 0,
    this.reviewSummary = "",
    this.studyDate = "",
    this.finished = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "videoLink": videoLink,
      "baiduVideoName": baiduVideoName,
      "baiduFolderPath": baiduFolderPath,
      "localFilePath": localFilePath,
      "studyMinutes": studyMinutes,
      "reviewSummary": reviewSummary,
      "studyDate": studyDate,
      "finished": finished,
    };
  }

  factory StudyEntry.fromJson(Map<String, dynamic> json) {
    return StudyEntry(
      id: json["id"] as String?,
      title: (json["title"] ?? "") as String,
      videoLink: (json["videoLink"] ?? "") as String,
      baiduVideoName: (json["baiduVideoName"] ?? "") as String,
      baiduFolderPath:
          (json["baiduFolderPath"] ?? json["extractionCode"] ?? "") as String,
      localFilePath:
          (json["localFilePath"] ?? json["localPath"] ?? "") as String,
      studyMinutes: (json["studyMinutes"] ?? 0) as int,
      reviewSummary: (json["reviewSummary"] ?? "") as String,
      studyDate: (json["studyDate"] ?? "") as String,
      finished: (json["finished"] ?? false) as bool,
    );
  }
}
