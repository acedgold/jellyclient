// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jellyfin_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuthResult _$AuthResultFromJson(Map<String, dynamic> json) {
  return _AuthResult.fromJson(json);
}

/// @nodoc
mixin _$AuthResult {
  String get userId => throw _privateConstructorUsedError;
  String get accessToken => throw _privateConstructorUsedError;
  String get serverId => throw _privateConstructorUsedError;
  String get serverName => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;

  /// Serializes this AuthResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResultCopyWith<AuthResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResultCopyWith<$Res> {
  factory $AuthResultCopyWith(
    AuthResult value,
    $Res Function(AuthResult) then,
  ) = _$AuthResultCopyWithImpl<$Res, AuthResult>;
  @useResult
  $Res call({
    String userId,
    String accessToken,
    String serverId,
    String serverName,
    String username,
  });
}

/// @nodoc
class _$AuthResultCopyWithImpl<$Res, $Val extends AuthResult>
    implements $AuthResultCopyWith<$Res> {
  _$AuthResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? accessToken = null,
    Object? serverId = null,
    Object? serverName = null,
    Object? username = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            serverId: null == serverId
                ? _value.serverId
                : serverId // ignore: cast_nullable_to_non_nullable
                      as String,
            serverName: null == serverName
                ? _value.serverName
                : serverName // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthResultImplCopyWith<$Res>
    implements $AuthResultCopyWith<$Res> {
  factory _$$AuthResultImplCopyWith(
    _$AuthResultImpl value,
    $Res Function(_$AuthResultImpl) then,
  ) = __$$AuthResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String accessToken,
    String serverId,
    String serverName,
    String username,
  });
}

/// @nodoc
class __$$AuthResultImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResultImpl>
    implements _$$AuthResultImplCopyWith<$Res> {
  __$$AuthResultImplCopyWithImpl(
    _$AuthResultImpl _value,
    $Res Function(_$AuthResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? accessToken = null,
    Object? serverId = null,
    Object? serverName = null,
    Object? username = null,
  }) {
    return _then(
      _$AuthResultImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        serverId: null == serverId
            ? _value.serverId
            : serverId // ignore: cast_nullable_to_non_nullable
                  as String,
        serverName: null == serverName
            ? _value.serverName
            : serverName // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResultImpl implements _AuthResult {
  const _$AuthResultImpl({
    required this.userId,
    required this.accessToken,
    required this.serverId,
    required this.serverName,
    required this.username,
  });

  factory _$AuthResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResultImplFromJson(json);

  @override
  final String userId;
  @override
  final String accessToken;
  @override
  final String serverId;
  @override
  final String serverName;
  @override
  final String username;

  @override
  String toString() {
    return 'AuthResult(userId: $userId, accessToken: $accessToken, serverId: $serverId, serverName: $serverName, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResultImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.serverName, serverName) ||
                other.serverName == serverName) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    accessToken,
    serverId,
    serverName,
    username,
  );

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResultImplCopyWith<_$AuthResultImpl> get copyWith =>
      __$$AuthResultImplCopyWithImpl<_$AuthResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResultImplToJson(this);
  }
}

abstract class _AuthResult implements AuthResult {
  const factory _AuthResult({
    required final String userId,
    required final String accessToken,
    required final String serverId,
    required final String serverName,
    required final String username,
  }) = _$AuthResultImpl;

  factory _AuthResult.fromJson(Map<String, dynamic> json) =
      _$AuthResultImpl.fromJson;

  @override
  String get userId;
  @override
  String get accessToken;
  @override
  String get serverId;
  @override
  String get serverName;
  @override
  String get username;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResultImplCopyWith<_$AuthResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ServerProfile _$ServerProfileFromJson(Map<String, dynamic> json) {
  return _ServerProfile.fromJson(json);
}

/// @nodoc
mixin _$ServerProfile {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get accessToken => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;

  /// Serializes this ServerProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServerProfileCopyWith<ServerProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServerProfileCopyWith<$Res> {
  factory $ServerProfileCopyWith(
    ServerProfile value,
    $Res Function(ServerProfile) then,
  ) = _$ServerProfileCopyWithImpl<$Res, ServerProfile>;
  @useResult
  $Res call({
    String id,
    String name,
    String url,
    String userId,
    String accessToken,
    String username,
  });
}

/// @nodoc
class _$ServerProfileCopyWithImpl<$Res, $Val extends ServerProfile>
    implements $ServerProfileCopyWith<$Res> {
  _$ServerProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? url = null,
    Object? userId = null,
    Object? accessToken = null,
    Object? username = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServerProfileImplCopyWith<$Res>
    implements $ServerProfileCopyWith<$Res> {
  factory _$$ServerProfileImplCopyWith(
    _$ServerProfileImpl value,
    $Res Function(_$ServerProfileImpl) then,
  ) = __$$ServerProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String url,
    String userId,
    String accessToken,
    String username,
  });
}

/// @nodoc
class __$$ServerProfileImplCopyWithImpl<$Res>
    extends _$ServerProfileCopyWithImpl<$Res, _$ServerProfileImpl>
    implements _$$ServerProfileImplCopyWith<$Res> {
  __$$ServerProfileImplCopyWithImpl(
    _$ServerProfileImpl _value,
    $Res Function(_$ServerProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? url = null,
    Object? userId = null,
    Object? accessToken = null,
    Object? username = null,
  }) {
    return _then(
      _$ServerProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ServerProfileImpl implements _ServerProfile {
  const _$ServerProfileImpl({
    required this.id,
    required this.name,
    required this.url,
    required this.userId,
    required this.accessToken,
    required this.username,
  });

  factory _$ServerProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServerProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String url;
  @override
  final String userId;
  @override
  final String accessToken;
  @override
  final String username;

  @override
  String toString() {
    return 'ServerProfile(id: $id, name: $name, url: $url, userId: $userId, accessToken: $accessToken, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, url, userId, accessToken, username);

  /// Create a copy of ServerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerProfileImplCopyWith<_$ServerProfileImpl> get copyWith =>
      __$$ServerProfileImplCopyWithImpl<_$ServerProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServerProfileImplToJson(this);
  }
}

abstract class _ServerProfile implements ServerProfile {
  const factory _ServerProfile({
    required final String id,
    required final String name,
    required final String url,
    required final String userId,
    required final String accessToken,
    required final String username,
  }) = _$ServerProfileImpl;

  factory _ServerProfile.fromJson(Map<String, dynamic> json) =
      _$ServerProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get url;
  @override
  String get userId;
  @override
  String get accessToken;
  @override
  String get username;

  /// Create a copy of ServerProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerProfileImplCopyWith<_$ServerProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JellyItem _$JellyItemFromJson(Map<String, dynamic> json) {
  return _JellyItem.fromJson(json);
}

/// @nodoc
mixin _$JellyItem {
  @JsonKey(name: 'Id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'Type')
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'Overview')
  String? get overview => throw _privateConstructorUsedError;
  @JsonKey(name: 'ProductionYear')
  int? get productionYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'CommunityRating')
  double? get communityRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'RunTimeTicks')
  int? get runTimeTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'UserData')
  UserData? get userData => throw _privateConstructorUsedError;
  @JsonKey(name: 'Genres')
  List<String>? get genres => throw _privateConstructorUsedError;
  @JsonKey(name: 'MediaStreams')
  List<MediaStream>? get mediaStreams => throw _privateConstructorUsedError;
  @JsonKey(name: 'SeriesId')
  String? get seriesId => throw _privateConstructorUsedError;
  @JsonKey(name: 'SeriesName')
  String? get seriesName => throw _privateConstructorUsedError;
  @JsonKey(name: 'IndexNumber')
  int? get indexNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'ParentIndexNumber')
  int? get parentIndexNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'ProviderIds')
  Map<String, String> get providerIds => throw _privateConstructorUsedError;
  @JsonKey(name: 'OfficialRating')
  String? get officialRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'Status')
  String? get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'People')
  List<JellyPerson> get people => throw _privateConstructorUsedError;
  @JsonKey(name: 'Taglines')
  List<String> get taglines => throw _privateConstructorUsedError;
  @JsonKey(name: 'DateCreated')
  String? get dateCreated => throw _privateConstructorUsedError;
  @JsonKey(name: 'Chapters')
  List<ChapterInfo> get chapters => throw _privateConstructorUsedError;

  /// Serializes this JellyItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JellyItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JellyItemCopyWith<JellyItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JellyItemCopyWith<$Res> {
  factory $JellyItemCopyWith(JellyItem value, $Res Function(JellyItem) then) =
      _$JellyItemCopyWithImpl<$Res, JellyItem>;
  @useResult
  $Res call({
    @JsonKey(name: 'Id') String id,
    @JsonKey(name: 'Name') String name,
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
    @JsonKey(name: 'ProviderIds') Map<String, String> providerIds,
    @JsonKey(name: 'OfficialRating') String? officialRating,
    @JsonKey(name: 'Status') String? status,
    @JsonKey(name: 'People') List<JellyPerson> people,
    @JsonKey(name: 'Taglines') List<String> taglines,
    @JsonKey(name: 'DateCreated') String? dateCreated,
    @JsonKey(name: 'Chapters') List<ChapterInfo> chapters,
  });

  $UserDataCopyWith<$Res>? get userData;
}

