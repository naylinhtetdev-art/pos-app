import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String shopName;
  final String phoneNo;
  final String shopAddress;
  final String deviceName;
  final String email;
  final String installationId;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.shopName,
    required this.phoneNo,
    required this.shopAddress,
    required this.deviceName,
    required this.email,
    required this.installationId,
    this.createdAt,
  });

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    final createdAtData = data['createdAt'];

    return UserModel(
      id: id,
      shopName: data['shopName'] ?? '',
      deviceName: data['deviceName'] ?? '',
      phoneNo: data['phoneNo'] ?? '',
      shopAddress: data['shopAddress'] ?? '',
      email: data['email'] ?? '',
      installationId: data['installationId'] ?? '',
      createdAt: createdAtData is Timestamp ? createdAtData.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopName': shopName,
      'deviceName': deviceName,
      'phoneNo': phoneNo,
      'shopAddress': shopAddress,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
