import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trial_model.dart';

class TrialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _devicesCollection {
    return _firestore.collection('devices');
  }

  /// Device ရှိ/မရှိ စစ်မယ်
  Future<TrialModel?> getDevice(String installationId) async {
    final doc = await _devicesCollection.doc(installationId).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return TrialModel.fromFirestore(installationId, data);
  }

  /// Device အသစ်အတွက် 7-Day Trial ဖန်တီးမယ်
  Future<TrialModel> createTrial(String installationId) async {
    final now = DateTime.now();

    final trialEndAt = now.add(const Duration(days: 7));

    await _devicesCollection.doc(installationId).set({
      'installationId': installationId,

      'trialStartAt': Timestamp.fromDate(now),

      'trialEndAt': Timestamp.fromDate(trialEndAt),

      'status': 'trial',

      'createdAt': Timestamp.fromDate(now),
    });

    return TrialModel(
      installationId: installationId,
      trialStartAt: now,
      trialEndAt: trialEndAt,
      status: 'trial',
      createdAt: now,
    );
  }

  /// Device အသစ်ဆို Trial စမယ်။
  /// ရှိပြီးသားဆို အရင် Trial ကို ပြန်ယူမယ်။
  Future<TrialModel> getOrCreateTrial(String installationId) async {
    final existing = await getDevice(installationId);

    if (existing != null) {
      return existing;
    }

    return await createTrial(installationId);
  }
}
