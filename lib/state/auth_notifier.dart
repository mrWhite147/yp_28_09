import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

enum Role {
  customer(1),
  manager(2),
  admin(3);

  const Role(this.level);
  final int level;
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final Role role;
  AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'],
    username: j['username'],
    fullName: j['fullName'],
    role: Role.values.firstWhere(
      (e) => e.name == j['role'],
      orElse: () => Role.customer,
    ),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'role': role.name,
  };
}

class AuthNotifier extends ChangeNotifier {
  final SharedPreferences _prefs;
  final Dio _dio;

  AppUser? _user;
  String? _accessToken;
  DateTime? _loginTime;

  AuthNotifier(this._prefs, this._dio);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  bool hasRole(Role requiredRole) =>
      _user != null && _user!.role.level >= requiredRole.level;

  Future<void> restore() async {
    final access = _prefs.getString('access_token');
    final refresh = _prefs.getString('refresh_token');
    final userJson = _prefs.getString('user');
    final loginIso = _prefs.getString('login_time');

    if (access == null || userJson == null || loginIso == null) return;

    _loginTime = DateTime.parse(loginIso);
    if (DateTime.now().difference(_loginTime!).inHours >= 24) {
      await logout();
      return;
    }

    _accessToken = access;
    _user = AppUser.fromJson(jsonDecode(userJson));

    try {
      await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        if (refresh != null) {
          await refreshTokens(refresh);
        } else {
          await logout();
        }
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    _saveSession(res.data);
  }

  Future<void> register(
    String username,
    String password,
    String fullName,
  ) async {
    await _dio.post(
      '/auth/register',
      data: {'username': username, 'password': password, 'fullName': fullName},
    );
    await login(username, password);
  }

  Future<void> refreshTokens(String refreshToken) async {
    try {
      final res = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      _saveSession(res.data);
    } catch (_) {
      await logout();
      throw Exception('Session expired');
    }
  }

  void _saveSession(Map<String, dynamic> data) {
    _accessToken = data['accessToken'];
    _user = AppUser.fromJson(data['user']);
    _loginTime = DateTime.now();

    _prefs.setString('access_token', _accessToken!);
    _prefs.setString('refresh_token', data['refreshToken']);
    _prefs.setString('user', jsonEncode(_user!.toJson()));
    _prefs.setString('login_time', _loginTime!.toIso8601String());
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      final refresh = _prefs.getString('refresh_token');
      if (refresh != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refresh});
      }
    } catch (_) {}

    _user = null;
    _accessToken = null;
    _loginTime = null;
    _prefs.remove('access_token');
    _prefs.remove('refresh_token');
    _prefs.remove('user');
    _prefs.remove('login_time');
    notifyListeners();
  }
}
