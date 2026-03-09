// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_database.dart';

// ignore_for_file: type=lint
class $GeocodeCacheTableTable extends GeocodeCacheTable
    with TableInfo<$GeocodeCacheTableTable, GeocodeCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeocodeCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _queryHashMeta =
      const VerificationMeta('queryHash');
  @override
  late final GeneratedColumn<String> queryHash = GeneratedColumn<String>(
      'query_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
      'query', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseJsonMeta =
      const VerificationMeta('responseJson');
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
      'response_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _biasLatMeta =
      const VerificationMeta('biasLat');
  @override
  late final GeneratedColumn<double> biasLat = GeneratedColumn<double>(
      'bias_lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _biasLonMeta =
      const VerificationMeta('biasLon');
  @override
  late final GeneratedColumn<double> biasLon = GeneratedColumn<double>(
      'bias_lon', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        queryHash,
        query,
        responseJson,
        language,
        biasLat,
        biasLon,
        createdAt,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geocode_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<GeocodeCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('query_hash')) {
      context.handle(_queryHashMeta,
          queryHash.isAcceptableOrUnknown(data['query_hash']!, _queryHashMeta));
    } else if (isInserting) {
      context.missing(_queryHashMeta);
    }
    if (data.containsKey('query')) {
      context.handle(
          _queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
          _responseJsonMeta,
          responseJson.isAcceptableOrUnknown(
              data['response_json']!, _responseJsonMeta));
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('bias_lat')) {
      context.handle(_biasLatMeta,
          biasLat.isAcceptableOrUnknown(data['bias_lat']!, _biasLatMeta));
    }
    if (data.containsKey('bias_lon')) {
      context.handle(_biasLonMeta,
          biasLon.isAcceptableOrUnknown(data['bias_lon']!, _biasLonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeocodeCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeocodeCacheTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      queryHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query_hash'])!,
      query: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query'])!,
      responseJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_json'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language']),
      biasLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bias_lat']),
      biasLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bias_lon']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $GeocodeCacheTableTable createAlias(String alias) {
    return $GeocodeCacheTableTable(attachedDatabase, alias);
  }
}

class GeocodeCacheTableData extends DataClass
    implements Insertable<GeocodeCacheTableData> {
  /// Auto-increment primary key
  final int id;

  /// SHA-256 hash of query parameters for fast lookup
  final String queryHash;

  /// Original search query
  final String query;

  /// Serialized GeocodeResponse as JSON
  final String responseJson;

  /// Language code (ru, en, etc.)
  final String? language;

  /// Location bias latitude (if used)
  final double? biasLat;

  /// Location bias longitude (if used)
  final double? biasLon;

  /// Timestamp when entry was created (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when entry expires (milliseconds since epoch)
  final int expiresAt;
  const GeocodeCacheTableData(
      {required this.id,
      required this.queryHash,
      required this.query,
      required this.responseJson,
      this.language,
      this.biasLat,
      this.biasLon,
      required this.createdAt,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['query_hash'] = Variable<String>(queryHash);
    map['query'] = Variable<String>(query);
    map['response_json'] = Variable<String>(responseJson);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || biasLat != null) {
      map['bias_lat'] = Variable<double>(biasLat);
    }
    if (!nullToAbsent || biasLon != null) {
      map['bias_lon'] = Variable<double>(biasLon);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  GeocodeCacheTableCompanion toCompanion(bool nullToAbsent) {
    return GeocodeCacheTableCompanion(
      id: Value(id),
      queryHash: Value(queryHash),
      query: Value(query),
      responseJson: Value(responseJson),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      biasLat: biasLat == null && nullToAbsent
          ? const Value.absent()
          : Value(biasLat),
      biasLon: biasLon == null && nullToAbsent
          ? const Value.absent()
          : Value(biasLon),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory GeocodeCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeocodeCacheTableData(
      id: serializer.fromJson<int>(json['id']),
      queryHash: serializer.fromJson<String>(json['queryHash']),
      query: serializer.fromJson<String>(json['query']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      language: serializer.fromJson<String?>(json['language']),
      biasLat: serializer.fromJson<double?>(json['biasLat']),
      biasLon: serializer.fromJson<double?>(json['biasLon']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'queryHash': serializer.toJson<String>(queryHash),
      'query': serializer.toJson<String>(query),
      'responseJson': serializer.toJson<String>(responseJson),
      'language': serializer.toJson<String?>(language),
      'biasLat': serializer.toJson<double?>(biasLat),
      'biasLon': serializer.toJson<double?>(biasLon),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  GeocodeCacheTableData copyWith(
          {int? id,
          String? queryHash,
          String? query,
          String? responseJson,
          Value<String?> language = const Value.absent(),
          Value<double?> biasLat = const Value.absent(),
          Value<double?> biasLon = const Value.absent(),
          int? createdAt,
          int? expiresAt}) =>
      GeocodeCacheTableData(
        id: id ?? this.id,
        queryHash: queryHash ?? this.queryHash,
        query: query ?? this.query,
        responseJson: responseJson ?? this.responseJson,
        language: language.present ? language.value : this.language,
        biasLat: biasLat.present ? biasLat.value : this.biasLat,
        biasLon: biasLon.present ? biasLon.value : this.biasLon,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  GeocodeCacheTableData copyWithCompanion(GeocodeCacheTableCompanion data) {
    return GeocodeCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      queryHash: data.queryHash.present ? data.queryHash.value : this.queryHash,
      query: data.query.present ? data.query.value : this.query,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      language: data.language.present ? data.language.value : this.language,
      biasLat: data.biasLat.present ? data.biasLat.value : this.biasLat,
      biasLon: data.biasLon.present ? data.biasLon.value : this.biasLon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeocodeCacheTableData(')
          ..write('id: $id, ')
          ..write('queryHash: $queryHash, ')
          ..write('query: $query, ')
          ..write('responseJson: $responseJson, ')
          ..write('language: $language, ')
          ..write('biasLat: $biasLat, ')
          ..write('biasLon: $biasLon, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, queryHash, query, responseJson, language,
      biasLat, biasLon, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeocodeCacheTableData &&
          other.id == this.id &&
          other.queryHash == this.queryHash &&
          other.query == this.query &&
          other.responseJson == this.responseJson &&
          other.language == this.language &&
          other.biasLat == this.biasLat &&
          other.biasLon == this.biasLon &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class GeocodeCacheTableCompanion
    extends UpdateCompanion<GeocodeCacheTableData> {
  final Value<int> id;
  final Value<String> queryHash;
  final Value<String> query;
  final Value<String> responseJson;
  final Value<String?> language;
  final Value<double?> biasLat;
  final Value<double?> biasLon;
  final Value<int> createdAt;
  final Value<int> expiresAt;
  const GeocodeCacheTableCompanion({
    this.id = const Value.absent(),
    this.queryHash = const Value.absent(),
    this.query = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.language = const Value.absent(),
    this.biasLat = const Value.absent(),
    this.biasLon = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  GeocodeCacheTableCompanion.insert({
    this.id = const Value.absent(),
    required String queryHash,
    required String query,
    required String responseJson,
    this.language = const Value.absent(),
    this.biasLat = const Value.absent(),
    this.biasLon = const Value.absent(),
    required int createdAt,
    required int expiresAt,
  })  : queryHash = Value(queryHash),
        query = Value(query),
        responseJson = Value(responseJson),
        createdAt = Value(createdAt),
        expiresAt = Value(expiresAt);
  static Insertable<GeocodeCacheTableData> custom({
    Expression<int>? id,
    Expression<String>? queryHash,
    Expression<String>? query,
    Expression<String>? responseJson,
    Expression<String>? language,
    Expression<double>? biasLat,
    Expression<double>? biasLon,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (queryHash != null) 'query_hash': queryHash,
      if (query != null) 'query': query,
      if (responseJson != null) 'response_json': responseJson,
      if (language != null) 'language': language,
      if (biasLat != null) 'bias_lat': biasLat,
      if (biasLon != null) 'bias_lon': biasLon,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  GeocodeCacheTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? queryHash,
      Value<String>? query,
      Value<String>? responseJson,
      Value<String?>? language,
      Value<double?>? biasLat,
      Value<double?>? biasLon,
      Value<int>? createdAt,
      Value<int>? expiresAt}) {
    return GeocodeCacheTableCompanion(
      id: id ?? this.id,
      queryHash: queryHash ?? this.queryHash,
      query: query ?? this.query,
      responseJson: responseJson ?? this.responseJson,
      language: language ?? this.language,
      biasLat: biasLat ?? this.biasLat,
      biasLon: biasLon ?? this.biasLon,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (queryHash.present) {
      map['query_hash'] = Variable<String>(queryHash.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (biasLat.present) {
      map['bias_lat'] = Variable<double>(biasLat.value);
    }
    if (biasLon.present) {
      map['bias_lon'] = Variable<double>(biasLon.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeocodeCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('queryHash: $queryHash, ')
          ..write('query: $query, ')
          ..write('responseJson: $responseJson, ')
          ..write('language: $language, ')
          ..write('biasLat: $biasLat, ')
          ..write('biasLon: $biasLon, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $ReverseCacheTableTable extends ReverseCacheTable
    with TableInfo<$ReverseCacheTableTable, ReverseCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReverseCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _latBucketMeta =
      const VerificationMeta('latBucket');
  @override
  late final GeneratedColumn<double> latBucket = GeneratedColumn<double>(
      'lat_bucket', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonBucketMeta =
      const VerificationMeta('lonBucket');
  @override
  late final GeneratedColumn<double> lonBucket = GeneratedColumn<double>(
      'lon_bucket', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _responseJsonMeta =
      const VerificationMeta('responseJson');
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
      'response_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        latBucket,
        lonBucket,
        lat,
        lon,
        responseJson,
        language,
        createdAt,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reverse_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<ReverseCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lat_bucket')) {
      context.handle(_latBucketMeta,
          latBucket.isAcceptableOrUnknown(data['lat_bucket']!, _latBucketMeta));
    } else if (isInserting) {
      context.missing(_latBucketMeta);
    }
    if (data.containsKey('lon_bucket')) {
      context.handle(_lonBucketMeta,
          lonBucket.isAcceptableOrUnknown(data['lon_bucket']!, _lonBucketMeta));
    } else if (isInserting) {
      context.missing(_lonBucketMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
          _responseJsonMeta,
          responseJson.isAcceptableOrUnknown(
              data['response_json']!, _responseJsonMeta));
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReverseCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReverseCacheTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      latBucket: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat_bucket'])!,
      lonBucket: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon_bucket'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      responseJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_json'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $ReverseCacheTableTable createAlias(String alias) {
    return $ReverseCacheTableTable(attachedDatabase, alias);
  }
}

class ReverseCacheTableData extends DataClass
    implements Insertable<ReverseCacheTableData> {
  /// Auto-increment primary key
  final int id;

  /// Rounded latitude for spatial indexing (e.g., 55.75 -> 55.8)
  final double latBucket;

  /// Rounded longitude for spatial indexing
  final double lonBucket;

  /// Exact latitude of the request
  final double lat;

  /// Exact longitude of the request
  final double lon;

  /// Serialized ReverseResponse as JSON
  final String responseJson;

  /// Language code (ru, en, etc.)
  final String? language;

  /// Timestamp when entry was created (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when entry expires (milliseconds since epoch)
  final int expiresAt;
  const ReverseCacheTableData(
      {required this.id,
      required this.latBucket,
      required this.lonBucket,
      required this.lat,
      required this.lon,
      required this.responseJson,
      this.language,
      required this.createdAt,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lat_bucket'] = Variable<double>(latBucket);
    map['lon_bucket'] = Variable<double>(lonBucket);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['response_json'] = Variable<String>(responseJson);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  ReverseCacheTableCompanion toCompanion(bool nullToAbsent) {
    return ReverseCacheTableCompanion(
      id: Value(id),
      latBucket: Value(latBucket),
      lonBucket: Value(lonBucket),
      lat: Value(lat),
      lon: Value(lon),
      responseJson: Value(responseJson),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory ReverseCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReverseCacheTableData(
      id: serializer.fromJson<int>(json['id']),
      latBucket: serializer.fromJson<double>(json['latBucket']),
      lonBucket: serializer.fromJson<double>(json['lonBucket']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      language: serializer.fromJson<String?>(json['language']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latBucket': serializer.toJson<double>(latBucket),
      'lonBucket': serializer.toJson<double>(lonBucket),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'responseJson': serializer.toJson<String>(responseJson),
      'language': serializer.toJson<String?>(language),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  ReverseCacheTableData copyWith(
          {int? id,
          double? latBucket,
          double? lonBucket,
          double? lat,
          double? lon,
          String? responseJson,
          Value<String?> language = const Value.absent(),
          int? createdAt,
          int? expiresAt}) =>
      ReverseCacheTableData(
        id: id ?? this.id,
        latBucket: latBucket ?? this.latBucket,
        lonBucket: lonBucket ?? this.lonBucket,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        responseJson: responseJson ?? this.responseJson,
        language: language.present ? language.value : this.language,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  ReverseCacheTableData copyWithCompanion(ReverseCacheTableCompanion data) {
    return ReverseCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      latBucket: data.latBucket.present ? data.latBucket.value : this.latBucket,
      lonBucket: data.lonBucket.present ? data.lonBucket.value : this.lonBucket,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      language: data.language.present ? data.language.value : this.language,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReverseCacheTableData(')
          ..write('id: $id, ')
          ..write('latBucket: $latBucket, ')
          ..write('lonBucket: $lonBucket, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('responseJson: $responseJson, ')
          ..write('language: $language, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, latBucket, lonBucket, lat, lon,
      responseJson, language, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReverseCacheTableData &&
          other.id == this.id &&
          other.latBucket == this.latBucket &&
          other.lonBucket == this.lonBucket &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.responseJson == this.responseJson &&
          other.language == this.language &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class ReverseCacheTableCompanion
    extends UpdateCompanion<ReverseCacheTableData> {
  final Value<int> id;
  final Value<double> latBucket;
  final Value<double> lonBucket;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> responseJson;
  final Value<String?> language;
  final Value<int> createdAt;
  final Value<int> expiresAt;
  const ReverseCacheTableCompanion({
    this.id = const Value.absent(),
    this.latBucket = const Value.absent(),
    this.lonBucket = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.language = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  ReverseCacheTableCompanion.insert({
    this.id = const Value.absent(),
    required double latBucket,
    required double lonBucket,
    required double lat,
    required double lon,
    required String responseJson,
    this.language = const Value.absent(),
    required int createdAt,
    required int expiresAt,
  })  : latBucket = Value(latBucket),
        lonBucket = Value(lonBucket),
        lat = Value(lat),
        lon = Value(lon),
        responseJson = Value(responseJson),
        createdAt = Value(createdAt),
        expiresAt = Value(expiresAt);
  static Insertable<ReverseCacheTableData> custom({
    Expression<int>? id,
    Expression<double>? latBucket,
    Expression<double>? lonBucket,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? responseJson,
    Expression<String>? language,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latBucket != null) 'lat_bucket': latBucket,
      if (lonBucket != null) 'lon_bucket': lonBucket,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (responseJson != null) 'response_json': responseJson,
      if (language != null) 'language': language,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  ReverseCacheTableCompanion copyWith(
      {Value<int>? id,
      Value<double>? latBucket,
      Value<double>? lonBucket,
      Value<double>? lat,
      Value<double>? lon,
      Value<String>? responseJson,
      Value<String?>? language,
      Value<int>? createdAt,
      Value<int>? expiresAt}) {
    return ReverseCacheTableCompanion(
      id: id ?? this.id,
      latBucket: latBucket ?? this.latBucket,
      lonBucket: lonBucket ?? this.lonBucket,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      responseJson: responseJson ?? this.responseJson,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latBucket.present) {
      map['lat_bucket'] = Variable<double>(latBucket.value);
    }
    if (lonBucket.present) {
      map['lon_bucket'] = Variable<double>(lonBucket.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReverseCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('latBucket: $latBucket, ')
          ..write('lonBucket: $lonBucket, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('responseJson: $responseJson, ')
          ..write('language: $language, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $RouteCacheTableTable extends RouteCacheTable
    with TableInfo<$RouteCacheTableTable, RouteCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _routeHashMeta =
      const VerificationMeta('routeHash');
  @override
  late final GeneratedColumn<String> routeHash = GeneratedColumn<String>(
      'route_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _fromLatMeta =
      const VerificationMeta('fromLat');
  @override
  late final GeneratedColumn<double> fromLat = GeneratedColumn<double>(
      'from_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fromLonMeta =
      const VerificationMeta('fromLon');
  @override
  late final GeneratedColumn<double> fromLon = GeneratedColumn<double>(
      'from_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _toLatMeta = const VerificationMeta('toLat');
  @override
  late final GeneratedColumn<double> toLat = GeneratedColumn<double>(
      'to_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _toLonMeta = const VerificationMeta('toLon');
  @override
  late final GeneratedColumn<double> toLon = GeneratedColumn<double>(
      'to_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _waypointsJsonMeta =
      const VerificationMeta('waypointsJson');
  @override
  late final GeneratedColumn<String> waypointsJson = GeneratedColumn<String>(
      'waypoints_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transportModeMeta =
      const VerificationMeta('transportMode');
  @override
  late final GeneratedColumn<String> transportMode = GeneratedColumn<String>(
      'transport_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseJsonMeta =
      const VerificationMeta('responseJson');
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
      'response_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        routeHash,
        fromLat,
        fromLon,
        toLat,
        toLon,
        waypointsJson,
        transportMode,
        responseJson,
        createdAt,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<RouteCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('route_hash')) {
      context.handle(_routeHashMeta,
          routeHash.isAcceptableOrUnknown(data['route_hash']!, _routeHashMeta));
    } else if (isInserting) {
      context.missing(_routeHashMeta);
    }
    if (data.containsKey('from_lat')) {
      context.handle(_fromLatMeta,
          fromLat.isAcceptableOrUnknown(data['from_lat']!, _fromLatMeta));
    } else if (isInserting) {
      context.missing(_fromLatMeta);
    }
    if (data.containsKey('from_lon')) {
      context.handle(_fromLonMeta,
          fromLon.isAcceptableOrUnknown(data['from_lon']!, _fromLonMeta));
    } else if (isInserting) {
      context.missing(_fromLonMeta);
    }
    if (data.containsKey('to_lat')) {
      context.handle(
          _toLatMeta, toLat.isAcceptableOrUnknown(data['to_lat']!, _toLatMeta));
    } else if (isInserting) {
      context.missing(_toLatMeta);
    }
    if (data.containsKey('to_lon')) {
      context.handle(
          _toLonMeta, toLon.isAcceptableOrUnknown(data['to_lon']!, _toLonMeta));
    } else if (isInserting) {
      context.missing(_toLonMeta);
    }
    if (data.containsKey('waypoints_json')) {
      context.handle(
          _waypointsJsonMeta,
          waypointsJson.isAcceptableOrUnknown(
              data['waypoints_json']!, _waypointsJsonMeta));
    }
    if (data.containsKey('transport_mode')) {
      context.handle(
          _transportModeMeta,
          transportMode.isAcceptableOrUnknown(
              data['transport_mode']!, _transportModeMeta));
    } else if (isInserting) {
      context.missing(_transportModeMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
          _responseJsonMeta,
          responseJson.isAcceptableOrUnknown(
              data['response_json']!, _responseJsonMeta));
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RouteCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteCacheTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      routeHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_hash'])!,
      fromLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}from_lat'])!,
      fromLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}from_lon'])!,
      toLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}to_lat'])!,
      toLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}to_lon'])!,
      waypointsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}waypoints_json']),
      transportMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transport_mode'])!,
      responseJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $RouteCacheTableTable createAlias(String alias) {
    return $RouteCacheTableTable(attachedDatabase, alias);
  }
}

class RouteCacheTableData extends DataClass
    implements Insertable<RouteCacheTableData> {
  /// Auto-increment primary key
  final int id;

  /// SHA-256 hash of route parameters for fast lookup
  final String routeHash;

  /// Origin latitude
  final double fromLat;

  /// Origin longitude
  final double fromLon;

  /// Destination latitude
  final double toLat;

  /// Destination longitude
  final double toLon;

  /// Serialized waypoints as JSON array (nullable if no waypoints)
  final String? waypointsJson;

  /// Transport mode (driving, walking, cycling, etc.)
  final String transportMode;

  /// Serialized RouteResponse as JSON
  final String responseJson;

  /// Timestamp when entry was created (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when entry expires (milliseconds since epoch)
  final int expiresAt;
  const RouteCacheTableData(
      {required this.id,
      required this.routeHash,
      required this.fromLat,
      required this.fromLon,
      required this.toLat,
      required this.toLon,
      this.waypointsJson,
      required this.transportMode,
      required this.responseJson,
      required this.createdAt,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['route_hash'] = Variable<String>(routeHash);
    map['from_lat'] = Variable<double>(fromLat);
    map['from_lon'] = Variable<double>(fromLon);
    map['to_lat'] = Variable<double>(toLat);
    map['to_lon'] = Variable<double>(toLon);
    if (!nullToAbsent || waypointsJson != null) {
      map['waypoints_json'] = Variable<String>(waypointsJson);
    }
    map['transport_mode'] = Variable<String>(transportMode);
    map['response_json'] = Variable<String>(responseJson);
    map['created_at'] = Variable<int>(createdAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  RouteCacheTableCompanion toCompanion(bool nullToAbsent) {
    return RouteCacheTableCompanion(
      id: Value(id),
      routeHash: Value(routeHash),
      fromLat: Value(fromLat),
      fromLon: Value(fromLon),
      toLat: Value(toLat),
      toLon: Value(toLon),
      waypointsJson: waypointsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(waypointsJson),
      transportMode: Value(transportMode),
      responseJson: Value(responseJson),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory RouteCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteCacheTableData(
      id: serializer.fromJson<int>(json['id']),
      routeHash: serializer.fromJson<String>(json['routeHash']),
      fromLat: serializer.fromJson<double>(json['fromLat']),
      fromLon: serializer.fromJson<double>(json['fromLon']),
      toLat: serializer.fromJson<double>(json['toLat']),
      toLon: serializer.fromJson<double>(json['toLon']),
      waypointsJson: serializer.fromJson<String?>(json['waypointsJson']),
      transportMode: serializer.fromJson<String>(json['transportMode']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routeHash': serializer.toJson<String>(routeHash),
      'fromLat': serializer.toJson<double>(fromLat),
      'fromLon': serializer.toJson<double>(fromLon),
      'toLat': serializer.toJson<double>(toLat),
      'toLon': serializer.toJson<double>(toLon),
      'waypointsJson': serializer.toJson<String?>(waypointsJson),
      'transportMode': serializer.toJson<String>(transportMode),
      'responseJson': serializer.toJson<String>(responseJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  RouteCacheTableData copyWith(
          {int? id,
          String? routeHash,
          double? fromLat,
          double? fromLon,
          double? toLat,
          double? toLon,
          Value<String?> waypointsJson = const Value.absent(),
          String? transportMode,
          String? responseJson,
          int? createdAt,
          int? expiresAt}) =>
      RouteCacheTableData(
        id: id ?? this.id,
        routeHash: routeHash ?? this.routeHash,
        fromLat: fromLat ?? this.fromLat,
        fromLon: fromLon ?? this.fromLon,
        toLat: toLat ?? this.toLat,
        toLon: toLon ?? this.toLon,
        waypointsJson:
            waypointsJson.present ? waypointsJson.value : this.waypointsJson,
        transportMode: transportMode ?? this.transportMode,
        responseJson: responseJson ?? this.responseJson,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  RouteCacheTableData copyWithCompanion(RouteCacheTableCompanion data) {
    return RouteCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      routeHash: data.routeHash.present ? data.routeHash.value : this.routeHash,
      fromLat: data.fromLat.present ? data.fromLat.value : this.fromLat,
      fromLon: data.fromLon.present ? data.fromLon.value : this.fromLon,
      toLat: data.toLat.present ? data.toLat.value : this.toLat,
      toLon: data.toLon.present ? data.toLon.value : this.toLon,
      waypointsJson: data.waypointsJson.present
          ? data.waypointsJson.value
          : this.waypointsJson,
      transportMode: data.transportMode.present
          ? data.transportMode.value
          : this.transportMode,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteCacheTableData(')
          ..write('id: $id, ')
          ..write('routeHash: $routeHash, ')
          ..write('fromLat: $fromLat, ')
          ..write('fromLon: $fromLon, ')
          ..write('toLat: $toLat, ')
          ..write('toLon: $toLon, ')
          ..write('waypointsJson: $waypointsJson, ')
          ..write('transportMode: $transportMode, ')
          ..write('responseJson: $responseJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, routeHash, fromLat, fromLon, toLat, toLon,
      waypointsJson, transportMode, responseJson, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteCacheTableData &&
          other.id == this.id &&
          other.routeHash == this.routeHash &&
          other.fromLat == this.fromLat &&
          other.fromLon == this.fromLon &&
          other.toLat == this.toLat &&
          other.toLon == this.toLon &&
          other.waypointsJson == this.waypointsJson &&
          other.transportMode == this.transportMode &&
          other.responseJson == this.responseJson &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class RouteCacheTableCompanion extends UpdateCompanion<RouteCacheTableData> {
  final Value<int> id;
  final Value<String> routeHash;
  final Value<double> fromLat;
  final Value<double> fromLon;
  final Value<double> toLat;
  final Value<double> toLon;
  final Value<String?> waypointsJson;
  final Value<String> transportMode;
  final Value<String> responseJson;
  final Value<int> createdAt;
  final Value<int> expiresAt;
  const RouteCacheTableCompanion({
    this.id = const Value.absent(),
    this.routeHash = const Value.absent(),
    this.fromLat = const Value.absent(),
    this.fromLon = const Value.absent(),
    this.toLat = const Value.absent(),
    this.toLon = const Value.absent(),
    this.waypointsJson = const Value.absent(),
    this.transportMode = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  RouteCacheTableCompanion.insert({
    this.id = const Value.absent(),
    required String routeHash,
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
    this.waypointsJson = const Value.absent(),
    required String transportMode,
    required String responseJson,
    required int createdAt,
    required int expiresAt,
  })  : routeHash = Value(routeHash),
        fromLat = Value(fromLat),
        fromLon = Value(fromLon),
        toLat = Value(toLat),
        toLon = Value(toLon),
        transportMode = Value(transportMode),
        responseJson = Value(responseJson),
        createdAt = Value(createdAt),
        expiresAt = Value(expiresAt);
  static Insertable<RouteCacheTableData> custom({
    Expression<int>? id,
    Expression<String>? routeHash,
    Expression<double>? fromLat,
    Expression<double>? fromLon,
    Expression<double>? toLat,
    Expression<double>? toLon,
    Expression<String>? waypointsJson,
    Expression<String>? transportMode,
    Expression<String>? responseJson,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routeHash != null) 'route_hash': routeHash,
      if (fromLat != null) 'from_lat': fromLat,
      if (fromLon != null) 'from_lon': fromLon,
      if (toLat != null) 'to_lat': toLat,
      if (toLon != null) 'to_lon': toLon,
      if (waypointsJson != null) 'waypoints_json': waypointsJson,
      if (transportMode != null) 'transport_mode': transportMode,
      if (responseJson != null) 'response_json': responseJson,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  RouteCacheTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? routeHash,
      Value<double>? fromLat,
      Value<double>? fromLon,
      Value<double>? toLat,
      Value<double>? toLon,
      Value<String?>? waypointsJson,
      Value<String>? transportMode,
      Value<String>? responseJson,
      Value<int>? createdAt,
      Value<int>? expiresAt}) {
    return RouteCacheTableCompanion(
      id: id ?? this.id,
      routeHash: routeHash ?? this.routeHash,
      fromLat: fromLat ?? this.fromLat,
      fromLon: fromLon ?? this.fromLon,
      toLat: toLat ?? this.toLat,
      toLon: toLon ?? this.toLon,
      waypointsJson: waypointsJson ?? this.waypointsJson,
      transportMode: transportMode ?? this.transportMode,
      responseJson: responseJson ?? this.responseJson,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routeHash.present) {
      map['route_hash'] = Variable<String>(routeHash.value);
    }
    if (fromLat.present) {
      map['from_lat'] = Variable<double>(fromLat.value);
    }
    if (fromLon.present) {
      map['from_lon'] = Variable<double>(fromLon.value);
    }
    if (toLat.present) {
      map['to_lat'] = Variable<double>(toLat.value);
    }
    if (toLon.present) {
      map['to_lon'] = Variable<double>(toLon.value);
    }
    if (waypointsJson.present) {
      map['waypoints_json'] = Variable<String>(waypointsJson.value);
    }
    if (transportMode.present) {
      map['transport_mode'] = Variable<String>(transportMode.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('routeHash: $routeHash, ')
          ..write('fromLat: $fromLat, ')
          ..write('fromLon: $fromLon, ')
          ..write('toLat: $toLat, ')
          ..write('toLon: $toLon, ')
          ..write('waypointsJson: $waypointsJson, ')
          ..write('transportMode: $transportMode, ')
          ..write('responseJson: $responseJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $SmartSearchCacheTableTable extends SmartSearchCacheTable
    with TableInfo<$SmartSearchCacheTableTable, SmartSearchCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartSearchCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _queryHashMeta =
      const VerificationMeta('queryHash');
  @override
  late final GeneratedColumn<String> queryHash = GeneratedColumn<String>(
      'query_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
      'query', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationLatMeta =
      const VerificationMeta('locationLat');
  @override
  late final GeneratedColumn<double> locationLat = GeneratedColumn<double>(
      'location_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _locationLonMeta =
      const VerificationMeta('locationLon');
  @override
  late final GeneratedColumn<double> locationLon = GeneratedColumn<double>(
      'location_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _radiusKmMeta =
      const VerificationMeta('radiusKm');
  @override
  late final GeneratedColumn<double> radiusKm = GeneratedColumn<double>(
      'radius_km', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _responseJsonMeta =
      const VerificationMeta('responseJson');
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
      'response_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        queryHash,
        query,
        locationLat,
        locationLon,
        radiusKm,
        language,
        responseJson,
        createdAt,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_search_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<SmartSearchCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('query_hash')) {
      context.handle(_queryHashMeta,
          queryHash.isAcceptableOrUnknown(data['query_hash']!, _queryHashMeta));
    } else if (isInserting) {
      context.missing(_queryHashMeta);
    }
    if (data.containsKey('query')) {
      context.handle(
          _queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('location_lat')) {
      context.handle(
          _locationLatMeta,
          locationLat.isAcceptableOrUnknown(
              data['location_lat']!, _locationLatMeta));
    } else if (isInserting) {
      context.missing(_locationLatMeta);
    }
    if (data.containsKey('location_lon')) {
      context.handle(
          _locationLonMeta,
          locationLon.isAcceptableOrUnknown(
              data['location_lon']!, _locationLonMeta));
    } else if (isInserting) {
      context.missing(_locationLonMeta);
    }
    if (data.containsKey('radius_km')) {
      context.handle(_radiusKmMeta,
          radiusKm.isAcceptableOrUnknown(data['radius_km']!, _radiusKmMeta));
    } else if (isInserting) {
      context.missing(_radiusKmMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('response_json')) {
      context.handle(
          _responseJsonMeta,
          responseJson.isAcceptableOrUnknown(
              data['response_json']!, _responseJsonMeta));
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmartSearchCacheTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartSearchCacheTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      queryHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query_hash'])!,
      query: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query'])!,
      locationLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}location_lat'])!,
      locationLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}location_lon'])!,
      radiusKm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}radius_km'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language']),
      responseJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $SmartSearchCacheTableTable createAlias(String alias) {
    return $SmartSearchCacheTableTable(attachedDatabase, alias);
  }
}

class SmartSearchCacheTableData extends DataClass
    implements Insertable<SmartSearchCacheTableData> {
  /// Auto-increment primary key
  final int id;

  /// SHA-256 hash of search parameters for fast lookup
  final String queryHash;

  /// Original search query
  final String query;

  /// Search center latitude
  final double locationLat;

  /// Search center longitude
  final double locationLon;

  /// Search radius in kilometers
  final double radiusKm;

  /// Language code (ru, en, etc.)
  final String? language;

  /// Serialized SmartSearchResponse as JSON
  final String responseJson;

  /// Timestamp when entry was created (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when entry expires (milliseconds since epoch)
  final int expiresAt;
  const SmartSearchCacheTableData(
      {required this.id,
      required this.queryHash,
      required this.query,
      required this.locationLat,
      required this.locationLon,
      required this.radiusKm,
      this.language,
      required this.responseJson,
      required this.createdAt,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['query_hash'] = Variable<String>(queryHash);
    map['query'] = Variable<String>(query);
    map['location_lat'] = Variable<double>(locationLat);
    map['location_lon'] = Variable<double>(locationLon);
    map['radius_km'] = Variable<double>(radiusKm);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    map['response_json'] = Variable<String>(responseJson);
    map['created_at'] = Variable<int>(createdAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  SmartSearchCacheTableCompanion toCompanion(bool nullToAbsent) {
    return SmartSearchCacheTableCompanion(
      id: Value(id),
      queryHash: Value(queryHash),
      query: Value(query),
      locationLat: Value(locationLat),
      locationLon: Value(locationLon),
      radiusKm: Value(radiusKm),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      responseJson: Value(responseJson),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory SmartSearchCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartSearchCacheTableData(
      id: serializer.fromJson<int>(json['id']),
      queryHash: serializer.fromJson<String>(json['queryHash']),
      query: serializer.fromJson<String>(json['query']),
      locationLat: serializer.fromJson<double>(json['locationLat']),
      locationLon: serializer.fromJson<double>(json['locationLon']),
      radiusKm: serializer.fromJson<double>(json['radiusKm']),
      language: serializer.fromJson<String?>(json['language']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'queryHash': serializer.toJson<String>(queryHash),
      'query': serializer.toJson<String>(query),
      'locationLat': serializer.toJson<double>(locationLat),
      'locationLon': serializer.toJson<double>(locationLon),
      'radiusKm': serializer.toJson<double>(radiusKm),
      'language': serializer.toJson<String?>(language),
      'responseJson': serializer.toJson<String>(responseJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  SmartSearchCacheTableData copyWith(
          {int? id,
          String? queryHash,
          String? query,
          double? locationLat,
          double? locationLon,
          double? radiusKm,
          Value<String?> language = const Value.absent(),
          String? responseJson,
          int? createdAt,
          int? expiresAt}) =>
      SmartSearchCacheTableData(
        id: id ?? this.id,
        queryHash: queryHash ?? this.queryHash,
        query: query ?? this.query,
        locationLat: locationLat ?? this.locationLat,
        locationLon: locationLon ?? this.locationLon,
        radiusKm: radiusKm ?? this.radiusKm,
        language: language.present ? language.value : this.language,
        responseJson: responseJson ?? this.responseJson,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  SmartSearchCacheTableData copyWithCompanion(
      SmartSearchCacheTableCompanion data) {
    return SmartSearchCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      queryHash: data.queryHash.present ? data.queryHash.value : this.queryHash,
      query: data.query.present ? data.query.value : this.query,
      locationLat:
          data.locationLat.present ? data.locationLat.value : this.locationLat,
      locationLon:
          data.locationLon.present ? data.locationLon.value : this.locationLon,
      radiusKm: data.radiusKm.present ? data.radiusKm.value : this.radiusKm,
      language: data.language.present ? data.language.value : this.language,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartSearchCacheTableData(')
          ..write('id: $id, ')
          ..write('queryHash: $queryHash, ')
          ..write('query: $query, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLon: $locationLon, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('language: $language, ')
          ..write('responseJson: $responseJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, queryHash, query, locationLat,
      locationLon, radiusKm, language, responseJson, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartSearchCacheTableData &&
          other.id == this.id &&
          other.queryHash == this.queryHash &&
          other.query == this.query &&
          other.locationLat == this.locationLat &&
          other.locationLon == this.locationLon &&
          other.radiusKm == this.radiusKm &&
          other.language == this.language &&
          other.responseJson == this.responseJson &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class SmartSearchCacheTableCompanion
    extends UpdateCompanion<SmartSearchCacheTableData> {
  final Value<int> id;
  final Value<String> queryHash;
  final Value<String> query;
  final Value<double> locationLat;
  final Value<double> locationLon;
  final Value<double> radiusKm;
  final Value<String?> language;
  final Value<String> responseJson;
  final Value<int> createdAt;
  final Value<int> expiresAt;
  const SmartSearchCacheTableCompanion({
    this.id = const Value.absent(),
    this.queryHash = const Value.absent(),
    this.query = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLon = const Value.absent(),
    this.radiusKm = const Value.absent(),
    this.language = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  SmartSearchCacheTableCompanion.insert({
    this.id = const Value.absent(),
    required String queryHash,
    required String query,
    required double locationLat,
    required double locationLon,
    required double radiusKm,
    this.language = const Value.absent(),
    required String responseJson,
    required int createdAt,
    required int expiresAt,
  })  : queryHash = Value(queryHash),
        query = Value(query),
        locationLat = Value(locationLat),
        locationLon = Value(locationLon),
        radiusKm = Value(radiusKm),
        responseJson = Value(responseJson),
        createdAt = Value(createdAt),
        expiresAt = Value(expiresAt);
  static Insertable<SmartSearchCacheTableData> custom({
    Expression<int>? id,
    Expression<String>? queryHash,
    Expression<String>? query,
    Expression<double>? locationLat,
    Expression<double>? locationLon,
    Expression<double>? radiusKm,
    Expression<String>? language,
    Expression<String>? responseJson,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (queryHash != null) 'query_hash': queryHash,
      if (query != null) 'query': query,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLon != null) 'location_lon': locationLon,
      if (radiusKm != null) 'radius_km': radiusKm,
      if (language != null) 'language': language,
      if (responseJson != null) 'response_json': responseJson,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  SmartSearchCacheTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? queryHash,
      Value<String>? query,
      Value<double>? locationLat,
      Value<double>? locationLon,
      Value<double>? radiusKm,
      Value<String?>? language,
      Value<String>? responseJson,
      Value<int>? createdAt,
      Value<int>? expiresAt}) {
    return SmartSearchCacheTableCompanion(
      id: id ?? this.id,
      queryHash: queryHash ?? this.queryHash,
      query: query ?? this.query,
      locationLat: locationLat ?? this.locationLat,
      locationLon: locationLon ?? this.locationLon,
      radiusKm: radiusKm ?? this.radiusKm,
      language: language ?? this.language,
      responseJson: responseJson ?? this.responseJson,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (queryHash.present) {
      map['query_hash'] = Variable<String>(queryHash.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (locationLat.present) {
      map['location_lat'] = Variable<double>(locationLat.value);
    }
    if (locationLon.present) {
      map['location_lon'] = Variable<double>(locationLon.value);
    }
    if (radiusKm.present) {
      map['radius_km'] = Variable<double>(radiusKm.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartSearchCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('queryHash: $queryHash, ')
          ..write('query: $query, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLon: $locationLon, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('language: $language, ')
          ..write('responseJson: $responseJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineRegionTableTable extends OfflineRegionTable
    with TableInfo<$OfflineRegionTableTable, OfflineRegionTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineRegionTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _regionIdMeta =
      const VerificationMeta('regionId');
  @override
  late final GeneratedColumn<String> regionId = GeneratedColumn<String>(
      'region_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _swLatMeta = const VerificationMeta('swLat');
  @override
  late final GeneratedColumn<double> swLat = GeneratedColumn<double>(
      'sw_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _swLonMeta = const VerificationMeta('swLon');
  @override
  late final GeneratedColumn<double> swLon = GeneratedColumn<double>(
      'sw_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _neLatMeta = const VerificationMeta('neLat');
  @override
  late final GeneratedColumn<double> neLat = GeneratedColumn<double>(
      'ne_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _neLonMeta = const VerificationMeta('neLon');
  @override
  late final GeneratedColumn<double> neLon = GeneratedColumn<double>(
      'ne_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minZoomMeta =
      const VerificationMeta('minZoom');
  @override
  late final GeneratedColumn<double> minZoom = GeneratedColumn<double>(
      'min_zoom', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxZoomMeta =
      const VerificationMeta('maxZoom');
  @override
  late final GeneratedColumn<double> maxZoom = GeneratedColumn<double>(
      'max_zoom', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _styleUrlMeta =
      const VerificationMeta('styleUrl');
  @override
  late final GeneratedColumn<String> styleUrl = GeneratedColumn<String>(
      'style_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _downloadedTilesMeta =
      const VerificationMeta('downloadedTiles');
  @override
  late final GeneratedColumn<int> downloadedTiles = GeneratedColumn<int>(
      'downloaded_tiles', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalTilesMeta =
      const VerificationMeta('totalTiles');
  @override
  late final GeneratedColumn<int> totalTiles = GeneratedColumn<int>(
      'total_tiles', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverRegionIdMeta =
      const VerificationMeta('serverRegionId');
  @override
  late final GeneratedColumn<String> serverRegionId = GeneratedColumn<String>(
      'server_region_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _regionTypeMeta =
      const VerificationMeta('regionType');
  @override
  late final GeneratedColumn<String> regionType = GeneratedColumn<String>(
      'region_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('custom'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        regionId,
        name,
        swLat,
        swLon,
        neLat,
        neLon,
        minZoom,
        maxZoom,
        styleUrl,
        status,
        downloadedTiles,
        totalTiles,
        sizeBytes,
        errorMessage,
        filePath,
        serverRegionId,
        regionType,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_regions';
  @override
  VerificationContext validateIntegrity(
      Insertable<OfflineRegionTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('region_id')) {
      context.handle(_regionIdMeta,
          regionId.isAcceptableOrUnknown(data['region_id']!, _regionIdMeta));
    } else if (isInserting) {
      context.missing(_regionIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sw_lat')) {
      context.handle(
          _swLatMeta, swLat.isAcceptableOrUnknown(data['sw_lat']!, _swLatMeta));
    } else if (isInserting) {
      context.missing(_swLatMeta);
    }
    if (data.containsKey('sw_lon')) {
      context.handle(
          _swLonMeta, swLon.isAcceptableOrUnknown(data['sw_lon']!, _swLonMeta));
    } else if (isInserting) {
      context.missing(_swLonMeta);
    }
    if (data.containsKey('ne_lat')) {
      context.handle(
          _neLatMeta, neLat.isAcceptableOrUnknown(data['ne_lat']!, _neLatMeta));
    } else if (isInserting) {
      context.missing(_neLatMeta);
    }
    if (data.containsKey('ne_lon')) {
      context.handle(
          _neLonMeta, neLon.isAcceptableOrUnknown(data['ne_lon']!, _neLonMeta));
    } else if (isInserting) {
      context.missing(_neLonMeta);
    }
    if (data.containsKey('min_zoom')) {
      context.handle(_minZoomMeta,
          minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta));
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(_maxZoomMeta,
          maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta));
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('style_url')) {
      context.handle(_styleUrlMeta,
          styleUrl.isAcceptableOrUnknown(data['style_url']!, _styleUrlMeta));
    } else if (isInserting) {
      context.missing(_styleUrlMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('downloaded_tiles')) {
      context.handle(
          _downloadedTilesMeta,
          downloadedTiles.isAcceptableOrUnknown(
              data['downloaded_tiles']!, _downloadedTilesMeta));
    }
    if (data.containsKey('total_tiles')) {
      context.handle(
          _totalTilesMeta,
          totalTiles.isAcceptableOrUnknown(
              data['total_tiles']!, _totalTilesMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('server_region_id')) {
      context.handle(
          _serverRegionIdMeta,
          serverRegionId.isAcceptableOrUnknown(
              data['server_region_id']!, _serverRegionIdMeta));
    }
    if (data.containsKey('region_type')) {
      context.handle(
          _regionTypeMeta,
          regionType.isAcceptableOrUnknown(
              data['region_type']!, _regionTypeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineRegionTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineRegionTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      regionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      swLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sw_lat'])!,
      swLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sw_lon'])!,
      neLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ne_lat'])!,
      neLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ne_lon'])!,
      minZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_zoom'])!,
      maxZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_zoom'])!,
      styleUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}style_url'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      downloadedTiles: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_tiles'])!,
      totalTiles: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_tiles'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      serverRegionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}server_region_id']),
      regionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region_type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OfflineRegionTableTable createAlias(String alias) {
    return $OfflineRegionTableTable(attachedDatabase, alias);
  }
}

class OfflineRegionTableData extends DataClass
    implements Insertable<OfflineRegionTableData> {
  /// Auto-increment primary key
  final int id;

  /// Unique region identifier (UUID)
  final String regionId;

  /// Human-readable region name
  final String name;

  /// Southwest bound latitude
  final double swLat;

  /// Southwest bound longitude
  final double swLon;

  /// Northeast bound latitude
  final double neLat;

  /// Northeast bound longitude
  final double neLon;

  /// Minimum zoom level
  final double minZoom;

  /// Maximum zoom level
  final double maxZoom;

  /// Style URL used for this region
  final String styleUrl;

  /// Download status: pending, downloading, paused, completed, failed
  final String status;

  /// Number of downloaded tiles
  final int downloadedTiles;

  /// Total number of tiles to download
  final int totalTiles;

  /// Size in bytes
  final int sizeBytes;

  /// Error message if status is failed
  final String? errorMessage;

  /// Path to the downloaded .mbtiles file
  final String? filePath;

  /// ID of the region on the server (for preset regions)
  final String? serverRegionId;

  /// Type of region: 'custom' or 'preset'
  final String regionType;

  /// Timestamp when region was created (milliseconds since epoch)
  final int createdAt;

  /// Timestamp when region was last updated (milliseconds since epoch)
  final int updatedAt;
  const OfflineRegionTableData(
      {required this.id,
      required this.regionId,
      required this.name,
      required this.swLat,
      required this.swLon,
      required this.neLat,
      required this.neLon,
      required this.minZoom,
      required this.maxZoom,
      required this.styleUrl,
      required this.status,
      required this.downloadedTiles,
      required this.totalTiles,
      required this.sizeBytes,
      this.errorMessage,
      this.filePath,
      this.serverRegionId,
      required this.regionType,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['region_id'] = Variable<String>(regionId);
    map['name'] = Variable<String>(name);
    map['sw_lat'] = Variable<double>(swLat);
    map['sw_lon'] = Variable<double>(swLon);
    map['ne_lat'] = Variable<double>(neLat);
    map['ne_lon'] = Variable<double>(neLon);
    map['min_zoom'] = Variable<double>(minZoom);
    map['max_zoom'] = Variable<double>(maxZoom);
    map['style_url'] = Variable<String>(styleUrl);
    map['status'] = Variable<String>(status);
    map['downloaded_tiles'] = Variable<int>(downloadedTiles);
    map['total_tiles'] = Variable<int>(totalTiles);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || serverRegionId != null) {
      map['server_region_id'] = Variable<String>(serverRegionId);
    }
    map['region_type'] = Variable<String>(regionType);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  OfflineRegionTableCompanion toCompanion(bool nullToAbsent) {
    return OfflineRegionTableCompanion(
      id: Value(id),
      regionId: Value(regionId),
      name: Value(name),
      swLat: Value(swLat),
      swLon: Value(swLon),
      neLat: Value(neLat),
      neLon: Value(neLon),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      styleUrl: Value(styleUrl),
      status: Value(status),
      downloadedTiles: Value(downloadedTiles),
      totalTiles: Value(totalTiles),
      sizeBytes: Value(sizeBytes),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      serverRegionId: serverRegionId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRegionId),
      regionType: Value(regionType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OfflineRegionTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineRegionTableData(
      id: serializer.fromJson<int>(json['id']),
      regionId: serializer.fromJson<String>(json['regionId']),
      name: serializer.fromJson<String>(json['name']),
      swLat: serializer.fromJson<double>(json['swLat']),
      swLon: serializer.fromJson<double>(json['swLon']),
      neLat: serializer.fromJson<double>(json['neLat']),
      neLon: serializer.fromJson<double>(json['neLon']),
      minZoom: serializer.fromJson<double>(json['minZoom']),
      maxZoom: serializer.fromJson<double>(json['maxZoom']),
      styleUrl: serializer.fromJson<String>(json['styleUrl']),
      status: serializer.fromJson<String>(json['status']),
      downloadedTiles: serializer.fromJson<int>(json['downloadedTiles']),
      totalTiles: serializer.fromJson<int>(json['totalTiles']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      serverRegionId: serializer.fromJson<String?>(json['serverRegionId']),
      regionType: serializer.fromJson<String>(json['regionType']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'regionId': serializer.toJson<String>(regionId),
      'name': serializer.toJson<String>(name),
      'swLat': serializer.toJson<double>(swLat),
      'swLon': serializer.toJson<double>(swLon),
      'neLat': serializer.toJson<double>(neLat),
      'neLon': serializer.toJson<double>(neLon),
      'minZoom': serializer.toJson<double>(minZoom),
      'maxZoom': serializer.toJson<double>(maxZoom),
      'styleUrl': serializer.toJson<String>(styleUrl),
      'status': serializer.toJson<String>(status),
      'downloadedTiles': serializer.toJson<int>(downloadedTiles),
      'totalTiles': serializer.toJson<int>(totalTiles),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'filePath': serializer.toJson<String?>(filePath),
      'serverRegionId': serializer.toJson<String?>(serverRegionId),
      'regionType': serializer.toJson<String>(regionType),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  OfflineRegionTableData copyWith(
          {int? id,
          String? regionId,
          String? name,
          double? swLat,
          double? swLon,
          double? neLat,
          double? neLon,
          double? minZoom,
          double? maxZoom,
          String? styleUrl,
          String? status,
          int? downloadedTiles,
          int? totalTiles,
          int? sizeBytes,
          Value<String?> errorMessage = const Value.absent(),
          Value<String?> filePath = const Value.absent(),
          Value<String?> serverRegionId = const Value.absent(),
          String? regionType,
          int? createdAt,
          int? updatedAt}) =>
      OfflineRegionTableData(
        id: id ?? this.id,
        regionId: regionId ?? this.regionId,
        name: name ?? this.name,
        swLat: swLat ?? this.swLat,
        swLon: swLon ?? this.swLon,
        neLat: neLat ?? this.neLat,
        neLon: neLon ?? this.neLon,
        minZoom: minZoom ?? this.minZoom,
        maxZoom: maxZoom ?? this.maxZoom,
        styleUrl: styleUrl ?? this.styleUrl,
        status: status ?? this.status,
        downloadedTiles: downloadedTiles ?? this.downloadedTiles,
        totalTiles: totalTiles ?? this.totalTiles,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        filePath: filePath.present ? filePath.value : this.filePath,
        serverRegionId:
            serverRegionId.present ? serverRegionId.value : this.serverRegionId,
        regionType: regionType ?? this.regionType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OfflineRegionTableData copyWithCompanion(OfflineRegionTableCompanion data) {
    return OfflineRegionTableData(
      id: data.id.present ? data.id.value : this.id,
      regionId: data.regionId.present ? data.regionId.value : this.regionId,
      name: data.name.present ? data.name.value : this.name,
      swLat: data.swLat.present ? data.swLat.value : this.swLat,
      swLon: data.swLon.present ? data.swLon.value : this.swLon,
      neLat: data.neLat.present ? data.neLat.value : this.neLat,
      neLon: data.neLon.present ? data.neLon.value : this.neLon,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      styleUrl: data.styleUrl.present ? data.styleUrl.value : this.styleUrl,
      status: data.status.present ? data.status.value : this.status,
      downloadedTiles: data.downloadedTiles.present
          ? data.downloadedTiles.value
          : this.downloadedTiles,
      totalTiles:
          data.totalTiles.present ? data.totalTiles.value : this.totalTiles,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      serverRegionId: data.serverRegionId.present
          ? data.serverRegionId.value
          : this.serverRegionId,
      regionType:
          data.regionType.present ? data.regionType.value : this.regionType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineRegionTableData(')
          ..write('id: $id, ')
          ..write('regionId: $regionId, ')
          ..write('name: $name, ')
          ..write('swLat: $swLat, ')
          ..write('swLon: $swLon, ')
          ..write('neLat: $neLat, ')
          ..write('neLon: $neLon, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('styleUrl: $styleUrl, ')
          ..write('status: $status, ')
          ..write('downloadedTiles: $downloadedTiles, ')
          ..write('totalTiles: $totalTiles, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('filePath: $filePath, ')
          ..write('serverRegionId: $serverRegionId, ')
          ..write('regionType: $regionType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      regionId,
      name,
      swLat,
      swLon,
      neLat,
      neLon,
      minZoom,
      maxZoom,
      styleUrl,
      status,
      downloadedTiles,
      totalTiles,
      sizeBytes,
      errorMessage,
      filePath,
      serverRegionId,
      regionType,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineRegionTableData &&
          other.id == this.id &&
          other.regionId == this.regionId &&
          other.name == this.name &&
          other.swLat == this.swLat &&
          other.swLon == this.swLon &&
          other.neLat == this.neLat &&
          other.neLon == this.neLon &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.styleUrl == this.styleUrl &&
          other.status == this.status &&
          other.downloadedTiles == this.downloadedTiles &&
          other.totalTiles == this.totalTiles &&
          other.sizeBytes == this.sizeBytes &&
          other.errorMessage == this.errorMessage &&
          other.filePath == this.filePath &&
          other.serverRegionId == this.serverRegionId &&
          other.regionType == this.regionType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OfflineRegionTableCompanion
    extends UpdateCompanion<OfflineRegionTableData> {
  final Value<int> id;
  final Value<String> regionId;
  final Value<String> name;
  final Value<double> swLat;
  final Value<double> swLon;
  final Value<double> neLat;
  final Value<double> neLon;
  final Value<double> minZoom;
  final Value<double> maxZoom;
  final Value<String> styleUrl;
  final Value<String> status;
  final Value<int> downloadedTiles;
  final Value<int> totalTiles;
  final Value<int> sizeBytes;
  final Value<String?> errorMessage;
  final Value<String?> filePath;
  final Value<String?> serverRegionId;
  final Value<String> regionType;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const OfflineRegionTableCompanion({
    this.id = const Value.absent(),
    this.regionId = const Value.absent(),
    this.name = const Value.absent(),
    this.swLat = const Value.absent(),
    this.swLon = const Value.absent(),
    this.neLat = const Value.absent(),
    this.neLon = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.styleUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.downloadedTiles = const Value.absent(),
    this.totalTiles = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.filePath = const Value.absent(),
    this.serverRegionId = const Value.absent(),
    this.regionType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  OfflineRegionTableCompanion.insert({
    this.id = const Value.absent(),
    required String regionId,
    required String name,
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
    required double minZoom,
    required double maxZoom,
    required String styleUrl,
    this.status = const Value.absent(),
    this.downloadedTiles = const Value.absent(),
    this.totalTiles = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.filePath = const Value.absent(),
    this.serverRegionId = const Value.absent(),
    this.regionType = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  })  : regionId = Value(regionId),
        name = Value(name),
        swLat = Value(swLat),
        swLon = Value(swLon),
        neLat = Value(neLat),
        neLon = Value(neLon),
        minZoom = Value(minZoom),
        maxZoom = Value(maxZoom),
        styleUrl = Value(styleUrl),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OfflineRegionTableData> custom({
    Expression<int>? id,
    Expression<String>? regionId,
    Expression<String>? name,
    Expression<double>? swLat,
    Expression<double>? swLon,
    Expression<double>? neLat,
    Expression<double>? neLon,
    Expression<double>? minZoom,
    Expression<double>? maxZoom,
    Expression<String>? styleUrl,
    Expression<String>? status,
    Expression<int>? downloadedTiles,
    Expression<int>? totalTiles,
    Expression<int>? sizeBytes,
    Expression<String>? errorMessage,
    Expression<String>? filePath,
    Expression<String>? serverRegionId,
    Expression<String>? regionType,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (regionId != null) 'region_id': regionId,
      if (name != null) 'name': name,
      if (swLat != null) 'sw_lat': swLat,
      if (swLon != null) 'sw_lon': swLon,
      if (neLat != null) 'ne_lat': neLat,
      if (neLon != null) 'ne_lon': neLon,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (styleUrl != null) 'style_url': styleUrl,
      if (status != null) 'status': status,
      if (downloadedTiles != null) 'downloaded_tiles': downloadedTiles,
      if (totalTiles != null) 'total_tiles': totalTiles,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (errorMessage != null) 'error_message': errorMessage,
      if (filePath != null) 'file_path': filePath,
      if (serverRegionId != null) 'server_region_id': serverRegionId,
      if (regionType != null) 'region_type': regionType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  OfflineRegionTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? regionId,
      Value<String>? name,
      Value<double>? swLat,
      Value<double>? swLon,
      Value<double>? neLat,
      Value<double>? neLon,
      Value<double>? minZoom,
      Value<double>? maxZoom,
      Value<String>? styleUrl,
      Value<String>? status,
      Value<int>? downloadedTiles,
      Value<int>? totalTiles,
      Value<int>? sizeBytes,
      Value<String?>? errorMessage,
      Value<String?>? filePath,
      Value<String?>? serverRegionId,
      Value<String>? regionType,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return OfflineRegionTableCompanion(
      id: id ?? this.id,
      regionId: regionId ?? this.regionId,
      name: name ?? this.name,
      swLat: swLat ?? this.swLat,
      swLon: swLon ?? this.swLon,
      neLat: neLat ?? this.neLat,
      neLon: neLon ?? this.neLon,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      styleUrl: styleUrl ?? this.styleUrl,
      status: status ?? this.status,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      totalTiles: totalTiles ?? this.totalTiles,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      filePath: filePath ?? this.filePath,
      serverRegionId: serverRegionId ?? this.serverRegionId,
      regionType: regionType ?? this.regionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (regionId.present) {
      map['region_id'] = Variable<String>(regionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (swLat.present) {
      map['sw_lat'] = Variable<double>(swLat.value);
    }
    if (swLon.present) {
      map['sw_lon'] = Variable<double>(swLon.value);
    }
    if (neLat.present) {
      map['ne_lat'] = Variable<double>(neLat.value);
    }
    if (neLon.present) {
      map['ne_lon'] = Variable<double>(neLon.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<double>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<double>(maxZoom.value);
    }
    if (styleUrl.present) {
      map['style_url'] = Variable<String>(styleUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (downloadedTiles.present) {
      map['downloaded_tiles'] = Variable<int>(downloadedTiles.value);
    }
    if (totalTiles.present) {
      map['total_tiles'] = Variable<int>(totalTiles.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (serverRegionId.present) {
      map['server_region_id'] = Variable<String>(serverRegionId.value);
    }
    if (regionType.present) {
      map['region_type'] = Variable<String>(regionType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineRegionTableCompanion(')
          ..write('id: $id, ')
          ..write('regionId: $regionId, ')
          ..write('name: $name, ')
          ..write('swLat: $swLat, ')
          ..write('swLon: $swLon, ')
          ..write('neLat: $neLat, ')
          ..write('neLon: $neLon, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('styleUrl: $styleUrl, ')
          ..write('status: $status, ')
          ..write('downloadedTiles: $downloadedTiles, ')
          ..write('totalTiles: $totalTiles, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('filePath: $filePath, ')
          ..write('serverRegionId: $serverRegionId, ')
          ..write('regionType: $regionType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$CacheDatabase extends GeneratedDatabase {
  _$CacheDatabase(QueryExecutor e) : super(e);
  $CacheDatabaseManager get managers => $CacheDatabaseManager(this);
  late final $GeocodeCacheTableTable geocodeCacheTable =
      $GeocodeCacheTableTable(this);
  late final $ReverseCacheTableTable reverseCacheTable =
      $ReverseCacheTableTable(this);
  late final $RouteCacheTableTable routeCacheTable =
      $RouteCacheTableTable(this);
  late final $SmartSearchCacheTableTable smartSearchCacheTable =
      $SmartSearchCacheTableTable(this);
  late final $OfflineRegionTableTable offlineRegionTable =
      $OfflineRegionTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        geocodeCacheTable,
        reverseCacheTable,
        routeCacheTable,
        smartSearchCacheTable,
        offlineRegionTable
      ];
}

typedef $$GeocodeCacheTableTableCreateCompanionBuilder
    = GeocodeCacheTableCompanion Function({
  Value<int> id,
  required String queryHash,
  required String query,
  required String responseJson,
  Value<String?> language,
  Value<double?> biasLat,
  Value<double?> biasLon,
  required int createdAt,
  required int expiresAt,
});
typedef $$GeocodeCacheTableTableUpdateCompanionBuilder
    = GeocodeCacheTableCompanion Function({
  Value<int> id,
  Value<String> queryHash,
  Value<String> query,
  Value<String> responseJson,
  Value<String?> language,
  Value<double?> biasLat,
  Value<double?> biasLon,
  Value<int> createdAt,
  Value<int> expiresAt,
});

class $$GeocodeCacheTableTableFilterComposer
    extends Composer<_$CacheDatabase, $GeocodeCacheTableTable> {
  $$GeocodeCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get query => $composableBuilder(
      column: $table.query, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get biasLat => $composableBuilder(
      column: $table.biasLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get biasLon => $composableBuilder(
      column: $table.biasLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$GeocodeCacheTableTableOrderingComposer
    extends Composer<_$CacheDatabase, $GeocodeCacheTableTable> {
  $$GeocodeCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get query => $composableBuilder(
      column: $table.query, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseJson => $composableBuilder(
      column: $table.responseJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get biasLat => $composableBuilder(
      column: $table.biasLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get biasLon => $composableBuilder(
      column: $table.biasLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$GeocodeCacheTableTableAnnotationComposer
    extends Composer<_$CacheDatabase, $GeocodeCacheTableTable> {
  $$GeocodeCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get queryHash =>
      $composableBuilder(column: $table.queryHash, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<double> get biasLat =>
      $composableBuilder(column: $table.biasLat, builder: (column) => column);

  GeneratedColumn<double> get biasLon =>
      $composableBuilder(column: $table.biasLon, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$GeocodeCacheTableTableTableManager extends RootTableManager<
    _$CacheDatabase,
    $GeocodeCacheTableTable,
    GeocodeCacheTableData,
    $$GeocodeCacheTableTableFilterComposer,
    $$GeocodeCacheTableTableOrderingComposer,
    $$GeocodeCacheTableTableAnnotationComposer,
    $$GeocodeCacheTableTableCreateCompanionBuilder,
    $$GeocodeCacheTableTableUpdateCompanionBuilder,
    (
      GeocodeCacheTableData,
      BaseReferences<_$CacheDatabase, $GeocodeCacheTableTable,
          GeocodeCacheTableData>
    ),
    GeocodeCacheTableData,
    PrefetchHooks Function()> {
  $$GeocodeCacheTableTableTableManager(
      _$CacheDatabase db, $GeocodeCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeocodeCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeocodeCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeocodeCacheTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> queryHash = const Value.absent(),
            Value<String> query = const Value.absent(),
            Value<String> responseJson = const Value.absent(),
            Value<String?> language = const Value.absent(),
            Value<double?> biasLat = const Value.absent(),
            Value<double?> biasLon = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> expiresAt = const Value.absent(),
          }) =>
              GeocodeCacheTableCompanion(
            id: id,
            queryHash: queryHash,
            query: query,
            responseJson: responseJson,
            language: language,
            biasLat: biasLat,
            biasLon: biasLon,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String queryHash,
            required String query,
            required String responseJson,
            Value<String?> language = const Value.absent(),
            Value<double?> biasLat = const Value.absent(),
            Value<double?> biasLon = const Value.absent(),
            required int createdAt,
            required int expiresAt,
          }) =>
              GeocodeCacheTableCompanion.insert(
            id: id,
            queryHash: queryHash,
            query: query,
            responseJson: responseJson,
            language: language,
            biasLat: biasLat,
            biasLon: biasLon,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GeocodeCacheTableTableProcessedTableManager = ProcessedTableManager<
    _$CacheDatabase,
    $GeocodeCacheTableTable,
    GeocodeCacheTableData,
    $$GeocodeCacheTableTableFilterComposer,
    $$GeocodeCacheTableTableOrderingComposer,
    $$GeocodeCacheTableTableAnnotationComposer,
    $$GeocodeCacheTableTableCreateCompanionBuilder,
    $$GeocodeCacheTableTableUpdateCompanionBuilder,
    (
      GeocodeCacheTableData,
      BaseReferences<_$CacheDatabase, $GeocodeCacheTableTable,
          GeocodeCacheTableData>
    ),
    GeocodeCacheTableData,
    PrefetchHooks Function()>;
typedef $$ReverseCacheTableTableCreateCompanionBuilder
    = ReverseCacheTableCompanion Function({
  Value<int> id,
  required double latBucket,
  required double lonBucket,
  required double lat,
  required double lon,
  required String responseJson,
  Value<String?> language,
  required int createdAt,
  required int expiresAt,
});
typedef $$ReverseCacheTableTableUpdateCompanionBuilder
    = ReverseCacheTableCompanion Function({
  Value<int> id,
  Value<double> latBucket,
  Value<double> lonBucket,
  Value<double> lat,
  Value<double> lon,
  Value<String> responseJson,
  Value<String?> language,
  Value<int> createdAt,
  Value<int> expiresAt,
});

class $$ReverseCacheTableTableFilterComposer
    extends Composer<_$CacheDatabase, $ReverseCacheTableTable> {
  $$ReverseCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latBucket => $composableBuilder(
      column: $table.latBucket, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lonBucket => $composableBuilder(
      column: $table.lonBucket, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$ReverseCacheTableTableOrderingComposer
    extends Composer<_$CacheDatabase, $ReverseCacheTableTable> {
  $$ReverseCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latBucket => $composableBuilder(
      column: $table.latBucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lonBucket => $composableBuilder(
      column: $table.lonBucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseJson => $composableBuilder(
      column: $table.responseJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$ReverseCacheTableTableAnnotationComposer
    extends Composer<_$CacheDatabase, $ReverseCacheTableTable> {
  $$ReverseCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latBucket =>
      $composableBuilder(column: $table.latBucket, builder: (column) => column);

  GeneratedColumn<double> get lonBucket =>
      $composableBuilder(column: $table.lonBucket, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$ReverseCacheTableTableTableManager extends RootTableManager<
    _$CacheDatabase,
    $ReverseCacheTableTable,
    ReverseCacheTableData,
    $$ReverseCacheTableTableFilterComposer,
    $$ReverseCacheTableTableOrderingComposer,
    $$ReverseCacheTableTableAnnotationComposer,
    $$ReverseCacheTableTableCreateCompanionBuilder,
    $$ReverseCacheTableTableUpdateCompanionBuilder,
    (
      ReverseCacheTableData,
      BaseReferences<_$CacheDatabase, $ReverseCacheTableTable,
          ReverseCacheTableData>
    ),
    ReverseCacheTableData,
    PrefetchHooks Function()> {
  $$ReverseCacheTableTableTableManager(
      _$CacheDatabase db, $ReverseCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReverseCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReverseCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReverseCacheTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> latBucket = const Value.absent(),
            Value<double> lonBucket = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<String> responseJson = const Value.absent(),
            Value<String?> language = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> expiresAt = const Value.absent(),
          }) =>
              ReverseCacheTableCompanion(
            id: id,
            latBucket: latBucket,
            lonBucket: lonBucket,
            lat: lat,
            lon: lon,
            responseJson: responseJson,
            language: language,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double latBucket,
            required double lonBucket,
            required double lat,
            required double lon,
            required String responseJson,
            Value<String?> language = const Value.absent(),
            required int createdAt,
            required int expiresAt,
          }) =>
              ReverseCacheTableCompanion.insert(
            id: id,
            latBucket: latBucket,
            lonBucket: lonBucket,
            lat: lat,
            lon: lon,
            responseJson: responseJson,
            language: language,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReverseCacheTableTableProcessedTableManager = ProcessedTableManager<
    _$CacheDatabase,
    $ReverseCacheTableTable,
    ReverseCacheTableData,
    $$ReverseCacheTableTableFilterComposer,
    $$ReverseCacheTableTableOrderingComposer,
    $$ReverseCacheTableTableAnnotationComposer,
    $$ReverseCacheTableTableCreateCompanionBuilder,
    $$ReverseCacheTableTableUpdateCompanionBuilder,
    (
      ReverseCacheTableData,
      BaseReferences<_$CacheDatabase, $ReverseCacheTableTable,
          ReverseCacheTableData>
    ),
    ReverseCacheTableData,
    PrefetchHooks Function()>;
typedef $$RouteCacheTableTableCreateCompanionBuilder = RouteCacheTableCompanion
    Function({
  Value<int> id,
  required String routeHash,
  required double fromLat,
  required double fromLon,
  required double toLat,
  required double toLon,
  Value<String?> waypointsJson,
  required String transportMode,
  required String responseJson,
  required int createdAt,
  required int expiresAt,
});
typedef $$RouteCacheTableTableUpdateCompanionBuilder = RouteCacheTableCompanion
    Function({
  Value<int> id,
  Value<String> routeHash,
  Value<double> fromLat,
  Value<double> fromLon,
  Value<double> toLat,
  Value<double> toLon,
  Value<String?> waypointsJson,
  Value<String> transportMode,
  Value<String> responseJson,
  Value<int> createdAt,
  Value<int> expiresAt,
});

class $$RouteCacheTableTableFilterComposer
    extends Composer<_$CacheDatabase, $RouteCacheTableTable> {
  $$RouteCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routeHash => $composableBuilder(
      column: $table.routeHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fromLat => $composableBuilder(
      column: $table.fromLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fromLon => $composableBuilder(
      column: $table.fromLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get toLat => $composableBuilder(
      column: $table.toLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get toLon => $composableBuilder(
      column: $table.toLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get waypointsJson => $composableBuilder(
      column: $table.waypointsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transportMode => $composableBuilder(
      column: $table.transportMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$RouteCacheTableTableOrderingComposer
    extends Composer<_$CacheDatabase, $RouteCacheTableTable> {
  $$RouteCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routeHash => $composableBuilder(
      column: $table.routeHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fromLat => $composableBuilder(
      column: $table.fromLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fromLon => $composableBuilder(
      column: $table.fromLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get toLat => $composableBuilder(
      column: $table.toLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get toLon => $composableBuilder(
      column: $table.toLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get waypointsJson => $composableBuilder(
      column: $table.waypointsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transportMode => $composableBuilder(
      column: $table.transportMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseJson => $composableBuilder(
      column: $table.responseJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$RouteCacheTableTableAnnotationComposer
    extends Composer<_$CacheDatabase, $RouteCacheTableTable> {
  $$RouteCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routeHash =>
      $composableBuilder(column: $table.routeHash, builder: (column) => column);

  GeneratedColumn<double> get fromLat =>
      $composableBuilder(column: $table.fromLat, builder: (column) => column);

  GeneratedColumn<double> get fromLon =>
      $composableBuilder(column: $table.fromLon, builder: (column) => column);

  GeneratedColumn<double> get toLat =>
      $composableBuilder(column: $table.toLat, builder: (column) => column);

  GeneratedColumn<double> get toLon =>
      $composableBuilder(column: $table.toLon, builder: (column) => column);

  GeneratedColumn<String> get waypointsJson => $composableBuilder(
      column: $table.waypointsJson, builder: (column) => column);

  GeneratedColumn<String> get transportMode => $composableBuilder(
      column: $table.transportMode, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$RouteCacheTableTableTableManager extends RootTableManager<
    _$CacheDatabase,
    $RouteCacheTableTable,
    RouteCacheTableData,
    $$RouteCacheTableTableFilterComposer,
    $$RouteCacheTableTableOrderingComposer,
    $$RouteCacheTableTableAnnotationComposer,
    $$RouteCacheTableTableCreateCompanionBuilder,
    $$RouteCacheTableTableUpdateCompanionBuilder,
    (
      RouteCacheTableData,
      BaseReferences<_$CacheDatabase, $RouteCacheTableTable,
          RouteCacheTableData>
    ),
    RouteCacheTableData,
    PrefetchHooks Function()> {
  $$RouteCacheTableTableTableManager(
      _$CacheDatabase db, $RouteCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RouteCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RouteCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RouteCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> routeHash = const Value.absent(),
            Value<double> fromLat = const Value.absent(),
            Value<double> fromLon = const Value.absent(),
            Value<double> toLat = const Value.absent(),
            Value<double> toLon = const Value.absent(),
            Value<String?> waypointsJson = const Value.absent(),
            Value<String> transportMode = const Value.absent(),
            Value<String> responseJson = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> expiresAt = const Value.absent(),
          }) =>
              RouteCacheTableCompanion(
            id: id,
            routeHash: routeHash,
            fromLat: fromLat,
            fromLon: fromLon,
            toLat: toLat,
            toLon: toLon,
            waypointsJson: waypointsJson,
            transportMode: transportMode,
            responseJson: responseJson,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String routeHash,
            required double fromLat,
            required double fromLon,
            required double toLat,
            required double toLon,
            Value<String?> waypointsJson = const Value.absent(),
            required String transportMode,
            required String responseJson,
            required int createdAt,
            required int expiresAt,
          }) =>
              RouteCacheTableCompanion.insert(
            id: id,
            routeHash: routeHash,
            fromLat: fromLat,
            fromLon: fromLon,
            toLat: toLat,
            toLon: toLon,
            waypointsJson: waypointsJson,
            transportMode: transportMode,
            responseJson: responseJson,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RouteCacheTableTableProcessedTableManager = ProcessedTableManager<
    _$CacheDatabase,
    $RouteCacheTableTable,
    RouteCacheTableData,
    $$RouteCacheTableTableFilterComposer,
    $$RouteCacheTableTableOrderingComposer,
    $$RouteCacheTableTableAnnotationComposer,
    $$RouteCacheTableTableCreateCompanionBuilder,
    $$RouteCacheTableTableUpdateCompanionBuilder,
    (
      RouteCacheTableData,
      BaseReferences<_$CacheDatabase, $RouteCacheTableTable,
          RouteCacheTableData>
    ),
    RouteCacheTableData,
    PrefetchHooks Function()>;
typedef $$SmartSearchCacheTableTableCreateCompanionBuilder
    = SmartSearchCacheTableCompanion Function({
  Value<int> id,
  required String queryHash,
  required String query,
  required double locationLat,
  required double locationLon,
  required double radiusKm,
  Value<String?> language,
  required String responseJson,
  required int createdAt,
  required int expiresAt,
});
typedef $$SmartSearchCacheTableTableUpdateCompanionBuilder
    = SmartSearchCacheTableCompanion Function({
  Value<int> id,
  Value<String> queryHash,
  Value<String> query,
  Value<double> locationLat,
  Value<double> locationLon,
  Value<double> radiusKm,
  Value<String?> language,
  Value<String> responseJson,
  Value<int> createdAt,
  Value<int> expiresAt,
});

class $$SmartSearchCacheTableTableFilterComposer
    extends Composer<_$CacheDatabase, $SmartSearchCacheTableTable> {
  $$SmartSearchCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get query => $composableBuilder(
      column: $table.query, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get locationLat => $composableBuilder(
      column: $table.locationLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get locationLon => $composableBuilder(
      column: $table.locationLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get radiusKm => $composableBuilder(
      column: $table.radiusKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$SmartSearchCacheTableTableOrderingComposer
    extends Composer<_$CacheDatabase, $SmartSearchCacheTableTable> {
  $$SmartSearchCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get query => $composableBuilder(
      column: $table.query, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get locationLat => $composableBuilder(
      column: $table.locationLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get locationLon => $composableBuilder(
      column: $table.locationLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get radiusKm => $composableBuilder(
      column: $table.radiusKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseJson => $composableBuilder(
      column: $table.responseJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$SmartSearchCacheTableTableAnnotationComposer
    extends Composer<_$CacheDatabase, $SmartSearchCacheTableTable> {
  $$SmartSearchCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get queryHash =>
      $composableBuilder(column: $table.queryHash, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<double> get locationLat => $composableBuilder(
      column: $table.locationLat, builder: (column) => column);

  GeneratedColumn<double> get locationLon => $composableBuilder(
      column: $table.locationLon, builder: (column) => column);

  GeneratedColumn<double> get radiusKm =>
      $composableBuilder(column: $table.radiusKm, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$SmartSearchCacheTableTableTableManager extends RootTableManager<
    _$CacheDatabase,
    $SmartSearchCacheTableTable,
    SmartSearchCacheTableData,
    $$SmartSearchCacheTableTableFilterComposer,
    $$SmartSearchCacheTableTableOrderingComposer,
    $$SmartSearchCacheTableTableAnnotationComposer,
    $$SmartSearchCacheTableTableCreateCompanionBuilder,
    $$SmartSearchCacheTableTableUpdateCompanionBuilder,
    (
      SmartSearchCacheTableData,
      BaseReferences<_$CacheDatabase, $SmartSearchCacheTableTable,
          SmartSearchCacheTableData>
    ),
    SmartSearchCacheTableData,
    PrefetchHooks Function()> {
  $$SmartSearchCacheTableTableTableManager(
      _$CacheDatabase db, $SmartSearchCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartSearchCacheTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartSearchCacheTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmartSearchCacheTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> queryHash = const Value.absent(),
            Value<String> query = const Value.absent(),
            Value<double> locationLat = const Value.absent(),
            Value<double> locationLon = const Value.absent(),
            Value<double> radiusKm = const Value.absent(),
            Value<String?> language = const Value.absent(),
            Value<String> responseJson = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> expiresAt = const Value.absent(),
          }) =>
              SmartSearchCacheTableCompanion(
            id: id,
            queryHash: queryHash,
            query: query,
            locationLat: locationLat,
            locationLon: locationLon,
            radiusKm: radiusKm,
            language: language,
            responseJson: responseJson,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String queryHash,
            required String query,
            required double locationLat,
            required double locationLon,
            required double radiusKm,
            Value<String?> language = const Value.absent(),
            required String responseJson,
            required int createdAt,
            required int expiresAt,
          }) =>
              SmartSearchCacheTableCompanion.insert(
            id: id,
            queryHash: queryHash,
            query: query,
            locationLat: locationLat,
            locationLon: locationLon,
            radiusKm: radiusKm,
            language: language,
            responseJson: responseJson,
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SmartSearchCacheTableTableProcessedTableManager
    = ProcessedTableManager<
        _$CacheDatabase,
        $SmartSearchCacheTableTable,
        SmartSearchCacheTableData,
        $$SmartSearchCacheTableTableFilterComposer,
        $$SmartSearchCacheTableTableOrderingComposer,
        $$SmartSearchCacheTableTableAnnotationComposer,
        $$SmartSearchCacheTableTableCreateCompanionBuilder,
        $$SmartSearchCacheTableTableUpdateCompanionBuilder,
        (
          SmartSearchCacheTableData,
          BaseReferences<_$CacheDatabase, $SmartSearchCacheTableTable,
              SmartSearchCacheTableData>
        ),
        SmartSearchCacheTableData,
        PrefetchHooks Function()>;
typedef $$OfflineRegionTableTableCreateCompanionBuilder
    = OfflineRegionTableCompanion Function({
  Value<int> id,
  required String regionId,
  required String name,
  required double swLat,
  required double swLon,
  required double neLat,
  required double neLon,
  required double minZoom,
  required double maxZoom,
  required String styleUrl,
  Value<String> status,
  Value<int> downloadedTiles,
  Value<int> totalTiles,
  Value<int> sizeBytes,
  Value<String?> errorMessage,
  Value<String?> filePath,
  Value<String?> serverRegionId,
  Value<String> regionType,
  required int createdAt,
  required int updatedAt,
});
typedef $$OfflineRegionTableTableUpdateCompanionBuilder
    = OfflineRegionTableCompanion Function({
  Value<int> id,
  Value<String> regionId,
  Value<String> name,
  Value<double> swLat,
  Value<double> swLon,
  Value<double> neLat,
  Value<double> neLon,
  Value<double> minZoom,
  Value<double> maxZoom,
  Value<String> styleUrl,
  Value<String> status,
  Value<int> downloadedTiles,
  Value<int> totalTiles,
  Value<int> sizeBytes,
  Value<String?> errorMessage,
  Value<String?> filePath,
  Value<String?> serverRegionId,
  Value<String> regionType,
  Value<int> createdAt,
  Value<int> updatedAt,
});

class $$OfflineRegionTableTableFilterComposer
    extends Composer<_$CacheDatabase, $OfflineRegionTableTable> {
  $$OfflineRegionTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regionId => $composableBuilder(
      column: $table.regionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get swLat => $composableBuilder(
      column: $table.swLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get swLon => $composableBuilder(
      column: $table.swLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get neLat => $composableBuilder(
      column: $table.neLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get neLon => $composableBuilder(
      column: $table.neLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get styleUrl => $composableBuilder(
      column: $table.styleUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedTiles => $composableBuilder(
      column: $table.downloadedTiles,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalTiles => $composableBuilder(
      column: $table.totalTiles, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverRegionId => $composableBuilder(
      column: $table.serverRegionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regionType => $composableBuilder(
      column: $table.regionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OfflineRegionTableTableOrderingComposer
    extends Composer<_$CacheDatabase, $OfflineRegionTableTable> {
  $$OfflineRegionTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regionId => $composableBuilder(
      column: $table.regionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get swLat => $composableBuilder(
      column: $table.swLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get swLon => $composableBuilder(
      column: $table.swLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get neLat => $composableBuilder(
      column: $table.neLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get neLon => $composableBuilder(
      column: $table.neLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get styleUrl => $composableBuilder(
      column: $table.styleUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedTiles => $composableBuilder(
      column: $table.downloadedTiles,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalTiles => $composableBuilder(
      column: $table.totalTiles, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverRegionId => $composableBuilder(
      column: $table.serverRegionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regionType => $composableBuilder(
      column: $table.regionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OfflineRegionTableTableAnnotationComposer
    extends Composer<_$CacheDatabase, $OfflineRegionTableTable> {
  $$OfflineRegionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get regionId =>
      $composableBuilder(column: $table.regionId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get swLat =>
      $composableBuilder(column: $table.swLat, builder: (column) => column);

  GeneratedColumn<double> get swLon =>
      $composableBuilder(column: $table.swLon, builder: (column) => column);

  GeneratedColumn<double> get neLat =>
      $composableBuilder(column: $table.neLat, builder: (column) => column);

  GeneratedColumn<double> get neLon =>
      $composableBuilder(column: $table.neLon, builder: (column) => column);

  GeneratedColumn<double> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<double> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<String> get styleUrl =>
      $composableBuilder(column: $table.styleUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get downloadedTiles => $composableBuilder(
      column: $table.downloadedTiles, builder: (column) => column);

  GeneratedColumn<int> get totalTiles => $composableBuilder(
      column: $table.totalTiles, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get serverRegionId => $composableBuilder(
      column: $table.serverRegionId, builder: (column) => column);

  GeneratedColumn<String> get regionType => $composableBuilder(
      column: $table.regionType, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OfflineRegionTableTableTableManager extends RootTableManager<
    _$CacheDatabase,
    $OfflineRegionTableTable,
    OfflineRegionTableData,
    $$OfflineRegionTableTableFilterComposer,
    $$OfflineRegionTableTableOrderingComposer,
    $$OfflineRegionTableTableAnnotationComposer,
    $$OfflineRegionTableTableCreateCompanionBuilder,
    $$OfflineRegionTableTableUpdateCompanionBuilder,
    (
      OfflineRegionTableData,
      BaseReferences<_$CacheDatabase, $OfflineRegionTableTable,
          OfflineRegionTableData>
    ),
    OfflineRegionTableData,
    PrefetchHooks Function()> {
  $$OfflineRegionTableTableTableManager(
      _$CacheDatabase db, $OfflineRegionTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineRegionTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineRegionTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineRegionTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> regionId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> swLat = const Value.absent(),
            Value<double> swLon = const Value.absent(),
            Value<double> neLat = const Value.absent(),
            Value<double> neLon = const Value.absent(),
            Value<double> minZoom = const Value.absent(),
            Value<double> maxZoom = const Value.absent(),
            Value<String> styleUrl = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> downloadedTiles = const Value.absent(),
            Value<int> totalTiles = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> serverRegionId = const Value.absent(),
            Value<String> regionType = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              OfflineRegionTableCompanion(
            id: id,
            regionId: regionId,
            name: name,
            swLat: swLat,
            swLon: swLon,
            neLat: neLat,
            neLon: neLon,
            minZoom: minZoom,
            maxZoom: maxZoom,
            styleUrl: styleUrl,
            status: status,
            downloadedTiles: downloadedTiles,
            totalTiles: totalTiles,
            sizeBytes: sizeBytes,
            errorMessage: errorMessage,
            filePath: filePath,
            serverRegionId: serverRegionId,
            regionType: regionType,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String regionId,
            required String name,
            required double swLat,
            required double swLon,
            required double neLat,
            required double neLon,
            required double minZoom,
            required double maxZoom,
            required String styleUrl,
            Value<String> status = const Value.absent(),
            Value<int> downloadedTiles = const Value.absent(),
            Value<int> totalTiles = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> serverRegionId = const Value.absent(),
            Value<String> regionType = const Value.absent(),
            required int createdAt,
            required int updatedAt,
          }) =>
              OfflineRegionTableCompanion.insert(
            id: id,
            regionId: regionId,
            name: name,
            swLat: swLat,
            swLon: swLon,
            neLat: neLat,
            neLon: neLon,
            minZoom: minZoom,
            maxZoom: maxZoom,
            styleUrl: styleUrl,
            status: status,
            downloadedTiles: downloadedTiles,
            totalTiles: totalTiles,
            sizeBytes: sizeBytes,
            errorMessage: errorMessage,
            filePath: filePath,
            serverRegionId: serverRegionId,
            regionType: regionType,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflineRegionTableTableProcessedTableManager = ProcessedTableManager<
    _$CacheDatabase,
    $OfflineRegionTableTable,
    OfflineRegionTableData,
    $$OfflineRegionTableTableFilterComposer,
    $$OfflineRegionTableTableOrderingComposer,
    $$OfflineRegionTableTableAnnotationComposer,
    $$OfflineRegionTableTableCreateCompanionBuilder,
    $$OfflineRegionTableTableUpdateCompanionBuilder,
    (
      OfflineRegionTableData,
      BaseReferences<_$CacheDatabase, $OfflineRegionTableTable,
          OfflineRegionTableData>
    ),
    OfflineRegionTableData,
    PrefetchHooks Function()>;

class $CacheDatabaseManager {
  final _$CacheDatabase _db;
  $CacheDatabaseManager(this._db);
  $$GeocodeCacheTableTableTableManager get geocodeCacheTable =>
      $$GeocodeCacheTableTableTableManager(_db, _db.geocodeCacheTable);
  $$ReverseCacheTableTableTableManager get reverseCacheTable =>
      $$ReverseCacheTableTableTableManager(_db, _db.reverseCacheTable);
  $$RouteCacheTableTableTableManager get routeCacheTable =>
      $$RouteCacheTableTableTableManager(_db, _db.routeCacheTable);
  $$SmartSearchCacheTableTableTableManager get smartSearchCacheTable =>
      $$SmartSearchCacheTableTableTableManager(_db, _db.smartSearchCacheTable);
  $$OfflineRegionTableTableTableManager get offlineRegionTable =>
      $$OfflineRegionTableTableTableManager(_db, _db.offlineRegionTable);
}
