import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Notes App';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'users.db';
  static const int databaseVersion = 5;

  // Validation
  static const int minNameLength = 2;
  static const int minPasswordLength = 6;
  static const int maxImageDimension = 1920;
  static const int imageQuality = 85;
  static const int profileImageSize = 512;
  static const int profileImageQuality = 90;

  // UI
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const int noteContentPreviewLines = 3;
  static const int editorMinLines = 12;

  // Error Messages
  static const String emailAlreadyExists = 'Email already registered';
  static const String invalidCredentials = 'Invalid email or password';
  static const String registrationFailed = 'Registration failed';
  static const String loginFailed = 'Login failed';
  static const String noteNotFound = 'Note not found';
  static const String userNotFound = 'User not found';
  static const String incorrectPassword = 'Current password is incorrect';
  
  // Success Messages
  static const String registrationSuccess = 'Registration successful';
  static const String loginSuccess = 'Login successful';
  static const String noteCreated = 'Note created successfully';
  static const String noteUpdated = 'Note updated successfully';
  static const String noteDeleted = 'Note deleted successfully';
  static const String notePinned = 'Note pinned';
  static const String noteUnpinned = 'Note unpinned';
  static const String nameUpdated = 'Name updated successfully';
  static const String passwordUpdated = 'Password updated successfully';
  static const String profilePictureUpdated = 'Profile picture updated';
  
  // Form Labels
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String nameLabel = 'Name';
  static const String titleLabel = 'Title';
  static const String contentLabel = 'Content';
  static const String currentPasswordLabel = 'Current Password';
  static const String newPasswordLabel = 'New Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  
  // Hints
  static const String emailHint = 'Enter your email';
  static const String passwordHint = 'Enter your password';
  static const String nameHint = 'Enter your name';
  static const String titleHint = 'Title';
  static const String contentHint = 'Start writing...';
  
  // Buttons
  static const String signInButton = 'Sign In';
  static const String signUpButton = 'Sign Up';
  static const String saveButton = 'Save';
  static const String cancelButton = 'Cancel';
  static const String deleteButton = 'Delete';
  static const String updateButton = 'Update';
  static const String logoutButton = 'Logout';
  
  // Priorities
  static const List<String> priorities = ['high', 'medium', 'normal', 'low'];
  
  // Routes
  static const String splashRoute = '/';
  static const String signInRoute = '/signin';
  static const String signUpRoute = '/signup';
  static const String notesRoute = '/notes';
  static const String noteDetailRoute = '/note-detail';
  static const String noteEditorRoute = '/note-editor';
  static const String profileRoute = '/profile';
}

class PriorityConfig {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const PriorityConfig({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  static const high = PriorityConfig(
    value: 'high',
    label: 'High',
    color: Color(0xFFEF5350),
    icon: Icons.priority_high,
  );

  static const medium = PriorityConfig(
    value: 'medium',
    label: 'Medium',
    color: Color(0xFFFF9800),
    icon: Icons.star,
  );

  static const normal = PriorityConfig(
    value: 'normal',
    label: 'Normal',
    color: Color(0xFF42A5F5),
    icon: Icons.circle,
  );

  static const low = PriorityConfig(
    value: 'low',
    label: 'Low',
    color: Color(0xFF66BB6A),
    icon: Icons.arrow_downward,
  );

  static const Map<String, PriorityConfig> all = {
    'high': high,
    'medium': medium,
    'normal': normal,
    'low': low,
  };

  static PriorityConfig fromString(String value) {
    return all[value] ?? normal;
  }
}