/// @nodoc
class _$JellyItemCopyWithImpl<$Res, $Val extends JellyItem>
    implements $JellyItemCopyWith<$Res> {
  _$JellyItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JellyItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = freezed,
    Object? overview = freezed,
    Object? productionYear = freezed,
    Object? communityRating = freezed,
    Object? runTimeTicks = freezed,
    Object? userData = freezed,
    Object? genres = freezed,
    Object? mediaStreams = freezed,
    Object? seriesId = freezed,
    Object? seriesName = freezed,
    Object? indexNumber = freezed,
    Object? parentIndexNumber = freezed,
    Object? providerIds = null,
    Object? officialRating = freezed,
    Object? status = freezed,
    Object? people = null,
    Object? taglines = null,
    Object? dateCreated = freezed,
    Object? chapters = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            overview: freezed == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String?,
            productionYear: freezed == productionYear
                ? _value.productionYear
                : productionYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            communityRating: freezed == communityRating
                ? _value.communityRating
                : communityRating // ignore: cast_nullable_to_non_nullable
                      as double?,
            runTimeTicks: freezed == runTimeTicks
                ? _value.runTimeTicks
                : runTimeTicks // ignore: cast_nullable_to_non_nullable
                      as int?,
            userData: freezed == userData
                ? _value.userData
                : userData // ignore: cast_nullable_to_non_nullable
                      as UserData?,
            genres: freezed == genres
                ? _value.genres
                : genres // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            mediaStreams: freezed == mediaStreams
                ? _value.mediaStreams
                : mediaStreams // ignore: cast_nullable_to_non_nullable
                      as List<MediaStream>?,
            seriesId: freezed == seriesId
                ? _value.seriesId
                : seriesId // ignore: cast_nullable_to_non_nullable
                      as String?,
            seriesName: freezed == seriesName
                ? _value.seriesName
                : seriesName // ignore: cast_nullable_to_non_nullable
                      as String?,
            indexNumber: freezed == indexNumber
                ? _value.indexNumber
                : indexNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            parentIndexNumber: freezed == parentIndexNumber
                ? _value.parentIndexNumber
                : parentIndexNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            providerIds: null == providerIds
                ? _value.providerIds
                : providerIds // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            officialRating: freezed == officialRating
                ? _value.officialRating
                : officialRating // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            people: null == people
                ? _value.people
                : people // ignore: cast_nullable_to_non_nullable
                      as List<JellyPerson>,
            taglines: null == taglines
                ? _value.taglines
                : taglines // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            dateCreated: freezed == dateCreated
                ? _value.dateCreated
                : dateCreated // ignore: cast_nullable_to_non_nullable
                      as String?,
            chapters: null == chapters
                ? _value.chapters
                : chapters // ignore: cast_nullable_to_non_nullable
                      as List<ChapterInfo>,
          )
          as $Val,
    );
  }

  /// Create a copy of JellyItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserDataCopyWith<$Res>? get userData {
    if (_value.userData == null) {
      return null;
    }

    return $UserDataCopyWith<$Res>(_value.userData!, (value) {
      return _then(_value.copyWith(userData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$JellyItemImplCopyWith<$Res>
    implements $JellyItemCopyWith<$Res> {
  factory _$$JellyItemImplCopyWith(
    _$JellyItemImpl value,
    $Res Function(_$JellyItemImpl) then,
  ) = __$$JellyItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'Id') String id,
    @JsonKey(name: 'Name') String name,
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
    @JsonKey(name: 'ProviderIds') Map<String, String> providerIds,
    @JsonKey(name: 'OfficialRating') String? officialRating,
    @JsonKey(name: 'Status') String? status,
    @JsonKey(name: 'People') List<JellyPerson> people,
    @JsonKey(name: 'Taglines') List<String> taglines,
    @JsonKey(name: 'DateCreated') String? dateCreated,
    @JsonKey(name: 'Chapters') List<ChapterInfo> chapters,
  });

  @override
  $UserDataCopyWith<$Res>? get userData;
}

/// @nodoc
class __$$JellyItemImplCopyWithImpl<$Res>
    extends _$JellyItemCopyWithImpl<$Res, _$JellyItemImpl>
    implements _$$JellyItemImplCopyWith<$Res> {
  __$$JellyItemImplCopyWithImpl(
    _$JellyItemImpl _value,
    $Res Function(_$JellyItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JellyItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = freezed,
    Object? overview = freezed,
    Object? productionYear = freezed,
    Object? communityRating = freezed,
    Object? runTimeTicks = freezed,
    Object? userData = freezed,
    Object? genres = freezed,
    Object? mediaStreams = freezed,
    Object? seriesId = freezed,
    Object? seriesName = freezed,
    Object? indexNumber = freezed,
    Object? parentIndexNumber = freezed,
    Object? providerIds = null,
    Object? officialRating = freezed,
    Object? status = freezed,
    Object? people = null,
    Object? taglines = null,
    Object? dateCreated = freezed,
    Object? chapters = null,
  }) {
    return _then(
      _$JellyItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        overview: freezed == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String?,
        productionYear: freezed == productionYear
            ? _value.productionYear
            : productionYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        communityRating: freezed == communityRating
            ? _value.communityRating
            : communityRating // ignore: cast_nullable_to_non_nullable
                  as double?,
        runTimeTicks: freezed == runTimeTicks
            ? _value.runTimeTicks
            : runTimeTicks // ignore: cast_nullable_to_non_nullable
                  as int?,
        userData: freezed == userData
            ? _value.userData
            : userData // ignore: cast_nullable_to_non_nullable
                  as UserData?,
        genres: freezed == genres
            ? _value._genres
            : genres // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        mediaStreams: freezed == mediaStreams
            ? _value._mediaStreams
            : mediaStreams // ignore: cast_nullable_to_non_nullable
                  as List<MediaStream>?,
        seriesId: freezed == seriesId
            ? _value.seriesId
            : seriesId // ignore: cast_nullable_to_non_nullable
                  as String?,
        seriesName: freezed == seriesName
            ? _value.seriesName
            : seriesName // ignore: cast_nullable_to_non_nullable
                  as String?,
        indexNumber: freezed == indexNumber
            ? _value.indexNumber
            : indexNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        parentIndexNumber: freezed == parentIndexNumber
            ? _value.parentIndexNumber
            : parentIndexNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        providerIds: null == providerIds
            ? _value._providerIds
            : providerIds // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        officialRating: freezed == officialRating
            ? _value.officialRating
            : officialRating // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        people: null == people
            ? _value._people
            : people // ignore: cast_nullable_to_non_nullable
                  as List<JellyPerson>,
        taglines: null == taglines
            ? _value._taglines
            : taglines // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        dateCreated: freezed == dateCreated
            ? _value.dateCreated
            : dateCreated // ignore: cast_nullable_to_non_nullable
                  as String?,
        chapters: null == chapters
            ? _value._chapters
            : chapters // ignore: cast_nullable_to_non_nullable
                  as List<ChapterInfo>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JellyItemImpl implements _JellyItem {
  const _$JellyItemImpl({
    @JsonKey(name: 'Id') required this.id,
    @JsonKey(name: 'Name') required this.name,
    @JsonKey(name: 'Type') this.type,
    @JsonKey(name: 'Overview') this.overview,
    @JsonKey(name: 'ProductionYear') this.productionYear,
    @JsonKey(name: 'CommunityRating') this.communityRating,
    @JsonKey(name: 'RunTimeTicks') this.runTimeTicks,
    @JsonKey(name: 'UserData') this.userData,
    @JsonKey(name: 'Genres') final List<String>? genres,
    @JsonKey(name: 'MediaStreams') final List<MediaStream>? mediaStreams,
    @JsonKey(name: 'SeriesId') this.seriesId,
    @JsonKey(name: 'SeriesName') this.seriesName,
    @JsonKey(name: 'IndexNumber') this.indexNumber,
    @JsonKey(name: 'ParentIndexNumber') this.parentIndexNumber,
    @JsonKey(name: 'ProviderIds')
    final Map<String, String> providerIds = const {},
    @JsonKey(name: 'OfficialRating') this.officialRating,
    @JsonKey(name: 'Status') this.status,
    @JsonKey(name: 'People') final List<JellyPerson> people = const [],
    @JsonKey(name: 'Taglines') final List<String> taglines = const [],
    @JsonKey(name: 'DateCreated') this.dateCreated,
    @JsonKey(name: 'Chapters') final List<ChapterInfo> chapters = const [],
  }) : _genres = genres,
       _mediaStreams = mediaStreams,
       _providerIds = providerIds,
       _people = people,
       _taglines = taglines,
       _chapters = chapters;

  factory _$JellyItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$JellyItemImplFromJson(json);

  @override
  @JsonKey(name: 'Id')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'Type')
  final String? type;
  @override
  @JsonKey(name: 'Overview')
  final String? overview;
  @override
  @JsonKey(name: 'ProductionYear')
  final int? productionYear;
  @override
  @JsonKey(name: 'CommunityRating')
  final double? communityRating;
  @override
  @JsonKey(name: 'RunTimeTicks')
  final int? runTimeTicks;
  @override
  @JsonKey(name: 'UserData')
  final UserData? userData;
  final List<String>? _genres;
  @override
  @JsonKey(name: 'Genres')
  List<String>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<MediaStream>? _mediaStreams;
  @override
  @JsonKey(name: 'MediaStreams')
  List<MediaStream>? get mediaStreams {
    final value = _mediaStreams;
    if (value == null) return null;
    if (_mediaStreams is EqualUnmodifiableListView) return _mediaStreams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'SeriesId')
  final String? seriesId;
  @override
  @JsonKey(name: 'SeriesName')
  final String? seriesName;
  @override
  @JsonKey(name: 'IndexNumber')
  final int? indexNumber;
  @override
  @JsonKey(name: 'ParentIndexNumber')
  final int? parentIndexNumber;
  final Map<String, String> _providerIds;
  @override
  @JsonKey(name: 'ProviderIds')
  Map<String, String> get providerIds {
    if (_providerIds is EqualUnmodifiableMapView) return _providerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_providerIds);
  }

  @override
  @JsonKey(name: 'OfficialRating')
  final String? officialRating;
  @override
  @JsonKey(name: 'Status')
  final String? status;
  final List<JellyPerson> _people;
  @override
  @JsonKey(name: 'People')
  List<JellyPerson> get people {
    if (_people is EqualUnmodifiableListView) return _people;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_people);
  }

  final List<String> _taglines;
  @override
  @JsonKey(name: 'Taglines')
  List<String> get taglines {
    if (_taglines is EqualUnmodifiableListView) return _taglines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taglines);
  }

  @override
  @JsonKey(name: 'DateCreated')
  final String? dateCreated;
  final List<ChapterInfo> _chapters;
  @override
  @JsonKey(name: 'Chapters')
  List<ChapterInfo> get chapters {
    if (_chapters is EqualUnmodifiableListView) return _chapters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chapters);
  }

  @override
  String toString() {
    return 'JellyItem(id: $id, name: $name, type: $type, overview: $overview, productionYear: $productionYear, communityRating: $communityRating, runTimeTicks: $runTimeTicks, userData: $userData, genres: $genres, mediaStreams: $mediaStreams, seriesId: $seriesId, seriesName: $seriesName, indexNumber: $indexNumber, parentIndexNumber: $parentIndexNumber, providerIds: $providerIds, officialRating: $officialRating, status: $status, people: $people, taglines: $taglines, dateCreated: $dateCreated, chapters: $chapters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JellyItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.productionYear, productionYear) ||
                other.productionYear == productionYear) &&
            (identical(other.communityRating, communityRating) ||
                other.communityRating == communityRating) &&
            (identical(other.runTimeTicks, runTimeTicks) ||
                other.runTimeTicks == runTimeTicks) &&
            (identical(other.userData, userData) ||
                other.userData == userData) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            const DeepCollectionEquality().equals(
              other._mediaStreams,
              _mediaStreams,
            ) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.seriesName, seriesName) ||
                other.seriesName == seriesName) &&
            (identical(other.indexNumber, indexNumber) ||
                other.indexNumber == indexNumber) &&
            (identical(other.parentIndexNumber, parentIndexNumber) ||
                other.parentIndexNumber == parentIndexNumber) &&
            const DeepCollectionEquality().equals(
              other._providerIds,
              _providerIds,
            ) &&
            (identical(other.officialRating, officialRating) ||
                other.officialRating == officialRating) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._people, _people) &&
            const DeepCollectionEquality().equals(other._taglines, _taglines) &&
            (identical(other.dateCreated, dateCreated) ||
                other.dateCreated == dateCreated) &&
            const DeepCollectionEquality().equals(other._chapters, _chapters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    type,
    overview,
    productionYear,
    communityRating,
    runTimeTicks,
    userData,
    const DeepCollectionEquality().hash(_genres),
    const DeepCollectionEquality().hash(_mediaStreams),
    seriesId,
    seriesName,
    indexNumber,
    parentIndexNumber,
    const DeepCollectionEquality().hash(_providerIds),
    officialRating,
    status,
    const DeepCollectionEquality().hash(_people),
    const DeepCollectionEquality().hash(_taglines),
    dateCreated,
    const DeepCollectionEquality().hash(_chapters),
  ]);

  /// Create a copy of JellyItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JellyItemImplCopyWith<_$JellyItemImpl> get copyWith =>
      __$$JellyItemImplCopyWithImpl<_$JellyItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JellyItemImplToJson(this);
  }
}

