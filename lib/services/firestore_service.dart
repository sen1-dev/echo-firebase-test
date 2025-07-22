import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hearing_test_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addHearingTest({required String uid, required HearingTestModel test}) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('tests')
          .doc(test.testId)
          .set(test.toMap());
    } catch (e) {
      throw Exception('Failed to save test: $e');
    }
  }

  Future<List<HearingTestModel>> fetchHearingTests({required String uid}) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('tests')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => HearingTestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tests: $e');
    }
  }

  Future<int> getTestCount({required String uid}) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('metadata').doc('testCount').get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('count')) {
        return doc['count'] as int;
      } else {
        // Initialize if not present
        await _db.collection('users').doc(uid).collection('metadata').doc('testCount').set({'count': 0});
        return 0;
      }
    } catch (e) {
      throw Exception('Failed to get test count: $e');
    }
  }

  Future<void> incrementTestCount({required String uid}) async {
    final ref = _db.collection('users').doc(uid).collection('metadata').doc('testCount');
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        int current = 0;
        if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('count')) {
          current = snapshot['count'] as int;
        }
        transaction.set(ref, {'count': current + 1});
      });
    } catch (e) {
      throw Exception('Failed to increment test count: $e');
    }
  }

  Future<void> updateTestPdfPath({required String uid, required String testId, required String pdfPath}) async {
    try {
      await _db
        .collection('users')
        .doc(uid)
        .collection('tests')
        .doc(testId)
        .update({'pdfPath': pdfPath});
    } catch (e) {
      throw Exception('Failed to update PDF path: $e');
    }
  }
} 