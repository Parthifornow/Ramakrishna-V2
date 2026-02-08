class Event {
  final String id;
  final String title;
  final String description;
  final String eventDate; // YYYY-MM-DD format
  final String? eventTime;
  final String? location;
  final String category; // 'academic', 'sports', 'cultural', 'holiday', 'exam', 'general'
  final String targetAudience; // 'all', 'students', 'staff', 'specific_class'
  final List<String>? targetClassIds;
  final String priority; // 'low', 'medium', 'high'
  final String? imageUrl;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.eventTime,
    this.location,
    required this.category,
    required this.targetAudience,
    this.targetClassIds,
    required this.priority,
    this.imageUrl,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      eventDate: json['eventDate'] ?? '',
      eventTime: json['eventTime'],
      location: json['location'],
      category: json['category'] ?? 'general',
      targetAudience: json['targetAudience'] ?? 'all',
      targetClassIds: json['targetClassIds'] != null 
          ? List<String>.from(json['targetClassIds']) 
          : null,
      priority: json['priority'] ?? 'medium',
      imageUrl: json['imageUrl'],
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? 'Staff',
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': eventDate,
      'eventTime': eventTime,
      'location': location,
      'category': category,
      'targetAudience': targetAudience,
      'targetClassIds': targetClassIds,
      'priority': priority,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  String get categoryDisplay {
    switch (category) {
      case 'academic':
        return 'Academic';
      case 'sports':
        return 'Sports';
      case 'cultural':
        return 'Cultural';
      case 'holiday':
        return 'Holiday';
      case 'exam':
        return 'Exam';
      default:
        return 'General';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  // Helper to parse Firestore timestamps
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    try {
      if (timestamp is Map) {
        final seconds = timestamp['_seconds'];
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
      
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      
      if (timestamp is DateTime) {
        return timestamp;
      }
    } catch (e) {
      print('⚠️ Error parsing timestamp: $e');
    }
    
    return DateTime.now();
  }

  DateTime? get eventDateTime {
    try {
      if (eventTime != null) {
        return DateTime.parse('$eventDate $eventTime');
      }
      return DateTime.parse(eventDate);
    } catch (e) {
      return null;
    }
  }

  bool get isUpcoming {
    final eventDT = eventDateTime;
    if (eventDT == null) return false;
    return eventDT.isAfter(DateTime.now());
  }

  bool get isPast {
    final eventDT = eventDateTime;
    if (eventDT == null) return false;
    return eventDT.isBefore(DateTime.now());
  }

  bool get isToday {
    final eventDT = eventDateTime;
    if (eventDT == null) return false;
    final now = DateTime.now();
    return eventDT.year == now.year &&
        eventDT.month == now.month &&
        eventDT.day == now.day;
  }
}