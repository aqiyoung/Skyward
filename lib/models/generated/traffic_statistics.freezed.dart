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
mixin _$TrafficHourPoint {

 DateTime get hour; int get download; int get upload;
/// Create a copy of TrafficHourPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrafficHourPointCopyWith<TrafficHourPoint> get copyWith => _$TrafficHourPointCopyWithImpl<TrafficHourPoint>(this as TrafficHourPoint, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrafficHourPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrafficHourPoint&&(identical(other.hour, _this.hour) || other.hour == _this.hour)&&(identical(other.download, _this.download) || other.download == _this.download)&&(identical(other.upload, _this.upload) || other.upload == _this.upload));
}


@override
int get hashCode {
  final _this = this as TrafficHourPoint;
  return Object.hash(runtimeType,_this.hour,_this.download,_this.upload);
}

@override
String toString() {
  final _this = this as TrafficHourPoint;
  return 'TrafficHourPoint(hour: ${_this.hour}, download: ${_this.download}, upload: ${_this.upload})';
}


}

/// @nodoc
abstract mixin class $TrafficHourPointCopyWith<$Res>  {
  factory $TrafficHourPointCopyWith(TrafficHourPoint value, $Res Function(TrafficHourPoint) _then) = _$TrafficHourPointCopyWithImpl;
@useResult
$Res call({
 DateTime hour, int download, int upload
});




}
/// @nodoc
class _$TrafficHourPointCopyWithImpl<$Res>
    implements $TrafficHourPointCopyWith<$Res> {
  _$TrafficHourPointCopyWithImpl(this._self, this._then);

  final TrafficHourPoint _self;
  final $Res Function(TrafficHourPoint) _then;

/// Create a copy of TrafficHourPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hour = null,Object? download = null,Object? upload = null,}) {
  return _then(TrafficHourPoint(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as DateTime,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TrafficHourPoint].
extension TrafficHourPointPatterns on TrafficHourPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrafficHourPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrafficHourPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrafficHourPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrafficHourPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrafficHourPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrafficHourPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime hour,  int download,  int upload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrafficHourPoint() when $default != null:
return $default(_that.hour,_that.download,_that.upload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime hour,  int download,  int upload)  $default,) {final _that = this;
switch (_that) {
case _TrafficHourPoint():
return $default(_that.hour,_that.download,_that.upload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime hour,  int download,  int upload)?  $default,) {final _that = this;
switch (_that) {
case _TrafficHourPoint() when $default != null:
return $default(_that.hour,_that.download,_that.upload);case _:
  return null;

}
}

}

/// @nodoc


class _TrafficHourPoint implements TrafficHourPoint {
  const _TrafficHourPoint({required this.hour, required this.download, required this.upload});
  

@override final  DateTime hour;
@override final  int download;
@override final  int upload;

/// Create a copy of TrafficHourPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrafficHourPointCopyWith<_TrafficHourPoint> get copyWith => __$TrafficHourPointCopyWithImpl<_TrafficHourPoint>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrafficHourPoint&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.download, download) || other.download == download)&&(identical(other.upload, upload) || other.upload == upload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,hour,download,upload);
}

@override
String toString() {
    return 'TrafficHourPoint(hour: $hour, download: $download, upload: $upload)';
}


}

