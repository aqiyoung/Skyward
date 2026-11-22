// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../chain.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChainSpec {

 int get id; String get name; List<String> get hops; bool get offered;@JsonKey(name: 'target-group') String? get targetGroup; bool get heal;
/// Create a copy of ChainSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChainSpecCopyWith<ChainSpec> get copyWith => _$ChainSpecCopyWithImpl<ChainSpec>(this as ChainSpec, _$identity);

  /// Serializes this ChainSpec to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChainSpec;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChainSpec&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.hops, _this.hops)&&(identical(other.offered, _this.offered) || other.offered == _this.offered)&&(identical(other.targetGroup, _this.targetGroup) || other.targetGroup == _this.targetGroup)&&(identical(other.heal, _this.heal) || other.heal == _this.heal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChainSpec;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.hops),_this.offered,_this.targetGroup,_this.heal);
}

@override
String toString() {
  final _this = this as ChainSpec;
  return 'ChainSpec(id: ${_this.id}, name: ${_this.name}, hops: ${_this.hops}, offered: ${_this.offered}, targetGroup: ${_this.targetGroup}, heal: ${_this.heal})';
}


}

/// @nodoc
abstract mixin class $ChainSpecCopyWith<$Res>  {
  factory $ChainSpecCopyWith(ChainSpec value, $Res Function(ChainSpec) _then) = _$ChainSpecCopyWithImpl;
@useResult
$Res call({
 int id, String name, List<String> hops, bool offered,@JsonKey(name: 'target-group') String? targetGroup, bool heal
});




}
/// @nodoc
class _$ChainSpecCopyWithImpl<$Res>
    implements $ChainSpecCopyWith<$Res> {
  _$ChainSpecCopyWithImpl(this._self, this._then);

  final ChainSpec _self;
  final $Res Function(ChainSpec) _then;

/// Create a copy of ChainSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? hops = null,Object? offered = null,Object? targetGroup = freezed,Object? heal = null,}) {
  return _then(ChainSpec(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hops: null == hops ? _self.hops : hops // ignore: cast_nullable_to_non_nullable
as List<String>,offered: null == offered ? _self.offered : offered // ignore: cast_nullable_to_non_nullable
as bool,targetGroup: freezed == targetGroup ? _self.targetGroup : targetGroup // ignore: cast_nullable_to_non_nullable
as String?,heal: null == heal ? _self.heal : heal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChainSpec].
extension ChainSpecPatterns on ChainSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChainSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChainSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChainSpec value)  $default,){
final _that = this;
switch (_that) {
case _ChainSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChainSpec value)?  $default,){
final _that = this;
switch (_that) {
case _ChainSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  List<String> hops,  bool offered, @JsonKey(name: 'target-group')  String? targetGroup,  bool heal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChainSpec() when $default != null:
return $default(_that.id,_that.name,_that.hops,_that.offered,_that.targetGroup,_that.heal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  List<String> hops,  bool offered, @JsonKey(name: 'target-group')  String? targetGroup,  bool heal)  $default,) {final _that = this;
switch (_that) {
case _ChainSpec():
return $default(_that.id,_that.name,_that.hops,_that.offered,_that.targetGroup,_that.heal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  List<String> hops,  bool offered, @JsonKey(name: 'target-group')  String? targetGroup,  bool heal)?  $default,) {final _that = this;
switch (_that) {
case _ChainSpec() when $default != null:
return $default(_that.id,_that.name,_that.hops,_that.offered,_that.targetGroup,_that.heal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChainSpec implements ChainSpec {
  const _ChainSpec({required this.id, required this.name, required  List<String> hops, this.offered = true, @JsonKey(name: 'target-group') this.targetGroup, this.heal = false}): _hops = hops;
  factory _ChainSpec.fromJson(Map<String, dynamic> json) => _$ChainSpecFromJson(json);

@override final  int id;
@override final  String name;
 final  List<String> _hops;
@override List<String> get hops {
  if (_hops is EqualUnmodifiableListView) return _hops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hops);
}

@override@JsonKey() final  bool offered;
@override@JsonKey(name: 'target-group') final  String? targetGroup;
@override@JsonKey() final  bool heal;

/// Create a copy of ChainSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChainSpecCopyWith<_ChainSpec> get copyWith => __$ChainSpecCopyWithImpl<_ChainSpec>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChainSpecToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChainSpec&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.hops, _hops)&&(identical(other.offered, offered) || other.offered == offered)&&(identical(other.targetGroup, targetGroup) || other.targetGroup == targetGroup)&&(identical(other.heal, heal) || other.heal == heal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_hops),offered,targetGroup,heal);
}

@override
String toString() {
    return 'ChainSpec(id: $id, name: $name, hops: $hops, offered: $offered, targetGroup: $targetGroup, heal: $heal)';
}


}

/// @nodoc
abstract mixin class _$ChainSpecCopyWith<$Res> implements $ChainSpecCopyWith<$Res> {
  factory _$ChainSpecCopyWith(_ChainSpec value, $Res Function(_ChainSpec) _then) = __$ChainSpecCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, List<String> hops, bool offered,@JsonKey(name: 'target-group') String? targetGroup, bool heal
});




}
/// @nodoc
class __$ChainSpecCopyWithImpl<$Res>
    implements _$ChainSpecCopyWith<$Res> {
  __$ChainSpecCopyWithImpl(this._self, this._then);

  final _ChainSpec _self;
  final $Res Function(_ChainSpec) _then;

/// Create a copy of ChainSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? hops = null,Object? offered = null,Object? targetGroup = freezed,Object? heal = null,}) {
  return _then(_ChainSpec(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hops: null == hops ? _self._hops : hops // ignore: cast_nullable_to_non_nullable
as List<String>,offered: null == offered ? _self.offered : offered // ignore: cast_nullable_to_non_nullable
as bool,targetGroup: freezed == targetGroup ? _self.targetGroup : targetGroup // ignore: cast_nullable_to_non_nullable
as String?,heal: null == heal ? _self.heal : heal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ChainReport {

 String get name; String get status; List<String> get hops;@JsonKey(name: 'targetGroup') String? get targetGroup;
/// Create a copy of ChainReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChainReportCopyWith<ChainReport> get copyWith => _$ChainReportCopyWithImpl<ChainReport>(this as ChainReport, _$identity);

  /// Serializes this ChainReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChainReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChainReport&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.hops, _this.hops)&&(identical(other.targetGroup, _this.targetGroup) || other.targetGroup == _this.targetGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChainReport;
  return Object.hash(runtimeType,_this.name,_this.status,const DeepCollectionEquality().hash(_this.hops),_this.targetGroup);
}

@override
String toString() {
  final _this = this as ChainReport;
  return 'ChainReport(name: ${_this.name}, status: ${_this.status}, hops: ${_this.hops}, targetGroup: ${_this.targetGroup})';
}


}

/// @nodoc
abstract mixin class $ChainReportCopyWith<$Res>  {
  factory $ChainReportCopyWith(ChainReport value, $Res Function(ChainReport) _then) = _$ChainReportCopyWithImpl;
@useResult
$Res call({
 String name, String status, List<String> hops,@JsonKey(name: 'targetGroup') String? targetGroup
});




}
/// @nodoc
class _$ChainReportCopyWithImpl<$Res>
    implements $ChainReportCopyWith<$Res> {
  _$ChainReportCopyWithImpl(this._self, this._then);

  final ChainReport _self;
  final $Res Function(ChainReport) _then;

/// Create a copy of ChainReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? status = null,Object? hops = null,Object? targetGroup = freezed,}) {
  return _then(ChainReport(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,hops: null == hops ? _self.hops : hops // ignore: cast_nullable_to_non_nullable
as List<String>,targetGroup: freezed == targetGroup ? _self.targetGroup : targetGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChainReport].
extension ChainReportPatterns on ChainReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChainReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChainReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChainReport value)  $default,){
final _that = this;
switch (_that) {
case _ChainReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChainReport value)?  $default,){
final _that = this;
switch (_that) {
case _ChainReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String status,  List<String> hops, @JsonKey(name: 'targetGroup')  String? targetGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChainReport() when $default != null:
return $default(_that.name,_that.status,_that.hops,_that.targetGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String status,  List<String> hops, @JsonKey(name: 'targetGroup')  String? targetGroup)  $default,) {final _that = this;
switch (_that) {
case _ChainReport():
return $default(_that.name,_that.status,_that.hops,_that.targetGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String status,  List<String> hops, @JsonKey(name: 'targetGroup')  String? targetGroup)?  $default,) {final _that = this;
switch (_that) {
case _ChainReport() when $default != null:
return $default(_that.name,_that.status,_that.hops,_that.targetGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChainReport implements ChainReport {
  const _ChainReport({required this.name, required this.status, required  List<String> hops, @JsonKey(name: 'targetGroup') this.targetGroup}): _hops = hops;
  factory _ChainReport.fromJson(Map<String, dynamic> json) => _$ChainReportFromJson(json);

@override final  String name;
@override final  String status;
 final  List<String> _hops;
@override List<String> get hops {
  if (_hops is EqualUnmodifiableListView) return _hops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hops);
}

@override@JsonKey(name: 'targetGroup') final  String? targetGroup;

/// Create a copy of ChainReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChainReportCopyWith<_ChainReport> get copyWith => __$ChainReportCopyWithImpl<_ChainReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChainReportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChainReport&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.hops, _hops)&&(identical(other.targetGroup, targetGroup) || other.targetGroup == targetGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,status,const DeepCollectionEquality().hash(_hops),targetGroup);
}

@override
String toString() {
    return 'ChainReport(name: $name, status: $status, hops: $hops, targetGroup: $targetGroup)';
}


}

/// @nodoc
abstract mixin class _$ChainReportCopyWith<$Res> implements $ChainReportCopyWith<$Res> {
  factory _$ChainReportCopyWith(_ChainReport value, $Res Function(_ChainReport) _then) = __$ChainReportCopyWithImpl;
@override @useResult
$Res call({
 String name, String status, List<String> hops,@JsonKey(name: 'targetGroup') String? targetGroup
});




}
/// @nodoc
class __$ChainReportCopyWithImpl<$Res>
    implements _$ChainReportCopyWith<$Res> {
  __$ChainReportCopyWithImpl(this._self, this._then);

  final _ChainReport _self;
  final $Res Function(_ChainReport) _then;

/// Create a copy of ChainReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? status = null,Object? hops = null,Object? targetGroup = freezed,}) {
  return _then(_ChainReport(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,hops: null == hops ? _self._hops : hops // ignore: cast_nullable_to_non_nullable
as List<String>,targetGroup: freezed == targetGroup ? _self.targetGroup : targetGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
