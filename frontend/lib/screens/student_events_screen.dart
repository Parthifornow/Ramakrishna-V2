import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import 'event_details_screen.dart';

class StudentEventsScreen extends ConsumerStatefulWidget {
  final User user;

  const StudentEventsScreen({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends ConsumerState<StudentEventsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(eventsProvider.notifier).loadEvents();
    });
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'academic':
        return const Color(0xFF00B4D8);
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

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.read(eventsProvider.notifier).refresh();
                        },
                        color: const Color(0xFF00B4D8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Events List
            Expanded(
              child: eventsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    )
                  : eventsState.events.isEmpty
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
                                'No upcoming events',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back later for new events',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(eventsProvider.notifier).refresh();
                          },
                          color: const Color(0xFF00B4D8),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: eventsState.events.length,
                            itemBuilder: (context, index) {
                              final event = eventsState.events[index];
                              return _buildEventCard(event);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final date = _parseDate(event.eventDate);
    final categoryColor = _getCategoryColor(event.category);
    final categoryIcon = _getCategoryIcon(event.category);

    final bool isToday = date != null &&
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              event: event,
              user: widget.user,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.categoryDisplay,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B4D8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: Color(0xFF00B4D8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey[200]),

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
                      color: Colors.black87,
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
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date, Time, Location
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.calendar_today,
                        date != null
                            ? DateFormat('MMM d, yyyy').format(date)
                            : event.eventDate,
                      ),
                      if (event.eventTime != null)
                        _buildInfoChip(Icons.access_time, event.eventTime!),
                      if (event.location != null)
                        _buildInfoChip(Icons.location_on, event.location!),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Organizer
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF00B4D8).withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'by ${event.createdByName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey[400],
                      ),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}