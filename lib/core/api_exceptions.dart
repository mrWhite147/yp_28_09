import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override String toString() => message;
}

class NetworkException extends ApiException { const NetworkException([super.m = 'Сервер недоступен. Проверьте соединение.']); }
class UnauthorizedException extends ApiException { const UnauthorizedException([super.m = 'Требуется вход в систему.']); }
class ForbiddenException extends ApiException { const ForbiddenException([super.m = 'Недостаточно прав.']); }
class NotFoundException extends ApiException { const NotFoundException([super.m = 'Запись не найдена.']); }
class ConflictException extends ApiException { const ConflictException(super.m); }
class ServerException extends ApiException { const ServerException([super.m = 'Ошибка сервера.']); }

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

ApiException mapHttpError(int status, dynamic body) {
  final msg = (body is Map && body['message'] is String) ? body['message'] as String : null;
  return switch (status) {
    401 => UnauthorizedException(msg ?? 'Требуется вход.'),
    403 => ForbiddenException(msg ?? 'Недостаточно прав.'),
    404 => NotFoundException(msg ?? 'Не найдено.'),
    409 => ConflictException(msg ?? 'Конфликт данных.'),
    422 => ValidationException(
        msg ?? 'Ошибка валидации',
        (body is Map && body['errors'] is Map) ? (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v')) : const {},
      ),
    _ => ServerException(msg ?? 'Неизвестная ошибка ($status).'),
  };
}

ApiException mapDioError(DioException e) {
  if (e.error is ApiException) return e.error as ApiException;
  if (e.type == DioExceptionType.cancel) return const NetworkException('Запрос отменён.');
  if (e.type == DioExceptionType.connectionError) return const NetworkException('Не удалось соединиться. Возможно, ошибка CORS.');
  return const ServerException();
}

Future<T> guard<T>(Future<T> Function() action) async {
  try { return await action(); } 
  on DioException catch (e) { throw mapDioError(e); }
}