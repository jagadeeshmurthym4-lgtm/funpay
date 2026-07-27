class DeviceRegistryEntity {
  final String deviceId;
  final String userId;
  final DateTime registeredAt;
  final String? deviceModel;
  final String? devicePlatform;

  const DeviceRegistryEntity({
    required this.deviceId,
    required this.userId,
    required this.registeredAt,
    this.deviceModel,
    this.devicePlatform,
  });

  DeviceRegistryEntity copyWith({
    String? deviceId,
    String? userId,
    DateTime? registeredAt,
    String? deviceModel,
    String? devicePlatform,
  }) {
    return DeviceRegistryEntity(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      registeredAt: registeredAt ?? this.registeredAt,
      deviceModel: deviceModel ?? this.deviceModel,
      devicePlatform: devicePlatform ?? this.devicePlatform,
    );
  }
}
