// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../module.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Module {

 int get id; String get label; String? get url; String get content; bool get enabled; String? get order; String? get author; String? get version; String? get homepage; String? get policy; DateTime? get updatedAt;
/// Create a copy of Module
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModuleCopyWith<Module> get copyWith => _$ModuleCopyWithImpl<Module>(this as Module, _$identity);

  /// Serializes this Module to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Module;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Module&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.homepage, _this.homepage) || other.homepage == _this.homepage)&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Module;
  return Object.hash(runtimeType,_this.id,_this.label,_this.url,_this.content,_this.enabled,_this.order,_this.author,_this.version,_this.homepage,_this.policy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Module;
  return 'Module(id: ${_this.id}, label: ${_this.label}, url: ${_this.url}, content: ${_this.content}, enabled: ${_this.enabled}, order: ${_this.order}, author: ${_this.author}, version: ${_this.version}, homepage: ${_this.homepage}, policy: ${_this.policy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ModuleCopyWith<$Res>  {
  factory $ModuleCopyWith(Module value, $Res Function(Module) _then) = _$ModuleCopyWithImpl;
@useResult
$Res call({
 int id, String label, String? url, String content, bool enabled, String? order, String? author, String? version, String? homepage, String? policy, DateTime? updatedAt
});




}
/// @nodoc
class _$ModuleCopyWithImpl<$Res>
    implements $ModuleCopyWith<$Res> {
  _$ModuleCopyWithImpl(this._self, this._then);

  final Module _self;
  final $Res Function(Module) _then;

/// Create a copy of Module
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? url = freezed,Object? content = null,Object? enabled = null,Object? order = freezed,Object? author = freezed,Object? version = freezed,Object? homepage = freezed,Object? policy = freezed,Object? updatedAt = freezed,}) {
  return _then(Module(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,policy: freezed == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Module].
extension ModulePatterns on Module {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Module value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Module() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Module value)  $default,){
final _that = this;
switch (_that) {
case _Module():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Module value)?  $default,){
final _that = this;
switch (_that) {
case _Module() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label,  String? url,  String content,  bool enabled,  String? order,  String? author,  String? version,  String? homepage,  String? policy,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Module() when $default != null:
return $default(_that.id,_that.label,_that.url,_that.content,_that.enabled,_that.order,_that.author,_that.version,_that.homepage,_that.policy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label,  String? url,  String content,  bool enabled,  String? order,  String? author,  String? version,  String? homepage,  String? policy,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Module():
return $default(_that.id,_that.label,_that.url,_that.content,_that.enabled,_that.order,_that.author,_that.version,_that.homepage,_that.policy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label,  String? url,  String content,  bool enabled,  String? order,  String? author,  String? version,  String? homepage,  String? policy,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Module() when $default != null:
return $default(_that.id,_that.label,_that.url,_that.content,_that.enabled,_that.order,_that.author,_that.version,_that.homepage,_that.policy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Module implements Module {
  const _Module({required this.id, required this.label, this.url, this.content = '', this.enabled = true, this.order, this.author, this.version, this.homepage, this.policy, this.updatedAt});
  factory _Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

@override final  int id;
@override final  String label;
@override final  String? url;
@override@JsonKey() final  String content;
@override@JsonKey() final  bool enabled;
@override final  String? order;
@override final  String? author;
@override final  String? version;
@override final  String? homepage;
@override final  String? policy;
@override final  DateTime? updatedAt;

/// Create a copy of Module
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModuleCopyWith<_Module> get copyWith => __$ModuleCopyWithImpl<_Module>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Module&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.url, url) || other.url == url)&&(identical(other.content, content) || other.content == content)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.order, order) || other.order == order)&&(identical(other.author, author) || other.author == author)&&(identical(other.version, version) || other.version == version)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,url,content,enabled,order,author,version,homepage,policy,updatedAt);
}

@override
String toString() {
    return 'Module(id: $id, label: $label, url: $url, content: $content, enabled: $enabled, order: $order, author: $author, version: $version, homepage: $homepage, policy: $policy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ModuleCopyWith<$Res> implements $ModuleCopyWith<$Res> {
  factory _$ModuleCopyWith(_Module value, $Res Function(_Module) _then) = __$ModuleCopyWithImpl;
@override @useResult
$Res call({
 int id, String label, String? url, String content, bool enabled, String? order, String? author, String? version, String? homepage, String? policy, DateTime? updatedAt
});




}
/// @nodoc
class __$ModuleCopyWithImpl<$Res>
    implements _$ModuleCopyWith<$Res> {
  __$ModuleCopyWithImpl(this._self, this._then);

  final _Module _self;
  final $Res Function(_Module) _then;

/// Create a copy of Module
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? url = freezed,Object? content = null,Object? enabled = null,Object? order = freezed,Object? author = freezed,Object? version = freezed,Object? homepage = freezed,Object? policy = freezed,Object? updatedAt = freezed,}) {
  return _then(_Module(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,policy: freezed == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
