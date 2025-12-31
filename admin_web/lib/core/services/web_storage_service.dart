import 'dart:html' as html;

/// Web-compatible storage service using localStorage
class WebStorageService {
  static const String _prefix = 'admin_';

  /// Write a value to localStorage
  Future<void> write({required String key, required String value}) async {
    try {
      html.window.localStorage['$_prefix$key'] = value;
    } catch (e) {
      print('⚠️ Error writing to localStorage: $e');
    }
  }

  /// Read a value from localStorage
  Future<String?> read({required String key}) async {
    try {
      return html.window.localStorage['$_prefix$key'];
    } catch (e) {
      print('⚠️ Error reading from localStorage: $e');
      return null;
    }
  }

  /// Delete a value from localStorage
  Future<void> delete({required String key}) async {
    try {
      html.window.localStorage.remove('$_prefix$key');
    } catch (e) {
      print('⚠️ Error deleting from localStorage: $e');
    }
  }

  /// Delete all values from localStorage
  Future<void> deleteAll() async {
    try {
      final keys = html.window.localStorage.keys.where((key) => key.startsWith(_prefix)).toList();
      for (final key in keys) {
        html.window.localStorage.remove(key);
      }
    } catch (e) {
      print('⚠️ Error clearing localStorage: $e');
    }
  }
}
