import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'api_exceptions.dart';
import '../state/auth_notifier.dart';

Dio buildDio({required AuthNotifier Function() getAuth}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (opts, handler) {
        final token = getAuth().accessToken;
        if (token != null) {
          opts.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) debugPrint('[API REQ] ${opts.method} ${opts.uri}');
        return handler.next(opts);
      },
      onResponse: (res, handler) {
        if (kDebugMode) {
          debugPrint('[API RES] ${res.statusCode} ${res.requestOptions.uri}');
        }
        final status = res.statusCode ?? 0;

        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: res.requestOptions,
              response: res,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, res.data),
            ),
            true,
          );
        }
        return handler.next(res);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401 &&
            !err.requestOptions.path.contains('/auth/')) {
          try {
            final auth = getAuth();
            final prefs = await SharedPreferences.getInstance();
            final refresh = prefs.getString('refresh_token');

            if (refresh != null) {
              await auth.refreshTokens(refresh);

              err.requestOptions.headers['Authorization'] =
                  'Bearer ${auth.accessToken}';
              final cloneReq = await dio.fetch(err.requestOptions);
              return handler.resolve(cloneReq);
            } else {
              await auth.logout();
            }
          } catch (_) {
            await getAuth().logout();
          }
        }
        return handler.next(err);
      },
    ),
  );
  return dio;
}
