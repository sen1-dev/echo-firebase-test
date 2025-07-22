import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/hearing_test_model.dart';
import '../widgets/audiogram_chart.dart';
import '../services/pdf_report_service.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:open_file/open_file.dart';
import 'dart:io';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  late Future<List<HearingTestModel>> _testsFuture;
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _testsFuture = _firestoreService.fetchHearingTests(uid: _user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test History')),
      body: FutureBuilder<List<HearingTestModel>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final tests = snapshot.data ?? [];
          if (tests.isEmpty) {
            return const Center(child: Text('No tests found.'));
          }
          return ListView.separated(
            itemCount: tests.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final test = tests[i];
              return ListTile(
                title: Text(
                  'Test on \\${test.date.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(test.remarks),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TestDetailScreen(test: test),
                      ),
                    );
                  },
                  child: const Text('View'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TestDetailScreen extends StatefulWidget {
  final HearingTestModel test;
  const TestDetailScreen({Key? key, required this.test}) : super(key: key);

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  final GlobalKey _chartKey = GlobalKey();
  bool _isGenerating = false;
  bool _isOpening = false;
  late HearingTestModel _test;

  @override
  void initState() {
    super.initState();
    _test = widget.test;
  }

  Future<void> _downloadPdf({bool showPreview = true}) async {
    setState(() { _isGenerating = true; });
    Uint8List? chartImage;
    try {
      RenderRepaintBoundary boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      chartImage = byteData?.buffer.asUint8List();
    } catch (e) {
      // Chart image capture failed, continue without image
    }
    final user = FirebaseAuth.instance.currentUser!;
    final pdfService = PdfReportService();
    final pdfBytes = await pdfService.generateTestReport(
      test: _test,
      user: user,
      audiogramImage: chartImage,
    );
    // Save PDF locally
    final fileName = 'ECHO_Report_${_test.testId}.pdf';
    String? pdfPath;
    try {
      pdfPath = await pdfService.savePdfToFile(pdfBytes, fileName);
      // Update Firestore and local model
      await FirestoreService().updateTestPdfPath(uid: user.uid, testId: _test.testId, pdfPath: pdfPath);
      setState(() {
        _test = HearingTestModel(
          testId: _test.testId,
          date: _test.date,
          leftEarThresholds: _test.leftEarThresholds,
          rightEarThresholds: _test.rightEarThresholds,
          testDuration: _test.testDuration,
          remarks: _test.remarks,
          pdfPath: pdfPath,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    }
    setState(() { _isGenerating = false; });
    if (showPreview) {
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    }
  }

  Future<void> _viewSavedPdf() async {
    if (_test.pdfPath == null) return;
    setState(() { _isOpening = true; });
    final file = File(_test.pdfPath!);
    if (await file.exists()) {
      await OpenFile.open(_test.pdfPath!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File not found. Please re-download.'),
          action: SnackBarAction(
            label: 'Re-Download PDF',
            onPressed: () => _downloadPdf(showPreview: false),
          ),
        ),
      );
    }
    setState(() { _isOpening = false; });
  }

  @override
  Widget build(BuildContext context) {
    final test = _test;
    return Scaffold(
      appBar: AppBar(title: const Text('Test Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text('Date: \\${test.date.toLocal()}'),
            const SizedBox(height: 8),
            Text('Duration: \\${test.testDuration.inSeconds} seconds'),
            const SizedBox(height: 8),
            Text('Remarks: \\${test.remarks}'),
            const SizedBox(height: 16),
            const Text('Left Ear Thresholds (Hz: dB HL):'),
            ...test.leftEarThresholds.entries.map((e) => Text('  \\${e.key}: \\${e.value} dB HL')),
            const SizedBox(height: 8),
            const Text('Right Ear Thresholds (Hz: dB HL):'),
            ...test.rightEarThresholds.entries.map((e) => Text('  \\${e.key}: \\${e.value} dB HL')),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: _chartKey,
              child: AudiogramChart(test: test),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: _isGenerating ? const Text('Generating...') : const Text('Download PDF'),
            ),
            if (test.pdfPath != null)
              FutureBuilder<bool>(
                future: File(test.pdfPath!).exists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.data == true) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton.icon(
                        onPressed: _isOpening ? null : _viewSavedPdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: _isOpening ? const Text('Opening...') : const Text('View Saved Report'),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }
} 