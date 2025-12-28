import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists sidebar collapsed/expanded state across route navigation.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => true);
