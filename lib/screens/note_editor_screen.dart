import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? note;

  const NoteEditorScreen({
    super.key,
    required this.userId,
    this.note,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  String _selectedPriority = 'normal';
  List<Map<String, dynamic>> _images = [];
  List<String> _newImagePaths = [];
  final _imagePicker = ImagePicker();

  // Priority colors and labels
  final Map<String, Map<String, dynamic>> _priorities = {
    'high': {'label': 'High', 'color': const Color(0xFFEF5350), 'icon': Icons.priority_high},
    'medium': {'label': 'Medium', 'color': const Color(0xFFFF9800), 'icon': Icons.star},
    'normal': {'label': 'Normal', 'color': const Color(0xFF42A5F5), 'icon': Icons.circle},
    'low': {'label': 'Low', 'color': const Color(0xFF66BB6A), 'icon': Icons.arrow_downward},
  };

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _isEditing = true;
      _titleController.text = widget.note!['title'];
      _contentController.text = widget.note!['content'];
      _selectedPriority = widget.note!['priority'] ?? 'normal';
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    if (widget.note != null) {
      final images = await DatabaseHelper.instance.getNoteImages(
        widget.note!['id'] as int,
      );
      setState(() {
        _images = images;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newImagePaths.add(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteExistingImage(int imageId, int index) async {
    final result = await DatabaseHelper.instance.deleteNoteImage(imageId);
    
    if (result['success'] && mounted) {
      setState(() {
        _images.removeAt(index);
      });
    }
  }

  void _deleteNewImage(int index) {
    setState(() {
      _newImagePaths.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    int noteId;

    if (_isEditing) {
      noteId = widget.note!['id'];
      result = await DatabaseHelper.instance.updateNote(
        noteId: noteId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        priority: _selectedPriority,
      );
    } else {
      result = await DatabaseHelper.instance.createNote(
        userId: widget.userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        priority: _selectedPriority,
      );
      if (result['success']) {
        noteId = result['noteId'] as int;
      } else {
        noteId = 0; // Won't be used if result is not success
      }
    }

    // Save new images if note was saved successfully
    if (result['success'] && noteId > 0 && _newImagePaths.isNotEmpty) {
      for (final imagePath in _newImagePaths) {
        await DatabaseHelper.instance.addNoteImage(noteId, imagePath);
      }
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Colored header background
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.lightPurple,
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Colors.white,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _isEditing ? 'Edit Note' : 'Create Note',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Main content card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title input
                                  TextFormField(
                                    controller: _titleController,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Title',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter a title';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Priority selector with chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _priorities.entries.map((entry) {
                                      final isSelected = _selectedPriority == entry.key;
                                      final priority = entry.value;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedPriority = entry.key;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? priority['color']
                                                : priority['color'].withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                priority['icon'],
                                                size: 16,
                                                color: isSelected
                                                    ? Colors.white
                                                    : priority['color'],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                priority['label'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : priority['color'],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Divider
                                  Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightPurple.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Content input
                                  TextFormField(
                                    controller: _contentController,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: Colors.grey[800],
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Start writing...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter some content';
                                      }
                                      return null;
                                    },
                                    maxLines: null,
                                    minLines: 12,
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Images section
                                  Row(
                                    children: [
                                      const Text(
                                        'Attachments',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        onPressed: _pickImage,
                                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                                        label: const Text('Add Image'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Display existing images
                                  if (_images.isNotEmpty) ...[
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemCount: _images.length,
                                      itemBuilder: (context, index) {
                                        final image = _images[index];
                                        final imagePath = image['image_path'] as String;
                                        
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                File(imagePath),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _deleteExistingImage(
                                                  image['id'] as int,
                                                  index,
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  
                                  // Display new images
                                  if (_newImagePaths.isNotEmpty) ...[
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemCount: _newImagePaths.length,
                                      itemBuilder: (context, index) {
                                        final imagePath = _newImagePaths[index];
                                        
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                File(imagePath),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _deleteNewImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  
                                  // Date info
                                  if (_isEditing && widget.note != null) ...[
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightPurple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 16,
                                            color: AppTheme.primaryPurple,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDateTime(widget.note!['updated_at']),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryPurple,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating save button
          Positioned(
            bottom: 24,
            right: 24,
            child: _isLoading
                ? Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _saveNote,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryPurple,
                            AppTheme.lightPurple,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
