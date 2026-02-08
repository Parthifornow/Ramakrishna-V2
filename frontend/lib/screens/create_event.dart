import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../services/api_service.dart';

class CreateEventScreen extends StatefulWidget {
  final User user;

  const CreateEventScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  String selectedCategory = 'general';
  String selectedPriority = 'medium';
  String selectedTarget = 'students';
  List<String> selectedClassIds = [];
  List<AssignedClass> availableClasses = [];
  bool isLoading = false;
  bool isLoadingClasses = false;

  final List<Map<String, dynamic>> categories = [
    {'value': 'academic', 'label': 'Academic', 'icon': Icons.school},
    {'value': 'sports', 'label': 'Sports', 'icon': Icons.sports},
    {'value': 'cultural', 'label': 'Cultural', 'icon': Icons.palette},
    {'value': 'holiday', 'label': 'Holiday', 'icon': Icons.celebration},
    {'value': 'exam', 'label': 'Exam', 'icon': Icons.assignment},
    {'value': 'general', 'label': 'General', 'icon': Icons.event},
  ];

  final List<Map<String, dynamic>> priorities = [
    {'value': 'low', 'label': 'Low', 'color': Colors.green},
    {'value': 'medium', 'label': 'Medium', 'color': Colors.orange},
    {'value': 'high', 'label': 'High', 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> targets = [
    {'value': 'all', 'label': 'Everyone', 'icon': Icons.public},
    {'value': 'students', 'label': 'All Students', 'icon': Icons.school},
    {'value': 'staff', 'label': 'Staff Only', 'icon': Icons.work},
    {'value': 'specific_class', 'label': 'Specific Classes', 'icon': Icons.class_},
  ];

  @override
  void initState() {
    super.initState();
    _loadStaffClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffClasses() async {
    setState(() => isLoadingClasses = true);

    try {
      final result = await ApiService.getStaffAssignedClasses(
        token: widget.user.token!,
        staffId: widget.user.id,
      );

      if (result['success']) {
        final data = result['data'];
        final List<dynamic> classesData = data['assignedClasses'] ?? [];
        setState(() {
          availableClasses = classesData.map((c) => AssignedClass.fromJson(c)).toList();
        });
      }
    } catch (e) {
      print('Error loading classes: $e');
    } finally {
      setState(() => isLoadingClasses = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6750A4),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6750A4),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedTarget == 'specific_class' && selectedClassIds.isEmpty) {
      _showSnackbar('Please select at least one class', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final timeStr = selectedTime != null
          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final result = await ApiService.createEvent(
        token: widget.user.token!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: dateStr,
        eventTime: timeStr,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        category: selectedCategory,
        targetAudience: selectedTarget,
        targetClassIds: selectedTarget == 'specific_class' ? selectedClassIds : null,
        priority: selectedPriority,
      );

      if (result['success']) {
        _showSnackbar('Event created successfully!', Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnackbar(
          result['message'] ?? 'Failed to create event',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackbar('Error creating event', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Event Title *',
                hintText: 'Enter event title',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter event title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText: 'Enter event description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter event description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Selection
            const Text(
              'Category *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat['value'];
                return InkWell(
                  onTap: () => setState(() => selectedCategory = cat['value']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6750A4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6750A4)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF6750A4)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(selectedDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF6750A4)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedTime != null
                                    ? selectedTime!.format(context)
                                    : 'Optional',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Field
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location (Optional)',
                hintText: 'Enter event location',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Priority Selection
            const Text(
              'Priority *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: priorities.map((priority) {
                final isSelected = selectedPriority == priority['value'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => selectedPriority = priority['value']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? priority['color']
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: priority['color'],
                          ),
                        ),
                        child: Text(
                          priority['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : priority['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Target Audience
            const Text(
              'Target Audience *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: targets.map((target) {
                final isSelected = selectedTarget == target['value'];
                return InkWell(
                  onTap: () => setState(() => selectedTarget = target['value']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6750A4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6750A4)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          target['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          target['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Specific Class Selection
            if (selectedTarget == 'specific_class') ...[
              const SizedBox(height: 16),
              const Text(
                'Select Classes *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (isLoadingClasses)
                const Center(child: CircularProgressIndicator())
              else if (availableClasses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Text(
                    'No classes assigned to you',
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableClasses.map((cls) {
                    final isSelected = selectedClassIds.contains(cls.classId);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedClassIds.remove(cls.classId);
                          } else {
                            selectedClassIds.add(cls.classId);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6750A4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6750A4)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          cls.fullName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'CREATE EVENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}