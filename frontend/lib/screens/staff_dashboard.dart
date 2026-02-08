import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../services/api_service.dart';
import 'mark_attendance_screen.dart';
import 'staff_event_screen.dart'; // Fixed: was staff_events_screen.dart

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({Key? key}) : super(key: key);

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;
  User? user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    user = ModalRoute.of(context)?.settings.arguments as User?;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _HomeScreen(user: user),
      _ClassesScreen(user: user),
      _EventsScreen(user: user),
      _ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
              _buildNavItem(Icons.class_rounded, 'Classes', 1),
              _buildNavItem(Icons.event_rounded, 'Events', 2),
              _buildNavItem(Icons.person_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6750A4) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class _HomeScreen extends StatelessWidget {
  final User? user;

  const _HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6750A4), Color(0xFF7E57C2)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.name ?? 'Staff',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.designation ?? 'Teacher',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            user?.name[0].toUpperCase() ?? 'S',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xFF6750A4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user?.subjects != null && user!.subjects!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user!.subjects!.map((subject) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              subject,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _QuickActionCard(
                        icon: Icons.edit_calendar_rounded,
                        title: 'Mark Attendance',
                        color: const Color(0xFF6750A4),
                        onTap: () => _navigateToAttendance(context),
                      ),
                      _QuickActionCard(
                        icon: Icons.event_rounded,
                        title: 'Events',
                        color: const Color(0xFF8E24AA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StaffEventsScreen(user: user!),
                            ),
                          );
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.people_rounded,
                        title: 'View Students',
                        color: const Color(0xFF1E88E5),
                        onTap: () => _loadAllStudents(context),
                      ),
                      _QuickActionCard(
                        icon: Icons.analytics_rounded,
                        title: 'Reports',
                        color: const Color(0xFF43A047),
                        onTap: () => _showComingSoon(context, 'Reports'),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAttendance(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6750A4)),
      ),
    );

    final result = await ApiService.getStaffAssignedClasses(
      token: user!.token!,
      staffId: user!.id,
    );

    Navigator.pop(context);

    if (result['success']) {
      final data = result['data'];
      final assignedClassesData = data['assignedClasses'] as List<dynamic>? ?? [];
      final classes = assignedClassesData.map((c) => AssignedClass.fromJson(c)).toList();

      if (classes.isEmpty) {
        _showSnackbar(context, 'No classes assigned');
      } else if (classes.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarkAttendanceScreen(
              user: user!,
              assignedClass: classes[0],
            ),
          ),
        );
      } else {
        _showClassSelectionDialog(context, classes);
      }
    }
  }

  void _showClassSelectionDialog(BuildContext context, List<AssignedClass> classes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Class',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final cls = classes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6750A4),
                      child: Text(
                        cls.className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Class ${cls.fullName}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarkAttendanceScreen(
                            user: user!,
                            assignedClass: cls,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _loadAllStudents(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6750A4)),
      ),
    );

    final result = await ApiService.getMyStudents(token: user!.token!);

    Navigator.pop(context);

    if (result['success']) {
      final List<dynamic> studentsData = result['data']['students'] ?? [];
      final students = studentsData.map((s) => Student.fromJson(s)).toList();
      _showStudentsDialog(context, students);
    }
  }

  void _showStudentsDialog(BuildContext context, List<Student> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Students (${students.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6750A4),
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(student.name),
                        subtitle: Text('Roll: ${student.rollNumber} • ${student.fullClassName}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Classes Screen
class _ClassesScreen extends StatefulWidget {
  final User? user;

  const _ClassesScreen({required this.user});

  @override
  State<_ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<_ClassesScreen> {
  List<AssignedClass> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => isLoading = true);

    final result = await ApiService.getStaffAssignedClasses(
      token: widget.user!.token!,
      staffId: widget.user!.id,
    );

    if (result['success']) {
      final data = result['data'];
      final assignedClassesData = data['assignedClasses'] as List<dynamic>? ?? [];

      setState(() {
        classes = assignedClassesData.map((c) => AssignedClass.fromJson(c)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Classes',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6750A4)),
            )
          : classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No Classes Assigned',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _viewStudents(cls),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF6750A4),
                                child: Text(
                                  cls.className,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class ${cls.fullName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap to view students',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _viewStudents(AssignedClass cls) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6750A4)),
      ),
    );

    final result = await ApiService.getMyClassStudents(
      token: widget.user!.token!,
      classId: cls.classId,
    );

    Navigator.pop(context);

    if (result['success']) {
      final data = result['data'];
      final List<dynamic> studentsData = data['students'] ?? [];
      final students = studentsData.map((s) => Student.fromJson(s)).toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cls.fullName} Students',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF6750A4),
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(student.name),
                          subtitle: Text('Roll: ${student.rollNumber}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// Events Screen
class _EventsScreen extends StatelessWidget {
  final User? user;

  const _EventsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return StaffEventsScreen(user: user!);
  }
}

// Profile Screen
class _ProfileScreen extends StatelessWidget {
  final User? user;

  const _ProfileScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1F1F1F)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF6750A4),
                    child: Text(
                      user?.name[0].toUpperCase() ?? 'S',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Staff',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.designation ?? 'Teacher',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ProfileInfoCard(
              icon: Icons.phone,
              title: 'Phone Number',
              value: user?.phoneNumber ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _ProfileInfoCard(
              icon: Icons.work,
              title: 'Designation',
              value: user?.designation ?? 'N/A',
            ),
            if (user?.subjects != null && user!.subjects!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ProfileInfoCard(
                icon: Icons.book,
                title: 'Subjects',
                value: user!.subjects!.join(', '),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6750A4), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}