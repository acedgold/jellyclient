import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';
import 'models/jellyfin_models.dart';

class JellyfinClient {
  final Dio _dio;
  final AuthInterceptor _authInterceptor;
  String _baseUrl;

  JellyfinClient({required String baseUrl})
      : _baseUrl = baseUrl,
        _authInterceptor = AuthInterceptor(),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(_authInterceptor);
  }

  void setBaseUrl(String url) => _baseUrl = url;
  void setToken(String token) => _authInterceptor.setToken(token);
  void setDeviceId(String id) => _authInterceptor.setDeviceId(id);
  void clearAuth() => _authInterceptor.clear();

  // ─── Auth ────────────────────────────────────────────────────────────────

  Future<AuthResult> authenticate({
    required String username,
    required String password,
  }) async {
    final resp = await _dio.post(
      '$_baseUrl/Users/AuthenticateByName',
      data: {'Username': username, 'Pw': password},
    );
    final data = resp.data as Map<String, dynamic>;
    final user = data['User'] as Map<String, dynamic>;
    return AuthResult(
      userId: user['Id'] as String,
      accessToken: data['AccessToken'] as String,
      serverId: data['ServerId'] as String,
      serverName: (data['ServerName'] as String?) ?? _baseUrl,
      username: user['Name'] as String,
    );
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    final resp = await _dio.get('$_baseUrl/System/Info');
    return resp.data as Map<String, dynamic>;
  }

  // ─── Library Views ───────────────────────────────────────────────────────

  Future<List<LibraryView>> getLibraryViews(String userId) async {
    final resp = await _dio.get('$_baseUrl/Users/$userId/Views');
    final data = resp.data as Map<String, dynamic>;
    final items = data['Items'] as List<dynamic>;
    return items
        .map((e) => LibraryView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Items ───────────────────────────────────────────────────────────────

  Future<ItemsResponse> getItems({
    required String userId,
    String? parentId,
    String? includeItemTypes,
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? startIndex,
    String? searchTerm,
    String? fields,
    bool? recursive,
    String? genres,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/Users/$userId/Items',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        if (includeItemTypes != null) 'IncludeItemTypes': includeItemTypes,
        if (sortBy != null) 'SortBy': sortBy,
        if (sortOrder != null) 'SortOrder': sortOrder,
        if (limit != null) 'Limit': limit,
        if (startIndex != null) 'StartIndex': startIndex,
        if (searchTerm != null) 'SearchTerm': searchTerm,
        if (recursive != null) 'Recursive': recursive,
        if (genres != null) 'Genres': genres,
        'Fields': fields ?? 'Overview,Genres,MediaStreams,UserData',
      },
    );
    final data = resp.data as Map<String, dynamic>;
    final rawItems = (data['Items'] as List<dynamic>?) ?? const [];
    final items = rawItems
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ItemsResponse(
      items: items,
      totalRecordCount: (data['TotalRecordCount'] as num?)?.toInt() ?? items.length,
      startIndex: (data['StartIndex'] as num?)?.toInt(),
    );
  }

  Future<JellyItem> getItem(String userId, String itemId) async {
    final resp = await _dio.get(
      '$_baseUrl/Users/$userId/Items/$itemId',
      queryParameters: {
        'Fields': 'Overview,Genres,MediaStreams,UserData,ProviderIds,OfficialRating,Status,People,Taglines,Chapters',
      },
    );
    return JellyItem.fromJson(resp.data as Map<String, dynamic>);
  }

  // ─── Resume / Latest ─────────────────────────────────────────────────────

  Future<List<JellyItem>> getResume(String userId) async {
    final resp = await _dio.get(
      '$_baseUrl/Users/$userId/Items/Resume',
      queryParameters: {
        'Limit': 12,
        'Fields': 'Overview,UserData,MediaStreams',
      },
    );
    final data = resp.data as Map<String, dynamic>;
    return (data['Items'] as List<dynamic>)
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<JellyItem>> getLatest(String userId, {String? parentId}) async {
    final resp = await _dio.get(
      '$_baseUrl/Users/$userId/Items/Latest',
      queryParameters: {
        'Limit': 16,
        if (parentId != null) 'ParentId': parentId,
        'Fields': 'Overview,UserData,MediaStreams',
      },
    );
    return (resp.data as List<dynamic>)
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Séries / Saisons / Épisodes ─────────────────────────────────────────

  Future<List<String>> getGlobalGenres(String userId) async {
    final resp = await _dio.get(
      '$_baseUrl/Genres',
      queryParameters: {
        'UserId': userId,
        'SortBy': 'SortName',
        'Limit': 20,
        'IncludeItemTypes': 'Movie,Series',
      },
    );
    final data = resp.data as Map<String, dynamic>;
    return (data['Items'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['Name'] as String)
        .toList();
  }

  Future<List<String>> getGenres(String userId, String parentId) async {
    final resp = await _dio.get(
      '$_baseUrl/Genres',
      queryParameters: {
        'ParentId': parentId,
        'UserId': userId,
        'SortBy': 'SortName',
        'Limit': 50,
      },
    );
    final data = resp.data as Map<String, dynamic>;
    return (data['Items'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['Name'] as String)
        .toList();
  }

  Future<List<JellyItem>> searchPersons(String query) async {
    final resp = await _dio.get(
      '$_baseUrl/Persons',
      queryParameters: {
        'searchTerm': query,
        'Limit': 20,
        'Fields': 'PrimaryImageAspectRatio',
      },
    );
    final data = resp.data as Map<String, dynamic>;
    return (data['Items'] as List<dynamic>)
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ItemsResponse> getPersonItems(String userId, String personId) async {
    final resp = await _dio.get(
      '$_baseUrl/Users/$userId/Items',
      queryParameters: {
        'PersonIds': personId,
        'Recursive': true,
        // Exclure les épisodes — afficher uniquement Film et Série parente
        'IncludeItemTypes': 'Movie,Series',
        'SortBy': 'ProductionYear',
        'SortOrder': 'Descending',
        'Fields': 'Overview,UserData',
        'Limit': 150,
      },
    );
    final data = resp.data as Map<String, dynamic>;
    final items = (data['Items'] as List<dynamic>)
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ItemsResponse(items: items, totalRecordCount: data['TotalRecordCount'] as int);
  }

  Future<List<JellyItem>> getSeasons(String userId, String seriesId) async {
    final resp = await _dio.get(
      '$_baseUrl/Shows/$seriesId/Seasons',
      queryParameters: {
        'UserId': userId,
        'Fields': 'Overview,UserData',
        'SortBy': 'IndexNumber',
        'SortOrder': 'Ascending',
      },
    );
    final data = resp.data as Map<String, dynamic>;
    return (data['Items'] as List<dynamic>)
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<JellyItem>> getEpisodes(String userId, String seasonId) async {
    final resp = await _dio.get(
      '$_baseUrl/Users/$userId/Items',
      queryParameters: {
        'ParentId': seasonId,
        'IncludeItemTypes': 'Episode',
        'SortBy': 'IndexNumber',
        'SortOrder': 'Ascending',
        'Fields': 'Overview,UserData,MediaStreams',
        'Recursive': false,
      },
    );
    final data = resp.data as Map<String, dynamic>;
    return (data['Items'] as List<dynamic>)
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Playback ────────────────────────────────────────────────────────────

  String getStreamUrl({
    required String itemId,
    required String userId,
    bool directPlay = true,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) {
    final token = _authInterceptor.accessToken ?? '';
    final audioParam = audioStreamIndex != null ? '&AudioStreamIndex=$audioStreamIndex' : '';
    final subParam = subtitleStreamIndex != null ? '&SubtitleStreamIndex=$subtitleStreamIndex' : '';

    if (directPlay) {
      return '$_baseUrl/Videos/$itemId/stream'
          '?Static=true'
          '&MediaSourceId=$itemId'
          '&DeviceId=${_authInterceptor.deviceId}'
          '&api_key=$token'
          '$audioParam'
          '$subParam';
    }
    // Transcoding fallback
    return '$_baseUrl/Videos/$itemId/stream'
        '?MediaSourceId=$itemId'
        '&DeviceId=${_authInterceptor.deviceId}'
        '&VideoCodec=h264'
        '&AudioCodec=aac'
        '&MaxWidth=1920'
        '&api_key=$token'
        '$audioParam'
        '$subParam';
  }

  String getImageUrl({required String itemId, String type = 'Primary', int maxWidth = 200}) =>
      '$_baseUrl/Items/$itemId/Images/$type?maxWidth=$maxWidth&quality=80';

  Future<void> reportPlaybackProgress({
    required String userId,
    required String itemId,
    required int positionTicks,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/Sessions/Playing/Progress',
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
          'IsPaused': false,
        },
      );
    } catch (_) {}
  }

  Future<void> reportPlaybackStop({
    required String itemId,
    required int positionTicks,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/Sessions/Playing/Stopped',
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
        },
      );
    } catch (_) {}
  }

  Future<void> markPlayed(String userId, String itemId) async {
    await _dio.post('$_baseUrl/Users/$userId/PlayedItems/$itemId');
  }

  Future<void> markUnplayed(String userId, String itemId) async {
    await _dio.delete('$_baseUrl/Users/$userId/PlayedItems/$itemId');
  }

  /// Utilisateurs publics du serveur (visibles sur l'écran de connexion).
  /// Aucun token requis — appelé avant authentification.
  Future<List<Map<String, dynamic>>> getPublicUsers() async {
    const timeout = Duration(seconds: 8);
    final resp = await _dio.get('$_baseUrl/Users/Public',
        options: Options(sendTimeout: timeout, receiveTimeout: timeout));
    return (resp.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getServerUsers() async {
    const timeout = Duration(seconds: 5);
    try {
      final resp = await _dio.get('$_baseUrl/Users',
          options: Options(sendTimeout: timeout, receiveTimeout: timeout));
      return (resp.data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      try {
        final resp = await _dio.get('$_baseUrl/Users/Public',
            options: Options(sendTimeout: timeout, receiveTimeout: timeout));
        return (resp.data as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (_) {
        return [];
      }
    }
  }

  Future<JellyItem?> getNextUp(String userId, {String? seriesId}) async {
    final resp = await _dio.get(
      '$_baseUrl/Shows/NextUp',
      queryParameters: {
        'UserId': userId,
        if (seriesId != null) 'SeriesId': seriesId,
        'Fields': 'Overview,UserData,MediaStreams',
        'Limit': 1,
      },
    );
    final data = resp.data as Map<String, dynamic>;
    final items = (data['Items'] as List<dynamic>)
        .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return items.isEmpty ? null : items.first;
  }

  // Endpoint plugin IntroSkipper — retourne null si plugin absent ou épisode sans données
  Future<(double start, double end)?> getIntroTimestamps(String episodeId) async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/Episode/$episodeId/IntroTimestamps',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = resp.data as Map<String, dynamic>;
      final start = (data['IntroStart'] as num?)?.toDouble();
      final end = (data['IntroEnd'] as num?)?.toDouble();
      if (start != null && end != null) return (start, end);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshItem(String itemId) async {
    await _dio.post(
      '$_baseUrl/Items/$itemId/Refresh',
      queryParameters: {
        'MetadataRefreshMode': 'FullRefresh',
        'ImageRefreshMode': 'FullRefresh',
        'ReplaceAllMetadata': false,
        'ReplaceAllImages': false,
      },
    );
  }

  Future<void> toggleFavorite({
    required String userId,
    required String itemId,
    required bool favorite,
  }) async {
    if (favorite) {
      await _dio.post('$_baseUrl/Users/$userId/FavoriteItems/$itemId');
    } else {
      await _dio.delete('$_baseUrl/Users/$userId/FavoriteItems/$itemId');
    }
  }

  // ─── Streams du 1er épisode d'une série (pour badge audio) ───────────────

  Future<List<MediaStream>> getFirstEpisodeStreams(String userId, String seriesId) async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/Shows/$seriesId/Episodes',
        queryParameters: {
          'UserId': userId,
          'SeasonNumber': 1,
          'Fields': 'MediaStreams',
          'Limit': 1,
        },
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = resp.data as Map<String, dynamic>;
      final items = (data['Items'] as List<dynamic>)
          .map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return items.isEmpty ? [] : (items.first.mediaStreams ?? []);
    } catch (_) {
      return [];
    }
  }

  // ─── Sessions actives ─────────────────────────────────────────────────────

  /// L'utilisateur courant est-il administrateur ? (Policy.IsAdministrator)
  Future<bool> isCurrentUserAdmin() async {
    try {
      final resp = await _dio.get('$_baseUrl/Users/Me',
          options: Options(receiveTimeout: const Duration(seconds: 8)));
      final data = resp.data as Map<String, dynamic>;
      final policy = data['Policy'] as Map<String, dynamic>?;
      return policy?['IsAdministrator'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<JellySession>> getSessions() async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/Sessions',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return (resp.data as List<dynamic>)
          .map((e) => JellySession.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isPlaying)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Test de connexion + débit ─────────────────────────────────────────────

  static Future<bool> pingServer(String url) async {
    final r = await testServer(url, '');
    return r.ok;
  }

  /// Teste la connectivité et mesure le débit en MB/s.
  /// [token] : accessToken du serveur (permet d'accéder à /Items pour un test plus représentatif).
  static Future<({bool ok, double? speedMBps})> testServer(
      String url, String token) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // ── 1. Vérification de connectivité ──
    try {
      await dio.get('$url/System/Ping',
          options: Options(receiveTimeout: const Duration(seconds: 5)));
    } catch (_) {
      return (ok: false, speedMBps: null);
    }

    // ── 2. Mesure de débit ──
    double? speedMBps;
    try {
      final headers = token.isNotEmpty
          ? {
              'Authorization':
                  'MediaBrowser Client="JellyClient", Device="SpeedTest",'
                  ' DeviceId="speedtest-01", Version="1.0", Token="$token"'
            }
          : null;

      final sw = Stopwatch()..start();
      final resp = await dio.get(
        '$url/Items',
        queryParameters: {
          'Limit': 200,
          'Recursive': true,
          'IncludeItemTypes': 'Movie,Series',
          'Fields': 'Overview',
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          receiveTimeout: const Duration(seconds: 12),
        ),
      );
      sw.stop();
      final bytes = (resp.data as List<int>).length;
      final secs = sw.elapsedMilliseconds / 1000.0;
      if (secs > 0 && bytes > 500) {
        speedMBps = bytes / secs / 1024 / 1024;
      }
    } catch (_) {
      // Débit non mesurable — connectivité OK quand même
    }

    return (ok: true, speedMBps: speedMBps);
  }
}
