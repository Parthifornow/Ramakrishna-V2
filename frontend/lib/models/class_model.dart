class ClassInfo {
  final String classId; // e.g., "10_A" or "8_C"
  final String className;
  final String section;
  final int studentCount;

  ClassInfo({
    required this.classId,
    required this.className,
    required this.section,
    required this.studentCount,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      classId: json['classId'] ?? '',
      className: json['className'] ?? '',
      section: json['section'] ?? '',
      studentCount: json['studentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'section': section,
      'studentCount': studentCount,
    };
  }

  String get fullName => '$className-$section';
}

class Student {
  final String id;
  final String name;
  final String phoneNumber;
  final String classId;
  final String className;
  final String section;
  final String rollNumber;

  Student({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.classId,
    required this.className,
    required this.section,
    required this.rollNumber,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // Handle both possible response formats
    final classId = json['classId'] ?? '';
    String className = json['className'] ?? '';
    String section = json['section'] ?? '';
    
    // If className or section is missing but classId exists, parse from classId
    if ((className.isEmpty || section.isEmpty) && classId.isNotEmpty) {
      final parts = classId.split('_');
      if (parts.length == 2) {
        className = parts[0];
        section = parts[1];
      }
    }
    
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      classId: classId,
      className: className,
      section: section,
      rollNumber: json['rollNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'classId': classId,
      'className': className,
      'section': section,
      'rollNumber': rollNumber,
    };
  }

  String get fullClassName => '$className-$section';
}

class AssignedClass {
  final String classId;
  final String className;
  final String section;
  final String fullName;

  AssignedClass({
    required this.classId,
    required this.className,
    required this.section,
    required this.fullName,
  });

  factory AssignedClass.fromJson(Map<String, dynamic> json) {
    // Handle both response formats
    final classId = json['classId'] ?? '';
    final className = json['className'] ?? '';
    final section = json['section'] ?? '';
    final fullName = json['fullName'] ?? '$className-$section';

    return AssignedClass(
      classId: classId,
      className: className,
      section: section,
      fullName: fullName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'section': section,
      'fullName': fullName,
    };
  }
}