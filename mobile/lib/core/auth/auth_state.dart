import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'token_storage.dart';

class User {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final int? age;
  final String? address;
  final List<String> roles;
  final String? activeSchoolId;
  final String? activeSchoolName;
  final List<String> permissions;
  final List<Map<String, dynamic>> menus;
  final Map<String, dynamic>? dashboardConfig;
  final List<Map<String, dynamic>> children;
  final Map<String, dynamic>? student;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.gender,
    this.birthDate,
    this.age,
    this.address,
    required this.roles,
    this.activeSchoolId,
    this.activeSchoolName,
    this.permissions = const [],
    this.menus = const [],
    this.dashboardConfig,
    this.children = const [],
    this.student,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      birthDate: json['birth_date'],
      age: json['age'] is int ? json['age'] : (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
      address: json['address'],
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      activeSchoolId: json['active_school_id'],
      activeSchoolName: json['active_school_name'] ?? 'SD Negeri 1 Teladan',
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      menus: (json['menus'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      dashboardConfig: json['dashboard_config'] != null
          ? Map<String, dynamic>.from(json['dashboard_config'] as Map)
          : null,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      student: json['student'] != null
          ? Map<String, dynamic>.from(json['student'] as Map)
          : null,
    );
  }
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;

  AuthNotifier(this._tokenStorage, this._apiClient) : super(AuthState()) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    state = state.copyWith(isLoading: true);
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return;
    }

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      final userData = response.data['data'];
      final user = User.fromJson(userData);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      // In case of offline or invalid token
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Gagal memulihkan sesi.',
      );
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'login': identifier,
          'password': password,
          'device_name': 'Mobile App',
        },
      );

      final token = response.data['data']['token'];
      final userData = response.data['data']['user'];
      final user = User.fromJson(userData);

      await _tokenStorage.saveToken(token);
      if (user.activeSchoolId != null) {
        await _tokenStorage.saveActiveSchoolId(user.activeSchoolId!);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email/nomor telepon atau kata sandi salah.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await _tokenStorage.clear();
    state = AuthState();
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: storage);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(storage, api);
});
