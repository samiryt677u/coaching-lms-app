import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'session.dart';
import 'navigation.dart';

/// Thin wrapper around http calls to the PHP API.
/// Always resolves to a Map (never throws) so screens can just check res['success'].
/// On network failure or bad JSON, returns {'success': false, 'message': ...}.
class ApiService {
  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _request('GET', path, query: query);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _request('POST', path, body: body);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) {
    return _request('PUT', path, body: body);
  }

  static Future<Map<String, dynamic>> delete(String path, Map<String, dynamic> body) {
    return _request('DELETE', path, body: body);
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    Uri uri = Uri.parse('${ApiConfig.baseUrl}/$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final token = await Session.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      http.Response res;
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          res = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 20));
          break;
        case 'PUT':
          res = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 20));
          break;
        case 'DELETE':
          res = await http
              .delete(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 20));
          break;
        default:
          return {'success': false, 'message': 'Unsupported method'};
      }
      return _handleResponse(res);
    } on SocketException {
      return {'success': false, 'message': 'No internet connection. Please check your network.'};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong. Please try again.'};
    }
  }

  /// Multipart upload — used by study material upload.
  static Future<Map<String, dynamic>> upload(
    String path, {
    required Map<String, String> fields,
    required String filePath,
    required String fileFieldName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$path');
    final token = await Session.getToken();

    try {
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(fileFieldName, filePath));

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return _handleResponse(res);
    } on SocketException {
      return {'success': false, 'message': 'No internet connection. Please check your network.'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed. Please try again.'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response res) {
    if (res.statusCode == 401) {
      Session.clear();
      // Redirect to login without needing a BuildContext at the call site.
      Future.microtask(() {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return {'success': false, 'message': 'Session expired. Please log in again.'};
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected server response'};
    } catch (_) {
      return {'success': false, 'message': 'Unexpected server response (status ${res.statusCode})'};
    }
  }
}
