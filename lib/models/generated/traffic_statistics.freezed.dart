// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../traffic_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrafficRankItem {

 String get key; int get upload; int get download; double get percent;
/// Create a copy of TrafficRankItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrafficRankItemCopyWith<TrafficRankItem> get copyWith => _$TrafficRankItemCopyWithImpl<TrafficRankItem>(this as TrafficRankItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrafficRankItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrafficRankItem&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.upload, _this.upload) || other.upload == _this.upload)&&(identical(other.download, _this.download) || other.download == _this.download)&&(identical(other.percent, _this.percent) || other.percent == _this.percent));
}


@override
int get hashCode {
  final _this = this as TrafficRankItem;
  return Object.hash(runtimeType,_this.key,_this.upload,_this.download,_this.percent);
}

@override
String toString() {
  final _this = this as TrafficRankItem;
  return 'TrafficRankItem(key: ${_this.key}, upload: ${_this.upload}, download: ${_this.download}, percent: ${_this.percent})';
}


}

/// @nodoc
abstract mixin class $TrafficRankItemCopyWith<$Res>  {
  factory $TrafficRankItemCopyWith(TrafficRankItem value, $Res Function(TrafficRankItem) _then) = _$TrafficRankItemCopyWithImpl;
@useResult
$Res call({
 String key, int upload, int download, double percent
});




}
/// @nodoc
class _$TrafficRankItemCopyWithImpl<$Res>
    implements $TrafficRankItemCopyWith<$Res> {
  _$TrafficRankItemCopyWithImpl(this._self, this._then);

  final TrafficRankItem _self;
  final $Res Function(TrafficRankItem) _then;

/// Create a copy of TrafficRankItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? upload = null,Object? download = null,Object? percent = null,}) {
  return _then(TrafficRankItem(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TrafficRankItem].
extension TrafficRankItemPatterns on TrafficRankItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrafficRankItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrafficRankItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrafficRankItem value)  $default,){
final _that = this;
switch (_that) {
case _TrafficRankItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrafficRankItem value)?  $default,){
final _that = this;
switch (_that) {
case _TrafficRankItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  int upload,  int download,  double percent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrafficRankItem() when $default != null:
return $default(_that.key,_that.upload,_that.download,_that.percent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  int upload,  int download,  double percent)  $default,) {final _that = this;
switch (_that) {
case _TrafficRankItem():
return $default(_that.key,_that.upload,_that.download,_that.percent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  int upload,  int download,  double percent)?  $default,) {final _that = this;
switch (_that) {
case _TrafficRankItem() when $default != null:
return $default(_that.key,_that.upload,_that.download,_that.percent);case _:
  return null;

}
}

}

/// @nodoc


class _TrafficRankItem implements TrafficRankItem {
  const _TrafficRankItem({required this.key, required this.upload, required this.download, required this.percent});
  

@override final  String key;
@override final  int upload;
@override final  int download;
@override final  double percent;

/// Create a copy of TrafficRankItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrafficRankItemCopyWith<_TrafficRankItem> get copyWith => __$TrafficRankItemCopyWithImpl<_TrafficRankItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrafficRankItem&&(identical(other.key, key) || other.key == key)&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.percent, percent) || other.percent == percent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,upload,download,percent);
}

@override
String toString() {
    return 'TrafficRankItem(key: $key, upload: $upload, download: $download, percent: $percent)';
}


}

