import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor for logging HTTP requests and responses
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌───────────────────────────────────────────────');
      print('│ REQUEST: ${options.method} ${options.uri}');
      print('│ Headers: ${options.headers}');
      if (options.data != null) {
        try {
          print('│ Body: ${jsonEncode(options.data)}');
        } catch (e) {
          print('│ Body: ${options.data}');
        }
      }
      if (options.queryParameters.isNotEmpty) {
        print('│ Query: ${options.queryParameters}');
      }
      print('└───────────────────────────────────────────────');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌───────────────────────────────────────────────');
      print('│ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      print('│ Body: ${response.data}');
      print('└───────────────────────────────────────────────');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌───────────────────────────────────────────────');
      print('│ ERROR: ${err.requestOptions.method} ${err.requestOptions.uri}');
      print('│ Status: ${err.response?.statusCode}');
      print('│ Message: ${err.message}');
      print('│ Response: ${err.response?.data}');
      print('└───────────────────────────────────────────────');
    }
    return handler.next(err);
  }
}
