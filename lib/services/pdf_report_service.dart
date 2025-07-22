import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hearing_test_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfReportService {
  Future<Uint8List> generateTestReport({
    required HearingTestModel test,
    required User user,
    Uint8List? audiogramImage,
  }) async {
    final pdf = pw.Document();
    final logo = pw.Text('ECHO', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.blue));
    final dateStr = '${test.date.toLocal()}'.split('.')[0];

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Row(children: [
            logo,
            pw.Spacer(),
            // Optionally add a logo image here
          ]),
          pw.SizedBox(height: 8),
          pw.Text('Hearing Test Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Text('User: ${user.displayName ?? ''} (${user.email ?? ''})'),
          pw.Text('Date: $dateStr'),
          pw.Text('Duration: ${test.testDuration.inSeconds} seconds'),
          pw.SizedBox(height: 8),
          pw.Text('Remarks: ${test.remarks}'),
          pw.SizedBox(height: 12),
          pw.Text('Thresholds (dB HL):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          _buildThresholdsTable(test),
          pw.SizedBox(height: 16),
          if (audiogramImage != null)
            pw.Column(children: [
              pw.Text('Audiogram:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Image(pw.MemoryImage(audiogramImage), height: 180),
            ]),
          pw.SizedBox(height: 16),
          pw.Text('Summary:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_generateSummary(test)),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Table _buildThresholdsTable(HearingTestModel test) {
    final freqs = [250, 500, 1000, 2000, 4000, 8000];
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Frequency (Hz)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Left Ear', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Right Ear', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),
        ...freqs.map((f) => pw.TableRow(
          children: [
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('$f')),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('${test.leftEarThresholds['$f']?.toStringAsFixed(1) ?? '-'}')),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('${test.rightEarThresholds['$f']?.toStringAsFixed(1) ?? '-'}')),
          ],
        )),
      ],
    );
  }

  String _generateSummary(HearingTestModel test) {
    // Simple interpretation: average left/right
    double avg(List<double> vals) => vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;
    final leftVals = test.leftEarThresholds.values.where((v) => v != null).toList();
    final rightVals = test.rightEarThresholds.values.where((v) => v != null).toList();
    final leftAvg = avg(leftVals);
    final rightAvg = avg(rightVals);
    String interp(double avg) {
      if (avg < 25) return 'Normal';
      if (avg < 40) return 'Mild hearing loss';
      if (avg < 55) return 'Moderate hearing loss';
      if (avg < 70) return 'Moderately severe hearing loss';
      if (avg < 90) return 'Severe hearing loss';
      return 'Profound hearing loss';
    }
    return 'Left Ear: ${interp(leftAvg)} (avg: ${leftAvg.toStringAsFixed(1)} dB HL)\n'
           'Right Ear: ${interp(rightAvg)} (avg: ${rightAvg.toStringAsFixed(1)} dB HL)';
  }

  Future<String> savePdfToFile(Uint8List pdfBytes, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes, flush: true);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }
} 