import 'package:freezed_annotation/freezed_annotation.dart';

part 'jellyfin_models.freezed.dart';
part 'jellyfin_models.g.dart';

// ─── Auth ──────────────────────────────────────────────────────────────────

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required String userId,
    required String accessToken,
    required String serverId,
    required String serverName,
    required String username,
  }) = _AuthResult;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}

// ─── Server ────────────────────────────────────────────────────────────────

@freezed
class ServerProfile with _$ServerProfile {
  const factory ServerProfile({
    required String id,
    required String name,
    required String url,
    required String userId,
    required String accessToken,
    required String username,
  }) = _ServerProfile;

  factory ServerProfile.fromJson(Map<String, dynamic> json) =>
      _$ServerProfileFromJson(json);
}

// ─── Media Item ────────────────────────────────────────────────────────────

@freezed
class JellyItem with _$JellyItem {
  const factory JellyItem({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Type') String? type,
    @JsonKey(name: 'Overview') String? overview,
    @JsonKey(name: 'ProductionYear') int? productionYear,
    @JsonKey(name: 'CommunityRating') double? communityRating,
    @JsonKey(name: 'RunTimeTicks') int? runTimeTicks,
    @JsonKey(name: 'UserData') UserData? userData,
    @JsonKey(name: 'Genres') List<String>? genres,
    @JsonKey(name: 'MediaStreams') List<MediaStream>? mediaStreams,
    @JsonKey(name: 'SeriesId') String? seriesId,
    @JsonKey(name: 'SeriesName') String? seriesName,
    @JsonKey(name: 'IndexNumber') int? indexNumber,
    @JsonKey(name: 'ParentIndexNumber') int? parentIndexNumber,
    @JsonKey(name: 'ProviderIds') @Default({}) Map<String, String> providerIds,
    @JsonKey(name: 'OfficialRating') String? officialRating,
    @JsonKey(name: 'Status') String? status,
    @JsonKey(name: 'People') @Default([]) List<JellyPerson> people,
    @JsonKey(name: 'Taglines') @Default([]) List<String> taglines,
    @JsonKey(name: 'DateCreated') String? dateCreated,
    @JsonKey(name: 'Chapters') @Default([]) List<ChapterInfo> chapters,
  }) = _JellyItem;

  factory JellyItem.fromJson(Map<String, dynamic> json) =>
      _$JellyItemFromJson(json);
}

@freezed
class UserData with _$UserData {
  const factory UserData({
    @JsonKey(name: 'IsFavorite') @Default(false) bool isFavorite,
    @JsonKey(name: 'Played') @Default(false) bool played,
    @JsonKey(name: 'PlaybackPositionTicks') int? playbackPositionTicks,
    @JsonKey(name: 'PlayedPercentage') double? playedPercentage,
    @JsonKey(name: 'UnplayedItemCount') int? unplayedItemCount,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}

@freezed
class MediaStream with _$MediaStream {
  const factory MediaStream({
    @JsonKey(name: 'Type') required String type,
    @JsonKey(name: 'Codec') String? codec,
    @JsonKey(name: 'Language') String? language,
    @JsonKey(name: 'DisplayTitle') String? displayTitle,
    @JsonKey(name: 'Index') int? index,
    @JsonKey(name: 'IsDefault') bool? isDefault,
    @JsonKey(name: 'IsForced') bool? isForced,
    @JsonKey(name: 'IsExternal') bool? isExternal,
  }) = _MediaStream;

  factory MediaStream.fromJson(Map<String, dynamic> json) =>
      _$MediaStreamFromJson(json);
}

// ─── Items response ────────────────────────────────────────────────────────

@freezed
class ItemsResponse with _$ItemsResponse {
  const factory ItemsResponse({
    @JsonKey(name: 'Items') @Default([]) List<JellyItem> items,
    @JsonKey(name: 'TotalRecordCount') @Default(0) int totalRecordCount,
    @JsonKey(name: 'StartIndex') int? startIndex,
  }) = _ItemsResponse;

  factory ItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$ItemsResponseFromJson(json);
}

// ─── Library view ──────────────────────────────────────────────────────────

@freezed
class JellyPerson with _$JellyPerson {
  const factory JellyPerson({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Type') String? type,
    @JsonKey(name: 'Role') String? role,
    @JsonKey(name: 'Id') String? id,
  }) = _JellyPerson;

  factory JellyPerson.fromJson(Map<String, dynamic> json) =>
      _$JellyPersonFromJson(json);
}

// ─── Chapter ───────────────────────────────────────────────────────────────

@freezed
class ChapterInfo with _$ChapterInfo {
  const factory ChapterInfo({
    @JsonKey(name: 'StartPositionTicks') @Default(0) int startPositionTicks,
    @JsonKey(name: 'Name') String? name,
  }) = _ChapterInfo;

  factory ChapterInfo.fromJson(Map<String, dynamic> json) =>
      _$ChapterInfoFromJson(json);
}

@freezed
class LibraryView with _$LibraryView {
  const factory LibraryView({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'CollectionType') String? collectionType,
  }) = _LibraryView;

  factory LibraryView.fromJson(Map<String, dynamic> json) =>
      _$LibraryViewFromJson(json);
}

@freezed
class LibraryViewsResponse with _$LibraryViewsResponse {
  const factory LibraryViewsResponse({
    @JsonKey(name: 'Items') @Default([]) List<LibraryView> items,
  }) = _LibraryViewsResponse;

  factory LibraryViewsResponse.fromJson(Map<String, dynamic> json) =>
      _$LibraryViewsResponseFromJson(json);
}

// ─── Session active ────────────────────────────────────────────────────────

class JellySession {
  final String? userId;
  final String? userName;
  final String? client;
  final String? deviceName;
  final String? nowPlayingItemId;
  final String? nowPlayingItemName;
  final String? nowPlayingItemType;
  final int? runTimeTicks;
  final int? positionTicks;
  final bool isPaused;

  const JellySession({
    this.userId,
    this.userName,
    this.client,
    this.deviceName,
    this.nowPlayingItemId,
    this.nowPlayingItemName,
    this.nowPlayingItemType,
    this.runTimeTicks,
    this.positionTicks,
    this.isPaused = false,
  });

  bool get isPlaying => nowPlayingItemId != null;

  factory JellySession.fromJson(Map<String, dynamic> json) {
    final nowPlaying = json['NowPlayingItem'] as Map<String, dynamic>?;
    final playState = json['PlayState'] as Map<String, dynamic>?;
    return JellySession(
      userId: json['UserId'] as String?,
      userName: json['UserName'] as String?,
      client: json['Client'] as String?,
      deviceName: json['DeviceName'] as String?,
      nowPlayingItemId: nowPlaying?['Id'] as String?,
      nowPlayingItemName: nowPlaying?['Name'] as String?,
      nowPlayingItemType: nowPlaying?['Type'] as String?,
      runTimeTicks: (nowPlaying?['RunTimeTicks'] as num?)?.toInt(),
      positionTicks: (playState?['PositionTicks'] as num?)?.toInt(),
      isPaused: playState?['IsPaused'] as bool? ?? false,
    );
  }
}
