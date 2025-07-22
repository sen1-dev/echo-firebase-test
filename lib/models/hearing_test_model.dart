import 'package:cloud_firestore/cloud_firestore.dart';

class HearingTestModel {
  final String testId;
  final DateTime date;
  final Map<String, double> leftEarThresholds; // frequency (Hz) -> dB HL
  final Map<String, double> rightEarThresholds;
  final Duration testDuration;
  final String remarks;
  final String? pdfPath;

  HearingTestModel({
    required this.testId,
    required this.date,
    required this.leftEarThresholds,
    required this.rightEarThresholds,
    required this.testDuration,
    required this.remarks,
    this.pdfPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'date': Timestamp.fromDate(date),
      'leftEarThresholds': leftEarThresholds,
      'rightEarThresholds': rightEarThresholds,
      'testDuration': testDuration.inSeconds,
      'remarks': remarks,
      if (pdfPath != null) 'pdfPath': pdfPath,
    };
  }

  factory HearingTestModel.fromMap(Map<String, dynamic> map) {
    return HearingTestModel(
      testId: map['testId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      leftEarThresholds: Map<String, double>.from(map['leftEarThresholds'] ?? {}),
      rightEarThresholds: Map<String, double>.from(map['rightEarThresholds'] ?? {}),
      testDuration: Duration(seconds: map['testDuration'] ?? 0),
      remarks: map['remarks'] as String? ?? '',
      pdfPath: map['pdfPath'] as String?,
    );
  }
} 