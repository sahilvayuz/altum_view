import 'dart:developer';
import 'package:altum_view/core/constants/api_constants.dart';
import 'package:altum_view/core/errors/app_exception.dart';
import 'package:dio/dio.dart';

class DioClient {
  late final Dio _dio;

  DioClient({required String accessToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      _AuthInterceptor(accessToken),
      _LogInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  void updateToken(String token) =>
      _dio.interceptors.whereType<_AuthInterceptor>().firstOrNull?.updateToken(token);
}

// ── Interceptors ──────────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  String _token;
  _AuthInterceptor(this._token);
  void updateToken(String t) => _token = t;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    o.headers['Authorization'] = 'Bearer $_token';
    h.next(o);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    log('➡️  [${o.method}] ${o.uri}');
    h.next(o);
  }

  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    log('✅  [${r.statusCode}] ${r.requestOptions.uri}');
    h.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    log('❌  [${e.response?.statusCode}] ${e.requestOptions.uri}');
    h.next(e);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ex = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout   ||
      DioExceptionType.sendTimeout      => const NetworkException('Connection timed out.'),
      DioExceptionType.connectionError  => const NetworkException('No internet connection.'),
      DioExceptionType.badResponse      => _fromStatus(err),
      _                                 => ApiException('Unexpected error: ${err.message}'),
    };
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: ex,
      response: err.response,
      type: err.type,
    ));
  }

  AppException _fromStatus(DioException err) {
    final code = err.response?.statusCode ?? 0;
    final msg  = (err.response?.data is Map)
        ? err.response?.data['message'] as String?
        : null;
    return switch (code) {
      400 => BadRequestException(msg ?? 'Bad request'),
      401 || 403 => UnauthorizedException(msg ?? 'Unauthorised'),
      404 => NotFoundException(msg ?? 'Not found'),
      >= 500 => ServerException(msg ?? 'Server error'),
      _ => ApiException(msg ?? 'HTTP $code'),
    };
  }
}