abstract class _JellyItem implements JellyItem {
  const factory _JellyItem({
    @JsonKey(name: 'Id') required final String id,
    @JsonKey(name: 'Name') required final String name,
    @JsonKey(name: 'Type') final String? type,
    @JsonKey(name: 'Overview') final String? overview,
    @JsonKey(name: 'ProductionYear') final int? productionYear,
    @JsonKey(name: 'CommunityRating') final double? communityRating,
    @JsonKey(name: 'RunTimeTicks') final int? runTimeTicks,
    @JsonKey(name: 'UserData') final UserData? userData,
    @JsonKey(name: 'Genres') final List<String>? genres,
    @JsonKey(name: 'MediaStreams') final List<MediaStream>? mediaStreams,
    @JsonKey(name: 'SeriesId') final String? seriesId,
    @JsonKey(name: 'SeriesName') final String? seriesName,
    @JsonKey(name: 'IndexNumber') final int? indexNumber,
    @JsonKey(name: 'ParentIndexNumber') final int? parentIndexNumber,
    @JsonKey(name: 'ProviderIds') final Map<String, String> providerIds,
    @JsonKey(name: 'OfficialRating') final String? officialRating,
    @JsonKey(name: 'Status') final String? status,
    @JsonKey(name: 'People') final List<JellyPerson> people,
    @JsonKey(name: 'Taglines') final List<String> taglines,
    @JsonKey(name: 'DateCreated') final String? dateCreated,
    @JsonKey(name: 'Chapters') final List<ChapterInfo> chapters,
  }) = _$JellyItemImpl;

