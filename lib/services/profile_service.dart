import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Future<bool> profileExists(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    return doc.exists;
  }

  Future<UserModel?> getProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return UserModel.fromFirestore(uid, data);
  }

  Future<void> createProfile({
    required String uid,
    required String shopName,
    required String phoneNo,
    required String shopAddress,
    required String deviceName,
    required String email,
    required String installationId,
  }) async {
    final user = UserModel(
      id: uid,
      shopName: shopName,
      phoneNo: phoneNo,
      shopAddress: shopAddress,
      deviceName: deviceName,
      email: email,
      installationId: installationId,
    );

    await _usersCollection.doc(uid).set(user.toFirestore());
  }
}
