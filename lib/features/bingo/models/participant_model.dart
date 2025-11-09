class Participant {
  final String id;
  final String name;
  final String phone;
  final String pixKey;
  final String deviceId;
  final String? email;
  final String? gameId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Participant({
    required this.id,
    required this.name,
    required this.phone,
    required this.pixKey,
    required this.deviceId,
    this.email,
    this.gameId,
    this.createdAt,
    this.updatedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      pixKey: json['pix_key'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      email: json['email'] as String?,
      gameId: json['game_id'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'pix_key': pixKey,
      'device_id': deviceId,
      'email': email,
      'game_id': gameId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Participant copyWith({
    String? id,
    String? name,
    String? phone,
    String? pixKey,
    String? deviceId,
    String? email,
    String? gameId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pixKey: pixKey ?? this.pixKey,
      deviceId: deviceId ?? this.deviceId,
      email: email ?? this.email,
      gameId: gameId ?? this.gameId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isComplete {
    return name.trim().length >= 2 &&
           phone.trim().length >= 10 &&
           pixKey.trim().length >= 5;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Participant &&
           other.id == id &&
           other.name == name &&
           other.phone == phone &&
           other.pixKey == pixKey &&
           other.deviceId == deviceId;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, phone, pixKey, deviceId);
  }

  @override
  String toString() {
    return 'Participant(id: $id, name: $name, phone: $phone, pixKey: $pixKey, deviceId: $deviceId)';
  }
}

class ParticipantForm {
  final String name;
  final String phone;
  final String pixKey;

  const ParticipantForm({
    required this.name,
    required this.phone,
    required this.pixKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      'pix_key': pixKey.trim(),
    };
  }

  bool get isValid {
    return name.trim().length >= 2 &&
           phone.trim().length >= 10 &&
           pixKey.trim().length >= 5;
  }
}