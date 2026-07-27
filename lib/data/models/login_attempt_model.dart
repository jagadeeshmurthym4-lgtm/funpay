class LoginAttemptModel {
  final String attemptId;
  final String userId;
  final bool success;
  final DateTime createdAt;
  final String? ipAddress;
  final String? deviceId;

  const LoginAttemptModel({
    required this.attemptId,
    required this.userId,
    required this.success,
    required this.createdAt,
    this.ipAddress,
    this.deviceId,
  });

  factory LoginAttemptModel.fromFirestore(
      Map<String, dynamic> map, String docId) {
    return LoginAttemptModel(
      attemptId: docId,
      userId: map['userId'] as String? ?? '',
      success: map['success'] as bool? ?? false,
      createdAt: (map['createdAt'] as dynamic) != null
          ? (map['createdAt'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      ipAddress: map['ipAddress'] as String?,
      deviceId: map['deviceId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'success': success,
      'createdAt': createdAt,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }
}
