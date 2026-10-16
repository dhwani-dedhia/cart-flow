import 'package:equatable/equatable.dart';

/// Sealed class representing the result of an API operation.
sealed class ApiResult<T> extends Equatable {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => switch (this) {
        ApiSuccess<T>(data: final data) => data,
        ApiFailure<T>() => null,
      };

  String? get errorMessageOrNull => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(message: final msg) => msg,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode, dynamic error) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(data: final data) => success(data),
      ApiFailure<T>(
        message: final msg,
        statusCode: final code,
        error: final err
      ) =>
        failure(msg, code, err),
    };
  }

  @override
  List<Object?> get props => [];
}

/// Represents a successful API response.
class ApiSuccess<T> extends ApiResult<T> {
  final T data;

  const ApiSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

/// Represents an API failure (network error, timeout, HTTP error, parsing error).
class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final dynamic error;

  const ApiFailure({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  List<Object?> get props => [message, statusCode, error];
}