  factory _JellyItem.fromJson(Map<String, dynamic> json) =
      _$JellyItemImpl.fromJson;

  @override
  @JsonKey(name: 'Id')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'Type')
  String? get type;
  @override
  @JsonKey(name: 'Overview')
  String? get overview;
  @override
  @JsonKey(name: 'ProductionYear')
  int? get productionYear;
  @override
  @JsonKey(name: 'CommunityRating')
  double? get communityRating;
  @override
  @JsonKey(name: 'RunTimeTicks')
  int? get runTimeTicks;
  @override
  @JsonKey(name: 'UserData')
  UserData? get userData;
  @override
  @JsonKey(name: 'Genres')
  List<String>? get genres;
  @override
  @JsonKey(name: 'MediaStreams')
  List<MediaStream>? get mediaStreams;
  @override
  @JsonKey(name: 'SeriesId')
  String? get seriesId;
  @override
  @JsonKey(name: 'SeriesName')
  String? get seriesName;
  @override
  @JsonKey(name: 'IndexNumber')
  int? get indexNumber;
  @override
  @JsonKey(name: 'ParentIndexNumber')
  int? get parentIndexNumber;
  @override
  @JsonKey(name: 'ProviderIds')
  Map<String, String> get providerIds;
  @override
  @JsonKey(name: 'OfficialRating')
  String? get officialRating;
  @override
  @JsonKey(name: 'Status')
  String? get status;
  @override
  @JsonKey(name: 'People')
  List<JellyPerson> get people;
  @override
  @JsonKey(name: 'Taglines')
  List<String> get taglines;
  @override
  @JsonKey(name: 'DateCreated')
  String? get dateCreated;
  @override
  @JsonKey(name: 'Chapters')
  List<ChapterInfo> get chapters;

  /// Create a copy of JellyItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JellyItemImplCopyWith<_$JellyItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserData _$UserDataFromJson(Map<String, dynamic> json) {
  return _UserData.fromJson(json);
}

/// @nodoc
mixin _$UserData {
  @JsonKey(name: 'IsFavorite')
  bool get isFavorite => throw _privateConstructorUsedError;
  @JsonKey(name: 'Played')
  bool get played => throw _privateConstructorUsedError;
  @JsonKey(name: 'PlaybackPositionTicks')
  int? get playbackPositionTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'PlayedPercentage')
  double? get playedPercentage => throw _privateConstructorUsedError;
  @JsonKey(name: 'UnplayedItemCount')
  int? get unplayedItemCount => throw _privateConstructorUsedError;

  /// Serializes this UserData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserDataCopyWith<UserData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDataCopyWith<$Res> {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) then) =
      _$UserDataCopyWithImpl<$Res, UserData>;
  @useResult
  $Res call({
    @JsonKey(name: 'IsFavorite') bool isFavorite,
    @JsonKey(name: 'Played') bool played,
    @JsonKey(name: 'PlaybackPositionTicks') int? playbackPositionTicks,
    @JsonKey(name: 'PlayedPercentage') double? playedPercentage,
    @JsonKey(name: 'UnplayedItemCount') int? unplayedItemCount,
  });
}

/// @nodoc
class _$UserDataCopyWithImpl<$Res, $Val extends UserData>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFavorite = null,
    Object? played = null,
    Object? playbackPositionTicks = freezed,
    Object? playedPercentage = freezed,
    Object? unplayedItemCount = freezed,
  }) {
    return _then(
      _value.copyWith(
            isFavorite: null == isFavorite
                ? _value.isFavorite
                : isFavorite // ignore: cast_nullable_to_non_nullable
                      as bool,
            played: null == played
                ? _value.played
                : played // ignore: cast_nullable_to_non_nullable
                      as bool,
            playbackPositionTicks: freezed == playbackPositionTicks
                ? _value.playbackPositionTicks
                : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
                      as int?,
            playedPercentage: freezed == playedPercentage
                ? _value.playedPercentage
                : playedPercentage // ignore: cast_nullable_to_non_nullable
                      as double?,
            unplayedItemCount: freezed == unplayedItemCount
                ? _value.unplayedItemCount
                : unplayedItemCount // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserDataImplCopyWith<$Res>
    implements $UserDataCopyWith<$Res> {
  factory _$$UserDataImplCopyWith(
    _$UserDataImpl value,
    $Res Function(_$UserDataImpl) then,
  ) = __$$UserDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'IsFavorite') bool isFavorite,
    @JsonKey(name: 'Played') bool played,
    @JsonKey(name: 'PlaybackPositionTicks') int? playbackPositionTicks,
    @JsonKey(name: 'PlayedPercentage') double? playedPercentage,
    @JsonKey(name: 'UnplayedItemCount') int? unplayedItemCount,
  });
}

