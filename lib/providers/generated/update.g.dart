// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../update.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The download that finished verification and is waiting for installation.

@ProviderFor(PreparedUpdateState)
final preparedUpdateStateProvider = PreparedUpdateStateProvider._();

/// The download that finished verification and is waiting for installation.
final class PreparedUpdateStateProvider
    extends $NotifierProvider<PreparedUpdateState, PreparedUpdate?> {
  /// The download that finished verification and is waiting for installation.
  PreparedUpdateStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedUpdateStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedUpdateStateHash();

  @$internal
  @override
  PreparedUpdateState create() => PreparedUpdateState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedUpdate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedUpdate?>(value),
    );
  }
}

String _$preparedUpdateStateHash() =>
    r'b56779c5ce2544e82f7c9a8bb46f1ba36560b437';

/// The download that finished verification and is waiting for installation.

abstract class _$PreparedUpdateState extends $Notifier<PreparedUpdate?> {
  PreparedUpdate? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PreparedUpdate?, PreparedUpdate?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PreparedUpdate?, PreparedUpdate?>,
              PreparedUpdate?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
