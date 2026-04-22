sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

class ApiException        extends AppException { const ApiException(super.m); }
class BadRequestException extends AppException { const BadRequestException(super.m); }
class UnauthorizedException extends AppException { const UnauthorizedException(super.m); }
class NotFoundException   extends AppException { const NotFoundException(super.m); }
class ServerException     extends AppException { const ServerException(super.m); }
class NetworkException    extends AppException { const NetworkException(super.m); }
class BleException        extends AppException { const BleException(super.m); }
class ParseException      extends AppException { const ParseException(super.m); }