/// @nodoc
class __$$UserDataImplCopyWithImpl<$Res>
    extends _$UserDataCopyWithImpl<$Res, _$UserDataImpl>
    implements _$$UserDataImplCopyWith<$Res> {
  __$$UserDataImplCopyWithImpl(
    _$UserDataImpl _value,
    $Res Function(_$UserDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFavorite = null,
    Object? played = null,
    Object? playbackPositionTicks = freezed,
    Object? playedPercentage = freezed,
    Object? unplayedItemCount = freezed,
  }) {
    return _then(
      _$UserDataImpl(
        isFavorite: null == isFavorite
            ? _value.isFavorite
            : isFavorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        played: null == played
            ? _value.played
            : played // ignore: cast_nullable_to_non_nullable
                  as bool,
        playbackPositionTicks: freezed == playbackPositionTicks
            ? _value.playbackPositionTicks
            : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
                  as int?,
        playedPercentage: freezed == playedPercentage
            ? _value.playedPercentage
            : playedPercentage // ignore: cast_nullable_to_non_nullable
                  as double?,
        unplayedItemCount: freezed == unplayedItemCount
            ? _value.unplayedItemCount
            : unplayedItemCount // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserDataImpl implements _UserData {
  const _$UserDataImpl({
    @JsonKey(name: 'IsFavorite') this.isFavorite = false,
    @JsonKey(name: 'Played') this.played = false,
    @JsonKey(name: 'PlaybackPositionTicks') this.playbackPositionTicks,
    @JsonKey(name: 'PlayedPercentage') this.playedPercentage,
    @JsonKey(name: 'UnplayedItemCount') this.unplayedItemCount,
  });

  factory _$UserDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserDataImplFromJson(json);

  @override
  @JsonKey(name: 'IsFavorite')
  final bool isFavorite;
  @override
  @JsonKey(name: 'Played')
  final bool played;
  @override
  @JsonKey(name: 'PlaybackPositionTicks')
  final int? playbackPositionTicks;
  @override
  @JsonKey(name: 'PlayedPercentage')
  final double? playedPercentage;
  @override
  @JsonKey(name: 'UnplayedItemCount')
  final int? unplayedItemCount;

  @override
  String toString() {
    return 'UserData(isFavorite: $isFavorite, played: $played, playbackPositionTicks: $playbackPositionTicks, playedPercentage: $playedPercentage, unplayedItemCount: $unplayedItemCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDataImpl &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.played, played) || other.played == played) &&
            (identical(other.playbackPositionTicks, playbackPositionTicks) ||
                other.playbackPositionTicks == playbackPositionTicks) &&
            (identical(other.playedPercentage, playedPercentage) ||
                other.playedPercentage == playedPercentage) &&
            (identical(other.unplayedItemCount, unplayedItemCount) ||
                other.unplayedItemCount == unplayedItemCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isFavorite,
    played,
    playbackPositionTicks,
    playedPercentage,
    unplayedItemCount,
  );

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      __$$UserDataImplCopyWithImpl<_$UserDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDataImplToJson(this);
  }
}

abstract class _UserData implements UserData {
  const factory _UserData({
    @JsonKey(name: 'IsFavorite') final bool isFavorite,
    @JsonKey(name: 'Played') final bool played,
    @JsonKey(name: 'PlaybackPositionTicks') final int? playbackPositionTicks,
    @JsonKey(name: 'PlayedPercentage') final double? playedPercentage,
    @JsonKey(name: 'UnplayedItemCount') final int? unplayedItemCount,
  }) = _$UserDataImpl;

  factory _UserData.fromJson(Map<String, dynamic> json) =
      _$UserDataImpl.fromJson;

  @override
  @JsonKey(name: 'IsFavorite')
  bool get isFavorite;
  @override
  @JsonKey(name: 'Played')
  bool get played;
  @override
  @JsonKey(name: 'PlaybackPositionTicks')
  int? get playbackPositionTicks;
  @override
  @JsonKey(name: 'PlayedPercentage')
  double? get playedPercentage;
  @override
  @JsonKey(name: 'UnplayedItemCount')
  int? get unplayedItemCount;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MediaStream _$MediaStreamFromJson(Map<String, dynamic> json) {
  return _MediaStream.fromJson(json);
}

/// @nodoc
mixin _$MediaStream {
  @JsonKey(name: 'Type')
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'Codec')
  String? get codec => throw _privateConstructorUsedError;
  @JsonKey(name: 'Language')
  String? get language => throw _privateConstructorUsedError;
  @JsonKey(name: 'DisplayTitle')
  String? get displayTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'Index')
  int? get index => throw _privateConstructorUsedError;
  @JsonKey(name: 'IsDefault')
  bool? get isDefault => throw _privateConstructorUsedError;
  @JsonKey(name: 'IsForced')
  bool? get isForced => throw _privateConstructorUsedError;
  @JsonKey(name: 'IsExternal')
  bool? get isExternal => throw _privateConstructorUsedError;

  /// Serializes this MediaStream to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaStream
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaStreamCopyWith<MediaStream> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaStreamCopyWith<$Res> {
  factory $MediaStreamCopyWith(
    MediaStream value,
    $Res Function(MediaStream) then,
  ) = _$MediaStreamCopyWithImpl<$Res, MediaStream>;
  @useResult
  $Res call({
    @JsonKey(name: 'Type') String type,
    @JsonKey(name: 'Codec') String? codec,
    @JsonKey(name: 'Language') String? language,
    @JsonKey(name: 'DisplayTitle') String? displayTitle,
    @JsonKey(name: 'Index') int? index,
    @JsonKey(name: 'IsDefault') bool? isDefault,
    @JsonKey(name: 'IsForced') bool? isForced,
    @JsonKey(name: 'IsExternal') bool? isExternal,
  });
}

/// @nodoc
class _$MediaStreamCopyWithImpl<$Res, $Val extends MediaStream>
    implements $MediaStreamCopyWith<$Res> {
  _$MediaStreamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaStream
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? codec = freezed,
    Object? language = freezed,
    Object? displayTitle = freezed,
    Object? index = freezed,
    Object? isDefault = freezed,
    Object? isForced = freezed,
    Object? isExternal = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            codec: freezed == codec
                ? _value.codec
                : codec // ignore: cast_nullable_to_non_nullable
                      as String?,
            language: freezed == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String?,
            displayTitle: freezed == displayTitle
                ? _value.displayTitle
                : displayTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            index: freezed == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                      as int?,
            isDefault: freezed == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isForced: freezed == isForced
                ? _value.isForced
                : isForced // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isExternal: freezed == isExternal
                ? _value.isExternal
                : isExternal // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MediaStreamImplCopyWith<$Res>
    implements $MediaStreamCopyWith<$Res> {
  factory _$$MediaStreamImplCopyWith(
    _$MediaStreamImpl value,
    $Res Function(_$MediaStreamImpl) then,
  ) = __$$MediaStreamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'Type') String type,
    @JsonKey(name: 'Codec') String? codec,
    @JsonKey(name: 'Language') String? language,
    @JsonKey(name: 'DisplayTitle') String? displayTitle,
    @JsonKey(name: 'Index') int? index,
    @JsonKey(name: 'IsDefault') bool? isDefault,
    @JsonKey(name: 'IsForced') bool? isForced,
    @JsonKey(name: 'IsExternal') bool? isExternal,
  });
}

/// @nodoc
class __$$MediaStreamImplCopyWithImpl<$Res>
    extends _$MediaStreamCopyWithImpl<$Res, _$MediaStreamImpl>
    implements _$$MediaStreamImplCopyWith<$Res> {
  __$$MediaStreamImplCopyWithImpl(
    _$MediaStreamImpl _value,
    $Res Function(_$MediaStreamImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaStream
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? codec = freezed,
    Object? language = freezed,
    Object? displayTitle = freezed,
    Object? index = freezed,
    Object? isDefault = freezed,
    Object? isForced = freezed,
    Object? isExternal = freezed,
  }) {
    return _then(
      _$MediaStreamImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        codec: freezed == codec
            ? _value.codec
            : codec // ignore: cast_nullable_to_non_nullable
                  as String?,
        language: freezed == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
        displayTitle: freezed == displayTitle
            ? _value.displayTitle
            : displayTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        index: freezed == index
            ? _value.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int?,
        isDefault: freezed == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isForced: freezed == isForced
            ? _value.isForced
            : isForced // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isExternal: freezed == isExternal
            ? _value.isExternal
            : isExternal // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaStreamImpl implements _MediaStream {
  const _$MediaStreamImpl({
    @JsonKey(name: 'Type') required this.type,
    @JsonKey(name: 'Codec') this.codec,
    @JsonKey(name: 'Language') this.language,
    @JsonKey(name: 'DisplayTitle') this.displayTitle,
    @JsonKey(name: 'Index') this.index,
    @JsonKey(name: 'IsDefault') this.isDefault,
    @JsonKey(name: 'IsForced') this.isForced,
    @JsonKey(name: 'IsExternal') this.isExternal,
  });

  factory _$MediaStreamImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaStreamImplFromJson(json);

  @override
  @JsonKey(name: 'Type')
  final String type;
  @override
  @JsonKey(name: 'Codec')
  final String? codec;
  @override
  @JsonKey(name: 'Language')
  final String? language;
  @override
  @JsonKey(name: 'DisplayTitle')
  final String? displayTitle;
  @override
  @JsonKey(name: 'Index')
  final int? index;
  @override
  @JsonKey(name: 'IsDefault')
  final bool? isDefault;
  @override
  @JsonKey(name: 'IsForced')
  final bool? isForced;
  @override
  @JsonKey(name: 'IsExternal')
  final bool? isExternal;

  @override
  String toString() {
    return 'MediaStream(type: $type, codec: $codec, language: $language, displayTitle: $displayTitle, index: $index, isDefault: $isDefault, isForced: $isForced, isExternal: $isExternal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaStreamImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.codec, codec) || other.codec == codec) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.displayTitle, displayTitle) ||
                other.displayTitle == displayTitle) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.isForced, isForced) ||
                other.isForced == isForced) &&
            (identical(other.isExternal, isExternal) ||
                other.isExternal == isExternal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    codec,
    language,
    displayTitle,
    index,
    isDefault,
    isForced,
    isExternal,
  );

  /// Create a copy of MediaStream
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaStreamImplCopyWith<_$MediaStreamImpl> get copyWith =>
      __$$MediaStreamImplCopyWithImpl<_$MediaStreamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaStreamImplToJson(this);
  }
}

