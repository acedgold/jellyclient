// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jellyfin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResultImpl _$$AuthResultImplFromJson(Map<String, dynamic> json) =>
    _$AuthResultImpl(
      userId: json['userId'] as String,
      accessToken: json['accessToken'] as String,
      serverId: json['serverId'] as String,
      serverName: json['serverName'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$$AuthResultImplToJson(_$AuthResultImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'accessToken': instance.accessToken,
      'serverId': instance.serverId,
      'serverName': instance.serverName,
      'username': instance.username,
    };

_$ServerProfileImpl _$$ServerProfileImplFromJson(Map<String, dynamic> json) =>
    _$ServerProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      userId: json['userId'] as String,
      accessToken: json['accessToken'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$$ServerProfileImplToJson(_$ServerProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'userId': instance.userId,
      'accessToken': instance.accessToken,
      'username': instance.username,
    };

_$JellyItemImpl _$$JellyItemImplFromJson(
  Map<String, dynamic> json,
) => _$JellyItemImpl(
  id: json['Id'] as String,
  name: json['Name'] as String,
  type: json['Type'] as String?,
  overview: json['Overview'] as String?,
  productionYear: (json['ProductionYear'] as num?)?.toInt(),
  communityRating: (json['CommunityRating'] as num?)?.toDouble(),
  runTimeTicks: (json['RunTimeTicks'] as num?)?.toInt(),
  userData: json['UserData'] == null
      ? null
      : UserData.fromJson(json['UserData'] as Map<String, dynamic>),
  genres: (json['Genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
  mediaStreams: (json['MediaStreams'] as List<dynamic>?)
      ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
      .toList(),
  seriesId: json['SeriesId'] as String?,
  seriesName: json['SeriesName'] as String?,
  indexNumber: (json['IndexNumber'] as num?)?.toInt(),
  parentIndexNumber: (json['ParentIndexNumber'] as num?)?.toInt(),
  providerIds:
      (json['ProviderIds'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  officialRating: json['OfficialRating'] as String?,
  status: json['Status'] as String?,
  people:
      (json['People'] as List<dynamic>?)
          ?.map((e) => JellyPerson.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  taglines:
      (json['Taglines'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  dateCreated: json['DateCreated'] as String?,
  chapters:
      (json['Chapters'] as List<dynamic>?)
          ?.map((e) => ChapterInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$JellyItemImplToJson(_$JellyItemImpl instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'Type': instance.type,
      'Overview': instance.overview,
      'ProductionYear': instance.productionYear,
      'CommunityRating': instance.communityRating,
      'RunTimeTicks': instance.runTimeTicks,
      'UserData': instance.userData,
      'Genres': instance.genres,
      'MediaStreams': instance.mediaStreams,
      'SeriesId': instance.seriesId,
      'SeriesName': instance.seriesName,
      'IndexNumber': instance.indexNumber,
      'ParentIndexNumber': instance.parentIndexNumber,
      'ProviderIds': instance.providerIds,
      'OfficialRating': instance.officialRating,
      'Status': instance.status,
      'People': instance.people,
      'Taglines': instance.taglines,
      'DateCreated': instance.dateCreated,
      'Chapters': instance.chapters,
    };

_$UserDataImpl _$$UserDataImplFromJson(Map<String, dynamic> json) =>
    _$UserDataImpl(
      isFavorite: json['IsFavorite'] as bool? ?? false,
      played: json['Played'] as bool? ?? false,
      playbackPositionTicks: (json['PlaybackPositionTicks'] as num?)?.toInt(),
      playedPercentage: (json['PlayedPercentage'] as num?)?.toDouble(),
      unplayedItemCount: (json['UnplayedItemCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UserDataImplToJson(_$UserDataImpl instance) =>
    <String, dynamic>{
      'IsFavorite': instance.isFavorite,
      'Played': instance.played,
      'PlaybackPositionTicks': instance.playbackPositionTicks,
      'PlayedPercentage': instance.playedPercentage,
      'UnplayedItemCount': instance.unplayedItemCount,
    };

_$MediaStreamImpl _$$MediaStreamImplFromJson(Map<String, dynamic> json) =>
    _$MediaStreamImpl(
      type: json['Type'] as String,
      codec: json['Codec'] as String?,
      language: json['Language'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      index: (json['Index'] as num?)?.toInt(),
      isDefault: json['IsDefault'] as bool?,
      isForced: json['IsForced'] as bool?,
      isExternal: json['IsExternal'] as bool?,
    );

Map<String, dynamic> _$$MediaStreamImplToJson(_$MediaStreamImpl instance) =>
    <String, dynamic>{
      'Type': instance.type,
      'Codec': instance.codec,
      'Language': instance.language,
      'DisplayTitle': instance.displayTitle,
      'Index': instance.index,
      'IsDefault': instance.isDefault,
      'IsForced': instance.isForced,
      'IsExternal': instance.isExternal,
    };

_$ItemsResponseImpl _$$ItemsResponseImplFromJson(Map<String, dynamic> json) =>
    _$ItemsResponseImpl(
      items:
          (json['Items'] as List<dynamic>?)
              ?.map((e) => JellyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalRecordCount: (json['TotalRecordCount'] as num?)?.toInt() ?? 0,
      startIndex: (json['StartIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ItemsResponseImplToJson(_$ItemsResponseImpl instance) =>
    <String, dynamic>{
      'Items': instance.items,
      'TotalRecordCount': instance.totalRecordCount,
      'StartIndex': instance.startIndex,
    };

_$JellyPersonImpl _$$JellyPersonImplFromJson(Map<String, dynamic> json) =>
    _$JellyPersonImpl(
      name: json['Name'] as String,
      type: json['Type'] as String?,
      role: json['Role'] as String?,
      id: json['Id'] as String?,
    );

Map<String, dynamic> _$$JellyPersonImplToJson(_$JellyPersonImpl instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'Type': instance.type,
      'Role': instance.role,
      'Id': instance.id,
    };

_$ChapterInfoImpl _$$ChapterInfoImplFromJson(Map<String, dynamic> json) =>
    _$ChapterInfoImpl(
      startPositionTicks: (json['StartPositionTicks'] as num?)?.toInt() ?? 0,
      name: json['Name'] as String?,
    );

Map<String, dynamic> _$$ChapterInfoImplToJson(_$ChapterInfoImpl instance) =>
    <String, dynamic>{
      'StartPositionTicks': instance.startPositionTicks,
      'Name': instance.name,
    };

_$LibraryViewImpl _$$LibraryViewImplFromJson(Map<String, dynamic> json) =>
    _$LibraryViewImpl(
      id: json['Id'] as String,
      name: json['Name'] as String,
      collectionType: json['CollectionType'] as String?,
    );

Map<String, dynamic> _$$LibraryViewImplToJson(_$LibraryViewImpl instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'CollectionType': instance.collectionType,
    };

_$LibraryViewsResponseImpl _$$LibraryViewsResponseImplFromJson(
  Map<String, dynamic> json,
) => _$LibraryViewsResponseImpl(
  items:
      (json['Items'] as List<dynamic>?)
          ?.map((e) => LibraryView.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$LibraryViewsResponseImplToJson(
  _$LibraryViewsResponseImpl instance,
) => <String, dynamic>{'Items': instance.items};
