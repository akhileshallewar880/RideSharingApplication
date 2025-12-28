import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A mixin that provides dynamic status bar color matching functionality.
/// This mixin automatically adjusts the status bar color to match the app bar color.
///
/// Usage:
/// 1. Add `with DynamicStatusBarMixin` to your State class
/// 2. Call `updateStatusBar(context)` in initState() or when the app bar color changes
///
/// Example:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with DynamicStatusBarMixin {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       updateStatusBar(context);
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         backgroundColor: Colors.blue,
///         // Your app bar content
///       ),
///       body: // Your body content
///     );
///   }
/// }
/// ```
mixin DynamicStatusBarMixin<T extends StatefulWidget> on State<T> {
  /// Updates the status bar color to match the current app bar color
  void updateStatusBar(BuildContext context) {
    // Get the current AppBar from the Scaffold
    final scaffoldContext = context.findAncestorWidgetOfExactType<Scaffold>();
    
    if (scaffoldContext == null) {
      return;
    }

    // Try to extract app bar color from the widget tree
    Color? appBarColor = _extractAppBarColor(context);
    
    if (appBarColor != null) {
      _setStatusBarColor(appBarColor);
    }
  }

  /// Updates the status bar with a specific color
  void updateStatusBarWithColor(Color color) {
    _setStatusBarColor(color);
  }

  /// Extract app bar color from the widget tree
  Color? _extractAppBarColor(BuildContext context) {
    // Try to find AppBar in the widget tree
    try {
      // Access app bar color from theme
      return Theme.of(context).appBarTheme.backgroundColor ??
             Theme.of(context).primaryColor;
    } catch (e) {
      // If we can't find the theme, return null
      return null;
    }
  }

  /// Set the status bar color and determine icon brightness
  void _setStatusBarColor(Color statusBarColor) {
    // Determine if the color is light or dark
    final brightness = _getColorBrightness(statusBarColor);
    final iconBrightness = brightness == Brightness.light 
        ? Brightness.dark 
        : Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: brightness,
      ),
    );
  }

  /// Calculate the brightness of a color
  Brightness _getColorBrightness(Color color) {
    // Calculate relative luminance
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }

  @override
  void dispose() {
    // Reset to default when leaving the screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }
}

/// A wrapper widget that automatically applies status bar color based on app bar color
///
/// This widget wraps your screen and automatically sets the status bar color
/// to match the AppBar backgroundColor.
///
/// Usage:
/// ```dart
/// return DynamicStatusBarWrapper(
///   statusBarColor: Colors.blue, // Optional: specify color manually
///   child: Scaffold(
///     appBar: AppBar(
///       backgroundColor: Colors.blue,
///       // ...
///     ),
///     body: // Your content
///   ),
/// );
/// ```
class DynamicStatusBarWrapper extends StatefulWidget {
  final Widget child;
  final Color? statusBarColor;

  const DynamicStatusBarWrapper({
    Key? key,
    required this.child,
    this.statusBarColor,
  }) : super(key: key);

  @override
  State<DynamicStatusBarWrapper> createState() => _DynamicStatusBarWrapperState();
}

class _DynamicStatusBarWrapperState extends State<DynamicStatusBarWrapper> {
  @override
  void initState() {
    super.initState();
    _updateStatusBar();
  }

  @override
  void didUpdateWidget(DynamicStatusBarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusBarColor != widget.statusBarColor) {
      _updateStatusBar();
    }
  }

  void _updateStatusBar() {
    if (widget.statusBarColor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setStatusBarColor(widget.statusBarColor!);
      });
    }
  }

  void _setStatusBarColor(Color statusBarColor) {
    // Determine if the color is light or dark
    final brightness = _getColorBrightness(statusBarColor);
    final iconBrightness = brightness == Brightness.light 
        ? Brightness.dark 
        : Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: brightness,
      ),
    );
  }

  Brightness _getColorBrightness(Color color) {
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }
}
