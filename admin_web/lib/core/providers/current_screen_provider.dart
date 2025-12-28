import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track the current screen without full navigation
final currentScreenProvider = StateProvider<String>((ref) => '/dashboard');
