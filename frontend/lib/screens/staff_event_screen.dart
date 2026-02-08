import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import 'create_event.dart';
import 'event_details_screen.dart';

class StaffEventsScreen extends StatefulWidget {
  final User user;

  const StaffEventsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<StaffEventsScreen> createState() => _StaffEventsScreenState();
}

class _StaffEventsScreenState extends State<StaffEventsScreen> {
  List<Event> events = [];
  bool isLoading = true;
  String selectedFilter = 'all'; // 'all', 'my_events', 'upcoming'

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> result;

      if (selectedFilter == 'my_events') {
        result = await ApiService.getMyEvents(
          token: widget.user.token!,
          limit: 50,
        );
      } else if (selectedFilter == 'upcoming') {
        result = await ApiService.getUpcomingEvents(
          token: widget.user.token!,
          limit: 50,
        );
      } else {
        result = await ApiService.getStaffEvents(
          token: widget.user.token!,
          limit: 50,
        );
      }

      if (result['success']) {
        final List<dynamic> eventsData = result['data']['events'] ?? [];
        setState(() {
          events = eventsData.map((e) => Event.fromJson(e)).toList();
        });
      } else {
        _showSnackbar(result['message'] ?? 'Failed to load events', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Error loading events', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final result = await ApiService.deleteEvent(
      token: widget.user.token!,
      eventId: eventId,
    );

    if (result['success']) {
      _showSnackbar('Event deleted successfully', Colors.green);
      _loadEvents();
    } else {
      _showSnackbar(result['message'] ?? 'Failed to delete event', Colors.red);
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'academic':
        return const Color(0xFF1E88E5);
      case 'sports':
        return const Color(0xFF43A047);
      case 'cultural':
        return const Color(0xFF8E24AA);
      case 'holiday':
        return const Color(0xFFFB8C00);
      case 'exam':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Events Management'),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('All Events', 'all'),
                _buildFilterChip('My Events', 'my_events'),
                _buildFilterChip('Upcoming', 'upcoming'),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6750A4),
                    ),
                  )
                : events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first event!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        color: const Color(0xFF6750A4),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return _buildEventCard(event);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEventScreen(user: widget.user),
            ),
          );
          
          if (result == true) {
            _loadEvents();
          }
        },
        backgroundColor: const Color(0xFF6750A4),
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() => selectedFilter = value);
        _loadEvents();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6750A4) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final categoryColor = _getCategoryColor(event.category);
    final priorityColor = _getPriorityColor(event.priority);
    final isMyEvent = event.createdBy == widget.user.id;

    DateTime? eventDate;
    try {
      eventDate = DateTime.parse(event.eventDate);
    } catch (e) {
      // Handle parse error
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(
                event: event,
                user: widget.user,
                onEventUpdated: _loadEvents,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(event.category),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.categoryDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor),
                    ),
                    child: Text(
                      event.priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date and Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        eventDate != null
                            ? DateFormat('MMM d, yyyy').format(eventDate)
                            : event.eventDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (event.eventTime != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          event.eventTime!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (event.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTargetIcon(event.targetAudience),
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getTargetText(event.targetAudience),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isMyEvent) ...[
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Event'),
                                content: const Text(
                                  'Are you sure you want to delete this event?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteEvent(event.id);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'academic':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'cultural':
        return Icons.palette;
      case 'holiday':
        return Icons.celebration;
      case 'exam':
        return Icons.assignment;
      default:
        return Icons.event;
    }
  }

  IconData _getTargetIcon(String target) {
    switch (target) {
      case 'all':
        return Icons.public;
      case 'students':
        return Icons.school;
      case 'staff':
        return Icons.work;
      case 'specific_class':
        return Icons.class_;
      default:
        return Icons.people;
    }
  }

  String _getTargetText(String target) {
    switch (target) {
      case 'all':
        return 'Everyone';
      case 'students':
        return 'All Students';
      case 'staff':
        return 'Staff Only';
      case 'specific_class':
        return 'Specific Classes';
      default:
        return 'Unknown';
    }
  }
}