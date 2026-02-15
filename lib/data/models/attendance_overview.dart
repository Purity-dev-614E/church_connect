// To parse this JSON data, do:
//
//     final overview = attendanceOverviewFromJson(jsonString);

import 'dart:convert';

AttendanceOverview attendanceOverviewFromJson(String str) =>
    AttendanceOverview.fromJson(json.decode(str));

String attendanceOverviewToJson(AttendanceOverview data) =>
    json.encode(data.toJson());

class AttendanceOverview {
  String scope;
  dynamic scopeId;
  String period;
  List<AttendanceBucket> buckets;
  AttendanceSummary summary;

  AttendanceOverview({
    required this.scope,
    required this.scopeId,
    required this.period,
    required this.buckets,
    required this.summary,
  });

  factory AttendanceOverview.fromJson(Map<String, dynamic> json) =>
      AttendanceOverview(
        scope: json["scope"] ?? "overall",
        scopeId: json["scopeId"],
        period: json["period"] ?? "week",
        buckets: _parseBuckets(json),
        summary: AttendanceSummary.fromJson(
          json["summary"] ??
              json["totals"] ??
              {
                "eventCount": 0,
                "presentCount": 0,
                "totalPossible": 0,
                "attendanceRate": 0.0,
              },
        ),
      );

  Map<String, dynamic> toJson() => {
    "scope": scope,
    "scopeId": scopeId,
    "period": period,
    "buckets": List<dynamic>.from(buckets.map((x) => x.toJson())),
    "summary": summary.toJson(),
  };
}

List<AttendanceBucket> _parseBuckets(Map<String, dynamic> json) {
  final rawBuckets = json["buckets"] ?? json["overview"];
  if (rawBuckets is List) {
    return rawBuckets
        .map((x) => AttendanceBucket.fromJson(x as Map<String, dynamic>))
        .toList();
  }
  return [];
}

class AttendanceBucket {
  String label;
  DateTime startDate;
  DateTime endDate;
  int eventCount;
  int presentCount;
  int totalPossible;
  double attendanceRate;

  AttendanceBucket({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.eventCount,
    required this.presentCount,
    required this.totalPossible,
    required this.attendanceRate,
  });

  factory AttendanceBucket.fromJson(Map<String, dynamic> json) =>
      AttendanceBucket(
        label: json["label"] ?? "",
        startDate: DateTime.parse(json["startDate"]),
        endDate: DateTime.parse(json["endDate"]),
        eventCount: json["eventCount"] ?? 0,
        presentCount: json["presentCount"] ?? 0,
        totalPossible: json["totalPossible"] ?? 0,
        attendanceRate: (json["attendanceRate"] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    "label": label,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "eventCount": eventCount,
    "presentCount": presentCount,
    "totalPossible": totalPossible,
    "attendanceRate": attendanceRate,
  };
}

class AttendanceSummary {
  int eventCount;
  int presentCount;
  int totalPossible;
  double attendanceRate;

  AttendanceSummary({
    required this.eventCount,
    required this.presentCount,
    required this.totalPossible,
    required this.attendanceRate,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        eventCount: json["eventCount"] ?? 0,
        presentCount: json["presentCount"] ?? 0,
        totalPossible: json["totalPossible"] ?? 0,
        attendanceRate: (json["attendanceRate"] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    "eventCount": eventCount,
    "presentCount": presentCount,
    "totalPossible": totalPossible,
    "attendanceRate": attendanceRate,
  };
}
