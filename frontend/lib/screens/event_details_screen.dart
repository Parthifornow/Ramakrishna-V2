import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  final User user;
  final VoidCallback? onEventUpdated;

  const EventDetailsScreen({
    Key? key,
    required this.event,
    required this.user,
    this.onEventUpdated,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool isDeleting = false;

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

  Future<void> _deleteEvent() async {
    setState(() => isDeleting = true);

    try {
      final result = await ApiService.deleteEvent(
        token: widget.user.token!,
        eventId: widget.event.id,
      );

      if (result['success']) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        widget.onEventUpdated?.call();
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete event'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting event'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Event'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.event.category);
    final priorityColor = _getPriorityColor(widget.event.priority);
    final isMyEvent = widget.event.createdBy == widget.user.id;
    final isStaff = widget.user.userType == 'staff';

    DateTime? eventDate;
    try {
      eventDate = DateTime.parse(widget.event.eventDate);
    } catch (e) {
      // Handle error
    }

    final bool isPast = eventDate != null && eventDate.isBefore(DateTime.now());
    final bool isToday = eventDate != null &&
        eventDate.year == DateTime.now().year &&
        eventDate.month == DateTime.now().month &&
        eventDate.day == DateTime.now().day;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: categoryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor,
                      categoryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(widget.event.category),
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.event.categoryDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'PAST EVENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (isStaff && isMyEvent)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Delete Event'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation();
                    }
                  },
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Card
                Container(
                  margin: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.event.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: priorityColor),
                            ),
                            child: Text(
                              widget.event.priority.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.event.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Details Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        eventDate != null
                            ? DateFormat('EEEE, MMMM d, yyyy').format(eventDate)
                            : widget.event.eventDate,
                        categoryColor,
                      ),

                      // Time
                      if (widget.event.eventTime != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.access_time,
                          'Time',
                          widget.event.eventTime!,
                          categoryColor,
                        ),
                      ],

                      // Location
                      if (widget.event.location != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.location_on,
                          'Location',
                          widget.event.location!,
                          categoryColor,
                        ),
                      ],

                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.people,
                        'Target Audience',
                        _getTargetText(widget.event.targetAudience),
                        categoryColor,
                      ),

                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.person,
                        'Organized By',
                        widget.event.createdByName,
                        categoryColor,
                      ),

                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.history,
                        'Posted',
                        _getTimeAgo(widget.event.createdAt),
                        categoryColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDeleting
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}