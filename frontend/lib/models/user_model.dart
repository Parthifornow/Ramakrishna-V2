class User {
  final String id;
  final String phoneNumber;
  final String name;
  final String userType; // 'student' or 'staff'
  final String? token;
  final bool? phoneVerified;
  final String? firebaseUid;

  // Student-specific fields
  final String? classId; // e.g., "10_A"
  final String? className;
  final String? section;
  final String? rollNumber;

  // Staff-specific fields
  final String? designation;
  final List<String>? subjects;
  final List<String>? assignedClassIds; // e.g., ["10_A", "10_B", "11_A"]

  User({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.userType,
    this.token,
    this.phoneVerified,
    this.firebaseUid,
    this.classId,
    this.className,
    this.section,
    this.rollNumber,
    this.designation,
    this.subjects,
    this.assignedClassIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'] ?? '',
      userType: json['userType'] ?? 'student',
      token: json['token'],
      phoneVerified: json['phoneVerified'] ?? false,
      firebaseUid: json['firebaseUid'],
      classId: json['classId'],
      className: json['className'],
      section: json['section'],
      rollNumber: json['rollNumber'],
      designation: json['designation'],
      subjects: json['subjects'] != null ? List<String>.from(json['subjects']) : null,
      assignedClassIds: json['assignedClassIds'] != null 
          ? List<String>.from(json['assignedClassIds']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'userType': userType,
      'token': token,
      'phoneVerified': phoneVerified,
      'firebaseUid': firebaseUid,
    };

    if (classId != null) data['classId'] = classId;
    if (className != null) data['className'] = className;
    if (section != null) data['section'] = section;
    if (rollNumber != null) data['rollNumber'] = rollNumber;
    if (designation != null) data['designation'] = designation;
    if (subjects != null) data['subjects'] = subjects;
    if (assignedClassIds != null) data['assignedClassIds'] = assignedClassIds;

    return data;
  }

  bool get isStaff => userType.toLowerCase() == 'staff';
  bool get isStudent => userType.toLowerCase() == 'student';
  bool get isVerified => phoneVerified ?? false;
  
  String get fullClassName => 
      (className != null && section != null) ? '$className-$section' : 'N/A';

  // Copy with method for updating user data
  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? userType,
    String? token,
    bool? phoneVerified,
    String? firebaseUid,
    String? classId,
    String? className,
    String? section,
    String? rollNumber,
    String? designation,
    List<String>? subjects,
    List<String>? assignedClassIds,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      token: token ?? this.token,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      rollNumber: rollNumber ?? this.rollNumber,
      designation: designation ?? this.designation,
      subjects: subjects ?? this.subjects,
      assignedClassIds: assignedClassIds ?? this.assignedClassIds,
    );
  }
}