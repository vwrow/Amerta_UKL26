import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_session.dart';

class UserSessionService {
  static const _accountsKey = 'registered_accounts';
  static const _currentSessionKey = 'current_user_session';

  Future<void> saveRegisteredAccount({
    required String username,
    required String password,
    required String name,
    required String userId,
    required String phone,
    required String role,
    required String createdAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);

    final normalizedUsername = username.trim().toLowerCase();
    accounts.removeWhere(
      (account) =>
          account['username']?.toString().trim().toLowerCase() ==
          normalizedUsername,
    );

    accounts.add({
      'username': username.trim(),
      'password': password,
      'name': name,
      'user_id': userId,
      'phone': phone,
      'role': role,
      'createdAt': createdAt,
    });

    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<String?> getStoredPassword(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final normalizedUsername = username.trim().toLowerCase();

    for (final account in accounts) {
      final storedUsername =
          account['username']?.toString().trim().toLowerCase();
      if (storedUsername == normalizedUsername) {
        return account['password']?.toString();
      }
    }

    return null;
  }

  Future<UserSession?> findRegisteredAccount(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final normalizedUsername = username.trim().toLowerCase();

    for (final account in accounts) {
      final storedUsername =
          account['username']?.toString().trim().toLowerCase();

      if (storedUsername == normalizedUsername) {
        return UserSession.fromStoredAccount(account);
      }
    }

    return null;
  }

  Future<void> saveCurrentSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, jsonEncode(session.toJson()));
  }

  Future<UserSession?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentSessionKey);
    if (raw == null || raw.isEmpty) return null;

    return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
  }

  Future<List<Map<String, dynamic>>> _loadAccounts(SharedPreferences prefs) async {
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
