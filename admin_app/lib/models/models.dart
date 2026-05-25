import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _dateFromFirestore(Object? value, {DateTime? fallback}) {
  if (value == null) return fallback ?? DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) {
    final isMillis = value > 100000000000;
    return DateTime.fromMillisecondsSinceEpoch(isMillis ? value : value * 1000);
  }
  if (value is double) {
    final asInt = value.toInt();
    final isMillis = asInt > 100000000000;
    return DateTime.fromMillisecondsSinceEpoch(isMillis ? asInt : asInt * 1000);
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  }
  return fallback ?? DateTime.now();
}

DateTime? _nullableDateFromFirestore(Object? value) {
  if (value == null) return null;
  return _dateFromFirestore(value);
}

String _normalizedLower(Object? value, String fallback) {
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text.isEmpty ? fallback : text;
}

String _normalizedTitle(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return fallback;
  final lower = text.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

// ─────────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────────
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'donor', 'recipient', or 'admin'
  final String? phone;
  final String? city;
  final String? bloodGroup;
  final DateTime createdAt;
  final bool isSuspended;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.city,
    this.bloodGroup,
    required this.createdAt,
    this.isSuspended = false,
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
      createdAt: _dateFromFirestore(map['createdAt']),
      isSuspended: map['isSuspended'] ?? false,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'isSuspended': isSuspended,
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
    bool? isSuspended,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      createdAt: createdAt,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }

  bool get isAdmin => role == 'admin';
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
  final bool isSuspended;

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
    this.isSuspended = false,
  });

  factory DonorModel.fromMap(Map<String, dynamic> map, String uid) {
    return DonorModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      age: (map['age'] ?? 0) is int
          ? map['age']
          : int.tryParse(map['age'].toString()) ?? 0,
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      weight: (map['weight'] ?? 0.0) is double
          ? map['weight']
          : double.tryParse(map['weight'].toString()) ?? 0.0,
      healthStatus: map['healthStatus'] ?? 'Healthy',
      diseases: map['diseases'],
      lastDonationDate: _nullableDateFromFirestore(map['lastDonationDate']),
      isAvailable: map['isAvailable'] ?? false,
      email: map['email'] ?? '',
      updatedAt: _dateFromFirestore(map['updatedAt']),
      totalDonations: map['totalDonations'] ?? 0,
      isSuspended: map['isSuspended'] ?? false,
    );
  }

  factory DonorModel.fromDocument(DocumentSnapshot doc) {
    return DonorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'phone': phone,
      'city': city,
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
      'isSuspended': isSuspended,
    };
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
    bool? isSuspended,
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
      isSuspended: isSuspended ?? this.isSuspended,
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
  final DateTime? respondedAt;
  final DateTime? completedAt;
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
    this.respondedAt,
    this.completedAt,
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
      urgency: _normalizedTitle(map['urgency'], 'Normal'),
      status: _normalizedLower(map['status'], 'pending'),
      additionalNotes: map['additionalNotes'],
      createdAt: _dateFromFirestore(map['createdAt']),
      respondedAt: _nullableDateFromFirestore(map['respondedAt']),
      completedAt: _nullableDateFromFirestore(map['completedAt']),
      unitsNeeded: map['unitsNeeded'] ?? 1,
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
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'unitsNeeded': unitsNeeded,
    };
  }

  RequestModel copyWith({
    String? status,
    DateTime? respondedAt,
    DateTime? completedAt,
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
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
      unitsNeeded: unitsNeeded,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isEmergency => urgency.toLowerCase() == 'emergency';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}
