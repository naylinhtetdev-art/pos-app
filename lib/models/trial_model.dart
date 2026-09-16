import 'package:cloud_firestore/cloud_firestore.dart';

class TrialModel {
  final String installationId;
  final DateTime trialStartAt;
  final DateTime trialEndAt;
  final String status;
  final DateTime createdAt;

  TrialModel({
    required this.installationId,
    required this.trialStartAt,
    required this.trialEndAt,
    required this.status,
    required this.createdAt,
  });

  factory TrialModel.fromFirestore(
    String installationId,
    Map<String, dynamic> data,
  ) {
    return TrialModel(
      installationId: installationId,

      trialStartAt: (data['trialStartAt'] as Timestamp).toDate(),

      trialEndAt: (data['trialEndAt'] as Timestamp).toDate(),

      status: data['status'] ?? 'trial',

      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  bool get isActive {
    return DateTime.now().isBefore(trialEndAt);
  }

  bool get isExpired {
    return !isActive;
  }

  Duration get remaining {
    final duration = trialEndAt.difference(DateTime.now());

    if (duration.isNegative) {
      return Duration.zero;
    }

    return duration;
  }
}
