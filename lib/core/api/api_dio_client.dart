import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'api_result.dart';

class ApiDioClient {
  late final Dio _dio;

  ApiDioClient({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          developer.log(
            '--> ${options.method.toUpperCase()} ${options.uri}',
            name: 'ApiDioClient',
          );
          if (options.data != null) {
            developer.log('Payload: ${options.data}', name: 'ApiDioClient');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '<-- ${response.statusCode} ${response.requestOptions.uri}',
            name: 'ApiDioClient',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          developer.log(
            '<-- ERROR ${error.type} for ${error.requestOptions.uri}: ${error.message}',
            name: 'ApiDioClient',
          );
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parser,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      final parsed = parser(response.data);
      return ApiSuccess<T>(parsed);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiFailure<T>(
        message: 'An unexpected error occurred: ${e.toString()}',
        error: e,
      );
    }
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parser,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      final parsed = parser(response.data);
      return ApiSuccess<T>(parsed);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiFailure<T>(
        message: 'An unexpected error occurred: ${e.toString()}',
        error: e,
      );
    }
  }

  ApiFailure<T> _handleDioError<T>(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiFailure<T>(
          message: 'Connection timed out. Please check your internet and try again.',
          error: e,
        );
      case DioExceptionType.connectionError:
        return ApiFailure<T>(
          message: 'No internet connection. Please verify your network.',
          error: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        String message = 'Server returned an error ($statusCode).';
        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }
        return ApiFailure<T>(
          message: message,
          statusCode: statusCode,
          error: e,
        );
      case DioExceptionType.cancel:
        return ApiFailure<T>(
          message: 'The request was cancelled.',
          error: e,
        );
      case DioExceptionType.badCertificate:
        return ApiFailure<T>(
          message: 'Security certificate verification failed.',
          error: e,
        );
      case DioExceptionType.unknown:
      default:
        return ApiFailure<T>(
          message: e.message ?? 'A network communication error occurred.',
          error: e,
        );
    }
  }
}
