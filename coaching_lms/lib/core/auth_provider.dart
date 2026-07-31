import 'package:flutter/material.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'session.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = true;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  /// Call once at app startup to restore a saved session.
  Future<void> restoreSession() async {
    _loading = true;
    notifyListeners();
    final savedUser = await Session.getUser();
    final token = await Session.getToken();
    _user = (token != null) ? savedUser : null;
    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiService.post('auth/login.php', {
      'email': email,
      'password': password,
    });
    if (res['success'] == true) {
      final newUser = AppUser.fromJson(res['user']);
      await Session.save(res['token'], newUser);
      _user = newUser;
      notifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final res = await ApiService.post('auth/signup.php', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });
    if (res['success'] == true && res['token'] != null) {
      final newUser = AppUser.fromJson(res['user']);
      await Session.save(res['token'], newUser);
      _user = newUser;
      notifyListeners();
    }
    return res;
  }

  Future<void> logout() async {
    await Session.clear();
    _user = null;
    notifyListeners();
  }
}
