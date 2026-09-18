import 'package:cloud_firestore/cloud_firestore.dart';

class LicenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkAndBindLicense({
    required String uid,
    required String installationId,
  }) async {
    final licenseRef = _firestore.collection('devices').doc(installationId);

    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(licenseRef);

        // ----------------------------
        // 1. License doesn't exist
        // ----------------------------
        if (!snapshot.exists) {
          return false;
        }

        final data = snapshot.data();

        if (data == null) {
          return false;
        }

        // ----------------------------
        // 2. Check status
        // ----------------------------
        final status = data['status'] as String?;

        if (status != 'active') {
          return false;
        }

        // ----------------------------
        // 3. Check expireAt
        // ----------------------------
        // final expireAt = data['expireAt'] as Timestamp?;

        // if (expireAt == null) {
        //   return false;
        // }

        // final now = DateTime.now();

        // if (!now.isBefore(expireAt.toDate())) {
        //   return false;
        // }

        // ----------------------------
        // 4. Existing device
        // ----------------------------
        final boundDevice = data['installationId'] as String?;

        // ----------------------------
        // 5. First device binding
        // ----------------------------
        if (boundDevice == null || boundDevice.isEmpty) {
          transaction.update(licenseRef, {
            'installationId': installationId,
            'boundAt': FieldValue.serverTimestamp(),
          });

          return true;
        }

        // ----------------------------
        // 6. Same device
        // ----------------------------
        if (boundDevice == installationId) {
          return true;
        }

        // ----------------------------
        // 7. Different device
        // ----------------------------
        return false;
      });

      return result;
    } catch (e) {
      print('License check error: $e');

      return false;
    }
  }
}
// class LicenseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<bool> checkAndBindLicense({
//     required String uid,
//     required String installationId,
//   }) async {
//     final licenseRef = _firestore.collection('licenses').doc(uid);

//     final licenseSnapshot = await licenseRef.get();

//     if (!licenseSnapshot.exists) {
//       return false;
//     }

//     final data = licenseSnapshot.data();

//     if (data == null) {
//       return false;
//     }

//     final status = data['status'] as String?;

//     if (status != 'active') {
//       return false;
//     }

//     final expireAtTimestamp = data['expireAt'] as Timestamp?;

//     if (expireAtTimestamp == null) {
//       return false;
//     }

//     final expireAt = expireAtTimestamp.toDate();

//     // License expired
//     if (!DateTime.now().isBefore(expireAt)) {
//       return false;
//     }

//     final savedInstallationId = data['installationId'] as String?;

//     // License is already bound
//     if (savedInstallationId != null && savedInstallationId.isNotEmpty) {
//       return savedInstallationId == installationId;
//     }

//     // First device binding
//     await licenseRef.update({
//       'installationId': installationId,
//       'boundAt': FieldValue.serverTimestamp(),
//     });

//     return true;
//   }
// }