abstract class _MediaStream implements MediaStream {
  const factory _MediaStream({
    @JsonKey(name: 'Type') required final String type,
    @JsonKey(name: 'Codec') final String? codec,
    @JsonKey(name: 'Language') final String? language,
    @JsonKey(name: 'DisplayTitle') final String? displayTitle,
    @JsonKey(name: 'Index') final int? index,
    @JsonKey(name: 'IsDefault') final bool? isDefault,
    @JsonKey(name: 'IsForced') final bool? isForced,
    @JsonKey(name: 'IsExternal') final bool? isExternal,
  }) = _$MediaStreamImpl;

  factory _MediaStream.fromJson(Map<String, dynamic> json) =
      _$MediaStreamImpl.fromJson;

  @override
  @JsonKey(name: 'Type')
  String get type;
  @override
  @JsonKey(name: 'Codec')
  String? get codec;
  @override
  @JsonKey(name: 'Language')
  String? get language;
  @override
  @JsonKey(name: 'DisplayTitle')
  String? get displayTitle;
  @override
  @JsonKey(name: 'Index')
  int? get index;
  @override
  @JsonKey(name: 'IsDefault')
  bool? get isDefault;
  @override
  @JsonKey(name: 'IsForced')
  bool? get isForced;
  @override
  @JsonKey(name: 'IsExternal')
  bool? get isExternal;

  /// Create a copy of MediaStream
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaStreamImplCopyWith<_$MediaStreamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemsResponse _$ItemsResponseFromJson(Map<String, dynamic> json) {
  return _ItemsResponse.fromJson(json);
}

/// @nodoc
mixin _$ItemsResponse {
  @JsonKey(name: 'Items')
  List<JellyItem> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'TotalRecordCount')
  int get totalRecordCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'StartIndex')
  int? get startIndex => throw _privateConstructorUsedError;

  /// Serializes this ItemsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemsResponseCopyWith<ItemsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemsResponseCopyWith<$Res> {
  factory $ItemsResponseCopyWith(
    ItemsResponse value,
    $Res Function(ItemsResponse) then,
  ) = _$ItemsResponseCopyWithImpl<$Res, ItemsResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'Items') List<JellyItem> items,
    @JsonKey(name: 'TotalRecordCount') int totalRecordCount,
    @JsonKey(name: 'StartIndex') int? startIndex,
  });
}

/// @nodoc
class _$ItemsResponseCopyWithImpl<$Res, $Val extends ItemsResponse>
    implements $ItemsResponseCopyWith<$Res> {
  _$ItemsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalRecordCount = null,
    Object? startIndex = freezed,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<JellyItem>,
            totalRecordCount: null == totalRecordCount
                ? _value.totalRecordCount
                : totalRecordCount // ignore: cast_nullable_to_non_nullable
                      as int,
            startIndex: freezed == startIndex
                ? _value.startIndex
                : startIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemsResponseImplCopyWith<$Res>
    implements $ItemsResponseCopyWith<$Res> {
  factory _$$ItemsResponseImplCopyWith(
    _$ItemsResponseImpl value,
    $Res Function(_$ItemsResponseImpl) then,
  ) = __$$ItemsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'Items') List<JellyItem> items,
    @JsonKey(name: 'TotalRecordCount') int totalRecordCount,
    @JsonKey(name: 'StartIndex') int? startIndex,
  });
}

/// @nodoc
class __$$ItemsResponseImplCopyWithImpl<$Res>
    extends _$ItemsResponseCopyWithImpl<$Res, _$ItemsResponseImpl>
    implements _$$ItemsResponseImplCopyWith<$Res> {
  __$$ItemsResponseImplCopyWithImpl(
    _$ItemsResponseImpl _value,
    $Res Function(_$ItemsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalRecordCount = null,
    Object? startIndex = freezed,
  }) {
    return _then(
      _$ItemsResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<JellyItem>,
        totalRecordCount: null == totalRecordCount
            ? _value.totalRecordCount
            : totalRecordCount // ignore: cast_nullable_to_non_nullable
                  as int,
        startIndex: freezed == startIndex
            ? _value.startIndex
            : startIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemsResponseImpl implements _ItemsResponse {
  const _$ItemsResponseImpl({
    @JsonKey(name: 'Items') final List<JellyItem> items = const [],
    @JsonKey(name: 'TotalRecordCount') this.totalRecordCount = 0,
    @JsonKey(name: 'StartIndex') this.startIndex,
  }) : _items = items;

  factory _$ItemsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemsResponseImplFromJson(json);

  final List<JellyItem> _items;
  @override
  @JsonKey(name: 'Items')
  List<JellyItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(name: 'TotalRecordCount')
  final int totalRecordCount;
  @override
  @JsonKey(name: 'StartIndex')
  final int? startIndex;

  @override
  String toString() {
    return 'ItemsResponse(items: $items, totalRecordCount: $totalRecordCount, startIndex: $startIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemsResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalRecordCount, totalRecordCount) ||
                other.totalRecordCount == totalRecordCount) &&
            (identical(other.startIndex, startIndex) ||
                other.startIndex == startIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    totalRecordCount,
    startIndex,
  );

  /// Create a copy of ItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemsResponseImplCopyWith<_$ItemsResponseImpl> get copyWith =>
      __$$ItemsResponseImplCopyWithImpl<_$ItemsResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemsResponseImplToJson(this);
  }
}

abstract class _ItemsResponse implements ItemsResponse {
  const factory _ItemsResponse({
    @JsonKey(name: 'Items') final List<JellyItem> items,
    @JsonKey(name: 'TotalRecordCount') final int totalRecordCount,
    @JsonKey(name: 'StartIndex') final int? startIndex,
  }) = _$ItemsResponseImpl;

  factory _ItemsResponse.fromJson(Map<String, dynamic> json) =
      _$ItemsResponseImpl.fromJson;

  @override
  @JsonKey(name: 'Items')
  List<JellyItem> get items;
  @override
  @JsonKey(name: 'TotalRecordCount')
  int get totalRecordCount;
  @override
  @JsonKey(name: 'StartIndex')
  int? get startIndex;

  /// Create a copy of ItemsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemsResponseImplCopyWith<_$ItemsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JellyPerson _$JellyPersonFromJson(Map<String, dynamic> json) {
  return _JellyPerson.fromJson(json);
}

/// @nodoc
mixin _$JellyPerson {
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'Type')
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'Role')
  String? get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'Id')
  String? get id => throw _privateConstructorUsedError;

  /// Serializes this JellyPerson to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JellyPerson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JellyPersonCopyWith<JellyPerson> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JellyPersonCopyWith<$Res> {
  factory $JellyPersonCopyWith(
    JellyPerson value,
    $Res Function(JellyPerson) then,
  ) = _$JellyPersonCopyWithImpl<$Res, JellyPerson>;
  @useResult
  $Res call({
    @JsonKey(name: 'Name') String name,
    @JsonKey(name: 'Type') String? type,
    @JsonKey(name: 'Role') String? role,
    @JsonKey(name: 'Id') String? id,
  });
}

