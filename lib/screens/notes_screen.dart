// Notes Screen - Main notes management interface
// Author: Nikodem Stach

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import 'sign_in_screen.dart';
import 'note_editor_screen.dart';
import 'note_detail_screen.dart';
import 'profile_screen.dart';

class NotesScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const NotesScreen({super.key, required this.user});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _allNotes = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String? _selectedPriorityFilter;

  // Priority colors
  final Map<String, Color> _priorityColors = {
    'high': const Color(0xFFEF5350),
    'medium': const Color(0xFFFF9800),
    'normal': const Color(0xFF42A5F5),
    'low': const Color(0xFF66BB6A),
  };

  final Map<String, IconData> _priorityIcons = {
    'high': Icons.priority_high,
    'medium': Icons.star,
    'normal': Icons.circle,
    'low': Icons.arrow_downward,
  };

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    final notes = await DatabaseHelper.instance.getNotesByUser(
      widget.user['id'] as int,
    );
    
    setState(() {
      _allNotes = notes;
      _filterNotes();
      _isLoading = false;
    });
  }

  void _filterNotes() {
    var filtered = List<Map<String, dynamic>>.from(_allNotes);
    
    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((note) {
        final title = note['title'].toString().toLowerCase();
        final content = note['content'].toString().toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    }
    
    // Filter by priority
    if (_selectedPriorityFilter != null) {
      filtered = filtered.where((note) {
        return note['priority'] == _selectedPriorityFilter;
      }).toList();
    }
    
    // Sort: pinned notes first, then by updated_at
    filtered.sort((a, b) {
      final aPinned = (a['is_pinned'] as int?) ?? 0;
      final bPinned = (b['is_pinned'] as int?) ?? 0;
      
      // If one is pinned and the other is not, pinned comes first
      if (aPinned != bPinned) {
        return bPinned.compareTo(aPinned);
      }
      
      // If both have same pin status, sort by updated_at
      final aDate = DateTime.parse(a['updated_at'] as String);
      final bDate = DateTime.parse(b['updated_at'] as String);
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _notes = filtered;
    });
  }

  Future<void> _deleteNote(int noteId) async {
    final result = await DatabaseHelper.instance.deleteNote(noteId);
    
    if (!mounted) return;
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _loadNotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePin(int noteId) async {
    final result = await DatabaseHelper.instance.togglePinNote(noteId);
    
    if (!mounted) return;
    
    if (result['success']) {
      _loadNotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(int noteId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(noteId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryPurple,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: widget.user),
                  ),
                ).then((_) {
                  // Reload user data after returning from profile
                  setState(() {});
                });
              } else if (value == 'logout') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.user['email'],
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Profile Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (value) => _filterNotes(),
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _filterNotes();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Priority filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('High', 'high'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Medium', 'medium'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Normal', 'normal'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Low', 'low'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          // Notes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryPurple.withOpacity(0.2),
                                    AppTheme.lightPurple.withOpacity(0.2),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 80,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              _searchController.text.isNotEmpty || _selectedPriorityFilter != null
                                  ? 'No notes found'
                                  : 'No notes yet',
                              style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty || _selectedPriorityFilter != null
                                ? 'Try adjusting your filters'
                                : 'Start capturing your ideas',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotes,
                      color: AppTheme.primaryPurple,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          final priority = note['priority'] ?? 'normal';
                          final priorityColor = _priorityColors[priority] ?? _priorityColors['normal']!;
                          final priorityIcon = _priorityIcons[priority] ?? _priorityIcons['normal']!;
                          
                          return TweenAnimationBuilder(
                            duration: Duration(milliseconds: 200 + (index * 30)),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: 0.95 + (0.05 * value),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NoteDetailScreen(
                                          userId: widget.user['id'] as int,
                                          note: note,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadNotes();
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      // Priority bar
                                      Container(
                                        width: 5,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: priorityColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      // Content
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  // Priority badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: priorityColor.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          priorityIcon,
                                                          size: 12,
                                                          color: priorityColor,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          priority[0].toUpperCase() + priority.substring(1),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: priorityColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  // Pin button
                                                  InkWell(
                                                    onTap: () => _togglePin(note['id']),
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: ((note['is_pinned'] as int?) ?? 0) == 1
                                                            ? AppTheme.primaryPurple.withOpacity(0.15)
                                                            : Colors.grey.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(
                                                        ((note['is_pinned'] as int?) ?? 0) == 1
                                                            ? Icons.push_pin
                                                            : Icons.push_pin_outlined,
                                                        size: 18,
                                                        color: ((note['is_pinned'] as int?) ?? 0) == 1
                                                            ? AppTheme.primaryPurple
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Delete button
                                                  InkWell(
                                                    onTap: () => _showDeleteDialog(
                                                      note['id'],
                                                      note['title'],
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.delete_outline_rounded,
                                                        size: 18,
                                                        color: Colors.red[400],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // Title
                                              Text(
                                                note['title'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2D3748),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              // Content preview
                                              Text(
                                                note['content'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 12),
                                              // Time
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 13,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    _formatDate(note['updated_at']),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
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
              builder: (context) => NoteEditorScreen(
                userId: widget.user['id'] as int,
              ),
            ),
          );
          if (result == true) {
            _loadNotes();
          }
        },
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Note',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? priority) {
    final isSelected = _selectedPriorityFilter == priority;
    final color = priority != null ? _priorityColors[priority]! : AppTheme.primaryPurple;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriorityFilter = priority;
          _filterNotes();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (priority != null)
              Icon(
                _priorityIcons[priority],
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
            if (priority != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
