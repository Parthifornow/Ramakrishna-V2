import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import 'event_details_screen.dart';

class StudentEventsScreen extends StatefulWidget {
  final User user;

  const StudentEventsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends State<StudentEventsScreen> {
  List<Event> allEvents = [];
  List<Event> filteredEvents = [];
  bool isLoading = true;
  String selectedFilter = 'upcoming'; // 'upcoming', 'all', 'past'
  String? selectedCategory;

  final List<String> categories = [
    'all',
    'academic',
    'sports',
    'cultural',
    'holiday',
    'exam',
    'general',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.getStudentEvents(
        token: widget.user.token!,
        limit: 100,
      );

      if (result['success']) {
        final List<dynamic> eventsData = result['data']['events'] ?? [];
        setState(() {
          allEvents = eventsData.map((e) => Event.fromJson(e)).toList();
          _applyFilters();
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

  void _applyFilters() {
    List<Event> filtered = List.from(allEvents);

    // Filter by time
    final now = DateTime.now();
    if (selectedFilter == 'upcoming') {
      filtered = filtered.where((event) {
        try {
          final eventDate = DateTime.parse(event.eventDate);
          return eventDate.isAfter(now) || 
                 (eventDate.year == now.year && 
                  eventDate.month == now.month && 
                  eventDate.day == now.day);
        } catch (e) {
          return false;
        }
      }).toList();
    } else if (selectedFilter == 'past') {
      filtered = filtered.where((event) {
        try {
          final eventDate = DateTime.parse(event.eventDate);
          return eventDate.isBefore(now) && 
                 !(eventDate.year == now.year && 
                   eventDate.month == now.month && 
                   eventDate.day == now.day);
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Filter by category
    if (selectedCategory != null && selectedCategory != 'all') {
      filtered = filtered.where((event) => event.category == selectedCategory).toList();
    }

    // Sort by date
    filtered.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.eventDate);
        final dateB = DateTime.parse(b.eventDate);
        return selectedFilter == 'past' 
            ? dateB.compareTo(dateA) // Descending for past
            : dateA.compareTo(dateB); // Ascending for upcoming
      } catch (e) {
        return 0;
      }
    });

    setState(() {
      filteredEvents = filtered;
    });
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

  String _getCategoryDisplay(String category) {
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
      case 'general':
        return 'General';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                ),
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
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadEvents,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay updated with school activities',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Filter
                  Row(
                    children: [
                      _buildTimeFilter('Upcoming', 'upcoming'),
                      const SizedBox(width: 8),
                      _buildTimeFilter('All', 'all'),
                      const SizedBox(width: 8),
                      _buildTimeFilter('Past', 'past'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryFilter(category),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Events Count
            if (!isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${filteredEvents.length} event${filteredEvents.length != 1 ? 's' : ''} found',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Events List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E88E5),
                      ),
                    )
                  : filteredEvents.isEmpty
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
                                selectedFilter == 'upcoming'
                                    ? 'No upcoming events'
                                    : selectedFilter == 'past'
                                        ? 'No past events'
                                        : 'No events found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back later for updates',
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
                          color: const Color(0xFF1E88E5),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = filteredEvents[index];
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

  Widget _buildTimeFilter(String label, String value) {
    final isSelected = selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = value;
            _applyFilters();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(String category) {
    final isSelected = (selectedCategory ?? 'all') == category;
    final color = category == 'all' ? Colors.grey[700]! : _getCategoryColor(category);
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = category;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != 'all')
              Icon(
                _getCategoryIcon(category),
                size: 14,
                color: isSelected ? color : Colors.grey[600],
              ),
            if (category != 'all') const SizedBox(width: 4),
            Text(
              _getCategoryDisplay(category),
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final categoryColor = _getCategoryColor(event.category);
    final priorityColor = _getPriorityColor(event.priority);

    DateTime? eventDate;
    try {
      eventDate = DateTime.parse(event.eventDate);
    } catch (e) {
      // Handle parse error
    }

    final bool isPast = eventDate != null && eventDate.isBefore(DateTime.now());

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
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.categoryDisplay,
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PAST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
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
                            ? DateFormat('EEEE, MMM d, yyyy').format(eventDate)
                            : event.eventDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  if (event.eventTime != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
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
                    ),
                  ],

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
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        'By ${event.createdByName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          fontSize: 12,
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: categoryColor,
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
}