/// @nodoc
abstract mixin class _$TrafficRankItemCopyWith<$Res> implements $TrafficRankItemCopyWith<$Res> {
  factory _$TrafficRankItemCopyWith(_TrafficRankItem value, $Res Function(_TrafficRankItem) _then) = __$TrafficRankItemCopyWithImpl;
@override @useResult
$Res call({
 String key, int upload, int download, double percent
});




}
/// @nodoc
class __$TrafficRankItemCopyWithImpl<$Res>
    implements _$TrafficRankItemCopyWith<$Res> {
  __$TrafficRankItemCopyWithImpl(this._self, this._then);

  final _TrafficRankItem _self;
  final $Res Function(_TrafficRankItem) _then;

/// Create a copy of TrafficRankItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? upload = null,Object? download = null,Object? percent = null,}) {
  return _then(_TrafficRankItem(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$RuleHit {

 String get key; int get hits; int get upload; int get download; double get percent;
/// Create a copy of RuleHit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleHitCopyWith<RuleHit> get copyWith => _$RuleHitCopyWithImpl<RuleHit>(this as RuleHit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RuleHit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuleHit&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.hits, _this.hits) || other.hits == _this.hits)&&(identical(other.upload, _this.upload) || other.upload == _this.upload)&&(identical(other.download, _this.download) || other.download == _this.download)&&(identical(other.percent, _this.percent) || other.percent == _this.percent));
}


@override
int get hashCode {
  final _this = this as RuleHit;
  return Object.hash(runtimeType,_this.key,_this.hits,_this.upload,_this.download,_this.percent);
}

@override
String toString() {
  final _this = this as RuleHit;
  return 'RuleHit(key: ${_this.key}, hits: ${_this.hits}, upload: ${_this.upload}, download: ${_this.download}, percent: ${_this.percent})';
}


}

/// @nodoc
abstract mixin class $RuleHitCopyWith<$Res>  {
  factory $RuleHitCopyWith(RuleHit value, $Res Function(RuleHit) _then) = _$RuleHitCopyWithImpl;
@useResult
$Res call({
 String key, int hits, int upload, int download, double percent
});




}
/// @nodoc
class _$RuleHitCopyWithImpl<$Res>
    implements $RuleHitCopyWith<$Res> {
  _$RuleHitCopyWithImpl(this._self, this._then);

  final RuleHit _self;
  final $Res Function(RuleHit) _then;

/// Create a copy of RuleHit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? hits = null,Object? upload = null,Object? download = null,Object? percent = null,}) {
  return _then(RuleHit(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RuleHit].
extension RuleHitPatterns on RuleHit {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuleHit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuleHit() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuleHit value)  $default,){
final _that = this;
switch (_that) {
case _RuleHit():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuleHit value)?  $default,){
final _that = this;
switch (_that) {
case _RuleHit() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  int hits,  int upload,  int download,  double percent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuleHit() when $default != null:
return $default(_that.key,_that.hits,_that.upload,_that.download,_that.percent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  int hits,  int upload,  int download,  double percent)  $default,) {final _that = this;
switch (_that) {
case _RuleHit():
return $default(_that.key,_that.hits,_that.upload,_that.download,_that.percent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  int hits,  int upload,  int download,  double percent)?  $default,) {final _that = this;
switch (_that) {
case _RuleHit() when $default != null:
return $default(_that.key,_that.hits,_that.upload,_that.download,_that.percent);case _:
  return null;

}
}

}

/// @nodoc


class _RuleHit implements RuleHit {
  const _RuleHit({required this.key, required this.hits, required this.upload, required this.download, required this.percent});
  

@override final  String key;
@override final  int hits;
@override final  int upload;
@override final  int download;
@override final  double percent;

/// Create a copy of RuleHit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleHitCopyWith<_RuleHit> get copyWith => __$RuleHitCopyWithImpl<_RuleHit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuleHit&&(identical(other.key, key) || other.key == key)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.percent, percent) || other.percent == percent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,hits,upload,download,percent);
}

@override
String toString() {
    return 'RuleHit(key: $key, hits: $hits, upload: $upload, download: $download, percent: $percent)';
}


}

/// @nodoc
abstract mixin class _$RuleHitCopyWith<$Res> implements $RuleHitCopyWith<$Res> {
  factory _$RuleHitCopyWith(_RuleHit value, $Res Function(_RuleHit) _then) = __$RuleHitCopyWithImpl;
@override @useResult
$Res call({
 String key, int hits, int upload, int download, double percent
});




}
/// @nodoc
class __$RuleHitCopyWithImpl<$Res>
    implements _$RuleHitCopyWith<$Res> {
  __$RuleHitCopyWithImpl(this._self, this._then);

  final _RuleHit _self;
  final $Res Function(_RuleHit) _then;

/// Create a copy of RuleHit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? hits = null,Object? upload = null,Object? download = null,Object? percent = null,}) {
  return _then(_RuleHit(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$TrafficStatistics {

 int get totalUpload; int get totalDownload; int get connectionCount; List<RuleHit> get ruleHits; List<TrafficRankItem> get ranking;
/// Create a copy of TrafficStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrafficStatisticsCopyWith<TrafficStatistics> get copyWith => _$TrafficStatisticsCopyWithImpl<TrafficStatistics>(this as TrafficStatistics, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrafficStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrafficStatistics&&(identical(other.totalUpload, _this.totalUpload) || other.totalUpload == _this.totalUpload)&&(identical(other.totalDownload, _this.totalDownload) || other.totalDownload == _this.totalDownload)&&(identical(other.connectionCount, _this.connectionCount) || other.connectionCount == _this.connectionCount)&&const DeepCollectionEquality().equals(other.ruleHits, _this.ruleHits)&&const DeepCollectionEquality().equals(other.ranking, _this.ranking));
}


@override
int get hashCode {
  final _this = this as TrafficStatistics;
  return Object.hash(runtimeType,_this.totalUpload,_this.totalDownload,_this.connectionCount,const DeepCollectionEquality().hash(_this.ruleHits),const DeepCollectionEquality().hash(_this.ranking));
}

@override
String toString() {
  final _this = this as TrafficStatistics;
  return 'TrafficStatistics(totalUpload: ${_this.totalUpload}, totalDownload: ${_this.totalDownload}, connectionCount: ${_this.connectionCount}, ruleHits: ${_this.ruleHits}, ranking: ${_this.ranking})';
}


}

/// @nodoc
abstract mixin class $TrafficStatisticsCopyWith<$Res>  {
  factory $TrafficStatisticsCopyWith(TrafficStatistics value, $Res Function(TrafficStatistics) _then) = _$TrafficStatisticsCopyWithImpl;
@useResult
$Res call({
 int totalUpload, int totalDownload, int connectionCount, List<RuleHit> ruleHits, List<TrafficRankItem> ranking
});




}
/// @nodoc
class _$TrafficStatisticsCopyWithImpl<$Res>
    implements $TrafficStatisticsCopyWith<$Res> {
  _$TrafficStatisticsCopyWithImpl(this._self, this._then);

  final TrafficStatistics _self;
  final $Res Function(TrafficStatistics) _then;

/// Create a copy of TrafficStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalUpload = null,Object? totalDownload = null,Object? connectionCount = null,Object? ruleHits = null,Object? ranking = null,}) {
  return _then(TrafficStatistics(
totalUpload: null == totalUpload ? _self.totalUpload : totalUpload // ignore: cast_nullable_to_non_nullable
as int,totalDownload: null == totalDownload ? _self.totalDownload : totalDownload // ignore: cast_nullable_to_non_nullable
as int,connectionCount: null == connectionCount ? _self.connectionCount : connectionCount // ignore: cast_nullable_to_non_nullable
as int,ruleHits: null == ruleHits ? _self.ruleHits : ruleHits // ignore: cast_nullable_to_non_nullable
as List<RuleHit>,ranking: null == ranking ? _self.ranking : ranking // ignore: cast_nullable_to_non_nullable
as List<TrafficRankItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrafficStatistics].
extension TrafficStatisticsPatterns on TrafficStatistics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrafficStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrafficStatistics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrafficStatistics value)  $default,){
final _that = this;
switch (_that) {
case _TrafficStatistics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrafficStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _TrafficStatistics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalUpload,  int totalDownload,  int connectionCount,  List<RuleHit> ruleHits,  List<TrafficRankItem> ranking)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrafficStatistics() when $default != null:
return $default(_that.totalUpload,_that.totalDownload,_that.connectionCount,_that.ruleHits,_that.ranking);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalUpload,  int totalDownload,  int connectionCount,  List<RuleHit> ruleHits,  List<TrafficRankItem> ranking)  $default,) {final _that = this;
switch (_that) {
case _TrafficStatistics():
return $default(_that.totalUpload,_that.totalDownload,_that.connectionCount,_that.ruleHits,_that.ranking);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalUpload,  int totalDownload,  int connectionCount,  List<RuleHit> ruleHits,  List<TrafficRankItem> ranking)?  $default,) {final _that = this;
switch (_that) {
case _TrafficStatistics() when $default != null:
return $default(_that.totalUpload,_that.totalDownload,_that.connectionCount,_that.ruleHits,_that.ranking);case _:
  return null;

}
}

}

/// @nodoc


class _TrafficStatistics implements TrafficStatistics {
  const _TrafficStatistics({required this.totalUpload, required this.totalDownload, required this.connectionCount, required  List<RuleHit> ruleHits, required  List<TrafficRankItem> ranking}): _ruleHits = ruleHits,_ranking = ranking;
  

@override final  int totalUpload;
@override final  int totalDownload;
@override final  int connectionCount;
 final  List<RuleHit> _ruleHits;
@override List<RuleHit> get ruleHits {
  if (_ruleHits is EqualUnmodifiableListView) return _ruleHits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ruleHits);
}

 final  List<TrafficRankItem> _ranking;
@override List<TrafficRankItem> get ranking {
  if (_ranking is EqualUnmodifiableListView) return _ranking;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ranking);
}


/// Create a copy of TrafficStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrafficStatisticsCopyWith<_TrafficStatistics> get copyWith => __$TrafficStatisticsCopyWithImpl<_TrafficStatistics>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrafficStatistics&&(identical(other.totalUpload, totalUpload) || other.totalUpload == totalUpload)&&(identical(other.totalDownload, totalDownload) || other.totalDownload == totalDownload)&&(identical(other.connectionCount, connectionCount) || other.connectionCount == connectionCount)&&const DeepCollectionEquality().equals(other.ruleHits, _ruleHits)&&const DeepCollectionEquality().equals(other.ranking, _ranking));
}


@override
int get hashCode {
    return Object.hash(runtimeType,totalUpload,totalDownload,connectionCount,const DeepCollectionEquality().hash(_ruleHits),const DeepCollectionEquality().hash(_ranking));
}

@override
String toString() {
    return 'TrafficStatistics(totalUpload: $totalUpload, totalDownload: $totalDownload, connectionCount: $connectionCount, ruleHits: $ruleHits, ranking: $ranking)';
}


}

