import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}


// ─────────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────────
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'donor' or 'recipient'
  final String? phone;
  final String? city;
  final String? bloodGroup;
  final bool notificationsEnabled;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.city,
    this.bloodGroup,
    this.notificationsEnabled = true,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'recipient',
      phone: map['phone'],
      city: map['city'],
      bloodGroup: map['bloodGroup'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      createdAt: _parseFirestoreDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'city': city,
      'bloodGroup': bloodGroup,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? role,
    String? phone,
    String? city,
    String? bloodGroup,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
    );
  }

  bool get isDonor => role == 'donor';
  bool get isRecipient => role == 'recipient';
}

// ─────────────────────────────────────────────
// DONOR MODEL
// ─────────────────────────────────────────────
class DonorModel {
  final String uid;
  final String fullName;
  final int age;
  final String gender;
  final String phone;
  final String city;
  final String bloodGroup;
  final double weight; // in kg
  final String healthStatus; // 'Healthy' or 'Not Healthy'
  final String? diseases;
  final DateTime? lastDonationDate;
  final bool isAvailable;
  final String email;
  final DateTime updatedAt;
  final int totalDonations;

  DonorModel({
    required this.uid,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.phone,
    required this.city,
    required this.bloodGroup,
    required this.weight,
    required this.healthStatus,
    this.diseases,
    this.lastDonationDate,
    required this.isAvailable,
    required this.email,
    required this.updatedAt,
    this.totalDonations = 0,
  });

  factory DonorModel.fromMap(Map<String, dynamic> map, String uid) {
    return DonorModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      age: _toInt(map['age']),
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      city: readCity(map),
      bloodGroup: map['bloodGroup'] ?? '',
      weight: _toDouble(map['weight']),
      healthStatus: map['healthStatus'] ?? 'Healthy',
      diseases: map['diseases'],
      lastDonationDate: _parseFirestoreDate(map['lastDonationDate']),
      isAvailable: map['isAvailable'] ?? false,
      email: map['email'] ?? '',
      updatedAt: _parseFirestoreDate(map['updatedAt']) ?? DateTime.now(),
      totalDonations: _toInt(map['totalDonations']),
    );
  }

  factory DonorModel.fromDocument(DocumentSnapshot doc) {
    return DonorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  static String readCity(Map<String, dynamic> map) {
    return _readString(map, ['city', 'City', 'cityName', 'location']);
  }

  static String _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'fullNameLower': _normalizeSearchText(fullName),
      'age': age,
      'gender': gender,
      'phone': phone,
      'city': city,
      'cityLower': _normalizeSearchText(city),
      'bloodGroup': bloodGroup,
      'weight': weight,
      'healthStatus': healthStatus,
      'diseases': diseases,
      'lastDonationDate': lastDonationDate != null
          ? Timestamp.fromDate(lastDonationDate!)
          : null,
      'isAvailable': isAvailable,
      'email': email,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'totalDonations': totalDonations,
    };
  }

  static String _normalizeSearchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  DonorModel copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? phone,
    String? city,
    String? bloodGroup,
    double? weight,
    String? healthStatus,
    String? diseases,
    DateTime? lastDonationDate,
    bool? isAvailable,
    int? totalDonations,
  }) {
    return DonorModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      weight: weight ?? this.weight,
      healthStatus: healthStatus ?? this.healthStatus,
      diseases: diseases ?? this.diseases,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      isAvailable: isAvailable ?? this.isAvailable,
      updatedAt: DateTime.now(),
      totalDonations: totalDonations ?? this.totalDonations,
    );
  }

  bool get canDonate =>
      isAvailable &&
      healthStatus == 'Healthy' &&
      age >= 18 &&
      age <= 65 &&
      weight >= 50;

  String get daysSinceLastDonation {
    if (lastDonationDate == null) return 'Never donated';
    final diff = DateTime.now().difference(lastDonationDate!).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  bool get canDonateAgain {
    if (lastDonationDate == null) return true;
    return DateTime.now().difference(lastDonationDate!).inDays >= 56;
  }
}

// ─────────────────────────────────────────────
// REQUEST MODEL
// ─────────────────────────────────────────────
class RequestModel {
  final String id;
  final String recipientId;
  final String recipientName;
  final String recipientContact;
  final String donorId;
  final String donorName;
  final String patientName;
  final String bloodGroup;
  final String hospital;
  final String city;
  final String urgency; // 'Normal' or 'Emergency'
  final String status; // 'pending', 'accepted', 'rejected', 'completed'
  final String? additionalNotes;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;
  final DateTime? expiredAt;
  final int unitsNeeded;

  RequestModel({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.recipientContact,
    required this.donorId,
    required this.donorName,
    required this.patientName,
    required this.bloodGroup,
    required this.hospital,
    required this.city,
    required this.urgency,
    required this.status,
    this.additionalNotes,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.completedAt,
    this.expiredAt,
    this.unitsNeeded = 1,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RequestModel(
      id: id,
      recipientId: map['recipientId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientContact: map['recipientContact'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      patientName: map['patientName'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      hospital: map['hospital'] ?? '',
      city: map['city'] ?? '',
      urgency: map['urgency'] ?? 'Normal',
      status: map['status'] ?? 'pending',
      additionalNotes: map['additionalNotes'],
      createdAt: _parseFirestoreDate(map['createdAt']) ?? DateTime.now(),
      expiresAt: _parseFirestoreDate(map['expiresAt']) ??
          DateTime.now().add(const Duration(hours: 24)),
      respondedAt: _parseFirestoreDate(map['respondedAt']),
      completedAt: _parseFirestoreDate(map['completedAt']),
      expiredAt: _parseFirestoreDate(map['expiredAt']),
      unitsNeeded: DonorModel._toInt(map['unitsNeeded']) == 0
          ? 1
          : DonorModel._toInt(map['unitsNeeded']),
    );
  }

  factory RequestModel.fromDocument(DocumentSnapshot doc) {
    return RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientContact': recipientContact,
      'donorId': donorId,
      'donorName': donorName,
      'patientName': patientName,
      'bloodGroup': bloodGroup,
      'hospital': hospital,
      'city': city,
      'urgency': urgency,
      'status': status,
      'additionalNotes': additionalNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'expiredAt': expiredAt != null ? Timestamp.fromDate(expiredAt!) : null,
      'unitsNeeded': unitsNeeded,
    };
  }

  RequestModel copyWith({
    String? status,
    DateTime? respondedAt,
    DateTime? completedAt,
    DateTime? expiredAt,
  }) {
    return RequestModel(
      id: id,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientContact: recipientContact,
      donorId: donorId,
      donorName: donorName,
      patientName: patientName,
      bloodGroup: bloodGroup,
      hospital: hospital,
      city: city,
      urgency: urgency,
      status: status ?? this.status,
      additionalNotes: additionalNotes,
      createdAt: createdAt,
      expiresAt: expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      unitsNeeded: unitsNeeded,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired' ||
      (status == 'pending' && DateTime.now().isAfter(expiresAt));
  bool get canRespond => status == 'pending' && !isExpired;
  bool get isEmergency => urgency == 'Emergency';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'expired':
        return 'Expired';
      default:
        return 'Unknown';
    }
  }
}

class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? requestId;
  final DateTime createdAt;
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.requestId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      requestId: map['requestId'],
      createdAt: _parseFirestoreDate(map['createdAt']) ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'requestId': requestId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

