import 'package:cashspark/domain/entities/device_registry_entity.dart';

class DeviceRegistryModel extends DeviceRegistryEntity {
  const DeviceRegistryModel({
    required super.deviceId,
    required super.userId,
    required super.registeredAt,
    super.deviceModel,
    super.devicePlatform,
  });

  factory DeviceRegistryModel.fromEntity(DeviceRegistryEntity entity) {
    return DeviceRegistryModel(
      deviceId: entity.deviceId,
      userId: entity.userId,
      registeredAt: entity.registeredAt,
      deviceModel: entity.deviceModel,
      devicePlatform: entity.devicePlatform,
    );
  }

  factory DeviceRegistryModel.fromFirestore(
      Map<String, dynamic> map, String docId) {
    return DeviceRegistryModel(
      deviceId: docId,
      userId: map['userId'] as String? ?? '',
      registeredAt: (map['registeredAt'] as dynamic) != null
          ? (map['registeredAt'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      deviceModel: map['deviceModel'] as String?,
      devicePlatform: map['devicePlatform'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'registeredAt': registeredAt,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (devicePlatform != null) 'devicePlatform': devicePlatform,
    };
  }

  DeviceRegistryModel copyWithModel({
    String? deviceId,
    String? userId,
    DateTime? registeredAt,
    String? deviceModel,
    String? devicePlatform,
  }) {
    return DeviceRegistryModel(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      registeredAt: registeredAt ?? this.registeredAt,
      deviceModel: deviceModel ?? this.deviceModel,
      devicePlatform: devicePlatform ?? this.devicePlatform,
    );
  }
}
