import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiBaseUrlProvider = StateNotifierProvider<ApiBaseUrlNotifier, String>(
  (ref) => ApiBaseUrlNotifier(),
);

class ApiBaseUrlNotifier extends StateNotifier<String> {
  ApiBaseUrlNotifier() : super('http://localhost:8080') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('apiBaseUrl') ?? 'http://localhost:8080';
  }

  Future<void> updateBaseUrl(String value) async {
    final normalized = value.trim();
    state = normalized.isEmpty ? 'http://localhost:8080' : normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiBaseUrl', state);
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(apiBaseUrlProvider)),
);

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio;

  ApiClient(String host)
      : _dio = Dio(
          BaseOptions(
            baseUrl: '${host.trim().replaceAll(RegExp(r'/+$'), '')}/api/v1',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            responseType: ResponseType.json,
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response != null) {
          final status = e.response?.statusCode ?? 0;
          if (status == 404) {
            handler.reject(DioException(
              requestOptions: e.requestOptions,
              error: 'Coin not found or not tracked yet',
            ));
            return;
          }
          if (status == 429) {
            handler.reject(DioException(
              requestOptions: e.requestOptions,
              error: 'CoinGecko rate limit hit — please try again in 1 minute',
            ));
            return;
          }
          if (status >= 500) {
            handler.reject(DioException(
              requestOptions: e.requestOptions,
              error: 'Server error. Please try again later.',
            ));
            return;
          }
        }
        handler.next(e);
      },
    ));
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<T>(path, queryParameters: queryParameters);
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException(error.error?.toString() ?? 'Unknown network error');
    } catch (error) {
      throw ApiException(error.toString());
    }
  }

  Future<T> post<T>(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post<T>(path, data: data);
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException(error.error?.toString() ?? 'Unknown network error');
    } catch (error) {
      throw ApiException(error.toString());
    }
  }

  Future<T> delete<T>(String path) async {
    try {
      final response = await _dio.delete<T>(path);
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException(error.error?.toString() ?? 'Unknown network error');
    } catch (error) {
      throw ApiException(error.toString());
    }
  }
}