/// @nodoc
abstract mixin class _$TrafficStatisticsCopyWith<$Res> implements $TrafficStatisticsCopyWith<$Res> {
  factory _$TrafficStatisticsCopyWith(_TrafficStatistics value, $Res Function(_TrafficStatistics) _then) = __$TrafficStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int totalUpload, int totalDownload, int connectionCount, List<RuleHit> ruleHits, List<TrafficRankItem> ranking
});




}
/// @nodoc
class __$TrafficStatisticsCopyWithImpl<$Res>
    implements _$TrafficStatisticsCopyWith<$Res> {
  __$TrafficStatisticsCopyWithImpl(this._self, this._then);

  final _TrafficStatistics _self;
  final $Res Function(_TrafficStatistics) _then;

/// Create a copy of TrafficStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalUpload = null,Object? totalDownload = null,Object? connectionCount = null,Object? ruleHits = null,Object? ranking = null,}) {
  return _then(_TrafficStatistics(
totalUpload: null == totalUpload ? _self.totalUpload : totalUpload // ignore: cast_nullable_to_non_nullable
as int,totalDownload: null == totalDownload ? _self.totalDownload : totalDownload // ignore: cast_nullable_to_non_nullable
as int,connectionCount: null == connectionCount ? _self.connectionCount : connectionCount // ignore: cast_nullable_to_non_nullable
as int,ruleHits: null == ruleHits ? _self._ruleHits : ruleHits // ignore: cast_nullable_to_non_nullable
as List<RuleHit>,ranking: null == ranking ? _self._ranking : ranking // ignore: cast_nullable_to_non_nullable
as List<TrafficRankItem>,
  ));
}


}

// dart format on