/// @nodoc
class _$JellyPersonCopyWithImpl<$Res, $Val extends JellyPerson>
    implements $JellyPersonCopyWith<$Res> {
  _$JellyPersonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JellyPerson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = freezed,
    Object? role = freezed,
    Object? id = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: freezed == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JellyPersonImplCopyWith<$Res>
    implements $JellyPersonCopyWith<$Res> {
  factory _$$JellyPersonImplCopyWith(
    _$JellyPersonImpl value,
    $Res Function(_$JellyPersonImpl) then,
  ) = __$$JellyPersonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'Name') String name,
    @JsonKey(name: 'Type') String? type,
    @JsonKey(name: 'Role') String? role,
    @JsonKey(name: 'Id') String? id,
  });
}

/// @nodoc
class __$$JellyPersonImplCopyWithImpl<$Res>
    extends _$JellyPersonCopyWithImpl<$Res, _$JellyPersonImpl>
    implements _$$JellyPersonImplCopyWith<$Res> {
  __$$JellyPersonImplCopyWithImpl(
    _$JellyPersonImpl _value,
    $Res Function(_$JellyPersonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JellyPerson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = freezed,
    Object? role = freezed,
    Object? id = freezed,
  }) {
    return _then(
      _$JellyPersonImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: freezed == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JellyPersonImpl implements _JellyPerson {
  const _$JellyPersonImpl({
    @JsonKey(name: 'Name') required this.name,
    @JsonKey(name: 'Type') this.type,
    @JsonKey(name: 'Role') this.role,
    @JsonKey(name: 'Id') this.id,
  });

  factory _$JellyPersonImpl.fromJson(Map<String, dynamic> json) =>
      _$$JellyPersonImplFromJson(json);

  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'Type')
  final String? type;
  @override
  @JsonKey(name: 'Role')
  final String? role;
  @override
  @JsonKey(name: 'Id')
  final String? id;

  @override
  String toString() {
    return 'JellyPerson(name: $name, type: $type, role: $role, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JellyPersonImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, type, role, id);

  /// Create a copy of JellyPerson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JellyPersonImplCopyWith<_$JellyPersonImpl> get copyWith =>
      __$$JellyPersonImplCopyWithImpl<_$JellyPersonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JellyPersonImplToJson(this);
  }
}

abstract class _JellyPerson implements JellyPerson {
  const factory _JellyPerson({
    @JsonKey(name: 'Name') required final String name,
    @JsonKey(name: 'Type') final String? type,
    @JsonKey(name: 'Role') final String? role,
    @JsonKey(name: 'Id') final String? id,
  }) = _$JellyPersonImpl;

  factory _JellyPerson.fromJson(Map<String, dynamic> json) =
      _$JellyPersonImpl.fromJson;

  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'Type')
  String? get type;
  @override
  @JsonKey(name: 'Role')
  String? get role;
  @override
  @JsonKey(name: 'Id')
  String? get id;

  /// Create a copy of JellyPerson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JellyPersonImplCopyWith<_$JellyPersonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChapterInfo _$ChapterInfoFromJson(Map<String, dynamic> json) {
  return _ChapterInfo.fromJson(json);
}

/// @nodoc
mixin _$ChapterInfo {
  @JsonKey(name: 'StartPositionTicks')
  int get startPositionTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this ChapterInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChapterInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChapterInfoCopyWith<ChapterInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChapterInfoCopyWith<$Res> {
  factory $ChapterInfoCopyWith(
    ChapterInfo value,
    $Res Function(ChapterInfo) then,
  ) = _$ChapterInfoCopyWithImpl<$Res, ChapterInfo>;
  @useResult
  $Res call({
    @JsonKey(name: 'StartPositionTicks') int startPositionTicks,
    @JsonKey(name: 'Name') String? name,
  });
}

/// @nodoc
class _$ChapterInfoCopyWithImpl<$Res, $Val extends ChapterInfo>
    implements $ChapterInfoCopyWith<$Res> {
  _$ChapterInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChapterInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? startPositionTicks = null, Object? name = freezed}) {
    return _then(
      _value.copyWith(
            startPositionTicks: null == startPositionTicks
                ? _value.startPositionTicks
                : startPositionTicks // ignore: cast_nullable_to_non_nullable
                      as int,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChapterInfoImplCopyWith<$Res>
    implements $ChapterInfoCopyWith<$Res> {
  factory _$$ChapterInfoImplCopyWith(
    _$ChapterInfoImpl value,
    $Res Function(_$ChapterInfoImpl) then,
  ) = __$$ChapterInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'StartPositionTicks') int startPositionTicks,
    @JsonKey(name: 'Name') String? name,
  });
}

/// @nodoc
class __$$ChapterInfoImplCopyWithImpl<$Res>
    extends _$ChapterInfoCopyWithImpl<$Res, _$ChapterInfoImpl>
    implements _$$ChapterInfoImplCopyWith<$Res> {
  __$$ChapterInfoImplCopyWithImpl(
    _$ChapterInfoImpl _value,
    $Res Function(_$ChapterInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChapterInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? startPositionTicks = null, Object? name = freezed}) {
    return _then(
      _$ChapterInfoImpl(
        startPositionTicks: null == startPositionTicks
            ? _value.startPositionTicks
            : startPositionTicks // ignore: cast_nullable_to_non_nullable
                  as int,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChapterInfoImpl implements _ChapterInfo {
  const _$ChapterInfoImpl({
    @JsonKey(name: 'StartPositionTicks') this.startPositionTicks = 0,
    @JsonKey(name: 'Name') this.name,
  });

  factory _$ChapterInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChapterInfoImplFromJson(json);

  @override
  @JsonKey(name: 'StartPositionTicks')
  final int startPositionTicks;
  @override
  @JsonKey(name: 'Name')
  final String? name;

  @override
  String toString() {
    return 'ChapterInfo(startPositionTicks: $startPositionTicks, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChapterInfoImpl &&
            (identical(other.startPositionTicks, startPositionTicks) ||
                other.startPositionTicks == startPositionTicks) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, startPositionTicks, name);

  /// Create a copy of ChapterInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChapterInfoImplCopyWith<_$ChapterInfoImpl> get copyWith =>
      __$$ChapterInfoImplCopyWithImpl<_$ChapterInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChapterInfoImplToJson(this);
  }
}

abstract class _ChapterInfo implements ChapterInfo {
  const factory _ChapterInfo({
    @JsonKey(name: 'StartPositionTicks') final int startPositionTicks,
    @JsonKey(name: 'Name') final String? name,
  }) = _$ChapterInfoImpl;

  factory _ChapterInfo.fromJson(Map<String, dynamic> json) =
      _$ChapterInfoImpl.fromJson;

  @override
  @JsonKey(name: 'StartPositionTicks')
  int get startPositionTicks;
  @override
  @JsonKey(name: 'Name')
  String? get name;

  /// Create a copy of ChapterInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChapterInfoImplCopyWith<_$ChapterInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LibraryView _$LibraryViewFromJson(Map<String, dynamic> json) {
  return _LibraryView.fromJson(json);
}

/// @nodoc
mixin _$LibraryView {
  @JsonKey(name: 'Id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'CollectionType')
  String? get collectionType => throw _privateConstructorUsedError;

  /// Serializes this LibraryView to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LibraryView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LibraryViewCopyWith<LibraryView> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryViewCopyWith<$Res> {
  factory $LibraryViewCopyWith(
    LibraryView value,
    $Res Function(LibraryView) then,
  ) = _$LibraryViewCopyWithImpl<$Res, LibraryView>;
  @useResult
  $Res call({
    @JsonKey(name: 'Id') String id,
    @JsonKey(name: 'Name') String name,
    @JsonKey(name: 'CollectionType') String? collectionType,
  });
}

/// @nodoc
class _$LibraryViewCopyWithImpl<$Res, $Val extends LibraryView>
    implements $LibraryViewCopyWith<$Res> {
  _$LibraryViewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LibraryView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? collectionType = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            collectionType: freezed == collectionType
                ? _value.collectionType
                : collectionType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LibraryViewImplCopyWith<$Res>
    implements $LibraryViewCopyWith<$Res> {
  factory _$$LibraryViewImplCopyWith(
    _$LibraryViewImpl value,
    $Res Function(_$LibraryViewImpl) then,
  ) = __$$LibraryViewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'Id') String id,
    @JsonKey(name: 'Name') String name,
    @JsonKey(name: 'CollectionType') String? collectionType,
  });
}

/// @nodoc
class __$$LibraryViewImplCopyWithImpl<$Res>
    extends _$LibraryViewCopyWithImpl<$Res, _$LibraryViewImpl>
    implements _$$LibraryViewImplCopyWith<$Res> {
  __$$LibraryViewImplCopyWithImpl(
    _$LibraryViewImpl _value,
    $Res Function(_$LibraryViewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LibraryView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? collectionType = freezed,
  }) {
    return _then(
      _$LibraryViewImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        collectionType: freezed == collectionType
            ? _value.collectionType
            : collectionType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LibraryViewImpl implements _LibraryView {
  const _$LibraryViewImpl({
    @JsonKey(name: 'Id') required this.id,
    @JsonKey(name: 'Name') required this.name,
    @JsonKey(name: 'CollectionType') this.collectionType,
  });

  factory _$LibraryViewImpl.fromJson(Map<String, dynamic> json) =>
      _$$LibraryViewImplFromJson(json);

  @override
  @JsonKey(name: 'Id')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'CollectionType')
  final String? collectionType;

  @override
  String toString() {
    return 'LibraryView(id: $id, name: $name, collectionType: $collectionType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryViewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.collectionType, collectionType) ||
                other.collectionType == collectionType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, collectionType);

  /// Create a copy of LibraryView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryViewImplCopyWith<_$LibraryViewImpl> get copyWith =>
      __$$LibraryViewImplCopyWithImpl<_$LibraryViewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LibraryViewImplToJson(this);
  }
}

abstract class _LibraryView implements LibraryView {
  const factory _LibraryView({
    @JsonKey(name: 'Id') required final String id,
    @JsonKey(name: 'Name') required final String name,
    @JsonKey(name: 'CollectionType') final String? collectionType,
  }) = _$LibraryViewImpl;

  factory _LibraryView.fromJson(Map<String, dynamic> json) =
      _$LibraryViewImpl.fromJson;

  @override
  @JsonKey(name: 'Id')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'CollectionType')
  String? get collectionType;

  /// Create a copy of LibraryView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryViewImplCopyWith<_$LibraryViewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LibraryViewsResponse _$LibraryViewsResponseFromJson(Map<String, dynamic> json) {
  return _LibraryViewsResponse.fromJson(json);
}

/// @nodoc
mixin _$LibraryViewsResponse {
  @JsonKey(name: 'Items')
  List<LibraryView> get items => throw _privateConstructorUsedError;

  /// Serializes this LibraryViewsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LibraryViewsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LibraryViewsResponseCopyWith<LibraryViewsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryViewsResponseCopyWith<$Res> {
  factory $LibraryViewsResponseCopyWith(
    LibraryViewsResponse value,
    $Res Function(LibraryViewsResponse) then,
  ) = _$LibraryViewsResponseCopyWithImpl<$Res, LibraryViewsResponse>;
  @useResult
  $Res call({@JsonKey(name: 'Items') List<LibraryView> items});
}

/// @nodoc
class _$LibraryViewsResponseCopyWithImpl<
  $Res,
  $Val extends LibraryViewsResponse
>
    implements $LibraryViewsResponseCopyWith<$Res> {
  _$LibraryViewsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LibraryViewsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<LibraryView>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LibraryViewsResponseImplCopyWith<$Res>
    implements $LibraryViewsResponseCopyWith<$Res> {
  factory _$$LibraryViewsResponseImplCopyWith(
    _$LibraryViewsResponseImpl value,
    $Res Function(_$LibraryViewsResponseImpl) then,
  ) = __$$LibraryViewsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Items') List<LibraryView> items});
}

/// @nodoc
class __$$LibraryViewsResponseImplCopyWithImpl<$Res>
    extends _$LibraryViewsResponseCopyWithImpl<$Res, _$LibraryViewsResponseImpl>
    implements _$$LibraryViewsResponseImplCopyWith<$Res> {
  __$$LibraryViewsResponseImplCopyWithImpl(
    _$LibraryViewsResponseImpl _value,
    $Res Function(_$LibraryViewsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LibraryViewsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$LibraryViewsResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<LibraryView>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LibraryViewsResponseImpl implements _LibraryViewsResponse {
  const _$LibraryViewsResponseImpl({
    @JsonKey(name: 'Items') final List<LibraryView> items = const [],
  }) : _items = items;

  factory _$LibraryViewsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LibraryViewsResponseImplFromJson(json);

  final List<LibraryView> _items;
  @override
  @JsonKey(name: 'Items')
  List<LibraryView> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'LibraryViewsResponse(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryViewsResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of LibraryViewsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryViewsResponseImplCopyWith<_$LibraryViewsResponseImpl>
  get copyWith =>
      __$$LibraryViewsResponseImplCopyWithImpl<_$LibraryViewsResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LibraryViewsResponseImplToJson(this);
  }
}

abstract class _LibraryViewsResponse implements LibraryViewsResponse {
  const factory _LibraryViewsResponse({
    @JsonKey(name: 'Items') final List<LibraryView> items,
  }) = _$LibraryViewsResponseImpl;

  factory _LibraryViewsResponse.fromJson(Map<String, dynamic> json) =
      _$LibraryViewsResponseImpl.fromJson;

  @override
  @JsonKey(name: 'Items')
  List<LibraryView> get items;

  /// Create a copy of LibraryViewsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryViewsResponseImplCopyWith<_$LibraryViewsResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
