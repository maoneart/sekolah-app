import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : dio = dio ?? Dio(),
        tokenStorage = tokenStorage ?? TokenStorage() {
    this.dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await this.tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final schoolId = await this.tokenStorage.getActiveSchoolId();
          if (schoolId != null && schoolId.isNotEmpty) {
            options.headers['X-School-Id'] = schoolId;
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Standardized error handling as specified in blueprint
          if (error.response?.statusCode == 401) {
            // Token revoked / expired - clear token
            this.tokenStorage.clear();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
