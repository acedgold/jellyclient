import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  String? accessToken;
  String? _deviceId;

  void setToken(String token) => accessToken = token;
  void setDeviceId(String id) => _deviceId = id;
  String get deviceId => _deviceId ?? 'jellyclient-unknown';
  void clear() {
    accessToken = null;
    _deviceId = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final parts = [
      'MediaBrowser Client="JellyClient"',
      'Device="Linux"',
      'DeviceId="${_deviceId ?? 'jellyclient-unknown'}"',
      'Version="0.1.0"',
    ];
    if (accessToken != null) parts.add('Token="$accessToken"');
    options.headers['X-Emby-Authorization'] = parts.join(', ');
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}