/// @nodoc
abstract mixin class _$TrafficHourPointCopyWith<$Res> implements $TrafficHourPointCopyWith<$Res> {
  factory _$TrafficHourPointCopyWith(_TrafficHourPoint value, $Res Function(_TrafficHourPoint) _then) = __$TrafficHourPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime hour, int download, int upload
});




}
/// @nodoc
class __$TrafficHourPointCopyWithImpl<$Res>
    implements _$TrafficHourPointCopyWith<$Res> {
  __$TrafficHourPointCopyWithImpl(this._self, this._then);

  final _TrafficHourPoint _self;
  final $Res Function(_TrafficHourPoint) _then;

/// Create a copy of TrafficHourPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hour = null,Object? download = null,Object? upload = null,}) {
  return _then(_TrafficHourPoint(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as DateTime,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TrafficStatistics {

 int get totalUpload; int get totalDownload; int get connectionCount; int get proxyBytes; int get directBytes; List<RuleHit> get ruleHits; List<TrafficRankItem> get ranking; List<TrafficHourPoint> get trend;
/// Create a copy of TrafficStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrafficStatisticsCopyWith<TrafficStatistics> get copyWith => _$TrafficStatisticsCopyWithImpl<TrafficStatistics>(this as TrafficStatistics, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrafficStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrafficStatistics&&(identical(other.totalUpload, _this.totalUpload) || other.totalUpload == _this.totalUpload)&&(identical(other.totalDownload, _this.totalDownload) || other.totalDownload == _this.totalDownload)&&(identical(other.connectionCount, _this.connectionCount) || other.connectionCount == _this.connectionCount)&&(identical(other.proxyBytes, _this.proxyBytes) || other.proxyBytes == _this.proxyBytes)&&(identical(other.directBytes, _this.directBytes) || other.directBytes == _this.directBytes)&&const DeepCollectionEquality().equals(other.ruleHits, _this.ruleHits)&&const DeepCollectionEquality().equals(other.ranking, _this.ranking)&&const DeepCollectionEquality().equals(other.trend, _this.trend));
}


@override
int get hashCode {
  final _this = this as TrafficStatistics;
  return Object.hash(runtimeType,_this.totalUpload,_this.totalDownload,_this.connectionCount,_this.proxyBytes,_this.directBytes,const DeepCollectionEquality().hash(_this.ruleHits),const DeepCollectionEquality().hash(_this.ranking),const DeepCollectionEquality().hash(_this.trend));
}

@override
String toString() {
  final _this = this as TrafficStatistics;
  return 'TrafficStatistics(totalUpload: ${_this.totalUpload}, totalDownload: ${_this.totalDownload}, connectionCount: ${_this.connectionCount}, proxyBytes: ${_this.proxyBytes}, directBytes: ${_this.directBytes}, ruleHits: ${_this.ruleHits}, ranking: ${_this.ranking}, trend: ${_this.trend})';
}


}

/// @nodoc
abstract mixin class $TrafficStatisticsCopyWith<$Res>  {
  factory $TrafficStatisticsCopyWith(TrafficStatistics value, $Res Function(TrafficStatistics) _then) = _$TrafficStatisticsCopyWithImpl;
@useResult
$Res call({
 int totalUpload, int totalDownload, int connectionCount, int proxyBytes, int directBytes, List<RuleHit> ruleHits, List<TrafficRankItem> ranking, List<TrafficHourPoint> trend
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
@pragma('vm:prefer-inline') @override $Res call({Object? totalUpload = null,Object? totalDownload = null,Object? connectionCount = null,Object? proxyBytes = null,Object? directBytes = null,Object? ruleHits = null,Object? ranking = null,Object? trend = null,}) {
  return _then(TrafficStatistics(
totalUpload: null == totalUpload ? _self.totalUpload : totalUpload // ignore: cast_nullable_to_non_nullable
as int,totalDownload: null == totalDownload ? _self.totalDownload : totalDownload // ignore: cast_nullable_to_non_nullable
as int,connectionCount: null == connectionCount ? _self.connectionCount : connectionCount // ignore: cast_nullable_to_non_nullable
as int,proxyBytes: null == proxyBytes ? _self.proxyBytes : proxyBytes // ignore: cast_nullable_to_non_nullable
as int,directBytes: null == directBytes ? _self.directBytes : directBytes // ignore: cast_nullable_to_non_nullable
as int,ruleHits: null == ruleHits ? _self.ruleHits : ruleHits // ignore: cast_nullable_to_non_nullable
as List<RuleHit>,ranking: null == ranking ? _self.ranking : ranking // ignore: cast_nullable_to_non_nullable
as List<TrafficRankItem>,trend: null == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as List<TrafficHourPoint>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalUpload,  int totalDownload,  int connectionCount,  int proxyBytes,  int directBytes,  List<RuleHit> ruleHits,  List<TrafficRankItem> ranking,  List<TrafficHourPoint> trend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrafficStatistics() when $default != null:
return $default(_that.totalUpload,_that.totalDownload,_that.connectionCount,_that.proxyBytes,_that.directBytes,_that.ruleHits,_that.ranking,_that.trend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalUpload,  int totalDownload,  int connectionCount,  int proxyBytes,  int directBytes,  List<RuleHit> ruleHits,  List<TrafficRankItem> ranking,  List<TrafficHourPoint> trend)  $default,) {final _that = this;
switch (_that) {
case _TrafficStatistics():
return $default(_that.totalUpload,_that.totalDownload,_that.connectionCount,_that.proxyBytes,_that.directBytes,_that.ruleHits,_that.ranking,_that.trend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalUpload,  int totalDownload,  int connectionCount,  int proxyBytes,  int directBytes,  List<RuleHit> ruleHits,  List<TrafficRankItem> ranking,  List<TrafficHourPoint> trend)?  $default,) {final _that = this;
switch (_that) {
case _TrafficStatistics() when $default != null:
return $default(_that.totalUpload,_that.totalDownload,_that.connectionCount,_that.proxyBytes,_that.directBytes,_that.ruleHits,_that.ranking,_that.trend);case _:
  return null;

}
}

}

/// @nodoc


class _TrafficStatistics implements TrafficStatistics {
  const _TrafficStatistics({required this.totalUpload, required this.totalDownload, required this.connectionCount, required this.proxyBytes, required this.directBytes, required  List<RuleHit> ruleHits, required  List<TrafficRankItem> ranking, required  List<TrafficHourPoint> trend}): _ruleHits = ruleHits,_ranking = ranking,_trend = trend;
  

@override final  int totalUpload;
@override final  int totalDownload;
@override final  int connectionCount;
@override final  int proxyBytes;
@override final  int directBytes;
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

 final  List<TrafficHourPoint> _trend;
@override List<TrafficHourPoint> get trend {
  if (_trend is EqualUnmodifiableListView) return _trend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trend);
}


/// Create a copy of TrafficStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrafficStatisticsCopyWith<_TrafficStatistics> get copyWith => __$TrafficStatisticsCopyWithImpl<_TrafficStatistics>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrafficStatistics&&(identical(other.totalUpload, totalUpload) || other.totalUpload == totalUpload)&&(identical(other.totalDownload, totalDownload) || other.totalDownload == totalDownload)&&(identical(other.connectionCount, connectionCount) || other.connectionCount == connectionCount)&&(identical(other.proxyBytes, proxyBytes) || other.proxyBytes == proxyBytes)&&(identical(other.directBytes, directBytes) || other.directBytes == directBytes)&&const DeepCollectionEquality().equals(other.ruleHits, _ruleHits)&&const DeepCollectionEquality().equals(other.ranking, _ranking)&&const DeepCollectionEquality().equals(other.trend, _trend));
}


@override
int get hashCode {
    return Object.hash(runtimeType,totalUpload,totalDownload,connectionCount,proxyBytes,directBytes,const DeepCollectionEquality().hash(_ruleHits),const DeepCollectionEquality().hash(_ranking),const DeepCollectionEquality().hash(_trend));
}

@override
String toString() {
    return 'TrafficStatistics(totalUpload: $totalUpload, totalDownload: $totalDownload, connectionCount: $connectionCount, proxyBytes: $proxyBytes, directBytes: $directBytes, ruleHits: $ruleHits, ranking: $ranking, trend: $trend)';
}


}

/// @nodoc
abstract mixin class _$TrafficStatisticsCopyWith<$Res> implements $TrafficStatisticsCopyWith<$Res> {
  factory _$TrafficStatisticsCopyWith(_TrafficStatistics value, $Res Function(_TrafficStatistics) _then) = __$TrafficStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int totalUpload, int totalDownload, int connectionCount, int proxyBytes, int directBytes, List<RuleHit> ruleHits, List<TrafficRankItem> ranking, List<TrafficHourPoint> trend
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
@override @pragma('vm:prefer-inline') $Res call({Object? totalUpload = null,Object? totalDownload = null,Object? connectionCount = null,Object? proxyBytes = null,Object? directBytes = null,Object? ruleHits = null,Object? ranking = null,Object? trend = null,}) {
  return _then(_TrafficStatistics(
totalUpload: null == totalUpload ? _self.totalUpload : totalUpload // ignore: cast_nullable_to_non_nullable
as int,totalDownload: null == totalDownload ? _self.totalDownload : totalDownload // ignore: cast_nullable_to_non_nullable
as int,connectionCount: null == connectionCount ? _self.connectionCount : connectionCount // ignore: cast_nullable_to_non_nullable
as int,proxyBytes: null == proxyBytes ? _self.proxyBytes : proxyBytes // ignore: cast_nullable_to_non_nullable
as int,directBytes: null == directBytes ? _self.directBytes : directBytes // ignore: cast_nullable_to_non_nullable
as int,ruleHits: null == ruleHits ? _self._ruleHits : ruleHits // ignore: cast_nullable_to_non_nullable
as List<RuleHit>,ranking: null == ranking ? _self._ranking : ranking // ignore: cast_nullable_to_non_nullable
as List<TrafficRankItem>,trend: null == trend ? _self._trend : trend // ignore: cast_nullable_to_non_nullable
as List<TrafficHourPoint>,
  ));
}


}

// dart format on
