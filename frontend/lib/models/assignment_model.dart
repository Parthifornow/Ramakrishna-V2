class StaffAssignment {
  final String id;
  final String staffId;
  final String staffName;
  final String className;
  final String section;
  final String subject;
  final String academicYear;

  StaffAssignment({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.className,
    required this.section,
    required this.subject,
    required this.academicYear,
  });

  factory StaffAssignment.fromJson(Map<String, dynamic> json) {
    return StaffAssignment(
      id: json['id'] ?? '',
      staffId: json['staffId'] ?? '',
      staffName: json['staffName'] ?? '',
      className: json['className'] ?? '',
      section: json['section'] ?? '',
      subject: json['subject'] ?? '',
      academicYear: json['academicYear'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'className': className,
      'section': section,
      'subject': subject,
      'academicYear': academicYear,
    };
  }

  String get fullClassName => '$className-$section';
}

class StaffMember {
  final String id;
  final String name;
  final String phoneNumber;
  final String designation;
  final List<String> subjects;

  StaffMember({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.designation,
    required this.subjects,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      designation: json['designation'] ?? '',
      subjects: json['subjects'] != null 
        ? List<String>.from(json['subjects']) 
        : [],
    );
  }

  String get subjectsText => subjects.join(', ');
}