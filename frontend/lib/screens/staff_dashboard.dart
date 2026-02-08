import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../services/api_service.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({Key? key}) : super(key: key);

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  User? user;
  List<AssignedClass> assignedClasses = [];
  bool isLoadingClasses = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    user = ModalRoute.of(context)?.settings.arguments as User?;
    if (user != null) {
      _loadStaffData();
    }
  }

  Future<void> _loadStaffData() async {
    print('🔄 _loadStaffData called');
    print('   User ID: ${user?.id}');
    print('   User Token: ${user?.token != null ? "Present" : "Missing"}');
    
    if (user?.token == null || user?.id == null) {
      print('❌ Cannot load data - missing user info');
      setState(() => isLoadingClasses = false);
      return;
    }

    setState(() => isLoadingClasses = true);

    try {
      print('📞 Calling getStaffAssignedClasses API...');
      
      // Load staff's assigned classes
      final classesResult = await ApiService.getStaffAssignedClasses(
        token: user!.token!,
        staffId: user!.id,
      );

      print('📊 Full API response: $classesResult');
      print('   Success: ${classesResult['success']}');

      if (classesResult['success'] == true) {
        final data = classesResult['data'];
        print('📦 Data object: $data');
        
        if (data != null && data is Map) {
          // FIXED: Get assignedClasses from the data object
          final assignedClassesData = data['assignedClasses'];
          print('📋 assignedClasses field: $assignedClassesData');
          print('   Type: ${assignedClassesData.runtimeType}');
          
          if (assignedClassesData != null && assignedClassesData is List) {
            print('🔄 Parsing ${assignedClassesData.length} classes...');
            
            final parsedClasses = <AssignedClass>[];
            for (var i = 0; i < assignedClassesData.length; i++) {
              try {
                final classData = assignedClassesData[i];
                print('   Class $i: $classData');
                
                // Parse each class
                final assignedClass = AssignedClass.fromJson(classData);
                parsedClasses.add(assignedClass);
                print('   ✅ Parsed: ${assignedClass.fullName}');
              } catch (e) {
                print('   ❌ Error parsing class $i: $e');
              }
            }
            
            setState(() {
              assignedClasses = parsedClasses;
              isLoadingClasses = false;
            });
            
            print('✅ Successfully loaded ${assignedClasses.length} classes');
            for (var cls in assignedClasses) {
              print('   - ${cls.fullName} (${cls.classId})');
            }
          } else {
            print('⚠️ assignedClasses is null or not a List');
            setState(() {
              assignedClasses = [];
              isLoadingClasses = false;
            });
          }
        } else {
          print('⚠️ Data is null or not a Map');
          setState(() {
            assignedClasses = [];
            isLoadingClasses = false;
          });
        }
      } else {
        final message = classesResult['message'] ?? 'Failed to load classes';
        print('❌ API returned success=false: $message');
        setState(() {
          assignedClasses = [];
          isLoadingClasses = false;
        });
        _showErrorSnackbar(message);
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _loadStaffData: $e');
      print('   Stack trace: $stackTrace');
      setState(() {
        assignedClasses = [];
        isLoadingClasses = false;
      });
      _showErrorSnackbar('Error loading data: $e');
    }
  }

  Future<void> _viewClassStudents(AssignedClass assignedClass) async {
    if (user?.token == null) return;

    print('🎓 Viewing students for class: ${assignedClass.fullName} (${assignedClass.classId})');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final studentsResult = await ApiService.getMyClassStudents(
      token: user!.token!,
      classId: assignedClass.classId,
    );

    // Close loading dialog
    if (!mounted) return;
    Navigator.pop(context);

    print('📊 Students Result: $studentsResult');
    print('   Success: ${studentsResult['success']}');
    
    if (studentsResult['success']) {
      // The backend returns {success: true, data: {classId, className, section, students, count}}
      final data = studentsResult['data'];
      print('📦 Data object: $data');
      
      final List<dynamic> studentsData = data['students'] ?? [];
      print('👥 Students data: $studentsData');
      print('   Count: ${studentsData.length}');
      
      final students = studentsData.map((s) {
        print('   Parsing student: $s');
        return Student.fromJson(s);
      }).toList();
      
      print('✅ Parsed ${students.length} students');
      for (var student in students) {
        print('   - ${student.name} (Roll: ${student.rollNumber})');
      }
      
      _showClassStudentsDialog(assignedClass, students);
    } else {
      final message = studentsResult['message'] ?? 'Failed to load students';
      print('❌ Failed to load students: $message');
      _showErrorSnackbar(message);
    }
  }

  Future<void> _loadAllMyStudents() async {
    if (user?.token == null) return;

    print('👥 Loading all my students');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final studentsResult = await ApiService.getMyStudents(
      token: user!.token!,
    );

    // Close loading dialog
    if (!mounted) return;
    Navigator.pop(context);

    print('📊 All Students Result: $studentsResult');
    
    if (studentsResult['success']) {
      final data = studentsResult['data'];
      print('📦 Data object: $data');
      
      final List<dynamic> studentsData = data['students'] ?? [];
      print('👥 Students count: ${studentsData.length}');
      
      final students = studentsData.map((s) => Student.fromJson(s)).toList();
      
      print('✅ Parsed ${students.length} students');
      
      _showMyStudentsDialog(students);
    } else {
      final message = studentsResult['message'] ?? 'Failed to load students';
      print('❌ Failed: $message');
      _showErrorSnackbar(message);
    }
  }

  void _showClassStudentsDialog(AssignedClass assignedClass, List<Student> students) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Class ${assignedClass.fullName} Students'),
        content: SizedBox(
          width: double.maxFinite,
          child: students.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No students found in this class'),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: students.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          student.name.isNotEmpty 
                              ? student.name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Roll No: ${student.rollNumber}'),
                          Text(
                            student.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          assignedClass.fullName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showMyStudentsDialog(List<Student> students) {
    // Group students by class
    Map<String, List<Student>> studentsByClass = {};
    for (var student in students) {
      final classKey = student.fullClassName;
      if (!studentsByClass.containsKey(classKey)) {
        studentsByClass[classKey] = [];
      }
      studentsByClass[classKey]!.add(student);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All My Students (${students.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: students.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No students found'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: studentsByClass.keys.length,
                  itemBuilder: (context, index) {
                    final classKey = studentsByClass.keys.elementAt(index);
                    final classStudents = studentsByClass[classKey]!;
                    
                    return ExpansionTile(
                      title: Text(
                        'Class $classKey',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${classStudents.length} students'),
                      children: classStudents.map((student) {
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              student.name.isNotEmpty 
                                  ? student.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(student.name),
                          subtitle: Text('Roll: ${student.rollNumber}'),
                          trailing: Text(
                            student.phoneNumber,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStaffData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Staff Info Card
                Card(
                  elevation: 4,
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Staff',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.designation ?? 'Teacher',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (user?.subjects != null && user!.subjects!.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text(
                            'Subjects:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: user!.subjects!.map((subject) {
                              return Chip(
                                label: Text(subject),
                                backgroundColor: Colors.deepPurple.shade100,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // My Classes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Classes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isLoadingClasses)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${assignedClasses.length} classes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (isLoadingClasses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (assignedClasses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No class assignments yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assignedClasses.length,
                    itemBuilder: (context, index) {
                      final assignedClass = assignedClasses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              assignedClass.className,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Class ${assignedClass.fullName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Tap to view students'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _viewClassStudents(assignedClass),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _buildQuickAction(
                      icon: Icons.people,
                      title: 'All Students',
                      color: Colors.blue,
                      onTap: _loadAllMyStudents,
                    ),
                    _buildQuickAction(
                      icon: Icons.assignment,
                      title: 'Assignments',
                      color: Colors.orange,
                      onTap: () => _showComingSoonDialog('Assignments'),
                    ),
                    _buildQuickAction(
                      icon: Icons.event,
                      title: 'Attendance',
                      color: Colors.green,
                      onTap: () => _showComingSoonDialog('Attendance'),
                    ),
                    _buildQuickAction(
                      icon: Icons.grade,
                      title: 'Grades',
                      color: Colors.purple,
                      onTap: () => _showComingSoonDialog('Grades'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}