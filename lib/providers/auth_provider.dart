import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool loading;
  final String? error;

  const AuthState({this.token, this.user, this.loading = false, this.error});

  bool get isLoggedIn => token != null;
  AuthState copyWith({String? token, Map<String, dynamic>? user, bool? loading, String? error}) =>
      AuthState(
        token: token ?? this.token,
        user: user ?? this.user,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await http.post(
        Uri.parse('$kApiBase/accounts/mobile/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        // Persist token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('auth_email', user['email'] as String? ?? '');
        // Update global token so GraphQL client rebuilds with auth header
        _ref.read(authTokenProvider.notifier).state = token;
        state = state.copyWith(token: token, user: user, loading: false);
        return true;
      } else {
        final data = jsonDecode(resp.body);
        state = state.copyWith(loading: false, error: data['error'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Connection error');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_email');
    _ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState();
  }

  void restoreFromToken(String token, {Map<String, dynamic>? user}) {
    _ref.read(authTokenProvider.notifier).state = token;
    state = state.copyWith(token: token, user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
