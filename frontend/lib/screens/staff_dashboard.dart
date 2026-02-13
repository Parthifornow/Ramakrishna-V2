import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/classes_provider.dart';
import '../providers/events_provider.dart';
import '../models/class_model.dart';
import 'mark_attendance_screen.dart';
import 'staff_event_screen.dart';
import '../widgets/sticky_header_widget.dart';

class StaffDashboard extends ConsumerStatefulWidget {
  const StaffDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(classesProvider.notifier).loadStaffClasses(user.id);
        ref.read(eventsProvider.notifier).loadEvents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    final List<Widget> screens = [
      _HomeScreen(user: user),
      _ClassesScreen(user: user),
      _EventsScreen(user: user),
      _ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
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
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
              _buildNavItem(Icons.class_outlined, Icons.class_, 'Classes', 1),
              _buildNavItem(Icons.event_outlined, Icons.event, 'Events', 2),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? filledIcon : outlinedIcon,
                color: isActive ? const Color(0xFF00B4D8) : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF00B4D8) : Colors.grey[600],
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Home Screen
class _HomeScreen extends ConsumerWidget {
  final dynamic user;

  const _HomeScreen({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Header
            StickyHeader(
              greeting: 'Home',
              name: user?.name ?? 'Staff',
              subtitle: user?.designation ?? 'Teacher',
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildQuickLink(
                    context,
                    ref,
                    'Mark Attendance',
                    'Take attendance for your classes',
                    Icons.edit_calendar_outlined,
                    const Color(0xFF00B4D8),
                    () => _navigateToAttendance(context, ref, user),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickLink(
                    context,
                    ref,
                    'Events',
                    'View and manage events',
                    Icons.event_outlined,
                    const Color(0xFF00B4D8),
                    () {
                      final dashboard = context.findAncestorStateOfType<_StaffDashboardState>();
                      dashboard?.setState(() {
                        dashboard._currentIndex = 2;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuickLink(
                    context,
                    ref,
                    'My Classes',
                    'View assigned classes',
                    Icons.class_outlined,
                    const Color(0xFF00B4D8),
                    () {
                      final dashboard = context.findAncestorStateOfType<_StaffDashboardState>();
                      dashboard?.setState(() {
                        dashboard._currentIndex = 1;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLink(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _navigateToAttendance(BuildContext context, WidgetRef ref, dynamic user) async {
    final classesState = ref.read(classesProvider);
    final classes = classesState.classes;

    if (classes.isEmpty) {
      // Load classes if not loaded
      if (user != null) {
        await ref.read(classesProvider.notifier).loadStaffClasses(user.id);
        final updatedClasses = ref.read(classesProvider).classes;
        if (updatedClasses.isEmpty) {
          if (context.mounted) {
            _showSnackbar(context, 'No classes assigned');
          }
          return;
        }
        if (context.mounted) {
          _showClassSelectionDialog(context, ref, updatedClasses, user);
        }
      }
    } else if (classes.length == 1) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarkAttendanceScreen(
              user: user!,
              assignedClass: classes[0],
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        _showClassSelectionDialog(context, ref, classes, user);
      }
    }
  }

  void _showClassSelectionDialog(BuildContext context, WidgetRef ref, List<AssignedClass> classes, dynamic user) {
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00B4D8),
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

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Classes Screen
class _ClassesScreen extends ConsumerWidget {
  final dynamic user;

  const _ClassesScreen({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(classesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Header
            StickyHeader(
              greeting: 'Classes',
              name: user?.name ?? 'Staff',
              subtitle: user?.designation ?? 'Teacher',
            ),

            // Content
            Expanded(
              child: classesState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    )
                  : classesState.classes.isEmpty
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
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (user != null) {
                              await ref.read(classesProvider.notifier).loadStaffClasses(
                                user.id,
                                forceRefresh: true,
                              );
                            }
                          },
                          color: const Color(0xFF00B4D8),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: classesState.classes.length,
                            itemBuilder: (context, index) {
                              final cls = classesState.classes[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFF00B4D8),
                                    child: Text(
                                      cls.className,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Class ${cls.fullName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: const Text('Tap to view students'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _viewStudents(context, ref, cls),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewStudents(BuildContext context, WidgetRef ref, AssignedClass cls) async {
    // Load students for this class
    await ref.read(classesProvider.notifier).loadClassStudents(cls.classId);
    if (!context.mounted) return;

    final students = ref.read(classesProvider).classStudents[cls.classId];

    if (students == null || students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found in this class'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00B4D8),
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

// Events Screen
class _EventsScreen extends ConsumerWidget {
  final dynamic user;

  const _EventsScreen({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StaffEventsScreen(user: user!);
  }
}

// Profile Screen
class _ProfileScreen extends ConsumerWidget {
  final dynamic user;

  const _ProfileScreen({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Header
            StickyHeader(
              greeting: 'Profile',
              name: user?.name ?? 'Staff',
              subtitle: user?.designation ?? 'Teacher',
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF00B4D8),
                          child: Text(
                            user?.name[0].toUpperCase() ?? 'S',
                            style: const TextStyle(
                              fontSize: 32,
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

                  // Info Cards
                  _ProfileInfoCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    value: user?.phoneNumber ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.work_outline,
                    title: 'Designation',
                    value: user?.designation ?? 'N/A',
                  ),
                  if (user?.subjects != null && user!.subjects!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ProfileInfoCard(
                      icon: Icons.book_outlined,
                      title: 'Subjects',
                      value: user!.subjects!.join(', '),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Logout Button
                  ElevatedButton.icon(
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
                              onPressed: () async {
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                }
                              },
                              child: const Text('Logout', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00B4D8), size: 22),
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